"""Independently derived binding values; no candidate dump supplies expectations."""
from copy import deepcopy
import json
from pathlib import Path
import sys
import traceback

from call_reference import immutable_answer
from cases import DEFINITIONS, examples, fixture
from generated import generate
from predicates import protection, walk
from syntax import check, parse
from transition_reference import TransitionReference, trace_projection


# Each list orders acquisitions: inputs, let, match head/tail, call parameters.
WORKED = [
    ("main = let xs = [2] in let xs = [7] in xs", [], [(2,), (7,)], (7,)),
    ("main = match [4, -1] do [] -> []; [h | t] -> [h + 2 | t] end", [], [4, (-1,)], (6, -1)),
    ("def pair(a: ListInt, b: ListInt): ListInt = a end main = pair((let n = 3 in [n]), (let n = 7 in [n]))",
     [], [3, 7, (3,), (7,)], (3,)),
    ("input xs: ListInt; " + DEFINITIONS + "main = let saved = xs in let changed = bump(xs) in first(saved) + first(changed)",
     [4, -1], [(4, -1), (4, -1), (4, -1), 4, (-1,), (-1,), -1, (), (), (5, 0), (4, -1), 4, (-1,), (5, 0), 5, (0,)], 9),
]


def predict(case):
    program = parse(case["source"]); check(program)
    values = {n: tuple(walk(case["cells"], v[1])[0]) if v[0] == "l" else int(v[1])
              for n, v in case["inputs"]}
    acquired = {}
    answer = immutable_answer(program, values, acquisitions=acquired)
    expected = {i: list(v) for i, v in acquired.items() if type(v) is tuple}
    reference = TransitionReference(program, case["cells"], case["inputs"], case["outside"], landmark_limit=20000)
    result = reference.observe(program["main"])
    assert result["status"] == "finished"
    assert set(acquired) == set(range(len(reference.bindings))), "binding identity/order"
    trace_projection(reference)
    protection([t["state"] for t in reference.trace], case["cells"], case["outside"], expected)
    return acquired, answer, reference, expected, result["outcome"]


def run(destination):
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, worked=0, public=0, generated=0, controls=0,
                  missing=["independent pending-value predictions", "nonterminating acquisition prefixes", "physical candidate execution"])
    case = None
    try:
        for source, items, expected, answer in WORKED:
            cells, inputs, outside = fixture(items) if "input xs:" in source else ([], [], [])
            case = dict(source=source, cells=cells, inputs=inputs, outside=outside)
            acquired, actual, reference, bindings, outcome = predict(case)
            assert acquired == dict(enumerate(expected)), "hand-derived acquisitions"
            assert type(actual) is type(answer) and actual == answer, "hand-derived answer"
            report["worked"] += 1
            state = next((t["state"] for t in reference.trace if any(b[3] == "holding" for b in t["state"]["bindings"])), None)
            if state is not None:
                broken = deepcopy(state)
                root = next(b[2][1] for b in broken["bindings"] if b[3] == "holding")
                next(c for c in broken["memory"] if c[0] == root)[1] = "999"
                try: protection([broken], cells, outside, bindings)
                except AssertionError as error: assert str(error) == "live binding mutation"
                else: raise AssertionError("corrupt first acquisition accepted")
                report["controls"] += 1
        for case in examples():
            if case["value"] is None: continue
            predict(case); report["public"] += 1
        for case in generate(1333, 500):
            predict(case); report["generated"] += 1
        report["passed"] = True
    except Exception:
        report["error"] = traceback.format_exc()
        (destination / "counterexample.json").write_text(json.dumps(case, indent=2) + "\n")
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return report["passed"]


if __name__ == "__main__": sys.exit(not run(Path(sys.argv[1])))
