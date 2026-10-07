"""Offline predicates for acceptance-observed normalized candidate evidence.

This does NOT obtain physical observations. A trusted native cell/graph adapter
must produce them; candidate-authored pointer JSON alone is insufficient.
"""
from copy import deepcopy
import json
from pathlib import Path
import sys
import traceback

from acquisitioncheck import predict
from predicates import final_memory, invocation_creates, physical_events, protection, walk


def compare_trace(actual, expected):
    assert len(actual) == len(expected), "transition count"
    for observed, predicted in zip(actual, expected):
        # Pending expectations come from the acceptance predictor, never from
        # the candidate's first acquisition. Check values before structural equality.
        values = [walk(predicted["state"]["memory"], v[1])[0] for v in predicted["state"]["pending"]]
        actual_values = [walk(observed["state"]["memory"], v[1])[0] for v in observed["state"]["pending"]]
        assert actual_values == values, "pending value mutation"
        # JSON's Bool/Int kinds are distinct; Python False == 0 must not let a
        # numeric flag or Boolean step pass an otherwise equal typed trace.
        assert json.dumps(observed, sort_keys=True) == json.dumps(predicted, sort_keys=True), "committed state/action/event prefix"


def check_bundle(case, bundle, required_boundaries=()):
    acquired, answer, reference, bindings, outcome = predict(case)
    compare_trace(bundle["trace"], reference.trace)
    assert bundle["events"] == reference.events, "ordered events/call identities"
    protection([t["state"] for t in bundle["trace"]], case["cells"], case["outside"], bindings)
    final_memory(bundle["outcome"], case["outside"])
    assert json.dumps(bundle["outcome"], sort_keys=True) == json.dumps(outcome, sort_keys=True), "final outcome"
    invocation_creates(bundle["events"])
    primitive = [e for e in bundle["events"] if e[0] in ("create", "write", "free")]
    physical_events(case["cells"], bundle["physical"], primitive, outcome["memory"])
    # Resume segments report native pointer maps immediately before/after resume,
    # not pointer maps taken after the resumed work has retired objects.
    for resume in bundle["resumes"]:
        assert resume["before_live"] == resume["after_resume_live"], "resume replaced live identity"
        assert resume["prefix_before"] == resume["prefix_after"], "resume performed hidden work"
        k = resume["boundary"]
        assert type(k) is int and 0 <= k <= len(reference.trace), "resume boundary range"
        prefix = reference.events[:reference.trace[k - 1]["event_end"]] if k else []
        assert resume["prefix_before"] == prefix, "resume wrong boundary"
        memory = reference.trace[k - 1]["state"]["memory"] if k else case["cells"]
        primitive_prefix = [e for e in prefix if e[0] in ("create", "write", "free")]
        physical_prefix = bundle["physical"][:len(case["cells"]) + len(primitive_prefix)]
        live = physical_events(case["cells"], physical_prefix, primitive_prefix, memory)
        assert resume["before_live"] == {str(i): p for i, p in live.items()}, "resume physical map"
    assert sorted(r["boundary"] for r in bundle["resumes"]) == sorted(required_boundaries), "resume coverage"


def run(destination):
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, valid=0, controls={})
    try:
        case = dict(source="def choose(a: ListInt, b: ListInt): ListInt = a end main = choose([3], [7])",
                    cells=[], inputs=[], outside=[])
        acquired, answer, reference, bindings, outcome = predict(case)
        pointers = {}; physical = []
        for event in reference.events:
            if event[0] == "create": pointers[event[1]] = 4096 + event[1] * 64
            if event[0] in ("create", "write", "free"):
                physical.append([*event, pointers[event[1]]])
        # Observations arrive as JSON, not the reference's owner-linked Records
        # subclass (whose deepcopy appends records back into its copied owner).
        bundle = json.loads(json.dumps(dict(trace=reference.trace, events=reference.events,
                                            outcome=outcome, physical=physical, resumes=[])))
        check_bundle(case, bundle); report["valid"] += 1
        for name in ("pending", "action", "physical", "resume"):
            broken = deepcopy(bundle)
            if name == "pending":
                state = next(t["state"] for t in broken["trace"] if t["state"]["pending"])
                root = state["pending"][0][1]
                next(c for c in state["memory"] if c[0] == root)[1] = "999"
            elif name == "action": broken["trace"][1]["transition"] = "Finish"
            elif name == "physical": broken["physical"][-1][2] += 8
            else: broken["resumes"] = [dict(boundary=0, before_live={"1": 4096}, after_resume_live={"1": 8192}, prefix_before=[], prefix_after=[])]
            try: check_bundle(case, broken)
            except AssertionError as error: report["controls"][name] = str(error)
            else: raise AssertionError("broken observation accepted: " + name)
        assert report["controls"] == dict(pending="pending value mutation", action="committed state/action/event prefix",
                                         physical="physical continuity", resume="resume replaced live identity")
        # Independently require an actual cut; empty evidence cannot pass it.
        try: check_bundle(case, bundle, required_boundaries=[0])
        except AssertionError as error: assert str(error) == "resume coverage"
        else: raise AssertionError("missing resume accepted")
        report["controls"]["omitted-resume"] = "resume coverage"
        resumed = deepcopy(bundle)
        resumed["resumes"] = [dict(boundary=0, before_live={}, after_resume_live={}, prefix_before=[], prefix_after=[])]
        check_bundle(case, resumed, required_boundaries=[0]); report["valid"] += 1
        report["passed"] = True
    except Exception: report["error"] = traceback.format_exc()
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2)); return report["passed"]


if __name__ == "__main__": sys.exit(not run(Path(sys.argv[1])))
