# V2 测试报告

2026-09-29，Go 1.26.0，固定 v1.4.1 源码。实现和测试位于独立解压的源码树：

`/tmp/opencode/juicefs-idle-v2/source/github.com/juicedata/juicefs@v1.4.1`

Redis 使用本地已有 `redis:7.2-alpine` 镜像启动的独立容器，`--network none`，无宿主机端口映射；新用例通过专用 Unix socket 访问。已有 Redis 回归在共享该容器网络命名空间的隔离容器中执行。外部生产元数据和对象存储不参与本次测试。

## 1. 原版失败 / V2 通过

`pkg/meta/reclaim_regression_test.go` 可在原版编译。它通过 JSON 配置启用新字段，原版会忽略未知字段；测试创建 99 条历史记录、制造普通并发门跳过，然后启动真正的 metadata session。

观察使用 engine `doRead`，不会触发普通 Read 合并。没有手工 compact、没有后续用户写入。

- 原版 memkv、SQLite：均在 5 秒观察期限后以 `RECLAIM_MISSING` 失败，仍有 99 条；不是编译失败。
- V2：同一用例通过，定时发现、再次稳定观察后收敛为 1 条。

日志：`stock-regression.log`、`meta-expanded.log`、`reclaim-race-final.log`。

## 2. 策略和恢复回归

memkv、SQLite、隔离 Redis 共同覆盖：

- 并发门跳过、同 chunk 忙；
- 低条数但高空间收益历史；
- 临时对象失败与预算扣减；
- 原始记录数 1024 的多批恢复；
- worker 重建后的重发现；
- 低收益小覆盖、无冗余相邻 slice、内部大空洞、完整大 slice 负控；
- 值得处理的部分覆盖正例；
- 子树过滤、硬链接排除；
- 合并期间追加写入在原 prefix/CAS 提交后仍然保留；
- 实际 chunk 下标不连续、每页仅 2 条的完整性与最终回收。

额外覆盖：持续变化的热 chunk 不挤占冷候选、队列容量、失败/CAS 作废计费、大小混合候选的 FIFO 与预算、观察时间从实际读完后计时、取消前准入和在途取消边界。

## 3. 放大对照和扫描成本

同一原版 compactor、相同的三轮 256 KiB 覆盖输入：

| 调度策略 | 业务增量 | 合并计划重写量 | 相对业务增量 |
| --- | ---: | ---: | ---: |
| 原候选的直接 ordinary sweep | 786,432 B | 201,326,592 B | 256 倍 |
| V2 收益/冷却准入 | 786,432 B | 0 B | 0 |

这是元数据决策与合并计划对照，不能换算成 Ceph 的前台性能改善倍数。V2 在这个负控中保留低收益历史。

1 TiB 纯空洞用例：V2 在 memkv 扫描 4 条记录、SQLite/Redis 各处理 1 条实际 chunk 记录；均未调用 chunk `doRead`。Redis 可能需要多个空 SCAN 页，不能将 1 条命中解释成一次总 RPC。

开发期间发现 OR 形式的 SQL 游标谓词会使 SQLite 选择从索引开头 SCAN，已改为 `(inode, indx) > (?, ?)`。新增测试对真实测试数据库检查：

```text
SEARCH jfs_chunk USING INDEX UQE_jfs_chunk_chunk ((inode,indx)>(?,?))
```

日志：`reclaim-race-final.log`、`budget-race.log`、`paging-race-final.log`。

## 4. 真实对象验证

SQLite 元数据 + 内存对象后端，使用真正的 `vfs.Compact` 与 `ChunkStore.Remove`，对象 PUT 统计成功写入的实际字节。

- 三个 64 KiB slice 部分重叠，192 KiB 历史变成 96 KiB 有效数据。
- 完整内容逐字节及 CRC 一致。
- 3 个旧对象被删除；新对象 PUT 字节为 98,304。
- 关闭旧 session/metadata client，再打开同一 SQLite 元数据和对象后端，新 session 自动完成回收。
- 小覆盖、相邻有效数据、内部空洞三个负控各带一个高收益哨兵：哨兵成功回收证明 worker 正常运行；目标负控没有额外重写。该轮 96 KiB 新增 PUT 全部属于哨兵。

