"""Inventory the Stage B scientific freeze. No candidate, control or resource run.

    python3 stage_b_freeze.py

Writes STAGE_B_LOCK.json and evidence/stage-b-freeze/validation.json. The lock
does not hash itself, and the validation report is not part of the lock's file
inventory. The 496 Stage A files are rechecked and not edited. The private
corpus is not opened.
"""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import time

import stage_b_delivery
from stage_b_delivery import ARCHIVE, ALLOWLIST


HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
STAGE_A = HERE / "STAGE_A_LOCK.json"
LOCK_PATH = HERE / "STAGE_B_LOCK.json"
VALIDATION = HERE / "evidence" / "stage-b-freeze" / "validation.json"
PACKAGE = HERE / "stage-b-delivery" / ARCHIVE
V18_ARCHIVE = HERE / "evidence" / "stage-b-03" / "delivery" / "rob-1333-stage-b-public-v18.tar.gz"
V18_SHA = "0e30809545c3114012c69cceaf024e22f69c08a9b9721eb0a199e35a5d76b997"
V18_BYTES = 28229
V18_DOC_SHA = "5be9136fb83e632aee8f4dbe451dde3fa62cd405b251d9162fd6934d188f15b4"
BASELINE = "424d0f4c09236d58a940477c190ac35afc984715"

EXCLUDED = {
    "STAGE_B_LOCK.json",
    "evidence/stage-b-freeze/validation.json",
}


def digest(path):
    h = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def digest_bytes(data):
    return hashlib.sha256(data).hexdigest()


def stage_a_intact(lock):
    mismatches = []
    for name, want in sorted(lock["files"].items()):
        path = HERE / name
        got = digest(path) if path.is_file() else None
        if got != want:
            mismatches.append(name)
    for name, want in sorted(lock["historical_dependencies"].items()):
        path = ROOT / name
        got = digest(path) if path.is_file() else None
        if got != want:
            mismatches.append(name)
    archives = {
        "rob-1333-final-review-v12-final.tar.gz":
            HERE / "stage-a-delivery" / "review-packages" / "rob-1333-final-review-v12-final.tar.gz",
        "rob-1333-integration-review-v13.tar.gz":
            HERE / "stage-a-delivery" / "review-packages" / "rob-1333-integration-review-v13.tar.gz",
        "rob-1333-stage-a-public-v13.tar.gz":
            HERE / "stage-a-delivery" / "public-packages" / "rob-1333-stage-a-public-v13.tar.gz",
        "rob-1333-stage-a-public-v14.tar.gz":
            HERE / "stage-a-delivery" / "public-packages" / "rob-1333-stage-a-public-v14.tar.gz",
    }
    checked = 0
    for name, path in archives.items():
        want = lock["preserved_archives"][name]["sha256"]
        got = digest(path) if path.is_file() else None
        checked += 1
        if got != want:
            mismatches.append(name)
    return mismatches, checked


def inventory_paths():
    listed = subprocess.check_output(["git", "ls-files", "-z", "--", str(HERE)], cwd=ROOT)
    names = []
    for raw in listed.split(b"\0"):
        if not raw:
            continue
        path = Path(raw.decode()).relative_to("experiments/13-source-acceptance")
        names.append(path.as_posix())
    extras = [
        "BUILDER_STAGE_B_V19.md",
        "BUILDER_STAGE_B_PREFLIGHT.md",
        "STAGE_B_LOCK.md",
        "stage_b_freeze.py",
        "stage-b-delivery/" + ARCHIVE,
    ]
    for name in extras:
        if name not in names:
            names.append(name)
    return sorted(name for name in names if name not in EXCLUDED)


def build_package():
    with tempfile.TemporaryDirectory(prefix="rob1333-stage-b-freeze-") as tmp:
        destination = Path(tmp) / "delivery"
        assert stage_b_delivery.run(destination), "v19 package check failed"
        archive = (destination / ARCHIVE).read_bytes()
        summary = json.loads((destination / "summary.json").read_text())
    PACKAGE.parent.mkdir(parents=True, exist_ok=True)
    PACKAGE.write_bytes(archive)
    return archive, summary


