"""Stage B acceptance inventory: what is frozen, what is missing, what is new.

Acceptance-owned preparation under D157, the 8 October 2026 authorization to
prepare the Stage B acceptance package for review. This module never changes a
frozen file, a prediction or a threshold. It reads `STAGE_A_LOCK.json`, rehashes
every frozen path, and derives the Stage B-deferred expectation and control
census mechanically from the frozen modules rather than restating a prose count.

No Mo interpreter, no Stage B builder delivery and no resource workload runs here.
"""
import hashlib
import json
from pathlib import Path
import sys
import traceback

import phasecheck
import refusalcheck
import selfcheck
from cases import examples
from closeoutcheck import CONTROLS, PREDICATES
from refusalcheck import expected as annotated
from syntax import Refusal, check, parse


HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
LOCK = HERE / "STAGE_A_LOCK.json"

# Stage A's reviewed record names these ten control paths as deferred. The list
# is read from the delivery rather than retyped, so a drift is a failure here.
DEFERRED_CONTROLS = HERE / "stage-a-delivery" / "controls-reviewed.json"

# New acceptance-owned Stage B preparation. Nothing in `files` below is touched.
PROPOSED_NEW = [
    "STAGE_B_PREPARATION.md",
    "stage_b_inventory.py",
    "stage_b_workloads.py",
    "stage_b_large.py",
    "stage_b_link.py",
    "stage_b_controls.py",
    "stage_b_delivery.py",
    "stage_b_check.py",
    "stage-b-stub/Cargo.toml",
    "stage-b-stub/Cargo.lock",
    "stage-b-stub/call_stub.rs",
    "stage-b-stub/large_stub.rs",
]

# Gaps the Stage A freeze and result record as unfinished for Stage B.
KNOWN_GAPS = {
    "large-streaming-adapter": "linked.run_linked sends large=false and the small verifier holds a full trace",
    "stage-b-candidate-linking": "no Stage B candidate has ever been linked or run",
    "stage-b-private-execution": "the 524 private rows are Stage A capability refusals only",
    "stage-b-builder-delivery": "no sanitized Stage B public package has been assembled",
    "stage-b-compiled-controls":
        "nine of the ten deferred controls are active and have no compiled evaluator run; "
        "omitted-entry-create is not applicable under the frozen rules (D164)",
    "d151-resource-workloads":
        "neither million-cell workload has ever run; D162 sets the recursive sum's "
        "limit at 900 seconds and leaves the discard at 600",
}


def digest(path):
    h = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def frozen_inventory():
    """Rehash every locked path. Returns (counts, mismatches). Never repairs."""
    lock = json.loads(LOCK.read_text())
    mismatches = []
    checked = 0
    for name, want in sorted(lock["files"].items()):
        path = HERE / name
        got = digest(path) if path.is_file() else None
        checked += 1
        if got != want:
            mismatches.append(dict(kind="file", path=name, expected=want, actual=got))
    deps = 0
    for name, want in sorted(lock["historical_dependencies"].items()):
        path = ROOT / name
        got = digest(path) if path.is_file() else None
        deps += 1
        if got != want:
            mismatches.append(dict(kind="historical_dependency", path=name, expected=want, actual=got))
    archives = 0
    for name, row in sorted(lock["preserved_archives"].items()):
        found = [p for p in HERE.rglob(name) if p.is_file()]
        archives += 1
        if not found:
            mismatches.append(dict(kind="archive", path=name, expected=row["sha256"], actual=None))
            continue
        got = digest(found[0])
        if got != row["sha256"]:
            mismatches.append(dict(kind="archive", path=name, expected=row["sha256"], actual=got))
    counts = dict(files=checked, historical_dependencies=deps, preserved_archives=archives)
    return counts, mismatches, lock


def stage_a_refusal(source):
    """What Stage A's frozen checker does with this source."""
    try:
        check(parse(source), "A")
    except Refusal as error:
        return error.kind
    return None


def deferred_expectations():
    """Expectations whose stated outcome needs Stage B, derived from the modules.

    An expectation is Stage B-deferred when the frozen Stage A checker answers
    `stage-unsupported` instead of the outcome the expectation states. Nothing
    is retyped from prose; disagreement with the Stage A record is reported.
    """
    rows = []
    for _, annotation, kind in refusalcheck.CASES:
        source = annotated(annotation)[0]
        if stage_a_refusal(source) == "stage-unsupported" and kind != "stage-unsupported":
            rows.append(dict(module="refusalcheck", source=source, expected=kind))
    for annotation, kind in phasecheck.CASES:
        source = annotated(annotation)[0]
        if stage_a_refusal(source) == "stage-unsupported" and kind != "stage-unsupported":
            rows.append(dict(module="phasecheck", source=source, expected=kind))
    accepts = [dict(module="selfcheck", source=source, expected="accept")
               for source, _ in selfcheck.ACCEPT if stage_a_refusal(source) == "stage-unsupported"]
    calls = [dict(module="cases", name=case["name"], expected="execute")
             for case in examples() if stage_a_refusal(case["source"]) == "stage-unsupported"]
    return rows, accepts, calls


def deferred_controls():
    names = json.loads(DEFERRED_CONTROLS.read_text())["deferred_stage_b"]
    groups = {name: group for group, members in CONTROLS.items() for name in members}
    return [dict(control=name, capability=groups[name], obligation=PREDICATES[name]) for name in names]


def run(destination):
    destination = Path(destination)
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, candidate_executed=False, resource_executed=False)
    try:
        counts, mismatches, lock = frozen_inventory()
        report["frozen"] = counts
        report["frozen_mismatches"] = mismatches
        refusals, accepts, calls = deferred_expectations()
        controls = deferred_controls()
        report["stage_b_deferred"] = dict(
            refusal_expectations=len(refusals),
            accept_expectations=len(accepts),
            public_call_cases=len(calls),
            control_paths=len(controls),
        )
        # The Stage A result says "ten exact Stage B control paths and sixteen
        # Stage B semantic expectations". Reproduce both numbers mechanically
        # rather than asserting the prose; a difference must be reported, never
        # silently adopted in either direction.
        report["stage_a_record_agreement"] = dict(
            control_paths=dict(recorded=10, derived=len(controls), agrees=len(controls) == 10),
            semantic_expectations=dict(recorded=16, derived=len(refusals), agrees=len(refusals) == 16),
        )
        report["known_gaps"] = KNOWN_GAPS
        report["proposed_new_files"] = {
            name: (digest(HERE / name) if (HERE / name).is_file() else None) for name in PROPOSED_NEW
        }
        report["private_corpus"] = dict(lock["private_corpus"], custody_note=
            "acceptance-private; this repository holds only the fingerprint, and nothing here regenerates it")
        inventory = dict(
            lock_sha256=digest(LOCK),
            baseline=lock["baseline"],
            frozen=counts,
            frozen_intact=not mismatches,
            deferred_refusal_expectations=refusals,
            deferred_accept_expectations=accepts,
            deferred_public_call_cases=calls,
            deferred_control_paths=controls,
            known_gaps=KNOWN_GAPS,
        )
        (destination / "inventory.json").write_text(json.dumps(inventory, indent=2) + "\n")
        assert not mismatches, "frozen inventory changed"
        assert len(controls) == 10, "deferred control count"
        report["passed"] = True
    except Exception:
        report["error"] = traceback.format_exc()
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return report["passed"]


if __name__ == "__main__":
    sys.exit(not run(Path(sys.argv[1])))
