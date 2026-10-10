# V3 verification report

7 October 2026. [中文](test-report.md)

## Method and provenance

Pinned v1.4.1 base; recorded field binary contains B-catchup + native V2 + V3. B-catchup is separate from this series. Local backends were memkv, SQLite and an isolated Redis instance, not TiKV. Real-cluster runs used TiKV/Ceph in the 192 test environment, with block size 256 KiB, trash-days 0, cache/writeback/async_dio off, max-uploads 150, backup-meta 0 and idle-compact-delay 2m. Idle observations did not read user files or invoke manual compact/GC. Reclamation evidence was frozen before full CRC, because reads can independently trigger ordinary compaction.

## Local evidence

V2: nine automatic-trigger cases fail with `IDLE_TRIGGER_MISSING`. V3: the same nine cases pass three race repetitions (27). Further V3 mechanics: 108 passes; inherited V2 retry/object regressions: 66; default-disabled C13 controls: 24. Total: 225 passing leaf executions, zero failures/skips/race reports, not 225 unique scenarios. Selected existing backend/CLI/VFS regressions pass; the full external-service matrix was not run.

Real-object tests use a real session timer, SQLite and in-memory ObjectStorage, exercising actual compaction and object deletion. Two cases repeated three times converge automatically before 98,304-byte content/CRC checks. They are not Ceph tests. Separate upstream/V2 diagnostic controls each reproduce the low-count gap in 24 executions; these are outside the 225 total.

## Field evidence

| Run | Actual load | Idle reclamation before CRC | Integrity and attribution |
|---|---|---|---|
| C14 | 8-GiB data, 40 GiB written including layout | References 16→8 and about23.94→8 GiB | Full8-GiB CRC passes. A loops-count script failure is preserved; separate continuation supplies missing work. Actual object-IO overlap with resumed foreground IO was not fully demonstrated. |
| C15 | 64-GiB data,16-MiB sequential writes,16 jobs,psync/QD1;2h,298 GiB written | References362→64 GiB, shadowed history about297.95→0;1,024 idle attempts;first minimal sample about2h31m after stopping | Full64-GiB CRC passes. Manual cleanup occurred only before the clean formal baseline. |
| C16 | 128-GiB data,256-KiB randrw50:50,128 jobs,libaio/QD128;2h,read159.664/write159.512 GiB | References about270.48→128 GiB;first minimal sample about3h02m;one idle attempt | Full128-GiB CRC passes. Ordinary compaction did most reclamation. |
| C17 | Same128-GiB data,256-KiB randwrite;2h,write219.019 GiB,read0 | References346.778→128 GiB;first minimal sample about2h48m,pending drained about3h33m;zero idle attempts | Full128-GiB CRC passes. Compatibility evidence, not isolated contribution of the new trigger. BlueStore slow-operation warnings remained. |

Times are observations with roughly15-minute sampling, not production SLAs. Frozen pool stored deltas for C15–C17 were approximately−11.875/−4.25/+4.3125 MiB from baseline. Shared-pool statistics are supporting evidence, not exact subtree release accounting.

C18 completed five hours then closed at an operator-requested hourly boundary; it is not a24-hour pass. Later burst/idle and24-hour read tests are not counted as accepted results here without bundled review. Read acceptance cannot substitute for write acceptance. Continuous overload capacity, restart recovery, multi-client behavior, overflow coverage and controlled foreground performance non-regression remain open.

## Reproduction and package limits

Apply the four patches in README order. In an independent source tree, copy `raw-test-data/diagnosis/c13_threshold_diagnosis_test.go` into `pkg/meta/` for the C13 controls, and run the Go commands in [test-report.md](test-report.md). The dedicated Redis socket must be configured through `COMPACT_RETRY_REDIS_SOCKET`; tests reset that database, so never point it at an existing service. Otherwise Redis subtests skip and the three-backend claim is invalid.

For the V2 negative control, use patches1 and2 only, copy the bundled `raw-test-data/diagnosis/idle_trigger_regression_test.go` into `pkg/meta/`, and run `TestIdleTriggerRegression`. That single test compiles on V2; the other tests in patch4 require V3 implementation, so do not apply patch4 as a whole to V2. All nine cases are expected missing-trigger failures. This material preparation verified recorded evidence and patch replay, not newly executed Go or cluster tests. Recorded local logs used the B-catchup source combination; applying this series to upstream is not claimed to have been rerun with identical counts here.

The package includes local logs, sanitized C13 summaries, C14 timeline, C15 result/frozen recovery/CRC and C16/C17 core fio/runtime evidence. C15 complete formal fio logs remain remote; an attempted read-only fetch timed out, and they are not fabricated or silently treated as bundled. User data, raw volume dumps, access credentials, large binaries and full per-second logs are excluded. The verifier covers bundled evidence, not the entire field history or latest live state.
