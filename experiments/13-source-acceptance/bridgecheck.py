"""Acceptance-owned full-state bridge, tested with a native storage/trace stub.

No Mo evaluator is implemented. Candidate-linked execution remains a later gate.
Observer rows must be acquired by acceptance, never from candidate pointer JSON.
"""
from copy import deepcopy
import json
from pathlib import Path
import subprocess
import sys
import traceback

from cleanupcheck import check_destroy
from observationcheck import check_bundle
from predicates import physical_events
from acquisitioncheck import predict
from structurecheck import canonical
from syntax import parse


def check_checked(source, actual):
    expected = canonical(parse(source))
    assert json.dumps(actual, sort_keys=True) == json.dumps(expected, sort_keys=True), "checked structure/resolution"


class Normalizer:
    def __init__(self, identities):
        self.maps = {k: {} for k in ("cell", "binding", "branch", "frame")}
        for domain, pairs in identities.items():
            for raw, canonical in pairs: self.birth(domain, raw, canonical)

    def birth(self, domain, raw, canonical):
        assert type(raw) in (str, int) and type(canonical) is int, "identity kind"
        assert raw not in self.maps[domain], "identity rebirth"
        assert canonical not in self.maps[domain].values(), "aliased normalization"
        self.maps[domain][raw] = canonical

    def ident(self, domain, raw):
        assert type(raw) in (str, int), "identity kind"
        assert raw in self.maps[domain], "unregistered identity"
        return self.maps[domain][raw]

    def cell(self, raw):
        return None if raw is None else self.ident("cell", raw)

    def value(self, value):
        return ["l", self.cell(value[1])] if value and value[0] == "l" else deepcopy(value)

    def memory(self, rows):
        converted = [[self.cell(i), item, self.cell(tail), count, status] for i, item, tail, count, status in rows]
        order = list(self.maps["cell"].values())
        return sorted(converted, key=lambda c: order.index(c[0]))

    def events(self, events):
        result = []
        for e in events:
            if e[0] == "enter": result.append(["enter", self.ident("frame", e[1]), self.ident("frame", e[2]), e[3]])
            elif e[0] == "return": result.append(["return", self.ident("frame", e[1])])
            else:
                assert e[0] in ("create", "write", "free"), "event kind"
                result.append([e[0], self.cell(e[1])])
        return result

    def state(self, raw, actual_graph):
        result = deepcopy(raw)
        reported = self.memory(raw["memory"])
        result["memory"] = self.memory([row[:5] for row in actual_graph])
        assert json.dumps(reported) == json.dumps(result["memory"]), "reported/actual physical graph"
        result["bindings"] = [[self.ident("binding", i), n, self.value(v), status] for i, n, v, status in raw["bindings"]]
        result["pending"] = [self.value(v) for v in raw["pending"]]
        result["outside"] = [self.cell(r) for r in raw["outside"]]
        result["aside"] = [[self.ident("branch", b), self.cell(c)] for b, c in raw["aside"]]
        result["branch"] = self.value(raw["branch"])
        result["frames"] = [self.ident("frame", f) for f in raw["frames"]]
        return result

    def transition(self, raw, actual_graph):
        result = deepcopy(raw); result["state"] = self.state(raw["state"], actual_graph)
        result["ready"] = self.value(raw["ready"])
        result["release"] = [self.cell(c) for c in raw["release"]]
        for item in result["control"]:
            item["scope"] = [[name, self.ident("binding", i)] for name, i in item["scope"]]
            item["invocation"] = self.ident("frame", item["invocation"])
            item["operands"] = [self.value(v) for v in item["operands"]]
        return result


