# 证据 / Evidence

- `logs/stock-verified.log/.json`: final stock run; 13 intended failures, nine controls pass.
- `logs/native-race.log/.json`: final exported-patch replay; 22 leaf cases × 3 passes, no skips.
- `logs/existing-engines.*`, `logs/build.*`, `logs/gofmt.*`: existing-client subset, generic build and formatting.
- `logs/meta-core.*`: complete target attempted; RedisClient passes, unavailable TiKV PD blocks the full target.
- Earlier native-development logs are retained, including `stock.*` with no tests actually run. They are not used for the final count.
- `mail-verification.json`: author/subject/commit-message decoding, application checks, diffstat and three resulting source files matched to the exported patches.
- `original-observation/`: two previously published sanitized files documenting the original idle observation/history analysis. `provenance.json` pins their hashes. This is historical context, not a new deployment run of the native fix.
- Field progress through 2026-10-04 13:30 is described separately in [中文测试报告](../test-report.md#field-validation) / [English test report](../test-report.en.md#field-validation), including stock reproduction, two successful two-hour random workloads and the capacity-stopped sequential run. Those deployment archives are not bundled here; the reports identify persistent paths and core archive hashes. Package verification does not automatically validate those external archives.

新测试日志中的本机工作目录、主目录和模块缓存用 `<WORK>`、`<HOME>`、`<GO_MODULE_CACHE>` 代替；结果、错误和计数保留。这里没有旧扫描 RFC 的测试结果或补丁。Native command records preserve arguments, relevant environment, actual/expected exit codes and timing; historical pool totals are not exact per-file or EC-expanded reclamation.
