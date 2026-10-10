# 测试报告：本地验证及真实TiKV/Ceph短功能验证

## 1. 新候选的执行结果

Go1.26.0 linux/amd64，GOTOOLCHAIN=local、GOPROXY=off、GOMAXPROCS=4；依赖只读，独立源码树。Redis用独占Unix socket，fixture会Reset测试库，不能连接业务实例。

| 日志 | 实际结果 |
|---|---|
| focused-race | 36叶子×3=108PASS，0FAIL/SKIP，无race |
| stock-negative | 同一自动对象测试上游FAIL：75秒后3条记录仍在，`IDLE_WRITE_TRIGGER_MISSING` |
| clients | MemKV/SQLite/Badger顶层及包PASS，非race |
| clients-race | 候选扩大客户端包FAIL，有race |
| stock-clients-race | 纯上游相同扩大客户端包FAIL，有race |
| build | 通用Go开发构建PASS |

扩大客户端竞争涉及共享format重初始化、异步文件删除和删除worker状态，与长期复用测试客户端有关。日志保留，不把叶子PASS当作顶层PASS，也不声称本补丁修复所有生命周期问题。这里没有通过修改原测试或加入全局关闭重构来消除该独立问题。

## 2. 专项映射

- 2/5/30/98条覆盖：一分钟前无合并，到期处理，再确认出队；三后端。
- 每chunk五代完整64MiB覆盖：20条16MiB映射、320MiB引用，原阈值不触发，idle合并为64MiB；三后端。此项为元数据fixture，不是320MiB对象IO压力。
- 普通99条快照后再追加5条：原任务保留6条，idle随后回收；三后端。
- idle对象回调期间追加、干净读取后追加：generation保留新工作。
- 非重叠有效映射：不重写；busy时让出并保留。
- 原始读取EIO、对象失败、提交EINVAL：保留、冷却、恢复。
- 2105条有限积压：三批原规划及一次干净确认收敛。
- oldest-ready调度、失败后让其他ready项前进、65536cap及满队列更新已有代次。
- readonly/no-bgjob/取消、slot释放、worker在途关闭等待。
- 慢回调失败后冷却从完成开始，而非启动时刻。

## 3. 真实timer与对象负控

`TestIdleWriteAutomaticObjects`在上游和候选源码原样编译。真实NewSession，无新配置参数；Write三条部分覆盖映射，没有公开Read或手工compact帮助触发。

对象先由真实CachedStore写入并Head确认。候选在生产的一分钟delay后调用真实vfs.Compact；冻结原始映射一条后才读98304字节，核对完整内容/CRC和每个旧block对象删除。

上游观察75秒仍3条记录，失败在预期缺触发断言，不是编译/连接错误。候选三轮均PASS。单次65～75秒量级的用例不是长稳，也不验证Ceph时延或吞吐。

## 4. 复验命令

```sh
# 干净固定上游按bug-report应用实现和测试补丁，独占Redis已启动：
export COMPACT_RETRY_REDIS_SOCKET=/path/to/dedicated/redis.sock
GOTOOLCHAIN=local GOPROXY=off GOMAXPROCS=4 go test -mod=readonly -p 1 -race -count=3 -timeout=300s -run '^TestIdleWrite' -json ./pkg/meta
GOTOOLCHAIN=local GOPROXY=off GOMAXPROCS=4 go test -mod=readonly -p 1 -count=1 -timeout=300s -run '^(TestMemKVClient|TestSQLiteClient|TestBadgerClient)$' -json ./pkg/meta
```

上游负控在另一干净源码仅复制测试补丁中的 `idle_write_fixture_test.go`、`idle_write_automatic_test.go`，运行 `-run '^TestIdleWriteAutomaticObjects$' -race -count=1`，预期上述FAIL；不要放入依赖新增接口的idle_write_test.go。

材料校验命令（不运行集群负载）：

```sh
python3 tools/verify.py
python3 tools/verify.py --upstream /path/to/clean/juicefs-v1.4.1
```

第二条只在独立临时副本重放补丁及检查逐阶段hash，不修改提供的上游目录；它不重新执行Go测试或真实后端测试。内部阅读文档不属于提交材料，材料校验不依赖它。

## 5. 根因证据与候选验收分开

`raw-test-data/cause/`是R01/R02真实TiKV/Ceph无新增回收策略的原因证明及独立审核，不是候选测试。原始冷期/维护归档SHA256和逐chunk来源列在JSON。人工维护不记自动回收。

候选真实后端短功能结果见下一节；原因、候选自动回收和前后台交叠分别统计，不把人工合并的通过记作自动通过。

## 6. 真实TiKV/Ceph短功能验证（2026-10-10已完成）

### 6.1 环境、版本和共同方法

Linux客户端、TiKV元数据及Ceph对象后端。基线为前述上游v1.4.1 commit，仅加本包0001及独立事件观测，不含其他回收方案或B-catchup。实现补丁SHA256为`776a542192a63595c5a5dbd039a03d16b601b24fa285a6e65cf057118ca10a5a`；观测二进制SHA256为`05d0417f90282e4b15aa123f5e52b81b0bfd2bf1756977827f74f929e5293dcb`。两轮同一二进制，一分钟静默未缩短。

