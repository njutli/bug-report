# Patch application and scope

Base: Ceph Quincy 17.2.8, `f817ceb7f187defb1d021d6328fa833eb8e943b3`.

| Number | Contents | Dependencies |
|---|---|---|
| 0001 | Configurable proportional pools, role reservations, release and msgr1/msgr2 connection replacement | Standalone core |
| 0002 | Worker TID and epoll ownership | Optional lightweight observation |
| 0003 | Message correlation context | Prerequisite for deeper observation |
| 0004 | Message send/receive events | Requires 0003 |
| 0005 | EC shard and completion-chain events | Requires 0003/0004 |

Apply 0001 for the core functionality. For the complete observation build, apply 0001–0005 in order from the same clean base. Do not apply 0001 twice.

## Core mechanism

The core targets OSD POSIX AsyncMessenger. Native `ms_async_op_threads` still controls the total worker threads per OSD. Enabled mode supports 2–24 actual workers and assigns public workers using `clamp(floor(T * public_weight / (public_weight + other_weight)), 1, T-1)`. Default weights 1:2 give 2+4 at six workers and 4+8 at twelve workers per OSD.

- Distinguish public data, cluster data, auxiliary and public-loopback roles. Public data and public loopback use the public pool; cluster and auxiliary connections use the other pool with separate role counters. Heartbeats, bootstrap and loopback do not inflate cluster-data counts.
- Select by live reservations of the same role, then total worker references, with rotating tie-breaking. Selection and reservation share the pool lock and include connections still being established.
- Maintain worker-reservation counts across failed accepts, connection close and connection reestablishment/replacement under Ceph's msgr1/msgr2 messaging protocols. Reservation transfer during replacement preserves lifecycle correctness; it is not online load migration.

Public traffic carries client requests, object data and responses to/from the primary OSD. Cluster traffic carries EC shards and replies and can also include recovery, backfill or replication. EC encoding occurs on the primary OSD, not the client.

The mechanism is not byte/CPU-adaptive balancing. It does not change EC or durability, pin CPUs, split a single connection or rebalance established connections. The core is independent of observation patches. Test configurations and measurements are in the [test report](../test-report.md).

## Application

For the core functionality, use a separate clean checkout of the upstream base:

```sh
packet=/absolute/path/to/ceph-async-worker-role-pools
git checkout f817ceb7f187defb1d021d6328fa833eb8e943b3
git am "$packet/patches/0001-msgr-configurable-role-pools.patch"
```

For the complete build used in the reported measurements, use another clean checkout of the same base and replace the `git am` command above with:

```sh
git am \
  "$packet/patches/0001-msgr-configurable-role-pools.patch" \
  "$packet/patches/0002-debug-worker-identity.patch" \
  "$packet/patches/0003-debug-message-context.patch" \
  "$packet/patches/0004-debug-messenger-events.patch" \
  "$packet/patches/0005-debug-ec-completion-events.patch"
```

Choose one of these alternatives; do not run both on the same checkout.

Do not stack the older fixed-worker isolation patch or reapply this series to a tree already containing it. If application fails, resolve the Git am state before applying subsequent patches.

The prototype uses startup environment variables passed only to the target OSD process, not official Ceph configuration options:

- `CEPH_T088_WORKER_POLICY=1` enables the policy; unset or 0 uses native allocation.
- `CEPH_T088_PUBLIC_WEIGHT` and `CEPH_T088_OTHER_WEIGHT` each accept 1–1000, default 1:2.
- `ms_async_op_threads` still controls the total. Enabled mode requires OSD/POSIX, matching configured/actual worker counts, and a total of 2–24.

Do not propagate this switch globally to MON/MGR or other Ceph services. Enabled mode rejects non-OSD or unsupported transports. The prototype does not change weights online or migrate established connections.

