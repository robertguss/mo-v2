#!/usr/bin/env python3
"""Cache-free check of the proof prefix, NOT the missing Conditional theorem."""
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
import tempfile
import os

FULL = Path(__file__).resolve().parent.parent
REPO = FULL.parents[2]
EVIDENCE = FULL / "stage-2/auxiliary/evidence"
BASE = "66f8aac22fbaa31100700a5ca9e5b486efd67c28"
INVENTORIES = [
    "BASELINE.sha256", "FREEZE.sha256",
    "stage-1/rank-amendment-01/FREEZE.sha256",
    "stage-1/rank-amendment-01/PREPARATION.sha256",
    "stage-1/rank-amendment-01/EVIDENCE.sha256",
    "stage-1/completion/PROOFS.sha256",
]


def run(args, cwd, log, env=None):
    with (EVIDENCE / log).open("a") as out:
        out.write("$ " + " ".join(map(str, args)) + "\n")
        out.flush()
        subprocess.run(args, cwd=cwd, stdout=out, stderr=subprocess.STDOUT,
                       env=env, check=True)


def main():
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    for log in EVIDENCE.glob("*.log"):
        log.unlink()
    for inventory in INVENTORIES:
        run(["sha256sum", "-c", inventory], FULL, "integrity.log")
    sources = [FULL / "lean/Full/Demand.lean", *sorted((FULL / "lean/Full/Demand").glob("*.lean"))]
    hashes = {str(p.relative_to(FULL)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}
    (EVIDENCE / "sources.sha256").write_text("".join(f"{h}  {p}\n" for p, h in hashes.items()))
    names, modules = [], []
    for source in sources:
        text = source.read_text()
        namespaces = re.findall(r"^namespace (\S+)$", text, re.M)
        assert len(namespaces) == 1, source
        modules.append(".".join(source.relative_to(FULL / "lean").with_suffix("").parts))
        names.extend(namespaces[0] + "." + name for name in
                     re.findall(r"^(?:@\[[^\n]*\] )?theorem ([\w.]+)", text, re.M))
    assert names and len(names) == len(set(names))
    gate = "-- Auxiliary proof prefix only; no Conditional proof is claimed.\n"
    gate += "".join(f"import {module}\n" for module in modules)
    gate += "\n" + "".join(f"#check {name}\n#print axioms {name}\n" for name in names)
    (EVIDENCE / "AuxiliaryGate.lean").write_text(gate)

    with tempfile.TemporaryDirectory(prefix="rob1139-stage2-aux-") as temp:
        root = Path(temp)
        archive = root / "base.tar"
        with archive.open("wb") as out:
            subprocess.run(["git", "archive", BASE, "experiments/03c-checker/full",
                            "experiments/03c-checker/trial"], cwd=REPO, stdout=out, check=True)
        with tarfile.open(archive) as tar:
            tar.extractall(root, filter="data")
        clean = root / FULL.relative_to(REPO)
        assert not list(root.rglob(".lake"))
        # Only the two public full-3c archives; never private experiment-13 data.
        for line in (REPO / "experiments/GZ_ARCHIVE.sha256").read_text().splitlines():
            digest, path = line.split(maxsplit=1)
            if path.startswith("experiments/03c-checker/full/"):
                src = REPO / path
                assert hashlib.sha256(src.read_bytes()).hexdigest() == digest
                dst = root / path
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dst)
        for inventory in INVENTORIES:
            run(["sha256sum", "-c", inventory], clean, "integrity.log")
        for source in sources:
            dest = clean / source.relative_to(FULL)
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, dest)
        lean = clean / "lean"
        (lean / "AuxiliaryGate.lean").write_text(gate)
        run(["lake", "env", "lean", "--version"], lean, "build.log")
        run(["lake", "build", *modules], lean, "build.log")
        run(["lake", "env", "lean", "-o", ".lake/build/lib/lean/AuxiliaryGate.olean",
             "AuxiliaryGate.lean"], lean, "gate.log")
        output = (EVIDENCE / "gate.log").read_text()
        audit = re.findall(r"'([^']+)' depends on axioms: \[([^\]]*)\]", output)
        empty = re.findall(r"'([^']+)' does not depend on any axioms", output)
        assert set(names) == {name for name, _ in audit} | set(empty)
        allow = {"propext", "Classical.choice", "Quot.sound"}
        for name, axioms in audit:
            assert set(filter(None, map(str.strip, axioms.split(",")))) <= allow, (name, axioms)
        run(["lake", "env", "leanchecker", "--fresh", "AuxiliaryGate"], lean, "kernel.log")
        shutil.copy2(FULL / "stage-2/Run.lean", lean / "stage-2-run.lean")
        run(["lake", "env", "lean", "-o", ".lake/build/lib/lean/Export.olean", "Export.lean"],
            lean, "execution.log")
        env = dict(os.environ, FULL3C_INPUTS=str(FULL / "stage-1/completion/evidence/inputs.json"),
                   FULL3C_DEMAND_OUTPUT=str(EVIDENCE / "observed.json"))
        run(["lake", "env", "lean", "stage-2-run.lean"], lean, "execution.log", env)
        assert json.loads((EVIDENCE / "observed.json").read_text()) == json.loads(
            (FULL / "stage-2/verification-preflight/evidence/original.json").read_text())
    assert hashes == {str(p.relative_to(FULL)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}
    for inventory in INVENTORIES:
        run(["sha256sum", "-c", inventory], FULL, "integrity.log")
    result = {"auxiliary_theorems": len(names), "cache_free_build": True,
              "axiom_allowlist": sorted(allow), "fresh_kernel": True,
              "checker_rows_equal_to_separate_preflight": 90,
              "conditional_theorem_delivered": False, "stage_2_complete": False}
    (EVIDENCE / "result.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
