# Bug Report

| Bug | 项目 | 状态 |
|-----|------|------|
| [juicefs-vfs-flush-dispatch-race](juicefs-vfs-flush-dispatch-race/) | JuiceFS VFS 异步 slice ID 分配导致满 block 漏派发 | 补丁+测试就绪，待社区提交 |
| [juicefs-idle-compaction-reclamation](juicefs-idle-compaction-reclamation/) | JuiceFS 冷文件历史 slice 引用滞留与周期性重发现候选 | 维护兜底及小规模候选验证完成，待上游讨论；非生产验收 |
| [juicefs-budgeted-idle-reclamation](juicefs-budgeted-idle-reclamation/) | 原生 compaction 忙时漏处理的最小补偿修复 | 仅 base.go +42/-5；测试独立；原版预期失败、修复后 66 次 race 通过 |
| [juicefs-idle-written-chunk-reclamation](juicefs-idle-written-chunk-reclamation/) | 已确认低记录数Write停写缺触发：窄范围回收候选 | 实现2文件+191/-19；独立测试108次race通过；扩大客户端race双方失败，待候选真实后端短轮 |