- 每轮独立16×256 MiB，共4 GiB；bs4M初始化一遍，再bs16M完整覆盖四遍，共20 GiB用户写入。16 jobs、psync/QD1、direct=1、fallocate=none、refill_buffers=1、每遍end_fsync=1；后四遍禁止新建文件，不使用time_based或loops替代明确的四遍。
- fio写入携带CRC32C/256 KiB校验头、do_verify=0；每遍核对逐job error、bytes、IO数和文件身份。先无读观察并冻结自动回收证据，才全量CRC，避免读取触发原生合并改变归因。
- BlockSize256KiB、TrashDays0、读缓存/writeback/async_dio关闭、MaxUpload150、MaxDeletes10、NoBGJob=false、BackupMeta0；不执行人工compact、GC、删除测试文件或改后端配置。
- 统计source size按slice ID去重；完全覆盖历史只计无当前可见片段的源slice完整size。删除回调成功与池空间作为交叉证据，不能把累计删除产物容量当成净物理释放量。

### 6.2 结果

| 项目 | 首轮独立验证 | 第二轮独立重复A | 前后台交叠B |
|---|---:|---:|---:|
| 用户写入 | 20 GiB | 20 GiB | 4 GiB再覆盖＋128 MiB目标写 |
| 成功Meta.Write | 1226 | 1187 | 193（B段） |
| 成功合并提交 | 66，全部idle | 66，全部idle | 61 idle＋4 native（B段） |
| 自动冻结引用/完全覆盖历史 | 4/0 GiB | 4/0 GiB | 4/0 GiB |
| 过期slice删除成功 | 1228 | 1189 | 累计1447（A＋B） |
| 停写至证据冻结 | 641.903秒 | 641.956秒 | 348.235秒 |
| 冻结时pending/compacting及在途上传/删除 | 均0 | 均0 | 均0 |
| 冻结后全量CRC | 4 GiB PASS，37.056秒 | 4 GiB PASS，36.785秒 | 4 GiB PASS，37.196秒 |

第二轮A的无读快照显示引用/历史为19.9375/15.9375→17.25/13.25→13.75/9.75→4/0 GiB。首轮未取得有效停写瞬间快照，不声称首轮也有相同曲线。冻结间隔包含轮询、采集和复核，不是通用回收SLA。

两轮写入和CRC均error=0，观测序号无缺口/丢失，最终16文件身份不变；各私有挂载正常卸载。交叠轮64次健康采样均HEALTH_OK、6 OSD up/in、BlueFS无spill。这支持低记录数普通覆盖写场景下的短功能修复，不证明长期满压容量有界或生产零性能回归。

### 6.3 交叠实际证明了什么

选定idle对象处理窗口22.005秒，期间同chunk一次成功Write令generation从1变2。旧批次结算保留待办；后续自动批次的来源包含这次新Write及旧合并产物，最后generation=2的检查确认clean，CRC正确。

同步进行了128 MiB目标写、另两文件各120秒且4 MiB/s的顺序读/随机读；三项error=0。目标写clat P99为21.627 ms，两读为233.832/219.152 ms。未做相同负载的上游延迟A/B，不能据此宣布无性能回归。

原计划把size=64M/loops=2描述为同区间两遍，但实际128 MiB目标写落到相邻chunk0、chunk1各64 MiB；选中chunk0有一次真实交叠Write，**不宣称同chunk两次写已经覆盖**。B含用户读取和4次原生合并，不能把B全部回收只归因idle；无读因果证据来自前两轮。

### 6.4 采集修正与证据

首轮初始执行器把元数据快照采到旧子树。该旧快照已排除；五遍fio目录及实际写入正确，没有重跑写入。仅修正显式子树参数、恢复观察，并核对新快照inode与本轮文件及完整trace一致；二进制不变。

[field-short复核摘要](raw-test-data/README.md)分别保存首轮自动审核/CRC/收口、独立重复A、交叠B及最终审核。首轮完整自动归档SHA256为`4b377244476d4d0cecd335ae7e38934facee6997ff4885cb077c4e3661de2553`；A为`52344e9039c9580e53f212a3c0b15c4015dbdda862a88930266babbf2bb37887`，B为`b9619130431c3ec5bb2bf9404a2eba9e55594f43706a885197cff00330db964f`，A/B最终收口为`8723354550763f069a63d1d324f37c52ae40a2d88beedaee22034c2fe5b8f435`。完整脱敏归档留存，可按需提供；本材料附小型独立复核摘要，不附凭据或用户数据内容。

## 7. 尚未证明的内容

近65536项的扫描持锁/内存成本、持续故障重试成本、慢后端关闭时间、生产前台吞吐/延迟回归和24/72小时长稳仍未完整验收。跨重启、其他客户端、非Write操作与溢出发现本来就不在实现承诺范围，不能靠短轮PASS消除这些限制。

最新候选的两小时顺序覆盖写自动回收及CRC还未签收，本报告不预先记PASS。后续边界见[field-validation.md](field-validation.md)。
