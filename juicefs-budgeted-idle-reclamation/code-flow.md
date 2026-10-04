# 原生 compaction 代码流程与忙时补偿补丁详解

2026-09-29；验证状态补充至2026-10-04。 [返回目录](README.md) · [问题报告](bug-report.md) · [测试报告](test-report.md)

**核心结论：原版的问题发生在普通 compaction 的准入阶段。请求因繁忙被直接丢弃，而正在执行的批次只处理自己读取的历史快照。补丁将被拒绝的请求按原 chunk key 合并保存，在已有批次退出时原子转交一个槽位，让待办重新读取最新历史并执行原普通批次。**

本文从 FUSE 读写入口展开到元数据引擎、对象重写和旧对象删除，再逐段解释补丁的状态、锁、调用关系及边界。

## 导航

1. [源码版本与阅读约定](#source)
2. [数据模型：覆盖、历史引用和物理对象](#data-model)
3. [关键函数与文件索引](#function-index)
4. [初始化：元数据层如何调用对象层](#wiring)
5. [触发链：读、写、同步保护和显式合并](#triggers)
6. [已准入批次：从历史快照到新 slice](#batch)
7. [提交与回收：保留并发追加，删除失效对象](#commit-delete)
8. [原版漏处理的位置与两种时序](#root-cause)
9. [补丁逐段解释：保存、准入、原子转交与退出](#patch)
10. [修复后的完整调用层级与状态变化](#fixed-flow)
11. [正确性依据与保证边界](#guarantees)
12. [测试如何对应这些代码路径](#tests)
13. [建议的源码阅读顺序](#reading-order)

<a id="source"></a>

## 1. 源码版本与阅读约定

### 1.1 固定依据

- 原版：JuiceFS **v1.4.1**，commit **`0b90c7db5a929ae6adc5faad948d108efd2c99f9`**。
- 修复候选补丁：[0001-meta-retry-compaction-after-busy-admission.patch](patches/0001-meta-retry-compaction-after-busy-admission.patch)，只改 `pkg/meta/base.go`，**+42/-5**；不是生产验收通过声明。
- 测试补丁：[0002-meta-test-busy-compaction-retries.patch](patches/0002-meta-test-busy-compaction-retries.patch)，新增两个测试文件。
- 原版在线入口：[base.go](https://github.com/juicedata/juicefs/blob/0b90c7db5a929ae6adc5faad948d108efd2c99f9/pkg/meta/base.go)、[slice.go](https://github.com/juicedata/juicefs/blob/0b90c7db5a929ae6adc5faad948d108efd2c99f9/pkg/meta/slice.go)、[vfs/compact.go](https://github.com/juicedata/juicefs/blob/0b90c7db5a929ae6adc5faad948d108efd2c99f9/pkg/vfs/compact.go)。

本次逐函数核对的本地源码根目录：

```text
/home/lilingfeng/tmp/juicefs-native-compaction-retry-20260929/stock/github.com/juicedata/juicefs@v1.4.1/
```

这里的 `stock` 是实验目录名称，**该目录现在已经应用最终生产和测试补丁**。未经修复的对照源码在 `/home/lilingfeng/go/pkg/mod/github.com/juicedata/juicefs@v1.4.1/`。

### 1.2 行号、箭头和同名函数

- 下文的 `文件:行号` 默认指**应用补丁后的源码**；明确标注“原版”的位置才使用原版行号。原版在线链接中没有新增的 `compactChunkAdmitted`。
- 调用树中的 `→`/缩进表示调用关系；`[go]` 明确表示另起 goroutine。有些树同时列出初始化和异步完成阶段，并不是单条同步调用栈。
- `m.en.doRead/doWrite/doCompactChunk` 是 `engine` 接口分发，实际落到 KV、SQL 或 Redis 实现。
- `(*baseMeta).compactChunk(...)` 是**准入/调度入口**；`pkg/meta/slice.go` 中无接收者的 `compactChunk(ss)` 是**计算合并布局的函数**。二者同名，职责不同。
- `release` 是 `compactChunkAdmitted` 内部的局部闭包，**不存在独立的 `baseMeta.release` 方法**。

<a id="data-model"></a>

## 2. 数据模型：覆盖、历史引用和物理对象

### 2.1 inode → chunk → slice → block 对象

```text
一个文件 inode
└── 固定逻辑 chunk：indx = 文件偏移 / 64 MiB
    └── 按写入顺序记录的 slice 历史
        ├── pos：这条映射在 chunk 内的起点
        ├── id / size：源 slice ID / 源 slice 总长度
        ├── off / len：引用源 slice 的哪一段
        └── slice 数据按配置的 BlockSize 拆成对象存储中的 block
```

相关定义：

- `ChunkSize = 1 << 26`：`pkg/meta/interface.go:35-45`，即 64 MiB。
- 对外 `Slice`：`pkg/meta/interface.go:328`，字段为 `Id、Size、Off、Len`。
- 内部历史记录 `slice`：`pkg/meta/slice.go:21`，还包含 chunk 内的 `pos`。
- `marshalSlice`：`pkg/meta/slice.go:93`，一条历史记录编码为 24 字节。
- block 对象键生成：`(*rSlice).key`，`pkg/chunk/cached_store.go:74`；键包含 slice ID、block index 和该 block 长度。

**一个 slice 可以对应多个物理对象。**例如 96 KiB 的 slice 在 64 KiB block 配置下对应两个 block。合并后的 slice 条数、对象键个数、Ceph stored 字节是不同指标。

### 2.2 为什么“数据已覆盖”不等于“旧对象已可删除”

假设同一逻辑范围先后写入 A、B、C：

```text
元数据原始历史： [A, B, C]
当前可见内容：   C
原始历史引用：   A、B、C 仍记录在 chunk 历史中
```

`buildSlice`（`pkg/meta/slice.go:134`）按时间顺序覆盖区间，计算当前读应该看到的映射。这个计算在内存中完成，**不会顺带修改持久化历史或释放源 slice 引用**。

真正的回收链是：

```text
读历史 → 计算可见布局 → 写出新 slice D
      → 事务校验并将相应历史替换成 D
      → 减少被替换源 slice 的引用
      → 引用达到删除条件 → 删除源 slice 的 block 对象
```

因此，正常读返回正确数据、CRC 正确，与部分旧对象还占用空间可以同时成立。提高 `MaxDeletes` 只影响链条后部，不能替代前面的历史替换。

<a id="function-index"></a>

## 3. 关键函数与文件索引

### 3.1 读写与调度入口

| 函数/结构 | 文件位置 | 作用 |
| --- | --- | --- |
| `(*fileSystem).Write` / `Read` | `pkg/fuse/fuse.go:279` / `pkg/fuse/fuse.go:263` | FUSE 请求转给 VFS |
| `(*VFS).Write` / `Read` | `pkg/vfs/vfs.go:801` / `pkg/vfs/vfs.go:693` | 文件句柄、读写协调，调用 writer/reader |
| `(*fileWriter).Write` / `writeChunk` | `pkg/vfs/writer.go:330` / `pkg/vfs/writer.go:272` | 将文件写入拆到 chunk/slice |
| `(*sliceWriter).flushData` | `pkg/vfs/writer.go:110` | 完成 slice 数据写出，通知提交线程 |
| `(*chunkWriter).commitThread` | `pkg/vfs/writer.go:186` | 按顺序提交 slice 映射，调用 `Meta.Write` |
| `(*fileReader).Read` / `prepareRequests` / `newSlice` | `pkg/vfs/reader.go:626` / `pkg/vfs/reader.go:561` / `pkg/vfs/reader.go:310` | 准备读取请求，启动 slice reader |
| `(*sliceReader).run` | `pkg/vfs/reader.go:162` | 调用 `Meta.Read` 获取 chunk 映射 |
| `(*baseMeta).Read` / `Write` | `pkg/meta/base.go:2085` / `pkg/meta/base.go:2165` | 根据历史条数触发 compaction |
| `baseMeta.compacting` / `compactTodo` | `pkg/meta/base.go:285-286` | 已准入槽位 / 新增的合并去重待办 |
| `(*baseMeta).compactChunk` | `pkg/meta/base.go:2804` | 普通、once、force 准入入口 |
| `(*baseMeta).compactChunkAdmitted` | `pkg/meta/base.go:2835` | 新增内部函数，运行已预留槽位的批次 |
| 局部 `release` 闭包 | `pkg/meta/base.go:2838-2859` | 释放自身槽位并转交一个待办 |

### 3.2 规划、对象操作、提交及生命周期

| 函数 | 文件位置 | 作用 |
| --- | --- | --- |
| `buildSlice` / `compactChunk` / `skipSome` | `pkg/meta/slice.go:134` / `pkg/meta/slice.go:157` / `pkg/meta/slice.go:183` | 计算可见区间、批次布局和可跳过前缀 |
| `(*baseMeta).NewSlice` | `pkg/meta/base.go:2134` | 分配新 slice ID |
| `registerMetaMsg` | `cmd/mount.go:318` | 将合并/删除消息接到对象层 |
| `(*baseMeta).OnMsg` / `newMsg` | `pkg/meta/base.go:695` / `pkg/meta/base.go:701` | 注册、同步调用进程内回调 |
| `vfs.Compact` / `vfs.readSlice` | `pkg/vfs/compact.go:54` / `pkg/vfs/compact.go:37` | 读取有效数据、写出合并结果 |
| `(*cachedStore).NewReader` / `NewWriter` | `pkg/chunk/cached_store.go:1164` / `pkg/chunk/cached_store.go:1168` | 创建 slice 数据 reader/writer |
| `(*wSlice).Finish` | `pkg/chunk/cached_store.go:497` | 完成 block 写出并收集上传结果 |
| `(*kvMeta).doCompactChunk` | `pkg/meta/tkv.go:3113` | KV 事务校验、替换历史、更新引用 |
| `(*dbMeta).doCompactChunk` | `pkg/meta/sql.go:3864` | SQL 对应事务路径 |
| `(*redisMeta).doCompactChunk` | `pkg/meta/redis.go:3782` | Redis 对应事务路径 |
| `(*baseMeta).deleteSlice` / `deleteSlice_` | `pkg/meta/base.go:3032` / `pkg/meta/base.go:3022` | 安排删除 / 执行对象和引用记录删除 |
| `(*cachedStore).Remove` / `(*rSlice).Remove` | `pkg/chunk/cached_store.go:1172` / `pkg/chunk/cached_store.go:187` | 根据 slice ID、size 删除其全部 block |
| `(*cachedStore).delete` | `pkg/chunk/cached_store.go:336` | 调用具体对象后端的 `Delete` |
| `(*baseMeta).NewSession` / `CloseSession` | `pkg/meta/base.go:768` / `pkg/meta/base.go:970` | session、后台任务和取消状态管理 |
| `(*baseMeta).startDeleteSliceTasks` / `stopDeleteSliceTasks` | `pkg/meta/base.go:828` / `pkg/meta/base.go:856` | 原有删除 worker 的启动与结束 |

<a id="wiring"></a>

## 4. 初始化：元数据层如何调用对象层

三种元数据实现都复用 `baseMeta`，并将 `m.en` 指向具体引擎。以 KV 为例，`newKVMeta`（`pkg/meta/tkv.go:115`）创建 `baseMeta` 后执行 `m.en = m`。这样上层共用一套 `Read/Write/compactChunk`，底层各自实现事务。

挂载初始化中的相关层级：

```text
cmd.mount                                      [cmd/mount.go:547]
├── registerMetaMsg(metaCli, store, chunkConf)   [cmd/mount.go:676 → :318]
│   ├── metaCli.OnMsg(DeleteSlice, callback)    [pkg/meta/base.go:695]
│   │   └── callback → store.Remove(id, size)
│   └── metaCli.OnMsg(CompactChunk, callback)
│       └── callback → vfs.Compact(conf, store, slices, id, tierID)
└── metaCli.NewSession(true)                    [cmd/mount.go:678]
    └── baseMeta.NewSession                    [pkg/meta/base.go:768]
        ├── 建立 sessCtx
        ├── startDeleteSliceTasks              [pkg/meta/base.go:828]
        └── 按 NoBGJob 等条件启动原有后台清理
```

`DeleteSlice = 1000`、`CompactChunk = 1001` 定义在 `pkg/meta/interface.go:42-45`。

`newMsg` 获取注册回调后直接 `return cb(args...)`。它是**进程内同步回调分发**：compactor 要等 `vfs.Compact` 返回，才能继续提交元数据。对象合并慢或被测试 channel 阻塞时，该 compactor 的准入槽位仍然被占用。

<a id="triggers"></a>

## 5. 触发链：读、写、同步保护和显式合并

### 5.1 写路径：先写数据，再提交 slice 映射，再判断合并

```text
FUSE 写请求
└── (*fileSystem).Write                        [pkg/fuse/fuse.go:279]
    └── (*VFS).Write                           [pkg/vfs/vfs.go:801]
        └── h.writer.Write → (*fileWriter).Write
                                              [pkg/vfs/writer.go:330]
            └── (*fileWriter).writeChunk       [pkg/vfs/writer.go:272]
                ├── 查找/创建 sliceWriter
                ├── 首个待提交 slice：[go] (*chunkWriter).commitThread
                │                             [pkg/vfs/writer.go:186]
                └── (*sliceWriter).write       [pkg/vfs/writer.go:131]

slice 满、冻结或 flush 等事件
└── [go] (*sliceWriter).flushData               [pkg/vfs/writer.go:110]
    ├── prepareID                             [pkg/vfs/writer.go:72]
    ├── writer.Finish → (*wSlice).Finish       [pkg/chunk/cached_store.go:497]
    └── markDone                              [pkg/vfs/writer.go:101]
        └── [通知已运行的提交 goroutine] (*chunkWriter).commitThread
                                              [pkg/vfs/writer.go:186]
            └── f.w.m.Write(...)               [pkg/vfs/writer.go:208]
                └── (*baseMeta).Write          [pkg/meta/base.go:2165]
                    ├── m.en.doWrite(...)      [各元数据后端]
                    └── 成功后按 numSlices 选择普通或 once 合并
```

`commitThread` 等待 `s.done`，按 slice 创建顺序和依赖提交映射。因此一次应用层 `write()` 与一次 `Meta.Write`、一次 compaction 并不是一一对应的关系。

各后端的映射追加路径：

| 后端 | 函数位置 | 与本问题相关的操作 |
| --- | --- | --- |
| KV/TiKV 等 | `(*kvMeta).doWrite`，`pkg/meta/tkv.go:2650` | 把编码后的 slice 追加到 chunk value，返回历史记录数 |
| SQL/SQLite 等 | `(*dbMeta).doWrite`，`pkg/meta/sql.go:3355` | `upsertSlice` 更新历史，维护 `sliceRef`，获取历史记录数 |
| Redis | `(*redisMeta).doWrite`，`pkg/meta/redis.go:3127` | `RPush` 追加记录，使用返回的 list 长度 |

`baseMeta.Write` 中的原有触发条件（`pkg/meta/base.go:2180-2185`）：

```go
if numSlices%100 == 99 || numSlices > 350 {
    if numSlices < maxSlices {
        go m.compactChunk(inode, indx, false, false, int(attr.Tier))
    } else {
        m.compactChunk(inode, indx, true, false, int(attr.Tier))
    }
}
```

常量 `maxSlices = 2500`、`maxCompactSlices = 1000` 在 `pkg/meta/base.go:63-64`。

- 例如历史达到 99、199、299 条时有普通触发；大于 350 条后，每次成功的相关写提交都会进入条件判断。
- 少于 2500 条时异步调用普通合并。
- 达到 2500 条时调用同步 `once` 路径。这是写路径的同步保护阈值；并不意味着代码能在所有错误和并发条件下保证历史永不超过 2500 条。
- 写映射成功与普通合并是否准入是两件事。普通合并因忙而返回，通常不会使这次写操作返回错误。

### 5.2 读路径：缓存未命中时读取历史并触发

```text
FUSE 读请求
└── (*fileSystem).Read                         [pkg/fuse/fuse.go:263]
    └── (*VFS).Read                            [pkg/vfs/vfs.go:693]
        ├── v.writer.Flush(ctx, ino)           [pkg/vfs/vfs.go:789]
        └── h.reader.Read → (*fileReader).Read [pkg/vfs/reader.go:626]
            └── prepareRequests               [pkg/vfs/reader.go:561]
                └── 缺少有效读取请求时 newSlice
                                              [pkg/vfs/reader.go:310]
                    └── [go] (*sliceReader).run
                                              [pkg/vfs/reader.go:162]
                        └── f.r.m.Read(...)    [pkg/vfs/reader.go:175]
                            └── (*baseMeta).Read
                                              [pkg/meta/base.go:2085]
                                ├── openfiles chunk 缓存命中 → 返回
                                └── 未命中 → m.en.doRead
                                    ├── buildSlice → 返回可见映射并缓存
                                    └── 满足条件：[go] compactChunk(..., false, false, tierID)
```

预读也可以经 `newSlice` 启动同样的 reader。`VFS.Read` 前面的 `Flush` 还可能间接完成写提交，进而走上一节的写触发链。

`baseMeta.Read` 的触发条件（`pkg/meta/base.go:2124`）：

```go
!m.conf.ReadOnly && (len(ss) >= 5 || len(*slices) >= 5)
```

其中 `ss` 是原始历史，`*slices` 是 `buildSlice` 计算后的可见布局。**命中 `m.of.ReadChunk` 缓存会提前返回，走不到这一判断**（`pkg/meta/base.go:2097-2100`）；不能认为每次用户读都必然重新触发 compaction。

### 5.3 ordinary、once、force 的区别

| 模式 | `once` | `force` | 准入行为 | 批次行为 |
| --- | --- | --- | --- | --- |
| ordinary | false | false | 检查全局繁忙及同 key 繁忙 | 原普通批次，执行到尾部后不主动递归 |
| 写入同步保护 | true | false | 等待同 key 结束，绕过普通全局拒绝门 | 重读后若少于 2500 条直接返回；否则执行受单批上限约束的批次 |
| 显式强制合并 | false | true | 等待同 key 结束，绕过普通全局拒绝门 | 到达函数尾部时释放槽位并递归调用入口 |

`once/force` 等待同 key 的现有逻辑位于 `pkg/meta/base.go:2812-2817`：解锁、睡眠 10 ms、重新加锁检查。普通并发门是 **`len(m.compacting) > 10`**，所以在只有普通任务时最多准入 11 个，不是 10 个。显式 `once/force` 沿用自己的准入规则，因此混合调用时不能把 `len(m.compacting) <= 11` 当成无条件全局不变量。

### 5.4 原有显式合并入口

```text
juicefs compact PATH
└── cmd.compact                               [cmd/compact.go:53]
    └── doCompact                             [cmd/compact.go:90]
        └── 向挂载控制文件写入 CompactPath 消息
            └── (*VFS).Write 的 controlInode 分支
                                              [pkg/vfs/vfs.go:817-832]
                └── [go] handleInternalMsg    [pkg/vfs/internal.go:302]
                    └── case meta.CompactPath [pkg/vfs/internal.go:570]
                        └── Meta.Compact → (*baseMeta).Compact
                                              [pkg/meta/base.go:2946]
                            └── 遍历目标、分发 chunk
                                └── compactChunk(..., false, true, tierID)

juicefs gc 的 compact 分支
└── cmd.gc                                    [cmd/gc.go:76，分支 :166]
    └── (*baseMeta).CompactAll                 [pkg/meta/base.go:2779]
        ├── m.en.scanAllChunks                [各后端原有实现]
        └── worker → compactChunk(..., false, true, -1)
```

这些是原有显式维护路径。本补丁补偿的是读写已经触发的普通请求，不经 `Compact/CompactAll` 发现任务。

<a id="batch"></a>

## 6. 已准入批次：从历史快照到新 slice

### 6.1 主体的调用层级

补丁把原 `compactChunk` 的批次主体移入 `compactChunkAdmitted`；原版主体从 `base.go:2826` 开始，补丁后从 `base.go:2865` 开始。

```text
(*baseMeta).compactChunkAdmitted              [pkg/meta/base.go:2835]
├── 安装 defer release，并检查 session 取消
├── m.en.doRead(Background(), inode, indx)     [pkg/meta/base.go:2865]
│   ├── (*kvMeta).doRead                      [pkg/meta/tkv.go:2624]
│   ├── (*dbMeta).doRead                      [pkg/meta/sql.go:3326]
│   └── (*redisMeta).doRead                   [pkg/meta/redis.go:3084]
├── once 门槛检查 / 截取最多 1000 条历史
├── skipSome(ss)                              [pkg/meta/slice.go:183]
├── compactChunk(compacted)                   [pkg/meta/slice.go:157，无接收者]
│   └── buildSlice                            [pkg/meta/slice.go:134]
├── 不足两条待合并记录或 size==0 → 返回
├── NewSlice                                  [pkg/meta/base.go:2134]
├── tierID 未知时 GetAttr
├── newMsg(CompactChunk, slices, id, tierID)    [pkg/meta/base.go:2907]
│   └── 挂载注册回调 → vfs.Compact            [pkg/vfs/compact.go:54]
├── 编码 origin、准备延迟删除数据
├── m.en.doCompactChunk                       [pkg/meta/base.go:2929]
├── 处理提交结果 / 失效本地 chunk 映射缓存
└── 返回执行 release；force 到达尾部时先 release 再递归
```

### 6.2 为什么补偿必须重新读历史

主体调用底层 `doRead`，读取持久化的原始历史，绕过 `baseMeta.Read` 的可见映射缓存，也不会经由 `Read` 再触发一个 compaction。

三种后端的 `doRead` 分别读取 KV chunk value、SQL chunk 的 `Slices` 列、Redis chunk list。待办只保存执行参数，**不保存忙时的 `ss` 快照**。因此它真正执行时能看到上一批结果和之后追加的历史。

### 6.3 普通单批仍采用原规划策略

`pkg/meta/base.go:2873-2883` 保留原顺序：

1. `once` 模式先检查原始历史数；少于 `maxSlices` 就退出。
2. 原始历史超过 `maxCompactSlices` 时，仅取前 1000 条参与本批规划。
3. `skipSome(ss)` 计算可以保留的前缀；`compacted := ss[skipped:]`。
4. 布局函数 `compactChunk(compacted)` 计算 `pos、size、slices`。
5. `len(compacted) < 2` 或 `size == 0` 时退出。

`skipSome` 会评估首条记录是否足够大（至少 1 MiB）、是否仍完整处于布局开头、是否值得保留等条件。主体还检查保留前缀与输出区间是否重叠（`pkg/meta/base.go:2885-2893`）。

特别注意：退出判断用的是**原始待替换记录数 `len(compacted)`**，不是可见源片段数 `len(slices)`。多条历史即使都被最后一条完全覆盖，仍可能通过重写一个可见片段来替换整段历史、释放旧引用。

补偿沿用这套策略。因此“一次待办得到执行”不等于“整个 chunk 的所有历史都必须合并成一条”。

### 6.4 `vfs.Compact` 如何完成数据重写

```text
vfs.Compact                                   [pkg/vfs/compact.go:54]
├── 内存使用达到原限制时等待
├── store.NewWriter(newID, tierID)
├── writer.SetWriteback(false)                 [pkg/vfs/compact.go:66]
├── 遍历规划得到的可见 slices
│   ├── Id==0：向 writer 写入零，保持空洞语义
│   └── Id>0：按 block 大小读取有效范围
│       ├── readSlice                          [pkg/vfs/compact.go:37]
│       │   └── store.NewReader → (*rSlice).ReadAt
│       │                                      [pkg/chunk/cached_store.go:97]
│       │       └── 本地缓存或对象存储读取
│       └── writer.WriteAt / FlushTo
└── writer.Finish                              [pkg/chunk/cached_store.go:497]
    └── (*wSlice).FlushTo / upload             [同文件 :479 / :400]
        └── (*cachedStore).upload / put        [同文件 :356 / :312]
            └── ObjectStorage.Put             [pkg/object/interface.go:90]
```

compaction 显式关闭 writeback，成功返回意味着新 slice 的 block 上传按该 writer 的完成语义成功，元数据随后才切换到新 slice。读取、写入或 `Finish` 出错时，`vfs.Compact` 调用 `writer.Abort` 中止并尝试清理本次输出，然后返回错误；上层不会继续提交这一批的映射替换。

对象层本来就有上传重试逻辑，例如 `cachedStore.upload`。这是**一次批次内部的 I/O 重试**；与本补丁的**忙时准入补偿**是不同层级。

<a id="commit-delete"></a>

## 7. 提交与回收：保留并发追加，删除失效对象

### 7.1 前缀校验解决“合并期间又有写入”的问题

设本批选取的原始历史前缀为 `H`，其中 `K` 是 `skipSome` 保留的部分，`P` 是真正要替换的部分：

```text
读取并选定的前缀： H = K + P
合并期间又追加：   T
提交时当前历史：   H + T
新 slice：         C

校验 H 仍与当前历史前缀完全一致后：
    H + T  →  K + [C] + T
```

这里的 `T` 也可以包含最初读取时就位于前 1000 条之后、未纳入本批的历史。

`origin` 由本批 `ss` 按原编码重新序列化得到（`pkg/meta/base.go:2925-2928`）。各后端在事务中重新读取当前历史，校验它是否仍以 `origin` 开头。**允许尾部增加记录，但不允许静默覆盖已经变化的原前缀。**这就是本文所说的 origin/prefix/CAS 式替换，并不是新增了一种存储格式或事务协议。

| 后端 | 校验和替换代码位置 | 实现要点 |
| --- | --- | --- |
| KV | `pkg/meta/tkv.go:3113-3138` | 比较当前 value 前缀；写入“保留前缀 + 新记录 + 当前尾部”，同事务更新引用 |
| SQL | `pkg/meta/sql.go:3864-3902` | 事务内 `ForUpdate` 读取 chunk，比较前缀后更新 `Slices` 和引用表 |
| Redis | `pkg/meta/redis.go:3782-3826` | 对 chunk key 的事务中读取并比较前 n 条；`LTrim` 保留尾部，`LPush` 新记录及保留前缀 |

各实现还会在部分不确定的提交错误后检查新 slice 的引用记录，尽量区分“提交实际成功但客户端得到错误”和“确实没有使用新 slice”。这些都是原有逻辑。

### 7.2 TiKV 下进一步的调用层级

```text
(*kvMeta).doCompactChunk                      [pkg/meta/tkv.go:3113]
└── (*kvMeta).txn                             [pkg/meta/tkv.go:1098]
    ├── txBatchLock / 原有事务冲突重试
    └── m.client.txn
        └── (*prefixClient).txn               [pkg/meta/tkv_prefix.go:103]
            └── (*tikvClient).txn             [pkg/meta/tkv_tikv.go:358]
                ├── TiKV KVStore.Begin
                ├── 执行业务事务回调
                │   ├── prefixTxn.get         [pkg/meta/tkv_prefix.go:41]
                │   │   └── tikvTxn.get       [pkg/meta/tkv_tikv.go:125]
                │   ├── 校验 origin / 计算替换 value
                │   ├── prefixTxn.set         [pkg/meta/tkv_prefix.go:76]
                │   │   └── tikvTxn.set       [pkg/meta/tkv_tikv.go:179]
                │   └── prefixTxn.incrBy      [pkg/meta/tkv_prefix.go:84]
                │       └── tikvTxn.incrBy    [pkg/meta/tkv_tikv.go:190]
                └── KVTxn.Commit             [调用点 pkg/meta/tkv_tikv.go:384]
```

这个路径处理已知 `(inode, indx)` 的 chunk 和相关 slice 引用，补偿也直接重用它。**任务来自内存待办，不需要扫描全卷寻找 chunk**，因而不依赖之前扫描方案的 TiKV 分页增量。

### 7.3 引用达到什么条件才删除对象

不开 Trash 时，`doCompactChunk` 在替换历史的事务内减少被替换源 slice 的引用；事务完成后，满足无引用条件的源 slice 才进入 `deleteSlice`。其他文件/chunk 仍有引用的源对象应继续保留。

三类后端的计数编码不完全相同：

| 后端 | 引用表示 | 删除条件 |
| --- | --- | --- |
| KV / Redis | 以一个默认引用为基准；记录值 0 或省略记录可表示仍有这个默认引用 | 减引用后检查存储计数 `< 0` |
| SQL | `sliceRef.Refs` 为显式引用数，新建一般为 1 | 检查 `Refs <= 0` |

不要把 KV/Redis 的 `cleanupZeroRef` 理解成删除零实际引用对象：这里的存储值 0 对应默认引用，清理的是冗余计数记录。真正对象删除走负值分支。

`TrashDays > 0` 时，`baseMeta` 准备 `dsbuf`，后端保存延迟 slice 信息，暂缓源 slice 减引用。随后由 `cleanupDelayedSlices`（`pkg/meta/base.go:3295`）分发到 `doCleanupDelayedSlices`：KV `pkg/meta/tkv.go:3045`、SQL `pkg/meta/sql.go:3803`、Redis `pkg/meta/redis.go:3718`。本问题原现场 `TrashDays=0`，使用直接减引用路径。

### 7.4 从 `deleteSlice` 到对象后端的完整层级

```text
后端 doCompactChunk：事务成功且源引用达到删除条件
└── (*baseMeta).deleteSlice                    [pkg/meta/base.go:3032]
    ├── id==0 或 MaxDeletes==0 → 返回
    ├── dslices 队列未建立 → 同步 deleteSlice_
    └── 否则发送到 dslices
        └── startDeleteSliceTasks 创建的 worker
                                              [pkg/meta/base.go:828]
            └── (*baseMeta).deleteSlice_       [pkg/meta/base.go:3022]
                ├── newMsg(DeleteSlice, id, size)
                │   └── registerMetaMsg 注册的回调
                │       └── (*cachedStore).Remove
                │                             [pkg/chunk/cached_store.go:1172]
                │           └── (*rSlice).Remove
                │                             [pkg/chunk/cached_store.go:187]
                │               ├── 清理对应 pending/cache 条目
                │               └── 逐 block 调用 (*rSlice).delete
                │                             [pkg/chunk/cached_store.go:182]
                │                   └── (*cachedStore).delete
                │                             [pkg/chunk/cached_store.go:336]
                │                       └── ObjectStorage.Delete
                └── 对象删除成功后 m.en.doDeleteSlice(id, size)
                    ├── KV：   pkg/meta/tkv.go:139
                    ├── SQL：  pkg/meta/sql.go:560
                    └── Redis：pkg/meta/redis.go:318
```

当具体对象后端是 Ceph RADOS 时，经过相应存储包装层后最终到 `(*ceph).Delete`（`pkg/object/ceph.go:190`），调用 RADOS `IOContext.Delete`。这是代码层级说明；本轮实际对象测试使用内存对象后端。

若对象删除失败，`deleteSlice_` 直接返回，保留后端的待删除引用记录。原有 `cleanupSlices`（`pkg/meta/base.go:1041`）可继续清理这些已满足删除条件的记录。它的三个后端入口是 KV `pkg/meta/tkv.go:2957`、SQL `pkg/meta/sql.go:3706`、Redis `pkg/meta/redis.go:3506`。

**这些清理任务处理已失效的引用/删除记录，不会代替一次缺失的 compaction，把仍保存在 chunk 历史中的覆盖记录自动替换掉。**

### 7.5 主体如何处理提交结果

`pkg/meta/base.go:2929-2938`：

| `doCompactChunk` 返回值 | 主体后续处理 |
| --- | --- |
| `0` | 失效本地 chunk 映射缓存；源对象回收由后端引用处理路径安排 |
| `EINVAL` | 本次新 slice 未被采用，调用 `deleteSlice(id, size)` 清理**新产物**，不是强删源对象 |
| 其他错误 | 记录可能孤立的新 slice，保留原有后续 GC 处理方式 |

普通任务随后结束。`force` 如果到达函数尾部则按原逻辑递归；前面的读取、规划、对象回调等提前返回路径不会走到该尾部。

<a id="root-cause"></a>

## 8. 原版漏处理的位置与两种时序

### 8.1 准入时丢弃，结束时只删活跃标记

原版 `pkg/meta/base.go:2814-2824` 的关键片段：

```go
} else if len(m.compacting) > 10 || m.compacting[k] {
    m.Unlock()
    return
}
m.compacting[k] = true
m.Unlock()
defer func() {
    m.Lock()
    delete(m.compacting, k)
    m.Unlock()
}()
```

这段代码只记录“谁已经在执行”，没有记录“谁因忙没能执行”。被拒绝的请求已经返回，正在执行的请求退出时也没有信息可用来恢复它。

### 8.2 场景 A：全局繁忙，另一个 chunk 的请求丢失

```text
t0  chunk A1...A11 已经进入 compaction，11 个槽位均被占用。
t1  chunk B 的 Write/Read 触发普通 compaction。
t2  B 检查 len(compacting)>10，立即返回。
t3  A1 完成；原版只 delete(compacting[A1])。
t4  后续没有新的 B 读写触发，也没有显式合并；B 的本次请求不会重来。
```

### 8.3 场景 B：同 chunk 正在合并，快照后的新历史未获补偿

这是同 chunk 确定性测试使用的时序，历史为同一区间的覆盖记录：

```text
t0  K 有 99 条历史，普通任务 F 读取这 99 条并开始对象合并。
t1  F 尚未提交，写入又追加 99 条历史；当前变成 198 条。
t2  针对 K 发出新的普通请求；原版见 compacting[K]==true，直接返回。
t3  F 按前缀规则提交，只替换最初的 99 条：
        [旧99条] + [新增99条]  →  [C1] + [新增99条]
t4  F 结束并清除活跃标记。剩余原始历史是 100 条。
t5  没有后续触发时，这 100 条不会仅因为 F 已完成就再合并一次。
```

这里 **t3 的“保留新增尾部”是正确的数据一致性行为**。缺失的是 t2 请求所表达的“前一批之后还需要再看一次”，不是应该让 F 越过快照范围覆盖新写入。

<a id="patch"></a>

## 9. 补丁逐段解释：保存、准入、原子转交与退出

### 9.1 增加一份去重待办状态

位置：`pkg/meta/base.go:285-286`。

```go
compacting  map[uint64]bool
compactTodo map[uint64]func()
```

- `compacting[k]`：key 已经被准入或预留，拥有执行槽位。
- `compactTodo[k]`：这个 key 还有一个普通请求需要重新检查最新历史。
- key 沿用原编码：`uint64(inode) + (uint64(indx) << 40)`，见 `pkg/meta/base.go:2806`。
- 两个 map 的并发访问使用同一把 `baseMeta` 的 mutex。
- `compactTodo` 首次遇到忙时请求才分配；多个相同 key 的请求覆盖同一项。

它表达的是“这个 chunk 还需处理一次”的意图，不是按触发次数累计 256 个重复任务，也不是持久化的任务表。

### 9.2 普通请求忙时保存，直接准入时覆盖旧待办

位置：`pkg/meta/base.go:2818-2831`。

```go
} else if len(m.compacting) > 10 || m.compacting[k] {
    if m.compactTodo == nil {
        m.compactTodo = make(map[uint64]func())
    }
    m.compactTodo[k] = func() {
        m.compactChunkAdmitted(inode, indx, false, false, tierID)
    }
    m.Unlock()
    return
} else {
    delete(m.compactTodo, k)
}
m.compacting[k] = true
m.Unlock()
m.compactChunkAdmitted(inode, indx, once, force, tierID)
```

上面按阅读需要展开了补丁中的单行闭包。

**忙时分支：**保留 inode、indx、tierID 等执行参数，固定用 ordinary 的 `false, false` 执行；最近一次同 key 请求替换较早回调。它没有捕获旧布局，后续由主体重新读取。

**直接准入分支：**新的普通任务马上就会读最新历史，因此它覆盖同 key 较早的待办意图，先删除旧待办。若在它准入之后又有普通请求因同 key 忙被拒绝，仍会重新设置待办，作为本批之后的新补偿意图。

### 9.3 为什么只有普通直接准入才能删除旧待办

`delete(m.compactTodo, k)` 位于普通分支的 `else` 内，没有放到所有模式共用的 `m.compacting[k] = true` 前面。

原因是 `once` 可能成功准入却完全不做合并：

```text
已有 B 的 ordinary 待办，B 只有 99 条历史
→ 同步 once 请求绕过普通全局门并准入
→ 主体重读发现 99 < 2500
→ 直接返回，没有对象重写
```

如果 once 准入时就清掉待办，真正需要执行的普通批次又会消失。补丁让 once 保留该意图；退出后是否立刻转交，由全局槽位和 key 状态决定。force 也不经过普通分支的这项删除。

### 9.4 将“准入”和“执行主体”分开

新增 `compactChunkAdmitted` 的调用前提是：**调用方已经在锁内设置了 `m.compacting[k] = true`**。

它有两种调用者：

1. `compactChunk`：新请求通过原准入逻辑后，同步调用主体。
2. `release` 派发的待办回调：已经原子预留槽位，直接调用主体。

因此补偿任务不会再次经过普通准入门。否则会产生两种错误设计：

- 只删除旧槽位，再 `go compactChunk(...)`：新普通请求可能抢先占槽，待办再次被拒绝；转交没有保证。
- 先预留 `compacting[next] = true`，却仍调用 `compactChunk(...)`：任务会把自己的预留看成“同 key 已忙”，无法正确进入主体。

内部入口使“已经获得槽位”成为明确的调用约定。

### 9.5 在所有主体返回路径统一释放并转交一个槽位

位置：`pkg/meta/base.go:2837-2860`。以下为实际闭包：

```go
released := false
release := func() {
    if released {
        return
    }
    released = true
    m.Lock()
    delete(m.compacting, k)
    if m.sessCtx != nil && m.sessCtx.Canceled() {
        m.compactTodo = nil
    } else if len(m.compacting) <= 10 {
        for next, run := range m.compactTodo {
            if !m.compacting[next] {
                delete(m.compactTodo, next)
                m.compacting[next] = true
                go run()
                break
            }
        }
    }
    m.Unlock()
}
defer release()
```

一次有效释放按以下顺序完成：

1. 删除本次执行拥有的 active key。
2. 若 session 已取消，清空待办并结束调度。
3. 否则只有在剩余活跃数量 `<=10` 时，才允许补入一个 ordinary。
4. 遍历待办，跳过仍有在途执行的 key。
5. 在**同一临界区**内删除选中待办、写入它的活跃标记，然后 `go run()`。
6. `break`，单次释放最多派发一个待办。

实际代码在持锁期间创建 goroutine；在它被派发前，槽位已经预留。对象 I/O 由该 goroutine 执行，不是在释放者的临界区内同步等待它完成。

因为 `defer release()` 安装在主体开头，读取失败、数据损坏、once 门槛未满足、无需合并、ID/属性获取失败、对象回调失败以及正常提交后返回，都能释放槽位并让其他合格待办继续。

### 9.6 为什么成功和失败都要释放待办机会

槽位可用与“上一批对象操作是否成功”是两个条件。A 的对象操作失败，只说明 A 这次没有完成；B 已经因 A 等任务占槽而等待，仍应在槽位腾出后得到一次执行机会。

补丁没有在错误分支重新给 A 入队：**没有新的忙时请求时，一次已准入失败不会自己制造无限整批重试。**如果 A 在执行期间确实收到过另一个被拒绝的请求，则那个已经存在的待办仍可得到补偿。

### 9.7 `released` 防止 force 递归破坏槽位所有权

force 在到达主体尾部时必须先释放自己的 key，再递归从入口等待/准入：

```go
if force {
    release()
    m.compactChunk(inode, indx, once, force, tierID)
}
```

位置：`pkg/meta/base.go:2940-2943`。

加入待办转交后，同一个 key 的布尔标记可能已经属于另一次调用。典型顺序：

```text
外层 force F0 持有 K
→ F0.release 将 K 转交给 ordinary R1
→ F0 递归调用 F1，F1 等待 R1 完成后重新准入
→ F1 最后一次读取/退出期间又收到 K 的普通待办
→ F1.release 将 K 转交给 R2
→ F1 返回，外层 F0 的 defer 开始执行
```

如果 F0 的 defer 再次无条件 `delete(compacting[K])`，就会错误清除 R2 的预留，使外部看到“没有任务”，甚至允许同 key 重复准入。

每次主体调用拥有自己的局部 `released`。F0 主动调用过 release 后，外层 defer 只会返回；它不会再改动已经转交出去的槽位。这是**一次调用最多释放一次**，不是只给某个 key 全局设置一个永久完成标记。

### 9.8 session 退出时清理待办

原有入口检查与补丁增加的主体、释放和关闭处理配合工作：

| 位置 | 行为 |
| --- | --- |
| `compactChunk` 入口，`pkg/meta/base.go:2808` | 沿用取消后拒绝新准入的检查 |
| `compactChunkAdmitted`，`pkg/meta/base.go:2861` | 预留后、主体读取前再次检查取消 |
| `release`，`pkg/meta/base.go:2845` | 取消后清空待办，不继续转交 |
| `CloseSession`，`pkg/meta/base.go:979-985` | Cancel 后持锁清空待办，再等待原有 session worker |

仍在 map 中的待办会被清空；已预留或正在派发的任务在主体入口观察到取消时直接返回，并由 defer 释放槽位。已经通过检查、进入 I/O 的任务仍遵循原来的取消边界：主体使用 `Background()`，补丁没有把在途对象操作变成可立即中断，也没有把 compactor 加入 `sessWG` 作为新增关闭等待任务。

<a id="fixed-flow"></a>

## 10. 修复后的完整调用层级与状态变化

### 10.1 从忙时请求到下一批提交

```text
Read / Write
└── [go] compactChunk(K, false, false, tierID)  [pkg/meta/base.go:2804]
    ├── Lock
    ├── 全局忙或 K 已忙
    ├── compactTodo[K] = 普通主体回调
    └── Unlock，返回

已有任务 A 结束（正常返回或错误返回）
└── compactChunkAdmitted(A) 的 defer release   [pkg/meta/base.go:2838]
    ├── Lock
    ├── 删除 compacting[A]
    ├── 找到可以执行的 K
    ├── 删除 compactTodo[K]，设置 compacting[K]=true
    ├── [go] run()
    │   └── compactChunkAdmitted(K, false, false, tierID)
    │       ├── doRead：读最新原始历史
    │       ├── 原有 skipSome / compactChunk 布局
    │       ├── newMsg → vfs.Compact → 新对象上传
    │       ├── doCompactChunk → 前缀校验及事务替换
    │       ├── 源引用释放 → deleteSlice → 对象删除
    │       └── defer release → 再给一个合格待办转交机会
    └── Unlock
```

若是同 chunk 场景，A 与 K 可以是同一个 key。先删除自己的 active 标记后，它自己的待办即可成为可选项；具体选择顺序仍由 map 遍历决定。

### 10.2 同 chunk 的 99 + 99 条示例如何收敛

| 时间 | `compacting[K]` | `compactTodo[K]` | 持久化历史/动作 |
| --- | --- | --- | --- |
| F 首次准入 | true | 无 | 读取旧 99 条，开始对象合并 |
| 又追加 99 条且普通触发被拒绝 | true | 有 | 当前历史 198 条；记录一次后续意图 |
| 再发生 255 次同 key 忙时请求 | true | 仍只有一项 | 覆盖待办回调，不累积 256 个独立批次 |
| F 提交 | true | 有 | 历史变成 `[C1] + 新99条`，共 100 条 |
| F 释放并选中 K | true，所有权转给 R | 无 | 删除旧 active、重新预留，均在锁内完成 |
| R 执行 | true | 无，除非又有新触发 | 重读这 100 条并执行原普通批次 |
| R 提交、释放 | false | 无 | 该测试布局最终为 `[C2]`，旧引用进入回收链 |

若没有新写入，R 重读后可能只看到一条记录，规划阶段直接返回，**不会仅因为有过 256 次触发就重写 256 次对象**。

### 10.3 全局繁忙下的转交

```text
初始：11 个活跃，待办 B、C
A 退出：删除 A → 10 个；预留 B → 11 个；启动 B
B 退出：删除 B → 10 个；预留 C → 11 个；启动 C
C 退出：删除 C → 10 个；没有待办则停止转交
```

不需要等待其他 10 个任务一起完成，也不一次性启动全部待办。若显式任务使活跃数更高，则继续等释放后满足 `<=10` 的条件才派发普通待办。

### 10.4 两个 map 的四种组合

| active | todo | 含义 |
| --- | --- | --- |
| 无 | 无 | 没有已准入执行，也没有保留的普通意图 |
| 有 | 无 | 正在执行或已经预留 |
| 有 | 有 | 当前批次在途；它之后还需一次普通重读机会 |
| 无 | 有 | 本 key 未执行，但等待全局槽位/下一次合格转交 |

特别是“active 与 todo 同时存在”是正常状态，正是同 chunk 快照后新请求的表达方式。

<a id="guarantees"></a>

## 11. 正确性依据与保证边界

### 11.1 为什么解决了确定复现的漏处理

1. **意图不再在忙门丢失。**命中忙门意味着有同 key 在途任务或全局已有过多任务；本次普通请求进入 todo。
2. **完成事件提供推进机会。**已有任务结束时，统一 release 检查待办；不再依赖新的用户读写来恢复这个意图。
3. **槽位交接没有重新抢占窗口。**待办的选择、删除和 active 预留在同一把锁内完成，随后直接进入已准入主体。
4. **旧快照没有被复用。**补偿读取最新历史，能处理前一次提交保留的追加尾部。
5. **原数据一致性链保留。**新对象先完成、事务校验原前缀、保留尾部、按引用删除源对象的顺序没有改变。
6. **普通直接准入能接替旧意图。**即便待办被一个后来成功准入的普通请求覆盖，它也会按同样的最新历史读取路径执行。

当请求积压有限、相关活跃操作最终能结束、goroutine 能继续获得调度且 session 保持运行时，这套机制提供忙时请求的普通批次补偿机会。

### 11.2 阅读实现时需要保留的边界

- **状态属于当前客户端实例。**它不是跨挂载节点的全局任务表；多客户端同时合并的最终一致性仍由后端事务校验负责。
- **意图不跨退出/重启保存。**未曾触发请求的旧历史以及重启前遗留历史，不会仅因本 map 存在而被发现。
- **一次意图对应一次普通批次机会。**单批 1000 条上限、`skipSome`、无需合并时退出等原策略继续有效。
- **队列没有硬容量上限。**同 key 去重限制了重复触发的开销，但不同 key 的待办仍可增长。
- **map 不是 FIFO。**有限积压下的补偿不等于持续新增任务时的严格公平性或等待时延保证。
- **失败不会自己重新排队。**没有额外忙时触发时，已准入的整批对象失败仍结束；对象层内部原有 I/O 重试继续存在。
- **删除仍受原条件约束。**引用未释放、其他引用仍存在、Trash 延迟、`MaxDeletes=0` 或对象删除错误，都可能使物理空间暂不下降。
- **`NoBGJob` 控制原有后台清理。**普通读写触发和本次完成事件补偿没有新增对该开关的依赖。
- **并发门保留不代表性能已验收。**补偿会执行此前丢弃的工作；实际 TiKV/Ceph 空间回收、吞吐和前台延迟仍需实测。

原现场空间差额没有逐分支归因证据。这里说明并验证的是忙时漏请求机制，不能据此把全部空间差额都归到这一处准入分支。

<a id="tests"></a>

## 12. 测试如何对应这些代码路径

### 12.1 入口、阻塞点和观察点

两个测试文件来自独立的 0002 补丁：

- `pkg/meta/compact_retry_test.go`：使用真实 memkv/SQLite/Redis 元数据操作，把 `CompactChunk` 回调作为可控制的阻塞/失败点。
- `pkg/meta/compact_retry_objects_test.go`：SQLite + 内存 ObjectStorage，实际调用 `vfs.Compact` 和 `store.Remove`。

前一组测试的元数据 compactor 确实经过准入、`doRead`、规划、回调和提交；对象回调由 fixture 控制，不承担真实对象重写。后一组补上真实数据重写、CRC 和删除链验证。

fixture 的关键位置：

| 辅助函数/位置 | 文件位置 | 为什么这样设计 |
| --- | --- | --- |
| `RunNativeCompactForTest` | `pkg/meta/compact_retry_test.go:32` | 外部对象测试可以直接触发 ordinary，并且在原版上也能编译 |
| `NativeCompactHistoryForTest` | `pkg/meta/compact_retry_test.go:43` | 直接读原始历史，避免观察过程触发新的 `Meta.Read` 补偿 |
| `newCompactRetryFixture` | `pkg/meta/compact_retry_test.go:100` | 创建独立元数据后端，安装回调和跟踪 |
| fixture 注册 `CompactChunk` 回调 | `pkg/meta/compact_retry_test.go:135` | 在真实在途执行处等待 channel，控制繁忙窗口 |
| `(*compactRetryFixture).write` | `pkg/meta/compact_retry_test.go:183` | 用底层 `doWrite` 安排追加历史，自动触发时机由测试显式控制 |

`RunNativeCompactForTest` 等辅助导出仅存在于 `_test.go`，不会进入生产构建。测试没有向 `compacting` 填入假的活跃任务来制造饱和。

### 12.2 每项测试对应的修复点

| 测试函数 | 文件位置 | 覆盖路径 |
| --- | --- | --- |
| `TestCompactRetryGlobal` | `pkg/meta/compact_retry_test.go:262` | 11 个真实在途任务、两个待办；成功/失败释放都能转交；once 无动作不能吞待办；普通对象并发不超原门槛 |
| `TestCompactRetrySameChunk` | `pkg/meta/compact_retry_test.go:318` | 首次快照后追加 99 条，256 次触发合并为一次补偿；最新历史重读 |
| `TestCompactRetryNoRedundantRewrite` | `pkg/meta/compact_retry_test.go:342` | 没有新写入时，重复触发不产生重复对象重写 |
| `TestCompactRetryFailureDoesNotLoop` | `pkg/meta/compact_retry_test.go:362` | 没有忙时新请求的一次对象错误不会自己形成整批重试循环 |
| `TestCompactRetryCancellation` | `pkg/meta/compact_retry_test.go:377` | 真实 `NewSession/CloseSession` 后不继续启动已排队请求 |
| `TestCompactRetryForcedOwnership` | `pkg/meta/compact_retry_test.go:402` | 强制递归最后一次读被阻塞时追加历史；外层 defer 不能删除转给新补偿的槽位 |
| `TestCompactRetryRealObjects` | `pkg/meta/compact_retry_objects_test.go:35` | 真实布局重写、并发追加保留、内容/CRC、实际源 block 删除 |

### 12.3 实际对象用例为什么能验证完整链条

对象用例的顺序是：

1. 写入 5 个源 slice，逐个通过 `Head` 确认对象已经存在。
2. 启动第一批 compaction，并在回调入口阻塞；此时元数据快照已读取。
3. 追加两次部分覆盖写：`16 KiB..48 KiB`、`80 KiB..96 KiB`，同样先确认源对象存在。
4. 在确定繁忙的窗口显式发一次普通请求，然后释放第一批。
5. 等待活跃任务完成，以底层历史读取确认最终一条记录，确认恰好两个普通对象批次。
6. 用最终 slice 的真实 reader 读取 **98304 B / 96 KiB**，比较完整字节和 CRC32。
7. 检查 7 个输入源 slice，加上第一批产生、第二批又替换掉的中间 slice，其全部 block 对象都已删除。

日志中的 `removed_source_slices=8` 指这 **8 个 slice**，不是“恰好 8 个物理对象键”。第一批 96 KiB 的中间 slice 在该测试的 64 KiB block 配置下就有两个对象。

### 12.4 已有验证结果

最终两份补丁对应的正式结果为：

- 原版只应用测试补丁：**13 个目标叶子用例在 `COMPACT_RETRY_MISSING` 预期断言失败，9 个负控通过，0 跳过**。
- 再应用修复候选补丁：**22 个叶子用例 × 3 次 race = 66 次通过，0 跳过**。
- 实际对象用例三轮均记录：`ordinary_batches=2 raw_records=1 content_bytes=98304 CRC=PASS removed_source_slices=8`。

以上是9月29日离线验证证据，见[测试报告](test-report.md)和 [raw-test-data/logs](raw-test-data/logs/)。它们针对普通 compactor 及对象链条，不是一次完整FUSE压力测试；完整meta core受隔离环境缺少TiKV PD阻塞的记录保留。后续真实TiKV/Ceph验证已完成C11 randrw、C12 randwrite两小时自动回收及全量CRC，C13顺序写因容量保护中止；最新现场状态见[现场验证章节](test-report.md#field-validation)。24/72小时长稳、持续容量上界和前台性能非劣性仍未验收，不能把上述66次离线通过换算成现场长稳通过。

<a id="reading-order"></a>

## 13. 建议的源码阅读顺序

如果要按最短路线核对补丁是否解决了问题，建议依次阅读：

1. **原始触发条件：**`pkg/meta/base.go:2085` 的 `Read`，以及 `pkg/meta/base.go:2165` 的 `Write`。
2. **漏请求与保存意图：**对照原版 `base.go:2800-2824` 和补丁后 `pkg/meta/base.go:2804-2831`。
3. **槽位所有权：**`pkg/meta/base.go:2835-2863`，重点看预留、局部 `release` 和取消检查。
4. **批次仍读取最新历史：**`pkg/meta/base.go:2865-2938`，配合 `pkg/meta/slice.go:134-209`。
5. **快照后的追加尾部为什么必须保留：**以 `pkg/meta/tkv.go:3113-3172` 为主，与 SQL/Redis 对应实现对照。
6. **物理回收的后半段：**`pkg/vfs/compact.go:54`、`pkg/meta/base.go:3022-3047`、`pkg/chunk/cached_store.go:187`。
7. **强制递归的释放次数：**`pkg/meta/base.go:2940-2943`，配合 `TestCompactRetryForcedOwnership`。
8. **完整前后对照：**从 `TestCompactRetrySameChunk` 开始，再看 `Global`、`RealObjects` 和其余负控。

最终可以把补丁理解为补齐了一条原来断开的连接：

```text
已发出但因繁忙被拒绝的普通请求
    → 保存“需要重读一次”的意图
    → 已有任务退出
    → 原子获得槽位
    → 原普通合并、事务替换和对象回收链
```
