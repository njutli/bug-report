# Test Report

## 1. Overview

All Go tests were performed on official JuiceFS main commit
`53835e2481f45cba159cdbcc1ce0f1fc576e3f1a`. Three independent test groups:

| Group | Source modification | Purpose |
|-------|-------------------|---------|
| Unpatched | + community test file | Verify bug exists |
| Patched | + fix + community test file | Verify fix corrects bug |
| Semantic | + fix + extended semantic test file | Semantic/fault/concurrency coverage |

Environment: WSL (Linux 5.15, 16 cores, 15 GiB RAM), Go 1.26.0,
`GOFLAGS=-mod=readonly`, `GOTOOLCHAIN=auto`.

## 2. Community regression tests

### 2.1 Design rationale

The bug is a **code-path logic issue** (FlushTo not called), not a
performance issue. The tests verify the dispatch decision directly using
Go interfaces and mock dependencies — no FUSE mount, fio, Ceph, or TiKV.

Three mock types replace external dependencies:

| Dependency | Mock | Role |
|-----------|------|------|
| `meta.Meta` (TiKV) | `delayedSliceMeta` | `NewSlice` blocks on a channel until released, ensuring ID is unavailable when `write` checks |
| `chunk.Writer` (Ceph RADOS) | `recordingChunkWriter` | `WriteAt` returns immediately; `FlushTo` writes to a channel — test reads this channel to verify dispatch |
| `chunk.ChunkStore` | `singleWriterStore` | Always returns the same `recordingChunkWriter` |

The test constructs a real `dataWriter` and `fileWriter` (production types
from `writer.go`) with mock dependencies, then calls the real
`writeChunk()` — same production code path, same mutex, same goroutine
launch for `prepareID`. Go's interface dispatch ensures `NewSlice()` and
`FlushTo()` call the mock implementations at runtime.

### 2.2 Three test functions

| Test | Write size | Unpatched expected | Patched expected | Verifies |
|------|-----------|-------------------|------------------|---------|
| `TestFullBlockDispatchedWhenSliceIDBecomesReady` (U1) | 256 KiB (full block) | FAIL: FlushTo not called | PASS: FlushTo called | Main path: full block should dispatch |
| `TestPartialBlockNotDispatchedWhenSliceIDBecomesReady` (U2) | 128 KiB (half block) | PASS: FlushTo not called | PASS: FlushTo not called | Negative control: partial block should not dispatch |
| `TestFlushErrorRecordedWhenSliceIDBecomesReady` (U3) | 256 KiB + injected flush error | FAIL: FlushTo not called | PASS: FlushTo called + s.err=EIO | Error path: dispatch failure recorded as EIO |

### 2.3 Unpatched results

U1 and U3 were each run as **10 independent `go test -count=1` processes**
(not `-count=10` in one process). Each must fail with the exact target
marker and no other failure type.

| Test | Processes | rc | Marker | Result |
|------|-----------|----|--------|--------|
| U1 | 10 | 10× rc=1 | 10× "full block was not dispatched after slice ID became ready" (count=1 each) | ✅ |
| U2 | 1 | rc=0 | N/A (PASS) | ✅ |
| U3 | 10 | 10× rc=1 | 10× "full block with injected flush error was not dispatched" (count=1 each) | ✅ |

Raw logs: `raw-test-data/U01/logs/s-u1-run{1..10}.log`,
`s-u2-single.log`, `s-u3-run{1..10}.log`.
RC files: `raw-test-data/U01/rc/s-u1-run{1..10}.rc`, etc.

### 2.4 Patched results

| Mode | U1 | U2 | U3 | Total PASS | rc | DATA RACE |
|------|-----|-----|-----|-----------|-----|-----------|
| single (count=1) | 1 PASS | 1 PASS | 1 PASS | 3 | 0 | no |
| count=100 | 100 PASS | 100 PASS | 100 PASS | 300 | 0 | no |
| race -count=20 | 20 PASS | 20 PASS | 20 PASS | 60 | 0 | no |

Raw logs: `raw-test-data/U01/logs/b-single-{u1,u2,u3}.log`,
`b-count100-{u1,u2,u3}.log`, `b-race20-{u1,u2,u3}.log`.

## 3. Extended semantic tests (supplementary, not included in submission)

Ten additional tests covering repair semantics, compatibility, fault
handling, and concurrency (multi-block dispatch, freeze skip, ENOSPC
abort, 32 concurrent writers, etc.). All passed on the patched version:

| Mode | Tests | PASS | Total | rc | DATA RACE |
|------|-------|------|-------|-----|-----------|
| single | 10 | 10 | 10 | 0 | no |
| count=20 | 10×20 | 200 | 200 | 0 | no |
| race -count=5 | 10×5 | 50 | 50 | 0 | no |

These are kept as internal supplementary coverage and not included in the
community submission. Available on request.

Raw logs: `raw-test-data/U01/logs/q-single.log`, `q-count20.log`,
`q-race5.log`.

## 4. Full pkg/vfs test suite

`go test ./pkg/vfs -count=1` runs all upstream JuiceFS tests in the
`pkg/vfs` package (19 official test functions) + our 3 community tests +
10 extended semantic tests. An isolated Redis 7.2 container (Docker,
loopback only) was used as the metadata engine for upstream tests.

Result: `ok github.com/juicedata/juicefs/pkg/vfs 13.049s` (rc=0).

Raw logs: `raw-test-data/U01/logs/b-full-vfs.log`.

## 5. Test execution commands

