"""Assemble and check the proposed sanitized Stage B builder delivery.

The rule from D150 and D155 is simple to state and easy to break by accident:
the builder may see finally approved requirements, interface declarations and
already-public examples, and nothing else. Acceptance sources, expected traces,
exact span tables, held-out cases, the private seed and the negative-control
implementations stay out, even where they are publicly retrievable from this
repository.

So the package is built from an explicit allowlist rather than by copying a
directory, every member is fingerprinted, the archive is byte-reproducible, and
the assembled bytes are scanned for the things that must never appear in it.
Then the public runtime crate is extracted on its own and type-checked with the
pinned toolchain, to show the builder receives something that compiles without
any acceptance-side file.

This is a proposal for owner review. Assembling a package is not dispatching a
builder, and nothing here verifies a future builder's context.
"""
import gzip
import hashlib
import io
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import traceback


HERE = Path(__file__).resolve().parent
TOOLCHAIN = "1.98.1"
ARCHIVE = "rob-1333-stage-b-public-v19.tar.gz"

# Exactly what a Stage B builder would receive. Everything except the Stage B
# addendum is byte-identical to the frozen Stage A public package, because the
# language contract, the interfaces and the runtime are unchanged.
ALLOWLIST = [
    "BUILDER_HANDOFF.md",
    "BUILDER_BRIEF.md",
    "BUILDER_AMENDMENT_D154.md",
    "BUILDER_EXECUTION.md",
    "BUILDER_CHECKED_DUMP_V14.md",
    "BUILDER_STAGE_A_DIAGNOSTICS_V15.md",
    "BUILDER_RUNTIME_METHODS_V16.md",
    "BUILDER_MATCH_BIRTH_V17.md",
    "BUILDER_STAGE_B_V19.md",
    "BUILDER_STAGE_B_PREFLIGHT.md",
    "runtime/Cargo.toml",
    "runtime/Cargo.lock",
    "runtime/lib.rs",
    "runtime/abi.rs",
]

# Nothing in the package may name acceptance machinery or private material.
# Each pattern is a thing that would be a real leak if it appeared.
FORBIDDEN = {
    "private corpus fingerprint": r"0f176c60d30d30fffd4d7fb25d982cd3517d1a847840027ad3e99f9c572f41f0",
    "private corpus path": r"rob-1333-private",
    "private seed": r"\bseed\.json\b",
    "held-out cases": r"\bheld[- ]?out\b",
    "generated case corpus": r"\b500 generated\b",
    "acceptance checker module": r"\b\w+check\.py\b",
    "acceptance reference module": r"\b(transition_reference|call_reference|finite_reference|predicates|integration|linked|cases|generated)\.py\b",
    "acceptance evidence directory": r"\bevidence/",
    "scientific lock": r"STAGE_[AB]_LOCK",
    "acceptance case identifier": r"\bC1[0-4]-[a-z]+\b",
}

# Control names are ordinary English phrases as well as identifiers:
# `tail-call/early-cleanup alternatives` and `fixture-provenance information`
# both appear in already-approved public documents as prose. A name only
# counts as a leak when it is used as a control identifier, so the scan looks
# at how it is written rather than only whether it occurs.
CONTROL_NAMES = [
    "always-copy", "hidden-entry-copy", "fixture-provenance", "caller-reservation-theft",
    "early-cleanup", "omitted-entry-create", "omitted-nested-create", "omitted-transient-create",
    "early-enter", "skipped-return-cleanup", "shadow-reporter", "premature-free", "tail-leak",
    "token-reader", "accept-all", "refuse-all", "wrong-scope", "whole-file-span", "fixed-i128",
    "shared-mutation", "lost-live-holder", "wrong-reservation-order", "counter-reset",
    "call-boundary-only", "suspended-as-finished", "resource-as-suspended", "physical-leak",
    "double-free", "outside-drop",
]
# Phrases that make a control name an identifier rather than English. The bare
# word "control" is deliberately not one of them: it is a snapshot field name
# and an ordinary adjective throughout the approved public documents.
CONTROL_CONTEXT = re.compile(
    r"\bcontrols\b|\bmutant|\bmutation\b|rejected by|negative control"
    r"|\bcontrol\s+(?:path|name|target|body|implementation|predicate)\b",
    re.IGNORECASE)
QUOTED = "`'\""


def digest_bytes(data):
    return hashlib.sha256(data).hexdigest()


def member_bytes():
    rows = {}
    for name in ALLOWLIST:
        path = HERE / name
        assert path.is_file(), "missing allowlisted file: " + name
        rows[name] = path.read_bytes()
    return rows