这些是实际内存对象操作，不是 Ceph 压力或 FUSE 挂载端到端性能测试。

## 5. 有效验证命令

为避免 `/tmp` 的 tmpfs 余量限制，race 最终运行使用磁盘上的专用临时目录：

```sh
export GOTMPDIR=/home/lilingfeng/tmp/juicefs-reclaim-v2-build
export GOTOOLCHAIN=local GOPROXY=off GOSUMDB=off GOMAXPROCS=2
export RECLAIM_TEST_REDIS_SOCKET=/tmp/opencode/juicefs-idle-v2/redis/redis.sock

go test -mod=readonly -race -p 1 -count=3 -timeout=180s \
  -run '^TestReclaim' -v ./pkg/meta ./pkg/vfs

go test -mod=readonly -race -p 1 -count=3 -timeout=60s \
  -run '^TestReclaimMixedBudgetKeepsFIFO$' -v ./pkg/meta

go test -mod=readonly -race -p 1 -count=3 -timeout=90s \
  -run '^TestReclaim(SQLUsesRangeSeek|PagingCompleteness)$' -v ./pkg/meta

go test -mod=readonly -p 2 -count=1 \
  -run '^TestReclaimMountConfig$' -v ./cmd

go test -mod=readonly -p 1 -count=1 -timeout=180s \
  -run '^(TestMemKVClient|TestSQLiteClient|TestBadgerClient)$' -v ./pkg/meta
```

全部上述命令通过。预算和分页测试是在主 race 执行后补充的，分别又重复 3 次；不是将较早的主 race 结果冒充最终新增测试覆盖。未设置 Redis socket 时相关新测试会 SKIP，不能将这样的重跑称为三后端全覆盖。

日志独立复算得到 **71 个不同叶子用例，每个以 race 执行 3 次，共 213 次通过**；另有 CLI 配置测试。该数字来自三份 race 日志的叶子用例去重，不包含父测试或原版预期失败。

打包后的补丁已在固定原版源码树通过 `git apply --check`。可在本目录执行 `python3 verify-results.py` 重新核对日志、计数和补丁/日志归档 SHA256；保存结果为 `verification.json`。

完整开发二进制构建、`--version`、`mount --help` 和 gofmt 检查通过。构建为通用开发版本 `1.4.1+unknown`，不作为生产发布二进制。

## 6. 既有回归和未通过的扩展套件

| 检查 | 结果 |
| --- | --- |
| `TestMemKVClient / TestSQLiteClient / TestBadgerClient` | PASS，约 62.9 秒 |
| 完整 `make test.meta.core` 中的 `TestRedisClient` | PASS，约 32.6 秒 |
| `make test.meta.core` 整体 | 未通过；`TestLoadDump` 仍尝试访问隔离环境中不存在的 TiKV PD `127.0.0.1:2379` 后退出 |
| `make test.pkg` | 未通过；离线只读模块缓存缺少 gogfapi，另有隔离容器根 inode 不满足既有 `TestGetInode` 的 1/2 假设 |
| `make test.cmd` | 未执行到测试；隔离运行环境没有 sudo |

源码里的既有负面测试会主动生成一些 WARNING/ERROR 日志；以上 PASS 依据 Go 测试结果，不以“日志里没有错误字样”为标准。

开发和测试过程中还修正了 CLI flag 分类不支持 `UintFlag` 的 panic，改用现有支持的 IntFlag。首次 race 编译因 `/tmp` 空间不足失败，改用磁盘临时目录后完整完成，未关闭 race 或删减那组用例。

## 7. 仍需验证

V2 尚未进行真实 TiKV/Ceph canary、前台延迟 ON/OFF 对照、长稳、跨客户端协调、Redis cluster 拓扑变化或严格卸载时限验收。引用收敛和逻辑工作量约束已经验证，真实业务性能改善幅度仍待实测。