```bash
# Unpatched oracle (10 independent processes)
for i in $(seq 1 10); do
  go test -count=1 -run '^TestFullBlockDispatchedWhenSliceIDBecomesReady$' ./pkg/vfs/
  go test -count=1 -run '^TestFlushErrorRecordedWhenSliceIDBecomesReady$' ./pkg/vfs/
done
go test -count=1 -run '^TestPartialBlockNotDispatchedWhenSliceIDBecomesReady$' ./pkg/vfs/

# Patched verification
go test -count=1 -run '^Test...' ./pkg/vfs/      # single (3 tests)
go test -count=100 -run '^Test...' ./pkg/vfs/    # count (3 tests × 100)
go test -race -count=20 -run '^Test...' ./pkg/vfs/  # race (3 tests × 20)

# Full pkg/vfs (needs Redis on 127.0.0.1:6379)
go test ./pkg/vfs -count=1

# Quality gates
gofmt -d pkg/vfs/writer.go pkg/vfs/writer_flush_test.go
go vet ./pkg/vfs
make juicefs
```

## 6. Not tested

- None. v1.3 real Ceph performance is covered by V02 (see §7).

## 7. fio performance validation

### Cluster architecture

| Component | Configuration |
|-----------|--------------|
| Client | 96-core Xeon 8462Y+, 100GbE NIC |
| Ceph cluster | 3 nodes, 2× 7T NVMe OSD per node, 6 OSDs total |
| Ceph EC | EC 4+2, failure domain = host |
| Ceph pool | `juicefs-data`, 256 KiB block size, no compression |
| Metadata engine | TiKV 3 replicas, co-located with Ceph |
| JuiceFS version | v1.3.1 (`e0032b2a`) + loadRange fix (`eaf3d21f`) |
| Mount options | `--max-uploads 150 --cache-size 0 --max-fuse-io 256K` |
| fio workload | 128 jobs × 1 GiB × 256K bs × randwrite × direct=1 × 180s |

### Description

The following fio results are based on v1.3.1 real Ceph cluster, using a
Latin-square interleaved matrix (2 versions × 3 mounts × 3 rounds = 18
randwrite + 18 randrw = 36 formal fio runs):

| Version | Source modification | Purpose |
|---------|-------------------|---------|
| Unpatched | v1.3.1 base + loadRange fix | Verify collapse exists |
| Patched | Unpatched + fix (async prepareID + catch-up FlushTo after SetID) | Verify fix |

All fio parameters fixed: `128 jobs × 1 GiB × 256K bs × randwrite × direct=1 × 180s`,
drop_caches on 4 nodes before each fio, `gc --compact` + OSD compact after
each write round. Steady-state values computed from 128 per-job bw logs:
per-second cross-job sum, trim first 45s, take p50. Per-mount median of
3 rounds, version-level median of 3 mounts.

### v1.3.1 results

#### randwrite version-level steady-state median

| Version | Mount 1 | Mount 2 | Mount 3 | **Version-level** |
|---------|---------|---------|---------|------------------|
| Unpatched | 561.4 | 560.9 | 560.6 | **560.9 MiB/s** |
| Patched | 2078.6 | 1917.0 | 1828.4 | **1917.0 MiB/s** |

Every patched mount exceeds the highest unpatched mount. Patched/unpatched
ratio = 3.42.

#### Conclusion

- Patched version confirmed recovery: 1917 MiB/s, ratio 3.42, no
  EIO/panic/safety events

### Raw log path guide

Raw data is under `raw-test-data/V02/juicefs-v02-20260819-110158/runs/`,
organized as `block{1-3}-{S|B}{1-3}/{randwrite|randrw}-{1-3}/`. `S` =
unpatched, `B` = patched.

Example — unpatched mount 1, randwrite round 1:

- fio full output: `runs/block1-S1/randwrite-1/fio.txt`
- fio return code: `runs/block1-S1/randwrite-1/fio.rc`
- 128 per-job bw logs: `runs/block1-S1/randwrite-1/S1-rw1_bw.1.log` ~ `S1-rw1_bw.128.log`
- JuiceFS .stats pre/post: `runs/block1-S1/randwrite-1/stats-pre.txt`, `stats-post.txt`
- Mount info: `runs/block1-S1/randwrite-1/mountinfo.txt`
- gc/compact cleanup: `runs/block1-S1/randwrite-1/gc.log`

Patched mount 1, randwrite round 1: `runs/block1-B1/randwrite-1/`,
bw log prefix `B1-rw1_bw.*`.

## 8. Raw test data locations

### Go tests (U01)

`raw-test-data/U01/`, 79 files:

- `logs/` — full stdout/stderr for each `go test` command
- `rc/` — return code for each command (.rc file, single number)
- `results.tsv` — 12-column result index, one row per test command
- `diffs/b-writer-diff.patch` — git diff between patched and unpatched
- `meta/` — git status snapshots for each test group

Example — unpatched U1 run 1:
- Test output: `raw-test-data/U01/logs/s-u1-run1.log`
- Return code: `raw-test-data/U01/rc/s-u1-run1.rc`

Patched U1 count=100:
- Test output: `raw-test-data/U01/logs/b-count100-u1.log`
- Return code: `raw-test-data/U01/rc/b-count100-u1.rc`

File name prefixes: `s-` = unpatched, `b-` = patched, `q-` = extended semantic.

### fio performance validation (V02)

`raw-test-data/V02/juicefs-v02-20260819-110158/`, 5159 files, containing
all fio runs × 128 per-job bw logs, fio full output, health/objects/mount
identity, gc/compact cleanup logs.
