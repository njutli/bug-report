# Test environment

| Item | Configuration |
|---|---|
| Ceph | Quincy 17.2.8, base `f817ceb7f187defb1d021d6328fa833eb8e943b3` |
| JuiceFS client | 1.4.1 with a local [write-dispatch fix](https://github.com/juicedata/juicefs/discussions/7427), reporting `1.4.1+unknown`; identical client binary in N12 and R12 |
| Load generator | fio 3.28 |
| Deployment | One client (157); three storage hosts (150/151/152), two BlueStore OSDs each; TiKV colocated on the storage hosts |
| Client CPU | 2 × Xeon 8462Y+, 32 cores/socket, 2 threads/core, 128 logical CPUs; session `nproc=96`. Storage CPU models were not recorded |
| Memory | Approximately 1 TiB per host; client MemTotal 1007.38 GiB |
| Storage | 2 × 7.68 TB NVMe data devices per storage host, LVM BlueStore; separate approximately 960 GB TiKV device |
| DB/WAL | Inventory includes 128 GiB DB and 10 GiB WAL loop devices and `/mnt/dbwal` tmpfs; full loop backing-file mapping was not recorded |
| Public network | One client 100 Gb/s port, `enp139s0f0np0`, MTU 4200, shared by routes to all three storage hosts |
| Pool | `juicefs-data`, EC 4+2, Jerasure/reed_sol_van, `w=8`, `min_size=5`, PG/PGP=32, autoscale off, fast_read on, EC overwrites enabled, stripe width 16384 bytes |
| Failure domain | OSD, not host; this is a three-host/six-OSD test deployment |
| Kernel | Client `5.15.0-170-generic`, storage host 150 `5.15.0-186-generic` |
| Ceph build | RelWithDebInfo, `-O2 -g -DNDEBUG`, tcmalloc; LTTng on, Babeltrace/RDMA/DPDK/Seastar off |

## Comparison controls

- Each group runs for 180 seconds, with 12 workers per OSD. Keep client budgets, file starting conditions and cache settings unchanged.
- JuiceFS data caching and writeback are disabled. Ceph caches are not dropped and there is no extra warm-up.
- Test batches pause and restore scrub, reclaim only their own test writes, and return capacity/background activity to comparable starting conditions. TiKV remains colocated on the storage hosts.

Workload parameters are in [test methods](PROCEDURE.md). Hardware/configuration records are under [environment](../raw-test-data/environment/).
