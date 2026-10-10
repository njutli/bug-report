# 原始证据索引

本包只保留支撑结论的小文件；不包含有效用户文件、原始卷dump、密钥或大二进制。字节单位均为B，展示GiB使用2^30。`SHA256SUMS`覆盖交付文件（自身和后生成的verification.json除外）。

| 目录 | 来源及用途 |
|---|---|
| `logs/` | 20261004-LT002-V3-IDLE-WRITTEN-CHUNKS最终V3 race日志、V2失败对照、选定既有后端/CLI/VFS结果 |
| `diagnosis/` | C13低记录数定位：脱敏聚合摘要、原版/V2诊断race、相同诊断测试；并非敏感原始dump |
| `field/c14/` | 独立续跑时间线审核，保留原loops计数失败及恢复上下文，不把原失败改成PASS |
| `field/c15/` | 正式2小时结果、无用户读的回收冻结/观测、事件、64 GiB CRC；不混入准备维护结果 |
| `field/c16/` | 原核心包中的result、cold-frozen、计数、事件、两窗口fio/runtime、最终128 GiB CRC |
| `field/c17/` | 同上，纯随机写核心结果；保留最终慢操作告警 |

原C16核心包SHA256：`dd8f48bded71f0ef5bcc88036b50276bb366e36ec8f2a1027236a173a37bbfa6`。
原C17核心包SHA256：`5f6a3fff6bc7816b4e5e9c58c8a84c15e139951948661d662aaf3ed73b9d7383`。

原持久证据根目录：`/mnt/c/SunRise/test/reliability/`，子目录见`provenance.json`。远端原始证据根目录：`/data/reliability-lt-results/`。网络补取失败不阻断已有离线材料整理；未取回文件不加入包内验证范围。

复核`python3 tools/verify.py`：检查清单、225结果、9项V2预期失败、C15～C17最小引用及冻结先于CRC，C16/C17 fio/runtime实际负载及冷期IO计数不增长。C15缺正式fio，不独立复算298 GiB，仅核对权威结果字段；C14只保留时间线审查、不计入该自动验证器完整现场签收。
