#!/usr/bin/env python3
"""Read-only expanded-export checks; never execute a language machine.

Uses the unchanged v1 assertion library on a documented field projection, then
checks the newly supplied fields separately. All expectations are checkpoint
data, handwritten call trees, or rule-derived boundary assertions.
"""
import argparse
import copy
import hashlib
import importlib.util
import json
import re
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("prior", HERE.parent / "supplemental/boundary_check.py")
prior = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prior)
eq, require, ROWS, fx = prior.eq, prior.require, prior.ROWS, prior.fx
BASE = "steps cells events outside bindings visibleBindings slots holders requiredBindings decodedPlain release memoryOperations frames reservations actions tasks".split()
STATE = BASE + ["status", "raw", "rank", "consContext"]


def load(path):
    return json.loads(path.read_text(), object_pairs_hook=fx.unique_object)


def project(s, keys=BASE):
    return {key: s[key] for key in keys}


def repr_tokens(text):
    # Lean wraps Except.ok payloads at a different pretty-print indentation.
    # Ignore whitespace outside strings only; retain names/string contents.
    return re.findall(r'"(?:\\.|[^"\\])*"|[^\s"]+', text)


def legacy(o):
    """Drop only added export fields, never existing evidence or steps."""
    p = dict(o)
    p["state"] = project(o["state"])
    p["trace"] = [project(s) for s in o["trace"]]
    p["destroyed"] = project(o["destroyed"])
    p["resumes"] = [[{"budget": s["budget"], "total": s["total"],
                      "split": project(s["split"]), "whole": project(s["whole"])}
                     for s in group] for group in o["resumes"]]
    return p


def exact_input(row, inp):
    start = fx.STARTS[row[2]]
    expected = {
        "cells": [[prior.addr(a), n, prior.addr(t), count] for a, n, t, count in start["cells"]],
        "inputs": [[n, k, prior.addr(v) if k == "L" else v] for n, k, v in start["inputs"]],
        "outside": [prior.addr(a) for a in start["outside"]],
    }
    eq([inp["main"], inp["start"], inp["functions"]],
       [row[3], expected, [[n, *decl, n in row[4]] for n, decl in fx.function_table(row[3]).items()]],
       "exact checkpoint inputs")
    eq(inp["trace"], True, "all cases traced")


def begun(row, o):
    s = o["trace"][0]
    initial = fx.STARTS[row[2]]
    eq(s["cells"], [[prior.addr(a), n, prior.addr(t), count, "live"] for a, n, t, count in initial["cells"]])
    for key in ("slots", "frames", "reservations", "events", "actions", "memoryOperations", "release"):
        eq(s[key], [], "begun " + key)
    eq(s["steps"], 0)
    eq(s["status"], "suspended")
    eq(s["raw"], None)
    graph = {prior.addr(a): (n, prior.addr(t)) for a, n, t, _ in initial["cells"]}
    expected = []
    for i, (name, kind, value) in enumerate(initial["inputs"]):
        raw = [kind, prior.addr(value) if kind == "L" else value]
        plain = fx.walk(graph, raw[1])[1] if kind == "L" else value
        status = prior.HOLD if kind == "L" and value is not None else "Trial.BStatus.noHolder"
        expected.append([i, name, raw, status, plain, 0, "main/input/" + name])
    eq(s["bindings"], expected, "begun identity/value associations")


def required(s):
    """Check supplied obligations; these IDs are NOT independently generated."""
    bindings = {b[0]: b for b in s["bindings"]}
    for bid, value in s["requiredBindings"]:
        require(bid in bindings, "required binding absent")
        b = bindings[bid]
        eq(b[4], value, "required binding immutable association")
        if b[2][0] == "L" and b[2][1] is not None:
            eq(b[3], prior.HOLD, "required owner cannot be marked dead")
        eq(prior.read(s, b[2]), value, "required value readable")
    eq(s["visibleBindings"], sorted(set(s["visibleBindings"])), "visible acquisition order")
    require(all(b[0] in s["visibleBindings"] for b in s["bindings"] if b[3] == prior.HOLD),
            "suspended holding binding omitted from visible view")


