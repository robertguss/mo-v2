"""Private 24 balanced + 500 bounded draft cases; no candidate or new targets.

Earlier private versions remain intact. Only public aggregate evidence is emitted.
Depth counts expanded expression nodes, separately for main and each body.
"""
import gzip
import hashlib
import json
from pathlib import Path
import random
import secrets
import sys
import traceback

from acquisitioncheck import predict
from cases import fixture
from fixturecheck import validate_fixture
from predicates import final_memory, invocation_creates
from syntax import check, parse
from transition_reference import children


DEFS = {
    "id": "def id(a: ListInt): ListInt = a end\n",
    "inc": "def inc(a: ListInt): ListInt = match a do [] -> []; [h | t] -> [h + 1 | inc(t)] end end\n",
    "pick": "def pick(a: ListInt, b: ListInt): ListInt = a end\n",
    "first": "def first(a: ListInt): Int = match a do [] -> 0; [h | t] -> h end end\n",
    "one": "def one(n: Int): ListInt = [n | []] end\n",
    "even": "def even(n: Int): Bool = if n <= 0 then true else odd(n - 1) end end\n",
    "odd": "def odd(n: Int): Bool = if n <= 0 then false else even(n - 1) end end\n",
}


def depth(e):
    return 1 + max([depth(c) for c in children(e)] + [0])


def shape(program):
    check(program)
    expressions = [program["main"]] + [f[3] for f in program["functions"]]
    def calls(e):
        return ([len(e[2])] if e[0] == "call" else []) + [a for c in children(e) for a in calls(c)]
    arities = [a for e in expressions for a in calls(e)]
    return dict(depth=max(map(depth, expressions)), functions=len(program["functions"]),
                arity=max(arities + [0]))


def check_bounds(program):
    measured = shape(program)
    assert measured["depth"] <= 5, "generated depth"
    assert measured["functions"] <= 3, "generated functions"
    assert measured["arity"] <= 4, "generated arity"
    return measured


def make(main, names, items, retained=False, tail=False):
    cells, inputs, outside = fixture(items, retained, tail)
    declarations = "input xs: ListInt;\n" + ("input ys: ListInt;\n" if tail else "")
    return dict(source=declarations + "".join(DEFS[n] for n in names) + "main = " + main,
                cells=cells, inputs=inputs, outside=outside)


def balanced(rng):
    for variant in range(3):
        a, b = rng.choice([-11, -4, 3, 8]), rng.choice([-7, -2, 5, 13])
        items = [a, b]
        # Independent expectations: identity preserves values; inc adds one;
        # pick returns its first argument; first returns the head; one creates
        # a singleton; parity alternates after decrementing to the base case.
        rows = [
            ("nested", make("id(id(xs))", ["id"], items), tuple(items)),
            ("arguments", make("pick(xs, inc(xs))", ["pick", "inc"], items), tuple(items)),
            ("shadow", make("let xs = xs in id(xs)", ["id"], items), tuple(items)),
            ("shared-head", make("inc(xs)", ["inc"], items, retained=True), (a + 1, b + 1)),
            ("shared-tail", make("let z = inc(xs) in first(ys) + first(z)", ["inc", "first"], items, tail=True), b + a + 1),
            ("returned-temporary", make("first(id(xs))", ["first", "id"], items), a),
            ("reservation", make("match xs do [] -> []; [h | t] -> [h | one(h)] end", ["one"], items), (a, a)),
            ("mutual", make(f"even({[0, 1, 7][variant]})", ["even", "odd"], []), [True, False, False][variant]),
        ]
        for family, case, expected in rows:
            case.update(family=family, variant=variant)
            yield case, expected


def generated(rng):
    def listed(d):
        if d == 1: return rng.choice(["xs", "[]"])
        operation = rng.randrange(4)
        if operation == 0: return f"id({listed(d - 1)})"
        if operation == 1: return f"inc({listed(d - 1)})"
        if operation == 2: return f"pick({listed(d - 1)}, {listed(d - 1)})"
        return f"[{rng.choice([-11, -4, 0, 3, 8])} | {listed(d - 1)}]"
    for index in range(500):
        if index % 5 == 0:
            # A terminating mutual-recursion family, no fabricated divergence answer.
            case = make(f"even({rng.randrange(8)})", ["even", "odd"], [])
        else:
            items = [rng.choice([-11, -4, 0, 3, 8]) for _ in range(rng.randrange(5))]
            case = make(f"id({listed(4)})", ["id", "inc", "pick"], items, retained=bool(rng.randrange(2)))
        case["index"] = index
        yield case


