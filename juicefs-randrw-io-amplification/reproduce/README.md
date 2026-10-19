# 实际测试方法

[English](README.en.md)

以下说明对应[所附原始数据](../raw-test-data/README.md)，不是另外执行过的一轮测试。每个负载步骤的完整实测命令保存在对应 `argv.json`，fio输出为相邻的 `fio.json`。文中的节点和路径使用变量代称；原始记录保留执行时的参数。

## 1. 环境与挂载

使用JuiceFS v1.4.1，commit `0b90c7db5a929ae6adc5faad948d108efd2c99f9`，编译时启用Ceph支持。TiKV管理文件元数据，Ceph RADOS保存对象，Ceph版本17.2.8、6个OSD、EC 4+2；客户端fio为3.28。

卷参数：BlockSize=256 KiB、TrashDays=0。客户端不启用本地数据缓存、writeback和 `async_dio`，正常后台工作与删除开启。挂载仍可读写，**fio的 `--readonly` 只限制该fio进程；它不阻止JuiceFS因读取而发起后台合并**。

下列为实际挂载参数，只有路径和元数据地址改为环境变量表示。`SUBDIR`是本组新建的卷内目录，`MNT`是客户端独立挂载点，`OUT`为卷外日志目录；负载文件位于 `MNT/R01/`。各次挂载使用独立进程和日志，均连接同一个卷。

```sh
env CEPH_CONF="$CEPH_CONF" \
  CEPH_ADMIN_SOCKET=none CEPH_LOG_FILE=none \
  nice -n 10 "$JUICEFS" mount -d \
  --cache-size 0 --max-uploads 150 --max-downloads 200 --buffer-size 300 \
  --max-fuse-io 256K --backup-meta 0 --subdir "$SUBDIR" \
  --metrics 127.0.0.1:9573 --log="$OUT/client.log" \
  -o default_permissions "$META" "$MNT"
```

预读没有额外设置，实际配置为2 MiB；挂载允许读写，正常后台任务开启。

`MNT`位于客户端本地目录下，但挂载后文件IO实际走FUSE，不是向该目录的底层本地文件系统测试。使用私有挂载是为了独立读取进程计数并保护既有挂载，不要求社区使用相同目录名。

## 2. 128文件随机读写

在新测试目录创建128个256 MiB文件，先顺序写入CRC格式数据。准备阶段逐文件执行 `juicefs compact --threads 1 FILE`，检查每文件4个chunk均为一条64 MiB映射，完成全32 GiB CRC。随后正常卸载并换新进程，正式起点没有前一进程的计数。

正式负载参数如下，实际完整命令含128个独立job区段，见[实际fio命令](../raw-test-data/upstream-independent/formal/argv.json)：

```text
filesize=256M, size=256M, offset=0
rw=randrw, rwmixread=50, bs=256K
ioengine=libaio, iodepth=128, direct=1, fallocate=none
allow_file_create=0, rate=64k,64k, rate_process=linear
time_based, runtime=1800
verify=crc32c, verify_interval=256K, do_verify=0
verify_fatal=1, verify_dump=0, verify_state_save=0, verify_state_load=0
refill_buffers=1, end_fsync=1, exitall_on_error=1
randrepeat=1, allrandrepeat=1, random_generator=tausworthe64
128个job：各numjobs=1，filename=lt.i.0，randseed=2026101900+i
output-format=json；带宽及延迟日志按1秒记录
```

正式段不做CRC、不手工合并或GC。正式起止抓取本挂载的FUSE、GET／PUT、合并和错误计数，与fio字节核对。先冻结正式结果，再等待在途工作结束、人工归一剩余历史、最终CRC及正常卸载；后续步骤不混入正式结果。

## 3. 一个64 MiB文件的最小复现

单处覆盖和两处覆盖各用一个新文件，按以下实际顺序执行。

