# Retained slice references after overwrite IO stops

[中文](README.md)

A fixed logical dataset retained obsolete object references after overwrite IO stopped. An idle observation of 24 hours did not return object-store usage to its starting level. Targeted manual file compaction reclaimed objects without CRC errors.

The admission limit is a protection, not itself the defect. The question is whether cold chunks whose compaction was skipped, or whose history remains below IO-trigger thresholds, need durable rediscovery. This is a reclamation-liveness/space-amplification report, not a demonstrated data-loss report.

## Status and contents

- Maintenance fallback: eight existing files compacted and fully CRC-verified; pool `stored` fell by 8.89 GiB. Repeated overwrite/maintenance results are in the test report.
- Candidate: default-off `--compact-interval`, periodic serial traversal of the mounted subtree, reusing existing compaction and transactional checks.
- Offline: stock-failing/candidate-passing regression, isolation/retry/cancellation/race tests, real object-content and session-restart integration tests.
- TiKV/Ceph canary: after client process restart, the same 1 GiB file converged from **3,402 to 16 records / 1.845 to 1 GiB** with no user IO/manual compact, confirmed at the ~99s sample; full CRC and normal unmount passed.
- **Not production acceptance or an upstream-approved fix.** Scan cost, in-flight cancellation and multi-client coordination remain discussion topics.

`bug-report[.en].md` explains mechanisms and attribution limits; `test-report[.en].md` records validation; `patches/` contains ordered regression, implementation and extended-test commits; `raw-test-data/` contains a sanitized compact evidence set.

Base: official v1.4.1 commit `0b90c7db5a929ae6adc5faad948d108efd2c99f9`. The environment also carries a separately documented VFS B-catchup fix; it is not included in these three patches.

```bash
git checkout 0b90c7db5a929ae6adc5faad948d108efd2c99f9
git am /path/to/patches/0001-*.patch
# Expected: 8 positive cases fail, 2 cancellation controls pass.
# This encodes the candidate's rediscovery contract, not a previous API promise.
go test -count=1 -run '^TestIdleCompactionMechanism$' ./pkg/meta
git am /path/to/patches/0002-*.patch /path/to/patches/0003-*.patch
go test -race -count=3 -run '^TestIdleCompaction' ./pkg/meta
go test -race -count=5 -run '^TestIdleCompactionRealObjectIntegration$' ./pkg/vfs
go test -count=1 -run '^TestIdleCompactionMountConfig$' ./cmd
```

Author: Li Lingfeng. 2026-09-27.
