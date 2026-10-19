# Actual test method

The following describes the [attached raw data](../raw-test-data/README.en.md); it is not a separate test run. The complete measured command for each workload step is stored in the corresponding `argv.json`, with the fio output in the adjacent `fio.json`. Node and path names are written as variables here; the raw records keep the parameters as executed.

## 1. Environment and mount

We used JuiceFS v1.4.1, commit `0b90c7db5a929ae6adc5faad948d108efd2c99f9`, built with Ceph support. TiKV manages file metadata and Ceph RADOS stores objects; Ceph version 17.2.8, 6 OSDs, EC 4+2; the client fio is 3.28.

Volume parameters: BlockSize=256 KiB, TrashDays=0. The client does not enable local data cache, writeback or `async_dio`; normal background work and deletion are enabled. The mount remains read-write, so **fio's `--readonly` only restricts that fio process; it does not stop JuiceFS from issuing background compaction because of a read**.

The following are the actual mount parameters, with only the path and metadata address replaced by environment variables. `SUBDIR` is the new directory inside the volume, `MNT` is the client's private mount point, and `OUT` is a log directory outside the volume; the workload files live in `MNT/R01/`. Each mount uses its own process and log, all connecting to the same volume.

```sh
env CEPH_CONF="$CEPH_CONF" \
  CEPH_ADMIN_SOCKET=none CEPH_LOG_FILE=none \
  nice -n 10 "$JUICEFS" mount -d \
  --cache-size 0 --max-uploads 150 --max-downloads 200 --buffer-size 300 \
  --max-fuse-io 256K --backup-meta 0 --subdir "$SUBDIR" \
  --metrics 127.0.0.1:9573 --log="$OUT/client.log" \
  -o default_permissions "$META" "$MNT"
```

Readahead was not set explicitly; the effective configuration is 2 MiB. The mount allows read-write and normal background tasks are enabled.

`MNT` is under a client-local directory, but after mounting, file IO goes through FUSE rather than testing the underlying local filesystem in that directory. A private mount is used to count reads in an independent process and to protect existing mounts; the community does not need to use the same directory name.

## 2. 128-file random read/write

In a new test directory we created 128 files of 256 MiB, first writing CRC-format data sequentially. In the preparation phase we ran `juicefs compact --threads 1 FILE` per file, checked that all 4 chunks per file had one 64 MiB mapping, and completed a full 32 GiB CRC. Then we unmounted normally and switched to a new process, so the formal start had no counters from the previous process.

The formal workload parameters are below; the actual full command contains 128 independent job sections, see the [actual fio command](../raw-test-data/upstream-independent/formal/argv.json):

```text
filesize=256M, size=256M, offset=0
rw=randrw, rwmixread=50, bs=256K
ioengine=libaio, iodepth=128, direct=1, fallocate=none
allow_file_create=0, rate=64k,64k, rate_process=linear
time_based, runtime=1800
verify=crc32c, verify_interval=256K, do_verify=0
verify_fatal=1, verify_dump=0, verify_state_save=0, verify_state_load=0
refill_buffers=1, end_fsync=1, exitall_on_error=1
randrepeat=1, allrandrepeat=1, random_generator=tausworthe64
128 jobs: each numjobs=1, filename=lt.i.0, randseed=2026101900+i
output-format=json; bandwidth and latency logged every 1 second
```

The formal phase does no CRC, manual compaction or GC. At the formal start and end we captured this mount's FUSE, GET/PUT, compaction and error counters, and cross-checked them against the fio bytes. We froze the formal results first, then waited for in-flight work to finish, manually normalized the remaining history, ran the final CRC and unmounted normally; later steps are not mixed into the formal results.

## 3. Minimal reproduction with one 64 MiB file

The single overwrite and the two overwrites each use a new file, executed in the actual order below.

