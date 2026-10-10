package meta

import (
	"fmt"
	"testing"
	"time"
)

// Diagnostics only: exercise public Write/Read, never force the compactor.
// Run unchanged on stock and native-retry through a base.go-only overlay.
func c13PublicOverwrite(t *testing.T, f *compactRetryFixture, inode Ino, n int) {
	t.Helper()
	for i := 0; i < n; i++ {
		var id uint64
		if st := f.m.NewSlice(Background(), &id); st != 0 {
			t.Fatal(st)
		}
		f.mu.Lock()
		f.owners[id] = inode
		f.mu.Unlock()
		if st := f.m.Write(Background(), inode, 0, 0,
			Slice{Id: id, Size: 64 << 10, Len: 64 << 10}, time.Now()); st != 0 {
			t.Fatal(st)
		}
	}
}

func c13AssertIdleHistory(t *testing.T, f *compactRetryFixture, inode Ino, records int, calls int) {
	t.Helper()
	// Finite observation plus source analysis, not a proof of perpetual state.
	for i := 0; i < 4; i++ {
		if got := f.records(t, inode); got != records {
			t.Fatalf("raw=%d want=%d", got, records)
		}
		f.mu.Lock()
		got := f.calls[inode]
		f.mu.Unlock()
		if got != calls {
			t.Fatalf("object batches=%d want=%d", got, calls)
		}
		if !NativeCompactIdleForTest(f.client) {
			t.Fatal("unexpected active compactor")
		}
		time.Sleep(50 * time.Millisecond)
	}
}

func TestC13WriteBelowThreshold(t *testing.T) {
	for _, backend := range []string{"memkv", "sqlite"} {
		for _, n := range []int{5, 34, 98} {
			t.Run(fmt.Sprintf("%s/n%d", backend, n), func(t *testing.T) {
				f := newCompactRetryFixture(t, backend)
				inode := f.file(t, "c13-low", 0)
				c13PublicOverwrite(t, f, inode, n)
				c13AssertIdleHistory(t, f, inode, n, 0)
				t.Logf("public_write_records=%d ordinary_batches=0 shadowed_records=%d", n, n-1)
				// Positive control: public Read, not an explicit compact call.
				var live []Slice
				if st := f.m.Read(Background(), inode, 0, &live); st != 0 {
					t.Fatal(st)
				}
				f.next(t)
				f.wait(t)
				c13AssertIdleHistory(t, f, inode, 1, 1)
				t.Log("read_trigger_control: records=1 ordinary_batches=1")
			})
		}
	}
}

func TestC13PostSnapshotLowTail(t *testing.T) {
	for _, backend := range []string{"memkv", "sqlite"} {
		t.Run(backend, func(t *testing.T) {
			f := newCompactRetryFixture(t, backend)
			inode := f.file(t, "c13-tail", 0)
			hold := f.hold(inode, 1)
			c13PublicOverwrite(t, f, inode, 99) // Actual ordinary Write threshold.
			f.next(t)                           // Metadata snapshot is already read.
			c13PublicOverwrite(t, f, inode, 5)  // Counts 100..104 do not issue another request.
			hold.release()
			f.wait(t)
			c13AssertIdleHistory(t, f, inode, 6, 1)
			t.Log("threshold99_batch_done: post_snapshot_tail=5 raw_records=6 ordinary_batches=1")
			var live []Slice
			if st := f.m.Read(Background(), inode, 0, &live); st != 0 {
				t.Fatal(st)
			}
			f.next(t)
			f.wait(t)
			c13AssertIdleHistory(t, f, inode, 1, 2)
			t.Log("read_trigger_control: records=1 ordinary_batches=2")
		})
	}
}