def collect(raw, native, identities):
    """Bridge input: raw execution dumps, separately acquired observer records.

    IDs are paired by acceptance-known fixture roots and ordered birth registries,
    never independently remapped at each snapshot. A linked driver must extend
    these registries as actual births occur and retain retired IDs forever.
    """
    norm = Normalizer(identities)
    assert len(native) == len(raw["trace"]) + 3, "native observation coverage"
    trace = [norm.transition(t, n["graph"]) for t, n in zip(raw["trace"], native[1:])]
    events = norm.events(raw["events"])
    initial = norm.memory([row[:5] for row in native[0]["graph"]])
    for transition, observed in zip(trace, native[1:]):
        prefix = [e for e in events[:transition["event_end"]] if e[0] in ("create", "write", "free")]
        stream = [[kind, norm.cell(c), ptr] for kind, c, ptr in observed["physical"]]
        live = physical_events(initial, stream, prefix, transition["state"]["memory"])
        assert live == {norm.cell(row[0]): row[5] for row in observed["graph"]}, "physical graph/event continuity"
    outcome = deepcopy(raw["outcome"])
    outcome["answer"] = norm.value(outcome["answer"])
    assert json.dumps(norm.memory(outcome["memory"])) == json.dumps(trace[-1]["state"]["memory"]), "reported/actual final physical graph"
    outcome["memory"] = trace[-1]["state"]["memory"]
    outcome["states"] = [t["state"] for t in trace if t["landmark"] is not None]
    outcome["record"] = norm.events(outcome["record"]); outcome["log"] = norm.events(outcome["log"])
    physical = [[kind, norm.cell(c), ptr] for kind, c, ptr in native[len(trace)]["physical"]]
    pointers = lambda graph: {str(norm.cell(row[0])): row[5] for row in graph}
    bundle = dict(trace=trace, events=norm.events(raw["events"]), outcome=outcome, physical=physical,
                  resumes=[dict(boundary=0, before_live=pointers(native[0]["graph"]),
                                after_resume_live=pointers(native[1]["graph"]), prefix_before=[], prefix_after=[])])
    return norm, bundle


def fixture_stub():
    # Hand-authored three-step shape for main=xs: start; move the input holder;
    # finish. The Rust probe supplies actual allocated contents independently.
    memory = [[41, "3", None, 1, "live"]]
    states, trace = [], []
    for i, (kind, action) in enumerate([( "start", "Start"), ("holderMoved", "Leaf"), ("end", "Finish")]):
        state = dict(kind=kind, memory=memory, bindings=[[901, "xs", ["l", 41], "holding" if i == 0 else "movedOn"]],
                     pending=[] if i == 0 else [["l", 41]], outside=[], aside=[], branch=None, frames=[])
        states.append(state)
        control = [dict(site="main", scope=[["xs", 901]], invocation=0, operands=[])] if i == 1 else []
        trace.append(dict(step=i + 1, transition=action, site="main" if i == 1 else "root", event_end=0,
                          landmark=i, state=state, control=control, ready=None if i == 0 else ["l", 41], release=[]))
    return dict(trace=trace, events=[], outcome=dict(answer=["l", 41], value=["l", ["3"]], memory=memory,
                                                   states=states, record=[], log=[]))


