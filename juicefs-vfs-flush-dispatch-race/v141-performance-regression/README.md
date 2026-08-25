# JuiceFS v1.4.1 randwrite 性能测试

## 测试对象

| 版本 | 来源 | md5 |
|---|---|---|
| v1.4.1 原版 | GitHub tag v1.4.1 (commit 0b90c7d)，`go build -tags ceph` | 58f4406e40e2001601711413682f4dde |
| v1.4.1 + 补丁 | v1.4.1 原版 + writer.go 补丁，同样构建方式 | 24fae0852051c80ca571cb2f20275d46 |

## 补丁内容

文件：`pkg/vfs/writer.go`，函数 `prepareID`，在 `SetID(s.id)` 后增加 3 行：

```diff
 if s.writer != nil && s.writer.ID() == 0 {
     s.writer.SetID(s.id)
+    if !s.freezed && int(s.slen) >= f.w.blockSize {
+        s.writer.FlushTo(int(s.slen))
+    }
 }
 f.Unlock()
```

完整 diff 见 `raw-data/writer-prepareID-flush-patch.diff`。

## 集群环境

### 节点拓扑

共 4 台物理服务器：

| 节点 | 角色 | CPU | 内存 |
|---|---|---|---|
| client | JuiceFS 客户端 + Ceph MON | 96 核 | 1TB |
| node-1 | Ceph MON + Ceph OSD ×2 + TiKV + PD | 128 核 | 1TB |
| node-2 | Ceph MON + Ceph OSD ×2 + TiKV + PD | 128 核 | 1TB |
| node-3 | Ceph MON + Ceph OSD ×2 + TiKV + PD | 128 核 | 1TB |

### 磁盘布局

每个 TiKV/Ceph 节点（node-1/2/3）有 4 块 NVMe：

| 设备 | 型号 | 容量 | 用途 |
|---|---|---|---|
| nvme0n1 | Dell DC NVMe CD8 U.2 960GB | 894GB | 系统盘（ext4） |
| nvme1n1 | Dell DC NVMe CD8 U.2 960GB | 894GB | ext4，挂载 /mnt/jfs-tikv — **TiKV 数据目录（KV + WAL + Raft 共享此盘**） |
| nvme2n1 | Dell DC NVMe 7500 U.2 ISE RI 7.68TB | 7TB | LVM → Ceph OSD 数据盘 |
| nvme3n1 | Dell DC NVMe 7500 U.2 ISE RI 7.68TB | 7TB | LVM → Ceph OSD 数据盘 |

OSD 的 RocksDB WAL/DB 使用 tmpfs-backed loop device：每节点在 200GB tmpfs（`/mnt/dbwal`）上创建 sparse file（2×40GB db + 2×10GB wal），通过 `losetup` 映射为 loop device，组成 LVM，格式化为 ceph_bluestore。

### TiKV 配置

三节点 TiKV 集群，每个节点：
- data-dir: `/mnt/jfs-tikv/tikv`（在 nvme1n1 上）
- RocksDB WAL: `/mnt/jfs-tikv/tikv/wal`（同盘）
- RaftDB: `/mnt/jfs-tikv/tikv/raft`（同盘）
- **KV、WAL、Raft 共享 /dev/nvme1n1**
- block-cache: 4GB
- sync-log: true
- 端口：TiKV 20160，status 20180
- PD 端口：2379（三节点各自一个）

### Ceph 配置

- 版本：17.2.8 quincy
- 6 个 OSD（每节点 2 个），分布在 nvme2n1 + nvme3n1 上
- 数据池 `juicefs-data`：EC 4+2（jerasure reed_sol_van, k=4 m=2），32 PG，size=6
- crush-failure-domain=osd
- 三节点 MON，端口 3300/6789

### JuiceFS 配置

- 版本：v1.4.1 (commit 0b90c7d)，构建命令 `go build -tags ceph`（需安装 librados-dev）
- 补丁版：在 v1.4.1 源码上应用 `writer.go` 补丁后，同样 `go build -tags ceph` 构建
- meta 引擎：TiKV（三节点 PD）
- 数据后端：Ceph (`ceph://juicefs-data/juicefs-prod/`)
- 挂载参数：`--max-uploads 150 --cache-size 0 --max-fuse-io 256K`
- Ceph 客户端配置：进程私有 conf，`[client] ms_async_op_threads = 8`
- 对象数基线：~2,434,614

## 测试方法

| 项 | 值 |
|---|---|
| fio | 3.28，256K bs，128 jobs，iodepth=128，direct=1，180s |
| 基线脚本 | FULLBASELINE_V4.sh（见 raw-data/），OBJ_GATE=1，每项 3 轮，--remount |
| 测试项 | seqread, mseqread, randread, randrw, seqwrite, mseqwrite, randwrite |

