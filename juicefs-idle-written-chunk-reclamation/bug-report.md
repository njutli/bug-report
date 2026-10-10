# 已确认问题：低记录数覆盖写停止后没有合并触发

## 1. 实测现象与根因

R01/R02是两个独立真实TiKV/Ceph子目录，用上游v1.4.1加事件观测执行。没有回收策略修改；观测有额外开销，不能称完全未修改的二进制或零性能扰动。

| 项目 | R01 | R02 |
|---|---:|---:|
| 文件/逻辑数据 | 16×256MiB / 4GiB | 同左 |
| 初始化+四次完整覆盖写 | 20GiB | 20GiB |
| 成功Write事件 | 1376 | 1388 |
| 64个chunk记录数范围 | 9～30 | 10～27 |
| 目标chunk的合并请求 | 0 | 0 |
| 冷期源引用/完全覆盖历史 | 20/16GiB | 20/16GiB |
| 六份冷期FSTree | 相同 | 相同 |
| 最后成功doWrite事件至冻结 | 3612.356秒 | 3610.768秒 |
| 人工合并后源引用/历史 | 4/0GiB | 4/0GiB |
| 成功人工提交 | 64 | 64 |
| 旧源slice删除成功响应 | 1376 | 1388 |
| 全量CRC | 4GiB PASS | 4GiB PASS |

Write事件按顺序精确重放为最终原始映射，记录计数连续1..N，所有触发表达式false；序号无缺口、emitted=logged、queue/drop=0。R02全局trace含R01维护事件，归因按各轮inode过滤。每轮16GiB残留是有效数据的400%、源引用的80%。

人工合并和CRC发生在冷期冻结之后，不算自动回收。对象删除成功是回调响应，不是盘面逐block独立读取证明。旧大规模现场不具备相同完整trace，不能将其全部残留归入这两轮结论。

[逐chunk结果和独立复核](raw-test-data/README.md)包含原归档hash。原因实验和当前候选的测试明确分开。

## 2. 写入过程与定位

### 2.1 先分清数据和“数据在哪里”的记录

以一个文件的前1MiB为例，它位于该文件的第0个chunk内：

| 名称 | 在这个例子中代表什么 | 保存在哪里 |
|---|---|---|
| inode | 标识这个文件 | 元数据引擎 |
| chunk | 文件按64MiB划分的逻辑区域；第0个chunk覆盖文件偏移 `[0,64MiB)` | 逻辑划分，不是一个必须原地覆盖的64MiB对象 |
| slice数据 | 一次形成的、有独立ID的数据，如下面的A、B、C | 拆成block对象保存到对象存储 |
| slice映射记录 | “chunk的哪段位置，对应哪个slice的哪段数据” | 元数据引擎，例如TiKV |
| block对象 | 按配置BlockSize拆分的实际数据对象 | 对象存储，例如Ceph |

一条映射包含 `pos、id、size、off、len`：chunk内起点、源slice ID、源完整大小、源内偏移、引用长度。它编码后只有24字节，却可以引用MiB级数据。

**下面用A/B/C表示不同slice的数据，而不是三个文件。** 为便于讲解，假定每一步写入的数据都形成一个slice，并在下一步开始前完成数据和映射提交。实际一次应用write可能拆成多次FUSE请求，VFS也可能合并或切分数据，不能把应用write次数、block对象数、Meta.Write次数直接画等号。

### 2.2 第一次写入：把1MiB的A写到文件开头

整体顺序如下。箭头表示处理和依赖关系，**不表示全部在应用write的同一个同步调用栈中完成**：

```text
应用写入文件的 [0,1MiB)，内容记为A
  → 内核通过FUSE把写请求交给JuiceFS
  → VFS writer定位到chunk 0，接收并组织slice数据
  → flushData调用底层writer.Finish，完成该slice的数据写出
  → 通知commitThread：这个slice的数据处理已结束
  → commitThread检查成功后调用Meta.Write，提交A的映射
  → baseMeta.Write调用engine.doWrite，把映射保存到元数据后端
  → 成功返回这个chunk当前的记录数numSlices
  → baseMeta.Write按numSlices判断是否请求合并
```

