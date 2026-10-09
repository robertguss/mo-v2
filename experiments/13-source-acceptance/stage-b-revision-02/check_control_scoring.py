"""Reproduce the two disputed public controls; judge the first failed row.

No crash alone counts. No historical report is rewritten. Only a passing
baseline, executed patch marker, and verified intended predicate qualify.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(1, str(HERE.parent))

from cases import examples
from closeoutcheck import PREDICATES, check_control
from integration import Verifier, load
import stage_b_authorized_runs as original


def first_rejection(case, directory):
    verifier = Verifier(case, [original.step_count(case)], stage="B")
    for line in (directory / "rows.jsonl").read_text().splitlines():
        row = json.loads(line)
        previous = verifier.last_snapshot
        try:
            verifier.row(row)
        except AssertionError as error:
            return verifier, previous, row, str(error)
    raise AssertionError("no checker rejection in recorded stream")


def judge(name, case, directory, result):
    assert result["baseline_passed"] and len(result["mutant"]) == 1
    mutant = result["mutant"][0]
    assert mutant["marker"] and mutant["passed"] is False, "control execution evidence"
    verifier, previous, row, error = first_rejection(case, directory)
    assert row["phase"] == "commit", "not an intended committed-action rejection"
    meta = load(row["raw"]["metadata"])
    snapshot = load(row["raw"]["snapshot"])
    if name == "early-enter":
        assert error == "commit metadata"
        assert verifier.expected()["transition"] == "Leaf" and meta["transition"] == "Enter"
        assert verifier.expected()["site"] == meta["site"] + "/0", "not the pending first argument"
        assert len(meta["events_added"]) == 1 and meta["events_added"][0][0] == "enter"
    else:
        assert name == "caller-reservation-theft" and error == "birth coverage"
        want = verifier.expected()
        assert meta["transition"] == want["transition"] == "Primitive result"
        assert meta["site"] == want["site"] and meta["event_end"] == want["event_end"]
        reserved = {cell for _, cell in previous["state"]["aside"]}
        writes = [cell for kind, cell, _, phase in row["events"] if kind == "write" and phase == "execution"]
        assert len(writes) == 1 and writes[0] in reserved, "no physical caller-reservation write"
        expected_added = verifier.ref.extended[previous["event_end"]:meta["event_end"]]
        assert len(expected_added) == 1 and expected_added[0][0] == "create"
        assert len(snapshot["births"]) + 1 == len(verifier.ref.birth_steps[verifier.step - 1])
        assert len(snapshot["state"]["aside"]) + 1 == len(previous["state"]["aside"])
    capability = "calls" if name == "early-enter" else "physical"
    record = dict(control=name, capability=capability, obligation=PREDICATES[name], compiled=True,
                  executed_intended_path=True, baseline_passed=True, rejected_by=PREDICATES[name],
                  unrelated_failure=False)
    check_control(record, name, capability)
    return dict(record, first_failed_step=row["step"], first_rejection=error,
                later_panic_recorded=mutant["panic"], caught=True)


def run(destination):
    destination.mkdir(parents=True, exist_ok=False)
    work = destination / "source"
    work.mkdir()
    for name in ("candidate-stage-b", "stage-b-link"):
        shutil.copytree(HERE / name, work / name)
    for name in ("runtime", "driver", "cells"):
        (work / name).symlink_to(HERE / name, target_is_directory=True)
    # Reuse the exact existing public sabotage patches in a new directory.
    original.HERE = work
    _, link = original.prepare_control_copy()
    target = destination / "target"
    with (destination / "build.log").open("w") as log:
        subprocess.run(["cargo", "+1.98.1", "build", "--locked", "--manifest-path", str(link / "Cargo.toml")],
                       env=dict(os.environ, CARGO_TARGET_DIR=str(target)), stdout=log,
                       stderr=subprocess.STDOUT, check=True)
    binary = target / "debug/rob1333-stage-b-link"
    by_name = {case["name"]: case for case in examples()}
    records = []
    for name, public_case in (("caller-reservation-theft", "C1"), ("early-enter", "C11-0")):
        case = by_name[public_case]
        (destination / (name + "-request.json")).write_text(json.dumps(
            dict(source=list(case["source"].encode()), cells=case["cells"], inputs=case["inputs"],
                 outside=case["outside"], budgets=[original.step_count(case)], large=False, deny=None)) + "\n")
        result = original.one_control([str(binary)], name, [case], destination / "runs")
        (destination / (name + "-original-scorer.json")).write_text(json.dumps(result, indent=2) + "\n")
        records.append(judge(name, case, destination / "runs" / name / "mutant" / public_case, result))
    report = dict(passed=True, baselines_passed=2, intended_rejections=2, records=records,
                  raw_failures_replayed=True, original_results_modified=False,
                  private_cases_executed=0, million_element_runs=0)
    (destination / "scoring.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    run(Path(sys.argv[1]).resolve())
