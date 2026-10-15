# 最简复现原始数据 / Raw data for the simple reproduction

在同一TiKV/Ceph卷上串行测试上游JuiceFS v1.4.1和所附补丁。每侧16×256 MiB文件，共4 GiB；初始化一遍，再完整覆盖四遍，累计写入20 GiB，随后停止读写60分钟。

容量实测保留本轮的16份原始日志和容量记录，按上游、补丁两组展开。另外在`automated/`单独附上0002的专项回归和上游负对照两份原始日志；不混入其他长稳或构建数据，没有压缩包。文件内容与原始记录相同，只整理了目录名称。

| 记录 | 上游版本 | 补丁版本 |
|---|---|---|
| 初始化：bs=4 MiB | [fio-0.log](upstream/fio-0.log) | [fio-0.log](patched/fio-0.log) |
| 四遍覆盖：bs=16 MiB | [第1遍](upstream/fio-1.log)、[第2遍](upstream/fio-2.log)、[第3遍](upstream/fio-3.log)、[第4遍](upstream/fio-4.log) | [第1遍](patched/fio-1.log)、[第2遍](patched/fio-2.log)、[第3遍](patched/fio-3.log)、[第4遍](patched/fio-4.log) |
| 测试前后容量，精确字节数 | [before.json](upstream/before.json)、[after.json](upstream/after.json) | [before.json](patched/before.json)、[after.json](patched/after.json) |
| 写入各阶段及60分钟空间观察 | [space.log](upstream/space.log) | [space.log](patched/space.log) |

`before.json` / `after.json` 是[实际外层执行脚本](../reproduce/lt002-plain-mount-ab.sh.txt)在负载脚本调用前后，用 `ceph df detail -f json` 直接生成的原始输出，不是人工填写或从文本日志换算出的JSON。内层负载脚本只生成fio日志和 `space.log`。用 `juicefs-data` 池的 `stats.stored` 测试后减测试前，计算本轮多占用了多少空间；不包括副本或纠删码的额外空间。`space.log` 中保留原始 `df -h` / `ceph df detail` 输出，显示值有取整，精确计算以JSON为准。

| 版本 | 测试前（字节） | 停写60分钟后（字节） | 本轮多占用 |
|---|---:|---:|---:|
| 上游 | 424702352812 | 446177189292 | 20 GiB |
| 补丁 | 446177189292 | 450472156588 | 4 GiB |

每份fio日志包含16个job的完成记录；每遍写4 GiB，五遍累计20 GiB。实际负载原文件见[juicefs-overwrite-manual-check.sh](../reproduce/juicefs-overwrite-manual-check.sh)，外层JSON采集命令、流程示例及挂载参数见[问题报告](../bug-report.md)，结果解释见[测试报告](../test-report.md)。

## 0002专项自动化日志

- [focused-race.log](automated/focused-race.log)：所附补丁的完整专项回归，`go test -json`原始输出；15个顶层测试、36个叶子用例各执行3遍，108次通过，无失败、跳过或race报告。
- [stock-negative.log](automated/stock-negative.log)：相同自动对象用例在未修改上游中等待约75秒后按预期报告缺少自动触发，不是编译失败。

两份日志原样保留，命令、测试范围和结果解释见[测试报告第4节](../test-report.md#4-0002自动化测试结果)。它们是本地自动化测试记录，不是额外的TiKV/Ceph容量实测。

English: `upstream/` and `patched/` contain the two serial runs on the same TiKV/Ceph volume. Each has five fio logs, two exact before/after Ceph JSON records and one 60-minute space-observation log. `fio-0.log` initializes 4 GiB with bs=4 MiB; logs 1–4 fully overwrite it with bs=16 MiB. The [actual outer execution script](../reproduce/lt002-plain-mount-ab.sh.txt) collected JSON directly using `ceph df detail -f json` before and after calling the [inner workload script](../reproduce/juicefs-overwrite-manual-check.sh). The inner script does not generate JSON; these records are not hand-written summaries. Subtract the `juicefs-data` pool's `stats.stored` byte counts to obtain 20 GiB of extra space for upstream and 4 GiB with the patch. `automated/` separately contains patch 0002's focused regression log (108 passes over three repetitions, no skips or race reports) and its expected-failing upstream negative control. These are original local `go test -json` records, not extra TiKV/Ceph capacity runs. File contents are unchanged; no archive extraction is needed. See the [English report](../test-report.en.md) for settings, commands and interpretation.
