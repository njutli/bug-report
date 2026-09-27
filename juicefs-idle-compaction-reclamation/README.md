# JuiceFS 停写后历史 slice 引用滞留：维护验证与自动重发现候选

[English](README.en.md)

固定逻辑数据集反复覆盖写后，部分旧对象仍由 chunk 的原始 slice 列表引用；停写后未再次触发合并，空闲 24 小时仍未回到原空间基线。手工精确文件 compact 可以合并引用并回收对象，内容校验通过。

并发门本身是保护机制。本报告讨论的是**被跳过或未达到触发条件的冷 chunk 是否需要后台重发现**，不是已确认的数据丢失，也不把全部空间放大归因于并发门。

## 状态

- 维护兜底：8 个旧文件合并、完整 CRC 通过；对象池 stored 净减 8.89 GiB。重复覆盖—维护验证见测试报告。
- 候选补丁：新增默认关闭的 `--compact-interval`，从指定挂载子树周期性重新发现冷 chunk，复用原合并与事务校验。
- 离线：原版失败/候选通过、取消/隔离/重试/race、真实对象内容与客户端重启验证完成。
- 集群 canary：真实 TiKV/Ceph、同一 1 GiB 文件经过客户端进程重启，开启扫描后无用户 IO/手工 compact，约 99 秒采样确认 **3,402→16 条、1.845→1 GiB**，完整 CRC 通过、正常卸载。
- **不是生产验收或上游已接受的修复**。全树扫描成本、在途操作取消、多客户端协调仍需讨论。

## 文件

| 文件 | 内容 |
| --- | --- |
| `bug-report.md` / `.en.md` | 现象、源码机制、归因边界和讨论问题 |
| `test-report.md` / `.en.md` | 维护、离线回归和真实 TiKV/Ceph 小规模验证 |
| `patches/` | 基于固定 v1.4.1 的三个有序提交：回归、候选实现、扩展验证 |
| `raw-test-data/` | 脱敏后的精简原始日志、结果和采集命令说明 |

基础提交：`0b90c7db5a929ae6adc5faad948d108efd2c99f9`。实验环境另有既有 VFS B-catchup 修复，与本次 meta 改动分开说明；本次三个提交不包含它。

```bash
git checkout 0b90c7db5a929ae6adc5faad948d108efd2c99f9
git am /path/to/patches/0001-*.patch
# 原版应在 8 个正例失败，2 个取消负控通过；这是候选要求的重发现契约。
go test -count=1 -run '^TestIdleCompactionMechanism$' ./pkg/meta
git am /path/to/patches/0002-*.patch /path/to/patches/0003-*.patch
go test -race -count=3 -run '^TestIdleCompaction' ./pkg/meta
go test -race -count=5 -run '^TestIdleCompactionRealObjectIntegration$' ./pkg/vfs
go test -count=1 -run '^TestIdleCompactionMountConfig$' ./cmd
```

作者：Li Lingfeng。2026-09-27。
