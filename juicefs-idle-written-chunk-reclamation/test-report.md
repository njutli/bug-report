# 最简实测：普通挂载下的上游/RFC空间回收对照

## 1. 目标与方法

验证：**对同一批文件反复覆盖写后停止读写，比较上游版本和补丁版本能否自动回收旧数据。**

客户端 `node2` 依次测试上游版本和补丁版本，使用同一TiKV/Ceph卷，JuiceFS挂载点为 `/mnt/juicefs`。上游基线为v1.4.1，commit `0b90c7db5a929ae6adc5faad948d108efd2c99f9`；补丁版本验证本文所附RFC处理方案。

- 每侧新建独立16×256 MiB文件，共4 GiB。
- bs=4 MiB初始化一遍，再bs=16 MiB完整覆盖四遍；实际每遍4 GiB，总计20 GiB。
- fio：16 jobs、psync/QD1、direct=1、fallocate=none、refill_buffers=1、end_fsync=1；后四遍禁止新建文件。
- 卷/挂载：BlockSize=256 KiB、TrashDays=0、cache-size=0、writeback/`async_dio`关闭、MaxUpload=150、MaxDeletes=10、NoBGJob=false、backup-meta=0。
- 写前、每遍结束及停写后每5分钟记录 `df -h` 和 `ceph df detail`；每侧停写观察60分钟。
- 不读取文件内容，不做CRC、人工compact/GC、文件删除或逐slice观测。
- 上游测试文件保留，补丁测试另建目录；每轮都用测试前后的容量占用记录相减，算出本轮多占用了多少空间。

完整外层原文件为[lt002-plain-mount-ab.sh.txt](reproduce/lt002-plain-mount-ab.sh.txt)，负责版本切换，以及测试开始前和停写观察结束后的JSON容量采集；它调用[juicefs-overwrite-manual-check.sh](reproduce/juicefs-overwrite-manual-check.sh)执行覆盖写测试。

内层脚本在JuiceFS挂载目录下新建独立测试子目录，fio只初始化和覆盖写该子目录中的16个测试文件。`fio-0.log`～`fio-4.log` 保存五遍写入的运行结果；`space.log` 保存 `df -h` 和 `ceph df detail` 的输出，记录文件系统及Ceph的容量变化。日志保存在被测JuiceFS卷之外。

[复现步骤](bug-report.md#2-最简复现步骤)区分流程示例和这两份实测原文件。这里的数据来自真实执行，不是根据流程示例重新生成的。

## 2. 实测结果

| 项目 | 上游v1.4.1 | 所附RFC方案 |
|---|---:|---:|
| 逻辑文件集 | 4 GiB | 4 GiB |
| 累计用户写入 | 20 GiB | 20 GiB |
| fio结果 | 五遍均成功，80个job结果均error=0 | 同左 |
| 停写观察 | 60分钟，12次采样 | 同左 |
| 本轮新增的容量占用 | **20 GiB** | **4 GiB** |
| 比当前文件大小多占用的空间 | **16 GiB** | **0 GiB** |

本文的容量占用指Ceph池 `juicefs-data` 中保存的数据量，不包括副本或纠删码增加的额外空间。每轮多占用了多少空间，用测试结束和开始时记录的字节数相减：

```text
上游：446177189292 - 424702352812 = 21474836480字节 = 20 GiB
RFC ：450472156588 - 446177189292 =  4294967296字节 =  4 GiB
```

上游版本在60分钟内没有出现容量占用下降。补丁版本每五分钟的记录显示，停写后约10～15分钟，容量占用已接近最终值；60分钟结束时确认只比测试前多占用4 GiB。每五分钟观察一次，不能确定精确到秒的回收完成时间。

**结论：停止读写后，补丁版本自动回收了覆盖写产生的旧数据，最后新增的容量占用与当前文件大小一致。** 本轮只观察空间变化，未做CRC或逐slice删除检查。

## 3. 证据与核查

| 证据 | 内容 |
|---|---|
| [上游版本](raw-test-data/upstream/) | 5份fio日志、`before.json` / `after.json` 容量记录、`space.log` 空间观察日志 |
| [补丁版本](raw-test-data/patched/) | 同上 |

`fio-0.log` 是初始化，`fio-1.log`～`fio-4.log` 是四遍完整覆盖写；`space.log` 包含写入前、每遍结束和停写后每五分钟的观察。JSON容量记录保留精确字节数，用于核算上表的20 GiB和4 GiB。文件均直接展开，内容与原始记录相同，详见[数据索引](raw-test-data/README.md)。

## 4. 0002自动化测试结果

0002是独立测试补丁，不参与客户端正常构建。以下专项回归检查合并时序、并发写入、失败重试、会话关闭、待办上限，以及自动合并后的内容和旧对象删除；与前面的TiKV/Ceph容量实测分开记录。

本地测试环境：Go 1.26.0，Redis 8.0.5专用测试实例。

专项回归命令：

```sh
export COMPACT_RETRY_REDIS_SOCKET=/path/to/dedicated/redis.sock
go test -mod=readonly -p 1 -race -count=3 -timeout=300s -run '^TestIdleWrite' -json ./pkg/meta
```

命令在应用补丁后的JuiceFS源码根目录执行。测试直接调用内部接口，不挂载文件系统：机制测试使用memkv、SQLite或Redis元数据引擎及模拟对象回调；自动对象用例使用SQLite和内存对象存储，复用真实`vfs.Compact`。所有用例均包含在下面的专项回归统计中。

`redis.sock`是已启动的专用Redis实例的Unix socket路径，不是数据库文件。测试初始化会清空该实例的DB 0；不设置该变量时，Redis子测试会跳过。

| 测试 | 结果 | 原始日志 |
|---|---|---|
| 专项回归 | 15个顶层测试、36个叶子用例，各执行3遍；108次通过，0失败、0跳过，无race报告 | [focused-race.log](raw-test-data/automated/focused-race.log) |
| 未修改上游的自动对象负对照 | 等待约75秒后报告`IDLE_WRITE_TRIGGER_MISSING records=3`，按预期失败，说明该用例能识别缺少停写后自动触发的现象 | [stock-negative.log](raw-test-data/automated/stock-negative.log) |

上游负对照不应用0001，只放入0002中的`idle_write_fixture_test.go`和`idle_write_automatic_test.go`，执行：

```sh
go test -mod=readonly -p 1 -race -count=1 -timeout=300s -run '^TestIdleWriteAutomaticObjects$' -json ./pkg/meta
```

这里只记录`TestIdleWrite`专项结果；内存对象测试不替代前面的真实TiKV/Ceph容量验证。

## 5. 结论边界

- 本实验比较的是 **上游版本多占用20 GiB、补丁版本多占用4 GiB**，没有测试吞吐收益，也没有规定回收必须完成的时间。
- 所附补丁新增的后台检查可能因本客户端其他chunk持续合并而长期推迟；满表遗漏、扫描锁竞争和实际合并读写成本仍需评估。
- 希望讨论触发策略与资源开销的取舍。
