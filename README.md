# Bug Report

| Bug | 项目 | 状态 |
|-----|------|------|
| [juicefs-vfs-flush-dispatch-race](juicefs-vfs-flush-dispatch-race/) | JuiceFS VFS 异步 slice ID 分配导致满 block 漏派发 | 补丁+测试就绪，社区已检视，内部使用。后续社区通过重构处理该问题 https://github.com/juicedata/juicefs/issues/7439 ；已上报 https://github.com/juicedata/juicefs/discussions/7427 |
| [juicefs-idle-written-chunk-reclamation](juicefs-idle-written-chunk-reclamation/) | JuiceFS覆盖写停写后，旧数据未自动回收 | 已完成TiKV/Ceph最简复现及补丁对照：停写60分钟后，上游新增占用20 GiB，补丁版本为4 GiB；附RFC补丁、自动化测试及原始数据；已上报 https://github.com/juicedata/juicefs/discussions/7700 |
| [juicefs-randrw-io-amplification](juicefs-randrw-io-amplification/) | JuiceFS小块随机读写约23倍对象IO放大 | 30分钟随机读写和单文件最小复现已完成；附测试方法与原始数据，询问配置、用法和合并策略的设计取舍；已上报 https://github.com/juicedata/juicefs/discussions/7713 |
| [ceph-get-worker-lock-race](ceph-get-worker-lock-race/) | Ceph `NetworkStack::get_worker()` 锁外自增导致 worker 分配瞬时聚集 | 已定位并复刻验证：人为放大解锁至自增的窗口后，10 个并发连接 95% 全部落到同一 worker；把自增移入锁内可完全消除，临界区开销无变化。已上报 https://tracker.ceph.com/issues/82667 |
| [ceph-async-worker-role-pools](ceph-async-worker-role-pools/) | Ceph AsyncMessenger 可配置角色分池与多客户端吞吐 RFC | 附5件RFC补丁、12线程写入对照（9527.56 → 11598.22 MiB/s，+21.73%）、CPU／排队数据和测试方法；尚未提交社区 |
