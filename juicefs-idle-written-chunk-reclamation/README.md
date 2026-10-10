# JuiceFS覆盖写停写后的历史回收：问题与修复提案

[English](README.en.md) · 基线：JuiceFS v1.4.1，commit `0b90c7db5a929ae6adc5faad948d108efd2c99f9`。

## 报告内容

反复覆盖写后，文件逻辑大小不变，但旧slice仍被元数据引用；如果记录数未达到现有合并触发条件，随后停写且不再读取，历史可能持续保留。我们在TiKV/Ceph两轮实测中，4 GiB文件引用20 GiB源数据，停写60分钟仍未变化；人工合并后引用回到4 GiB、CRC通过。

建议为成功写入过的chunk增加有界的后台检查，在该chunk静默后复用现有合并、提交和删除流程。候选已完成本地测试、两轮真实后端短验证及前后台交叠正确性验证；这是供社区讨论的提案，不代表长期稳定性或生产验收完成。

## 文档分布

| 材料 | 内容 |
|---|---|
| [bug-report.md](bug-report.md) / [English](bug-report.en.md) | 问题现象、根因、建议实现及适用边界 |
| [test-report.md](test-report.md) / [English](test-report.en.md) | 测试环境、方法、结果、复验命令及未验证项 |
| [patches/](patches/) | 0001实现补丁、0002独立测试补丁及基线清单 |
| [raw-test-data/](raw-test-data/README.md) | 原始测试日志、根因审计和候选短验证复核摘要 |
| [field-validation.md](field-validation.md) | 真实后端补验计划与覆盖边界 |
| [tools/verify.py](tools/verify.py)、[SHA256SUMS](SHA256SUMS) | 提交材料的完整性校验；用法见测试报告 |
