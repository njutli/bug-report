#!/usr/bin/env python3
"""Verify and summarize the bundled V2 test evidence without a running cluster."""

from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import tarfile


root = Path(__file__).resolve().parent
archive = root / "test-logs.tar.gz"
with tarfile.open(archive, "r:gz") as bundle:
    logs = {
        member.name: bundle.extractfile(member).read()
        for member in bundle.getmembers() if member.isfile()
    }


def text(name):
    return logs[name].decode()


def outcomes(name):
    return re.findall(r"^\s*--- (PASS|FAIL|SKIP): (\S+) \(", text(name), re.M)


def leaves(name):
    rows = outcomes(name)
    names = {test for _, test in rows}
    leaf_names = {test for test in names if not any(other.startswith(test + "/") for other in names)}
    return Counter((status, test) for status, test in rows if test in leaf_names)


race_logs = ["reclaim-race-final.log", "budget-race.log", "paging-race-final.log"]
race = Counter()
for name in race_logs:
    assert not re.search(r"^WARNING: DATA RACE|^FAIL\b", text(name), re.M), name
    assert "\nPASS\n" in text(name), name
    counts = leaves(name)
    assert all(status == "PASS" and count == 3 for (status, _), count in counts.items()), name
    race.update(counts)
assert all(count == 3 for count in race.values())

stock = leaves("stock-regression.log")
assert stock == Counter({("FAIL", "TestReclaimRegression/memkv"): 1, ("FAIL", "TestReclaimRegression/sqlite"): 1})
assert text("stock-regression.log").count("RECLAIM_MISSING") == 2
assert "build failed" not in text("stock-regression.log")

assert ("PASS", "TestReclaimMountConfig") in outcomes("cli-final.log")
for test in ["TestMemKVClient", "TestSQLiteClient", "TestBadgerClient"]:
    assert ("PASS", test) in outcomes("meta-inprocess.log")
assert ("PASS", "TestRedisClient") in outcomes("meta-core.log")
assert "not available" in text("meta-core.log") and "127.0.0.1:2379" in text("meta-core.log")
assert "gogfapi" in text("extended-suites.log") and "TestGetInode" in text("extended-suites.log")
assert "sudo: not found" in text("cmd-suite.log")

crc = re.findall(r"CRC=PASS old_objects_deleted=(\d+) actual_compaction_PUT_bytes=(\d+)", text("reclaim-race-final.log"))
negative = re.findall(r"victim_rewrites=(\d+) sentinel_rewrites=(\d+) actual_added_PUT_bytes=(\d+)", text("reclaim-race-final.log"))
assert crc == [("3", "98304")] * 6
assert negative == [("0", "1", "98304")] * 9
amp = Counter(re.findall(r"user_delta_bytes=786432 compact_rewrite_bytes=(\d+) amplification=(\d+)", text("reclaim-race-final.log")))
assert amp == Counter({("201326592", "256"): 3, ("0", "0"): 3})
assert "SEARCH jfs_chunk USING INDEX" in text("paging-race-final.log")

patch = (root / "budgeted-reclamation.patch").read_bytes()
result = {
    "base_commit": "0b90c7db5a929ae6adc5faad948d108efd2c99f9",
    "patch_sha256": hashlib.sha256(patch).hexdigest(),
    "patch_files": len(re.findall(rb"^diff --git ", patch, re.M)),
    "archive_sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
    "expected_stock_failures": 2,
    "race_leaf_cases": len(race),
    "race_leaf_executions": sum(race.values()),
    "race_repetitions_per_case": 3,
    "cli_configuration_test": "PASS",
    "existing_engine_tests": {name: "PASS" for name in ["Redis", "MemKV", "SQLite", "Badger"]},
    "real_object_crc_passes": len(crc),
    "real_object_negative_controls_passes": len(negative),
    "small_overwrite_comparison": {"user_bytes": 786432, "v1_planned_rewrite_bytes": 201326592, "v2_planned_rewrite_bytes": 0},
    "sqlite_range_seek": "PASS",
    "full_meta_core": "NOT_PASSED: isolated TiKV unavailable",
    "full_pkg_suite": "NOT_PASSED: offline gogfapi dependency and container root-inode assumption",
    "full_cmd_suite": "NOT_RUN: isolated environment lacks sudo",
    "production_tikv_ceph_validation": "NOT_RUN",
    "log_sha256": {name: hashlib.sha256(data).hexdigest() for name, data in sorted(logs.items())},
    "race_case_counts": {test: count for (_, test), count in sorted(race.items())},
}
print(json.dumps(result, ensure_ascii=False, indent=2))
