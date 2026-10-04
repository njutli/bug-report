#!/usr/bin/env python3
"""Verify the minimal native patch pair and its final before/after evidence."""
import argparse
from collections import Counter
from email import policy
from email.parser import BytesParser
import hashlib
import json
from pathlib import Path
import re


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def require(value, message):
    if not value:
        raise ValueError(message)


def results(path):
    events = [json.loads(line) for line in path.read_text().splitlines() if line.strip()]
    names = {e["Test"] for e in events if "Test" in e}
    leaves = {n for n in names if not any(x.startswith(n + "/") for x in names)}
    actions = {a: Counter(e["Test"] for e in events if e.get("Action") == a and e.get("Test") in leaves)
               for a in ("pass", "fail", "skip")}
    return events, leaves, actions


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path)
    parser.add_argument("--write-manifest", action="store_true")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    manifest = json.loads((root / "patches/manifest.json").read_text())
    require(manifest["base_commit"] == "0b90c7db5a929ae6adc5faad948d108efd2c99f9", "wrong base")
    require(len(manifest["patches"]) == 2, "expected separate fix and test patches")
    output = {"base_commit": manifest["base_commit"], "patches": []}
    for n, patch in enumerate(manifest["patches"]):
        file = root / patch["path"]
        require(sha(file) == patch["sha256"], "patch hash differs")
        message = BytesParser(policy=policy.default).parsebytes(file.read_bytes().split(b"\n", 1)[1])
        require(str(message["From"]) == patch["author"] and str(message["Subject"]) == patch["subject"], "mail metadata differs")
        require(str(message["Date"]) == patch["date"] and str(message["Subject"]).startswith(f"[PATCH {n+1}/2]"), "mail date/number differs")
        body = message.get_payload(decode=True).decode()
        require(len(body.split("\n---\n", 1)[0].strip()) > 200, "commit message missing")
        diff = body[body.index("diff --git "):].split("\nbase-commit: ", 1)[0]
        require(hashlib.sha256(diff.encode()).hexdigest() == patch["diff_sha256"], "diff differs")
        paths = re.findall(r"^diff --git a/(\S+) b/\1$", diff, re.M)
        require(paths == [item["path"] for item in patch["files"]], "file list differs")
        require(paths == ["pkg/meta/base.go"] if n == 0 else
                paths == ["pkg/meta/compact_retry_test.go", "pkg/meta/compact_retry_objects_test.go"], "patch scope differs")
        added = sum(line.startswith("+") and not line.startswith("+++") for line in diff.splitlines())
        removed = sum(line.startswith("-") and not line.startswith("---") for line in diff.splitlines())
        require((added, removed) == ((42, 5) if n == 0 else (621, 0)), "change size differs")
        if args.source:
            for item in patch["files"]:
                require(sha(args.source / item["path"]) == item["result_sha256"], "result source differs")
        output["patches"].append({"path": patch["path"], "sha256": patch["sha256"], "files": paths,
                                   "insertions": added, "deletions": removed})

    logs = root / "raw-test-data/logs"
    stock_events, stock_leaves, stock = results(logs / "stock-verified.log")
    events, leaves, fixed = results(logs / "native-race.log")
    require(stock_leaves == leaves and len(leaves) == 22, "unexpected test selection")
    require(len(stock["fail"]) == 13 and len(stock["pass"]) == 9 and not stock["skip"], "unexpected stock result")
    for name in stock["fail"]:
        text = "".join(e.get("Output", "") for e in stock_events if e.get("Test") == name)
        require("COMPACT_RETRY_MISSING" in text, "stock failed for an unrelated reason")
    require(len(fixed["pass"]) == 22 and set(fixed["pass"].values()) == {3} and not fixed["fail"] and not fixed["skip"], "native regression failed/skipped")
    object_output = "".join(e.get("Output", "") for e in events if e.get("Test") == "TestCompactRetryRealObjects")
    require(object_output.count("content_bytes=98304 CRC=PASS removed_source_slices=8") == 3, "object evidence differs")
    for name in ("stock-verified", "native-race", "existing-engines", "build", "gofmt"):
        run = json.loads((logs / (name + ".json")).read_text())
        require(run["expectation_met"] and not run["timed_out"], "required command failed")
    race = json.loads((logs / "native-race.json").read_text())
    require("-race" in race["command"] and "-mod=readonly" in race["command"], "wrong test mode")
    existing_events, _, _ = results(logs / "existing-engines.log")
    for name in ("TestMemKVClient", "TestSQLiteClient", "TestBadgerClient"):
        require(any(e.get("Action") == "pass" and e.get("Test") == name for e in existing_events), "existing engine test missing: " + name)
    require(not (logs / "gofmt.log").read_text().strip(), "unformatted source")
    core = json.loads((logs / "meta-core.json").read_text())
    core_output = (logs / "meta-core.log").read_text()
    require(core["exit_code"] != 0 and "<FATAL>: Meta tikv://127.0.0.1:2379" in core_output, "core status changed")
    require("--- PASS: TestRedisClient (" in core_output, "RedisClient result missing")
    mail = json.loads((root / "raw-test-data/mail-verification.json").read_text())
    require(mail["source_matches_tested_patches"] and mail["result_files"] == 3, "mail replay mismatch")
    require([e["sha256"] for e in mail["patches"]] == [e["sha256"] for e in manifest["patches"]], "mail artifact mismatch")
    for item in json.loads((root / "raw-test-data/provenance.json").read_text()):
        require(sha(root / "raw-test-data" / item["path"]) == item["sha256"], "historical evidence differs")
    output.update(stock={"expected_failing_leaf_cases": 13, "passing_controls": 9},
                  fixed={"leaf_cases": 22, "race_repetitions": 3, "passed_leaf_executions": 66, "skips": 0},
                  real_object_crc_passes=3, full_meta_core="blocked: isolated TiKV PD unavailable")

    for file in root.rglob("*.md"):
        text = re.sub(r"```.*?```", "", file.read_text(), flags=re.S)
        for link in re.findall(r"\[[^\]]*\]\(([^)]+)\)", text):
            if "://" in link or link.startswith("#"):
                continue
            target = (file.parent / link.split("#", 1)[0]).resolve()
            require(target.is_relative_to(root) and target.exists(), "invalid local link: " + link)
    checksums = root / "SHA256SUMS"
    if args.write_manifest:
        excluded = {checksums, root / "verification.json"}
        if args.output:
            excluded.add(args.output.resolve())
        files = sorted(f for f in root.rglob("*") if f.is_file() and f not in excluded and "__pycache__" not in f.parts)
        checksums.write_text("".join(f"{sha(f)}  {f.relative_to(root).as_posix()}\n" for f in files))
    if checksums.exists():
        for line in checksums.read_text().splitlines():
            digest, path = line.split("  ", 1)
            target = (root / path).resolve()
            require(target.is_relative_to(root) and sha(target) == digest, "checksum mismatch: " + path)
    output["source_verified"] = bool(args.source)
    output["integrity_checks_passed"] = True
    text = json.dumps(output, indent=2) + "\n"
    if args.output:
        args.output.write_text(text)
    print(text, end="")


if __name__ == "__main__":
    main()
