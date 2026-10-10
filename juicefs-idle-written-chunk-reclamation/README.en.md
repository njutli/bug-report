# Overwrite history retained after writes stop: report and proposal

[中文](README.md) · Base: JuiceFS v1.4.1, commit `0b90c7db5a929ae6adc5faad948d108efd2c99f9`.

## What is reported

Repeated overwrites can leave old slices referenced even though the logical file size is unchanged. If a chunk remains below the native compaction trigger and receives no further writes or reads, those references may persist. In two TiKV/Ceph experiments, 4 GiB of files referenced 20 GiB of source data after 60 idle minutes; manual compaction reduced references to 4 GiB and CRC passed.

The proposal tracks successfully written chunks in a bounded client-local set and checks them after an idle interval, reusing existing compaction, commit and deletion paths. Local tests, two real-backend short checks and a foreground-overlap correctness check have completed. This is a proposal for discussion, not completed soak or production acceptance.

## Documents

| Material | Purpose |
|---|---|
| [Bug report](bug-report.en.md) / [中文](bug-report.md) | Observations, cause, implementation proposal and limitations |
| [Test report](test-report.en.md) / [中文](test-report.md) | Environment, methods, results, reproduction commands and remaining checks |
| [patches/](patches/) | Implementation patch 0001, separate test patch 0002 and baseline manifest |
| [Evidence index](raw-test-data/README.md) | Original test logs, cause audits and candidate short-check summaries |
| [Field checklist](field-validation.md) | Real-backend validation plan and coverage boundaries |
| [Verifier](tools/verify.py), [SHA256SUMS](SHA256SUMS) | Submission-artifact integrity checks; usage is in the test report |
