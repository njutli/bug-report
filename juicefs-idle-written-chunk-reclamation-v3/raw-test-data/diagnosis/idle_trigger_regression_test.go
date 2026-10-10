/*
 * JuiceFS, Copyright 2026 Juicedata, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package meta

import (
	"encoding/json"
	"testing"
	"time"
)

// Compiles unchanged on V2: unknown JSON config is ignored there. Only public
// Write and actual NewSession timer startup; no new V3 method is called.
func TestIdleTriggerRegression(t *testing.T) {
	for _, backend := range []string{"memkv", "sqlite", "redis"} {
		for _, scenario := range []string{"low2", "low34", "tail"} {
			t.Run(backend+"/"+scenario, func(t *testing.T) {
				f := newCompactRetryFixture(t, backend)
				f.m.conf.NoBGJob = false
				if err := json.Unmarshal([]byte(`{"IdleCompactDelay":250000000}`), f.m.conf); err != nil {
					t.Fatal(err)
				}
				if err := f.client.NewSession(false); err != nil {
					t.Fatal(err)
				}
				t.Cleanup(func() { _ = f.client.CloseSession() })
				inode := f.file(t, "trigger", 0)
				write := func(n int) {
					for i := 0; i < n; i++ {
						var id uint64
						if st := f.m.NewSlice(Background(), &id); st != 0 {
							t.Fatal(st)
						}
						f.mu.Lock()
						f.owners[id] = inode
						f.mu.Unlock()
						if st := f.m.Write(Background(), inode, 0, 0, Slice{Id: id, Size: 64 << 10, Len: 64 << 10}, time.Now()); st != 0 {
							t.Fatal(st)
						}
					}
				}
				switch scenario {
				case "low2":
					write(2)
				case "low34":
					write(34)
				case "tail":
					gate := f.hold(inode, 1)
					write(99)
					f.next(t)
					write(5)
					gate.release()
					f.wait(t)
				}
				deadline := time.Now().Add(time.Second)
				for {
					// memkv returns shared backing buffers. Observe only with no
					// admitted compactor, holding the admission lock through this
					// test-only raw read; do not use public Read as a trigger.
					f.m.Lock()
					n, idle := 0, len(f.m.compacting) == 0
					if idle {
						n = f.records(t, inode)
					}
					f.m.Unlock()
					if idle && n == 1 {
						break
					}
					if time.Now().After(deadline) {
						t.Fatalf("IDLE_TRIGGER_MISSING: scenario=%s raw_records=%d idle=%v, no public Read/forced compact", scenario, n, idle)
					}
					time.Sleep(5 * time.Millisecond)
				}
			})
		}
	}
}
