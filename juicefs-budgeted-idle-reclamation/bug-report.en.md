# Ordinary compaction requests dropped during busy admission are not retried

[中文](bug-report.md) · [Test report](test-report.en.md)

## Observation and scope

The original deployment used JuiceFS v1.4.1 (`0b90c7db5a929ae6adc5faad948d108efd2c99f9`), TiKV metadata and Ceph RADOS objects. After two hours of 256 KiB randrw overwrites across 128 one-GiB files, fio and full CRC verification passed. During 289 idle samples over about 24 h 5 min, pool stored decreased by only about 0.144 GiB and remained about 89.795 GiB above the pre-write baseline.

That deployment also carried an independent VFS B-catchup change; this native fix and its clean-stock offline comparison do not depend on it. Idle-observation settings were TrashDays=0, NoBGJob=false and MaxDeletes=10, with 256 KiB object blocks and 64 MiB JuiceFS chunks.

Raw analysis found 686,671 history records and 345,921 fully shadowed source slices. Targeted manual compaction reclaimed sample space. This supports retained-history reclamation as a real concern, but the long run lacks per-branch traces and does not attribute the entire capacity difference to one branch.

**This patch fixes the deterministically reproducible native gap: an already-issued ordinary request is dropped while busy and is not retried when existing work finishes.** It does not add volume-wide discovery or cross-process recovery.

## Root cause

In the pinned [pkg/meta/base.go](https://github.com/juicedata/juicefs/blob/0b90c7db5a929ae6adc5faad948d108efd2c99f9/pkg/meta/base.go):

- `Read` asynchronously requests ordinary compaction at its slice-count threshold.
- `Write` triggers at `numSlices%100 == 99 || numSlices > 350`, with a separate synchronous `once` safeguard at the hard limit.
- Ordinary admission returns when `len(compacting) > 10` or the same key is already active.
- Completion removes the active entry without retaining or waking rejected requests.

Consequently, releasing a slot does not retry the missed work. After IO stops, another trigger may never arrive during the observation window. Deletion concurrency cannot remove references still present in chunk history.

## Minimal change

Only `pkg/meta/base.go` changes (+42/-5):

1. Lazily retain one callback per existing compaction key in `compactTodo`; repeated busy requests coalesce.
2. A newly admitted ordinary attempt supersedes older pending requests for its key and reads current metadata.
3. Move the admitted batch body into internal `compactChunkAdmitted`; retain the existing object work, planner and origin/prefix/CAS replacement.
4. On success, no-work or error return, release the slot and reserve it for one eligible pending request under the same mutex before dispatch. The retry cannot lose its reserved slot to another arrival, and completion does not launch the whole backlog.
5. A synchronous `once` check may do no work, so it must not consume an ordinary pending request.
6. Release only once before forced recursion, preventing an outer defer from deleting a slot already handed to another attempt.
7. Clear pending callbacks at session cancellation and recheck cancellation before admitted work begins.

The original `>10` ordinary gate remains: at most 11 ordinary slots. Explicit `once/force` behavior is retained. There is no periodic worker or new trigger source, nor a new automatic retry loop for already-admitted object failures.

## Deterministic verification

Tests run real compactions held at object-callback channel barriers:

- **Global busy:** occupy 11 real slots, submit two other chunk requests, then release one slot. Stock does not resume them; the fix transfers slots while preserving ordinary concurrency. Both successful and failed releasing operations are covered.
- **Same chunk:** append 99 mappings after the first snapshot and issue 256 duplicate requests. Stock retains 100 records after its first merge; the fix performs one coalesced follow-up and finishes at one record.
- **Duplicate negative control:** without new writes, the follow-up observes no further useful batch and does not rewrite objects again.
- **Lifecycle/ownership:** cover cancellation, unchanged object-failure behavior, synchronous threshold checks and forced-recursion handoff.
- **Real objects:** SQLite and in-memory ObjectStorage call actual `vfs.Compact`; post-snapshot partial overwrites survive, full contents/CRC match, and source objects are checked from existence through deletion.

Test-only helpers invoke the existing ordinary entry directly, ensuring requests occur during the busy window. Raw observations do not trigger user Read compaction. Active slots are not fabricated in the map.

The same test files compile on stock: 13 target leaf cases fail at `COMPACT_RETRY_MISSING`, while nine controls pass. The fix passes all 22 leaf cases three times with race detection. See the test report for commands and evidence.

## Contract boundaries

- Finite current-client backlog gets an ordinary-batch retry opportunity when active operations can finish and the client continues running.
- Same-key requests coalesce. Existing batch limits and `skipSome` remain; one slice per chunk is not a universal guarantee.
- Pending state is volatile and discarded on session exit. It does not discover pre-restart backlog or histories that never triggered ordinary compaction.
- Pending memory grows with distinct queued keys; deduplication is not a hard queue-capacity bound. Sustained overload can still accumulate work.
- In-flight object cancellation retains its existing boundary. Completing formerly dropped work adds actual work; preserving concurrency is not proof of foreground performance acceptance.

This native retry does not depend on the earlier V2 scanner or its TiKV prefetch correction. Both patches remain unchanged; the following update records field validation, not production acceptance.

## Field update (2026-10-04)

- **Independent stock reproduction:** C8-U0 had no B-catchup or reclamation patch. About 11.28 hours after overwriting a 16 GiB dataset, full referenced slice capacity remained 26.4565 GiB, including 2.4902 GiB of fully shadowed slices, with uploads drained. The symptom therefore does not require B-catchup. The run was interrupted without final CRC; it is not a complete equal-work A/B or attribution of every residual byte to busy admission.
- **Stock plus this candidate:** C9-U1 completed 16 GiB layout and initial CRC, but its overwrite phase completed only 57.78/64 GiB total IO before the old PG-delay guard stopped it. About 64 minutes after writes stopped, references reached 16 GiB with zero fully shadowed capacity before final CRC; supplemental full CRC then passed. This does not retroactively make the incomplete round a pass.
- **Deployment combination:** C11/C12 used B-catchup plus this candidate and completed two-hour randrw/randwrite runs on 128 GiB, writing about 159 GiB and 232.532 GiB respectively. With no idle user-file reads or manual reclamation, minimal 128 GiB references were first observed about 2 h 34 min and 3 h 05 min after writes stopped, confirmed again before full CRC. Both CRCs passed and private mounts were normally unmounted.
- **Unclosed scenario:** C13 sequential writes used 16 jobs of 4 GiB each and bs=16M. After about 1 h 45 min and 259.703 GiB of formal writes, the capacity safety floor stopped the run. Space was being reclaimed at 13:30, but complete reclamation and final CRC remained unverified. This was not a latency stop and does not by itself identify a candidate defect.

**The reproducible busy-admission gap is compensated, and two two-hour field scenarios support automatic reclamation and content correctness. Sustained capacity bounds, all write shapes and foreground performance non-regression are not accepted.** Observed recovery times are not production SLAs. Versions, workload and evidence are listed in [field validation](test-report.en.md#field-validation).
