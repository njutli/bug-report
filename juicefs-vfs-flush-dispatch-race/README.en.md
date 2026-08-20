# JuiceFS VFS flush dispatch race fix

When a new slice's ID is allocated asynchronously, a full block written before
the ID is ready is never dispatched — the write path checks `s.id == 0` and
skips `FlushTo`, and the ID-ready path only calls `SetID` without a catch-up
dispatch.

On v1.3.x this bug causes a ~3.4x randwrite throughput collapse (560.9 vs
1917.0 MiB/s). On main the same race exists but is masked by faster fallback
drainage.

## Files

| File | Description |
|------|-------------|
| `bug-report.md` | Problem description, root cause analysis, v1.3 vs main |
| `patches/0001-vfs-dispatch-complete-blocks-after-preparing-slice-id.patch` | Fix: 7 lines in `pkg/vfs/writer.go` |
| `patches/0002-vfs-add-regression-tests-for-flush-dispatch.patch` | Regression tests: 3 deterministic tests (243 lines, new file) |
| `test-report.md` | Test steps, results, design rationale, raw data paths |
| `raw-test-data/U01/` | All raw logs, RC files, metadata, diffs, results |

## Patches

Two patches, applied in order on `53835e2481f45cba159cdbcc1ce0f1fc576e3f1a`:

```bash
git am patches/0001-vfs-dispatch-complete-blocks-after-preparing-slice-id.patch
git am patches/0002-vfs-add-regression-tests-for-flush-dispatch.patch
```

0001 is the production fix. 0002 is the regression test that deterministically
verifies the bug and the fix.

## How to verify

```bash
git clone https://github.com/juicedata/juicefs
cd juicefs
git checkout 53835e2481f45cba159cdbcc1ce0f1fc576e3f1a
git am <path-to>/0001-*.patch
git am <path-to>/0002-*.patch

# Run the three regression tests
go test -v -count=1 -run '^Test(FullBlock|PartialBlock|FlushError)' ./pkg/vfs/

# Run full pkg/vfs (needs Redis on 127.0.0.1:6379)
go test ./pkg/vfs -count=1
```

Expected: all tests pass. On unpatched stock, the full-block and error-path
tests fail with their target markers; the partial-block control passes.

## Author

Li Lingfeng <a1151488180@gmail.com>
Assisted-by: DeepSeek <deepseek-v4-pro>
