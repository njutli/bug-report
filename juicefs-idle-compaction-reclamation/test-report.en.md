# Validation report

2026-09-27. Native idle observation, manual maintenance and candidate automation are separate evidence categories; none alone is long-term production acceptance.

## 1. Original observation and instrumented mechanism

| Experiment | Observed result | Limit |
| --- | --- | --- |
| Original LT-002 | Fixed 128 GiB, two hours of 256K randrw; fio and full CRC passed | No per-trigger trace |
| Idle observation | 289 samples over about 24h, all HEALTH_OK; stored 348,283,477,420→348,129,107,372 B (only 0.144 GiB reclaimed); still +89.795 GiB over prewrite baseline; compaction count stayed 2255 | Finite observation, not proof of never reclaiming or one exclusive cause |
| B2 new-file trace | 1 GiB file / 8 GiB overwrite; 26,649 triggers, 26,616 skips, 33 successful compactions; 9,837 records remained after ~3 idle minutes | Instrumented mount used no-bgjob; do not generalize its skip rate |

Retained-slice bytes and pool stored are not EC-expanded physical disk bytes or proof of BlueStore DB reclamation.

## 2. C1: maintenance fallback

Eight exact old 1 GiB files were compacted sequentially with `juicefs compact --threads 1 <file>`. Their record counts were 4,965 / 5,437 / 5,251 / 5,233 / 5,406 / 5,676 / 4,759 / 5,035; each ended at 16 records and 1 GiB of slice references. Full CRC passed for all eight; the other 120 files' analyzed metadata rows were unchanged.

Each compact took about 86–158 seconds. Net pool stored reduction: **9,543,876,608 B (8.89 GiB)** and **37,740 objects**. Files were not deleted and no whole-volume GC was run.

A separate 1 GiB CRC file then underwent three cycles, each a fixed 8 GiB overwrite (256K/libaio/one job/QD4/16MiB/s), followed by compact, stable pool samples, metadata dump and full CRC:

| Cycle | Before records | Before full-slice GiB | Compact seconds | After | CRC |
| --- | ---: | ---: | ---: | --- | --- |
| 1 | 11,196 | 4.0078 | 155.0 | 16 records / 1 GiB | PASS |
| 2 | 10,558 | 3.8313 | 145.3 | 16 records / 1 GiB | PASS |
| 3 | 9,370 | 3.4900 | 164.6 | 16 records / 1 GiB | PASS |

All three low-water marks were **342,023,380,396 stored bytes / 1,329,334 objects**: zero spread, 0.313 MiB below initial pool baseline. All 19 fio JSON results had error=0; all 256 health samples were HEALTH_OK with six OSDs up/in.

### Foreground cost

An already-compacted different file received 120-second 256K/QD1 reads capped at 8MiB/s before, during and after maintenance:

| Phase | MiB/s | Mean total latency ms | P99 total latency ms |
| --- | ---: | ---: | ---: |
| Before | 8.00 | 9.65 | 13.17 |
| First 120s during | 8.00 | 14.13 | 139.46 |
| After | 8.00 | 9.58 | 13.04 |

P99 increased approximately 10.6×. **This supports a maintenance-window fallback, not impact-free online compaction.** The ~863s in read-during's supervisor runtime is delayed child collection; actual fio read runtime is 120001ms, the correct throughput denominator.

## 3. Offline candidate

Pinned official v1.4.1 base.go matched the publicly fetched commit byte-for-byte. Go 1.26.0, isolated caches/SQLite/object backend; no cluster changes.

| Check | Result |
| --- | --- |
| Fresh source archive + patch 1 only | Same test compiles: eight positive cases fail due to missing idle rediscovery, two cancellation controls pass |
| Add patch 2 | Pass: concurrency skips, same-chunk busy, below threshold, transient failure and bounded 1024→25→1 retry |
| Extended meta/race | Subtree isolation, disabled/readonly/no-bgjob gates, scheduling, throttle and cancellation; final race repeated three times passed |
| Real objects/race | SQLite + memory object backend with real vfs.Compact and DeleteSlice; three partly overlapping 64KiB writes: 192KiB history→96KiB visible data; exact bytes/CRC preserved, three old objects deleted; rediscovery after session restart; final race repeated five times passed |
| CLI | 0/1h/15s option propagation passed |
| Existing engine regression | TestMemKVClient/TestSQLiteClient/TestBadgerClient plus new tests passed (~63s) |
| make test.meta.core | Attempted; Redis connection blocked by sandbox. **Not a full-suite pass or full Redis/TiKV regression** |

