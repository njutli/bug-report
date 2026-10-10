# Confirmed cause: low-record overwrite history has no post-write trigger

## 1. Observation and cause

Two isolated TiKV/Ceph experiments used upstream JuiceFS v1.4.1, commit `0b90c7db5a929ae6adc5faad948d108efd2c99f9`, plus observation-only instrumentation. Each used 16 × 256 MiB files, initialization and four full overwrites: 4 GiB logical data and 20 GiB total user writes. R01/R02 recorded 1376/1388 successful metadata Writes; all 64 chunks remained at 9–30/10–27 records. Exact event replay matches the raw mappings, record counts are continuous, trigger predicates are false, and the complete trace contains no target compaction request or busy rejection.

Six idle snapshots per round remained identical for at least 60 minutes: 20 GiB of distinct source slices remained referenced, including 16 GiB entirely shadowed by later writes. These are deduplicated full-slice reference sizes, not Ceph physical disk usage. After freezing this evidence, manual compaction succeeded on 64 chunks, references became 4 GiB, source deletion callbacks succeeded and full CRC passed.

The file-content path is FUSE Write → VFS slice writer → data Finish → commitThread → Meta.Write → engine.doWrite. File data is stored as block objects; metadata stores ordered slice mappings. A slice mapping has `pos/id/size/off/len`, and one slice may comprise several block objects. New mappings append to history; read-time latest-wins layout computation does not itself remove persistent old references. Application writes, metadata records and block objects are not one-to-one.

Upstream Write triggers on `numSlices%100 == 99 || numSlices > 350`, using the current per-chunk record count. Below 2500 it requests ordinary asynchronous compaction; at or above 2500 it uses synchronous once. The predicate is deterministic, not a 1% probability. Five full versions can reference five times the live data while still leaving far fewer than 99 records. Waiting does not increase the count. Reads or explicit maintenance may later trigger compaction, but were absent before the evidence was frozen.

This establishes a missing post-write opportunity in these two low-record-count rounds, not a busy-admission or synchronous-once failure. Instrumentation adds overhead; successful deletion callbacks are not independent physical-sector measurements. Older field history cannot all be attributed to this mechanism without its missing trace. See the [cause evidence](raw-test-data/README.md).

## 2. Proposed change

The implementation patch modifies `pkg/meta/base.go` and adds `pkg/meta/idle_write.go` (+191/-19); tests are separate. Apply implementation patch 0001, then test patch 0002 to the clean fixed baseline. No new CLI, metadata format, engine reader interface, busy-request queue or Copy/Truncate/hole tracking is added. There is **no `--idle-compact-delay` option**. The native Write predicate is unchanged.

### Registration and scheduling

After successful `doWrite`, remember `(inode, chunk index)` when it has multiple records. Further successful Writes update an existing entry's generation and ready time, even if its record count has decreased. Writable sessions with background jobs enabled activate registration.

One minute without a successful **local-client Write to that chunk** makes it eligible; reads and writes to other chunks do not reset it. One serial session worker processes at most one eligible entry per tick, and defers admission while any client-local compactor is active. This is not global client or cluster idleness.

The worker reserves the existing compaction slot and calls native `doRead` for the raw history, without invoking public Read. With at most 1000 records it compares non-hole raw mapping lengths with latest-wins live lengths: no covered data means the entry can be removed. This is an overlap check, not full-slice capacity accounting or permission to delete objects. Otherwise it reuses the native batch planner with the same snapshot. A successful batch remains pending until a later clean inspection; errors and unconfirmed work cool down for one minute from actual completion. ENOENT or a non-nil empty list may be clean; nil or failed reads may not.

### New writes and object safety

Keep the entry while inspecting it. Check generation after probing and again at settlement so an old check cannot discard new work. A Write during object processing is preserved by the native origin-prefix/CAS commit and a later check. Do not force-delete source objects: shared references, TrashDays and MaxDeletes continue to apply.

`compactChunkOnce` extracts the native batch body; ordinary callers still read normally and the idle caller reuses its probe. Native skipSome, the 1000-record batch limit, object rewrite, prefix replacement and deletion semantics remain. Ordinary force recursion starts only after the current slot is released; the idle caller releases its own slot once.

### Costs and limitations

- The process-local map is capped at 65536 chunks. Selecting the oldest eligible entry scans it under the existing metadata mutex, O(pending). Overflow logs rate-limited warnings and may omit new keys.
- Backend reads remain full-value/list reads. The batch limit is not an RPC byte, memory or whole-step CPU budget. Histories over 1000 records use native limited batches; convergence is not proven for every layout.
- One worker and busy deferral do not cap bandwidth or guarantee zero foreground competition once a batch starts. Persistent backend errors retry once per minute.
- The worker joins the existing session wait group. CloseSession may wait for in-flight backend/object operations with native cancellation semantics; no hard close deadline or general ordinary-compactor lifecycle redesign is added.
- Restart recovery, other clients' history, non-Write mutations and omitted overflow entries are outside scope. This is not a full-volume history scanner or a promise that all retained history will eventually be reclaimed.

## 3. Validation status

Local focused race tests passed 108 executions across three engines. A real-object automatic test with the production one-minute timer failed on upstream after 75 seconds with no trigger, and passed with the candidate. Broader client race tests failed on both upstream and candidate; no full-suite race success is claimed.

On 2026-10-10 the same candidate completed two independent TiKV/Ceph short checks: without user reads or manual compaction, references converged to 4 GiB with no fully shadowed history, followed by full CRC. A foreground-overlap check also observed a new Write to the active chunk, generation retention and subsequent reclamation. The [test report](test-report.en.md) records data, workload deviations and remaining checks. Long-term operation, production latency/throughput regression, near-capacity scanning cost and slow-backend shutdown remain unaccepted; the two-hour sequential overwrite's final reclamation/CRC acceptance is still pending.