def run(destination):
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, native_stub=0, controls={}, candidate_executed=False)
    try:
        command = ["cargo", "run", "--quiet", "--locked", "--manifest-path", "cells/Cargo.toml", "--example", "bridge_probe"]
        def acquire(bad=False):
            process = subprocess.run(command + (["--", "--corrupt-physical-value"] if bad else []), capture_output=True, text=True)
            (destination / ("bad-native.txt" if bad else "native.txt")).write_text(process.stdout + process.stderr)
            assert process.returncode == 0, "native probe execution"
            return [json.loads(line) for line in process.stdout.splitlines()]
        native = acquire()
        raw = fixture_stub()
        identities = dict(cell=[(41, 7)], binding=[(901, 0)], branch=[], frame=[(0, 0)])
        norm, bundle = collect(raw, native, identities)
        case = dict(source="input xs: ListInt; main = xs", cells=[[7, "3", None, 1, "live"]], inputs=[("xs", ["l", 7])], outside=[])
        check_bundle(case, bundle, [0]); report["native_stub"] += 1
        wrong_kind = deepcopy(bundle); wrong_kind["trace"][0]["step"] = True
        try: check_bundle(case, wrong_kind, [0])
        except AssertionError as error: assert str(error) == "committed state/action/event prefix"; report["controls"]["Boolean-step"] = str(error)
        else: raise AssertionError("Boolean numeric step accepted")
        before = bundle["trace"][-1]["state"]
        after = dict(memory=[], bindings=[], pending=[], outside=[], aside=[], frames=[])
        cleanup = native[4]["physical"][len(native[3]["physical"]):]
        check_destroy(before, after, norm.events([[kind, c] for kind, c, _ in cleanup]), {7: native[3]["graph"][0][5]}, {})
        assert native[4]["graph"] == native[5]["graph"] == [] and native[4]["physical"] == native[5]["physical"]
        # Deliberately inconsistent candidate shadow dump versus REAL Rust cell.
        try: collect(raw, acquire(True), identities)
        except AssertionError as error: assert str(error) == "reported/actual physical graph"; report["controls"]["shadow"] = str(error)
        else: raise AssertionError("shadow contents accepted")
        replaced = deepcopy(native); replaced[2]["graph"][0][5] += 64
        try: collect(raw, replaced, identities)
        except AssertionError as error: assert str(error) == "physical graph/event continuity"; report["controls"]["intermediate-replacement"] = str(error)
        else: raise AssertionError("intermediate replacement accepted")
        for name, domain, opaque, canonical_id in [("rebirth", "cell", 41, 8), ("alias", "binding", 902, 0)]:
            try: norm.birth(domain, opaque, canonical_id)
            except AssertionError as error: report["controls"][name] = str(error)
            else: raise AssertionError("bad identity correspondence accepted")
        # Exercise all identity-bearing fields, not just the baseline's cells.
        n = Normalizer(dict(cell=[(81, 2)], binding=[(82, 3)], branch=[(83, 4)], frame=[(84, 5), (85, 0)]))
        sample = deepcopy(raw["trace"][1]); sample["state"].update(memory=[[81, "9", None, 0, "aside"]],
            bindings=[[82, "h", ["n", "9"], "noHolder"]], pending=[], aside=[[83, 81]], frames=[84], branch=["l", 81])
        sample.update(ready=["l", 81], release=[81], control=[dict(site="main", scope=[["h", 82]], invocation=84, operands=[["l", 81]])])
        translated = n.transition(sample, [[81, "9", None, 0, "aside", 4096]])
        assert translated["state"]["aside"] == [[4, 2]] and translated["state"]["frames"] == [5]
        assert translated["ready"] == ["l", 2] and translated["release"] == [2]
        assert translated["control"] == [dict(site="main", scope=[["h", 3]], invocation=5, operands=[["l", 2]])]
        assert n.events([["enter", 84, 85, "f"], ["return", 84], ["free", 81]]) == [["enter", 5, 0, "f"], ["return", 5], ["free", 2]]
        acquired, answer, _, _, outcome = predict(dict(source="input n: Int; main = n + 1", cells=[], inputs=[("n", ["n", "-3"])], outside=[]))
        assert acquired == {0: -3} and answer == -2 and outcome["value"] == ["n", "-2"]
        source = "main = let x = 7 in let x = 11 in x"
        checked = canonical(parse(source)); check_checked(source, checked)
        checked["main"]["children"][1]["children"][1]["binding"] = "main/binding"
        try: check_checked(source, checked)
        except AssertionError as error: report["controls"]["wrong-checked-scope"] = str(error)
        else: raise AssertionError("wrong checked scope accepted")
        report["passed"] = True
    except Exception: report["error"] = traceback.format_exc()
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2)); return report["passed"]


if __name__ == "__main__": sys.exit(not run(Path(sys.argv[1])))
