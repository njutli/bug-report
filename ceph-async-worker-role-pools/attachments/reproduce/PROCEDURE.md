# Test method

This comparison measures the JuiceFS write-bandwidth change from 9527.56 to 11598.22 MiB/s. [Environment](ENVIRONMENT.md) · [Results](../../test-report.md) · [Original data](../raw-test-data/README.md)

## Two configurations

| Group | AsyncMessenger threads per OSD | Connection placement |
|---|---:|---|
| N12 | 12 | Custom policy disabled, native allocation |
| R12 | 12 | Custom policy enabled, public 4 + other 8 |

Use the same Ceph build containing observation code for both groups. The policy's startup variables are listed in the test report and [patch guide](../../patches/README.md). Stop test IO before changing OSD settings, confirm all six OSDs are ready, then establish connections under the intended policy. Restore the original settings afterward.

## Client mounts

Both groups use the same locally modified JuiceFS 1.4.1 binary, reporting `1.4.1+unknown`, and fio 3.28. All eight independent mounts, c0–c7, access the same volume with 4 MiB blocks. Client budgets are divided across the mounts, not repeated in full on each mount:

| Setting | Per mount | Total across eight mounts |
|---|---|---|
| `--max-uploads` | 19 for c0–c5; 18 for c6–c7 | 150 |
| `--max-downloads` | 25 | 200 |
| `--buffer-size` | 256 MiB | 2048 MiB |
| `--max-readahead` | 8 MiB | 64 MiB |
| `objecter_inflight_op_bytes` | 134217728 bytes (128 MiB) | 1 GiB |
| `objecter_inflight_ops` | 128 | 1024 |
| Client `ms_async_op_threads` | 1 | 8 |

The last three options belong to each mount's librados client configuration, not the OSD configuration. Each OSD uses 12 threads in this comparison. Add these overrides to a separate copy of the working Ceph client configuration for each mount:

```ini
[client.juicefs]
objecter_inflight_op_bytes = 134217728
objecter_inflight_ops = 128
ms_async_op_threads = 1
```

Example for c0, with test paths and TiKV endpoints to be supplied for the target environment:

```sh
juicefs_bin=/absolute/path/to/tested-juicefs
meta_url='tikv://PD1:2379,PD2:2379,PD3:2379/test-volume'
CEPH_CONF=/absolute/path/to/c0.conf \
CEPH_ADMIN_SOCKET=/absolute/path/to/c0/client.asok \
CEPH_LOG_FILE=/absolute/path/to/c0/client.log \
  "$juicefs_bin" mount -d --max-fuse-io 1M \
  --max-uploads 19 --max-downloads 25 --buffer-size 256 \
  --max-readahead 8 --cache-size 0 \
  --cache-dir /absolute/path/to/c0/cache --metrics 127.0.0.1:21101 \
  "$meta_url" /absolute/path/to/c0/mount
```

Use distinct mount, cache, socket and log paths, client configuration files, and metrics ports 21101–21108 for c0–c7; c6/c7 use `--max-uploads 18`. Do not enable `--writeback`. `--max-fuse-io 1M` is a FUSE request limit, distinct from the 16 MiB application IO and 4 MiB volume block size.

## Workload and commands

- Eight independent JuiceFS mounts, two file writers per mount: 16 concurrent sequential streams.
- Application IO 16 MiB; JuiceFS volume blocks 4 MiB; psync, QD1, direct first writes, `end_fsync=1`.
- Each group runs once for 180 seconds, with a 256 GiB/file cap and no wrap or overwrite. Use fresh test filenames for each group.
- Keep aggregate uploads 150, in-flight bytes 1 GiB and buffer 2048 MiB unchanged. JuiceFS data caching and writeback are off; do not drop Ceph caches or add a separate warm-up.

The complete original jobs are [N12/jobs.fio](../raw-test-data/mechanism/N12/jobs.fio) and [R12/jobs.fio](../raw-test-data/mechanism/R12/jobs.fio). Adapt their file/log paths and lab-specific `exec_prerun` timing hook to a dedicated test deployment; retain the IO parameters and record the new run's timing origin.

```sh
# Native placement, after preparing the eight mounts and fresh files:
fio --output-format=json --output=/absolute/N12-fio.json /absolute/N12-jobs.fio
# Custom placement, after switching policy and reconnecting the mounts:
fio --output-format=json --output=/absolute/R12-fio.json /absolute/R12-jobs.fio
```

The groups run separately, not concurrently. Save fio output and all 16 per-IO bandwidth logs. Each run writes a TiB-scale dataset; reserve EC capacity and reclaim only the run's own test files between groups, returning capacity/background activity to comparable conditions.

## Observation windows

Average write bandwidth is the arithmetic mean of two 18-second windows, 21–39 and 159–177 seconds, without event tracing. Record CPU and EC events in 73–91 and 130–148 seconds; each duration uses timestamps from the same host. New event collection requires local LTTng setup and timing markers.

CPU is messenger-thread usage, with 100% representing one logical CPU. Critical-shard queueing sums the request and reply send waits for the last required remote shard, not total object latency. The two windows belong to one run, not independent repetitions.
