# JuiceFS v1.4.1：小块随机读写产生约23倍对象IO，是否符合预期？

[English](README.en.md) · 基线：JuiceFS v1.4.1，commit `0b90c7db5a929ae6adc5faad948d108efd2c99f9`。

我们在JuiceFS v1.4.1＋TiKV＋Ceph上测试256 KiB随机读写。应用读写各约8 MiB/s，JuiceFS向对象存储发出的读写却各约189 MiB/s。进一步缩小测试后发现：一个64 MiB文件只覆盖两处256 KiB，再读取256 KiB，就能触发一次64 MiB的数据合并和重新上传。

本次希望通过社区了解：这是测试方式或配置需要调整，还是当前合并策略对小块随机覆盖读写的预期取舍？有哪些推荐的配置或使用方式？

| 文档 | 内容 |
|---|---|
| [问题说明](bug-report.md) / [English](bug-report.en.md) | 环境、主要现象、我们对原因的理解及希望社区解答的问题 |
| [测试报告](test-report.md) / [English](test-report.en.md) | 30分钟随机读写和单文件最小复现两组实验 |
| [复现方法](reproduce/README.md) / [English](reproduce/README.en.md) | 实际测试步骤、挂载参数、fio参数和计数采集方法 |
| [原始数据](raw-test-data/README.md) / [English](raw-test-data/README.en.md) | fio输出、测试前后的IO统计数据、slice映射及来源清单 |

读写放大按同一客户端、同一窗口的对象字节与应用字节相除。这里的对象IO尚未包含Ceph纠删码、磁盘日志等底层开销，也不是容量占用的倍数。
