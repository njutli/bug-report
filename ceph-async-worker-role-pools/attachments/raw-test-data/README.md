# Test data

These files support the 12-worker placement comparison: **9527.56 → 11598.22 MiB/s (+21.73%)**. N12 uses native allocation; R12 enables role-aware allocation in the same Ceph build. [Test report](../../test-report.md)

| Data | Contents |
|---|---|
| [Window table](tables/mechanism-windows.csv) | Eight rows: four windows per group, with bandwidth and observed CPU/queueing |
| [Native write outputs](mechanism/N12/) | Original fio output, full job parameters, first-write record and 16 compressed per-IO completion logs |
| [Custom write outputs](mechanism/R12/) | Matching outputs for custom placement |
| [Native CPU and events](mechanism-detail/N12/) | Three-host thread samples, window markers, associated requests and six-OSD EC event extracts |
| [Custom CPU and events](mechanism-detail/R12/) | Matching samples and event extracts for custom placement |
| [Comparison analysis](analyses/mechanism.json) | The two groups' per-worker CPU, connection-role observations, critical queueing and request counts |
| [Environment records](environment/) | Hardware, pool, network and build records |

## Measurement definitions

Write bandwidth sums completed bytes in each 18-second window. The headline averages 21–39 and 159–177 seconds without tracing; CPU and queueing use 73–91 and 130–148 seconds. Percentage change is `(after/before−1)×100%`; MiB is 2²⁰ bytes.

CPU 100% means one logical CPU; its lower/upper values reflect sampling-time bounds, not a statistical confidence interval. Queueing is the request-weighted forward-plus-reply send wait for the last required remote shard, not full object latency or pure network time.

The EC extracts cover the archived analysis's request set, not all CTF traces. R12 window markers are reconstructed from original boundary records; its combined marker and contemporaneous post-test capacity record are unavailable.
