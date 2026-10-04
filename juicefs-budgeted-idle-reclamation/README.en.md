# JuiceFS: minimal native retry for busy compaction admission

2026-09-29; field results updated through 2026-10-04 13:30 Beijing time. [中文](README.md)

**The fix candidate changes only `pkg/meta/base.go`: 42 insertions, five deletions.** Ordinary requests rejected by the global or same-chunk admission guard are coalesced by chunk and retried through the existing ordinary batch when a compactor releases a slot. Short field validation is available; production and 24/72-hour endurance acceptance are not complete.

| Patch | Scope |
| --- | --- |
| [0001-meta-retry-compaction-after-busy-admission.patch](patches/0001-meta-retry-compaction-after-busy-admission.patch) | Native fix, one file, +42/-5 |
| [0002-meta-test-busy-compaction-retries.patch](patches/0002-meta-test-busy-compaction-retries.patch) | Separate regression/object tests, two files, +621; no dependency changes |

Both are Git mail patches with author, date, subject, commit message, diffstat and base-commit. Apply at the root of a clean **v1.4.1 / `0b90c7db5a929ae6adc5faad948d108efd2c99f9`** checkout:

```sh
REPORT=/absolute/path/to/juicefs-budgeted-idle-reclamation
git am "$REPORT/patches/0001-meta-retry-compaction-after-busy-admission.patch"
git am "$REPORT/patches/0002-meta-test-busy-compaction-retries.patch"
```

## Relationship to the earlier V2 proposal

The earlier `juicefs-idle-compaction-reclamation/revised-fix-v2/budgeted-reclamation.patch` is a scan-based maintenance feature, not a minimal native fix. It also predates the subsequent TiKV prefetch-budget correction. Adding that correction does not turn V2 into this native fix.

This package has been replaced with the native retry implementation. It adds no scan, periodic worker, CLI option, benefit policy or metadata format. TiKV scanning is untouched, so the separate TiKV delta is not needed. These two patches apply directly to the pinned release.

## Reports and verification

- [Problem, root cause and changes](bug-report.en.md)
- [Detailed code flow and patch walkthrough (Chinese)](code-flow.md): call hierarchies, function/file locations, metadata and object lifecycle, and retry slot ownership.
- [Tests and reproduction](test-report.en.md)
- [Evidence index](raw-test-data/README.md)

The same tests produce **13 intended failures and nine passing controls on stock**. The fix passes **22 leaf cases × three race repetitions = 66 passes, zero skips**, covering memkv, SQLite, isolated Redis and real `vfs.Compact` content/CRC/deletion. Generic build and selected existing engine regressions pass; the full meta core target is blocked by unavailable isolated TiKV PD.

Field update: completely unmodified upstream also retained history after writes stopped. B-catchup plus this candidate reached minimal references after two-hour randrw and randwrite runs on a 128 GiB dataset, first observed about 2 h 34 min and 3 h 05 min after writes stopped; full CRC then passed. Idle observations used no user-file reads, manual compact or GC. A 64 GiB sequential-overwrite run stopped at the capacity safety floor after about 1 h 45 min; complete reclamation and final CRC remain unverified. See [field validation](test-report.en.md#field-validation).

Retry state belongs to the current client and is not durable. Each retry uses an existing ordinary batch, without forcing all history down to one slice. Sustained-overload capacity bounds, foreground performance non-regression, 24/72-hour endurance and restart recovery remain unaccepted. This is not a claim that all reclamation issues are solved.

From this report directory:

```sh
python3 tools/verify.py
python3 tools/verify.py --source /absolute/path/to/patched-juicefs
```