逐步解释：

1. **FUSE Write是文件写请求入口。** 请求带文件句柄、文件偏移和数据，不是直接向TiKV写文件内容。
2. **VFS writer负责组织数据。** 它把文件偏移换成chunk编号和chunk内偏移，选择或创建slice writer，缓冲/分块写出数据。有些block可在Finish之前已经上传。
3. **Finish完成的是slice的数据写出，不是历史合并。** `flushData`会冻结该slice的数据范围并调用底层writer的Finish。按本次原因实验的writeback关闭配置，成功后相关数据上传已经完成；不同缓存/writeback配置的持久性边界需另行区分。
4. **commitThread负责随后提交映射。** 每个活跃chunk的提交goroutine按slice创建顺序等待数据处理完成，成功才调用Meta.Write；若数据阶段失败，不进入这次正常映射提交。它不是等文件关闭才统一启动的线程。
5. **Meta.Write写的是“数据在哪里”，不是再次上传1MiB的A。** Meta.Write是接口入口，实际进入公共的baseMeta.Write，再调用当前后端的engine.doWrite。TiKV属于KV引擎实现；Redis、SQL有各自实现。
6. **engine.doWrite成功后才检查记录数。** 此时A的映射已经保存；上游用当前chunk的记录数决定要不要另外请求compaction。映射提交成功不等于已合并，也不等于旧对象已删除。

A提交后，第0个chunk的状态是：

```text
元数据原始记录：[A: pos=0, size=1MiB, off=0, len=1MiB]
当前可见内容：  文件 [0,1MiB) → A
numSlices：    1
```

如果BlockSize为256KiB，A的数据对应4个block对象，**元数据这里仍只有1条slice映射，不是4条**。

### 2.3 第二次写入：用B覆盖中间256KiB

现在把文件 `[256KiB,512KiB)` 改成B。B走同样的流程：数据写出完成，再提交映射。本例中已提交的A不会被就地改写，元数据追加B的记录：

```text
原始记录（按提交顺序）：
  A：文件 [0,1024KiB)   → A的 [0,1024KiB)
  B：文件 [256,512KiB)  → B的 [0,256KiB)

读取时的有效布局（后写覆盖先写）：
  [0,256KiB)    → A的前256KiB
  [256,512KiB)  → B的256KiB
  [512,1024KiB) → A的后512KiB
```

这里有**2条原始记录、3段可见片段**。Write触发判断使用的是前者，即 `numSlices=2`。A还有768KiB可见数据，其源slice也不能作为全无效数据直接删除。

### 2.4 第三次写入：用C完整覆盖这1MiB

再把文件 `[0,1MiB)` 全部改成C，数据写出和映射提交后：

```text
原始记录仍保存： [A, B, C]       → numSlices=3
当前读取只需要： [C]             → 1MiB有效数据
源slice完整容量：1MiB+256KiB+1MiB = 2.25MiB
完全被覆盖的源： A和B            → 1.25MiB
```

**读到的是新内容，不代表旧引用已经从元数据中移除。** 读侧可以根据后写优先规则算出只读C，但这个计算本身不把持久化的 `[A,B,C]` 改成 `[C]`，也不直接删除A/B的对象。

在这个简化例子中，若合并处理了这三条记录，后续过程是：

```text
读取历史[A,B,C]，计算有效布局只有C
  → 按有效布局写出合并结果D（1MiB）
  → 元数据事务校验原历史前缀，替换为[D]
  → 减少A/B/C的源引用
  → 无其他共享引用、无Trash保留等约束时，删除旧源block对象
```

如果合并期间又提交了E，提交逻辑应保留新尾部，结果为 `[D,E]`。因此“逻辑覆盖”“移除历史引用”“删除实际对象”是三个不同阶段。

### 2.5 为什么写完这些数据后，上游没有请求合并

上游 `pkg/meta/base.go`的`baseMeta.Write`：

