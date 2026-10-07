"""Destroy-state predicates, independently derived from outside roots/edges.

No reference destroy evaluator is implemented. Generated valid post-states below
exercise predicates only; future native destruction must supply real observations.
"""
from collections import Counter
from copy import deepcopy
import json
from pathlib import Path
import sys
import traceback

from cases import examples
from predicates import walk
from syntax import parse
from transition_reference import TransitionReference


def outside_graph(before):
    reachable = set()
    for root in before["outside"]: reachable.update(walk(before["memory"], root)[1])
    cells = [deepcopy(c) for c in before["memory"] if c[0] in reachable]
    counts = Counter(r for r in before["outside"] if r is not None)
    counts.update(c[2] for c in cells if c[2] is not None)
    for c in cells: c[3] = counts[c[0]]
    return cells


def check_destroy(before, after, events, before_pointers, after_pointers):
    expected = outside_graph(before)
    assert after["memory"] == expected, "destroy outside graph/counts"
    assert after["outside"] == before["outside"], "destroy outside roots"
    assert not after["pending"] and not after["aside"] and not after["frames"], "destroy live state"
    assert all(b[3] != "holding" for b in after["bindings"]), "destroy binding holder"
    remain = {c[0] for c in expected}
    freed = {c[0] for c in before["memory"]} - remain
    assert all(e[0] == "free" for e in events), "destroy created/wrote cells"
    assert len(events) == len(freed) and {e[1] for e in events} == freed, "destroy free set/duplicate"
    assert set(after_pointers) == remain, "destroy physical leak"
    assert all(after_pointers[i] == before_pointers[i] for i in remain), "destroy outside identity"


def run(destination):
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, boundaries=0, controls={}, real_destroy_executed=False)
    try:
        for case in examples():
            program = parse(case["source"])
            reference = TransitionReference(program, case["cells"], case["inputs"], case["outside"], landmark_limit=60 if case["value"] is None else 10000)
            reference.observe(program["main"])
            for trace in reference.trace:
                before = trace["state"]
                cells = outside_graph(before)
                after = dict(memory=cells, outside=before["outside"], pending=[], aside=[], frames=[], bindings=[])
                pointers = {c[0]: 4096 + 64 * c[0] for c in before["memory"]}
                after_pointers = {c[0]: pointers[c[0]] for c in cells}
                events = [["free", i] for i in pointers if i not in after_pointers]
                check_destroy(before, after, events, pointers, after_pointers)
                check_destroy(after, after, [], after_pointers, after_pointers)
                report["boundaries"] += 1
        before = dict(memory=[[1, "3", 2, 1, "live"], [2, "7", None, 2, "live"]], outside=[2])
        good = dict(memory=[[2, "7", None, 1, "live"]], outside=[2], pending=[], aside=[], frames=[], bindings=[])
        for name, after, events, pointers in [
            ("leak", dict(good, memory=before["memory"]), [["free", 1]], {2: 8192}),
            ("double-free", good, [["free", 1], ["free", 1]], {2: 8192}),
            ("outside-replaced", good, [["free", 1]], {2: 16384}),
            ("lost-outside", dict(good, memory=[]), [["free", 1], ["free", 2]], {}),
        ]:
            try: check_destroy(before, after, events, {1: 4096, 2: 8192}, pointers)
            except AssertionError as error: report["controls"][name] = str(error)
            else: raise AssertionError("broken cleanup accepted: " + name)
        assert report["controls"] == {"leak": "destroy outside graph/counts", "double-free": "destroy free set/duplicate",
                                     "outside-replaced": "destroy outside identity", "lost-outside": "destroy outside graph/counts"}
        report["passed"] = True
    except Exception: report["error"] = traceback.format_exc()
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2)); return report["passed"]


if __name__ == "__main__": sys.exit(not run(Path(sys.argv[1])))
