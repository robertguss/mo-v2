"""Hand-derived ready/operand/cleanup schedules and bounded prefix acquisitions."""
import json
from pathlib import Path
import sys
import traceback

from call_reference import immutable_answer, ObservationEnd
from cases import examples
from predicates import protection, walk
from syntax import check, parse
from transition_reference import TransitionReference


def run(destination):
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, worked=0, prefixes=0)
    try:
        program = parse("main = 9 - (4 - 2)"); check(program)
        reference = TransitionReference(program, [], [], [])
        reference.observe(program["main"])
        primitives = [t for t in reference.trace if t["transition"] == "Primitive result"]
        assert [t["ready"] for t in primitives] == [["n", "2"], ["n", "7"]]
        inner_leaf = next(t for t in reference.trace if t["site"] == "main/1/1" and t["transition"] == "Leaf")
        assert inner_leaf["control"][0]["operands"] == [["n", "9"]]
        assert inner_leaf["control"][1]["operands"] == [["n", "4"]]
        assert reference.trace[-1]["ready"] == ["n", "7"]
        report["worked"] += 1
        program = parse("def f(n: Int): Int = n + 1 end main = f(3)"); check(program)
        reference = TransitionReference(program, [], [], [])
        reference.observe(program["main"])
        leaf = next(t for t in reference.trace if t["site"] == "function/0/body/0" and t["transition"] == "Leaf")
        assert leaf["control"][-1]["scope"] == [["n", 0]]
        assert leaf["control"][-1]["invocation"] == 1 and leaf["ready"] == ["n", "3"]
        assert next(t for t in reference.trace if t["transition"] == "Return")["ready"] == ["n", "4"]
        report["worked"] += 1
        program = parse("input xs: ListInt; main = 3"); check(program)
        reference = TransitionReference(program, [[1, "7", 2, 1, "live"], [2, "9", None, 1, "live"]], [("xs", ["l", 1])], [])
        reference.observe(program["main"])
        assert [t["release"] for t in reference.trace[:4]] == [[1], [1], [1, 2], [1, 2]]
        report["worked"] += 1
        for case in examples():
            if case["value"] is not None: continue
            program = parse(case["source"]); check(program)
            values = {n: tuple(walk(case["cells"], v[1])[0]) for n, v in case["inputs"]}
            acquired = {}
            try: immutable_answer(program, values, limit=200, acquisitions=acquired)
            except ObservationEnd: pass
            else: raise AssertionError("prefix example unexpectedly terminates")
            reference = TransitionReference(program, case["cells"], case["inputs"], case["outside"], landmark_limit=60)
            assert reference.observe(program["main"])["status"] == "reference-prefix"
            protection([t["state"] for t in reference.trace], case["cells"], case["outside"],
                       {i: list(v) for i, v in acquired.items() if type(v) is tuple})
            for state in reference.states:
                for ident, name, value, status in state["bindings"]:
                    assert ident in acquired
                    if value[0] == "n": assert int(value[1]) == acquired[ident] and type(acquired[ident]) is int
            report["prefixes"] += 1
        report["passed"] = True
    except Exception: report["error"] = traceback.format_exc()
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2)); return report["passed"]


if __name__ == "__main__": sys.exit(not run(Path(sys.argv[1])))
