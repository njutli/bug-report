# VFS may miss dispatching a full block when the slice ID is prepared asynchronously

## Summary

When a write creates a new slice, `prepareID` runs as a goroutine. If the
first write fills a complete block (write size == block size) before the
slice ID is ready, `sliceWriter.write` skips `FlushTo` because `s.id == 0`.
When the ID later becomes ready, the ID-ready path calls `SetID` but does
not revisit the missed dispatch. This causes data to linger in memory,
eventually triggering the client buffer throttle and collapsing randwrite
throughput.

## Affected versions

- **v1.3.x** (`e0032b2a`): severe — randwrite throughput collapses ~3.4x
  (560.9 vs 1917.0 MiB/s with 256 KiB block size, Latin-square 3-mount
  interleaved measurement).
- **main** (`53835e24`): the same race code exists (99.2% skip rate
  confirmed by instrumentation), but main's commitThread refactoring
  (#6311 "improve lock management in commitThread") allows faster fallback
  drainage — retained data is absorbed before the buffer threshold is
  reached, so no visible collapse in fresh environments. The code path is
  still incorrect; it is merely masked.

## Root cause

### Write path timeline

```
writer.go:257  writeChunk()     — holds f.Lock()
writer.go:268    go s.prepareID()  — goroutine, needs f.Lock() → blocked
writer.go:277    s.write()         — checks s.id > 0 → s.id == 0 → FlushTo skipped
                  f.Unlock()         — writeChunk returns
                  prepareID gets lock → NewSlice → SetID → no catch-up FlushTo
```

`prepareID` needs the same `fileWriter` mutex that `writeChunk` holds.
Because Go mutexes are not reentrant, `prepareID` cannot run synchronously
inside `writeChunk` — it is launched as a goroutine and blocked on the lock
until `writeChunk` returns. By then, `write` has already checked `s.id`
(found it 0) and skipped `FlushTo`. When `prepareID` later sets the ID,
the missed dispatch is never revisited.

### Why only full-block random writes trigger the visible collapse

- **Block size == write size** (e.g. 256 KiB block + 256K fio bs): the
  first write fills the block, `FlushTo` is skipped, and random writes
  never revisit the same slice → no second chance to dispatch.
- **Write size < block size** (e.g. 128K bs): the kernel splits a 256K
  application write into two consecutive 128K writes; the second write
  continues the same slice, and by then the ID is ready → `FlushTo` hits.
- **Sequential/mixed workloads**: subsequent writes or read interleaving
  give fallback drainage (5s timer, 10s forced flush) time to catch up.

### Why main doesn't collapse but v1.3 does

Both versions have the same race (99.2% skip rate on both). The difference
is in the fallback drainage speed:

- **v1.3.1**: `commitThread` uses `defer f.Unlock()` — holds the lock for
  its entire lifetime, only releasing during `WaitWithTimeout(100ms)`.
  `prepareID` (called by `flushData` fallback) struggles to acquire the
  lock → drainage is slow → buffer grows past 300 MB threshold →
  throttle activates (10ms/100ms sleep per write) → self-lock at ~560 MiB/s.
- **main** (#6311): `defer f.Unlock()` removed, lock held in shorter windows;
  #7016 added commit dependency tracking (`dep`/`committed`/`commitcond`)
  for ordered slice commits → `prepareID` gets the lock faster → drainage
  keeps up with write rate → buffer stays low → no throttle → ~1900+ MiB/s.

The fix does not change drainage speed — it eliminates the source of
retention by adding a catch-up `FlushTo` after `SetID`. On v1.3.1 this
prevents the buffer from ever filling up; on main the buffer was already
drained by fallback, so the patch has no visible performance effect.

## Fix

After `SetID` in `prepareID`, check whether the slice already contains a
complete block and dispatch it if so:

```go
if s.writer != nil && s.writer.ID() == 0 {
    s.writer.SetID(s.id)
    // added:
    if s.id > 0 && !s.freezed && int(s.slen) >= f.w.blockSize {
        if err := s.writer.FlushTo(int(s.slen)); err != nil {
            logger.Warnf("flush inode: %v chunk: %d after preparing slice ID: %s",
                s.chunk.file.inode, s.id, err)
            s.err = syscall.EIO
        }
    }
}
```

The fix preserves the async `prepareID` design (unlike making `NewSlice`
synchronous, which would hold `f.Lock()` during metadata roundtrips and
block concurrent writes to the same file). It only adds a conditional
catch-up after the ID is set — 7 lines in `pkg/vfs/writer.go`.

## Historical context

The async `prepareID` was originally correct: in 2021, `NewSlice` did a
real metadata roundtrip (Redis/TiKV) on every call, so making it async
avoided blocking the write path. In 2022, #2397 refactored `NewSlice` to
use a local counter with batch pre-allocation (4096 IDs per roundtrip),
making the cost microseconds for most calls. The async wrapper was never
revisited, leaving the race in place.