def source_at(row, site):
    name, *path = site.split("/")
    expr = row[3] if name == "main" else fx.FUNCTIONS[name][2]
    for index in path:
        op = expr[0]
        children = expr[2:] if op in ("call", "let") else [expr[1], expr[2], expr[5]] if op == "match" else expr[1:]
        expr = children[int(index)]
    return expr


def plain_and_internal(row, o):
    trace = o["trace"]
    require(bool(trace), "trace missing")
    eq(project(trace[-1], STATE), project(o["state"], STATE), "trace endpoint")
    require(trace[0]["decodedPlain"].startswith("Except.ok "), "initial decode failed")
    carried = trace[0]["decodedPlain"][len("Except.ok "):]
    plain_steps = 0
    counts = Counter()
    for s in trace:
        required(s)
        require(type(s["rank"]) is int and s["rank"] >= 0, "natural administrative rank")
    for before, after in zip(trace, trace[1:]):
        eq(repr_tokens(after["plainBefore"]), repr_tokens(carried), "Plain carrier cannot reset to decode")
        eq(after["decodedState"], after["independentPlain"], "independent Plain vs decode")
        eq(repr_tokens(after["decodedPlain"]), repr_tokens("Except.ok " + after["independentPlain"]), "decoded projections agree")
        eq(after["rankBefore"], before["rank"], "rank source")
        kind = after["correspondence"]
        counts[kind] += 1
        if kind == "denial":
            eq(repr_tokens(after["independentPlain"]), repr_tokens(carried), "denial does not step Plain")
            eq(after["internal"], None, "denial has no transfer boundary")
            eq(project(after, STATE), project(before, STATE), "denial state unchanged")
            require(after is trace[-1] and o["status"] == "failed", "denial only at failure")
        else:
            require(kind in ("step", "stutter"), "unknown correspondence")
            eq(after["denialBefore"], None)
            eq(after["denialAfter"], None)
            if kind == "step":
                require(repr_tokens(after["independentPlain"]) != repr_tokens(carried), "step mislabeled stutter")
                eq(after["independentPlain"], after["plainNext"], "exactly one independent Plain step")
                plain_steps += 1
            else:
                eq(repr_tokens(after["independentPlain"]), repr_tokens(carried), "stutter changed Plain")
                require(after["rank"] < before["rank"], "stutter must strictly decrease rank")
            internal = after["internal"]
            require(isinstance(internal, dict), "missing pre-commit boundary")
            # Ownership/control/effects are installed before the metadata commit.
            # Do not pretend history or action count has already advanced there.
            eq(internal["steps"], before["steps"], "pre-commit count")
            eq(internal["actions"], before["actions"], "pre-commit history")
            eq({k: internal[k] for k in STATE if k not in ("steps", "actions")},
               {k: after[k] for k in STATE if k not in ("steps", "actions")},
               "metadata commit must preserve all exported semantic fields")
            required(internal)
            # v1 labels answer holders by committed Finish history. Install only
            # that metadata in a COPY for v1; all ownership fields are original.
            checkable = project(internal)
            checkable["steps"], checkable["actions"] = after["steps"], after["actions"]
            prior.snapshot(row, checkable)
        eq(after["plainPrefixSteps"], plain_steps, "cumulative independent Plain steps")
        carried = after["independentPlain"]
    return dict(counts)


