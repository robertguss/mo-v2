"""Validate proposed trace predictions; no candidate or real suspension executes."""
import json
from pathlib import Path
import sys
import traceback

from cases import examples
from predicates import protection
from syntax import check, parse
from transition_reference import TransitionReference, trace_projection


# Action order derived from v5's English operations BEFORE running the predictor.
WORKED = [
    ("main = 3", ["Start", "Leaf", "Finish"]),
    ("main = 1 + 2", ["Start", "Dispatch compound", "Leaf", "Operand capture", "Leaf", "Operand capture", "Primitive result", "Finish"]),
    ("main = let n = 3 in n - 2", ["Start", "Dispatch compound", "Leaf", "Bind", "Dispatch compound", "Leaf", "Operand capture", "Leaf", "Operand capture", "Primitive result", "Handoff", "Finish"]),
    ("main = if true then 1 else 2 end", ["Start", "Dispatch compound", "Leaf", "Choose branch", "Branch start", "Leaf", "Handoff", "Finish"]),
    ("def f(): Int = 7 end main = f()", ["Start", "Dispatch compound", "Enter", "Leaf", "Return", "Finish"]),
    ("def f(n: Int): Int = n + 1 end main = f(3)", ["Start", "Dispatch compound", "Leaf", "Operand capture", "Enter", "Dispatch compound", "Leaf", "Operand capture", "Leaf", "Operand capture", "Primitive result", "Return", "Finish"]),
]


def run(destination):
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, worked=0, public=0, transitions=0,
                  missing=["candidate control/operand-slot dumps", "real physical/resume/destroy execution",
                           "independently predicted protected acquisitions", "full-corpus fine-trace projection"])
    results = []
    try:
        for source, actions in WORKED:
            program = parse(source); check(program)
            reference = TransitionReference(program, [], [], [])
            outcome = reference.observe(program["main"])
            assert outcome["status"] == "finished"
            assert [t["transition"] for t in reference.trace] == actions, source
            trace_projection(reference)
            results.append(dict(source=source, expected_actions=actions, trace=reference.trace, events=reference.events))
            report["worked"] += 1
        # Give-up/free cascade is separate BEFORE Start, not hidden preparation.
        program = parse("input xs: ListInt; main = 3"); check(program)
        reference = TransitionReference(program, [[1, "7", 2, 1, "live"], [2, "9", None, 1, "live"]], [("xs", ["l", 1])], [])
        reference.observe(program["main"])
        assert [t["transition"] for t in reference.trace] == ["Give up holder", "Free cell", "Give up holder", "Free cell", "Start", "Leaf", "Finish"]
        assert reference.events == [["free", 1], ["free", 2]]
        trace_projection(reference); report["worked"] += 1
        results.append(dict(source=program["source"], trace=reference.trace, events=reference.events))
        for case in examples():
            program = parse(case["source"]); check(program)
            reference = TransitionReference(program, case["cells"], case["inputs"], case["outside"], landmark_limit=60 if case["value"] is None else 10000)
            outcome = reference.observe(program["main"])
            trace_projection(reference)
            protection([t["state"] for t in reference.trace], case["cells"], case["outside"])
            results.append(dict(name=case["name"], status=outcome["status"], trace=reference.trace, events=reference.events))
            report["public"] += 1; report["transitions"] += len(reference.trace)
        report["passed"] = True
    except Exception:
        report["error"] = traceback.format_exc()
    (destination / "observed.json").write_text(json.dumps(results, indent=2) + "\n")
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return report["passed"]


if __name__ == "__main__": sys.exit(not run(Path(sys.argv[1])))