| 顺序 | 操作及检查 |
|---|---|
| 1 | 挂载准备进程；以4 MiB顺序IO写满64 MiB，写结束fsync；检查初始为一条64 MiB slice映射 |
| 2 | 完整读取64 MiB作初始CRC；等待对象请求完成，正常卸载 |
| 3 | 挂载新的写进程；负对照在16 MiB偏移写256 KiB，正样例在16、48 MiB偏移各写256 KiB；每次写结束fsync |
| 4 | 记录写进程计数，通过metadata dump检查实际映射为2条／3条；正常卸载 |
| 5 | 挂载新的读取进程，先记录零起点；只读偏移0的256 KiB，随后等待对象字节计数稳定且上传／staging为0 |
| 6 | 冻结计数，metadata dump确认映射；随后才进行全64 MiB CRC并正常卸载 |

两组实际初始化均直接形成单条64 MiB映射，未调用人工compact。若其他环境初始化为多条slice，就不满足这里的初始条件；不能忽略这一差异而直接比较结果。

共同fio参数为 `numjobs=1, ioengine=psync, iodepth=1, direct=1, fallocate=none, filesize=64M, rate=64M`，使用CRC32C、`verify_interval=256K`、固定随机种子2026101920和JSON输出。初始化实际 `size=64M, bs=4M`；覆盖和触发读取实际 `size=256K, bs=256K`。`filesize=64M`不表示每次覆盖都写64 MiB。

| 最小负载命令原始记录 | 作用 |
|---|---|
| [正样例layout](../raw-test-data/mini-positive/layout/argv.json) | 初始化64 MiB |
| [正样例write-1](../raw-test-data/mini-positive/write-1/argv.json) | 偏移16 MiB覆盖256 KiB |
| [正样例write-2](../raw-test-data/mini-positive/write-2/argv.json) | 偏移48 MiB覆盖256 KiB |
| [正样例trigger](../raw-test-data/mini-positive/trigger/argv.json) | 新进程第一次读256 KiB |
| [负对照write-1](../raw-test-data/mini-negative/write-1/argv.json) | 只做第一处覆盖 |
| [负对照trigger](../raw-test-data/mini-negative/trigger/argv.json) | 同样读256 KiB |

覆盖步骤使用 `--do_verify=0 --end_fsync=1`；触发和完整CRC使用 `--readonly --verify_only=1`。读取时仍是可读写的JuiceFS挂载。

## 4. IO统计数据与slice映射如何取得

IO统计数据包括应用读写字节、对象GET／PUT字节、合并次数和合并规模，由本挂载点对应的JuiceFS后台进程记录。第一节完整挂载命令中的 `--metrics 127.0.0.1:9573` 用于开启统计查询接口，通过以下命令直接查询该进程，无需另外部署Prometheus服务：

```sh
curl --fail --silent --show-error http://127.0.0.1:9573/metrics
```

测试脚本通过HTTP查询这个接口，将返回的完整文本、采样时间、JuiceFS后台进程PID和测试阶段一起保存为JSONL。读写字节和合并计数都是累计值，测试结束值减去开始值，就是本阶段发生的IO量。所附 `metrics-boundaries.jsonl` 从这些记录中选取所需采样点，保留原始行。

slice映射保存在TiKV中，记录一个chunk的数据来自哪些slice，以及各段的位置和长度。以下命令连接TiKV导出JuiceFS元数据，测试脚本从输出JSON中提取 `chunks[].slices`，用于检查最小复现中的映射变化：

```sh
"$JUICEFS" dump --threads 1 --subdir "$SUBDIR/R01" --skip-trash "$META"
```

dump操作只查询元数据，不读取Ceph中的文件内容，不触发这里讨论的读侧合并，也不经过上述IO统计接口。`prepared-mapping.json`、`written-mapping.json`、`measurement-end-mapping.json`分别为初始化后、覆盖后和触发读取后的映射。

`metrics-boundaries.jsonl`是原始采样记录的子集，fio JSON是fio直接输出；`results.json`及映射摘录由解析程序生成。来源清单说明了每个文件的来源与选择方式，避免把计算结果当成命令原始输出。
