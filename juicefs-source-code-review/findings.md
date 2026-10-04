# JuiceFS 源码检视发现

> 基座：main commit `53835e24`（~86K 行 Go 代码）
> 检视范围：写路径、读路径、元数据引擎（TKV/Redis/SQL）、VFS、对象存储、数据同步、CLI、FUSE、工具
> 共发现 19 项，按重要程度和社区接收可能性排序

## 高优先级（数据竞争/崩溃/数据错误，修复简单）

### 1. Truncate(0) 整数下溢

- 文件：`pkg/fs/fs.go:1434`
- 问题：`uint32(((length - 1) >> meta.ChunkBits))`，当 `length == 0` 时 `length - 1` 下溢为 MaxUint64，生成无效 chunk index 4294967295
- 影响：SDK/Gateway 路径每次 Truncate(0) 必触发，调用 `InvalidateChunkCache(inode, 4294967295)` 产生无意义查询
- 修复：`if length > 0 { ... }` 包裹
- 触发路径：Go SDK `File.Truncate(ctx, 0)`、`FileSystem.Truncate(ctx, path, 0)`
- 置信度：高

### 2. singleflight.Execute panic 导致等待者死锁

- 文件：`pkg/chunk/singleflight.go:37-43`
- 问题：如果 `fn()` panic，`c.wg.Done()` 不执行，所有 `c.wg.Wait()` 的等待者永久阻塞；`con.rs[key]` 不删除，后续相同 key 的请求也永久阻塞
- 影响：对象存储客户端 bug 或 nil deref 可导致整个读路径卡死
- 修复：`defer func() { c.wg.Done() }()` 或 `defer c.wg.Done()`
- 置信度：高

### 3. juicefs sync 的 srcDelayDel/dstDelayDel 无锁读

- 文件：`pkg/sync/sync.go:2428, 2321`
- 问题：worker goroutine 用 `srcDelayDelMu.Lock()` 保护 `append`，但 `delayDelFunc(src, srcDelayDel)` 和 `for len(srcDelayDel) > 0` 直接读 slice 不加锁。如果 append 触发扩容，主 goroutine 可能读到旧 slice header
- 影响：数据竞争，可能 panic 或读到已释放内存
- 修复：读操作也加 `srcDelayDelMu.Lock()`，或用 `atomic.Pointer[[]string]`
- 置信度：高

### 4. juicefs destroy 的 failed 计数器数据竞争

- 文件：`cmd/destroy.go:194`
- 问题：`var failed int`，8 个 goroutine 并发 `failed++` 无同步
- 影响：Go race detector 会报，ARM 架构可能读到撕裂值
- 修复：`var failed atomic.Int64`，`failed.Add(1)`
- 置信度：高

### 5. wSlice.uploadError 数据竞争

- 文件：`pkg/chunk/cached_store.go:385 vs 508`
- 问题：`Finish` 在持 `f.Lock()` 时写 `s.uploadError`（line 508），upload goroutine 在无锁时读 `s.uploadError`（line 385）判断是否取消
- 影响：goroutine 可能读到 stale 值多重试一次，Go race detector 会报
- 修复：`s.uploadError` 改为 `atomic.Pointer[error]`
- 置信度：高

## 中优先级（崩溃/资源泄漏/安全）

### 6. compactChunk 用 panic 处理 compaction 重叠

- 文件：`pkg/meta/base.go:2860-2868`
- 问题：`skipSome` + `compactChunk` 纯函数组合正确性检查用 `panic`，崩溃整个 FUSE 客户端
- 影响：边界条件异常时所有应用收到 EIO
- 修复：改成 `logger.Errorf` + return（跳过本次 compaction）
- 置信度：中

### 7. prefetcher.do panic 导致永久 key 阻塞

- 文件：`pkg/chunk/prefetch.go:49-55`
- 问题：`p.op(key)` panic 后 `delete(p.busy, key)` 不执行，key 永久留在 busy map，后续相同 key 的 prefetch 被静默丢弃；worker goroutine 退出降低并发能力
- 修复：`defer func() { p.Lock(); delete(p.busy, key); p.Unlock() }()` + panic recovery
- 置信度：中

### 8. ACL Rule.Decode 缺少边界检查

