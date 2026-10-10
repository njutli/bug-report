# V3测试报告与复验

2026-10-07。本文区分离线机制验证、真实集群功能验证和未完成项目。[English](test-report.en.md)

## 1. 方法与版本

v1.4.1固定底本；现场使用B-catchup＋原生V2＋V3，二进制SHA见README。V3`base.go` SHA256为`fc6a0eb4e2c7676ac6b0fa101b52ce3e93c6324441918f6b19490b5b9ee2f9c5`；B-catchup `writer.go`为`cedd984e2bc0113d5d635aa9f49b0c1023f56b6e4c2aace4e4c4b3249a002b18`。离线后端memkv/SQLite/隔离Redis，不冒充TiKV。现场只在192集群，不将其吞吐与157调优环境比较。

现场`BlockSize=256K`、`TrashDays=0`、cache/writeback/async_dio关闭、max-uploads=150、backup-meta=0、idle-compact-delay=2m。准备阶段手工维护与正式阶段隔离；正式覆盖写后保持挂载，不读用户文件、不手工compact/GC，先确认元数据及空间回收、冻结证据，再全量CRC。原挂载保留。

## 2. 离线结果（原始日志随包）

| 检查 | 实际结果 |
|---|---|
| V2相同自动触发用例 | 9项预期失败，均`IDLE_TRIGGER_MISSING`，不是编译/环境失败 |
| V3自动触发：2条/34条/快照后尾部，三后端 | 9项×3＝27次通过 |
| V3队列、代次、静默门、有效记录、错误退避、取消等 | 36项×3＝108次通过 |
| 原V2普通补偿与真实对象回归 | 22项×3＝66次通过 |
| V3默认关闭的C13诊断负控 | 8项×3＝24次通过，复现原行为 |
| 合计race叶子结果 | 225次通过，0失败、0跳过、无race报告 |
| memkv/SQLite/Badger既有客户端，CLI参数，VFS Compact | 选定回归通过，完整外部服务套件未运行 |

实际对象测试使用真实session定时worker、SQLite和内存ObjectStorage，不mock合并：低记录数、并发尾部两场景各重复3次，自动收敛冻结后98,304字节内容/CRC及旧对象删除通过。它不是实际Ceph测试。上述225是多组检查次数，不是225种独立场景；包含原V2和默认关闭负控。

原版/V2共同缺口的10月4日诊断另外保存在`raw-test-data/diagnosis/`：同一fixture，原版仅通过Go overlay换回stock base；每版8项×3次race通过，表示成功复现缺口。它不属于225计数，也不是纯上游整包的现场A/B。

## 3. 真实TiKV/Ceph结果

| 场景 | 正式IO | CRC前无读自动回收 | 最终CRC及边界 |
|---|---|---|---|
| C14短轮 | 8 GiB数据；含layout共写40 GiB | 两轮引用16→8、约23.94→8 GiB；覆盖历史归零 | 8 GiB CRC通过；原`loops=2`实际写一遍的脚本错误保留，独立续跑补齐；前台恢复后无IO错误，但实际对象IO交叠证据不足，不签收零性能影响 |
| C15顺序覆盖写 | 16×4 GiB、16M、psync/QD1；两个完整1小时，累计写298 GiB | 引用362→64 GiB、完全覆盖历史约297.95→0；新增idle attempts=1024；首次最小引用约停写后2小时31分 | 64 GiB全量CRC通过，正常卸载；准备阶段曾手工清旧C13，正式基线干净，正式期间无手工维护 |
| C16随机读写 | 128×1 GiB、256K、libaio/QD128、128 jobs、50:50；完整2小时，读159.664/写159.512 GiB | 引用约270.48→128 GiB；首次最小引用约停写后3小时02分；idle attempts=1 | 128 GiB CRC通过；普通合并承担主要回收，不能全部归因V3 |
| C17随机写 | 同128 GiB、256K、libaio/QD128、128 jobs；完整2小时，写219.019 GiB、读0 | 引用346.778→128 GiB；首次最小引用约2小时48分，pending排空约3小时33分；idle attempts=0 | 128 GiB CRC通过；证明组合兼容，不单独证明新增触发贡献；完成时仍有BlueStore慢操作告警 |

以上首次收敛时间受15分钟采样及环境限制，不是精确完成时间或生产SLA。C15～C17冻结时池stored分别较基线约−11.875、−4.25、+4.3125 MiB，基本返回起点；共享池变化仅辅证，不作子树精确物理释放量。每次CRC均在自动回收判断之后，不能以校验读取帮助合并制造PASS。

C18原计划24小时随机读写，仅完成5小时后按用户重新排序要求在小时边界收口，不是24小时通过。LT-003三轮突发/空闲及LT-001随机读24小时属于后续项目，**本材料不将尚未打包复核的后续数据加入正式通过表**。尤其不能用读24小时替代写24小时。

## 4. 复验命令

应用README中的四份补丁。三后端测试需要独占Redis Unix socket，设置`COMPACT_RETRY_REDIS_SOCKET`；fixture会Reset其测试DB，禁止指向已有实例。未设置时Redis子例会跳过，不能称三后端通过。Redis隔离方式沿用原V2报告，不在本次整理中新启动服务。

```sh
# 在独立源码树；此文件是诊断负控，不进入生产构建。
cp "$REPORT/raw-test-data/diagnosis/c13_threshold_diagnosis_test.go" pkg/meta/
GOTOOLCHAIN=local GOPROXY=off go test -mod=readonly -p 1 -race -count=3 -timeout=300s \
  -run '^(TestIdleCompactV3|TestIdleTriggerRegression|TestCompactRetry|TestC13)' -json ./pkg/meta
GOTOOLCHAIN=local GOPROXY=off go test -mod=readonly -p 1 -count=1 -timeout=180s \
  -run '^(TestMemKVClient|TestSQLiteClient|TestBadgerClient)$' -json ./pkg/meta
GOTOOLCHAIN=local GOPROXY=off go test -mod=readonly -p 1 -count=1 -timeout=120s \
  -run '^TestIdleCompactDelay' -json ./cmd
```

V2负控用另一独立源码，仅应用第1、2份补丁，再复制`raw-test-data/diagnosis/idle_trigger_regression_test.go`到`pkg/meta/`（这个单独测试在V2也可编译，不依赖新V3方法）；不要应用第3份实现或第4份全部测试，其他V3测试依赖新实现。执行`-run '^TestIdleTriggerRegression' -count=1`，期待9项缺触发失败。原始225日志已在B-catchup组合源码跑过；上述命令提供复验方法，**本次整理未重新运行Go测试，也未声称在不带B-catchup的完整新源码上重新得到225次结果**。补丁应用顺序与结果源码另行离线检查。

## 5. 尚未验收及材料完整性

未完成持续写24/72小时、严格前台性能非劣性、跨进程重启、多客户端独立历史、超65,536队列覆盖及持久后端故障恢复。C15提供新增idle触发的必要性与实际回收证据；C16/C17提供组合回归，不能夸大新增机制贡献。

本包收录离线日志、C13脱敏元数据分析、C14时间线、C15结果/冻结/CRC及C16/C17核心结果（含fio/runtime）。C15完整正式fio日志仍在远端，包内只有事件及权威结果/冻结/CRC；当次SSH补取超时，不以人为填造替代。未收入用户文件、原始卷dump、访问密钥、大二进制或全量秒级日志。`tools/verify.py`只验证本包能验证的内容，不证明所有历史测试或最新现场已复核。
