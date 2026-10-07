"""Validate all proposed trace-to-landmark projections against the old corpus.

Reads expected fields only after prediction. Extra empty root-frame metadata is
the ONLY new state field removed by this Stage A projection; none of the frozen
fields/kinds is omitted. Successful per-case traces are retained losslessly.
"""
import gzip
import hashlib
import json
from pathlib import Path
import sys
import traceback

from finite_reference import decode
from predicates import protection
from syntax import check, parse, pretty
from transition_reference import TransitionReference, trace_projection
from validate import CORPUS


def run(destination):
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, cases=0, snapshots=0, transitions=0,
                  corpus_sha256=hashlib.sha256(CORPUS.read_bytes()).hexdigest(),
                  missing=["candidate/physical instrumentation", "full control/operand-slot state",
                           "independent acquisition-value predictions"])
    witness = None
    try:
        lock = json.loads((CORPUS.parents[1] / "LOCK.json").read_text())
        assert report["corpus_sha256"] == lock["frozen"]["evidence/expected.jsonl.gz"]
        with gzip.open(CORPUS, "rt") as stream, gzip.open(destination / "per-case.jsonl.gz", "wt") as output:
            for line in stream:
                case = json.loads(line)
                expr, cells, inputs, outside = decode(case["input"])
                source = "".join(f"input {n}: {'ListInt' if v[0] == 'l' else 'Int'};\n" for n, v in inputs) + "main = " + pretty(expr)
                program = parse(source); check(program, "A")
                assert program["main"] == expr
                reference = TransitionReference(program, cells, inputs, outside, landmark_limit=100000)
                actual = reference.run(program["main"])
                trace_projection(reference)
                protection([t["state"] for t in reference.trace], cells, outside)
                assert all(s["frames"] == [] for s in actual["states"])
                assert reference.events == actual["record"]  # no synthetic main invocation
                projected = dict(actual)
                projected["states"] = [{k: v for k, v in s.items() if k != "frames"} for s in actual["states"]]
                witness = dict(id=case["id"], source=source, trace=reference.trace,
                               actual=projected, expected=case["expected"])
                for field, value in case["expected"].items():
                    assert projected[field] == value, (case["id"], field)
                output.write(json.dumps(dict(id=case["id"], source=source, checked_fields=list(case["expected"]),
                            trace=reference.trace, events=reference.events)) + "\n")
                report["cases"] += 1; report["snapshots"] += len(reference.states)
                report["transitions"] += len(reference.trace)
        assert report["cases"] == 4276 and report["snapshots"] == 27721
        report["passed"] = True
    except Exception:
        report["error"] = traceback.format_exc()
        (destination / "counterexample.json").write_text(json.dumps(witness, indent=2) + "\n")
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return report["passed"]


if __name__ == "__main__": sys.exit(not run(Path(sys.argv[1])))
