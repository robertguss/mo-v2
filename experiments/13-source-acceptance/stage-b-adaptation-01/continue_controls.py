"""Run the existing public control patches and deferred refusals on adaptation 01.

All source changes are confined to a disposable, retained control copy. The
frozen candidate, verifier, control predicates and expectations are untouched.
Usage: python3 continue_controls.py NEW_PUBLIC_DIRECTORY VERIFIED_BINARY
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
BASE = HERE.parent
REVISION = BASE / "stage-b-revision-02"
sys.path[:0] = [str(REVISION), str(BASE)]
import stage_b_authorized_runs as original
from boundedcheck import DEFS
from cases import examples, fixture
from check_control_scoring import first_rejection, judge
from linked import run_linked
from stage_b_controls import rerun_deferred_expectations
from validate_public import frozen


def main(destination, candidate_binary):
    destination.mkdir(parents=True, exist_ok=False)
    started = time.monotonic()
    before = frozen()
    work = destination / "source"
    work.mkdir()
    shutil.copytree(HERE / "candidate", work / "candidate-stage-b")
    shutil.copytree(BASE / "stage-b-link", work / "stage-b-link")
    for name in ("runtime", "driver", "cells"):
        (work / name).symlink_to(REVISION / name, target_is_directory=True)
    # Only the disposable copy's linkage changes: Cargo must resolve the same
    # frozen runtime through one path for both the candidate and the driver.
    manifest = work / "candidate-stage-b" / "Cargo.toml"
    manifest.write_text(original.patch(manifest.read_text(),
        'path = "../../stage-b-revision-02/runtime"', 'path = "../runtime"',
        "control-copy runtime linkage"))
    original.HERE = work
    _, link = original.prepare_control_copy()
    target = destination / "target"
    command = ["cargo", "+1.98.1", "build", "--locked", "--offline", "--manifest-path", str(link / "Cargo.toml")]
    (destination / "build-command.json").write_text(json.dumps(command) + "\n")
    with (destination / "build.log").open("w") as log:
        subprocess.run(command, env=dict(os.environ, CARGO_TARGET_DIR=str(target)),
                       stdout=log, stderr=subprocess.STDOUT, check=True)
    binary = target / "debug/rob1333-stage-b-link"
    by_name = {case["name"]: case for case in examples()}
    cells, inputs, outside = fixture([3, -2, 8])
    routes = [
        dict(name="fixture-route", source="input xs: ListInt; " + DEFS["inc"] + "main = inc(xs)",
             cells=cells, inputs=inputs, outside=outside, value=[4, -1, 9]),
        dict(name="literal-route", source=DEFS["inc"] + "main = inc([3, -2, 8])",
             cells=[], inputs=[], outside=[], value=[4, -1, 9]),
    ]
    plan = [
        ("always-copy", [by_name["C10-unique"]]),
        ("hidden-entry-copy", [by_name["C8"]]),
        ("fixture-provenance", routes),
        ("caller-reservation-theft", [by_name["C1"]]),
        ("early-cleanup", [by_name["C14"]]),
        ("omitted-nested-create", [by_name["C9"]]),
        ("omitted-transient-create", [by_name["C7"]]),
        ("early-enter", [by_name["C11-0"]]),
        ("skipped-return-cleanup", [by_name["C7"]]),
    ]
    results = []
    for name, cases in plan:
        (destination / (name + "-requests.json")).write_text(json.dumps([
            dict(case=case, budgets=[original.step_count(case)], command=[str(binary)],
                 mutant_environment={"ROB_ACCEPT_MUTANT": name}) for case in cases]) + "\n")
        result = original.one_control([str(binary)], name, cases, destination / "runs")
        result["first_rejections"] = []
        for case in cases:
            directory = destination / "runs" / name / "mutant" / case["name"]
            verifier, previous, row, error = first_rejection(case, directory)
            evidence = dict(error=error, previous_snapshot=previous, row=row,
                            expected=verifier.expected())
            (directory / "first-rejection.json").write_text(json.dumps(evidence, indent=2) + "\n")
            result["first_rejections"].append(dict(step=row["step"], error=error))
        if name in ("caller-reservation-theft", "early-enter"):
            result["reviewed_predicate"] = judge(name, cases[0],
                destination / "runs" / name / "mutant" / cases[0]["name"], result)
        results.append(result)
        (destination / "controls-runs.json").write_text(json.dumps(results, indent=2) + "\n")
        assert result["baseline_passed"], "control baseline failed"
        assert all(m["marker"] and not m["passed"] for m in result["mutant"]), "control not reached/rejected"
        print(name, "baseline passed; intended patch reached; rejection retained", flush=True)
    refusals = rerun_deferred_expectations()
    for index, expected in enumerate(refusals):
        case = dict(source=expected["source"], cells=[], inputs=[], outside=[])
        (destination / f"refusal-{index:02d}-request.json").write_text(json.dumps(case) + "\n")
        run_linked([str(candidate_binary)], case, [0], destination / f"refusal-{index:02d}", stage="B")
    report = dict(control_classes_run=len(results), baseline_runs=10, mutant_runs=10,
                  deferred_refusals_passed=len(refusals), source_review_pending=True,
                  control_binary_sha256=hashlib.sha256(binary.read_bytes()).hexdigest(),
                  candidate_binary_sha256=hashlib.sha256(candidate_binary.read_bytes()).hexdigest(),
                  preservation_before=before, preservation_after=frozen(),
                  elapsed_seconds=time.monotonic() - started)
    (destination / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main(Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve())
