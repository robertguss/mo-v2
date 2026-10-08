"""Stage B compiled-control harness readiness, and the deferred expectations.

Stage A executed 21 of the 31 locked control obligations. Ten were deferred
because a call-free interpreter cannot reach their intended path at all, and
sixteen refusal expectations were deferred because Stage A answers
`stage-unsupported` where they state a name or type diagnostic.

**Nothing here executes one of those ten control paths.** A control is only
satisfied by a real compiled Stage B evaluator: the mutation disabled must give
a passing baseline, the mutation enabled must reach the mutated code, and the
named predicate must be the thing that rejects it. What this module prepares is
everything else:

* the registry, read from the locked inventory rather than retyped;
* for each deferred control, the public example whose predicted trace actually
  reaches the intended path, derived from the frozen reference;
* the sixteen deferred refusal expectations, re-derived and re-run under Stage
  B so they are known to be executable the moment a candidate exists;
* proof that the frozen acceptance of control evidence still refuses a record
  that claims a control ran when it did not.
"""
import json
from pathlib import Path
import re
import sys
import traceback

import phasecheck
import refusalcheck
from boundedcheck import DEFS
from cases import examples, fixture
from closeoutcheck import CONTROLS, PREDICATES, check_control
from refusalcheck import expected as annotated
from stage_b_inventory import deferred_controls, deferred_expectations
from syntax import Refusal, check, parse, position
from transition_reference import TransitionReference


HERE = Path(__file__).resolve().parent

# The capability a compiled Stage B evaluator must have before each control can
# be attempted at all. These are statements of what is missing, not of what was
# done; every row's `executed` stays false until a real evaluator runs.
REQUIRED_CAPABILITY = {
    "always-copy": "decide reuse from the actual holder count of a unique list",
    "hidden-entry-copy": "enter an invocation without copying its arguments",
    "fixture-provenance": "treat an installed fixture list and a source literal list alike",
    "caller-reservation-theft": "keep a caller's reservation out of reach of the callee",
    "early-cleanup": "hold a reservation for as long as its originating branch needs it",
    "omitted-entry-create": "create the cells an invocation entry genuinely needs",
    "omitted-nested-create": "attribute a descendant invocation's creates to its ancestors",
    "omitted-transient-create": "count a cell created and freed inside one invocation",
    "early-enter": "finish every explicit argument before entering the invocation",
    "skipped-return-cleanup": "run the return cleanup an invocation owes before returning",
}


def named_case(obligation):
    """The public example a locked obligation names, if it names one."""
    match = re.search(r"\bC(\d+)\b", obligation)
    return "C" + match.group(1) if match else None


def case_features():
    """Per public example, the features that decide which control it can trigger."""
    rows = {}
    for case in examples():
        program = parse(case["source"])
        check(program, "B")
        reference = TransitionReference(program, case["cells"], case["inputs"], case["outside"],
                                        landmark_limit=60 if case["value"] is None else 10000)
        reference.observe(program["main"])
        # Features come from what the predicted run actually does, not from the
        # shared definition block that every public example carries.
        table = {f[0]: f[1] for f in program["functions"]}
        entry_creates = 0
        cleanup_inside_call = 0
        seen = 0
        for row in reference.trace:
            added = reference.events[seen:row["event_end"]]
            seen = row["event_end"]
            if row["transition"] == "Enter":
                entry_creates += sum(1 for event in added if event[0] == "create")
            if row["transition"] in ("Free cell", "Give up holder") and row["state"]["frames"]:
                cleanup_inside_call += 1
        invoked = [event[3] for event in reference.events if event[0] == "enter"]
        rows[case["name"]] = dict(
            executed_calls=len(invoked),
            executed_calls_with_arguments=sum(1 for name in invoked if table.get(name)),
            executed_calls_with_list_arguments=sum(
                1 for name in invoked
                if any(kind == "ListInt" for _, kind, _, _ in table.get(name, []))),
            entry_creates=entry_creates,
            cleanup_inside_call=cleanup_inside_call,
            descendant_creates=max((n for _, _, n in invocation_counts(reference)), default=0),
            reservations=any(row["state"]["aside"] for row in reference.trace),
        )
    return rows


def walk_expressions(program):
    from transition_reference import children
    stack = [program["main"]] + [f[3] for f in program["functions"]]
    while stack:
        node = stack.pop()
        yield node
        stack.extend(children(node))


def invocation_counts(reference):
    from predicates import invocation_creates
    try:
        return invocation_creates(reference.events, finished=False)
    except AssertionError:
        return []


def cross_route_cases():
    """The two fixture-versus-literal sources the frozen closeout check uses."""
    cells, inputs, outside = fixture([3, -2, 8])
    return [dict(route="fixture", source="input xs: ListInt; " + DEFS["inc"] + "main = inc(xs)",
                 cells=cells, inputs=inputs, outside=outside),
            dict(route="literal", source=DEFS["inc"] + "main = inc([3, -2, 8])",
                 cells=[], inputs=[], outside=[])]


