# Minimal native retry verification

Offline verification: 2026-09-29; field update through 2026-10-04 13:30 Beijing time. [中文](test-report.md)

## Base and method

JuiceFS v1.4.1 / `0b90c7db5a929ae6adc5faad948d108efd2c99f9`, Go 1.26.0, Linux amd64. Fix-candidate runtime changes are limited to base.go; both test files compile on stock. go.mod/go.sum are unchanged.

The final test patch was applied to an independently extracted release and produced intended failures. The final fix-candidate patch was then applied to that tree and tested three times with race detection. Exported mail patches and all three resulting source files were verified by SHA256 and Git mail parsing.

Redis used a dedicated Unix socket in a network-none container without host port mappings, stopped after testing. Commands used readonly modules, local toolchain, cached/offline dependencies and a disk-backed build temporary directory; JSON records contain exact settings.

## Results

| Check | Result | Evidence |
| --- | --- | --- |
| Stock plus test patch | **13 intended failing leaf cases, nine passing controls, zero skips** | `stock-verified.*` |
| Final replayed-patch race run | **22 leaf cases × three repetitions = 66 passes, zero skips** | `native-race.*` |
| Real object integration | Two ordinary batches; one final mapping/96 KiB; byte/CRC match; objects for eight old source slices removed | Same run, `TestCompactRetryRealObjects` |
| Existing MemKV/SQLite/Badger client tests | PASS | `existing-engines.*` |
| Existing RedisClient | PASS within core attempt, about 29.29 s | `meta-core.log` |
| Generic development build | PASS | `build.*` |
| gofmt | No output for three Go files | `gofmt.*` |
| Full `make test.meta.core` | **Failed**: TestLoadDump attempts unavailable isolated TiKV PD `127.0.0.1:2379` | `meta-core.*` |

`*` denotes output plus invocation/exit-status JSON in [raw-test-data/logs](raw-test-data/logs/). This table records only the September 29 offline tests. Subsequent TiKV/Ceph field results are listed separately below; their counts are not combined.

The 22 leaf cases cover global busy with successful/failed release (two per backend), same-chunk append/coalescing, duplicate/no-new-write control, non-looping admitted object failure, cancellation and forced-recursion ownership across memkv/SQLite/Redis, plus one real-object case.

Tests call the existing ordinary entry directly for a deterministic busy window. The object case first checks source objects exist, appends data after the first snapshot, and issues a busy request. No more user IO is needed for completion; final bytes/CRC come from real object reads.

## Reproduce

At the root of a clean pinned source tree, apply only tests:

```sh
REPORT=/absolute/path/to/juicefs-budgeted-idle-reclamation
git apply "$REPORT/patches/0002-meta-test-busy-compaction-retries.patch"
go test -mod=readonly -p 1 -count=1 -timeout=120s \
  -run '^TestCompactRetry' -json ./pkg/meta
```

Expect nonzero exit at `COMPACT_RETRY_MISSING`, not compilation failure. Then apply the fix:

```sh
git apply "$REPORT/patches/0001-meta-retry-compaction-after-busy-admission.patch"
go test -mod=readonly -race -p 1 -count=3 -timeout=180s \
  -run '^TestCompactRetry' -json ./pkg/meta
```

Set `COMPACT_RETRY_REDIS_SOCKET` to a **dedicated test instance** for all three backends. Tests reset its test database. Without the variable Redis cases skip, so that run is not full three-backend coverage. Example isolation:

```sh
REDIS_DIR=$(mktemp -d)
CID=$(docker run --detach --rm --network none --user "$(id -u):$(id -g)" \
  --mount "type=bind,src=$REDIS_DIR,dst=/run/retry" redis:7.2-alpine \
  redis-server --save '' --appendonly no --port 6379 \
  --unixsocket /run/retry/redis.sock --unixsocketperm 700)
docker exec "$CID" redis-cli -s /run/retry/redis.sock ping
export COMPACT_RETRY_REDIS_SOCKET="$REDIS_DIR/redis.sock"
# Wait for PONG, run the tests, then:
docker stop "$CID"
```

Other checks:

```sh
go test -mod=readonly -p 1 -count=1 -timeout=180s \
  -run '^(TestMemKVClient|TestSQLiteClient|TestBadgerClient)$' ./pkg/meta
go build -mod=readonly -p 1 -o juicefs-native-retry .
make test.meta.core
```

The last target requires the repository's test services; its environment blocker here is recorded above. A normal build excludes test files. No separate `tikv-test.mod` dependency setup is needed.

## Provenance and limits

`initial.*`, `fixed-race.*` and `replay.*` are earlier checks. Source-object existence assertions were subsequently added, and stock plus the final patches were reverified. Authoritative counts use `stock-verified` and `native-race`.

The first `stock.*` attempt did not actually apply tests because Git discovered an ancestor repository; it reported `no tests to run`. It is not acceptance or bug evidence. Restricting Git's upward discovery fixed the setup, and the intended before/after results were then obtained. The initial record is retained.

The old V2 count of 225 is not reused. This fix compensates current-client busy requests only; pre-restart backlog, histories beyond an ordinary batch's policy, sustained-overload capacity bounds and real foreground impact are outside these results.

<a id="field-validation"></a>

## TiKV/Ceph field validation (through 2026-10-04 13:30)

