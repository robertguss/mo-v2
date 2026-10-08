"""Small public-workload checks only; no private corpus or approved-depth run.

Usage: python3 check_revision.py NEW_EVIDENCE_DIRECTORY BINARY_DIRECTORY
The directory must not exist. Original files are hashed before and afterwards.
"""
from copy import deepcopy
import gzip
import hashlib
import json
from pathlib import Path
import sys
import time

HERE = Path(__file__).resolve().parent
ORIGINAL = HERE.parent
sys.path.insert(1, str(ORIGINAL))

from stage_b_large import LargeVerifier, run_large_linked
from stage_b_workloads import DiscardedList, NonTailSum, reference_trace, validate_schedule, validate_states


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def preservation():
    lock = json.loads((ORIGINAL / "STAGE_B_LOCK.json").read_text())
    for name, digest in lock["files"].items():
        assert sha(ORIGINAL / name) == digest, "original Stage B fingerprint: " + name
    a = json.loads((ORIGINAL / "STAGE_A_LOCK.json").read_text())
    for name, digest in a["historical_dependencies"].items():
        assert sha(ORIGINAL.parent.parent / name) == digest, "historical fingerprint: " + name
    for line in (ORIGINAL / "candidate-stage-b/CANDIDATE.sha256").read_text().splitlines():
        digest, name = line.split()
        assert sha(ORIGINAL / "candidate-stage-b" / name) == digest
        assert sha(HERE / "candidate-stage-b" / name) == digest
    return dict(original_frozen_files=len(lock["files"]), historical_dependencies=len(a["historical_dependencies"]),
                original_lock=sha(ORIGINAL / "STAGE_B_LOCK.json"), candidate_byte_identical=True)


def budgets_through(workload, cut):
    stops = sorted({0, cut, min(cut, workload.deepest_step())})
    return [0] + [b - a for a, b in zip(stops, stops[1:])] + [0]


def rejected(fn, message):
    try:
        fn()
    except AssertionError as error:
        assert message in str(error), (message, str(error))
        return str(error)
    raise AssertionError("incorrect stream accepted: " + message)


def replay(rows, workload, budgets):
    verifier = LargeVerifier(workload, budgets)
    for row in rows:
        verifier.row(row)
    return verifier.finish()


def relabel(rows):
    """Opaque identity changes, not cell-address changes or expected-value edits."""
    rows = deepcopy(rows)
    def ident(domain, value):
        if domain == "frame" and value == 0:
            return 0
        return value + dict(frame=101, binding=307, branch=509)[domain]
    def births(items):
        for item in items:
            item["id"] = ident(item["domain"], item["id"])
            item["invocation"] = ident("frame", item["invocation"])
    def events(items):
        for item in items:
            if item[0] in ("enter", "return"):
                item[1] = ident("frame", item[1])
            if item[0] == "enter":
                item[2] = ident("frame", item[2])
    for row in rows:
        for key in ("metadata", "snapshot"):
            if not row.get("raw", {}).get(key):
                continue
            value = json.loads(row["raw"][key])
            births(value.get("births_added", value.get("births", [])))
            events(value.get("events_added", value.get("events", [])))
            if key == "snapshot":
                for binding in value["state"]["bindings"]:
                    binding[0] = ident("binding", binding[0])
                value["state"]["frames"] = [ident("frame", f) for f in value["state"]["frames"]]
                for aside in value["state"]["aside"]:
                    aside[0] = ident("branch", aside[0])
                for context in value["control"]:
                    context["invocation"] = ident("frame", context["invocation"])
                    for binding in context["scope"]:
                        binding[1] = ident("binding", binding[1])
            row["raw"][key] = json.dumps(value)
    return rows