| Order | Operation and check |
|---|---|
| 1 | Mount the preparation process; write 64 MiB with 4 MiB sequential IO, fsync at the end; check that it starts as one 64 MiB slice mapping |
| 2 | Read the full 64 MiB as the initial CRC; wait for object requests to finish, unmount normally |
| 3 | Mount a new write process; the negative control writes 256 KiB at offset 16 MiB, the positive case writes 256 KiB at offsets 16 and 48 MiB; fsync after each write |
| 4 | Record the write-process counters and check through a metadata dump that there are actually 2 / 3 mappings; unmount normally |
| 5 | Mount a new read process, first record the zero point; read only 256 KiB at offset 0, then wait until the object byte counters are stable and upload/staging is 0 |
| 6 | Freeze the counters, confirm the mappings with a metadata dump; only then run the full 64 MiB CRC and unmount normally |

Both initializations directly formed a single 64 MiB mapping, with no manual compact invoked. If another environment initializes to multiple slices, it does not meet the initial condition here; do not ignore that difference and compare the results directly.

The common fio parameters are `numjobs=1, ioengine=psync, iodepth=1, direct=1, fallocate=none, filesize=64M, rate=64M`, using CRC32C, `verify_interval=256K`, fixed random seed 2026101920 and JSON output. Initialization actually uses `size=64M, bs=4M`; the overwrite and trigger read actually use `size=256K, bs=256K`. `filesize=64M` does not mean each overwrite writes 64 MiB.

| Minimal workload command raw record | Purpose |
|---|---|
| [positive layout](../raw-test-data/mini-positive/layout/argv.json) | Initialize 64 MiB |
| [positive write-1](../raw-test-data/mini-positive/write-1/argv.json) | Overwrite 256 KiB at offset 16 MiB |
| [positive write-2](../raw-test-data/mini-positive/write-2/argv.json) | Overwrite 256 KiB at offset 48 MiB |
| [positive trigger](../raw-test-data/mini-positive/trigger/argv.json) | First 256 KiB read in a new process |
| [negative write-1](../raw-test-data/mini-negative/write-1/argv.json) | Only the first overwrite |
| [negative trigger](../raw-test-data/mini-negative/trigger/argv.json) | The same 256 KiB read |

The overwrite steps use `--do_verify=0 --end_fsync=1`; the trigger and full CRC use `--readonly --verify_only=1`. During reads the JuiceFS mount is still read-write.

## 4. How the IO counters and slice mappings were obtained

The IO counters include application read/write bytes, object GET/PUT bytes, compaction count and compaction size, recorded by the JuiceFS background process for this mount point. The `--metrics 127.0.0.1:9573` in the full mount command of section 1 opens the statistics query interface, queried directly on that process with the following command, without deploying a separate Prometheus service:

```sh
curl --fail --silent --show-error http://127.0.0.1:9573/metrics
```

The test script queries this interface over HTTP and saves the full returned text, sample time, JuiceFS background process PID and test phase together as JSONL. The read/write bytes and compaction counts are cumulative values; the end value minus the start value is the IO that occurred in this phase. The attached `metrics-boundaries.jsonl` selects the needed sample points from these records and keeps the original lines.

The slice mappings are stored in TiKV and record which slices a chunk's data comes from, and the position and length of each segment. The following command connects to TiKV to export JuiceFS metadata; the test script extracts `chunks[].slices` from the output JSON to check the mapping changes in the minimal reproduction:

```sh
"$JUICEFS" dump --threads 1 --subdir "$SUBDIR/R01" --skip-trash "$META"
```

The dump operation only queries metadata; it does not read file content from Ceph, does not trigger the read-side compaction discussed here, and does not go through the IO statistics interface above. `prepared-mapping.json`, `written-mapping.json` and `measurement-end-mapping.json` are the mappings after initialization, after overwrite and after the trigger read respectively.

`metrics-boundaries.jsonl` is a subset of the raw sample records and the fio JSON is direct fio output; `results.json` and the mapping extracts are generated by the parsing program. The source manifest explains the origin and selection method of each file, so that computed results are not mistaken for raw command output.
