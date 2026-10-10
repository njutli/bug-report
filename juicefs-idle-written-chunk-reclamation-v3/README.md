# JuiceFS V3：补齐停写后的覆盖历史回收触发

2026-10-07（北京时间）。[English](README.en.md)

**这是功能修复候选材料，不是生产全面验收声明。** V3在原生忙时补偿（V2）之上，补齐“覆盖历史存在，但未达到普通合并触发条件”的缺口。离线机制对照及真实TiKV/Ceph短轮验证支持已覆盖场景的自动回收与数据正确性；24/72小时写入验收、跨重启恢复和严格性能非劣性尚未完成。

## 为什么还需要V3

V2保存并重试已经发出、却因繁忙未执行的普通合并请求；**没有产生请求时，V2无任务可重试**。顺序大块覆盖写可以留下大量旧数据，但每个64 MiB chunk仅有少量slice记录，低于写侧触发点。合并快照后追加的少量新写也可能留下同类尾部。

实际V2场景C13中，64 GiB逻辑文件仍引用211.39 GiB slice，其中147.36 GiB在该子树完全被覆盖；剩余有历史的chunk仅6～34条记录，停写后回收停滞。不是“Ceph已经收到删除，只是释放慢”：JuiceFS元数据仍持有旧引用。

V3只跟踪**本客户端成功写过的chunk**，元数据Read/Write安静后有界、串行检查覆盖历史，复用原普通合并和安全引用删除，不进行全卷扫描。

## 材料导航

- [问题、根因与边界](bug-report.md) / [English](bug-report.en.md)
- [实现流程与参数](code-flow.md)
- [测试结果与复验方法](test-report.md) / [English](test-report.en.md)
- [原始证据索引](raw-test-data/README.md)
- [补丁和版本指纹](patches/manifest.json)

## 补丁依赖与应用

底本为JuiceFS **v1.4.1 / `0b90c7db5a929ae6adc5faad948d108efd2c99f9`**。本包复制既有V2补丁作为前置依赖，保留V3已经实测的增量补丁原字节，不混入旧全卷扫描方案。

| 顺序 | 文件 | 性质 |
|---|---|---|
| 1 | `patches/0001-meta-retry-compaction-after-busy-admission.patch` | 既有V2实现依赖 |
| 2 | `patches/0002-meta-test-busy-compaction-retries.patch` | V2测试及V3使用的公共fixture |
| 3 | `patches/0003-v3-idle-written-chunks-on-native-v2.patch` | 本次V3实现增量 |
| 4 | `patches/0004-v3-idle-trigger-regression-tests.patch` | 本次V3回归测试 |

在独立、干净的上述源码根目录：

```sh
REPORT=/absolute/path/to/juicefs-idle-written-chunk-reclamation-v3
git apply "$REPORT/patches/0001-meta-retry-compaction-after-busy-admission.patch"
git apply "$REPORT/patches/0002-meta-test-busy-compaction-retries.patch"
git apply "$REPORT/patches/0003-v3-idle-written-chunks-on-native-v2.patch"
git apply "$REPORT/patches/0004-v3-idle-trigger-regression-tests.patch"
```

V3两份文件是普通diff，不是Git邮件格式，应用时用`git apply`，不要直接用`git am`。已经安装V2实现和测试的源码只应用第3、4份；不要把第3份直接应用到原版。诊断负控源码另见证据索引。

现场程序包含**独立的VFS B-catchup补丁＋V2＋V3**，版本为`1.4.1+2026-07-30.0b90c7d-lt002-idle-written-v3`，SHA256为`c2307d90c9184c7d48a9770c8d775a093671496c5569d0e5f7c81d594d7b3b6f`。B-catchup不是本包回收补丁；本包四份补丁不会生成与现场二进制完全相同的组合。机制缺口在原版和V2均可复现，但真实集群V3数据不能冒充不带B-catchup的等量A/B。

## 使用与验收边界

显式启用`juicefs mount --idle-compact-delay=2m ...`，默认0关闭；只读、`--no-bgjob`关闭新worker。2分钟是本轮验证参数，不是生产最优推荐。队列限65,536个chunk，溢出告警；不发现重新挂载前或其他客户端的旧历史。持续IO不空闲时不会保证新增idle回收；已在途的一批也不会被前台恢复强制取消。

只读核对本包：

```sh
python3 tools/verify.py
```

本次仅整理和核验材料，未启动新实验、修改挂载或集群配置，也未提交/推送GitHub。原V2目录不改动。核心验证仍为“停写后不读取用户文件、不手工compact/GC，先冻结自动回收证据，再全量CRC”。
