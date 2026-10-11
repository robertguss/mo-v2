#!/usr/bin/env python3
"""Independent frozen-prediction consumer and actual-source mutation campaign."""
import collections
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
FULL = HERE.parents[1]
REPO = FULL.parents[2]
EVIDENCE = HERE / "evidence"
EVIDENCE.mkdir(exist_ok=True)
spec = importlib.util.spec_from_file_location("frozen_check", FULL / "acceptance/check.py")
frozen = importlib.util.module_from_spec(spec)
spec.loader.exec_module(frozen)
rows = frozen.all_cases()
inputs = FULL / "stage-1/completion/evidence/inputs.json"
source = FULL / "lean/Full/Demand.lean"
original = source.read_text()

# Validate the reused adapter input against frozen ASTs, declaration closure,
# demand metadata and an independently fixed letter-to-address bijection.
encoded = {r["id"]: r for r in json.loads(inputs.read_text())}
assert set(encoded) == {r[0] for r in rows}
for row in rows:
    inp = encoded[row[0]]
    assert inp["main"] == row[3]
    assert inp["functions"] == [[n, *d, n in row[4]] for n, d in frozen.function_table(row[3]).items()]
    start = frozen.STARTS[row[2]]
    addresses = {c[0]: ord(c[0]) - ord("A") for c in start["cells"]}
    address = lambda a: None if a is None else addresses[a]
    assert inp["start"] == {
        "cells": [[address(a), h, address(t), n] for a, h, t, n in start["cells"]],
        "inputs": [[n, k, address(v) if k == "L" else v] for n, k, v in start["inputs"]],
        "outside": [address(a) for a in start["outside"]]}

def command(args, cwd, log, env=None):
    with (EVIDENCE / log).open("a") as out:
        out.write("$ " + " ".join(map(str, args)) + "\n")
        out.flush()
        subprocess.run(args, cwd=cwd, env=env, stdout=out, stderr=subprocess.STDOUT, check=True)

def execute(root, label):
    lean = root / "lean"
    command(["lake", "env", "lean", "--version"], lean, label + ".log")
    command(["lake", "build", "Full.Demand", "Full.Statements"], lean, label + ".log")
    command(["lake", "env", "lean", "-o", ".lake/build/lib/lean/Export.olean", "Export.lean"], lean, label + ".log")
    env = dict(os.environ, FULL3C_INPUTS=str(inputs),
               FULL3C_DEMAND_OUTPUT=str(EVIDENCE / (label + ".json")))
    command(["lake", "env", "lean", "stage-2-run.lean" if root != FULL else "../stage-2/Run.lean"],
            lean, label + ".log", env)
    return json.loads((EVIDENCE / (label + ".json")).read_text())

def consume(observed):
    assert set(observed) == {r[0] for r in rows}
    counts = collections.Counter()
    failures = []
    for row in rows:
        result = observed[row[0]]
        categories = [c for c in row[1] if c.startswith("S1")]
        verdicts = [v for v in result["verdicts"] if v["demanded"]]
        assert {v["name"] for v in verdicts} == set(row[4]), row[0]
        for category in categories:
            counts[category] += 1
            if category.startswith("S1A") and not all(v["accepted"] for v in verdicts):
                failures.append([row[0], category, "must accept"])
            if category.startswith("S1R") and not any(not v["accepted"] for v in verdicts):
                failures.append([row[0], category, "must refuse"])
        if row[9] == "finished":
            assert result["finished"], row[0]
            answer = result["answer"]
            assert json.dumps(answer) == json.dumps(row[6]), (row[0], answer, row[6])
            names = {ord(c[0]) - ord("A"): c[0] for c in frozen.STARTS[row[2]]["cells"]}
            next_fresh = 0
            events = []
            for event in result["events"]:
                if event[0] == "C":
                    names[event[1]] = f"N{next_fresh}"
                    next_fresh += 1
                if event[0] in ("C", "W"):
                    tail = "-" if event[3] is None else names[event[3]]
                    events.append(f"{event[0]} {names[event[1]]} {event[2]} {tail}")
                elif event[0] == "F":
                    events.append(f"F {names[event[1]]}")
            assert events == row[8], (row[0], events, row[8])
        for entry in result["entries"]:
            active, total = False, 0
            for event in result["events"]:
                if event[0] == "E" and event[2] == entry["id"]:
                    active = True
                elif event[0] == "R" and event[1] == entry["id"]:
                    active = False
                elif event[0] == "C" and active:
                    total += 1
            assert total == entry["creates"], (row[0], entry, total)
            verdict = next(v for v in result["verdicts"] if v["name"] == entry["name"])
            if verdict["demanded"] and verdict["accepted"] and entry["unique"] and entry["creates"]:
                failures.append([row[0], entry["name"], "conditional finite counterexample", entry])
    return dict(counts), failures

command(["sha256sum", "-c", "PREDICTIONS.sha256"], FULL / "acceptance", "frozen.log")
command(["python3", "-B", "check.py"], FULL / "acceptance", "frozen.log")
baseline = execute(FULL, "original")
counts, failures = consume(baseline)
assert not failures, failures
report = {"rows": len(rows), "slice1_row_coverage": counts,
          "all_27_categories": sorted({c for r in rows for c in r[1] if c.startswith("S")}),
          "source_sha256": hashlib.sha256(original.encode()).hexdigest(), "mutants": {}}
with tempfile.TemporaryDirectory(prefix="rob1139-preflight-") as tmp:
    root = Path(tmp) / "experiments/03c-checker/full"
    root.mkdir(parents=True)
    shutil.copytree(FULL / "lean", root / "lean", ignore=shutil.ignore_patterns(".lake", "Demand", "Proofs", "Proofs.lean", "__pycache__"))
    # Demand.lean is retained; only unfinished proof subdirectories are omitted.
    trial = root.parent / "trial/lean"
    shutil.copytree(FULL.parent / "trial/lean", trial, ignore=shutil.ignore_patterns(".lake"))
    shutil.copy(FULL / "stage-2/Run.lean", root / "lean/stage-2-run.lean")
    scratch_source = root / "lean/Full/Demand.lean"
    scratch_source.write_text(original)
    clean = execute(root, "scratch-original")
    assert clean == baseline
    variants = {
        "accept-all": original.replace("(check p name).isOk", "true"),
        "reject-all": original.replace("(check p name).isOk", "false"),
        "missing-affine": original.replace("if kind == .list && occurrences body [(name,some 0)] 0 > 1 then", "if false then"),
    }
    for label, mutated in variants.items():
        assert mutated != original
        scratch_source.write_text(mutated)
        (EVIDENCE / (label + "-Demand.lean.txt")).write_text(mutated)
        observed = execute(root, label)
        _, failures = consume(observed)
        assert failures, label
        if label != "reject-all":
            assert any(f[2] == "conditional finite counterexample" for f in failures), label
        else:
            assert any(f[2] == "must accept" for f in failures)
        report["mutants"][label] = failures
assert source.read_text() == original
(EVIDENCE / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps(report, indent=2))
