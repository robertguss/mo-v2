#!/usr/bin/env python3
"""Run the logical definitions on public fixtures; never synthesize expectations.

The predictor's module expands inputs. Only program/start/demand metadata enter
Lean. Independently recorded answers and events remain exclusively in check.py.
All generated evidence goes to the explicitly supplied directory.
"""
import argparse
import importlib.util
import json
from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("predictions", HERE / "acceptance/check.py")
fixtures = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fixtures)


def address(name):
    return None if name is None else ord(name) - ord("A")


def input_row(row):
    initial = fixtures.STARTS[row[2]]
    start = {
        "cells": [[address(a), n, address(t), c] for a, n, t, c in initial["cells"]],
        "inputs": [[n, k, address(v) if k == "L" else v] for n, k, v in initial["inputs"]],
        "outside": [address(a) for a in initial["outside"]],
    }
    gate = row[0].removeprefix("C20-") if row[0] in {"C20-number", "C20-frame", "C20-create"} else ""
    if gate == "create":
        gate = "cell"
    return {
        "id": row[0], "main": row[3], "start": start,
        "functions": [[n, *definition, n in row[4]] for n, definition in fixtures.function_table(row[3]).items()],
        "budget": 29 if row[0] in {"C12", "C13"} else 18 if row[0] == "C14" else 10000,
        "gate": gate,
        "trace": True,
        "cuts": [5, 6, 7, 8] if row[0] == "C16" else [],
        "segments": [[0], [17], [18], [23], [6, 6, 3, 2, 1], [0, 6, 0, 11, 0, 1],
                     [17, 1], [18, 0, 1, 23]] if row[0] == "C19" else [[29, 4]] if row[0] == "C12" else [],
    }


def normalize(row, obs):
    initial = fixtures.STARTS[row[2]]
    names = {address(a): a for a, *_ in initial["cells"]}
    fresh = 0
    events = []
    for event in obs["state"]["events"]:
        op, *args = event
        if op == "C":
            a = args[0]
            assert a not in names, "fresh identity reused"
            names[a] = f"N{fresh}"
            fresh += 1
        if op in {"C", "W"}:
            a, n, tail = args
            events.append(f"{op} {names[a]} {n} {names[tail] if tail is not None else '-'}")
        elif op == "F":
            events.append(f"F {names[args[0]]}")
    status = obs["status"]
    if row[0] in {"C12", "C13", "C14"}:
        assert status == "suspended"
        if row[0] == "C12":
            assert obs["state"]["steps"] == 29 and len(obs["state"]["frames"]) == 7
            status += ":after-7th-spin-Enter;action-29"
        elif row[0] == "C13":
            assert obs["state"]["steps"] == 29 and obs["state"]["actions"][-1] == "Free"
            status += ":after-2nd-Free;action-29"
        else:
            assert len(obs["state"]["frames"]) == 3 and obs["state"]["actions"][-1] == "Enter"
            status += ":after-3rd-spin-Enter"
    if row[0] in {"C20-number", "C20-frame", "C20-create"}:
        assert status == "failed"
        suffix = {"C20-number": "number-before-add-20-3", "C20-frame": "frame-before-one-Enter",
                  "C20-create": "cell-before-one-Create"}[row[0]]
        status += f":deny-{suffix}"
    raw = obs["raw"]
    kind = raw[0] if raw is not None else fixtures.kind(row[3], {n: k for n, k, _ in initial["inputs"]})
    if obs["status"] == "finished":
        assert json.dumps(obs["plainAnswer"]) == json.dumps(obs["answer"]), f"plain/counted answer {row[0]}"
    assert obs["destroyTwiceEqual"], f"non-idempotent destruction {row[0]}"
    return {
        "status": status, "kind": kind, "answer": obs["answer"],
        "rawListRoot": names[raw[1]] if raw is not None and kind == "L" and raw[1] is not None else None,
        "cellEvents": events,
        "finalCells": [[names[a], n, names[t] if t is not None else None, c, state]
                       for a, n, t, c, state in obs["state"]["cells"]],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    rows = fixtures.all_cases()
    inputs = output / "inputs.json"
    raw = output / "raw.json"
    summary = output / "summary.json"
    inputs.write_text(json.dumps([input_row(row) for row in rows]))
    subprocess.run(["lake", "build"], cwd=HERE / "lean", check=True)
    subprocess.run(["lake", "env", "lean", "--run", "Export.lean", str(inputs), str(raw)],
                   cwd=HERE / "lean", check=True)
    observations = json.loads(raw.read_text())
    summary.write_text(json.dumps({r[0]: normalize(r, observations[r[0]]) for r in rows}, indent=2) + "\n")
    subprocess.run(["python3", str(HERE / "acceptance/check.py"), "--observations", str(summary)], check=True)


if __name__ == "__main__":
    main()
