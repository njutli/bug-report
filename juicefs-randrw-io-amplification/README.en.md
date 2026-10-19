# JuiceFS v1.4.1: small-block random I/O produces about 23x object IO — is this expected?

[中文](README.md) · Base: JuiceFS v1.4.1, commit `0b90c7db5a929ae6adc5faad948d108efd2c99f9`.

We tested 256 KiB random read/write on JuiceFS v1.4.1 + TiKV + Ceph. The application read and wrote about 8 MiB/s each, but JuiceFS issued about 189 MiB/s each to the object store. Narrowing the test further showed that a single 64 MiB file with only two 256 KiB overwrites, followed by a 256 KiB read, can trigger one 64 MiB data compaction and re-upload.

We would like the community's help to understand: is this something we should adjust in our test method or configuration, or is it the expected trade-off of the current compaction strategy for small-block random overwrite/read workloads? What configuration or usage is recommended?

| Document | Contents |
|---|---|
| [Bug report](bug-report.en.md) / [中文](bug-report.md) | Environment, main observations, our understanding of the cause, and the questions we are asking |
| [Test report](test-report.en.md) / [中文](test-report.md) | Two experiments: 30-minute random read/write, and a single-file minimal reproduction |
| [Reproduction method](reproduce/README.en.md) / [中文](reproduce/README.md) | Actual test steps, mount parameters, fio parameters and how the counters were collected |
| [Raw data](raw-test-data/README.en.md) / [中文](raw-test-data/README.md) | fio output, before/after IO counters, slice mappings and the source manifest |

Read/write amplification is the object bytes divided by the application bytes for the same client and the same window. The object IO here does not yet include lower-level overhead such as Ceph erasure coding or disk journaling, and it is not a capacity-usage multiplier.
