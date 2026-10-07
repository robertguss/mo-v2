"""D144 correction and asymmetric integer-only comparisons, independently stated."""
import json
from pathlib import Path
import sys
import traceback

from call_reference import immutable_answer
from refusalcheck import expected
from syntax import Refusal, check, parse, position


REFUSALS = [
    (f"main = ⟦[]⟧ {op} 1", "operand-kind") for op in ("==", "<", "<=")
] + [
    (f"main = 1 {op} ⟦[]⟧", "operand-kind") for op in ("==", "<", "<=")
] + [
    (f"main = ⟦false⟧ {op} 1", "operand-kind") for op in ("==", "<", "<=")
] + [
    (f"main = 1 {op} ⟦true⟧", "operand-kind") for op in ("==", "<", "<=")
]
ACCEPTS = [
    ("main = -7 == 3", False), ("main = 3 == -7", False), ("main = -7 == -7", True),
    ("main = -7 < 3", True), ("main = 3 < -7", False), ("main = -7 < -7", False),
    ("main = -7 <= 3", True), ("main = 3 <= -7", False), ("main = -7 <= -7", True),
    ("main = 340282366920938463463374607431768211463 == 340282366920938463463374607431768211456", False),
    ("main = -340282366920938463463374607431768211463 < -340282366920938463463374607431768211456", True),
]


def run(destination):
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, rule="D144 versioned operand prediction correction",
                  refusals=0, accepts=0, observed=[])
    try:
        for annotation, kind in REFUSALS:
            source, start, end = expected(annotation)
            try: check(parse(source))
            except Refusal as error:
                actual = (error.kind, position(source, error.start), position(source, error.end))
                report["observed"].append(dict(source=source, expected=[kind, start, end], actual=actual))
                assert actual == (kind, start, end), (source, actual, (kind, start, end))
            else: raise AssertionError("invalid source accepted: " + source)
            report["refusals"] += 1
        for source, answer in ACCEPTS:
            program = parse(source)
            assert check(program) == "Bool"
            actual = immutable_answer(program, {})
            assert type(actual) is bool and actual is answer, (source, actual, answer)
            report["observed"].append(dict(source=source, expected=answer, actual=actual))
            report["accepts"] += 1
        report["passed"] = True
    except Exception:
        report["error"] = traceback.format_exc()
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({k: v for k, v in report.items() if k != "observed"}, indent=2))
    return report["passed"]


if __name__ == "__main__": sys.exit(not run(Path(sys.argv[1])))
