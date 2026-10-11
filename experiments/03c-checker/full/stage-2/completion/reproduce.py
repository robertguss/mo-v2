#!/usr/bin/env python3
"""Reconstruct exact stage-1 base plus additive stage-2 sources; no cache copied.

Default output is completion/evidence. Pass a new output directory to preserve
an earlier run. Historical records and acceptance expectations are never edited.
"""
import collections
import gzip
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile

HERE = Path(__file__).resolve().parent
FULL = HERE.parents[1]
REPO = FULL.parents[2]
OUT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else HERE / "evidence"
BASE = "66f8aac22fbaa31100700a5ca9e5b486efd67c28"
ALLOW = {"propext", "Classical.choice", "Quot.sound"}
INVENTORIES = ["BASELINE.sha256", "FREEZE.sha256",
               "stage-1/rank-amendment-01/FREEZE.sha256",
               "stage-1/rank-amendment-01/PREPARATION.sha256",
               "stage-1/rank-amendment-01/EVIDENCE.sha256",
               "stage-1/completion/PROOFS.sha256"]


def run(args, cwd, log, env=None):
    with (OUT / log).open("a") as out:
        out.write("$ " + " ".join(map(str, args)) + "\n")
        out.flush()
        result = subprocess.run(args, cwd=cwd, stdout=out,
                                stderr=subprocess.STDOUT, env=env)
        out.write(f"EXIT={result.returncode}\n")
        result.check_returncode()


def digest(path):
    with path.open("rb") as src:
        return hashlib.file_digest(src, "sha256").hexdigest()


def audit(log, expected):
    text = (OUT / log).read_text()
    rows = re.findall(r"'([^']+)' depends on axioms: \[([^\]]*)\]", text)
    empty = re.findall(r"'([^']+)' does not depend on any axioms", text)
    assert set(expected) == {n for n, _ in rows} | set(empty)
    sets = collections.Counter({"empty": len(empty)})
    for name, raw in rows:
        found = set(filter(None, map(str.strip, raw.split(","))))
        assert found <= ALLOW, (name, found)
        sets[", ".join(sorted(found))] += 1
    return dict(sets)


