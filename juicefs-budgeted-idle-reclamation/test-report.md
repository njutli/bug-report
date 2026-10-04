# 最小原生修复测试报告

离线验证：2026-09-29；现场进展更新至2026-10-04 13:30（北京时间）。 [English](test-report.en.md)

## 1. 基线与方法

固定 JuiceFS v1.4.1 / `0b90c7db5a929ae6adc5faad948d108efd2c99f9`；Go 1.26.0、Linux amd64。修复只涉及 base.go；两个测试文件可直接在原版编译。没有修改 go.mod/go.sum。

在独立解压的原版源码上实际应用最终测试补丁，确认预期失败；再应用最终修复候选补丁，在该源码上跑三次 race。另核对导出补丁、Git 邮件解析和三个结果源码文件的 SHA256。

Redis 使用专用 Unix socket 和 network-none 容器，没有映射宿主端口。测试结束后已停止该容器。命令使用 `-mod=readonly`、本地工具链及离线依赖缓存，编译临时目录在磁盘上；详细环境见各命令 JSON。

## 2. 结果

| 检查 | 结果 | 日志 |
| --- | --- | --- |
| 原版，仅测试补丁 | **13 个目标叶子用例预期失败，9 个负控通过，0 跳过** | `stock-verified.*` |
| 最终补丁重放后的 race | **22 个叶子用例 × 3 = 66 次通过，0 跳过** | `native-race.*` |
| 实际对象测试 | 每次两个普通批次，最终一条映射/96 KiB；内容与 CRC 一致，8 个旧源 slice 的对象删除 | 同上，`TestCompactRetryRealObjects` |
| 既有 MemKV/SQLite/Badger 客户端 | 通过 | `existing-engines.*` |
| 既有 RedisClient | 通过，本次 core 尝试中耗时约 29.29 秒 | `meta-core.log` |
| 通用开发构建 | 通过 | `build.*` |
| gofmt | 三个 Go 文件检查无输出 | `gofmt.*` |
| 完整 `make test.meta.core` | **未通过**：TestLoadDump 访问隔离环境内不存在的 TiKV PD `127.0.0.1:2379` 后退出 | `meta-core.*` |

`*` 表示 `.log` 与记录命令/退出码的 `.json`；均在 [raw-test-data/logs](raw-test-data/logs/) 中。这张表只记录9月29日离线验证；后续真实TiKV/Ceph结果另列于文末现场章节，不把两组计数合并。

22 个叶子用例包括：全局繁忙成功/失败释放（每后端两例），同 chunk 追加与去重，无新写入的重复请求负控，已准入对象失败不循环，取消，强制递归槽位所有权；以上覆盖 memkv/SQLite/Redis，再加一例实际对象集成。

测试直接调用原普通 compactor 入口，以确定性地控制忙时窗口。实际对象测试先确认源对象已经存在；第一次快照之后追加数据，再触发忙时请求；观察期间不再发用户读写，最终用真实对象读取核对字节及 CRC。

## 3. 复验

在干净基线的源码根目录，只应用测试补丁：

```sh
REPORT=/absolute/path/to/juicefs-budgeted-idle-reclamation
git apply "$REPORT/patches/0002-meta-test-busy-compaction-retries.patch"
go test -mod=readonly -p 1 -count=1 -timeout=120s \
  -run '^TestCompactRetry' -json ./pkg/meta
```

预期出现 `COMPACT_RETRY_MISSING` 并非零退出，不是编译失败。再应用修复候选补丁：

```sh
git apply "$REPORT/patches/0001-meta-retry-compaction-after-busy-admission.patch"
go test -mod=readonly -race -p 1 -count=3 -timeout=180s \
  -run '^TestCompactRetry' -json ./pkg/meta
```

完整三后端结果需要设置 `COMPACT_RETRY_REDIS_SOCKET`，指向**专用测试实例**。测试会 Reset 该实例的测试数据库；未设置时 Redis 子例会跳过，不能称为三后端完整通过。可建立隔离实例：

```sh
REDIS_DIR=$(mktemp -d)
CID=$(docker run --detach --rm --network none --user "$(id -u):$(id -g)" \
  --mount "type=bind,src=$REDIS_DIR,dst=/run/retry" redis:7.2-alpine \
  redis-server --save '' --appendonly no --port 6379 \
  --unixsocket /run/retry/redis.sock --unixsocketperm 700)
docker exec "$CID" redis-cli -s /run/retry/redis.sock ping
export COMPACT_RETRY_REDIS_SOCKET="$REDIS_DIR/redis.sock"
# 确认 PONG 后执行上面的测试；结束后：
docker stop "$CID"
```

其他有效命令：

```sh
go test -mod=readonly -p 1 -count=1 -timeout=180s \
  -run '^(TestMemKVClient|TestSQLiteClient|TestBadgerClient)$' ./pkg/meta
go build -mod=readonly -p 1 -o juicefs-native-retry .
make test.meta.core
```

最后一项需准备仓库测试所需的后端；本次环境阻塞如结果表所述。构建不包含测试文件。源码/测试没有引入需要独立 `tikv-test.mod` 的依赖。

## 4. 过程记录和边界

`initial.*`、`fixed-race.*`、`replay.*` 是早期检查。最终对象测试又增加源对象预先存在的断言，随后重新验证原版并在最终补丁上完成 `native-race`；正式计数以这两组最终日志为准。

首次 `stock.*` 因上层目录的 Git 仓库归属导致测试补丁未实际应用，输出 `no tests to run`，不作为成功或原版缺陷证据。限制 Git 向上搜索范围后，完成了正式的原版失败/修复通过验证；原记录保留。

