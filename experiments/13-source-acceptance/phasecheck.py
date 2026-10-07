"""D143 whole-file syntax-before-name/type expectations, stated independently."""
import json
from pathlib import Path
import sys
import traceback

from refusalcheck import expected
from syntax import Refusal, check, parse, position


CASES = [
    ("main = match [] do [] -> 0; [x | x] -> ⟦@⟧ end", "lexical"),
    ("main = match [] do [] -> 0; [x | ⟦x⟧] -> 1 end", "match-binders"),
    ("main = match [] do [] -> 0; [x | x] -> 1 end ⟦2⟧ @", "syntax"),
    ("input x: Int; input x: Int; main = ⟦@⟧", "lexical"),
    ("input x: Int; input x: Int; main = 1 ⟦2⟧ @", "syntax"),
    ("input x: Int; input ⟦x⟧: Int; main = 1", "duplicate-input"),
    ("def f(x: Int, x: Int): Int = ⟦@⟧ end main = 7", "lexical"),
    ("def f(x: Int, x: Int): Int = x end main = 1 ⟦2⟧ @", "syntax"),
    ("def f(x: Int, ⟦x⟧: Int): Int = x end main = 7", "duplicate-parameter"),
    ("def f(): Int = 7 end def f(): Int = 9 end main = ⟦@⟧", "lexical"),
    ("def f(): Int = 7 end def f(): Int = 9 end main = 1 ⟦2⟧ @", "syntax"),
    ("def f(): Int = 7 end def ⟦f⟧(): Int = 9 end main = 1", "duplicate-function"),
    ("input flag: Bool; main = ⟦@⟧", "lexical"),
    ("input flag: ⟦Bool⟧; main = 1", "input-type"),
    ("def f(x: Other): Int = 7 end main = (1 ⟦2⟧) @", "syntax"),
    ("def f(x: ⟦Other⟧): Int = 7 end main = 7", "type"),
    ("def f(): Other = 7 end main = ⟦@⟧", "lexical"),
    ("def f(): ⟦Other⟧ = 7 end main = 7", "type"),
    ("def f(): Int = false end main = 1 ⟦2⟧ @", "syntax"),
    ("def f(): Int = ⟦false⟧ end main = 7", "result-kind"),
    ("def f(x: Int): Int = x end main = f(false) ⟦2⟧ @", "syntax"),
    ("def f(x: Int): Int = x end main = f(⟦false⟧)", "argument-kind"),
    ("main = ghost ⟦@⟧", "lexical"),
    ("main = ⟦ghost⟧", "unbound-variable"),
]


def run(destination):
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, rule="D143 whole-file syntax before name/type", cases=0, observed=[])
    try:
        for annotation, kind in CASES:
            source, start, end = expected(annotation)
            try: check(parse(source))
            except Refusal as error:
                actual = (error.kind, position(source, error.start), position(source, error.end))
                report["observed"].append(dict(source=source, expected=[kind, start, end], actual=actual))
                assert actual == (kind, start, end), (source, actual, (kind, start, end))
            else: raise AssertionError("invalid source accepted: " + source)
            report["cases"] += 1
        report["passed"] = True
    except Exception:
        report["error"] = traceback.format_exc()
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({k: v for k, v in report.items() if k != "observed"}, indent=2))
    return report["passed"]


if __name__ == "__main__": sys.exit(not run(Path(sys.argv[1])))
