"""Exploratory bounded call compositions, not a frozen or held-out corpus.

No candidate output is used to generate or discard cases. Stop on first failure.
Exact future holdout seeds/cases must be isolated from the implementation context.
"""
import json
from pathlib import Path
import random
import sys
import traceback

from call_reference import CallReference, immutable_answer
from cases import DEFINITIONS, fixture
from predicates import final_memory, invocation_creates, protection, walk
from syntax import check, parse


def generate(seed, count):
    rng = random.Random(seed)
    def scalar(depth):
        if depth == 0: return str(rng.choice([-7, -2, 0, 3, 11]))
        k = rng.randrange(5)
        if k == 0: return f"first({listed(depth - 1)})"
        if k == 1: return f"sum({listed(depth - 1)})"
        if k == 2: return f"({scalar(depth - 1)} - {scalar(depth - 1)})"
        if k == 3: return f"(if {scalar(depth - 1)} < 3 then {scalar(depth - 1)} else {scalar(depth - 1)} end)"
        return f"(let n = {scalar(depth - 1)} in n + 3)"
    def listed(depth):
        if depth == 0: return rng.choice(["xs", "[]", "[3, -2]"])
        k = rng.randrange(6)
        if k == 0: return f"one({scalar(depth - 1)})"
        if k == 1: return f"bump({listed(depth - 1)})"
        if k == 2: return f"choose({listed(depth - 1)}, {listed(depth - 1)})"
        if k == 3: return f"[{scalar(depth - 1)} | {listed(depth - 1)}]"
        if k == 4: return f"(let xs = {listed(depth - 1)} in identity(xs))"
        return f"identity({listed(depth - 1)})"
    for index in range(count):
        items = [rng.choice([-7, -2, 0, 3, 11]) for _ in range(rng.randrange(5))]
        cells, inputs, outside = fixture(items, outside=bool(rng.randrange(2)))
        main = f"identity({listed(3)})" if index % 2 else f"first({listed(3)}) + {scalar(2)}"
        yield dict(index=index, source="input xs: ListInt;\n" + DEFINITIONS + "main = " + main,
                   cells=cells, inputs=inputs, outside=outside)


def validate(destination, count=500):
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, kind="exploratory-reference-validation-not-heldout", cases=0,
                  seed=1333, requested=count, snapshots=0, missing=["fine-grained transitions",
                  "independent pending-value acquisition predictions", "candidate physical/resume/destroy checks"])
    case = None
    try:
        for case in generate(1333, count):
            program = parse(case["source"]); check(program)
            values = {n: tuple(walk(case["cells"], v[1])[0]) for n, v in case["inputs"]}
            expected = immutable_answer(program, values)
            reference = CallReference(program, case["cells"], case["inputs"], case["outside"], landmark_limit=20000)
            result = reference.observe(program["main"])
            assert result["status"] == "finished", "bounded finite reference did not finish"
            outcome = result["outcome"]
            actual = (tuple(map(int, outcome["value"][1])) if outcome["value"][0] == "l"
                      else int(outcome["value"][1]))
            assert type(actual) is type(expected) and actual == expected, "answer mismatch"
            protection(outcome["states"], case["cells"], case["outside"])
            final_memory(outcome, case["outside"])
            invocation_creates(result["events"])
            report["cases"] += 1
            report["snapshots"] += len(outcome["states"])
        report["passed"] = True
    except Exception:
        report["error"] = traceback.format_exc()
        (destination / "counterexample.json").write_text(json.dumps(case, indent=2) + "\n")
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return report["passed"]


if __name__ == "__main__": sys.exit(not validate(Path(sys.argv[1])))
