# Ceph NetworkStack::get_worker() 锁外自增导致 worker 分配聚集

## 问题概述

`NetworkStack::get_worker()` 在 `pool_spin` 内选出引用计数最小的 worker，解锁后才自增该计数。多个线程若在 `unlock()` 与 `++references` 之间被调度打断，会读到同一份旧计数、选中同一个 worker，之后各自自增，造成瞬时严重聚集。

同时发起的多个连接（OSD 启动、重连风暴）可能全部落到同一个 worker，其余 worker 空闲。连接与 worker 的绑定是连接级的，建立后不迁移，因此一次瞬时聚集会持续到连接关闭。

## 受影响版本

- Ceph Quincy 17.2.8（`src/msg/async/Stack.cc`）
- 当前 ceph main 分支的 `get_worker()` 与 17.2.8 一致，仍未修复

不受影响：08-8 补丁启用角色池策略时走 `t088_get_worker()`，该方法在锁内完成选点与自增。

## 代码位置

`src/msg/async/Stack.cc`，`NetworkStack::get_worker()`：

```cpp
pool_spin.lock();
for (Worker* worker : workers) {
  unsigned worker_load = worker->references.load();
  if (worker_load < min_load) { current_best = worker; min_load = worker_load; }
}
pool_spin.unlock();          // 锁在此释放
ceph_assert(current_best);
++current_best->references;  // 自增在锁外
```

## 影响性质

- 不是内存安全问题。`Worker` 由 `NetworkStack::workers` 独占持有，只在 `~NetworkStack()` 中统一释放；`references` 归零不会触发释放，不存在 UAF。
- 不是永久失衡。连接关闭时 `release_worker()` 会减计数，后续选择会重新偏移。
- 影响的是负载均衡精度，会加剧 worker 热点。

## 复现与实测

`raw-data/consolidated.cc` 复刻该逻辑：6 个 worker、10 个并发线程同时起跑。

| 方案 | unlock→++ 窗口 | 10 个全部落到同一 worker | 平均最大堆积 | 最坏 |
|---|---|---:|---:|---:|
| 锁外自增 | 无延迟 | 0/300（0.0%） | 4.85 | 8/10 |
| 锁外自增 | 5 μs | 286/300（95.3%） | 9.95 | 10/10 |
| 锁外自增 | 50 μs | 292/300（97.3%） | 9.96 | 10/10 |
| 锁内自增 | 无延迟 | 0/300（0.0%） | 2.00 | 2/10 |
| 锁内自增 | 5 μs | 0/300（0.0%） | 2.00 | 2/10 |
| 锁内自增 | 50 μs | 0/300（0.0%） | 2.00 | 2/10 |

说明：原生窗口只有几条指令，无干扰时概率低；但 `unlock()` 之后线程可被抢占，窗口可拉长到微秒级。窗口放大只是为了让问题稳定可观测，不代表实际系统一定出现 95% 的聚集。

编译与运行：

```sh
g++ -std=c++17 -O2 -pthread consolidated.cc -o consolidated && ./consolidated
```

`raw-data/overhead.cc` 测量临界区开销（2000 万次循环，6 个 worker）：

| 方案 | 每次耗时（三次运行） |
|---|---|
| 锁内自增 | 19.6 / 17.6 / 15.6 ns |
| 锁外自增 | 22.3 / 18.5 / 16.6 ns |

锁内自增开销在测量噪声范围内，没有可测劣化。

## 修复

```cpp
  pool_spin.lock();
  for (Worker* worker : workers) {
    unsigned worker_load = worker->references.load();
    if (worker_load < min_load) { current_best = worker; min_load = worker_load; }
  }
  if (current_best)
    ++current_best->references;
  pool_spin.unlock();
  ceph_assert(current_best);
  return current_best;
```

`if (current_best)` 是必要的：原代码在解锁后由 `ceph_assert` 兜底，自增移入锁内后 assert 尚未执行，`workers` 为空时会空指针解引用。

`pool_spin` 是 `ceph::spinlock`，持锁执行一次 `std::atomic_uint` 自增在 x86 上即一条 `lock xadd`，开销可忽略。

`release_worker()` 的 `fetch_sub` 仍在锁外，但减计数不会造成多个线程选中同一目标，不构成同类问题。

## 社区调研

检索 GitHub ceph/ceph 的 issues、pull requests、commits 及 tracker.ceph.com，未找到针对该锁外自增问题的报告或讨论。

相关但不同的问题：

| 编号 | 内容 | 与本问题的区别 |
|---|---|---|
| PR #15897 / #16323 | DPDK local listen table 分支漏加 `references`，导致 `assert(oldref > 0)`；后 revert | 计数遗漏，非锁外自增 |
| PR #19886 | DPDK 路径同样漏更新 `references` | 同上 |
| PR #10702 | `ms_async_op_threads=1` 时早期 WorkerPool 启动崩溃 | 线程池创建时序，非本问题 |

PR #15897 中维护者回复 "the reference doesn't mean the lifecycle of Worker, it's just a hit about connection aggressive"，只说明该计数不是生命周期引用计数，未涉及均衡性问题。

结论：目前没有公开材料表明该问题被提出过，也没有公开表态说无需关注；"官方已知并接受"没有依据。

## 文件

| 文件 | 说明 |
|---|---|
| `README.md` | 本文件 |
| `raw-data/consolidated.cc` | 锁外/锁内自增在不同抢占窗口下的对比程序 |
| `raw-data/consolidated.out` | 上表数据 |
| `raw-data/overhead.cc` | 临界区开销测量程序 |
| `raw-data/overhead.out` | 上述耗时数据 |