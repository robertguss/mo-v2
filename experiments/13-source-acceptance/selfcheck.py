"""Validate draft references/predicates against separately stated examples and defects."""
from copy import deepcopy
import json
from pathlib import Path
import sys
import traceback

from call_reference import CallReference, immutable_answer
from cases import examples
from predicates import (final_memory, invocation_creates, physical_events,
                        protection, resume_join, walk)
from syntax import Refusal, check, parse, position


# Expected outcomes/ranges chosen from English rules, not copied from parser output.
ACCEPT = [
    ("main = 9 - 4 - 2", 3), ("main = 9 - (4 - 2)", 7),
    ("main = true", True), ("main = false", False),
    ("main = if false then 7 else 11 end", 11),
    ("main = let flag = true in if flag then 13 else -4 end", 13),
    ("main = if true then false else true end", False),
    ("main = let n = 5 in let n = n - 2 in n + 7", 10),
    ("main = [3, -2, 8]", (3, -2, 8)),
    ("main = 340282366920938463463374607431768211456 + 7", 340282366920938463463374607431768211463),
    ("main = 0 - 340282366920938463463374607431768211456", -340282366920938463463374607431768211456),
    ("main = 340282366920938463463374607431768211456 < 340282366920938463463374607431768211455", False),
    ("main = let n = 340282366920938463463374607431768211456 in n - (n - 9)", 9),
    ("def pick(flag: Bool): Int = if flag then 7 else 11 end end main = pick(false)", 11),
    ("def f(f: Int): Int = f + 2 end main = f(9)", 11),
    ("def f(n: Int): Int = F(n) end def F(n: Int): Int = n - 3 end main = f(8)", 5),
]
REFUSE = [
    ("main = ghost", "unbound-variable", [1, 8], [1, 13]),
    ("main = if 3 then 1 else 2 end", "condition-kind", [1, 11], [1, 12]),
    ("main = 1 + []", "operand-kind", [1, 12], [1, 14]),
    ("main = if 0 == 0 then 1 else [] end", "branch-kind", [1, 30], [1, 32]),
    ("main = true + 1", "operand-kind", [1, 8], [1, 12]),
    ("main = true == false", "operand-kind", [1, 8], [1, 12]),
    ("main = if 1 then 7 else 11 end", "condition-kind", [1, 11], [1, 12]),
    ("main = trueish", "unbound-variable", [1, 8], [1, 15]),
    ("main = 01", "numeral", [1, 8], [1, 10]),
    ("main = -(1)", "syntax", [1, 9], [1, 10]),
    ("main = if true then 1 else 2", "syntax", [1, 29], [1, 29]),
    ("main =\r\n\tghost", "unbound-variable", [2, 2], [2, 7]),
]

ORDER = {
    "C1": [["enter", 1, 0, "one"], ["create", 2], ["return", 1], ["free", 1]],
    "C2": [["enter", 1, 0, "one"], ["create", 2], ["return", 1], ["write", 1]],
    "C8": [["create", 0], ["enter", 1, 0, "identity"], ["return", 1]],
    "C9": [["enter", 1, 0, "outer"], ["create", 0], ["enter", 2, 1, "identity"],
           ["return", 2], ["return", 1]],
}


def reject(fn, message):
    try: fn()
    except AssertionError as error:
        assert message in str(error), (message, str(error))
        return str(error)
    raise AssertionError("broken input accepted: " + message)


