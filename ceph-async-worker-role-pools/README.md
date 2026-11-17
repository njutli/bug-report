# Role aware worker placement in Ceph AsyncMessenger

Base: Ceph Quincy 17.2.8, commit `f817ceb7f187defb1d021d6328fa833eb8e943b3`.

## Observed problem

In 16-stream sequential read/write tests on JuiceFS, larger application IOs did not produce corresponding throughput gains. Applications access a JuiceFS FUSE mount; TiKV stores filesystem metadata, while the JuiceFS client reads and writes file data directly through librados to a Ceph EC 4+2 pool, without RGW. Client data caching and writeback were disabled.

## Cause

Application IO size is not actual object size: increasing application IO alone does not change the JuiceFS volume block size. After using larger objects and increasing client supply, we identified a Ceph-side limitation: public client and inter-OSD cluster traffic concentrated on a few messenger workers, creating hotspots and send queueing. Similar connection counts do not imply similar processing load. The primary OSD also encodes writes and distributes EC shards, so both traffic classes need distributed processing.

## Proposed fix

Keep the total messenger worker count unchanged in comparisons, separate public connections from other connections, and place connections within each pool using live per-role reservations. Selection and reservation share a lock and cover connection establishment, release and protocol replacement. The mechanism does not change EC or durability semantics or migrate established connections online.

## Measured results

With 8 independent mounts, 16 streams and twelve AsyncMessenger worker threads per OSD, the same Ceph build containing observation code was tested with custom placement disabled/enabled, once each for 180 seconds:

| Metric | Native allocation → custom allocation |
|---|---:|
| Measured average JuiceFS file-write bandwidth | 9527.56 → 11598.22 MiB/s (+21.73%) |
| Hottest messenger worker CPU | About 96% → 58–59% of one core |
| Forward-plus-reply send queueing for the critical remote shard | About 18–21 → 0.40–0.45 ms (about 98% lower) |

This is the placement-policy improvement on top of an existing large-object/multi-mount configuration, not the cumulative gain of the entire tuning effort. Window methods and applicability are covered in the test report.

## Test environment and configuration

| Item | Configuration |
|---|---|
| Deployment | 1 client host and 3 storage hosts, with 2 BlueStore OSDs per storage host (6 total); TiKV is colocated on the storage hosts |
| Hardware and network | Approximately 1 TiB RAM per host; 2 × 7.68 TB NVMe data devices per storage host; the client public path uses a single 100 Gb/s port, MTU 4200 |
| Pool | EC 4+2, Jerasure plugin and reed_sol_van technique; 32 PGs, `min_size=5`; failure domain is OSD, not host |
| OSD messenger | POSIX AsyncMessenger; native `ms_async_op_threads` controls the total workers per OSD; both groups use 12 |
| Large-object write | 8 independent JuiceFS mounts × 2 streams = 16 streams; application IO 16 MiB, volume objects 4 MiB; psync/QD1, direct first writes; JuiceFS data cache and writeback disabled |
| JuiceFS client budgets | Aggregate uploads 150, in-flight bytes 1 GiB, buffer 2048 MiB across the mounts |

Each group runs once for 180 seconds. Ceph caches are not dropped and no extra warm-up is performed. Detailed conditions are in the attachments; patch-specific settings are in the test report.

## Detailed materials

- [Patch guide](patches/README.md): series contents, application and supported scope.
- [Test report](test-report.md): the 12-worker write comparison, CPU/queueing measurements and applicability.

## Attachments

[Test method and data](attachments/README.md): environment, commands and original outputs for this comparison.
