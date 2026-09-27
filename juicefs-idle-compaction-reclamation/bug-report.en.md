# Cold overwritten chunks may retain historical slice references

## Observation and environment

Official JuiceFS v1.4.1, commit `0b90c7db5a929ae6adc5faad948d108efd2c99f9`, plus a separate existing VFS B-catchup fix; TiKV metadata, Ceph RADOS objects, EC 4+2, six OSDs. Volume block size 256 KiB, TrashDays=0; active client NoBGJob=false, MaxDeletes=10, read cache disabled. No Ceph/TiKV configuration changes are part of this candidate.

A fixed 128×1 GiB dataset underwent two hours of 256 KiB mixed random overwrite IO. fio completed without errors and a full CRC read passed. After 24 idle hours, pool stored bytes remained approximately 89.795 GiB above baseline and the client's compaction count had not increased. Raw slice analysis found retained history. This long run has no per-trigger trace: its entire excess cannot be attributed to one branch.

A separate September 26 single-file canary reduced 5,973 records to 16, passed a full 1 GiB CRC read and reclaimed approximately 1.261 GiB of pool stored data. The September 27 C1 experiment then maintained eight different files, reclaiming 8.89 GiB; its tables cover only those eight, not the earlier sample. This shows the backend can delete objects safely released from these samples; it does not establish that every file or BlueStore DB space was reclaimed.

## Mechanism and evidence boundary

Pinned [base.go](https://github.com/juicedata/juicefs/blob/0b90c7db5a929ae6adc5faad948d108efd2c99f9/pkg/meta/base.go):

1. Writes trigger ordinary compaction according to slice **record counts**, including periodic 99-record points or counts above 350; maxSlices also provides synchronous protection.
2. Ordinary compaction returns when `len(compacting)>10` or the same chunk is already busy, without a persistent retry queue. One ordinary batch handles at most 1000 records.
3. Reads can also trigger compaction. Cold observation therefore uses metadata dumps, not file reads or `info --raw`.
4. Deleted-file/slice/trash cleanup cannot remove objects still referenced by raw chunk metadata. Compaction must first safely replace those references.
5. The original session background tasks do not periodically revisit these cold chunks. With no further IO and no durable pending work, missed attempts can persist. Below-threshold partial overwrite history can also persist; not all amplification is a concurrency skip.

A separate instrumented experiment used a new 1 GiB file, 16 jobs/QD4 and a fixed 8 GiB overwrite budget: 26,649 triggers, 26,616 skips (26,579 concurrency-limit and 37 same-chunk), and 33 starts/completions with status zero. About three idle minutes later, 9,837 raw records remained. **That instrumentation mount used no-bgjob**; IO-driven compaction still operated. Its skip ratio is not the original two-hour run's ratio or a production frequency. The tracing did not alter compaction decisions.

## Candidate

Add default-off client option `--compact-interval`. One designated maintenance client walks its mounted subtree, optionally restricted by `--subdir`, and makes one serial ordinary attempt per chunk per pass. Existing admission and origin/CAS checks remain. Busy, failed or partially processed histories are rediscovered from durable metadata on later passes, including after restart. No format change, increased admission limit or per-write unbounded waiting goroutine is introduced.

This is a **new patched option**, not a released tuning knob. Increasing deletion concurrency, disabling already-disabled trash, or changing Ceph settings cannot make still-referenced objects unreferenced.

## Open design questions

- This is not production acceptance. A periodic traversal is not idle-only and consumes metadata/object IO; large directories, hard links and sparse files need overhead evaluation.
- The same-root counter is best-effort throttling, not a distributed lease. Long passes and overlapping subtrees can overlap. Initially restrict to one maintenance client.
- Cancellation stops subsequent chunks, not an in-flight `vfs.Compact`. Existing memory waits lack cancellation and may delay unmount.
- Successful traversal does not prove all object operations succeeded. Inspect errors, raw references and object-store capacity. No capacity bound under sustained overload is claimed.
- Should pending work be durable rather than discovered by scans? Should triggers use retained bytes/amplification? How should IO budgets, observability, multi-client coordination and cancellation be designed?

See the test report for measured results and explicit untested scopes. This report does not claim a unique root cause, an upstream-approved remedy or a production-ready candidate.
