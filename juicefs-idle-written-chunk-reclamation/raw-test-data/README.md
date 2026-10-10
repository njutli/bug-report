# 验证证据

根因与修复证据分开：

- `cause/independent-audit.json`：真实TiKV/Ceph R01/R02归档独立复核，原档hash、逐Write重放、无触发、冷期、人工正对照和CRC。
- `cause/R01-*.json`、`R02-*.json`：每chunk归因和维护排空摘要；不是候选效果。
- `focused-race.*`：新候选36叶子×3=108PASS，无跳过/race。
- `stock-negative.*`：上游真实对象timer目标75秒无触发，预期FAIL。
- `clients.*`：新候选原客户端非race回归PASS。
- `clients-race.*`、`stock-clients-race.*`：双方扩大客户端race失败，完整保留。
- `build.*`：新候选开发构建。
- `field-short/first-auto-review.json`、`first-crc-review.json`、`first-closure.json`：真实TiKV/Ceph首轮自动冻结、之后CRC及正常收口。auto审核时CRC尚未执行，不能只读这一文件就宣称CRC通过。
- `field-short/repeat-auto-review.json`：第二轮独立无读自动回收审核。
- `field-short/overlap-auto-review.json`：前后台交叠、同chunk新Write与代次/后续提交证据。
- `field-short/repeat-overlap-closure-review.json`：第二轮及交叠的CRC、最终排空/卸载和资源汇总；含完整脱敏归档hash，完整归档留存、可按需提供。

本地`.log`为原始Go输出；配套`.json`记录命令、退出码、用时。统计必须同时核对顶层/包结果，不能只看leaf。`field-short/`是已有真实后端短验证的独立复核摘要，非全部原始IO/trace；原始归档按hash关联，不把摘要称作完整trace。它证明已记录的短功能场景，不是24/72小时或生产验收结果。
