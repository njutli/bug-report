# V3实现流程、依赖与观测指标

以本包最终diff及固定源码为准；不将V1扫描方案、原生V2和本次V3混称一个补丁。

## 1. 调用流程

```text
baseMeta.Write -> engine.doWrite 成功
  -> noteIdleCompactWrite(inode, chunk, records)
     多条记录首次加入；已有条目更新generation
  -> 原有Write阈值触发普通compact（V2忙时补偿仍保留）

NewSession -> startIdleCompact -> ticker -> idleCompactStep
  -> 当前meta IO安静且无activeIO
  -> 公平取一个到期跟踪条目
  -> 无普通compacting/compactTodo；预留同chunk槽位
  -> engine.doRead原始映射 -> latest-wins判定覆盖历史
  -> 再确认前台未恢复
  -> compactChunkAdmittedWithFinish（原普通合并主体）
     -> 原批次选取/对象合并/引擎CAS替换/引用更新
     -> 槽位释放前再次doRead检查剩余历史
  -> generation变化/剩余历史/失败：保留并退避
     否则移出队列；releaseCompactSlot沿用V2原子交接
  -> 原引用清理及对象删除释放不再被引用的历史
```

`Read/Write`用`beginIdleCompactIO/endIdleCompactIO`更新当前客户端元数据IO静默时钟。观察工具读取原始元数据不应调用用户Read，否则可能独立触发原合并。

## 2. 修改文件

| 文件 | 作用 |
|---|---|
| `pkg/meta/base.go` | Write跟踪、Read/Write静默门、session生命周期、带结束确认的普通批次及槽位释放 |
| `pkg/meta/idle_compact.go` | 新增有界队列、写代次、串行worker、覆盖判断、退避、观测指标 |
| `pkg/meta/config.go` | `IdleCompactDelay`及SelfCheck |
| `cmd/flags.go`、`cmd/mount.go` | CLI参数及mount配置传递 |
| `docs/en/experimental-idle-compaction.md` | 候选行为及限制 |

V3测试文件为`idle_compact_test.go`、`idle_compact_objects_test.go`、`idle_trigger_regression_test.go`及`cmd/idle_compact_flags_test.go`。依赖V2测试fixture，不改变go.mod/go.sum。现场另外保留B-catchup的`pkg/vfs/writer.go`，该文件不是V3改动。

## 3. 参数与指标

`--idle-compact-delay=2m`：显式开启；默认0关闭；负值归零，正值不足1秒提升至1秒。常用2分钟配置下，ticker间隔1秒；串行处理至多每tick一个新批次，慢批次会延后下一批，**不是固定回收带宽**。

| 指标 | 含义 |
|---|---|
| `juicefs_idle_compact_pending_chunks` | 跟踪条目数，包含当前检查中的条目 |
| `juicefs_idle_compact_queue_checks_total` | 被调度检查次数；不等于实际对象重写次数 |
| `juicefs_idle_compact_queue_attempts_total` | 进入原普通合并主体次数；不等于成功次数 |
| `juicefs_idle_compact_queue_overflow_total` | 达到65,536上限后的未新增跟踪次数；非零表示覆盖不完整 |

实际回收必须核对完整逻辑覆盖、完整slice引用及完全被覆盖历史，并检查上传、pending和池空间。不能只凭attempts或compact计数判定成功；也不能将所有普通compaction归因于新增idle worker。

## 4. 安全语义

检查前占槽避免同chunk compactor改变观察快照；写代次避免旧任务完成丢掉新写。普通批次/CAS/共享引用/回收站规则不改，未增加“直接删除过时对象”的捷径。退出停止新调度，等待在途处理返回；不强制打断对象RPC。由于状态不持久化，旧历史必要时仍需受控维护。