def scan(rows):
    """Forbidden matches, plus the control-name mentions judged to be prose."""
    findings, prose = [], []
    for name, data in rows.items():
        try:
            text = data.decode()
        except UnicodeDecodeError:
            findings.append(dict(file=name, pattern="non-text member", match=""))
            continue
        for label, pattern in FORBIDDEN.items():
            for match in re.finditer(pattern, text, re.IGNORECASE):
                findings.append(dict(file=name, pattern=label, match=match.group(0),
                                     line=text[:match.start()].count("\n") + 1))
        for number, line in enumerate(text.splitlines(), start=1):
            hits = [c for c in CONTROL_NAMES if re.search(r"\b" + re.escape(c) + r"\b", line, re.I)]
            for control in hits:
                match = re.search(r"\b" + re.escape(control) + r"\b", line, re.I)
                start, end = match.span()
                quoted = line[start - 1:start] in QUOTED and line[end:end + 1] in QUOTED
                row = dict(file=name, pattern="control identifier", match=match.group(0),
                           line=number, context=line.strip())
                if quoted or len(hits) > 1 or CONTROL_CONTEXT.search(line):
                    findings.append(row)
                else:
                    prose.append(row)
    return findings, prose


def manifest(rows):
    lines = [f"{digest_bytes(data)}  {name}\n" for name, data in sorted(rows.items())]
    return "".join(lines).encode()


def build_archive(rows, delivery):
    """A byte-reproducible archive: sorted, fixed times, no owner metadata."""
    raw = io.BytesIO()
    with tarfile.open(fileobj=raw, mode="w") as tar:
        for name, data in list(sorted(rows.items())) + [("DELIVERY.sha256", delivery)]:
            info = tarfile.TarInfo(name)
            info.size = len(data)
            info.mtime = 0
            info.mode = 0o644
            info.uid = info.gid = 0
            info.uname = info.gname = ""
            tar.addfile(info, io.BytesIO(data))
    packed = io.BytesIO()
    with gzip.GzipFile(fileobj=packed, mode="wb", mtime=0) as handle:
        handle.write(raw.getvalue())
    return packed.getvalue()


def check_public_runtime(archive_bytes, destination):
    """Extract only the runtime and type-check it with the pinned toolchain."""
    work = Path(tempfile.mkdtemp(prefix="rob1333-stage-b-public-"))
    try:
        with tarfile.open(fileobj=io.BytesIO(archive_bytes), mode="r:gz") as tar:
            for member in tar.getmembers():
                assert member.isfile(), "package member must be a regular file"
                assert not member.name.startswith("/") and ".." not in member.name, "package path"
                if member.name.startswith("runtime/"):
                    tar.extract(member, work, filter="data")
        command = ["cargo", f"+{TOOLCHAIN}", "check", "--locked", "--offline",
                   "--manifest-path", str(work / "runtime" / "Cargo.toml")]
        result = subprocess.run(command, capture_output=True, text=True,
                                env=dict(CARGO_TARGET_DIR=str(work / "target"), **_env()))
        (destination / "public-runtime-check.txt").write_text(
            " ".join(command) + "\n" + result.stdout + result.stderr)
        assert result.returncode == 0, "public runtime check failed"
        return " ".join(command)
    finally:
        shutil.rmtree(work, ignore_errors=True)


def _env():
    import os
    return {k: v for k, v in os.environ.items() if k != "CARGO_TARGET_DIR"}


def run(destination):
    destination = Path(destination)
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, candidate_executed=False, builder_dispatched=False)
    try:
        rows = member_bytes()
        findings, prose = scan(rows)
        report["leak_findings"] = findings
        report["control_names_judged_prose"] = prose
        assert not findings, "forbidden content in the proposed delivery"
        delivery = manifest(rows)
        archive = build_archive(rows, delivery)
        (destination / ARCHIVE).write_bytes(archive)
        (destination / "DELIVERY.sha256").write_bytes(delivery)
        # A second build must give identical bytes, or the fingerprint below is
        # not something a reviewer can reproduce.
        assert build_archive(rows, delivery) == archive, "archive is not reproducible"
        report["archive"] = ARCHIVE
        report["archive_sha256"] = digest_bytes(archive)
        report["archive_bytes"] = len(archive)
        report["delivery_sha256"] = digest_bytes(delivery)
        report["files"] = {name: digest_bytes(data) for name, data in sorted(rows.items())}
        report["file_count"] = len(rows)
        report["unchanged_from_stage_a"] = sorted(
            name for name in rows
            if name not in ("BUILDER_STAGE_B_V19.md", "BUILDER_STAGE_B_PREFLIGHT.md"))
        report["new_in_stage_b"] = ["BUILDER_STAGE_B_V19.md", "BUILDER_STAGE_B_PREFLIGHT.md"]
        report["replaces"] = "BUILDER_STAGE_B_V18.md"
        report["public_runtime_check"] = check_public_runtime(archive, destination)
        report["qualification"] = (
            "Public package v19. D162 sets the recursive sum's limit at 900 seconds and leaves "
            "the discard at 600. The preflight clarification states frozen Stage B rules and "
            "does not add a rule. Assembling this package does not dispatch a builder, verify a "
            "future builder's starting context, or make the separation technically enforced; "
            "same-account retrieval of excluded material remains possible.")
        report["passed"] = True
    except Exception:
        report["error"] = traceback.format_exc()
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({k: v for k, v in report.items() if k != "files"}, indent=2))
    return report["passed"]


if __name__ == "__main__":
    sys.exit(not run(Path(sys.argv[1])))