def reservations(row, o):
    """Reconstruct only branch lifetimes from observed action boundaries.

    This is an acceptance monitor, not a source evaluator or demand checker.
    Match IDs follow the checkpoint's Choose order (empty branches included).
    The tracked lexical stack, not the exporter-provided eligible set, selects
    reservations for each Cons. Every expected cell payload remains checkpointed.
    """
    branches, next_branch = {0: []}, 0
    created = 0
    fresh = max((prior.addr(c[0]) for c in fx.STARTS[row[2]]["cells"]), default=-1) + 1
    count, multi = 0, 0
    for before, after in zip(o["trace"], o["trace"][1:]):
        if after["correspondence"] == "denial":
            continue
        owner = before["frames"][0][0] if before["frames"] else 0
        head = before["tasks"]
        delta = after["events"][len(before["events"]):]
        if head.startswith("[Full.Counted.Task.chooseMatch"):
            branches[owner].append(next_branch)
            next_branch += 1
        if head.startswith("[Full.Counted.Task.handoffMatch"):
            require(bool(branches[owner]), "handoff without match branch")
            branches[owner].pop()
        for e in delta:
            if e[0] == "E": branches[e[2]] = []
            elif e[0] == "R":
                eq(branches[e[1]], [], "Return with active lexical branch")
                del branches[e[1]]
        ctx = before["consContext"]
        if ctx is not None:
            eq(ctx["invocation"], owner, "Cons executing invocation")
            eq(ctx["branches"], list(reversed(branches[owner])), "Cons active lexical branches")
            eq(ctx["site"].split("/")[0], before["frames"][0][1] if before["frames"] else "main", "Cons source function")
            eq(source_at(row, ctx["site"])[0], "cons", "Cons source site")
            eligible = [r for r in before["reservations"] if r[0] == owner and r[1] in branches[owner]]
            count += 1
            multi += len(eligible) > 1
            tail, h = before["slots"][:2]
            eq([h[0][0], tail[0][0]], ["I", "L"], "Cons operand kinds")
            if eligible:
                newest = max(eligible, key=lambda r: r[1])
                expected = ["W", newest[2], h[0][1], tail[0][1]]
            else:
                expected = ["C", fresh + created, h[0][1], tail[0][1]]
            eq(delta, [expected], "newest same-invocation active-branch Cons effect")
            eq(prior.read(after, ["L", expected[1]]), [h[1]] + tail[1], "Cons immutable list value")
        elif any(e[0] in ("C", "W") for e in delta):
            raise ValueError("construction without Cons context")
        created += sum(e[0] == "C" for e in delta)
        for inv, bid, _ in after["reservations"]:
            require(inv in branches and bid in branches[inv], "reservation outside owning branch lifetime")
    return {"cons": count, "multipleEligible": multi}


def full_resume(cid, o):
    expected = ([[0], [17], [18], [23], [6, 6, 3, 2, 1], [0, 6, 0, 11, 0, 1],
                 [17, 1], [18, 0, 1, 23]] if cid == "C19" else [[29, 4]])
    eq([[s["budget"] for s in g] for g in o["resumes"]], expected, "exact requested segments")
    for group in o["resumes"]:
        total = 0
        for entry in group:
            total += entry["budget"]
            eq(entry["total"], total)
            require(bool(entry["split"]["completeState"]), "full resume state absent")
            for key in ("whole", "observation1", "observation2", "afterObservation"):
                eq(entry[key], entry["split"], "full state/observer equality: " + key)
            s = entry["split"]
            if cid == "C19":
                eq(s["steps"], min(18, total))
                eq(s["status"], "finished" if total >= 18 else "suspended")
                eq(s["raw"], ["L", 0] if total >= 18 else None)
                eq(project(s, STATE), project(o["trace"][min(total, 18)], STATE))
            else:
                eq(s["steps"], total)
                eq(s["status"], "suspended")
                eq(s["raw"], None)
                n = 7 if total == 29 else 8
                eq(s["events"], [["E", "spin", i, i-1, [["I", 0]], "main" if i == 1 else "spin"] for i in range(1, n+1)])
                eq(s["frames"], [[i, "spin", i-1] for i in range(n, 0, -1)])
                for key in ("cells", "slots", "holders", "reservations", "release", "memoryOperations"):
                    eq(s[key], [], "spin finite prefix " + key)
                eq([b[2:5] for b in s["bindings"]], [[["I", 0], "Trial.BStatus.noHolder", 0]] * n)
                if total == 33:
                    eq(s["actions"], o["state"]["actions"] + ["Dispatch", "Leaf", "Capture", "Enter"])