def main():
    OUT.mkdir(parents=True, exist_ok=False)
    sources = [FULL / "lean/Full/Demand.lean",
               *sorted((FULL / "lean/Full/Demand").glob("*.lean"))]
    inputs = [*sources, HERE / "Gate.lean", Path(__file__).resolve(),
              FULL / "stage-2/Run.lean", FULL / "stage-2/verification-preflight/verify.py"]
    hashes = {str(p.relative_to(FULL)): digest(p) for p in inputs}
    (OUT / "sources.sha256").write_text("".join(f"{h}  {p}\n" for p, h in hashes.items()))
    for inventory in INVENTORIES:
        run(["sha256sum", "-c", inventory], FULL, "integrity.log")
    run(["git", "diff", "--exit-code", BASE, "--", ".",
         ":(exclude)experiments/03c-checker/full/lean/Full/Demand.lean",
         ":(exclude)experiments/03c-checker/full/lean/Full/Demand",
         ":(exclude)experiments/03c-checker/full/stage-2"], REPO, "integrity.log")
    with tempfile.TemporaryDirectory(prefix="rob1139-stage2-complete-") as temp:
        root = Path(temp)
        archive = root / "base.tar"
        with archive.open("wb") as out:
            subprocess.run(["git", "archive", BASE, "experiments/03c-checker/full",
                            "experiments/03c-checker/trial"], cwd=REPO, stdout=out, check=True)
        with tarfile.open(archive) as tar:
            tar.extractall(root, filter="data")
        clean = root / FULL.relative_to(REPO)
        assert not list(root.rglob(".lake")), "build cache copied"
        for line in (REPO / "experiments/GZ_ARCHIVE.sha256").read_text().splitlines():
            sha, path = line.split(maxsplit=1)
            if path.startswith("experiments/03c-checker/full/"):
                assert digest(REPO / path) == sha
                dst = root / path
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(REPO / path, dst)
        for inventory in INVENTORIES:
            run(["sha256sum", "-c", inventory], clean, "integrity.log")
        for source in sources:
            dst = clean / source.relative_to(FULL)
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, dst)
        lean = clean / "lean"
        shutil.copy2(HERE / "Gate.lean", lean / "DemandGate.lean")
        modules = [".".join(p.relative_to(FULL / "lean").with_suffix("").parts) for p in sources]
        run(["lake", "env", "lean", "--version"], lean, "build.log")
        run(["lake", "build", "Full", "Full.Proofs", *modules], lean, "build.log")
        run(["lake", "env", "lean", "-o", ".lake/build/lib/lean/DemandGate.olean",
             "DemandGate.lean"], lean, "gate.log")
        names = sorted(re.findall(r"^PUBLIC_THEOREM (\S+)$", (OUT / "gate.log").read_text(), re.M))
        assert names and len(names) == len(set(names))
        assert "Full.Demand.Soundness.conditional" in names
        gate = "import DemandGate\n\n" + "".join(
            f"#check {name}\n#print axioms {name}\n" for name in names)
        (OUT / "Audit.lean").write_text(gate)
        (lean / "DemandAudit.lean").write_text(gate)
        run(["lake", "env", "lean", "-o", ".lake/build/lib/lean/DemandAudit.olean",
             "DemandAudit.lean"], lean, "axioms.log")
        axiom_sets = audit("axioms.log", names)
        run(["lake", "env", "leanchecker", "--fresh", "DemandAudit"], lean, "kernel.log")
        run(["lake", "env", "lean", "-o", ".lake/build/lib/lean/ProofGate.olean",
             "ProofGate.lean"], lean, "stage1-gate.log")
        audit("stage1-gate.log", [f"Full.Proofs.{n}" for n in
                                 ["f1", "f2", "f3", "f4", "f5", "f6", "l1", "l2"]])
        run(["lake", "env", "leanchecker", "--fresh", "ProofGate"], lean, "stage1-kernel.log")
        observations = root / "observations"
        run(["python3", "-B", str(clean / "run_spec.py"), str(observations)], lean, "finite-suite.log")
        run(["python3", "-B", str(clean / "acceptance/supplemental-v2/check_expanded.py"),
             str(observations), "--report", str(OUT / "expanded-results.json")], lean, "expanded.log")
        run(["python3", "-B", str(clean / "verification/check_final.py"), str(observations),
             "--report", str(OUT / "boundary-results.json")], lean, "boundaries.log")
        with gzip.open(clean / "stage-1/rank-amendment-01/evidence/raw.json.gz", "rb") as src:
            historical = hashlib.file_digest(src, "sha256").hexdigest()
        assert digest(observations / "raw.json") == historical
        for name in ["inputs.json", "summary.json"]:
            shutil.copy2(observations / name, OUT / name)
        (OUT / "raw.sha256").write_text(f"{historical}  raw.json (existing D191 release asset)\n")
        run(["lake", "-d", "../../trial/lean", "build", "Checks"], lean, "trial-build.log")
        run(["lake", "env", "lean", "--run", "TrialCompatibility.lean"], lean, "trial.log")
        run(["lake", "env", "lean", "--run", "../verification/ReviewCases.lean"], lean, "review-cases.log")
        run(["lake", "env", "lean", "-o", ".lake/build/lib/lean/Export.olean", "Export.lean"], lean, "controls.log")
        env = dict(os.environ, FULL3C_INPUTS=str(observations / "inputs.json"))
        run(["lake", "env", "lean", "../verification/Controls.lean"], lean, "controls.log", env)
    # Reuse the separately authored scientific consumer byte-for-byte except
    # redirecting its output. Expectations, mutations and checks are untouched.
    consumer = FULL / "stage-2/verification-preflight/verify.py"
    text = consumer.read_text()
    old = 'EVIDENCE = HERE / "evidence"'
    assert text.count(old) == 1
    redirected = text.replace(old, f"EVIDENCE = Path({str(OUT / 'checker')!r})")
    with (OUT / "checker-campaign.log").open("w") as log:
        result = subprocess.run([sys.executable, "-B", "-c",
            f"__file__ = {str(consumer)!r}\n" + redirected], cwd=REPO,
            stdout=log, stderr=subprocess.STDOUT)
        result.check_returncode()
    assert hashes == {str(p.relative_to(FULL)): digest(p) for p in inputs}
    for inventory in INVENTORIES:
        run(["sha256sum", "-c", inventory], FULL, "integrity.log")
    result = {"exact_conditional": True, "public_theorems_including_generated": len(names),
              "axiom_sets": axiom_sets, "fresh_kernel": True,
              "stage1_exact_gate_and_kernel": True, "raw_equals_archived_D191": historical,
              "finite_and_checker_controls_pass": True, "separate_verification": "required"}
    (OUT / "result.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
