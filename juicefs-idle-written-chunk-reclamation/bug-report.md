# JuiceFS覆盖写停写后保留历史空间：最简复现与RFC提议

## 1. 测试环境与现象

测试架构为 **JuiceFS文件系统＋TiKV元数据引擎＋Ceph对象存储**：

```text
fio → /mnt/juicefs → Linux VFS/FUSE → JuiceFS客户端
                                      ├─ TiKV：文件属性、chunk/slice映射
                                      └─ Ceph RADOS：实际文件内容的block对象
```

客户端为 `node2`，TiKV和Ceph后端部署在 `node1`、`node3`、`node4` 上，Ceph有6个OSD。JuiceFS卷名为 `juicefs-prod`，挂载点为 `/mnt/juicefs`，文件内容保存在采用EC 4+2纠删码的Ceph对象池 `juicefs-data`。

基线是JuiceFS v1.4.1，commit `0b90c7db5a929ae6adc5faad948d108efd2c99f9`。参数为BlockSize=256 KiB、TrashDays=0、读缓存/writeback/`async_dio`关闭、正常后台任务开启、MaxUpload=150、MaxDeletes=10、backup-meta=0。

**同一后端串行执行上游/RFC对照**，每侧另建16×256 MiB文件，初始化后完整覆盖四遍，累计写入20 GiB，最后停止文件IO60分钟：

| 项目 | 上游v1.4.1 | 所附RFC方案 |
|---|---:|---:|
| 最终逻辑文件大小 | 4 GiB | 4 GiB |
| 累计用户写入 | 20 GiB | 20 GiB |
| 停写60分钟后，本轮新增的容量占用 | **20 GiB** | **4 GiB** |
| 含EC 4+2冗余的本轮新增占用 | 30 GiB | 6 GiB |
| 当前有效数据占保存数据量的比例 | **20%** | **100%** |
| 当前有效数据占含冗余容量的比例 | **13.3%** | **66.7%** |
| fio错误 | 0 | 0 |

停止读写60分钟后，上游版本仍比测试前多占用20 GiB空间；补丁版本最后只多占用4 GiB，与当前文件大小一致。

也就是说，上游版本本轮保存的20 GiB数据中，只有4 GiB是当前文件的有效内容，其余16 GiB已被覆盖，却仍占着空间。算上EC 4+2冗余，Ceph统计的本轮容量占用增加了30 GiB；补丁版本回收后增加了6 GiB，其中4 GiB是有效内容，2 GiB是正常冗余，不是未回收历史。

含冗余的容量取自原始JSON中的 `stats.bytes_used`，不等同于包含DB/WAL等开销的整盘实际占用。上表比例按每轮测试前后的容量差值计算，不是整个池的空间利用率。

## 2. 最简复现步骤

前提：被测版本已正常挂载；没有其他池写入或维护工作；可执行fio及 `ceph df detail`。输出保存到被测卷之外。单侧本次实测约67分钟，其中停写观察60分钟。

**以下仅为帮助理解的流程示例，不是本次实测执行的脚本原文件。** 实际使用的负载脚本和JSON采集命令见本节末尾；核查所附数据或复测时，以实际脚本为准。

```bash
set -euo pipefail
MNT=/mnt/juicefs
TEST_DIR=$(mktemp -d "$MNT/overwrite-repro-XXXXXX")
sample() {
    date '+%F %T %z'
    df -h "$TEST_DIR"
    ceph df detail
}
sample
for wave in 0 1 2 3 4; do
    BS=16M
    CREATE=0
    if (( wave == 0 )); then BS=4M; CREATE=1; fi
    fio --directory="$TEST_DIR" --name=lt --filename_format='lt.$jobnum.0' \
        --filesize=256M --size=256M --numjobs=16 --ioengine=psync --iodepth=1 \
        --direct=1 --fallocate=none --rw=write --allow_file_create="$CREATE" \
        --bs="$BS" --refill_buffers=1 --end_fsync=1
    sample
done
for point in {1..12}; do
    sleep 300
    sample
done
```