def run(private, destination):
    private.mkdir(parents=True, exist_ok=False)
    destination.mkdir(parents=True, exist_ok=False)
    seed = secrets.randbits(128)
    (private / "seed.json").write_text(json.dumps(dict(seed=str(seed))) + "\n")
    report = dict(passed=False, heldouts=0, generated=0, families={}, max_depth=0,
                  max_functions=0, max_arity=0, candidate_executed=False, frozen=False)
    try:
        rng = random.Random(seed)
        with gzip.open(private / "cases.jsonl.gz", "wt") as output:
            for category, rows in [("heldouts", balanced(rng)), ("generated", ((c, None) for c in generated(rng)))]:
                for case, hand in rows:
                    program = parse(case["source"])
                    measured = check_bounds(program)
                    assert len(case["cells"]) <= 4
                    validate_fixture(program, case["cells"], case["inputs"], case["outside"])
                    _, answer, reference, bindings, outcome = predict(case)
                    assert any(e[0] == "enter" for e in reference.events), "no executed call"
                    if category == "heldouts":
                        assert type(answer) is type(hand) and answer == hand, "independent hand answer"
                        report["families"][case["family"]] = report["families"].get(case["family"], 0) + 1
                    final_memory(outcome, case["outside"]); invocation_creates(reference.events)
                    for k in ("depth", "functions", "arity"): report["max_" + k] = max(report["max_" + k], measured[k])
                    case["expected"] = dict(answer=answer, bindings=bindings, trace=reference.trace, events=reference.events, outcome=outcome)
                    output.write(json.dumps(case) + "\n"); report[category] += 1
        assert report["heldouts"] == 24 and report["generated"] == 500
        assert len(report["families"]) == 8 and set(report["families"].values()) == {3}
        # Exercise boundary discrimination without constructing larger programs.
        assert depth(parse("main = id(id(id(id(id(xs)))))")["main"]) == 6
        report["passed"] = True
    except Exception:
        (private / "failure.txt").write_text(traceback.format_exc())
        report["error"] = "private failure retained; no case skipped or expectations changed"
    report["cases_sha256"] = hashlib.sha256((private / "cases.jsonl.gz").read_bytes()).hexdigest()
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2)); return report["passed"]


def verify(private, destination):
    """Recheck unchanged private bytes; never regenerate or retune predictions."""
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, heldouts=0, generated=0, bounds_controls=0,
                  unique_generated=0, candidate_executed=False, frozen=False)
    identities = set()
    try:
        for line in gzip.open(private / "cases.jsonl.gz", "rt"):
            case = json.loads(line); program = parse(case["source"]); check_bounds(program)
            assert len(case["cells"]) <= 4
            _, answer, reference, bindings, outcome = predict(case)
            expected = dict(answer=answer, bindings=bindings, trace=reference.trace, events=reference.events, outcome=outcome)
            # JSON object keys are strings. Normalize transport before sorting:
            # integer binding keys 2,10 and saved strings "2","10" sort
            # differently without changing any binding identity or prediction.
            expected = json.loads(json.dumps(expected))
            assert json.dumps(expected, sort_keys=True) == json.dumps(case["expected"], sort_keys=True), "private predictions changed"
            kind = "heldouts" if "family" in case else "generated"; report[kind] += 1
            if kind == "generated": identities.add(json.dumps({k: case[k] for k in ("source", "cells", "inputs", "outside")}, sort_keys=True))
        report["unique_generated"] = len(identities)
        # The proposed bound is on generator coverage, NOT language acceptance.
        for source, expected_error in [
            ("input xs: ListInt; " + DEFS["id"] + "main = id(id(id(id(id(xs)))))", "generated depth"),
            ("def a(): Int = 1 end def b(): Int = 2 end def c(): Int = 3 end def d(): Int = 4 end main = a()", "generated functions"),
            ("def f(a: Int,b: Int,c: Int,d: Int,e: Int): Int = a end main = f(1,2,3,4,5)", "generated arity"),
        ]:
            try: check_bounds(parse(source))
            except AssertionError as error: assert str(error) == expected_error; report["bounds_controls"] += 1
            else: raise AssertionError("out-of-bound generator shape accepted")
        four = "def f(a: Int,b: Int,c: Int,d: Int): Int = a + b - c + d end main = f(7,2,11,3)"
        assert check_bounds(parse(four))["arity"] == 4
        assert predict(dict(source=four, cells=[], inputs=[], outside=[]))[1] == 1
        assert report["heldouts"] == 24 and report["generated"] == 500
        report["passed"] = True
    except Exception:
        (private / (destination.name + "-failure.txt")).write_text(traceback.format_exc())
        report["error"] = "private verification failure retained"
    report["cases_sha256"] = hashlib.sha256((private / "cases.jsonl.gz").read_bytes()).hexdigest()
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2)); return report["passed"]


if __name__ == "__main__":
    operation = verify if len(sys.argv) > 3 and sys.argv[3] == "verify" else run
    sys.exit(not operation(Path(sys.argv[1]), Path(sys.argv[2])))
