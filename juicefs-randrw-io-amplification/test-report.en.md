# Random read/write object IO amplification test record

The test used JuiceFS v1.4.1 (`0b90c7db5a929ae6adc5faad948d108efd2c99f9`), TiKV and Ceph RADOS, with fio version 3.28. The volume BlockSize and maximum FUSE IO were both 256 KiB, and local data cache and writeback were disabled. Full mount parameters, fio parameters and collection methods are in the [test method](reproduce/README.en.md).

Object read/write amplification is the GET/PUT bytes divided by the application read/write bytes for the same client and the same time window. The application bytes were cross-checked between the FUSE IO counters recorded by JuiceFS and the fio output; the object bytes include JuiceFS compaction IO and do not yet include Ceph-internal EC or disk overhead. Initialization, manual compaction and CRC verification are outside the formal counting window.

## 1. Random read/write: about 23.7x object IO amplification

We created 128 files of 256 MiB, 32 GiB in total. After sequential initialization we compacted each file single-threaded to confirm that every 64 MiB chunk had only one full slice mapping; we completed the initial CRC, unmounted normally and mounted again, then started the 30-minute test.

fio used `randrw`, 50% read / 50% write, `bs=256K`, `direct=1`, `libaio`, `iodepth=128`, with 128 jobs each accessing one file. Each job was set to `rate=64k,64k`, so application read and write were each about 8 MiB/s. No manual compaction or CRC was performed during the formal period.

| Metric | 30-minute test result |
|---|---:|
| Application read / write | 14.0625 GiB each |
| Object GET / PUT | 333.00317 / 332.8125 GiB |
| Object read / write amplification | **23.68023x / 23.66667x** |
| Compaction count / cumulative size | 5100 times / 318.75 GiB |
| Average compaction size | 64 MiB |
| fio / object request errors | 0 |
| Final full CRC | 32 GiB passed |

Object PUT satisfies `14.0625 GiB application writes + 318.75 GiB compaction size = 332.8125 GiB`, so about 95.77% of object writes can be explained by compaction size. GET exceeds "application reads + compaction size" by 195.25 MiB, about 0.0573% of GET; this part is not yet broken down by source.

After the formal period, a manual compaction performed to tidy up file history produced another 29.75 GiB of GET and PUT each, not included in the table above; the final CRC was also counted separately. [Raw records for this experiment](raw-test-data/upstream-independent/).

## 2. Single-file minimal reproduction: a read after two small overwrites triggers a 64 MiB compaction

We created two 64 MiB files, each initialized with `bs=4M`, `psync/QD1`, `direct=1`, and confirmed that each had only one full 64 MiB slice mapping. After the initial CRC, we ran the following comparison, with fsync at the end of each overwrite:

- Single overwrite: write 256 KiB at offset 16 MiB.
- Two overwrites: write 256 KiB at offset 16 MiB and at offset 48 MiB, 512 KiB in total.

After the overwrites we recorded the mappings, then unmounted normally and mounted with a new process so that the first read would not hit the old process's mapping cache. In both cases we read only 256 KiB at offset 0, waited for that read and the background object requests to finish, recorded the results, and only then ran the full CRC.

| Metric | Single overwrite | Two overwrites |
|---|---:|---:|
| Application overwrite | 256 KiB | 512 KiB |
| Object GET / PUT in the overwrite phase | 0 / 256 KiB | 0 / 512 KiB |
| Raw mappings / live fragments after overwrite | 2 / 3 | 3 / 5 |
| Subsequent application read | 256 KiB | 256 KiB |
| GET produced by that read and background work | 256 KiB | **64.5 MiB** |
| PUT produced by that read and background work | 0 | **64 MiB** |
| Compaction count / size | 0 / 0 | **1 / 64 MiB** |
| Raw mappings after the read and background work | 2 | 1 |
| fio / object request errors | 0 | 0 |
| Final full CRC | 64 MiB passed | 64 MiB passed |

The initial data is called A. After overwrite B, two mappings A and B are stored, and the live content is "head of A, B, tail of A", 3 fragments. After overwrite C, three mappings A, B and C are stored, and the live content is "head of A, B, middle of A, C, tail of A", 5 fragments, reaching the condition for the read side to request compaction.

The GET for two overwrites was 64.5 MiB, of which 64 MiB corresponds to the compaction range, 256 KiB is the application read, and another 256 KiB is not yet broken down. After compaction the mapping becomes one new slice, showing that a read after a small overwrite can trigger re-upload of the whole 64 MiB range. [Raw records, single overwrite](raw-test-data/mini-negative/) / [raw records, two overwrites](raw-test-data/mini-positive/).

All the above data can be checked with the [raw records](raw-test-data/README.en.md) and the [recompute program](tools/recompute.py); [results.json](results.json) is the summary computed from them.