Client 192.168.11.12 and storage nodes .11/.13/.14 only. Here “latest V2” means this native busy-admission candidate, not the earlier scanner. Cache/writeback/async_dio are off; max-uploads=150, BlockSize=256K and TrashDays=0. Neither patch changed. This environment has a gigabit client link and different storage from node157, so its bandwidth is not directly comparable to the performance environment.

| Run and version | Actual workload | Reclamation and correctness | Limit |
|---|---|---|---|
| C8-U0, completely unmodified upstream | 128×128 MiB =16 GiB, 256K randrw; interrupted after 25.167 GiB total IO | About 11.28 h idle: full referenced slice capacity 26.4565 GiB, fully shadowed 2.4902 GiB; no manual maintenance | Stock also retains history; no final CRC or complete equal-work comparison |
| C9-U1, stock plus candidate | Same 16 GiB scale; old PG-delay guard stopped total overwrite IO at 57.7754/64 GiB | No-read snapshot 3838 s after stopping: 256 records/16 GiB, zero fully shadowed capacity; supplemental full 16 GiB CRC passed afterward | Reclamation/correctness evidence; original interrupted round remains incomplete |
| C11, B-catchup plus candidate | 128 GiB, 256K randrw50:50, two full one-hour windows; about 159 GiB written | Minimal 2048 records/128 GiB/zero shadowed capacity first observed about 2 h 34 min after stopping, confirmed at 2 h 50 min; full 128 GiB CRC error/rc=0, normal unmount | Two-hour functional validation, not endurance or performance non-regression acceptance |
| C12, B-catchup plus candidate | Same 128 GiB, 256K randwrite, two full one-hour windows; 232.532 GiB written | Minimal 2048 records/128 GiB/zero shadowed capacity first observed at about 3 h 05 min, confirmed at 3 h 20 min; full 128 GiB CRC error/rc=0, normal unmount | Short pure-write validation; hourly write bandwidth fell from 36.812 to 29.187 MiB/s, so no claim of no slowdown |
| C13, B-catchup plus candidate | New 64 GiB, 16 jobs, psync/QD1, bs=16M sequential overwrites; one full hour plus about 45 min, 259.703 GiB written | At 11:00, pool max_avail 408.52 GiB breached the 409.6 GiB safety floor; by 13:30 stored fell 111.46 GiB from peak and physical usage fell 167.19 GiB without manual reclamation; final CRC not performed | Incomplete two-hour run and unaccepted reclamation; not evidence by itself of a candidate defect |

C11/C12 used no idle user-file reads, compact or GC. Scoped metadata established reclamation and was frozen before CRC to avoid a read-triggered false pass. Before CRC, C11 pool stored/physical usage differed from baseline by about 12.59/18.91 MiB; C12 differed by 19.25/28.875 MiB. Shared-pool statistics corroborate the scoped references; they are not exact per-file reclamation.

C13's 256 GiB growth reserve was derived from C12 and did not cover its sequential-write growth. The controller exited while preserving the private mount; subsequent observation, final CRC and unmount were not automatically completed. Launch success or fio error=0 does not replace complete execution. Network loss did not cause this capacity stop.

Binary fingerprints:

- C8-U0 stock SHA256: `8cd9fb2b129b57c88e378580c987d2d183b4d29f787783cd13254ef0cfd12ff6`.
- C9-U1 stock plus candidate SHA256: `b5d5e12306b0881e41634e605e9a0f0bf0260f6c1509e83a54eb4db81c8ddf29`; no B-catchup.
- C11/C12/C13 version: `1.4.1+2026-07-30.0b90c7d-lt002-native-retry-v2`, SHA256 `41e6946926b4e66f3f5c94766a0512deafda679cf7bfcb97b75ffa6d6bcd7353`; B-catchup plus candidate, no old scanner.

Local evidence prefix: `/mnt/c/SunRise/test/reliability/`; original remote prefix: `/data/reliability-lt-results/`:

- `20260929-LT002-C8-PURE/`: stock residual-history and interruption evidence.
- `20260930-LT002-C9-FUNCTIONAL/`: U1 cold snapshot and `supplemental-crc-evidence.tar.gz`.
- `20261003-LT002-C11-NATIVE-2H/c11-completion-core-evidence.tar.gz`, SHA256 `4be315b85e30685cf5164cb8a2547f52fe20b215a6894e0866b95c5164a7ee2f`.
- `20261003-LT002-C12-NATIVE-RANDWRITE-2H/c12-completion-core-evidence.tar.gz`, SHA256 `3a816a0a5b47c9b60d64791b50ac1d148731cf8b8f8eaf23f69f4364ef98cce0`.
- `20261004-LT002-C13-NATIVE-SEQWRITE-2H/capacity-stop-readonly-20261004.json` and `c13-capacity-stop-core-evidence.tar.gz`, archive SHA256 `b0d5748af5134fdcb4049cc5a57a7e1a7a1fcf0ec8bab9dbce5639f5635e7b67`.

Field archives are not bundled in this submission. `tools/verify.py` checks the packaged offline materials, not every field result. Project records are in `/home/lilingfeng/demo/production/reliability/debug/LT-002-STAGE-C{8,9,11,12,13}-*.md`; metadata dumps may contain sensitive configuration and need sanitization before external sharing.

**Two two-hour random workloads support automatic reclamation and content correctness. C13 remains open; 24/72-hour endurance, multi-round low-water drift, sustained-overload capacity bounds, restart recovery and foreground performance non-regression remain unaccepted.** These results do not establish that all historical-space issues are solved. Observed recovery times are not production SLAs.