初始化4 GiB后，后四遍只覆盖原文件，不新建文件。观察期间不读取文件内容、不执行人工compact/GC，也不删除文件。观察结束后保留目录。

比较补丁方案时，先卸载上游版本的挂载，再用补丁版本挂载同一卷，在新目录中按相同参数重复测试。上游测试文件保留，**用每轮测试前后Ceph池容量占用的差值，计算本轮多占用了多少空间**，不能直接比较两轮结束时的池总占用。

容量占用通过 `ceph df detail` 记录，比较的是 `juicefs-data` 池测试前后多占用了多少空间。具体记录和每五分钟的观察结果见[测试报告](test-report.md)。

### 实际使用的脚本与JSON采集

本次实际执行的是两个脚本，而不是单独一个负载脚本：

- [lt002-plain-mount-ab.sh.txt](reproduce/lt002-plain-mount-ab.sh.txt)：完整外层执行脚本，调用负载脚本，并在每侧调用前后生成 `before.json` / `after.json`。
- [juicefs-overwrite-manual-check.sh](reproduce/juicefs-overwrite-manual-check.sh)：内层负载脚本，只生成fio日志和 `space.log`，不生成JSON。

外层脚本涉及挂载切换，因此以 `.sh.txt` 附上，**只供核查执行过程，不要在其他环境原样执行**。
内层脚本创建独立文件集，执行五遍写入，生成 `fio-0.log`～`fio-4.log` 和 `space.log`；停写后按实际经过的一小时观察，不执行读文件、CRC、compact/GC或删除。

```bash
bash reproduce/juicefs-overwrite-manual-check.sh --mount /mnt/juicefs --hours 1 --interval 300
```

复现前可按自身环境调整脚本中的结果目录和Ceph查询命令，保持fio参数和观察时长不变。结果目录需可写，日志保存在被测卷之外。

`before.json` / `after.json` 由外层执行脚本在测试前后采集，命令如下。`ROOT` 指向结果目录，`CEPH` 是该脚本中的Ceph查询命令数组：

```bash
# 上游版本已经挂载时执行
"${CEPH[@]}" df detail -f json > "$ROOT/A/before.json"
bash "$ROOT/juicefs-overwrite-manual-check.sh" --mount /mnt/juicefs --hours 1 --interval 300 | tee "$ROOT/A/execution.log"
"${CEPH[@]}" df detail -f json > "$ROOT/A/after.json"

# 正常卸载并切换为补丁版本后执行；不是两组连续使用同一个挂载进程
"${CEPH[@]}" df detail -f json > "$ROOT/B/before.json"
bash "$ROOT/juicefs-overwrite-manual-check.sh" --mount /mnt/juicefs --hours 1 --interval 300 | tee "$ROOT/B/execution.log"
"${CEPH[@]}" df detail -f json > "$ROOT/B/after.json"
```

测试及停写观察期间，需保持对应版本的客户端挂载运行。

## 3. 原因分析：逻辑覆盖不等于解除旧引用

JuiceFS把文件按64 MiB划分为逻辑chunk；一次形成的slice有独立ID，并按卷的BlockSize拆成Ceph对象。元数据保存 `pos/id/size/off/len` 映射记录，编码为24字节。

普通写入的处理关系为：

```text
VFS组织slice数据 → 数据写出完成 → Meta.Write/engine.doWrite追加映射
                                             ↓
                              按chunk当前记录数判断是否请求合并
```

后写覆盖先写只改变最终可见布局，不会因此直接移除全部旧映射和旧对象。例如同一区间先写A再写B，读时可以选择B，但持久化历史仍可能包含[A,B]。旧源slice仍被历史映射引用时，不能由Ceph直接删除；TrashDays=0也不能代替解除这些引用。

上游 `pkg/meta/base.go` 的写侧触发条件为：