## 测试结果

### 全量 7 项（v1.4.1 原版，fio 汇总，MiB/s）

| 项 | r1 | r2 | r3 | 中位数 |
|---|---:|---:|---:|---:|
| seqread | 1499 | 1522 | 1514 | 1514 |
| mseqread | 5194 | 5478 | 5452 | 5452 |
| randread | 5563 | 5543 | 5469 | 5543 |
| randrw | 1806 | 1803 | 1775 | 1803 |
| seqwrite | 1529 | 1579 | 1587 | 1579 |
| mseqwrite | 4912 | 4906 | 4579 | 4906 |
| randwrite | 551 | 552 | 551 | 551 |

### 全量 7 项（v1.4.1 + 补丁，fio 汇总，MiB/s）

| 项 | r1 | r2 | r3 | 中位数 |
|---|---:|---:|---:|---:|
| seqread | 1425 | 1442 | 1430 | 1430 |
| mseqread | 5181 | 5273 | 5305 | 5273 |
| randread | 5571 | 5569 | 5605 | 5571 |
| randrw | 2024 | 1939 | 1758 | 1939 |
| seqwrite | 1596 | 1601 | 1588 | 1596 |
| mseqwrite | 4684 | 5025 | 4701 | 4701 |
| randwrite | 2754 | 2726 | 2679 | 2726 |

### randwrite 补丁对比（逐轮，MiB/s）

| 轮次 | v1.4.1 原版 | v1.4.1 + 补丁 |
|---|---:|---:|
| r1 | 551 | 2754 |
| r2 | 552 | 2726 |
| r3 | 551 | 2679 |

## 原始数据文件

```
raw-data/
├── FULLBASELINE_V4.sh                              # 基线测试脚本
├── writer-prepareID-flush-patch.diff               # 补丁 diff
└── fio/
    ├── v141-seqread-r1.txt          # v1.4.1 原版 7 项 fio 输出（21 个文件）
    ├── v141-seqread-r2.txt
    ├── v141-seqread-r3.txt
    ├── v141-mseqread-r1.txt
    ├── v141-mseqread-r2.txt
    ├── v141-mseqread-r3.txt
    ├── v141-randread-r1.txt
    ├── v141-randread-r2.txt
    ├── v141-randread-r3.txt
    ├── v141-randrw-r1.txt
    ├── v141-randrw-r2.txt
    ├── v141-randrw-r3.txt
    ├── v141-seqwrite-r1.txt
    ├── v141-seqwrite-r2.txt
    ├── v141-seqwrite-r3.txt
    ├── v141-mseqwrite-r1.txt
    ├── v141-mseqwrite-r2.txt
    ├── v141-mseqwrite-r3.txt
    ├── v141-randwrite-r1.txt
    ├── v141-randwrite-r2.txt
    ├── v141-randwrite-r3.txt
    ├── v141-patched-seqread-r1.txt       # v1.4.1+补丁 7 项 fio 输出（21 个文件）
    ├── v141-patched-seqread-r2.txt
    ├── v141-patched-seqread-r3.txt
    ├── v141-patched-mseqread-r1.txt
    ├── v141-patched-mseqread-r2.txt
    ├── v141-patched-mseqread-r3.txt
    ├── v141-patched-randread-r1.txt
    ├── v141-patched-randread-r2.txt
    ├── v141-patched-randread-r3.txt
    ├── v141-patched-randrw-r1.txt
    ├── v141-patched-randrw-r2.txt
    ├── v141-patched-randrw-r3.txt
    ├── v141-patched-seqwrite-r1.txt
    ├── v141-patched-seqwrite-r2.txt
    ├── v141-patched-seqwrite-r3.txt
    ├── v141-patched-mseqwrite-r1.txt
    ├── v141-patched-mseqwrite-r2.txt
    ├── v141-patched-mseqwrite-r3.txt
    ├── v141-patched-randwrite-r1.txt
    ├── v141-patched-randwrite-r2.txt
    ├── v141-patched-randwrite-r3.txt
    ├── v141-patched-randwrite-r1-jfs-stats-pre.txt   # JuiceFS metrics
    ├── v141-patched-randwrite-r1-jfs-stats-post.txt
    ├── v141-patched-randwrite-r2-jfs-stats-pre.txt
    ├── v141-patched-randwrite-r2-jfs-stats-post.txt
    ├── v141-patched-randwrite-r3-jfs-stats-pre.txt
    └── v141-patched-randwrite-r3-jfs-stats-post.txt
```
