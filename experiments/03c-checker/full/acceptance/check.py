#!/usr/bin/env python3
"""Fixture/type/graph checks, not an interpreter, demand checker or theorem test.

Optional --observations accepts exported summary JSON (see CHECKS.md). It cannot
replace the still-unimplemented formal boundary/lifetime integration checks.
"""
import argparse
import copy
import json
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def load(name):
    return json.loads((HERE / name).read_text(), object_pairs_hook=unique_object)


FUNCTIONS = load("programs.json")["functions"]
STARTS = load("starts.json")["starts"]
PREDICTIONS = load("predictions.json")


def check(condition, why):
    if not condition:
        raise ValueError(why)


def kind(expr, env):
    if type(expr) is bool:
        return "B"
    if type(expr) is int:
        return "I"
    if type(expr) is str:
        check(expr in env, f"unbound variable {expr}")
        return env[expr]
    check(type(expr) is list, "expression is not a tree")
    if not expr:
        return "L"
    op, *args = expr
    if op in ("cons", "add", "sub", "eq", "lt", "le"):
        check(len(args) == 2, "binary arity")
        check(kind(args[0], env) == "I", "binary head must be Int")
        check(kind(args[1], env) == ("L" if op == "cons" else "I"), "binary tail kind")
        return "L" if op == "cons" else ("I" if op in ("add", "sub") else "B")
    if op == "call":
        name, *actuals = args
        check(name in FUNCTIONS, f"unknown function {name}")
        params, result, _ = FUNCTIONS[name]
        check(len(actuals) == len(params), "call arity")
        for actual, (_, formal_kind) in zip(actuals, params):
            check(kind(actual, env) == formal_kind, f"argument kind for {name}")
        return result
    if op == "let":
        check(len(args) == 3, "let arity")
        name, initializer, body = args
        return kind(body, {**env, name: kind(initializer, env)})
    if op == "if":
        check(len(args) == 3, "if arity")
        condition, yes, no = args
        check(kind(condition, env) == "B", "if condition kind")
        result = kind(yes, env)
        check(result == kind(no, env), "if branch mismatch")
        return result
    if op == "match":
        check(len(args) == 5, "match arity")
        scrutinee, empty, head, tail, cell = args
        check(head != tail, "duplicate pattern binder")
        check(kind(scrutinee, env) == "L", "match scrutinee kind")
        result = kind(empty, env)
        check(result == kind(cell, {**env, head: "I", tail: "L"}), "match branch mismatch")
        return result
    raise ValueError(f"unknown operator {op}")


def calls(expr):
    if not isinstance(expr, list) or not expr:
        return set()
    found = {expr[1]} if expr[0] == "call" else set()
    for child in expr[1:]:
        found |= calls(child)
    return found


def function_table(main):
    names = calls(main)
    while True:
        expanded = names | set().union(*(calls(FUNCTIONS[n][2]) for n in names))
        if expanded == names:
            return {n: d for n, d in FUNCTIONS.items() if n in names}
        names = expanded


def walk(cells, root):
    seen, values = set(), []
    while root is not None:
        check(root in cells, f"dangling root/link {root}")
        check(root not in seen, f"cycle at {root}")
        seen.add(root)
        item, root = cells[root]
        values.append(item)
    return seen, values


def graph(cells, roots):
    reached = set()
    for root in roots:
        reached |= walk(cells, root)[0]
    check(reached == set(cells), "unreachable allocated cell")
    return Counter(r for r in roots if r is not None) + Counter(
        tail for _, tail in cells.values() if tail is not None
    )


def valid_start(start):
    cells = {a: (n, tail) for a, n, tail, _ in start["cells"]}
    check(len(cells) == len(start["cells"]), "duplicate cell identity")
    check(all(type(n) is int for n, _ in cells.values()), "cell item not Int")
    names = [name for name, _, _ in start["inputs"]]
    check(len(set(names)) == len(names), "duplicate input")
    roots = list(start["outside"])
    for _, k, v in start["inputs"]:
        check(k in ("I", "L"), "Bool/unknown input kind")
        if k == "I":
            check(type(v) is int, "input not Int")
        else:
            roots.append(v)
    counts = graph(cells, roots)
    for a, _, _, count in start["cells"]:
        check(type(count) is int and count == counts[a], f"start count mismatch at {a}")


def all_cases():
    rows = list(PREDICTIONS["cases"])
    variants = PREDICTIONS["boundary_variants"]
    for i, (fn, args, nil_answer, single_answer, events, category) in enumerate(variants["rows"]):
        demands = next(r[4] for r in rows if category in r[1])
        binary = fn in ("append", "merge")
        main = ["call", fn, "xs", "ys"] if binary else ["call", fn, *args, "xs"]
        for label, start, answer, trace in (
            ("nil", "twoNil" if binary else "nil", nil_answer, []),
            ("single", "singleAndNil" if binary else "singleNeg", single_answer, events),
        ):
            rows.append([f"boundary-{i}-{label}", [category], start, main, demands,
                         "L", answer, "A" if answer else None, trace, "finished"])
    for i, (fn, args, start, answer, events, category) in enumerate(variants["additional"]):
        demands = next(r[4] for r in rows if category in r[1])
        main = ["call", fn, *args] + ([] if fn == "build" else ["xs"])
        rows.append([f"additional-{i}", [category], start, main, demands,
                     "L", answer, "N0" if answer else None, events, "finished"])
    return rows