def triggers(control, obligation, features):
    """Public examples that reach this control's intended path."""
    named = named_case(obligation)
    if named:
        return sorted(name for name in features if name == named or name.startswith(named + "-"))
    if control == "omitted-entry-create":
        return sorted(name for name, row in features.items() if row["entry_creates"])
    if control == "hidden-entry-copy":
        # A hidden copy can only show up where a list actually crosses an entry.
        return sorted(name for name, row in features.items()
                      if row["executed_calls_with_list_arguments"])
    if control == "early-enter":
        return sorted(name for name, row in features.items()
                      if row["executed_calls_with_arguments"])
    if control == "skipped-return-cleanup":
        return sorted(name for name, row in features.items() if row["cleanup_inside_call"])
    if control == "fixture-provenance":
        return [row["route"] + "-route" for row in cross_route_cases()]
    raise AssertionError("unmapped control: " + control)


def registry():
    rows = []
    features = case_features()
    for row in deferred_controls():
        control = row["control"]
        assert PREDICATES[control] == row["obligation"], "locked obligation drifted"
        rows.append(dict(row,
                         required_capability=REQUIRED_CAPABILITY[control],
                         trigger_examples=triggers(control, row["obligation"], features),
                         baseline_required=True,
                         executed=False,
                         evidence_still_needed=[
                             "source patch applied to the Stage B candidate",
                             "passing baseline with the mutation disabled",
                             "recorded marker that the mutated path ran",
                             "rejection by " + row["obligation"],
                         ]))
    return rows, features


def rerun_deferred_expectations():
    """Run the sixteen deferred refusal expectations under Stage B."""
    passed = []
    index = {}
    for _, annotation, kind in refusalcheck.CASES:
        index.setdefault(annotated(annotation)[0], []).append(("refusalcheck", annotation, kind))
    for annotation, kind in phasecheck.CASES:
        index.setdefault(annotated(annotation)[0], []).append(("phasecheck", annotation, kind))
    refusals, _, _ = deferred_expectations()
    for row in refusals:
        module = row["module"]
        annotation, kind = next((a, k) for m, a, k in index[row["source"]] if m == module)
        source, start, end = annotated(annotation)
        try:
            check(parse(source), "B")
        except Refusal as error:
            actual = (error.kind, position(source, error.start), position(source, error.end))
        else:
            raise AssertionError("Stage B accepted a refusal expectation: " + source)
        assert actual == (kind, start, end), (source, actual, (kind, start, end))
        passed.append(dict(module=module, source=source, **{"class": kind}, start=start, end=end))
    return passed


def run(destination):
    destination = Path(destination)
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, candidate_executed=False, controls_executed=0,
                  record_controls=0)
    try:
        rows, features = registry()
        assert len(rows) == 10, "deferred control count"
        report["deferred_controls"] = len(rows)
        # A control with no public trigger cannot be run on public evidence at
        # all. That is reported, not papered over by inventing a new example:
        # adding one changes the frozen public case set and needs approval.
        report["controls_without_public_trigger"] = [
            row["control"] for row in rows if not row["trigger_examples"]]
        report["controls_with_public_trigger"] = len(rows) - len(report["controls_without_public_trigger"])
        expectations = rerun_deferred_expectations()
        assert len(expectations) == 16, "deferred expectation count"
        report["deferred_expectations_rerun_under_stage_b"] = len(expectations)

        # The frozen acceptance of control evidence must still refuse a record
        # that describes a control as satisfied when it was not. This is the
        # guard that stops a prepared plan being mistaken for a passing control.
        for row in rows:
            valid = dict(control=row["control"], capability=row["capability"],
                         obligation=row["obligation"], compiled=True, executed_intended_path=True,
                         baseline_passed=True, rejected_by=row["obligation"], unrelated_failure=False)
            check_control(valid, row["control"], row["capability"])
            for key, wrong in (("compiled", False), ("executed_intended_path", False),
                               ("baseline_passed", False), ("rejected_by", "crash"),
                               ("unrelated_failure", True)):
                bad = dict(valid)
                bad[key] = wrong
                try:
                    check_control(bad, row["control"], row["capability"])
                except AssertionError:
                    report["record_controls"] += 1
                else:
                    raise AssertionError("invalid control evidence accepted")
        assert set(CONTROLS) == {"frontend", "physical", "calls", "resume", "destroy"}, "control groups"
        (destination / "registry.json").write_text(json.dumps(
            dict(deferred_controls=rows, case_features=features,
                 deferred_expectations=expectations), indent=2) + "\n")
        report["qualification"] = (
            "Zero of the ten deferred Stage B control paths executed. Each needs a compiled Stage B "
            "evaluator, a passing baseline with the mutation disabled, evidence the mutated path ran, "
            "and rejection by its named predicate. This file prepares the targets and reruns the "
            "sixteen deferred refusal expectations; it is not control evidence.")
        report["passed"] = True
    except Exception:
        report["error"] = traceback.format_exc()
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return report["passed"]


if __name__ == "__main__":
    sys.exit(not run(Path(sys.argv[1])))
