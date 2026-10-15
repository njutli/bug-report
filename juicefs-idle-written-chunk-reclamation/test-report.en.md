# Simple field comparison: upstream/RFC reclamation on a normal mount

## 1. Goal and method

Compare whether **upstream JuiceFS and the patched version reclaim old data after the same file set is repeatedly overwritten and file IO stops**.

Client `node2` ran the arms serially on the same TiKV/Ceph volume, with JuiceFS mounted at `/mnt/juicefs`. The baseline was v1.4.1, commit `0b90c7db5a929ae6adc5faad948d108efd2c99f9`; the other arm tested the RFC processing approach.

- Each arm created a separate 16 × 256 MiB file set: 4 GiB.
- Initialize once with bs=4 MiB, then fully overwrite four times with bs=16 MiB. Each pass wrote 4 GiB; total writes were 20 GiB.
- fio: 16 jobs, psync/QD1, direct=1, fallocate=none, refill_buffers=1, end_fsync=1; no file creation after initialization.
- Volume/mount: BlockSize=256 KiB, TrashDays=0, cache-size=0, writeback/`async_dio` disabled, MaxUpload=150, MaxDeletes=10, NoBGJob=false, backup-meta=0.
- Record `df -h` and `ceph df detail` before writing, after each pass and every five minutes during 60 idle minutes.
- No file-content reads, CRC, manual compact/GC, deletion or per-slice observation.
- Preserve the upstream test files and use a new directory for the patched run. For each run, subtract the space used before the test from the space used afterward to calculate how much extra space it used.

The complete outer file, [lt002-plain-mount-ab.sh.txt](reproduce/lt002-plain-mount-ab.sh.txt), switches client versions and collects JSON space records before the test and after idle observation. It calls [juicefs-overwrite-manual-check.sh](reproduce/juicefs-overwrite-manual-check.sh) to run the overwrite test.

The inner script creates a separate test subdirectory beneath the JuiceFS mount. fio only initializes and overwrites the 16 test files in that subdirectory. `fio-0.log` through `fio-4.log` contain the five write passes' results; `space.log` contains the output of `df -h` and `ceph df detail`, recording filesystem and Ceph space usage. Logs are saved outside the tested JuiceFS volume.

The [reproduction section](bug-report.en.md#2-simple-reproduction) distinguishes the flow example from these two original files. The data came from the actual execution, not a rerun of the example.

## 2. Results

| Metric | Upstream v1.4.1 | Attached RFC approach |
|---|---:|---:|
| Logical file set | 4 GiB | 4 GiB |
| Total user writes | 20 GiB | 20 GiB |
| fio outcome | Five successful passes; all 80 job results error=0 | Same |
| Idle observation | 60 minutes, 12 samples | Same |
| Extra pool space used by this run | **20 GiB** | **4 GiB** |
| Space used beyond the current file size | **16 GiB** | **0 GiB** |

Space usage here means the amount of data stored in Ceph pool `juicefs-data`, excluding extra space for replicas or erasure coding. Subtract the recorded byte count before each test from the count afterward:

```text
Upstream: 446177189292 - 424702352812 = 21474836480 bytes = 20 GiB
RFC:      450472156588 - 446177189292 =  4294967296 bytes =  4 GiB
```

Upstream pool space usage did not decrease during the 60-minute observation. Five-minute records from the patched run showed usage approaching its final level about 10–15 minutes after writes stopped. At 60 minutes, only 4 GiB more space was used than before the test. Checking every five minutes does not give an exact completion second.

**After file IO stopped, the patched version automatically reclaimed old overwrite data, leaving only as much extra space used as the current file set's size.** This round observes space changes without CRC or per-slice deletion checks.

## 3. Evidence and checks

| Artifact | Contents |
|---|---|
| [Upstream run](raw-test-data/upstream/) | Five fio logs, `before.json` / `after.json` space records and `space.log` observations |
| [Patched run](raw-test-data/patched/) | Same |

`fio-0.log` is initialization; `fio-1.log` through `fio-4.log` are the four full overwrites. `space.log` records usage before writes, after each pass and every five idle minutes. The JSON records preserve exact byte counts used to calculate the 20 GiB and 4 GiB results. Files are directly accessible and retain their original contents; see the [data index](raw-test-data/README.md).

Artifact verification:

```sh
sha256sum -c SHA256SUMS
```

This checks file integrity without rerunning tests. The submission includes this simple reproduction's raw data and the two focused automated-test logs below, not broader investigations, build logs or long-running test data.

## 4. Automated tests from patch 0002

Patch 0002 adds tests only and does not participate in normal client builds. The focused tests cover compaction timing, concurrent writes, failures and retries, session shutdown, the tracking limit, content integrity after automatic compaction and deletion of old objects. These results are separate from the TiKV/Ceph space comparison above.

Local test environment: Go 1.26.0 and a dedicated Redis 8.0.5 instance.

Focused regression command:

```sh
export COMPACT_RETRY_REDIS_SOCKET=/path/to/dedicated/redis.sock
go test -mod=readonly -p 1 -race -count=3 -timeout=300s -run '^TestIdleWrite' -json ./pkg/meta
```

Run the command from the JuiceFS source root after applying the patches. Tests call internal interfaces without mounting a filesystem: mechanism tests use memkv, SQLite or Redis metadata with simulated object callbacks; the automatic object case uses SQLite, in-memory object storage and the real `vfs.Compact` path. All cases are included in the focused regression totals below.

`redis.sock` is the Unix socket of an already-running, dedicated Redis instance, not a database file. Test initialization clears DB 0 of that instance. Without this variable, Redis subtests are skipped.

| Test | Result | Original log |
|---|---|---|
| Focused regression | 15 top-level tests and 36 leaf cases, each repeated three times: 108 passes, no failures or skips, no race reports | [focused-race.log](raw-test-data/automated/focused-race.log) |
| Automatic object negative control on unmodified upstream | Reported `IDLE_WRITE_TRIGGER_MISSING records=3` after approximately 75 seconds, failing as expected and demonstrating that the test detects the missing idle trigger | [stock-negative.log](raw-test-data/automated/stock-negative.log) |

For the upstream negative control, do not apply patch 0001. Copy only `idle_write_fixture_test.go` and `idle_write_automatic_test.go` from patch 0002 into the upstream tree, then run:

```sh
go test -mod=readonly -p 1 -race -count=1 -timeout=300s -run '^TestIdleWriteAutomaticObjects$' -json ./pkg/meta
```

These are focused `TestIdleWrite` results. The in-memory object test does not replace the real TiKV/Ceph space verification above.

## 5. Scope

- The comparison is **20 GiB of extra space used by upstream versus 4 GiB with the patch**. This test does not measure throughput benefits or set a deadline for reclamation.
- The patch's background checks can be postponed for a long time if compactions on other chunks in the same client remain active. Overflow omissions, locked scanning and actual backend compaction IO remain considerations.
- Feedback is welcome on triggering policy and resource trade-offs.
