# Candidate validation: local tests and real-backend short checks

## 1. Local environment and results

New executions use Go 1.26.0 Linux/amd64, GOMAXPROCS=4, offline modules and read-only dependencies. Focused tests use memkv, SQLite and an exclusive Redis Unix socket.

| Run | Outcome |
|---|---|
| Focused race | 36 leaves × 3 = 108 passes, no failures/skips/race |
| Upstream automatic object control | Expected failure after 75 seconds: three records remain, IDLE_WRITE_TRIGGER_MISSING |
| Non-race client regressions | MemKV/SQLite/Badger pass |
| Broad client race, candidate | FAIL, race reported |
| Same broad client race, upstream | FAIL, race reported |
| Generic development build | PASS |

Broader races concern reused-client format initialization and asynchronous deletion state; the proposal does not redesign all lifecycle handling or remove test assertions. Original logs and package failures are retained.

Focused coverage includes low record counts, five complete overwrite generations, native 99-record snapshot tails, writes during object work/clean inspection, valid nonoverlap, busy deferral, read/object/commit errors, completion-relative cooldown, finite large histories, oldest-ready scheduling, capacity, disabled states and close during worker IO.

The automatic object test compiles unchanged on upstream and uses a real session timer, the production one-minute delay, CachedStore/vfs.Compact and memory ObjectStorage. It freezes metadata convergence before reading 98304 bytes and checking content/CRC and deletion of old blocks. Upstream does not trigger within 75 seconds; the candidate passes all three runs. This is not Ceph or soak acceptance.

## 2. Reproduction and artifact verification

Apply the implementation and test patches as described in the bug report. With an exclusive COMPACT_RETRY_REDIS_SOCKET:

```sh
GOTOOLCHAIN=local GOPROXY=off GOMAXPROCS=4 go test -mod=readonly -p 1 -race -count=3 -timeout=300s -run '^TestIdleWrite' -json ./pkg/meta
GOTOOLCHAIN=local GOPROXY=off GOMAXPROCS=4 go test -mod=readonly -p 1 -count=1 -timeout=300s -run '^(TestMemKVClient|TestSQLiteClient|TestBadgerClient)$' -json ./pkg/meta
python3 tools/verify.py
python3 tools/verify.py --upstream /path/to/clean/juicefs-v1.4.1
```

For the upstream automatic control, copy only idle_write_fixture_test.go and idle_write_automatic_test.go and run the automatic test; other tests depend on the new implementation. The artifact verifier checks hashes and recorded summaries; --upstream applies patches in a separate temporary copy without modifying the supplied baseline. It does not rerun Go or cluster workloads. Internal reading notes are not required in the submission.

## 3. TiKV/Ceph short checks completed on 2026-10-10

The Linux client used TiKV metadata and Ceph objects. The fixed upstream baseline plus patch 0001 and observation-only instrumentation was used, with no B-catchup or older reclamation policy. Implementation SHA256: `776a542192a63595c5a5dbd039a03d16b601b24fa285a6e65cf057118ca10a5a`; observed binary SHA256: `05d0417f90282e4b15aa123f5e52b81b0bfd2bf1756977827f74f929e5293dcb`. The same binary and production one-minute delay were used in both rounds.

Each independent round initialized 16 × 256 MiB files with bs=4M, then performed four explicit full overwrites with bs=16M: 4 GiB logical data, 20 GiB user writes. Settings: 16 jobs, psync/QD1, direct=1, fallocate=none, refill_buffers=1 and end_fsync=1 per pass. Writes carried CRC32C headers at 256 KiB intervals, without immediate readback. Per-job errors, bytes, IO counts and file identities were checked. Automatic evidence was frozen without user reads or manual maintenance before full CRC.

Volume/mount settings: BlockSize=256 KiB, TrashDays=0, read cache/writeback/async_dio disabled, MaxUpload=150, MaxDeletes=10, NoBGJob=false and BackupMeta=0. Source-reference sizes are deduplicated by slice ID; completely shadowed sizes count only sources with no live fragment. They are not raw Ceph usage or cumulative deleted-object bytes.

| Metric | First independent round | Independent repeat A | Foreground overlap B |
|---|---:|---:|---:|
| User writes | 20 GiB | 20 GiB | Additional 4 GiB + 128 MiB |
| Successful Meta.Write events | 1226 | 1187 | 193 in B |
| Successful compaction commits | 66 idle | 66 idle | 61 idle + 4 native in B |
| Frozen references / shadowed history | 4 / 0 GiB | 4 / 0 GiB | 4 / 0 GiB |
| Obsolete slices with deletion success | 1228 | 1189 | 1447 cumulative A+B |
| Stop-to-evidence-freeze | 641.903 s | 641.956 s | 348.235 s |
| Pending/compacting and in-flight upload/deletion | Zero | Zero | Zero |
| Subsequent full CRC | 4 GiB PASS, 37.056 s | 4 GiB PASS, 36.785 s | 4 GiB PASS, 37.196 s |

Repeat A's no-read snapshots show references/shadowed history decreasing from 19.9375/15.9375 through 17.25/13.25 and 13.75/9.75 to 4/0 GiB. The first round did not retain a valid immediate-stop snapshot; do not attribute the same curve to it. Freeze intervals include sampling/review overhead and are not universal reclamation SLAs. Files retained their identities and private mounts closed normally.

### Actual overlap and limitations

A selected idle object batch lasted 22.005 seconds. A successful Write to that same chunk changed generation 1 to 2 during the batch; settlement retained the entry. A later automatic commit included the new Write and previous compacted output, followed by a clean generation-2 inspection and passing CRC.

The overlap included a 128 MiB write and two 120-second reads at 4 MiB/s. All fio errors were zero. Write clat P99 was 21.627 ms; sequential/random read P99 was 233.832/219.152 ms. There was no matched upstream latency A/B, so zero foreground performance regression is not established.

The planned size=64M/loops=2 write was incorrectly described as two passes over the same chunk. Actual IO covered adjacent chunks 0 and 1 once each. One real Write overlapped the selected chunk's batch; two separate Writes to the same chunk were not tested. B also had user reads and native compactions, so its entire reclamation cannot be attributed to idle; the two no-read rounds provide that evidence.

The first collector initially snapshotted an older subtree. Those snapshots were excluded; the five fio writes were correct and were not repeated. Only explicit-subtree observation was repaired; target inode matching and gap-free trace were rechecked, with the binary unchanged.

The [evidence index](raw-test-data/README.md) contains independent field summaries and archive hashes. Full sanitized archives are retained and available on request; the submission does not include credentials or user file contents. Overlap's 64 health samples were HEALTH_OK, with six OSDs up/in and no BlueFS spill. Read-side context-canceled warnings were retained; passing fio/CRC without an upstream A/B does not prove no change in their frequency.

## 4. Remaining boundaries

The cause experiments are not candidate tests. Local passes and these short functional checks do not establish sustained full-load capacity, production latency/throughput, near-65536-entry scan costs, persistent-error retry cost or slow-backend shutdown bounds. Restart recovery, other-client histories, non-Write mutations and overflow recovery are outside the proposal. Broader race failures remain recorded.

The current two-hour sequential overwrite's automatic reclamation/CRC acceptance is not yet complete and is not marked PASS. Further checks and their coverage are in the [field checklist](field-validation.md).
