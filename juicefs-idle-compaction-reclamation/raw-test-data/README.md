# Evidence / 证据

- `idle-24h/`: original idle time series and raw-slice analysis (not metadata dump).
- `B2/`: separate instrumented new-file experiment, including full sanitized trace and fio results; this mount used no-bgjob.
- `C1/`: manual fallback, repeat cycles, scoped analyses, CRC fio JSON and health samples.
- `C2/`: candidate private-subtree experiment; present only after completion and independent review.
- `offline/`: stock/fixed replay, final meta/object race tests, CLI and existing engine subset logs. `meta-core.log` explicitly records the blocked Redis dependency, not a full-suite pass.
- `manifest.json`: original/private and sanitized/public SHA256 for every exported file. Identifiers/paths are redacted; metrics are unchanged.

Do not use pool totals as exact per-file reclamation. Do not interpret read-during's delayed supervisor completion timestamp as the actual fio measurement interval. See the bilingual test report for attribution boundaries and untested scenarios.

Commands are recorded as executed, with private addresses/paths replaced by conspicuous placeholders. They are evidence, not an executable deployment script. No credentials, full metadata dumps, private keys, test file contents or binaries are published.
