# Overwrite history retained after writes stop: simple reproduction and RFC

## 1. Environment and observation

The stack is **JuiceFS filesystem + TiKV metadata engine + Ceph object storage**:

```text
fio → /mnt/juicefs → Linux VFS/FUSE → JuiceFS client
                                      ├─ TiKV: attributes and chunk/slice mappings
                                      └─ Ceph RADOS: block objects with file content
```

The client is `node2`; TiKV and Ceph run on `node1`, `node3` and `node4`, with six Ceph OSDs. The JuiceFS volume `juicefs-prod` is mounted at `/mnt/juicefs`, with file content stored in Ceph pool `juicefs-data` using EC 4+2 erasure coding.

The baseline is JuiceFS v1.4.1, commit `0b90c7db5a929ae6adc5faad948d108efd2c99f9`. Settings: BlockSize=256 KiB, TrashDays=0, read cache/writeback/`async_dio` disabled, ordinary background jobs enabled, MaxUpload=150, MaxDeletes=10, backup-meta=0.

**Upstream and RFC arms ran serially on the same backend.** Each created a separate 16 × 256 MiB file set, initialized it, fully overwrote it four times, and stopped file IO for 60 minutes:

| Metric | Upstream v1.4.1 | Attached RFC approach |
|---|---:|---:|
| Final logical file size | 4 GiB | 4 GiB |
| Total user writes | 20 GiB | 20 GiB |
| Extra pool space used after 60 idle minutes | **20 GiB** | **4 GiB** |
| Extra pool space, including EC 4+2 redundancy | 30 GiB | 6 GiB |
| Current live data / stored data | **20%** | **100%** |
| Current live data / space including redundancy | **13.3%** | **66.7%** |
| fio errors | 0 | 0 |

After 60 minutes without file IO, upstream JuiceFS still used 20 GiB more pool space than before the test. The patched run ended with only 4 GiB of extra space used, matching the current file set's size.

Only 4 GiB of upstream's 20 GiB stored by this run was current file content; the other 16 GiB had been overwritten but still occupied space. Including EC 4+2 redundancy, Ceph reported 30 GiB of extra space used. After reclamation, the patched run used 6 GiB of extra space: 4 GiB of live content plus 2 GiB of normal redundancy, not unreclaimed history.

Usage including redundancy comes from `stats.bytes_used` in the raw JSON records; it is not a measurement of total device usage including DB/WAL and other overhead. These ratios use each run's before/after differences, not whole-pool utilization.

## 2. Simple reproduction

Prerequisites: the tested version is mounted normally, no other pool writers or maintenance are active, and fio and `ceph df detail` are available. Save output outside the tested volume. Each measured arm took about 67 minutes, including 60 idle minutes.

**The following is a flow example for explanation, not the original script executed for these measurements.** The actual workload script and JSON collection commands are provided below; use them when checking the supplied evidence or reproducing the test.

```bash
set -euo pipefail
MNT=/mnt/juicefs
TEST_DIR=$(mktemp -d "$MNT/overwrite-repro-XXXXXX")
sample() {
    date '+%F %T %z'
    df -h "$TEST_DIR"
    ceph df detail
}
sample
for wave in 0 1 2 3 4; do
    BS=16M
    CREATE=0
    if (( wave == 0 )); then BS=4M; CREATE=1; fi
    fio --directory="$TEST_DIR" --name=lt --filename_format='lt.$jobnum.0' \
        --filesize=256M --size=256M --numjobs=16 --ioengine=psync --iodepth=1 \
        --direct=1 --fallocate=none --rw=write --allow_file_create="$CREATE" \
        --bs="$BS" --refill_buffers=1 --end_fsync=1
    sample
done
for point in {1..12}; do
    sleep 300
    sample
done
```

After the 4 GiB initialization, the remaining passes overwrite existing files without creating new ones. During observation, do not read file content, run CRC, invoke manual compact/GC or delete files. Preserve the directory afterward.

To test the patch, unmount the upstream client, mount the same volume using the patched binary, and repeat with identical parameters in a new directory. Preserve the upstream test files: **for each run, compare the space used in the Ceph pool before and after the test to calculate how much extra space it used**, rather than directly comparing the pool totals at the end of the two runs.

Record pool space usage with `ceph df detail` and compare how much extra space the `juicefs-data` pool used before and after each test. The records and five-minute observations are in the [test report](test-report.en.md).

### Actual script and JSON collection

The measurements used two scripts, not the workload script alone:

- [lt002-plain-mount-ab.sh.txt](reproduce/lt002-plain-mount-ab.sh.txt): the complete outer execution script; calls the workload and collects `before.json` / `after.json` around each run.
- [juicefs-overwrite-manual-check.sh](reproduce/juicefs-overwrite-manual-check.sh): the inner workload; produces fio logs and `space.log`, not JSON.

The outer script switches mounts and is attached as `.sh.txt` **for inspection only; do not execute it unchanged in another environment**.

The inner script creates a separate file set, runs the five write passes and produces `fio-0.log` through `fio-4.log` plus `space.log`. It observes one actual elapsed hour after writes stop, without file-content reads, CRC, manual compact/GC or deletion.

```bash
bash reproduce/juicefs-overwrite-manual-check.sh --mount /mnt/juicefs --hours 1 --interval 300
```

Adapt the script's result directory and Ceph query command to your environment without changing fio parameters or observation duration. Use a writable result directory outside the tested volume.

The outer execution script collects `before.json` and `after.json` before and after each test using the commands below. `ROOT` points to the result directory; `CEPH` is that script's Ceph query command array:

