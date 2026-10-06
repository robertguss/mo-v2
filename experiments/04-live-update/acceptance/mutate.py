"""Lead-selected mutation sites; expectations remain in the pre-builder lock.

Run against this exact candidate, in disposable copies, never the live runtime.
This file is an execution recipe written after inspecting the builder source,
as expressly allowed by ACCEPTANCE.md step 6. It does not redefine acceptance.
"""
import difflib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]
EVIDENCE = BASE / "evidence" / "mutations"
JAR = Path("/tmp/mo-live-update-tools/tla2tools-1.7.4.jar")


def replace_once(source, old, new):
    assert source.count(old) == 1, (old, source.count(old))
    return source.replace(old, new)


def rust_mutant(name, source):
    if name == "lost_work":
        return replace_once(source,
            "self.queue = Queue::V2(std::mem::take(&mut self.candidate));",
            "self.queue = Queue::V2(std::mem::take(&mut self.candidate));\n"
            "                    if let Queue::V2(q) = &mut self.queue { q.clear(); }")
    if name == "duplicate_completion":
        return replace_once(source, "self.completed.push(job.id);",
                            "self.completed.push(job.id);\n                self.completed.push(job.id);")
    if name == "premature_activation":
        source = replace_once(source, 'if self.phase != "ready" {',
                              'if !matches!(self.phase, "ready" | "draining") {')
        return replace_once(source, "self.valid_candidate() && self.flight.is_none()",
                            "self.valid_candidate()")
    if name == "corrupt_activation":
        return replace_once(source, "self.valid_candidate() && self.flight.is_none()",
                            "self.flight.is_none()")
    if name == "expired_activation":
        return replace_once(source, 'if self.phase != "ready" {',
                            'if self.phase != "ready" && self.outcome != "refused" {')
    raise AssertionError(name)


def model_mutant(name, source):
    if name == "duplicate_completion":
        return replace_once(source, "completed' = Append(completed, flight)",
                            "completed' = Append(Append(completed, flight), flight)")
    if name == "lost_work":
        return replace_once(source,
            "/\\ UNCHANGED <<queue, flight, flight_version, accepted,\n"
            "                                       completed, completed_values, attempted>>",
            "/\\ queue' = <<>>\n"
            "                       /\\ UNCHANGED <<flight, flight_version, accepted,\n"
            "                                       completed, completed_values, attempted>>")
    raise AssertionError(name)


def record_patch(name, old, new):
    patch = "".join(difflib.unified_diff(old.splitlines(True), new.splitlines(True),
                                       fromfile="accepted-source", tofile=name))
    (EVIDENCE / (name + ".patch")).write_text(patch)


def run_capture(name, command, cwd=None):
    result = subprocess.run(command, cwd=cwd, text=True, capture_output=True, timeout=300)
    (EVIDENCE / (name + ".stdout")).write_text(result.stdout)
    (EVIDENCE / (name + ".stderr")).write_text(result.stderr)
    return {"command": command, "exit": result.returncode}, result


def main():
    EVIDENCE.mkdir(exist_ok=True)
    results = {}
    source = (BASE / "runtime/src/main.rs").read_text()
    for name in ("lost_work", "duplicate_completion", "premature_activation",
                 "corrupt_activation", "expired_activation"):
        new = rust_mutant(name, source)
        record_patch("runtime-" + name, source, new)
        with tempfile.TemporaryDirectory(prefix="mo-runtime-control-") as temp:
            root = Path(temp)
            (root / "src").mkdir()
            (root / "src/main.rs").write_text(new)
            for filename in ("Cargo.toml", "Cargo.lock"):
                shutil.copyfile(BASE / "runtime" / filename, root / filename)
            build, process = run_capture("runtime-" + name + "-build", [
                "cargo", "build", "--locked", "--offline", "--release",
                "--manifest-path", str(root / "Cargo.toml")])
            assert process.returncode == 0, (name, "control did not compile")
            check, process = run_capture("runtime-" + name + "-check", [
                sys.executable, str(BASE / "acceptance/run.py"), "--binary",
                str(root / "target/release/mo-live-update"), "--control", name])
            assert process.returncode != 0 and "AssertionError:" in process.stderr, name
            assert '"expected":' in process.stderr and '"actual":' in process.stderr, name
            results["runtime-" + name] = {"build": build, "check": check, "detected": True}
    source = (BASE / "model/LiveUpdate.tla").read_text()
    for name in ("lost_work", "duplicate_completion"):
        new = model_mutant(name, source)
        record_patch("model-" + name, source, new)
        with tempfile.TemporaryDirectory(prefix="mo-model-control-") as temp:
            root = Path(temp)
            (root / "LiveUpdate.tla").write_text(new)
            shutil.copyfile(BASE / "model/LiveUpdate.cfg", root / "LiveUpdate.cfg")
            check, process = run_capture("model-" + name, [
                "java", "-Xmx1g", "-cp", str(JAR), "tlc2.TLC", "-workers", "1",
                "-config", "LiveUpdate.cfg", "LiveUpdate.tla"], cwd=root)
            assert process.returncode != 0, name
            assert "Invariant Safety is violated" in process.stdout, name
            results["model-" + name] = {"check": check, "detected": True}
    (EVIDENCE / "results.json").write_text(json.dumps(results, indent=2) + "\n")
    print(json.dumps({name: value["detected"] for name, value in results.items()}, indent=2))


if __name__ == "__main__":
    main()