本次没有用旧 V2 的 225 次测试代替新修复验证。该补丁只保留/补偿当前客户端的忙时请求；跨重启积压、单批策略之外的历史、持续过载下的容量界限及实际前台影响均不由这组结果保证。

<a id="field-validation"></a>

## 5. 真实TiKV/Ceph验证（截至2026-10-04 13:30）

仅192.168.11.12客户端及.11/.13/.14存储集群。以下“最新V2”指本目录的原生忙时补偿，不是旧周期扫描版。cache/writeback/async_dio关闭、max-uploads=150；BlockSize=256K、TrashDays=0。补丁内容未改；真实负载速度受到本环境千兆链路和存储条件限制，不与157性能结果直接比较。

| 阶段与版本 | 实际负载 | 自动回收及正确性 | 判定边界 |
|---|---|---|---|
| C8-U0：完全纯上游 | 128×128 MiB，共16 GiB；256K randrw；覆盖写总IO25.167 GiB后中止 | 停写约11.28小时，引用26.4565 GiB、完全被覆盖2.4902 GiB；无人工维护 | 上游也有残留；无最终CRC，不是完整等量对照 |
| C9-U1：纯上游＋本候选 | 同规模16 GiB；覆盖写总IO57.7754/64 GiB后被旧PG延迟保护停止 | 停写3838秒的无读快照达到256条/16 GiB、被覆盖引用0；随后补充16 GiB CRC通过 | 现场回收改善与正确性有证据；原轮中止记录保留 |
| C11：B-catchup＋本候选 | 128 GiB、256K randrw50:50，两个完整1小时，写约159 GiB | 停写约2小时34分首次、2小时50分再次达到2048条/128 GiB/被覆盖引用0；CRC完整读128 GiB，error/rc=0，正常卸载 | 两小时短轮通过，不代表长期或性能非劣性通过 |
| C12：B-catchup＋本候选 | 同128 GiB、256K randwrite，两个完整1小时，写232.532 GiB | 停写约3小时05分首次、3小时20分再次达到2048条/128 GiB/被覆盖引用0；CRC完整读128 GiB，error/rc=0，正常卸载 | 纯随机写短轮通过；小时带宽36.812→29.187 MiB/s，不能宣称无性能下降 |
| C13：B-catchup＋本候选 | 新64 GiB、16 jobs、psync/QD1、16M顺序写；第1小时及第2小时约45分钟，写259.703 GiB | 11:00可用空间408.52 GiB低于409.6 GiB安全线而停止；13:30较峰值stored已下降111.46 GiB、物理下降167.19 GiB，无人工回收；最终CRC未做 | 两小时未完成、回收未签收；不能追认通过或据此认定候选缺陷 |

C11/C12停写后先不读用户文件、不执行compact/GC，以精确子目录元数据确认回收，冻结结果后才CRC，排除校验读触发合并的假通过。CRC前，C11共享池stored/物理占用与起点仅差约12.59/18.91 MiB，C12差约19.25/28.875 MiB；共享池统计是辅证，不是逐文件释放量。

C13的256 GiB预留增长预算取自C12，未覆盖该顺序写轮次的实际增长。控制器停止并保留私有挂载，后续回收观察、最终CRC与卸载没有自动完成；启动成功或fio error=0不能替代完整轮次完成。当前容量停止记录不受网络断连影响。

版本指纹：

- 纯上游C8-U0：SHA256 `8cd9fb2b129b57c88e378580c987d2d183b4d29f787783cd13254ef0cfd12ff6`。
- 纯上游＋本候选C9-U1：SHA256 `b5d5e12306b0881e41634e605e9a0f0bf0260f6c1509e83a54eb4db81c8ddf29`；不含B-catchup。
- C11/C12/C13：`1.4.1+2026-07-30.0b90c7d-lt002-native-retry-v2`，SHA256 `41e6946926b4e66f3f5c94766a0512deafda679cf7bfcb97b75ffa6d6bcd7353`；含B-catchup及本候选，不含旧回收扫描。

本地证据目录前缀`/mnt/c/SunRise/test/reliability/`，原始远端前缀`/data/reliability-lt-results/`：

- `20260929-LT002-C8-PURE/`：纯上游残留及中止证据。
- `20260930-LT002-C9-FUNCTIONAL/`：U1冷快照及`supplemental-crc-evidence.tar.gz`。
- `20261003-LT002-C11-NATIVE-2H/c11-completion-core-evidence.tar.gz`，SHA256 `4be315b85e30685cf5164cb8a2547f52fe20b215a6894e0866b95c5164a7ee2f`。
- `20261003-LT002-C12-NATIVE-RANDWRITE-2H/c12-completion-core-evidence.tar.gz`，SHA256 `3a816a0a5b47c9b60d64791b50ac1d148731cf8b8f8eaf23f69f4364ef98cce0`。
- `20261004-LT002-C13-NATIVE-SEQWRITE-2H/capacity-stop-readonly-20261004.json`及`c13-capacity-stop-core-evidence.tar.gz`，后者SHA256 `b0d5748af5134fdcb4049cc5a57a7e1a7a1fcf0ec8bab9dbce5639f5635e7b67`。

这些现场原始包不包含在当前上报目录中，`tools/verify.py`只校验本目录打包的离线材料，不能称为它已自动复核现场全部数据。主工程记录在`/home/lilingfeng/demo/production/reliability/debug/LT-002-STAGE-C{8,9,11,12,13}-*.md`；原始元数据可能含敏感配置，外发前需脱敏。

**结论边界：两个两小时随机负载支持自动回收改善和数据正确性；C13尚未闭合，24/72小时、多轮低谷、持续过载容量界限、跨重启恢复与前台性能非劣性未验收。**不存在“已全面解决所有历史空间问题”的结论；回收时间只是本环境记录，不是生产SLA。