def double_destroy(row, before, first, second):
    require(bool(first["completeState"]), "first complete lifecycle missing")
    eq(second, first, "actual second destruction must be fully idempotent")
    eq(before["destroyed"], False)
    eq(first["destroyed"], True)
    for key in ("failure", "requests"):
        eq(first[key], before[key], "destruction retains lifecycle " + key)
    eq(first["execution"]["raw"], None, "destroy removes answer")
    synthetic = {"state": before["execution"], "destroyed": first["execution"],
                 "cleanup": first["cleanup"][len(before["cleanup"]):], "destroyTwiceEqual": True}
    prior.lifecycle(row, synthetic)
    eq(first["cleanup"][:len(before["cleanup"])], before["cleanup"], "cleanup append-only")


def destruction(row, o):
    eq(o["lifecycle"]["execution"], o["state"])
    eq(o["destroyFirst"]["execution"], o["destroyed"])
    eq(o["destroyFirst"]["cleanup"], o["cleanup"])
    double_destroy(row, o["lifecycle"], o["destroyFirst"], o["destroySecond"])


def cleanup_cuts(o):
    eq([c["cut"] for c in o["cutChecks"]], [5, 6, 7, 8])
    for entry in o["cutChecks"]:
        cut = entry["cut"]
        before = entry["before"]["execution"]
        eq(project(before, STATE), project(o["trace"][cut], STATE), "exact paused cleanup cut")
        eq(entry["resumed"], entry["whole"], "full resumed state equals uninterrupted")
        eq(entry["resumed"], o["state"], "resume reaches checkpoint final state")
        eq(entry["resumed"]["events"][len(before["events"]):], [["F", 0], ["F", 1]] if cut == 5 else [["F", 1]] if cut < 8 else [])
        double_destroy(ROWS["C16"], entry["before"], entry["destroyFirst"], entry["destroySecond"])
        eq(entry["destroyFirst"]["cleanup"], [0, 1] if cut == 5 else [1] if cut < 8 else [], "cleanup-only remaining frees")
        eq(entry["destroyFirst"]["execution"]["events"], before["events"])


def full_denial(raw):
    accepted = [["Full.Lifecycle.Domain.frame", "outerFail"],
                ["Full.Lifecycle.Domain.number", "outerFail/1/0"],
                ["Full.Lifecycle.Domain.frame", "one"],
                ["Full.Lifecycle.Domain.cell", "one"],
                ["Full.Lifecycle.Domain.frame", "choose"]]
    for cid, n in (("C20-number", 1), ("C20-frame", 2), ("C20-create", 3)):
        o = raw[cid]
        s = o["trace"][-1]
        before, after = s["denialBefore"], s["denialAfter"]
        require(bool(before["execution"]["completeState"]), "full pre-denial execution absent")
        eq(before["execution"], after["execution"], "denial preserves complete execution")
        eq(after, o["lifecycle"], "denial is final exported lifecycle")
        eq(before["failure"], None)
        for key in ("requests", "cleanup", "destroyed"):
            eq(after[key], before[key], "denial changes only failure")
        eq(after["requests"], accepted[:n], "source-derived admitted requests")
        domain, site = accepted[n]
        eq(after["failure"], {"domain": domain, "site": site, "ordinal": 1,
                               "abort": [[2, "one"], [1, "outerFail"]] if n == 3 else [[1, "outerFail"]]})
        eq(sum(request == [domain, site] for request in before["requests"]) + 1, 1)
    eq(raw["C20-control"]["lifecycle"]["requests"], accepted)
    eq(raw["C20-control"]["lifecycle"]["failure"], None)


