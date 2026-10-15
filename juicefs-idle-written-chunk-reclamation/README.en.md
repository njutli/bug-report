# Overwrite history retained after writes stop: report and proposal (RFC)

[中文](README.md) · Base: JuiceFS v1.4.1, commit `0b90c7db5a929ae6adc5faad948d108efd2c99f9`.

## What is reported

We wrote 4 GiB of data on a normal JuiceFS mount, then fully overwrote the same files four times, writing 20 GiB in total. We stopped file IO and waited 60 minutes. With upstream JuiceFS, the Ceph pool still used 20 GiB more space than before the test. With the attached patch, the same test ended with only 4 GiB of extra space used, matching the file set's size.

We would like to ask: if overwrite mappings remain below the compaction threshold and file IO then stops, is there another background mechanism to reclaim the old data? Or is retaining this history an intentional way to reduce compaction overhead? The attached patch keeps a bounded list of chunks written by this client that need checking, inspects them after writes stop, and reuses existing compaction and deletion to reclaim old data.

## Documents

| Material | Purpose |
|---|---|
| [Bug report](bug-report.en.md) / [中文](bug-report.md) | Environment, simple reproduction commands, analysis and proposal |
| [Test report](test-report.en.md) / [中文](test-report.md) | Test steps, results and original records |
| [Actual workload script](reproduce/juicefs-overwrite-manual-check.sh) | Produces fio logs and `space.log`, not JSON |
| [Actual outer execution script](reproduce/lt002-plain-mount-ab.sh.txt) | Calls the workload and collects before/after JSON; original site-specific file for inspection only |
| [patches/](patches/) | One RFC implementation patch, separate test patch and baseline manifest |
| [Evidence index](raw-test-data/README.md) | fio/space records for both versions, plus patch 0002's focused regression and upstream negative-control logs |
| [SHA256SUMS](SHA256SUMS) | File checksums; verify with `sha256sum -c SHA256SUMS` |
