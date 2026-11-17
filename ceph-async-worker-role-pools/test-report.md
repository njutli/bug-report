# Ceph AsyncMessenger write comparison

With 12 AsyncMessenger worker threads per OSD, enabling role-aware placement increased average JuiceFS file-write bandwidth from **9527.56 to 11598.22 MiB/s (+21.73%)**, while reducing the hot worker's CPU and critical-shard send queueing.

## Test configuration

Both groups use the same Ceph Quincy 17.2.8 build containing observation code. N12 uses native allocation; R12 enables custom allocation. This is a placement-switch comparison, not stock binaries versus a core-only patched build.

| Setting | N12 | R12 |
|---|---|---|
| Native `ms_async_op_threads`, per OSD | 12 | 12 |
| Custom `CEPH_T088_WORKER_POLICY` | 0, native allocation | 1, custom allocation |
| Custom `CEPH_T088_PUBLIC_WEIGHT` / `CEPH_T088_OTHER_WEIGHT` | Not used | 1 / 2 |
| Worker pools | Native allocation | Public 4 + other 8 |

One client, three storage hosts, six OSDs, EC 4+2; eight independent JuiceFS mounts with two streams each. Application IO is 16 MiB, volume blocks 4 MiB, psync/QD1/direct first writes, `end_fsync=1`, 256 GiB per-file cap without wrapping. Each group runs once for 180 seconds. Aggregate uploads 150, in-flight bytes 1 GiB and buffer 2048 MiB remain unchanged; JuiceFS data caching and writeback are disabled.

## Results

| Metric | Native N12 → custom R12 |
|---|---:|
| Average file-write bandwidth, mean of two non-tracing windows | 9527.56 → 11598.22 MiB/s (+21.73%) |
| File-write bandwidth, 73–91 s | 9440.89 → 11604.44 MiB/s (+22.92%) |
| File-write bandwidth, 130–148 s | 9594.67 → 11592.89 MiB/s (+20.83%) |
| Hottest worker CPU, 73–91 s | 95.76–96.00% → 58.98–59.16% of one core |
| Hottest worker CPU, 130–148 s | 95.75–95.98% → 58.06–58.21% of one core |
| Critical-shard forward-plus-reply send queueing, 73–91 s | 20.528 → 0.403 ms (−98.04%) |
| Critical-shard forward-plus-reply send queueing, 130–148 s | 18.482 → 0.447 ms (−97.58%) |

The reported average uses 21–39 and 159–177 seconds without event tracing. CPU and queueing use the two event windows shown above. Queueing is the request-weighted sum of forward and reply send waits for the last required remote shard, not full object latency. [Window data and original outputs](attachments/raw-test-data/README.md)

## Conclusion and scope

At unchanged worker and client budgets, lower worker CPU concentration and send queueing accompany higher throughput. This supports role-aware connection placement as an effective improvement for this large-object, multi-mount write workload.

Each configuration has one run; two windows are not independent repetitions or a long-term stability result. Other tests did not show consistent gains at six workers, and mixed-read call latency increased. These results do not establish all-workload non-regression or core-only performance.

[Test environment](attachments/reproduce/ENVIRONMENT.md) · [Test method](attachments/reproduce/PROCEDURE.md) · [Test data](attachments/raw-test-data/README.md)