def corrupt_newest(o):
    for before, after in zip(o["trace"], o["trace"][1:]):
        ctx = before["consContext"]
        if ctx is None:
            continue
        eligible = [r for r in before["reservations"] if r[0] == ctx["invocation"] and r[1] in ctx["branches"]]
        if len(eligible) > 1:
            after["events"][-1][1] = min(eligible, key=lambda r: r[1])[2]
            return
    raise ValueError("negative control did not reach multiple eligible reservations")


def corrupt_pause_evaluation(o):
    # Keep the two destroy outputs mutually equal: the rejection must check
    # separation from the pre-destroy evaluation stream, not mere idempotence.
    for key in ("destroyFirst", "destroySecond"):
        o["cutChecks"][0][key]["execution"]["events"].append(["F", 0])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("observations", type=Path)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    raw = load(args.observations / "raw.json")
    inputs = load(args.observations / "inputs.json")
    expected = load(HERE / "expected-events.json")
    old = {cid: legacy(o) for cid, o in raw.items()}
    results, details, negatives = [], {}, []

    def test(name, function):
        try:
            value = function()
            results.append({"name": name, "status": "PASS"})
            if value is not None: details[name] = value
        except (ValueError, KeyError, IndexError, TypeError, StopIteration) as error:
            results.append({"name": name, "status": "FAIL", "detail": str(error)})

    test("exact case sets", lambda: eq([sorted(raw), sorted(expected), sorted(i["id"] for i in inputs)], [sorted(ROWS)] * 3))
    for inp in inputs:
        test(inp["id"] + " input", lambda inp=inp: exact_input(ROWS[inp["id"]], inp))
    for cid, row in ROWS.items():
        o, p = raw[cid], old[cid]
        test(cid + " begun", lambda row=row, o=o: begun(row, o))
        test(cid + " result", lambda row=row, p=p: prior.result(row, p))
        test(cid + " all committed snapshots", lambda row=row, p=p: prior.trajectory(row, p))
        test(cid + " complete predicted event history", lambda cid=cid, o=o: eq([e[:5] if e[0] == "E" else e for e in o["state"]["events"]], expected[cid]))
        test(cid + " demand accounting", lambda row=row, p=p: prior.accounting(row, p))
        test(cid + " independent Plain/internal", lambda row=row, o=o: plain_and_internal(row, o))
        test(cid + " newest eligible reservations", lambda row=row, o=o: reservations(row, o))
        test(cid + " actual double destroy", lambda row=row, o=o: destruction(row, o))
    for name, fn in [("selected source lifetimes", prior.selected), ("C16/C17 schedules", prior.cleanup_pauses),
                     ("finite prefixes", prior.finite_prefixes), ("original C19 cuts", prior.budget_checks),
                     ("original C20 operands", prior.denial_checks)]:
        test(name, lambda fn=fn: fn(old))
    test("C19 full resume and observations", lambda: full_resume("C19", raw["C19"]))
    test("C12 29+4", lambda: full_resume("C12", raw["C12"]))
    test("C16 paused resume/destroy", lambda: cleanup_cuts(raw["C16"]))
    test("C20 complete denial", lambda: full_denial(raw))

    def negative(label, cid, mutate, check):
        item = copy.deepcopy(raw[cid])
        mutate(item)
        try: check(item)
        except (ValueError, KeyError, IndexError, TypeError) as error:
            negatives.append({"name": label, "status": "REJECTED", "reason": str(error)[:3000]})
        else: negatives.append({"name": label, "status": "MISSED"})

    negative("reset independent Plain carrier", "C19", lambda o: o["trace"][2].__setitem__("plainBefore", "reset"), lambda o: plain_and_internal(ROWS["C19"], o))
    negative("nondecreasing stutter rank", "C19", lambda o: o["trace"][1].__setitem__("rank", o["trace"][0]["rank"]), lambda o: plain_and_internal(ROWS["C19"], o))
    negative("internal boundary loses slot", "C19", lambda o: o["trace"][12]["internal"].__setitem__("slots", []), lambda o: plain_and_internal(ROWS["C19"], o))
    negative("forged active branch list", "U-merge", lambda o: next(s for s in o["trace"] if s["consContext"])["consContext"].__setitem__("branches", []), lambda o: reservations(ROWS["U-merge"], o))
    negative("choose older eligible reservation", "U-merge", corrupt_newest, lambda o: reservations(ROWS["U-merge"], o))
    negative("changed hidden resume field", "C19", lambda o: o["resumes"][4][-1]["split"].__setitem__("completeState", "changed next ID"), lambda o: full_resume("C19", o))
    negative("observer changes state", "C19", lambda o: o["resumes"][0][0]["afterObservation"].__setitem__("steps", 1), lambda o: full_resume("C19", o))
    negative("second destroy appends duplicate free", "C14", lambda o: o["destroySecond"]["cleanup"].append(0), lambda o: destruction(ROWS["C14"], o))
    negative("pause destroy runs evaluation", "C16", corrupt_pause_evaluation, cleanup_cuts)
    negative("extra spin budget restarts", "C12", lambda o: o["resumes"][0][1]["split"].__setitem__("steps", 4), lambda o: full_resume("C12", o))
    negative("wrong usefulness call argument", "U-merge", lambda o: o["state"]["events"][0][4].__setitem__(0, ["L", 1]), lambda o: eq([e[:5] if e[0] == "E" else e for e in o["state"]["events"]], expected["U-merge"]))
    negative("denial mutates hidden state", "C20-number", lambda o: o["trace"][-1]["denialBefore"]["execution"].__setitem__("completeState", "changed"), lambda o: full_denial({**raw, "C20-number": o}))

    failed = [r for r in results if r["status"] == "FAIL"]
    missed = [r for r in negatives if r["status"] == "MISSED"]
    counts = Counter()
    for name, value in details.items():
        if name.endswith("independent Plain/internal"): counts.update(value)
    coverage = {"cases": len(raw), "tracedCases": sum(bool(o["trace"]) for o in raw.values()),
                "snapshots": sum(len(o["trace"]) for o in raw.values()), "transitions": dict(counts),
                "cons": sum(v["cons"] for n, v in details.items() if n.endswith("newest eligible reservations")),
                "multipleEligibleCons": sum(v["multipleEligible"] for n, v in details.items() if n.endswith("newest eligible reservations"))}
    report = {"checks": results, "coverage": coverage, "details": details, "consumerNegatives": negatives,
              "inputHashes": {f: hashlib.sha256((args.observations / f).read_bytes()).hexdigest() for f in ("inputs.json", "raw.json", "summary.json")},
              "limits": ["Finite mathematical exports, not universal proofs or native observer fidelity.",
                         "Plain.next and decode are parent-authored functions; equality checked, not independently reimplemented.",
                         "Required binding IDs still derive from counted tasks; no separately exported plain obligation ID/lifetime bijection. Selected source-required owners checked independently.",
                         "Pre-commit exports omit completeState; semantic projections checked, not every hidden metadata field.",
                         "Exact visible binding acquisition order and holding inclusion checked; complete source-derived ordered active-scope view not independently reconstructed.",
                         "No kernel/axiom audit, checker verdicts, native model execution, trial rerun, or executed machine mutants by this author."]}
    args.report.write_text(json.dumps(report, indent=2) + "\n")
    for r in failed: print("FAIL", r["name"], r["detail"])
    print(f"CHECKS: {len(results)-len(failed)} passed; {len(failed)} failed; {len(negatives)-len(missed)}/{len(negatives)} consumer corruptions rejected")
    print("COVERAGE:", json.dumps(coverage, sort_keys=True))
    print("Finite export evidence only; see report limits. No proof/freeze/native fidelity claim.")
    raise SystemExit(1 if failed or missed else 0)


if __name__ == "__main__":
    main()
