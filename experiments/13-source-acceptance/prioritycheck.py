"""D142 mixed-error expectations stated from character positions, not lexer output."""
import json
from pathlib import Path
import sys
import traceback

from syntax import Refusal, check, parse, position


REFUSALS = [
    ("main = (1 2)", "syntax", [1, 11], [1, 12]),
    ("main = (1 2) @", "syntax", [1, 11], [1, 12]),
    ("main = (1 2) 01", "syntax", [1, 11], [1, 12]),
    ("main = (01 2) @", "numeral", [1, 9], [1, 11]),
    ("main = (@ 2) @", "lexical", [1, 9], [1, 10]),
    ("main = (1 @ 2) @", "lexical", [1, 11], [1, 12]),
    ("main = (1 2) # @ 01", "syntax", [1, 11], [1, 12]),
    ("main = (1\n 2) @", "syntax", [2, 2], [2, 3]),
    ("main = (1\r\n\t2) @", "syntax", [2, 2], [2, 3]),
    ("main = 1 2 @", "syntax", [1, 10], [1, 11]),
    ("main = 1 @ 2", "lexical", [1, 10], [1, 11]),
    ("main = let x 1 in x @", "syntax", [1, 14], [1, 15]),
    ("main =", "syntax", [1, 7], [1, 7]),
    ("main = 1 EOF", "syntax", [1, 10], [1, 13]),
]
ACCEPTS = ["main = 1 # @ 01\n + 2", "main = let EOF = 3 in EOF"]


def run(destination):
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, rule="D142 earliest lexical/syntax source error",
                  refusals=0, accepts=0, observed=[])
    try:
        for source, kind, start, end in REFUSALS:
            try: parse(source)
            except Refusal as error:
                actual = (error.kind, position(source, error.start), position(source, error.end))
                report["observed"].append(dict(source=source, expected=[kind, start, end], actual=actual))
                assert actual == (kind, start, end), (source, actual, (kind, start, end))
            else: raise AssertionError("invalid source accepted: " + source)
            report["refusals"] += 1
        for source in ACCEPTS:
            assert check(parse(source)) == "Int"
            report["accepts"] += 1
        report["passed"] = True
    except Exception:
        report["error"] = traceback.format_exc()
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return report["passed"]


if __name__ == "__main__": sys.exit(not run(Path(sys.argv[1])))
