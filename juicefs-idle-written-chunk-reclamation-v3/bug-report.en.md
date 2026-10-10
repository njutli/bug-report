# Missing idle compaction trigger for low-count overwrite history

7 October 2026. [中文](bug-report.md)

## Observation and distinction from V2

Native retry V2 compensates ordinary requests rejected by busy admission. C13 exposed a different gap: history exists but no request is generated, or a few writes after a compaction snapshot leave an untriggered tail. The gap is reproducible in upstream and V2, not demonstrated to be introduced by V2.

C13 used sixteen 4-GiB files, 16-MiB sequential overwrites, psync/QD1, without local cache, writeback or async_dio. It stopped on the capacity safety floor after about 1h45m and 259.70 GiB of writes. An idle metadata snapshot showed 64 GiB of fully covered logical data but 211.39 GiB of full slice references, including 147.36 GiB entirely shadowed in the subtree. Of 1,024 chunks, 502 had one record and 522 had 6–34. Uploads had drained. Obsolete slices were still referenced by JuiceFS metadata; this was not simply Ceph delaying an already valid deletion. Subtree-local shadowing alone does not authorize object deletion because references can be shared.

## Mechanism in v1.4.1

Pinned base: `0b90c7db5a929ae6adc5faad948d108efd2c99f9`. Write triggers ordinary compaction at `numSlices % 100 == 99 || numSlices > 350`, using mapping count rather than obsolete bytes. Large overwrites can leave substantial history below the trigger. Small writes after a compaction snapshot can also leave a low-count tail. Metadata Read may trigger compaction independently, so a CRC read must not precede the idle-reclamation verdict. Slice cleanup handles eligible reference counts; TiKV MVCC GC and Ceph cannot remove still-referenced overwrite history instead of file-level compaction.

Controlled tests stop after overlapping writes, or append writes after a blocked ordinary snapshot. On V2, nine automatic-trigger cases across memkv/SQLite/Redis fail with `IDLE_TRIGGER_MISSING`. On V3, the same nine cases pass three race repetitions. Separate upstream/V2 diagnostic controls each pass 24 observations of the expected gap. These controls are not a claim that original reclamation succeeds.

## V3 approach and limits

Successful writes track deduplicated (inode,index) entries with generations and a 65,536-entry limit. After this client's metadata Read/Write is quiet, one worker reserves the chunk admission slot before inspecting raw history. It yields to existing compactors or resumed IO, recognizes byte overlap using latest-wins reconstruction, and invokes the existing ordinary batch and CAS/reference/deletion path. A post-batch check retains remaining history, generation changes or errors with cooldown/backoff. Non-overlapping live records are not needlessly rewritten.

`--idle-compact-delay` defaults to zero; read-only/no-bgjob mounts disable it. Tracking is process-local, not restart discovery or a volume scan. Overflow means incomplete coverage; the inherited V2 retry map is separately uncapped. The idle gate is not global cluster/object IO idleness. An already started batch is not preempted by resumed foreground IO, and each client has its own worker. Single concurrency is not a bandwidth limiter or a performance non-regression proof. Persistent backend errors, shared references and trash retention still matter. Continuous overload can still grow storage usage.

Short cluster tests support the tested functionality, not universal reclamation, 24/72-hour write acceptance or zero introduced risk. See [test-report.en.md](test-report.en.md).
