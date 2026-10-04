# JuiceFS 原生 compaction 忙时漏处理：最小修复

2026-09-29；现场验证进展更新至2026-10-04 13:30（北京时间）。 [English](README.en.md)

**修复候选只修改 `pkg/meta/base.go`，新增 42 行、删除 5 行。**普通合并因并发门或同 chunk 忙而被跳过时，按 chunk 合并保存待办；已有合并释放槽位后，继续执行一次原普通批次。当前已有真实集群短时验证，不代表生产或24/72小时长稳验收完成。

## 两份补丁

| 补丁 | 内容 |
| --- | --- |
| [0001-meta-retry-compaction-after-busy-admission.patch](patches/0001-meta-retry-compaction-after-busy-admission.patch) | 原生修复，1 文件，+42/-5 |
| [0002-meta-test-busy-compaction-retries.patch](patches/0002-meta-test-busy-compaction-retries.patch) | 独立回归与实际对象测试，2 个测试文件，+621；无依赖变更 |

两份都带作者、日期、标题、commit message、diffstat 和 base-commit。

在干净 JuiceFS **v1.4.1 / `0b90c7db5a929ae6adc5faad948d108efd2c99f9`** 的源码根目录应用：

```sh
REPORT=/absolute/path/to/juicefs-budgeted-idle-reclamation
git am "$REPORT/patches/0001-meta-retry-compaction-after-busy-admission.patch"
git am "$REPORT/patches/0002-meta-test-busy-compaction-retries.patch"
```

## 与之前 V2/TiKV 补丁的关系

`juicefs-idle-compaction-reclamation/revised-fix-v2/budgeted-reclamation.patch` 是旧的扫描维护方案，**不是最小原生修复，也没有包含后来的 TiKV 预读预算修改**。叠加那次 TiKV 修改也不会使它变成本次原生修复。

本目录已改为原生补偿方案：没有新增扫描、定时 worker、CLI 参数、收益策略或元数据格式；TiKV 扫描代码没有改动，因此不需要那份 TiKV 增量。直接从固定原版应用本目录两份补丁即可。

## 报告与验证

- [问题、根因与修改说明](bug-report.md) / [English](bug-report.en.md)
- [代码流程与补丁详解](code-flow.md)：读写触发调用树、关键函数/文件/行号、事务与对象回收、忙时补偿和槽位所有权。
- [测试报告与复验命令](test-report.md) / [English](test-report.en.md)
- [原始证据索引](raw-test-data/README.md)

同一套测试在原版上 **13 个目标用例预期失败，9 个负控通过**；修复后 **22 个叶子用例 × 3 次 race = 66 次通过，0 跳过**。覆盖 memkv、SQLite、隔离 Redis，以及实际 `vfs.Compact` 的内容/CRC 和源对象删除。通用构建、选定既有引擎回归通过；完整 meta core 因隔离环境缺少真实 TiKV PD 未通过。

现场补充：完全不带自研补丁的上游版也出现停写后的历史引用残留；B-catchup＋本候选在128 GiB数据集的两小时randrw、randwrite场景中，分别于停写约2小时34分、3小时05分首次回到最小历史引用，随后全量CRC通过。观察中没有读取用户文件、手动compact或GC。64 GiB顺序覆盖写约1小时45分时触及容量安全线停止，完整回收与最终CRC尚未完成。详见[现场验证](test-report.md#field-validation)。

本修复只补偿当前客户端接收到的忙时请求。待办不持久化；每次补偿使用原普通批次，不强制全部历史合并为一个 slice。持续过载的容量上界、前台性能非劣性、24/72小时长稳及跨重启恢复仍未验收；不能宣称所有空间回收问题均已解决。

在本报告目录核对文件与测试结果：

```sh
python3 tools/verify.py
python3 tools/verify.py --source /absolute/path/to/patched-juicefs
```
