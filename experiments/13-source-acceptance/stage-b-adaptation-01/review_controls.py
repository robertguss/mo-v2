"""Replay retained public control failures; do not execute candidates.

This records why the existing frozen predicates rejected the compiled faults.
It does not change their verdicts or the original run/scorer reports.
Usage: python3 review_controls.py CONTROL_RUN_DIRECTORY NEW_REPORT_PATH
"""
import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path[:0] = [str(HERE.parent / "stage-b-revision-02"), str(HERE.parent)]
from check_control_scoring import first_rejection, judge
from closeoutcheck import PREDICATES, check_control
from integration import load


def main(directory, output):
    results = json.loads((directory / "controls-runs.json").read_text())
    reviews = []
    for result in results:
        name = result["control"]
        assert result["baseline_passed"]
        cases = json.loads((directory / (name + "-requests.json")).read_text())
        for request, mutant in zip(cases, result["mutant"], strict=True):
            case = request["case"]
            path = directory / "runs" / name / "mutant" / case["name"]
            assert mutant["marker"] and not mutant["passed"]
            verifier, previous, row, error = first_rejection(case, path)
            assert row["phase"] == "commit"
            meta = load(row["raw"]["metadata"])
            snapshot = load(row["raw"]["snapshot"])
            expected = verifier.expected()
            native = [(kind, ident) for kind, ident, _, phase in row["events"] if phase == "execution"]
            if name in ("caller-reservation-theft", "early-enter"):
                reviews.append(judge(name, case, path, result))
                continue
            if name == "always-copy":
                assert error == "full committed execution/physical state"
                assert meta["transition"] == expected["transition"] == "Match decompose"
                assert len(expected["state"]["aside"]) == 1 and snapshot["state"]["aside"] == []
                # The exact unique-decomposition rule rejects the copy policy
                # before construction. This is not an observed later allocation.
                witness = "unique input follows shared decomposition instead of reserving its cell"
            elif name == "fixture-provenance":
                assert error == "birth coverage" and [kind for kind, _ in native] == ["create"]
                assert meta["transition"] == expected["transition"] == "Primitive result"
                assert snapshot["state"]["aside"] == previous["state"]["aside"]
                assert len(expected["state"]["aside"]) + 1 == len(snapshot["state"]["aside"])
                witness = "physical creation instead of consuming the available reservation"
            elif name == "hidden-entry-copy":
                assert error == "commit metadata" and meta["transition"] == expected["transition"] == "Enter"
                assert [kind for kind, _ in native] == ["create"]
                assert meta["event_end"] == expected["event_end"] + 1
                witness = "physical extra creation during invocation entry"
            elif name == "early-cleanup":
                assert error == "commit metadata" and meta["transition"] == expected["transition"] == "Branch start"
                assert [kind for kind, _ in native] == ["free"]
                assert native[0][1] in {ident for _, ident in previous["state"]["aside"]}
                assert meta["event_end"] == expected["event_end"] + 1
                witness = "reserved cell physically freed at branch start"
            elif name in ("omitted-nested-create", "omitted-transient-create"):
                assert error == "commit metadata" and meta["transition"] == expected["transition"] == "Primitive result"
                assert [kind for kind, _ in native] == ["create"]
                assert meta["events_added"] == [] and meta["event_end"] + 1 == expected["event_end"]
                assert len(snapshot["state"]["frames"]) >= 1
                witness = "physical creation inside a call missing from the logical creation stream"
            else:
                assert name == "skipped-return-cleanup" and error == "commit metadata"
                assert expected["transition"] == "Give up holder" and meta["transition"] == "Leaf"
                assert native == [] and any(cell[3] > 0 for cell in row["graph"])
                witness = "execution continues while the required holder-release action is skipped"
            capability = "calls" if name.startswith("omitted-") or name == "skipped-return-cleanup" else "physical"
            record = dict(control=name, capability=capability, obligation=PREDICATES[name], compiled=True,
                          executed_intended_path=True, baseline_passed=True, rejected_by=PREDICATES[name],
                          unrelated_failure=False)
            check_control(record, name, capability)
            reviews.append(dict(record, first_failed_step=row["step"], first_rejection=error,
                                later_panic_recorded=mutant["panic"], witness=witness, caught=True))
    assert len(results) == 9 and len(reviews) == 10
    report = dict(passed=True, classes=9, baseline_runs=10, intended_rejections=10,
                  first_failures_replayed=True, historical_reports_modified=False,
                  records=reviews)
    with output.open("x") as stream:
        json.dump(report, stream, indent=2)
        stream.write("\n")
    print("9 active control classes; 10 passing baselines; 10 intended first rejections")


if __name__ == "__main__":
    main(Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve())