- 文件：`pkg/acl/acl.go:113-132`
- 问题：`uCnt := rb.Get32()` 是 xattr 数据控制的，`make([]Entry, uCnt)` 可分配 ~25GB；buf 不足时 Get32/Get16 越界 panic
- 影响：构造的 ACL xattr 可导致 OOM 或客户端崩溃
- 前提：需要对文件有写权限（设置 xattr），非远程攻击
- 修复：读取 uCnt/gCnt 后检查 `uCnt > len(buf)/6`，加上限
- 置信度：中

### 9. writeback staging 的 stageFailed 数据竞争

- 文件：`pkg/chunk/cached_store.go:431 vs 437`
- 问题：`WithTimeout` 超时后主 goroutine 写 `stageFailed = true`，staging callback 可能仍在运行并读 `stageFailed`。读到 true 会删除已成功 staged 的文件
- 影响：writeback 超时路径可能误删数据
- 修复：`stageFailed` 改为 `atomic.Bool`
- 置信度：中

### 10. juicefs sync 的 os.Exit 绕过 defer

- 文件：`pkg/sync/sync.go:2337`
- 问题：MaxFailure 达到后 `os.Exit(1)` 绕过所有 defer（`wg.Done()`、`checkpointMgr.Stop()`），checkpoint 可能丢失，goroutine 泄漏
- 修复：改用 channel 通知主 goroutine 退出，不直接 os.Exit
- 置信度：中

### 11. Abort 后 upload goroutine 产生孤儿对象

- 文件：`pkg/chunk/cached_store.go:515-525`
- 问题：`Finish` 失败后 `Abort` 调 `Remove()` 删除已上传 block，但未完成的 upload goroutine 可能在 Remove 之后完成上传，创建孤儿对象
- 影响：错误路径资源泄漏，`juicefs gc --delete` 兜底
- 置信度：中

### 12. ListAllWithDelimiter 的 err 变量数据竞争

- 文件：`pkg/object/object_storage.go:248 vs 301/311`
- 问题：`var err error` 被 goroutine 闭包捕获，goroutine 在 `WaitWithTimeout` 期间读 `err`，主循环写 `err`
- 修复：用 channel 或 atomic 传递错误
- 置信度：中

## 低优先级（设计选择/防御性/当前安全）

### 13. flush 派发竞态（已报告社区）

- 文件：`pkg/vfs/writer.go:95-96`
- 状态：已上报 https://github.com/juicedata/juicefs/discussions/7427，社区确认存在，计划做 "more fundamental fix"
- 置信度：高

### 14. doDeleteFileData 遇错即返回

- 文件：`pkg/meta/tkv.go:2413-2425`
- 问题：一个 chunk 删除失败就返回，剩余 chunk 不删，每小时重试
- 影响：清理效率低，不是数据错误
- 修复：改成 continue
- 置信度：低

### 15. 三引擎 slice refcount 初始值不一致

- 文件：`pkg/meta/redis.go, sql.go, tkv.go`
- 问题：SQL 的 compacted slice 初始 refs=1，Redis/TKV 为 0，导致 cleanupSlices 对 refs==0 的处理不同（SQL 调 deleteSlice 删数据，Redis/TKV 调 cleanupZeroRef 只删 metadata）
- 影响：行为差异，最终一致
- 置信度：低

### 16. Redis txn 对无 prefix key 用 panic

- 文件：`pkg/meta/redis.go:1146`
- 问题：防御性检查用 panic 而非 error，崩溃客户端
- 触发条件：极窄（代码 bug 才会传错 key）
- 置信度：低

### 17. Ceph 后端忽略 context

- 文件：`pkg/object/ceph.go`
- 问题：所有方法签名为 `_ context.Context`，RADOS 操作无法超时/取消
- 影响：网络分区时操作挂起，goroutine 泄漏到 RADOS 返回
- 限制：cgo/librados 限制，修复需要异步 API
- 置信度：低

### 18. RootSquash 直接修改 FUSE header

- 文件：`pkg/fuse/context.go:101-107`
- 问题：`ctx.header.Uid = fs.conf.RootSquash.Uid` 直接改 `*fuse.InHeader`，当前安全（go-fuse 不复用 request struct），但未来版本有风险
- 修复建议：拷贝 header 到局部变量再修改
- 置信度：低

### 19. mount 信号处理中 os.Exit 绕过清理

- 文件：`cmd/mount_unix.go:950, 962`
- 问题：SIGHUP 和超时路径用 `os.Exit` 绕过 defer
- 影响：CLI 进程退出即清理资源，容器内可能 goroutine 泄漏
- 置信度：低
