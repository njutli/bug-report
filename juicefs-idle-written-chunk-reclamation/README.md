# JuiceFS覆盖写停写后的历史回收：问题与修复提案（RFC）

[English](README.en.md) · 基线：JuiceFS v1.4.1，commit `0b90c7db5a929ae6adc5faad948d108efd2c99f9`。

## 报告内容

我们在普通JuiceFS挂载目录里写入4 GiB数据，再对同一批文件完整覆盖写四遍，累计写入20 GiB。随后停止读写，等待60分钟。上游版本的Ceph池仍比测试前多占用20 GiB；打上所附补丁后，同样的测试最终只多占用4 GiB，与文件大小一致。

我们想请教：如果覆盖写后的slice映射记录数还没达到合并门槛，随后也不再读写，是否还有后台机制来回收旧数据？还是为了减少合并开销，有意保留这些历史？附上的补丁尝试用一个有数量上限的待办表，记下本客户端写过且需要检查的chunk，停写后再检查，并沿用原有合并和删除流程回收旧数据。

## 文档分布

| 材料 | 内容 |
|---|---|
| [bug-report.md](bug-report.md) / [English](bug-report.en.md) | 环境、最简复现命令、原因分析及修复提议 |
| [test-report.md](test-report.md) / [English](test-report.en.md) | 测试步骤、结果和原始记录 |
| [实际负载脚本](reproduce/juicefs-overwrite-manual-check.sh) | 生成fio日志和 `space.log`，不生成JSON |
| [实际外层执行脚本](reproduce/lt002-plain-mount-ab.sh.txt) | 调用负载脚本并生成前后JSON；现场原文件，仅供核查 |
| [patches/](patches/) | 一个RFC实现补丁、独立测试补丁及基线清单 |
| [raw-test-data/](raw-test-data/README.md) | 两版本fio／容量记录，以及0002专项回归和上游负对照日志 |
| [SHA256SUMS](SHA256SUMS) | 文件校验清单，可用 `sha256sum -c SHA256SUMS` 检查 |