```go
if numSlices%100 == 99 || numSlices > 350 {
    if numSlices < maxSlices {
        go m.compactChunk(inode, indx, false, false, int(attr.Tier))
    } else {
        m.compactChunk(inode, indx, true, false, int(attr.Tier))
    }
}
```

该条件为99/199/299等确定性计数，不是1%随机概率。达到2500是同步once保护，但本两轮**从未达到任何写触发点**，不是同步保护失效。低记录历史不会因等待时间变长而进入该条件。

代入上面的例子：A/B/C提交后，当前记录数依次为1、2、3，均不满足外层条件。**流程走到了“判断是否合并”，但判断结果一直为否，因此根本没有发出Write侧合并请求。** 停写后没有新的Meta.Write来执行这一判断，等待一分钟或一小时也不会把3条变成99条。

### 2.6 对应到本次4GiB实测：少量记录为什么能留下16GiB历史

再用一个贴近实验量级的简化模型：一个64MiB chunk，每遍完整写入假定形成4条独立16MiB映射，轮与轮完全覆盖，期间没有合并、没有共享引用。

| 完整写入遍数（含初始化） | 每chunk原始记录数 | 当前有效数据 | 源slice完整容量 | 完全被覆盖的历史 |
|---|---:|---:|---:|---:|
| 1 | 4 | 64MiB | 64MiB | 0 |
| 2 | 8 | 64MiB | 128MiB | 64MiB |
| 5 | 20 | 64MiB | 320MiB | 256MiB |

20条记录仍远低于第一次99条触发点，却已引用5倍于有效数据的源容量。chunk的64MiB限制的是文件**逻辑地址范围**，不是历次覆盖写的源容量之和。

将同样的五代完整覆盖模式扩展到64个chunk：

```text
当前逻辑数据：64 × 64MiB  = 4GiB
全部源容量：  64 × 320MiB = 20GiB
覆盖历史：    64 × 256MiB = 16GiB
```

这里“每遍4条、最后20条”只是讲解模型，**不是对fio的16MiB请求和slice个数做一一对应**。真实R01/R02每chunk是9～30/10～27条；20GiB源引用和16GiB历史来自实际映射核算。两者说明同一件事：**以记录数量为条件的触发，在少量大slice覆盖后可能还没到门槛，但无效历史容量已经很大。** 源容量也不等同于含压缩、副本/EC等因素的Ceph raw used。

代码对照：固定上游`pkg/vfs/writer.go`的`flushData`、`commitThread`和`pkg/meta/base.go`的`baseMeta.Write`。上述调用链和数据/映射区别已在本报告展开，不依赖额外的内部代码阅读文档。

读侧缓存未命中且>=5条原始/可见映射可以请求合并；显式compact/GC也可触发。两轮执行器先写、再冷期、再人工维护/CRC；trace证明没有合格读触发请求，不把“没有request”单独解释成“没有任何用户读”。

**根因范围：低记录数普通覆盖写缺少停写后的后续合并机会。** busy丢请求虽可另行复现，但不发生在这两轮；Copy/Truncate/打洞和全局元数据静默策略也不是这两轮证明必须改造的部分。

## 3. 修复提议

### 3.1 改动范围和应用方式

实现补丁仅修改`pkg/meta/base.go`并新增`pkg/meta/idle_write.go`，+191/-19；测试单独放在0002。没有新CLI、元数据格式、跨引擎reader接口、busy请求队列或Copy/Truncate/打洞通知。原Write触发条件保持不变。

```sh
REPORT=/absolute/path/to/juicefs-idle-written-chunk-reclamation
git apply "$REPORT/patches/0001-meta-compact-written-chunks-after-idle.patch"
git apply "$REPORT/patches/0002-meta-test-written-chunk-idle-compaction.patch"
```

只对前述干净固定基线按序应用。补丁含作者、日期、说明和署名；**没有`--idle-compact-delay`参数**，一分钟是当前提案的固定策略，不是生产回收SLA。

### 3.2 登记、检查和重试

