"""Proposed pre-installation fixture validation; never modifies managed storage."""
from collections import Counter
from copy import deepcopy
import gzip
import json
from pathlib import Path
import re
import sys
import traceback

from finite_reference import decode
from predicates import walk
from syntax import parse, pretty
from validate import CORPUS


def validate_fixture(program, cells, inputs, outside):
    declarations = [(n, k) for n, k, *_ in program["inputs"]]
    assert [n for n, _ in inputs] == [n for n, _ in declarations], "input names/order"
    ids = [c[0] for c in cells]
    assert all(type(i) is int and i >= 0 for i in ids) and len(set(ids)) == len(ids), "cell identities"
    roots = list(outside)
    for (_, kind), (_, value) in zip(declarations, inputs):
        assert value[0] == {"Int": "n", "ListInt": "l"}[kind], "input kind"
        if kind == "ListInt": roots.append(value[1])
        else: assert type(value[1]) is str and re.fullmatch(r"0|-?[1-9][0-9]*", value[1]), "integer input"
    assert all(r is None or type(r) is int and r in ids for r in roots), "root dangling"
    counts = Counter(r for r in roots if r is not None)
    for ident, item, tail, count, status in cells:
        assert type(item) is str and re.fullmatch(r"0|-?[1-9][0-9]*", item), "cell integer"
        assert tail is None or type(tail) is int and tail in ids, "tail dangling"
        assert type(count) is int and count > 0 and status == "live", "initial live/count"
        if tail is not None: counts[tail] += 1
    assert all(c[3] == counts[c[0]] for c in cells), "holder counts"
    reachable = set()
    for root in roots: reachable.update(walk(cells, root)[1])
    assert reachable == set(ids), "unreachable initial cell"


def run(destination):
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, corpus=0, refusals={})
    try:
        for line in gzip.open(CORPUS, "rt"):
            expr, cells, inputs, outside = decode(json.loads(line)["input"])
            source = "".join(f"input {n}: {'ListInt' if v[0] == 'l' else 'Int'};" for n, v in inputs) + "main = " + pretty(expr)
            validate_fixture(parse(source), cells, inputs, outside); report["corpus"] += 1
        program = parse("input xs: ListInt; main = xs")
        base = [[1, "3", 2, 1, "live"], [2, "7", None, 1, "live"]]
        for name, cells, inputs, expected in [
            ("duplicate", base + [base[0]], [("xs", ["l", 1])], "cell identities"),
            ("bad-count", [[1, "3", 2, 2, "live"], base[1]], [("xs", ["l", 1])], "holder counts"),
            ("dangling", base, [("xs", ["l", 9])], "root dangling"),
            ("tail-dangling", [[1, "3", 9, 1, "live"]], [("xs", ["l", 1])], "tail dangling"),
            ("unreachable", base + [[3, "9", None, 1, "live"]], [("xs", ["l", 1])], "holder counts"),
            ("cycle", [[1, "3", 2, 2, "live"], [2, "7", 1, 1, "live"]], [("xs", ["l", 1])], "dangling/cycle"),
            ("wrong-kind", base, [("xs", ["n", "3"])], "input kind"),
            ("bad-item", [[1, "03", None, 1, "live"]], [("xs", ["l", 1])], "cell integer"),
        ]:
            before = deepcopy(cells)
            try: validate_fixture(program, cells, inputs, [])
            except AssertionError as error: assert str(error) == expected; report["refusals"][name] = expected
            else: raise AssertionError("invalid fixture accepted: " + name)
            assert cells == before, "fixture validation mutated input"
        report["passed"] = True
    except Exception: report["error"] = traceback.format_exc()
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2)); return report["passed"]


if __name__ == "__main__": sys.exit(not run(Path(sys.argv[1])))