def run(destination, binaries):
    destination.mkdir(parents=True, exist_ok=False)
    started = time.monotonic()
    report = dict(passed=False, native_runs=0, stub_runs=0, reference_steps=0, rejections={},
                  private_cases_executed=0, million_element_runs=0)
    try:
        report["preservation_before"] = preservation()
        for cls in (DiscardedList, NonTailSum):
            for depth in range(9):
                workload = cls(depth)
                report["reference_steps"] += validate_schedule(workload)
                validate_states(workload)
                reference, _ = reference_trace(workload)
                births, events = workload.births_at(0), []
                for row in reference.trace:
                    step = row["step"]
                    births += workload.births_at(step)
                    events += workload.events_at(step)
                    assert births == reference.birth_steps[step - 1], "births differ from frozen reference"
                    assert events == reference.extended[:row["event_end"]], "events differ from frozen reference"
                # Each destruction cut is preceded by a full observation at
                # the deepest point if execution has reached it.
                for cut in range(workload.transitions() + 1):
                    budgets = budgets_through(workload, cut)
                    folder = destination / f"{cls.__name__}-{depth}-{cut}"
                    result = run_large_linked([str(binaries / "rob1333-stage-b-link")], workload,
                                              budgets, folder, keep_rows=True)
                    assert result["destroy_calls"] == 2 and result["committed_steps"] == cut
                    assert result["candidate_executed"] and not result["fixture_stub"]
                    report["native_runs"] += 1

        w = NonTailSum(3)
        schedule = budgets_through(w, w.transitions())
        with gzip.open(destination / f"NonTailSum-3-{w.transitions()}" / "rows.jsonl.gz", "rt") as source:
            rows = [json.loads(line) for line in source]
        replay(relabel(rows), w, schedule)
        report["opaque_identity_replay"] = True
        probes = [
            (5, "metadata", "missing-enter-birth", "birth coverage",
             lambda value: value["births_added"].pop()),
            (9, "metadata", "wrong-branch-owner", "birth owning invocation",
             lambda value: value["births_added"][0].update(invocation=0)),
            (17, "metadata", "wrong-call-parent", "large call/cell events",
             lambda value: value["events_added"][0].__setitem__(2, 0)),
            (49, "metadata", "wrong-return-value", "large call/cell events",
             lambda value: value["events_added"][0].__setitem__(2, ["n", "99"])),
            (w.deepest_step(), "snapshot", "rewritten-prefix", "events prefix rewritten",
             lambda value: value["events"][0].__setitem__(3, "wrong")),
        ]
        for step, key, name, message, mutate in probes:
            bad = deepcopy(rows)
            target = next(row for row in bad if row.get("step") == step and row.get("raw", {}).get(key))
            value = json.loads(target["raw"][key]); mutate(value)
            target["raw"][key] = json.dumps(value)
            report["rejections"][name] = rejected(lambda: replay(bad, w, schedule), message)
        report["rejections"]["missing-deepest"] = rejected(
            lambda: run_large_linked([str(binaries / "rob1333-stage-b-link")], w, [w.transitions()],
                                     destination / "missing-deepest", keep_rows=True),
            "missing deepest full observation")
        report["native_runs"] += 1

        # This is a compiled protocol fixture, NOT evaluator acceptance.
        # Cross the actual 10,000 grid twice, with an off-grid pause resetting
        # the changed-cell cursor and a zero-work resume between observations.
        stub_workload = DiscardedList(10_003)
        schedule = [10_001, 0, stub_workload.deepest_step() - 10_001,
                    stub_workload.transitions() - stub_workload.deepest_step()]
        result = run_large_linked([str(binaries / "stage_b_large_stub")], stub_workload,
                                 schedule, destination / "summary-protocol", keep_rows=True, fixture_stub=True)
        assert result["summary_observations"] == 2 and result["deepest_photographed"]
        assert not result["candidate_executed"] and result["fixture_stub"]
        report["stub_runs"] += 1
        with gzip.open(destination / "summary-protocol/rows.jsonl.gz", "rt") as source:
            stub_rows = [json.loads(line) for line in source]
        for field, wrong in (("depth", 1), ("live_cells", 0), ("cleanup_chain_length", 0),
                             ("changed_cells", []), ("counts", dict(create=1, write=0, free=5000))):
            bad = deepcopy(stub_rows)
            target = next(row for row in bad if row.get("phase") == "commit" and row["step"] == 10_000)
            snapshot = json.loads(target["raw"]["snapshot"]); snapshot[field] = wrong
            target["raw"]["snapshot"] = json.dumps(snapshot)
            report["rejections"]["summary-" + field] = rejected(
                lambda: replay(bad, stub_workload, schedule), "summary")
        report["preservation_after"] = preservation()
        assert report["preservation_before"] == report["preservation_after"]
        report["passed"] = True
    finally:
        report["elapsed_seconds"] = time.monotonic() - started
        (destination / "validation.json").write_text(json.dumps(report, indent=2) + "\n")
        print(json.dumps(report, indent=2))


if __name__ == "__main__":
    run(Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve())