```bash
# Run with upstream JuiceFS already mounted
"${CEPH[@]}" df detail -f json > "$ROOT/A/before.json"
bash "$ROOT/juicefs-overwrite-manual-check.sh" --mount /mnt/juicefs --hours 1 --interval 300 | tee "$ROOT/A/execution.log"
"${CEPH[@]}" df detail -f json > "$ROOT/A/after.json"

# Run after a normal unmount and switch to the patched client
"${CEPH[@]}" df detail -f json > "$ROOT/B/before.json"
bash "$ROOT/juicefs-overwrite-manual-check.sh" --mount /mnt/juicefs --hours 1 --interval 300 | tee "$ROOT/B/execution.log"
"${CEPH[@]}" df detail -f json > "$ROOT/B/after.json"
```

Keep the intended client version mounted throughout writes and idle observation.

## 3. Analysis: logical overwrite is not reference removal

JuiceFS divides files into logical 64 MiB chunks. Each slice has an independent ID and is split into Ceph objects according to BlockSize. Metadata stores `pos/id/size/off/len` records encoded in 24 bytes; one slice containing multiple block objects does not imply multiple mapping records.

The ordinary write path is:

```text
VFS prepares slice data → data output completes → Meta.Write/engine.doWrite appends mapping
                                                     ↓
                                      check current per-chunk record count
```

Latest-wins layout computation changes visible file content, but does not itself remove persistent historical mappings and objects. For example, after writing A and then B to the same range, reading can select B while history still contains [A,B]. Ceph cannot directly delete old sources still referenced by those mappings. TrashDays=0 is not a substitute for releasing them.

The native Write trigger in `pkg/meta/base.go` is:

```go
if numSlices%100 == 99 || numSlices > 350 {
    if numSlices < maxSlices {
        go m.compactChunk(inode, indx, false, false, int(attr.Tier))
    } else {
        m.compactChunk(inode, indx, true, false, int(attr.Tier))
    }
}
```

This depends on record count, not retained bytes or elapsed time. A few large overwrite slices can retain substantial history before the first 99-record trigger; after writes stop, no new Write rechecks that condition. Qualified reads or explicit maintenance can provide other opportunities, but neither occurred during this experiment's observation.

We ask maintainers whether **retaining low-record-count overwrite history after file IO stops is an intentional space/compaction trade-off, or whether another background mechanism should handle it**.

## 4. RFC proposal

Keep the native Write predicate and add registration on successful writes, post-write inspection and follow-up until clean:

1. **Register.** Track `(inode, chunk index)` after a successful ordinary Write if it has multiple records. Further Writes update an existing entry's generation and ready time. Entries are client-local and capped at 65536.
2. **Inspect.** Each writable client with background jobs enabled starts one background inspection goroutine to check the pending entries. Each chunk becomes eligible one minute after its most recent successful local Write. The goroutine checks once per second and selects at most one eligible chunk at a time. It does not start the next item until the current operation returns, and does not create a goroutine for each chunk.
3. **Compact.** For up to 1000 records, compare summed raw reference lengths with the latest-wins live length. A clean layout needs no rewrite; covered history uses native single-batch compaction. Larger histories use native bounded planning.
4. **Follow up.** Keep the entry after a batch and reread later; failures cool down before retry. A changed generation prevents an older inspection from deleting or rescheduling newer work. Native prefix validation retains concurrently appended tails.
5. **Delete.** Release old references through compaction and use native deletion for eligible objects, retaining shared-reference and TrashDays rules. Do not bypass metadata by directly removing backend objects.

### Costs and limitations

- **One idle minute does not guarantee immediate reclamation.** Each chunk has its own timer. However, if the background inspection goroutine finds any unfinished compaction in this client, it keeps the pending entry and defers the attempt until a later timer check. Those compactions may involve other chunks; continuous activity can therefore postpone reclamation of an already idle chunk indefinitely. One minute is a waiting period before inspection, not a reclamation completion time.
- **Compaction performs actual data IO.** Read required live data, upload new block objects under a new slice ID, then delete old objects after reference release. This is not just metadata tidying or reuse of existing object keys. More processing opportunities can increase backend contention.
- **A shared client lock is used.** Registration, selection and compaction-marker settlement use the existing `baseMeta` mutex. Selection scans O(pending) entries. This is not a TiKV cluster-global lock, but large pending sets can increase client contention.
- **Bounded tracking can omit work.** New keys may be omitted at capacity, with rate-limited warnings; existing entries can still update. Entries are not persistent and do not guarantee restart recovery, other-client history or Copy/Truncate/hole-operation coverage.
- **Cancellation is cooperative.** Closing the client session requests the background inspection goroutine to exit and waits for already-started operations to return. Backend operations retain their existing cancellation mechanism, without a new forced-interruption deadline. Read-only and `NoBGJob=true` clients neither register pending entries nor start this goroutine.

## 5. Patches and evidence

The implementation modifies `pkg/meta/base.go` and adds `pkg/meta/idle_write.go`; tests are separate. It adds no CLI or persistent metadata format and no `--idle-compact-delay` option.

Apply to the clean fixed upstream baseline:

```sh
REPORT=/absolute/path/to/juicefs-idle-written-chunk-reclamation
git apply "$REPORT/patches/0001-meta-compact-written-chunks-after-idle.patch"
git apply "$REPORT/patches/0002-meta-test-written-chunk-idle-compaction.patch"
```

Results are in the [test report](test-report.en.md). The [raw-data index](raw-test-data/README.md) links directly to both runs' fio logs and space records; no archive download or extraction is needed.