The in-flight cancellation test intentionally documents that session shutdown waits until an entered object callback returns. No subsequent chunk starts after cancellation; no strict cancellation deadline was added.

Candidate binary SHA256: `09ea7095454f987e345eb4aa7f08f1b18c10868a7b6d5ddec248cd68d85cee8d`. The environment build separately applied the existing seven-line writer.go B-catchup fix; these meta patches do not bundle it or other performance experiments.

## 4. C2: scoped TiKV/Ceph canary

**PASS: normal unmount completed at 14:57 local time; not long-term production acceptance.** Independently recomputed raw metadata dumps, four fio JSON files, the executed command ledger and 72 health samples.

| Sample | Records | Full-slice bytes |
| --- | ---: | ---: |
| Immediately after writes, scanner off | 7,320 | 3,025,666,048 |
| After 180s idle | 3,402 | 1,981,022,208 |
| Another 30s, after unmount and before enabling | 3,402 | 1,981,022,208 |
| Enabled new session, 2.4s | 3,402 | 1,981,022,208 |
| 34.5s | 2,696 | 1,794,899,968 |
| 66.7s | 854 | 1,303,117,824 |
| 98.7s | 16 | 1,073,741,824 |

OFF stable snapshots and the ON starting snapshot have identical chunk arrays. The earlier 7,320→3,402 reduction is late ordinary compaction, not candidate benefit. The logged scan root matched the new subtree inode; its first traversal took 55.783s. 98.7s is the sampling point confirming convergence, not exact completion time or a production deadline. Final 1GiB CRC began 34s after the converged snapshot and passed with error=0; inode/size/mtime were unchanged.

Reference reduction: **907,280,384 B (865.25 MiB)**. Net pool stored reduction: **907,673,600 B (865.625 MiB)** and 3,462 objects. Pool end was 0.375 MiB below the layout baseline with the same object count; that small difference is not attributed precisely to the file. All 72 health samples were HEALTH_OK with six OSDs up/in; minimum max_avail was 863,464,259,584 B. The command ledger confirms **two private mounts, two normal unmounts, zero manual compact/GC**. Repeated UMOUNT_PASS events are continuation-time rechecks, not additional unmount commands.

With the candidate's new scanner disabled (interval=0), create a 1GiB CRC file. Sixteen jobs overwrite disjoint 64MiB ranges, each writing exactly 512MiB (8GiB total), bs256K/QD4, capped at 1MiB/s each. A scaled local fixture first verified partitioning and full CRC semantics.

After writes stop, no data read/manual compact is allowed. Use metadata dumps, idle for 180s, then require two identical snapshots 30s apart. Normally unmount and remount the same subtree with interval=15s. Observe automatic traversal without new user IO, and only after reference convergence run full CRC and normal unmount. CRC reads therefore cannot explain the measured convergence.

Verify volume UUID, effective subdir/options, worker PID/start time/executable; preserve the original mount. The first mount succeeded but an argv identity check stopped before any data IO because daemon process titles truncate long commands. Replace the check with effective configuration + executable + process topology, then adopt the same mount without another mount attempt. This harness incident is retained, not reported as a flawless first run.

A second harness race occurred after normal OFF unmount: a parent process exited between ps enumeration and reading `/proc/<pid>/exe`. Independently confirming the mount/process were gone and file identity matched saved cold metadata allowed continuation of ON only. The read-only process check now tolerates vanished/zombie processes, not identity/permission mismatches. A subsequent comparison exposed integer histogram keys in memory versus string keys after JSON decoding: independent saved snapshots were identical. Canonical full-JSON comparison, with positive/negative tests, fixed the false difference. No overwrite or OFF mount was repeated; ON had not been mounted by either continuation failure. All three failure records remain; candidate source and binary were unchanged.

Subdir restricts the new scan, not all existing background deletion. Accordingly, **scoped reference convergence and content correctness are primary; whole-pool stored change is corroboration only**.

## 5. Untested and evidence handling

Not tested: candidate 2/24/72h operation, full-load scanning, multi-client conflict, crash/power loss, full Redis/TiKV unit suites, large-tree overhead, permanently stuck object requests or bounded shutdown. A small canary does not approve production deployment or a larger stress run.

Full originals remain private. Published files remove credentials, real hosts, private user/paths and volume UUIDs; no complete metadata dumps or binaries are published. `raw-test-data/manifest.json` records original and sanitized hashes. Numeric measurements, events and outcomes are unchanged. Memory-object integration is not a Ceph load test.
