# JuiceFS V3: filling the idle trigger gap for overwritten chunks

7 October 2026, UTC+8. [中文](README.md)

This is a functional fix candidate, not a blanket production acceptance claim. V3 extends native busy-admission retry (V2) to cover overwritten history that never produces an ordinary compaction request. Deterministic local controls and short real TiKV/Ceph runs support reclamation and integrity in the tested scenarios. Continuous 24/72-hour write acceptance, restart recovery and controlled foreground performance non-regression remain unverified.

V2 retries requests rejected by busy admission. It cannot retry a request that was never generated. Large overwrites can retain many obsolete bytes while keeping the per-64-MiB-chunk mapping count below the Write trigger. Small writes after a compaction snapshot can leave the same gap. In C13, 64 GiB of logical data still referenced 211.39 GiB of slices, including 147.36 GiB completely shadowed within the tested subtree.

V3 tracks only chunks successfully written by this client. After metadata Read/Write is quiet, one worker checks for byte overlap and reuses ordinary compaction, CAS replacement and reference-counted deletion. It does not scan the volume.

- [Problem and boundaries](bug-report.en.md)
- [Tests and reproduction](test-report.en.md)
- [Implementation flow](code-flow.md) (Chinese)
- [Evidence index](raw-test-data/README.md) and [patch manifest](patches/manifest.json)

Base: JuiceFS v1.4.1, commit `0b90c7db5a929ae6adc5faad948d108efd2c99f9`. Apply the four patches listed in [README.md](README.md) in order with `git apply`. The first two are unchanged V2 implementation/test prerequisites; the third and fourth are the verified V3 implementation/test diffs. They are not all email patches: do not use `git am` for the raw V3 diffs. On an already patched V2 source including its test fixtures, apply only patches 3 and 4.

Real-cluster tests used VFS B-catchup + V2 + V3. B-catchup is not included in this reclamation patch series. Applying the four bundled patches to upstream therefore does not reproduce the exact field binary. Its recorded version is `1.4.1+2026-07-30.0b90c7d-lt002-idle-written-v3`; SHA256 `c2307d90c9184c7d48a9770c8d775a093671496c5569d0e5f7c81d594d7b3b6f`.

Opt in with `--idle-compact-delay=2m`; default 0 disables it. Read-only and no-bgjob mounts disable the worker. Two minutes is a tested setting, not a production-tuned recommendation. The process-local tracking limit is 65,536 chunks, with observable overflow. It does not discover pre-remount history or independent writes from other clients, bound storage growth under continuous overload, or preempt a batch already running when foreground IO resumes.

Verify the package without running tests or connecting to a cluster: `python3 tools/verify.py`. This preparation did not change any cluster or publish to GitHub. The original V2 material is preserved.
