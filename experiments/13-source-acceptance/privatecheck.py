"""Prepare isolated draft heldouts; publish a manifest, never cases or predictions.

The private destination must remain outside the builder checkout/context. These
are preparation cases, not a scientific lock. No candidate is run by this tool.
"""
import gzip
import hashlib
import json
from pathlib import Path
import re
import secrets
import sys
import traceback

from acquisitioncheck import predict
from fixturecheck import validate_fixture
from generated import generate
from predicates import final_memory, invocation_creates
from structurecheck import canonical
from syntax import parse


def run(private, evidence, count=500):
    private.mkdir(parents=True, exist_ok=False)
    evidence.mkdir(parents=True, exist_ok=False)
    seed = secrets.randbits(128)
    (private / "seed.json").write_text(json.dumps(dict(seed=str(seed), count=count)) + "\n")
    report = dict(passed=False, cases=0, private=True, frozen=False,
                  missing=["candidate physical equality", "actual resumed/destroyed executions", "owner approval"])
    case = None
    try:
        with gzip.open(private / "cases.jsonl.gz", "wt") as output:
            for case in generate(seed, count):
                declarations, _, main = case["source"].rpartition("main = ")
                declarations += "def marker(flag: Bool): Int = if flag then 17 else -23 end end\n"
                if case["index"] % 2:
                    main = f"if even({case['index'] % 8}) then ({main}) else bump(({main})) end"
                else: main = f"({main}) + marker(even({case['index'] % 8}))"
                source = declarations + "main = " + main
                names = re.findall(r"\bdef ([A-Za-z_][A-Za-z_0-9]*)\(", declarations)
                rename = {name: f"helper{case['index']}_{i}" for i, name in enumerate(names)}
                pattern = r"\b(" + "|".join(names) + r")(?=\s*\()"
                case["source"] = re.sub(pattern, lambda m: rename[m[1]], source)
                acquired, answer, reference, bindings, outcome = predict(case)
                actual = tuple(map(int, outcome["value"][1])) if type(answer) is tuple else int(outcome["value"][1])
                assert actual == answer and type(actual) is type(answer), "independent answer"
                final_memory(outcome, case["outside"])
                invocation_creates(reference.events)
                case["expected"] = dict(answer=[str(x) for x in answer] if type(answer) is tuple else answer,
                                        bindings=bindings, canonical=canonical(parse(case["source"])),
                                        trace=reference.trace, events=reference.events)
                output.write(json.dumps(case) + "\n")
                report["cases"] += 1
        report["passed"] = True
    except Exception:
        # Details remain private; a failing case is not dropped or regenerated.
        (private / "failure.json").write_text(json.dumps(dict(case=case, error=traceback.format_exc()), indent=2) + "\n")
        report["error"] = "private preparation failed; retained private failure.json"
    path = private / "cases.jsonl.gz"
    if path.exists(): report["cases_sha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
    (evidence / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2)); return report["passed"]


def verify(private, evidence):
    """Preserve cases/predictions; add new control fields in a separate file."""
    evidence.mkdir(parents=True, exist_ok=False)
    target = private / "controls.jsonl.gz"
    assert not target.exists(), "never overwrite private evidence"
    report = dict(passed=False, cases=0, frozen=False, kind="same-private-cases-control-supplement")
    try:
        with gzip.open(private / "cases.jsonl.gz", "rt") as source, gzip.open(target, "wt") as output:
            for line in source:
                case = json.loads(line)
                program = parse(case["source"])
                validate_fixture(program, case["cells"], case["inputs"], case["outside"])
                acquired, answer, reference, bindings, outcome = predict(case)
                expected = case["expected"]
                assert expected["canonical"] == canonical(program)
                assert expected["bindings"] == {str(i): v for i, v in bindings.items()}
                assert expected["events"] == reference.events
                assert expected["answer"] == ([str(x) for x in answer] if type(answer) is tuple else answer)
                old_trace = [{k: v for k, v in t.items() if k not in ("control", "ready", "release")} for t in reference.trace]
                assert expected["trace"] == old_trace, "private predictions changed"
                final_memory(outcome, case["outside"])
                output.write(json.dumps(dict(index=case["index"], trace=reference.trace)) + "\n")
                report["cases"] += 1
        assert report["cases"] == 500
        report["passed"] = True
    except Exception:
        (private / "verify-failure.txt").write_text(traceback.format_exc())
        report["error"] = "retained private verify-failure.txt"
    report["cases_sha256"] = hashlib.sha256((private / "cases.jsonl.gz").read_bytes()).hexdigest()
    report["control_sha256"] = hashlib.sha256(target.read_bytes()).hexdigest()
    (evidence / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2)); return report["passed"]


if __name__ == "__main__":
    action = verify if len(sys.argv) > 3 and sys.argv[3] == "verify" else run
    sys.exit(not action(Path(sys.argv[1]), Path(sys.argv[2])))