def main():
    began = time.monotonic()
    started = datetime.now(timezone.utc)
    lock_a = json.loads(STAGE_A.read_text())
    mismatches, archives_checked = stage_a_intact(lock_a)
    assert not mismatches, "Stage A freeze bytes changed: " + ", ".join(mismatches)
    assert digest(HERE / "BUILDER_STAGE_B_V18.md") == V18_DOC_SHA, "v18 addendum bytes changed"
    v18 = V18_ARCHIVE.read_bytes()
    assert digest_bytes(v18) == V18_SHA and len(v18) == V18_BYTES, "preserved v18 archive"

    archive, summary = build_package()
    assert summary["leak_findings"] == [], "v19 leak"
    assert summary["file_count"] == len(ALLOWLIST) == 14, "v19 member count"
    rows = stage_b_delivery.member_bytes()
    content = {name: digest_bytes(data) for name, data in sorted(rows.items())}
    assert "BUILDER_STAGE_B_V18.md" not in content, "stale addendum still delivered"
    assert "900" in (HERE / "BUILDER_STAGE_B_V19.md").read_text(), "sum clock missing"
    assert "six-hundred-second" not in (HERE / "BUILDER_STAGE_B_V19.md").read_text()

    files = {name: digest(HERE / name) for name in inventory_paths()}
    assert all((HERE / name).is_file() for name in files), "missing inventory file"
    for name, want in lock_a["files"].items():
        assert files.get(name) == want, "inventory drifted from Stage A: " + name

    document = {
        "format": "ROB-1333 Stage B scientific freeze 1",
        "status": "frozen",
        "provisional": False,
        "created_at": started.isoformat(),
        "baseline": BASELINE,
        "branch": "acceptance/rob-1333-stage-b-freeze",
        "before_candidate_implementation": True,
        "scope": (
            "Stage A freeze unchanged, plus the reviewed Stage B preparation and public "
            "package v19. D162 amends the recursive-sum clock to 900 seconds; the discard "
            "stays at 600. The five preflight questions are answered from the frozen rules. "
            "Private execution, the nine active sabotage tests and the million-element runs "
            "stay gated."
        ),
        "authorization": {
            "D157": "prepare the Stage B acceptance package; no build yet",
            "D159": "summaries between boundaries; full photographs at boundaries",
            "D160": "cleanup chain in full at photographs; length only between them",
            "D162": "900 seconds for the million-element recursive sum; discard stays at 600; per-step record kept",
            "D164": "omitted-entry-create is not applicable; nine of ten controls stay active",
            "D165": "scientifically freeze the Stage B acceptance package, then hand it to a separate builder",
        },
        "interpretation": (
            "This inventory preserves the Stage A freeze and the Stage B preparation. "
            "Preparation prose that says the package is not frozen describes that checkpoint. "
            "The lock does not hash itself. The validation report is excluded from the content inventory. "
            "No open preflight question remains, so the lock is not provisional."
        ),
        "stage_a_lock": {
            "path": "STAGE_A_LOCK.json",
            "sha256": digest(STAGE_A),
            "frozen_files": len(lock_a["files"]),
            "historical_dependencies": len(lock_a["historical_dependencies"]),
            "preserved_archives": len(lock_a["preserved_archives"]),
        },
        "v19_document_amendment": {
            "replaced": "BUILDER_STAGE_B_V18.md",
            "old_sha256": V18_DOC_SHA,
            "new_document": "BUILDER_STAGE_B_V19.md",
            "new_sha256": content["BUILDER_STAGE_B_V19.md"],
            "added": "BUILDER_STAGE_B_PREFLIGHT.md",
            "added_sha256": content["BUILDER_STAGE_B_PREFLIGHT.md"],
            "old_archive": "rob-1333-stage-b-public-v18.tar.gz",
            "old_archive_sha256": V18_SHA,
            "reason": (
                "D162 gives the recursive sum 900 seconds and leaves the discard at 600. "
                "The preflight clarification states the frozen Stage B rules for five questions. "
                "No executable Stage A file changed."
            ),
            "executable_changes": False,
            "open_questions": [],
        },
        "preserved_archives": {
            "rob-1333-stage-b-public-v18.tar.gz": {
                "path": "evidence/stage-b-03/delivery/rob-1333-stage-b-public-v18.tar.gz",
                "sha256": V18_SHA,
                "bytes": V18_BYTES,
                "delivery": "historical; not current builder delivery",
            },
            "rob-1333-stage-b-public-v19.tar.gz": {
                "path": "stage-b-delivery/" + ARCHIVE,
                "sha256": digest_bytes(archive),
                "bytes": len(archive),
                "delivery": "builder",
            },
        },
        "public_delivery": {
            "archive": ARCHIVE,
            "sha256": digest_bytes(archive),
            "bytes": len(archive),
            "files": content,
            "content_count": len(content),
            "additional_member": "DELIVERY.sha256",
            "dispatch_context_verification": "parent-owned, not yet performed",
            "access_boundary": "procedural; same-account retrieval technically remains available",
        },
        "private_corpus": dict(lock_a["private_corpus"], local_recheck="not performed here; acceptance orb, read-only"),
        "controls": {
            "deferred": 10,
            "active": 9,
            "not_applicable": ["omitted-entry-create"],
            "reason": "D164: the frozen predictor never allocates on Enter",
            "executed": 0,
            "record_shape_rejections_still_required": 50,
        },
        "preflight": {
            "document": "BUILDER_STAGE_B_PREFLIGHT.md",
            "questions": {
                "1": "answered",
                "2": "answered",
                "3": "answered",
                "4": "answered",
                "5": "answered",
            },
            "open": [],
        },
        "remaining_gates": [
            "acceptance-orb read-only private fingerprint, case counts and freeze-commit no-leak scan",
            "parent dispatch and fresh-context verification",
            "private execution of the 24 reserved and 500 generated cases",
            "the nine active sabotage tests, on a Stage B interpreter",
            "either million-element run",
        ],
        "files": files,
    }
    LOCK_PATH.write_text(json.dumps(document, indent=2) + "\n")
    lock_sha = digest(LOCK_PATH)
    VALIDATION.parent.mkdir(parents=True, exist_ok=True)
    report = {
        "passed": True,
        "kind": "freeze inventory/publication verification; no new scientific campaign",
        "lock": "STAGE_B_LOCK.json",
        "lock_sha256": lock_sha,
        "status": "frozen",
        "provisional": False,
        "frozen_file_hashes_checked": len(lock_a["files"]),
        "historical_dependency_hashes_checked": len(lock_a["historical_dependencies"]),
        "stage_a_preserved_archives_checked": archives_checked,
        "stage_a_mismatches": [],
        "executable_changes_to_stage_a_freeze": False,
        "inventory_files_checked": len(files),
        "v18_archive_sha256": V18_SHA,
        "v19_archive_sha256": digest_bytes(archive),
        "v19_archive_bytes": len(archive),
        "v19_regular_members": len(content) + 1,
        "v19_content_hashes_checked": len(content),
        "v19_leak_findings": [],
        "private_corpus_fingerprint_checked": False,
        "private_corpus_contents_published": False,
        "publication_audit": {
            "v19_members_checked": len(content) + 1,
            "forbidden_pattern_matches_in_v19": 0,
            "stale_v18_addendum_in_v19": False,
            "scope": (
                "v19 allowlist bytes only. The acceptance orb still scans the freeze commit "
                "and checks the private corpus without publishing it."
            ),
        },
        "orb_checks_remaining": [
            "SHA256 /home/user/rob-1333-private-v11/cases.jsonl.gz equals "
            "0f176c60d30d30fffd4d7fb25d982cd3517d1a847840027ad3e99f9c572f41f0 and the file is 1003653 bytes; "
            "do not print contents. seed.json beside it is 50 bytes; do not print the seed.",
            "Read-only counts, with no source or expected output exported: 24 heldouts, 8 families, "
            "500 generated rows, 404 distinct generated cases, 96 repeats.",
            "No-leak scan of the freeze commit: v19 members are only the public allowlist plus "
            "DELIVERY.sha256; those members contain no private fingerprint, private path, seed filename, "
            "held-out case, acceptance checker source or lock filename; the commit adds no private file.",
        ],
        "effort": {
            "start": started.isoformat(),
            "stopped": datetime.now(timezone.utc).isoformat(),
            "contributors": 1,
            "check_run_seconds": round(time.monotonic() - began, 3),
        },
        "candidate_acceptance_executed": False,
        "builder_dispatched": False,
        "controls_executed": 0,
        "million_element_runs": 0,
        "private_corpus_used": False,
    }
    VALIDATION.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({k: report[k] for k in (
        "passed", "lock_sha256", "frozen_file_hashes_checked", "inventory_files_checked",
        "v19_archive_sha256", "v19_archive_bytes", "provisional")}, indent=2))


if __name__ == "__main__":
    main()
