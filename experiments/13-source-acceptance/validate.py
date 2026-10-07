"""Preparation validation only. Stops and saves evidence on the first mismatch."""
import gzip
import hashlib
import json
from collections import Counter
from pathlib import Path
import sys
import traceback

from finite_reference import decode, FiniteReference
from syntax import parse, check, pretty

ROOT = Path(__file__).resolve().parent
CORPUS = ROOT.parent / "10-finite-rust/evidence/expected.jsonl.gz"


def run(destination):
    destination.mkdir(parents=True, exist_ok=False)
    summary = dict(status="preparation-only", passed=False, cases=0, snapshots=0,
                   corpus_sha256=hashlib.sha256(CORPUS.read_bytes()).hexdigest(),
                   missing_coverage=["Stage B reference/predictions/checks",
                       "physical implementation and every resume/destroy join",
                       "held-out/generated layer", "million-depth execution",
                       "owner-approved detailed rules and scientific lock"])
    kinds, transitions = Counter(), Counter()
    try:
        old_lock = json.loads((CORPUS.parents[1] / "LOCK.json").read_text())
        assert summary["corpus_sha256"] == old_lock["frozen"]["evidence/expected.jsonl.gz"]
        for line in gzip.open(CORPUS, "rt"):
            case = json.loads(line)
            expr, cells, inputs, outside = decode(case["input"])
            source = "".join(f"input {n}: {'ListInt' if v[0] == 'l' else 'Int'};\n" for n, v in inputs)
            source += "main = " + pretty(expr)
            parsed = parse(source)
            assert parsed["main"] == expr, "source structural round-trip"
            check(parsed, "A")
            reference = FiniteReference(cells, inputs, outside)
            actual = reference.run(parsed["main"])
            expected = case["expected"]
            try:
                for field in expected:
                    assert actual[field] == expected[field], f"historical mismatch: {field}"
            except AssertionError:
                witness = dict(case=case, source=source, actual=actual,
                               transitions=reference.transitions)
                (destination / "counterexample.json").write_text(json.dumps(witness, indent=2) + "\n")
                raise
            summary["cases"] += 1
            summary["snapshots"] += len(actual["states"])
            kinds.update(s["kind"] for s in actual["states"])
            transitions.update(reference.transitions)
        assert summary["cases"] == 4276 and summary["snapshots"] == 27721
        summary["passed"] = True
    except Exception:
        summary["error"] = traceback.format_exc()
    summary["snapshot_kinds"] = dict(kinds)
    summary["reference_landmark_transitions"] = dict(transitions)
    (destination / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps(summary, indent=2))
    return summary["passed"]


if __name__ == "__main__":
    sys.exit(not run(Path(sys.argv[1])))