```go
if numSlices%100 == 99 || numSlices > 350 {
    if numSlices < maxSlices {
        go m.compactChunk(inode, indx, false, false, int(attr.Tier))
    } else {
        m.compactChunk(inode, indx, true, false, int(attr.Tier))
    }
}
```

它按记录数量触发，不按历史容量或等待时间触发。少量大slice的覆盖可能留下很多历史字节，却尚未达到第一次99条的触发点；停写后没有新的Write再次检查。符合条件的读或显式维护可以另外触发，但本实验的观察阶段没有这些操作。

因此，需要确认：**低记录数覆盖写后停止读写时保留历史，是预期的空间/合并开销取舍，还是应有其他后台机制继续处理？**

## 4. RFC修复提议

保留原有写侧触发条件，增加“成功写入时登记，停写后检查，确认无覆盖历史才结束”的处理路径：

1. **登记。** 普通Write成功提交映射后，按 `(inode, chunk index)` 跟踪有多条记录的chunk；已有项遇到新Write时更新代次和到期时间。待办只在本客户端内存中，上限65536项。
2. **检查。** 每个允许后台任务的可写客户端新增一个后台检查协程，负责定期查看待办表。每个chunk从本客户端最近一次成功Write起，等待一分钟后才可以被检查。该协程每秒检查一次，每次最多选择一个已到期的chunk处理；一次处理尚未结束，就不会开始下一项，也不会为每个chunk单独创建协程。
3. **合并。** 对不超过1000条的记录，比较原始映射累计引用长度与最终有效长度；没有重叠历史就结束，否则复用原有单批合并。更大记录集继续使用原有有限批次规划。
4. **跟进。** 成功合并一次后仍保留待办，之后重新读取确认；失败则冷却后重试。新Write改变代次时，旧检查不能删除待办或覆盖新的等待时间。元数据提交继续校验旧前缀并保留并发追加尾部。
5. **删除。** 合并解除旧slice引用后，由原有删除流程处理满足条件的对象；共享引用、TrashDays等规则保留。不通过直接删除后端对象绕过元数据。

### 成本与边界

- **停写一分钟不保证立即回收。** 每个chunk分别计时，但上述后台检查协程发现本客户端还有合并任务未结束时，会保留待办、暂不开始本次检查，等后续定时检查再尝试。这些合并任务也可能来自其他chunk；如果持续存在，就可能让已停写chunk的回收长期延后。因此，一分钟只是开始检查前的等待时间，不是回收完成时间。
- **合并是真实数据IO。** 按最终可见布局读取所需有效数据，再以新slice ID上传新block对象，并在解除引用后删除旧对象；不是仅整理元数据，也不是直接复用旧对象键。新增触发机会可能增加后端读写竞争。
- **共享客户端锁。** 登记、待办选取及合并标记结算使用已有 `baseMeta` 锁；扫描为O(pending)。这不是TiKV集群全局锁，但大待办表仍可能增加客户端锁竞争。
- **有界不等于不遗漏。** 满表时新chunk可能不被登记，并打印限频告警；已有项仍可更新。待办不持久化，不保证重启后补处理，也不覆盖其他客户端或Copy/Truncate/打洞等非Write操作。
- **关闭不是强制中断。** 关闭客户端会话时，会通知上述后台检查协程退出，并等待已经开始的操作返回；后端操作仍沿用原有取消机制，没有新增强制中断时限。只读及 `NoBGJob=true` 客户端不登记待办，也不启动该后台检查协程。

## 5. 补丁与材料

实现补丁仅修改 `pkg/meta/base.go`、新增 `pkg/meta/idle_write.go`；测试另附。

在干净固定上游基线上应用：

```sh
REPORT=/absolute/path/to/juicefs-idle-written-chunk-reclamation
git apply "$REPORT/patches/0001-meta-compact-written-chunks-after-idle.patch"
git apply "$REPORT/patches/0002-meta-test-written-chunk-idle-compaction.patch"
```

实测结果见[测试报告](test-report.md)，两侧的fio日志和空间记录直接列在[原始数据目录](raw-test-data/README.md)，无需下载或解压压缩包。
