"""Exact decimal carry expectations derived as strings, not from the reference.

An all-nines positive integer plus one is one followed by the same number of
zeros. No proposed digit-count grammar restriction or new operator is involved.
"""
import json
from pathlib import Path
import sys
import traceback

from call_reference import immutable_answer
from syntax import check, parse, pretty


def run(destination):
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, passed_cases=0, python_digit_limit=sys.get_int_max_str_digits())
    case = None
    try:
        for digits in (1000, 4299, 4300, 4301, 5000):
            nines, power = "9" * digits, "1" + "0" * digits
            # Decimal carry/borrow/sign identities stated independently as strings.
            for expression, answer, derivation in (
                (nines + " + 1", power, "carry across every nine"),
                (power + " - 1", nines, "borrow across every zero"),
                ("-" + nines + " - 1", "-" + power, "negative carry"),
                ("-" + power + " + 1", "-" + nines, "negative borrow"),
                (nines + " - " + nines, "0", "equal operands cancel"),
            ):
                case = dict(digits=digits, source="main = " + expression,
                            expected_kind="Int", expected_decimal=answer, derivation=derivation)
                program = parse(case["source"])
                assert check(program) == "Int"
                assert str(immutable_answer(program, {})) == answer
                assert parse("main = " + pretty(program["main"]))["main"] == program["main"], "decimal source round trip"
                report["passed_cases"] += 1
            for sign in ("", "-"):
                source = "input n: Int; main = n + " + ("1" if sign == "" else "-1")
                case = dict(digits=digits, source=source, input_decimal=sign + nines,
                            expected_decimal=sign + power, derivation="signed input carry")
                program = parse(source); assert check(program) == "Int"
                assert str(immutable_answer(program, {"n": int(sign + nines)})) == sign + power
                report["passed_cases"] += 1
        report["passed"] = True
    except Exception:
        report["error"] = traceback.format_exc()
        (destination / "counterexample.json").write_text(json.dumps(case, indent=2) + "\n")
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return report["passed"]


if __name__ == "__main__": sys.exit(not run(Path(sys.argv[1])))