def validate(destination):
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, source_accept=0, source_refuse=0, public_cases=0,
                  controls={}, missing=["all fine-grained expected transition traces",
                      "real candidate/physical/allocator instrumentation", "all resume/destroy boundaries",
                      "private heldouts/generated corpus", "complete exact refusal set", "scientific lock"])
    outputs = []
    try:
        for source, expected in ACCEPT:
            program = parse(source); check(program)
            actual = immutable_answer(program, {})
            assert type(actual) is type(expected) and actual == expected, (source, actual, expected)
            report["source_accept"] += 1
        for source, kind, start, end in REFUSE:
            try: check(parse(source))
            except Refusal as error:
                assert (error.kind, position(source, error.start), position(source, error.end)) == (kind, start, end)
            else: raise AssertionError("invalid source accepted: " + source)
            report["source_refuse"] += 1
        for case in examples():
            program = parse(case["source"]); check(program)
            reference = CallReference(program, case["cells"], case["inputs"], case["outside"], landmark_limit=60 if case["value"] is None else 10000)
            result = reference.observe(program["main"])
            states = result.get("states", result.get("outcome", {}).get("states"))
            protection(states, case["cells"], case["outside"])
            if case["value"] is None:
                assert result["status"] == "reference-prefix"
                counts = invocation_creates(result["events"], False)
                if case["name"] in ("C12", "C14"):
                    assert not reference.record
                else:
                    assert sum(e[0] == "create" for e in reference.record) > 1
                    assert sum(e[0] == "free" for e in reference.record) > 1
                if case["name"] == "C14": assert result["memory"] == [[1, "1", None, 0, "aside"]]
            else:
                assert result["status"] == "finished"
                outcome = result["outcome"]
                plain = outcome["value"]
                actual = ([int(n) for n in plain[1]] if plain[0] == "l" else
                          int(plain[1]) if plain[0] == "n" else plain[1])
                assert type(actual) is type(case["value"]) and actual == case["value"]
                counts = [sum(e[0] == k for e in outcome["record"]) for k in ("create", "write", "free")]
                assert counts == case["counts"], (case["name"], counts, case["counts"])
                final_memory(outcome, case["outside"])
                inputs = {name: tuple(walk(case["cells"], v[1])[0]) for name, v in case["inputs"]}
                expected = immutable_answer(program, inputs)
                assert actual == (list(expected) if isinstance(expected, tuple) else expected)
                intervals = invocation_creates(result["events"])
                if case["name"] in ORDER: assert result["events"] == ORDER[case["name"]]
                if case["name"] == "C9": assert [x[2] for x in intervals] == [1, 0]
                if case["name"] == "C10-unique": assert [e[1] for e in outcome["record"]] == [3, 2, 1]
                if case["name"] == "C10-retained": assert [x[2] for x in intervals] == [3, 2, 1, 0]
            outputs.append(dict(case=case, observed=result))
            report["public_cases"] += 1
        # Synthetic stream/state defects validate predicates, NOT runtime controls.
        initial = [[1, "7", None, 1, "live"]]
        good = [["fixture", 1, 100], ["write", 1, 100]]
        physical_events(initial, good, [["write", 1]], initial)
        bad = [["fixture", 1, 100], ["write", 1, 200]]
        report["controls"]["replaced-object"] = reject(lambda: physical_events(initial, bad, [["write", 1]], initial), "physical continuity")
        recycled = [["fixture", 1, 100], ["free", 1, 100], ["create", 1, 100]]
        report["controls"]["recycled-lifetime"] = reject(lambda: physical_events(initial, recycled, [["free", 1], ["create", 1]], initial), "identity recycled")
        prefix = [["create", 1]]; suffix = [["write", 1]]
        resume_join(prefix, prefix + suffix, suffix, {1: 100}, {1: 100})
        report["controls"]["replay"] = reject(lambda: resume_join(prefix, prefix + prefix + suffix, suffix, {1: 100}, {1: 100}), "replay/wrong suffix")
        report["controls"]["resume-object"] = reject(lambda: resume_join(prefix, prefix + suffix, suffix, {1: 100}, {1: 200}), "replaced live object")
        report["controls"]["wrong-return"] = reject(lambda: invocation_creates([["enter", 1, 0, "f"], ["return", 2]]), "return identity")
        report["controls"]["lost-return"] = reject(lambda: invocation_creates([["enter", 1, 0, "f"]]), "missing return")
        outcome = dict(memory=initial + [[2, "9", None, 0, "live"]], answer=["l", 1], value=["l", ["7"]])
        report["controls"]["unreachable-cell"] = reject(lambda: final_memory(outcome, []), "final reachability")
        report["passed"] = True
    except Exception:
        report["error"] = traceback.format_exc()
    (destination / "observed.json").write_text(json.dumps(outputs, indent=2) + "\n")
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return report["passed"]


if __name__ == "__main__": sys.exit(not validate(Path(sys.argv[1])))
