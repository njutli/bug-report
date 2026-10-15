# Bug Report

| Bug | 项目 | 状态 |
|-----|------|------|
| [juicefs-vfs-flush-dispatch-race](juicefs-vfs-flush-dispatch-race/) | JuiceFS VFS 异步 slice ID 分配导致满 block 漏派发 | 补丁+测试就绪，社区已检视，内部使用。后续社区通过重构处理该问题 https://github.com/juicedata/juicefs/issues/7439 |
| [juicefs-idle-written-chunk-reclamation](juicefs-idle-written-chunk-reclamation/) | JuiceFS覆盖写停写后，旧数据未自动回收 | 已完成TiKV/Ceph最简复现及补丁对照：停写60分钟后，上游新增占用20 GiB，补丁版本为4 GiB；附RFC补丁、自动化测试及原始数据 |
