"""Proposed frontend refusal set; annotated ranges precede reference execution.

Annotations select the English-rule explanatory construct. No parser output is
used to derive the expected range. Stop/save on the first reference mismatch.
"""
import json
from pathlib import Path
import sys
import traceback

from syntax import Refusal, check, parse, position


# Preserved v8 authoring error. D144 authorizes only the versioned correction below:
# equality needs integer operands; [] is invalid, while 1 is a valid integer.
V8_ORIGINAL_OPERAND_ROW = ("B", "main = [] == ⟦1⟧", "operand-kind")

CASES = [
    # Syntax/lexical checks must finish before match-binder/name/kind checks.
    ("B", "main = match [] do [] -> 0; [x | x] -> ⟦@⟧ end", "lexical"),
    ("B", "main = ⟦missing⟧(7)", "unknown-function"),
    ("A", "⟦def f(): Int = 7 end⟧ main = f()", "stage-unsupported"),
    ("A", "main = ⟦missing(7)⟧", "stage-unsupported"),
    ("B", "input xs: ListInt; input ⟦xs⟧: Int; main = 1", "duplicate-input"),
    ("B", "input xs: ⟦Bool⟧; main = 1", "input-type"),
    ("B", "main = match [] do [] -> 0; [h | ⟦h⟧] -> 1 end", "match-binders"),
    ("B", "main = match ⟦3⟧ do [] -> 0; [h | t] -> 1 end", "scrutinee-kind"),
    ("B", "main = [⟦false⟧]", "head-kind"),
    ("B", "main = [3 | ⟦9⟧]", "tail-kind"),
    ("B", "main = ⟦[]⟧ == 1", "operand-kind"),
    ("B", "main = if true then [] else ⟦7⟧ end", "branch-kind"),
    ("B", "main = let x = ⟦x⟧ in x", "unbound-variable"),
    ("B", "main = if true then 7 else ⟦ghost⟧ end", "unbound-variable"),
    ("B", "def f(): Int = 7 end def ⟦f⟧(): Int = 9 end main = f()", "duplicate-function"),
    ("B", "def f(x: Int, ⟦x⟧: Int): Int = x end main = 7", "duplicate-parameter"),
    ("B", "def f(x: Int): Int = x end main = ⟦f()⟧", "arity"),
    ("B", "def f(x: Int): Int = x end main = f(⟦false⟧)", "argument-kind"),
    ("B", "def f(): Int = ⟦false⟧ end main = 7", "result-kind"),
    ("B", "input n: Int; def f(): Int = ⟦n⟧ end main = 7", "unbound-variable"),
    ("B", "def f(): Int = 7 end main = ⟦f⟧", "unbound-variable"),
    ("B", "def f(x: ⟦Other⟧): Int = 7 end main = 7", "type"),
    ("B", "def f(): ⟦Other⟧ = 7 end main = 7", "type"),
    ("B", "main = 1 ⟦*⟧ 2", "lexical"),
]


def expected(annotation):
    start = annotation.index("⟦"); close = annotation.index("⟧")
    assert annotation.count("⟦") == annotation.count("⟧") == 1
    source = annotation[:start] + annotation[start + 1:close] + annotation[close + 1:]
    end = close - 1
    # These examples are single-line ASCII after removing the range markers.
    assert "\n" not in source and source.isascii()
    return source, [1, start + 1], [1, end + 1]


def run(destination):
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, proposed=True, cases=0, observed=[])
    try:
        for stage, annotation, kind in CASES:
            source, start, end = expected(annotation)
            try: check(parse(source), stage)
            except Refusal as error:
                actual = (error.kind, position(source, error.start), position(source, error.end))
                report["observed"].append(dict(source=source, stage=stage, expected=[kind, start, end], actual=actual))
                assert actual == (kind, start, end), (source, actual, (kind, start, end))
            else: raise AssertionError("invalid source accepted: " + source)
            report["cases"] += 1
        report["passed"] = True
    except Exception:
        report["error"] = traceback.format_exc()
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return report["passed"]


if __name__ == "__main__": sys.exit(not run(Path(sys.argv[1])))