成功`engine.doWrite`后，若chunk有多条记录则登记`(inode, index)`；已有登记项后续每次成功Write均更新代次和ready，即使记录数已变少。可写session且`NoBGJob=false`才启用。

每个chunk一分钟没有**本客户端的成功Write**后有检查机会；其他chunk的IO、用户Read不重置它。一个串行session worker每秒tick至多处理一个到期chunk，当前客户端有任意compactor时先让出，避免另起无界并发。

worker预留原compacting槽，调用现有`doRead`取得原始历史，不通过公开Read触发合并。记录数不超过1000时，比较原始非hole引用长度与latest-wins有效长度；确认没有覆盖历史才出队。发现覆盖则复用原单批合并及该快照。成功合并不立即出队，随后再检查确认；读取、对象或提交失败及未确认完成时保留待办，从实际完成时刻再冷却一分钟。

这里比较的长度仅用于判断是否有覆盖，**不是源slice完整容量统计，也不直接决定对象可否删除**。非nil空列表或ENOENT可判无工作；nil/读取失败不能当作干净。超过1000条时不额外对全历史buildSlice，仍尝试原有限单批，并不保证所有历史布局最终清空。

### 3.3 新写入和对象安全

检查期间不提前移除待办。探查后、开始对象合并前核对代次；结算时再次核对。若同chunk有新Write，则保留其更新的ready，不让旧检查删除新工作。若新Write发生在对象处理阶段，继续依赖原元数据提交的origin前缀校验保留并发尾部，再由后续检查处理。

`compactChunkOnce`只提取原单批主体：普通调用仍自行读取，idle调用复用探查快照；原`skipSome`、最多1000条单批、布局、对象重写及引用删除规则保留。普通force在本批释放槽后才递归，避免外层defer误删后继任务槽；idle自身负责释放槽，不重复释放。

流程仍为：有效数据重写→原事务前缀校验/替换、保留尾部→减少源引用→满足原删除条件后删block。共享引用、TrashDays及MaxDeletes仍约束删除；不能越过这些条件强删旧对象。提交失败的孤立产物仍按上游语义处理。

### 3.4 成本和适用边界

- 待办为进程内有界map，最多65536个chunk；选取时在原metadata mutex内扫描map，成本O(pending)。满时保留已登记项、限频告警，新增未登记项没有兜底发现。
- 后端`doRead`仍可能全量读取KV/SQL value或Redis列表；1000限制是单批规划上限，不是RPC读取字节、内存或全步骤CPU硬上限。
- 单worker和busy让出不等于带宽限速或零前台竞争；批次开始后，前台读写与其他普通合并可以同时发生。持续后端错误会每分钟重试。
- 新worker纳入原`sessWG`；CloseSession会等待在途检查/批次退出。但已开始的对象回调、提交和不响应ctx的后端读取沿用原取消边界，没有新增硬关闭期限，也没有改造所有普通compactor生命周期。
- 只跟踪本进程成功普通Write；不保证跨重启恢复、其他客户端历史、非Write修改或溢出遗漏。它不是全卷历史扫描器，不能声称所有历史最终回收、完全无成本或绝对无新问题。

## 4. 已验证和待验证

本地三后端36专项×3 race通过；真实timer＋对象用例不依赖配置注入或合成时间，使用一分钟生产等待，CRC/源删除通过。相同公开操作的上游负控在75秒后失败于缺触发断言。

2026-10-10，同一候选已完成**两轮独立真实TiKV/Ceph短验证**：不读取用户数据、不人工compact/GC，历史引用自动收敛至0、有效引用4 GiB，随后全量CRC通过；另一次前后台交叠验证观察到同chunk新Write、代次保留及后续自动回收。完整方法、数据和实际负载偏差见[test-report](test-report.md)。

扩大客户端race在上游/候选都失败，不能声称全套race无问题。长期运行、近容量扫描成本、生产前台延迟/吞吐回归和慢后端关闭边界仍未完整验收；进行中的两小时顺序覆盖写也不预先记PASS。此补丁仍是针对已确认原因的窄范围提案，短功能通过不等于生产可用。