def expected_final(row):
    """Cross-check manual cell ledger against manual answer; never run its AST.

    This does NOT establish intermediate reference counts/reservation eligibility.
    Detach/GiveUp are intentionally absent from this primitive-event projection.
    """
    start = STARTS[row[2]]
    cells = {a: (n, tail) for a, n, tail, _ in start["cells"]}
    ever = set(cells)
    next_fresh = 0
    for event in row[8]:
        parts = event.split()
        op, a = parts[:2]
        check(op in ("C", "W", "F"), "unknown cell event")
        if op == "F":
            check(len(parts) == 2 and a in cells, "free absent/duplicate cell")
            del cells[a]
        else:
            check(len(parts) == 4, "cell event arity")
            if op == "C":
                check(a == f"N{next_fresh}" and a not in ever, "fresh lifetime/order mismatch")
                next_fresh += 1
                ever.add(a)
            else:
                check(a in cells, "write to unallocated cell")
            cells[a] = (int(parts[2]), None if parts[3] == "-" else parts[3])
    if row[9] != "finished":
        return None
    roots = list(start["outside"]) + ([row[7]] if row[5] == "L" else [])
    counts = graph(cells, roots)
    if row[5] == "L":
        check(walk(cells, row[7])[1] == row[6], f"manual ledger/answer disagree: {row[0]}")
    for outside in start["outside"]:
        initial = {a: (n, t) for a, n, t, _ in start["cells"]}
        check(walk(cells, outside)[1] == walk(initial, outside)[1], "outside value changed")
    return sorted([a, n, t, counts[a], "live"] for a, (n, t) in cells.items())


def rejects(label, operation):
    try:
        operation()
    except ValueError:
        print(f"PASS fixture-negative: {label}")
    else:
        raise ValueError(f"negative control did not fail: {label}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--observations", type=Path)
    args = parser.parse_args()
    for name, (params, result, body) in FUNCTIONS.items():
        check(len(dict(params)) == len(params), "duplicate parameter")
        check(kind(body, dict(params)) == result, f"function result kind {name}")
    for start in STARTS.values():
        valid_start(start)
    rows = all_cases()
    check(len({r[0] for r in rows}) == len(rows), "duplicate case id")
    coverage = set().union(*(set(r[1]) for r in rows))
    required = {f"C{i}" for i in range(1, 23)}
    for prefix, count in [("S1A", 12), ("S1R", 6), ("S1O", 1), ("S2A", 3), ("S2R", 3), ("S2O", 2)]:
        required |= {f"{prefix}{i:02d}" for i in range(1, count + 1)}
    check(coverage == required, "coverage mismatch")
    finals = {}
    for row in rows:
        env = {n: k for n, k, _ in STARTS[row[2]]["inputs"]}
        check(kind(row[3], env) == row[5], f"main result kind {row[0]}")
        check(set(row[4]) <= set(function_table(row[3])), f"unreferenced demand {row[0]}")
        finals[row[0]] = expected_final(row)
        if any(c.startswith("S1A") for c in row[1]):
            check(not any(e.startswith("C ") for e in row[8]), "must-accept predicted Create")
    for category in required:
        if category.startswith(("S1R", "S2R")):
            check(any(category in r[1] and any(e.startswith("C ") for e in r[8]) for r in rows),
                  f"no allocating refusal witness for {category}")
    print(f"PASS: {len(FUNCTIONS)} typed library declarations; {len(STARTS)} valid starts; "
          f"{len(rows)} exact cases; C1-C22 and all 27 categories")
    print(f"PASS: {sum(v is not None for v in finals.values())} finished manual ledgers/answers/retained graphs")
    rejects("Bool is not Int", lambda: kind(["add", True, 1], {}))
    rejects("unselected branch checked", lambda: kind(["if", True, 0, []], {}))
    rejects("function cannot capture caller input", lambda: kind("xs", {"n": "I"}))
    bad = copy.deepcopy(STARTS["pair"])
    bad["cells"][0][3] = 2
    rejects("bad initial multiplicity", lambda: valid_start(bad))
    bad_cycle = copy.deepcopy(STARTS["pair"])
    bad_cycle["cells"][1][2] = "A"
    rejects("cycle", lambda: valid_start(bad_cycle))
    bad_answer = copy.deepcopy(rows[0])
    bad_answer[6] = [9]
    rejects("wrong answer vs ledger", lambda: expected_final(bad_answer))
    missing_free = copy.deepcopy(rows[0])
    missing_free[8].remove("F A")
    rejects("omitted Free retains garbage", lambda: expected_final(missing_free))
    fake_write = copy.deepcopy(rows[0])
    fake_write[8][0] = "W N0 1 -"
    rejects("Create relabeled as Write", lambda: expected_final(fake_write))
    if args.observations:
        observed = json.loads(args.observations.read_text(), object_pairs_hook=unique_object)
        check(set(observed) == {r[0] for r in rows}, "observation case set mismatch")
        for row in rows:
            obs = observed[row[0]]
            for field, expected in [("status", row[9]), ("kind", row[5]), ("answer", row[6]),
                                    ("rawListRoot", row[7]), ("cellEvents", row[8])]:
                # Python equates True with 1; the public kinds must remain distinct.
                check(json.dumps(obs[field]) == json.dumps(expected), f"observed {field} mismatch: {row[0]}")
            if finals[row[0]] is not None:
                check(json.dumps(sorted(obs["finalCells"])) == json.dumps(finals[row[0]]),
                      f"final heap mismatch: {row[0]}")
        print("PASS summary observations; boundary/lifetime/F5/lifecycle checks STILL REQUIRED")
    else:
        print("NOT RUN: formal execution, boundary assertions, theorem/axiom checks, scientific mutants")


if __name__ == "__main__":
    main()
