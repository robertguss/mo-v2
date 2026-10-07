"""Candidate-dependent gates exercised only with records/reference fixtures.

No evaluator control or resource workload is run here. Each gate names the
candidate capability it requires; fake preparation records never constitute
real evidence for those gates.
"""
import json
from pathlib import Path
import sys
import traceback

from acquisitioncheck import predict
from boundedcheck import DEFS
from cases import fixture
from predicates import invocation_creates


# Retained control classes from v5, grouped by the capability needed to execute
# their intended path. Actual source patches await the candidate implementation.
CONTROLS = {
    "frontend": ["token-reader", "accept-all", "refuse-all", "wrong-scope", "whole-file-span", "frontend-list-preallocation", "fixed-i128"],
    "physical": ["shared-mutation", "shadow-reporter", "premature-free", "tail-leak", "always-copy", "hidden-entry-copy", "fixture-provenance", "caller-reservation-theft", "lost-live-holder", "wrong-reservation-order", "early-cleanup"],
    "calls": ["omitted-entry-create", "omitted-nested-create", "omitted-transient-create", "early-enter", "skipped-return-cleanup"],
    "resume": ["replay", "counter-reset", "call-boundary-only", "suspended-as-finished", "resource-as-suspended"],
    "destroy": ["physical-leak", "double-free", "outside-drop"],
}

PREDICATES = {
    "token-reader": "canonical parsed structure", "accept-all": "must-refuse", "refuse-all": "must-accept",
    "wrong-scope": "checked binding/call scope", "whole-file-span": "exact refusal span",
    "frontend-list-preallocation": "zero frontend managed cells", "fixed-i128": "exact growing answer",
    "shared-mutation": "continuous live values", "shadow-reporter": "reported/actual physical graph",
    "premature-free": "live lifetime readability", "tail-leak": "final reachability/destroy free set",
    "always-copy": "unique C10 zero creates", "hidden-entry-copy": "invocation entry creates",
    "fixture-provenance": "fixture/literal route consistency", "caller-reservation-theft": "C1 reservation origin",
    "lost-live-holder": "pending/binding counts", "wrong-reservation-order": "nested reservation identity/order",
    "early-cleanup": "C14 reservation lifetime", "omitted-entry-create": "entry creates",
    "omitted-nested-create": "C9 descendant creates", "omitted-transient-create": "C7 transient creates",
    "early-enter": "arguments before enter", "skipped-return-cleanup": "return cleanup state",
    "replay": "normalized predicted suffix", "counter-reset": "cumulative prefix",
    "call-boundary-only": "every transition cut", "suspended-as-finished": "terminal classification",
    "resource-as-suspended": "resource failure classification", "physical-leak": "destroy outside exact graph",
    "double-free": "destroy free set/duplicate", "outside-drop": "outside value/lifetime continuity",
}


def check_control(record, name, obligation):
    assert record["control"] == name and record["capability"] == obligation and record["obligation"] == PREDICATES[name], "control target"
    assert record["compiled"] is True and record["executed_intended_path"] is True, "control viability"
    assert record["baseline_passed"] is True and record["rejected_by"] == PREDICATES[name], "control decisive predicate"
    assert record["unrelated_failure"] is False, "control unrelated failure"


def check_resource(row):
    assert row["case"] in ("non-tail-sum", "discarded-list"), "resource case"
    assert all(type(row[k]) is int and row[k] >= 0 for k in ("depth", "available_bytes", "stack_bytes", "transitions", "remaining_owned_cells", "peak_explicit_frames")), "resource integer fields"
    assert all(type(n) is int for n in row["evaluation_cell_counts"]), "resource count kinds"
    assert row["status"] == "finished" and row["depth"] == 1000000, "resource completion/depth"
    assert row["answer"] == ("1000000" if row["case"] == "non-tail-sum" else "0"), "resource answer"
    assert row["available_bytes"] >= 4 * 1024 ** 3 and row["stack_bytes"] == 8 * 1024 ** 2, "resource provisioning"
    assert 0 <= row["elapsed_seconds"] <= 600 and row["transitions"] <= 100000000, "resource envelope"
    assert row["evaluation_cell_counts"] == [0, 0, 1000000], "resource physical counts"
    assert row["remaining_owned_cells"] == 0, "resource cleanup"
    if row["case"] == "non-tail-sum": assert row["peak_explicit_frames"] >= 1000000, "resource frame evidence"
    # A real run also needs separate source/path inspection. This numeric record
    # check cannot prove those paths iterative or avoid hidden host-stack use.


def run(destination):
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, controls_specified=sum(map(len, CONTROLS.values())),
                  record_controls=0, cross_routes=False, resource_executed=False, candidate_executed=False)
    try:
        for capability, names in CONTROLS.items():
            for name in names:
                valid = dict(control=name, capability=capability, obligation=PREDICATES[name], compiled=True, executed_intended_path=True,
                             baseline_passed=True, rejected_by=PREDICATES[name], unrelated_failure=False)
                check_control(valid, name, capability)
                for key, wrong in [("compiled", False), ("executed_intended_path", False),
                                   ("baseline_passed", False), ("rejected_by", "crash"), ("unrelated_failure", True)]:
                    bad = dict(valid); bad[key] = wrong
                    try: check_control(bad, name, capability)
                    except AssertionError: report["record_controls"] += 1
                    else: raise AssertionError("invalid control evidence accepted")
        row = dict(case="non-tail-sum", status="finished", depth=1000000, answer="1000000",
                   available_bytes=4 * 1024 ** 3, stack_bytes=8 * 1024 ** 2, elapsed_seconds=600,
                   transitions=100000000, evaluation_cell_counts=[0, 0, 1000000], remaining_owned_cells=0, peak_explicit_frames=1000001)
        check_resource(row)
        for key, bad_value in [("depth", 999999), ("answer", "999999"), ("elapsed_seconds", 601),
                               ("transitions", 100000001), ("stack_bytes", 16 * 1024 ** 2),
                               ("status", "failed"), ("remaining_owned_cells", 1), ("peak_explicit_frames", 1)]:
            bad = dict(row); bad[key] = bad_value
            try: check_resource(bad)
            except AssertionError: report["record_controls"] += 1
            else: raise AssertionError("wrong resource record accepted")
        row.update(case="discarded-list", answer="0", peak_explicit_frames=0); check_resource(row)
        cells, inputs, outside = fixture([3, -2, 8])
        a = dict(source="input xs: ListInt; " + DEFS["inc"] + "main = inc(xs)", cells=cells, inputs=inputs, outside=outside)
        b = dict(source=DEFS["inc"] + "main = inc([3, -2, 8])", cells=[], inputs=[], outside=[])
        for case, expected_counts in [(a, [0, 3, 0]), (b, [3, 3, 0])]:
            _, answer, reference, _, outcome = predict(case)
            assert answer == (4, -1, 9) and outcome["value"] == ["l", ["4", "-1", "9"]]
            assert [sum(e[0] == k for e in reference.events) for k in ("create", "write", "free")] == expected_counts
            assert len(invocation_creates(reference.events)) == 4
            assert all(n == 0 for _, _, n in invocation_creates(reference.events))
        report["cross_routes"] = True; report["passed"] = True
    except Exception: report["error"] = traceback.format_exc()
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2)); return report["passed"]


if __name__ == "__main__": sys.exit(not run(Path(sys.argv[1])))
