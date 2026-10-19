# Bug Report

| Bug | 项目 | 状态 |
|-----|------|------|
| [juicefs-vfs-flush-dispatch-race](juicefs-vfs-flush-dispatch-race/) | JuiceFS VFS 异步 slice ID 分配导致满 block 漏派发 | 补丁+测试就绪，社区已检视，内部使用。后续社区通过重构处理该问题 https://github.com/juicedata/juicefs/issues/7439 |
| [juicefs-idle-written-chunk-reclamation](juicefs-idle-written-chunk-reclamation/) | JuiceFS覆盖写停写后，旧数据未自动回收 | 已完成TiKV/Ceph最简复现及补丁对照：停写60分钟后，上游新增占用20 GiB，补丁版本为4 GiB；附RFC补丁、自动化测试及原始数据 |
| [juicefs-randrw-io-amplification](juicefs-randrw-io-amplification/) | JuiceFS小块随机读写约23倍对象IO放大 | 30分钟随机读写和单文件最小复现已完成；附测试方法与原始数据，询问配置、用法和合并策略的设计取舍 |
