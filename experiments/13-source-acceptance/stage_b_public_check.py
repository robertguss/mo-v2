"""Independent public checks for one Stage B candidate archive.

This is acceptance-owned. It does not change the candidate or any frozen file.
It does not run private cases, sabotage controls, or either million-element
workload. The candidate directory is extracted beside the public runtime for
the build and is not repository content.
"""
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
import traceback
from pathlib import Path

import integration
from cases import examples
from integration import Origins
from linked import run_linked
from syntax import parse


HERE = Path(__file__).resolve().parent
ARCHIVE_SHA = "7babb36cd741b44354157ee33fc1fd741f882c6bab314ebe9217197813fed590"
ARCHIVE_BYTES = 38678
MANIFEST_SHA = "9387747ac744896aa6eb9a906bcddb6c4597eed406fe2b9e47d1bbc7090e616e"
TOOLCHAIN = "1.98.1"
TARGET = Path("/tmp/mo-stage-b-public-target")

_DIFFS = []


def exact(actual, expected, message):
    actual_text = json.dumps(actual, sort_keys=True)
    expected_text = json.dumps(expected, sort_keys=True)
    if actual_text != expected_text:
        _DIFFS.append(dict(message=message, actual=actual, expected=expected))
        raise AssertionError(message)
    return None


integration.exact = exact


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def frozen_hashes():
    lock = json.loads((HERE / "STAGE_A_LOCK.json").read_text())
    rows = {}
    for rel, digest in lock["files"].items():
        rows[rel] = sha256(HERE / rel)
        if rows[rel] != digest:
            raise SystemExit("frozen file already differs before the check: " + rel)
    return rows


def extract(archive, destination):
    if destination.exists():
        shutil.rmtree(destination)
    destination.mkdir(parents=True)
    subprocess.run(["tar", "-xzf", str(archive), "-C", str(destination), "--strip-components=1"],
                   check=True)
    return destination


def region_at(text, index):
    module = text.rfind("\n#[cfg(test)]\n", 0, index)
    if module >= 0 and "\nmod tests" in text[module:index + 20]:
        return "cfg(test)"
    line_start = text.rfind("\n", 0, index) + 1
    previous = text.rfind("\n", 0, line_start - 1) + 1
    if text[previous:line_start].strip() == "#[cfg(test)]":
        return "cfg(test)"
    return "production"


def audit(root):
    names = ["lib.rs", "frontend.rs", "execution.rs", "number.rs", "Cargo.toml", "HANDOFF.md"]
    patterns = {
        "acceptance python module": re.compile(
            r"\b(syntax|cases|integration|linked|predicates|transition_reference|call_reference|"
            r"finite_reference|generated|privatecheck|controlcheck)\.py\b"),
        "acceptance crate": re.compile(r"\b(mo_acceptance_driver|acceptance_cells)\b"),
        "case identifier": re.compile(r"\bC1[0-4](?:-[A-Za-z0-9]+)?\b"),
        "native mock": re.compile(r"\bNoCells\b|\bmock\b"),
        "old im path": re.compile(r"\bim::"),
    }
    findings = []
    for name in names:
        text = (root / name).read_text()
        for label, pattern in patterns.items():
            for match in pattern.finditer(text):
                line = text[:match.start()].count("\n") + 1
                findings.append(dict(
                    file=name, region=region_at(text, match.start()) if name.endswith(".rs") else "prose",
                    pattern=label, line=line, match=match.group(0)))
    frontend = (root / "frontend.rs").read_text()
    execution = (root / "execution.rs").read_text()
    frontend_prod = frontend.split("\n#[cfg(test)]\n", 1)[0]
    execution_prod = execution.split("\n#[cfg(test)]\n", 1)[0]
    structure = dict(
        production_lex=frontend_prod.count("fn lex("),
        production_check=frontend_prod.count("fn check("),
        production_parse_in_execution=len(re.findall(r"\bfn parse\b|\bfn lex\b", execution_prod)),
        production_machines=execution_prod.count("struct Machine"),
    )
    blocking = [row for row in findings if row["region"] == "production" or (
        row["region"] == "prose" and row["file"] != "HANDOFF.md")]
    return dict(findings=findings, blocking=blocking, structure=structure)


def step_count(case):
    program = parse(case["source"])
    limit = 60 if case.get("value", 0) is None else 20000
    reference = Origins(program, case["cells"], case["inputs"], case["outside"], landmark_limit=limit)
    reference.observe(program["main"])
    return len(reference.trace)


def one_run(command, case, budgets, destination):
    _DIFFS.clear()
    if destination.exists():
        shutil.rmtree(destination)
    try:
        report = run_linked(command, case, budgets, destination, stage="B", fixture_stub=False)
    except Exception as error:
        summary_path = destination / "summary.json"
        summary = json.loads(summary_path.read_text()) if summary_path.exists() else {}
        diff = _DIFFS[0] if _DIFFS else None
        return dict(passed=False, error=f"{type(error).__name__}: {error}",
                    summary_error=summary.get("error"), diff=diff,
                    stderr=(destination / "stderr.txt").read_text(errors="replace") if (destination / "stderr.txt").exists() else "")
    return dict(passed=True, steps=report["committed_steps"], destroy_calls=report["destroy_calls"],
                advances=report["advances"])


def main():
    archive = Path(sys.argv[1]).resolve()
    evidence = Path(sys.argv[2]).resolve()
    evidence.mkdir(parents=True, exist_ok=False)
    started = time.time()
    report = dict(passed=False, candidate_executed=False, private_cases=0, controls_executed=0,
                  million_element_runs=0)
    before = frozen_hashes()
    candidate = HERE / "candidate-stage-b"
    try:
        data = archive.read_bytes()
        report["integrity"] = dict(
            archive=str(archive),
            archive_bytes=len(data),
            archive_sha256=hashlib.sha256(data).hexdigest(),
            archive_sha_matches=hashlib.sha256(data).hexdigest() == ARCHIVE_SHA and len(data) == ARCHIVE_BYTES,
        )
        extract(archive, candidate)
        manifest = (candidate / "CANDIDATE.sha256").read_bytes()
        members = []
        manifest_ok = hashlib.sha256(manifest).hexdigest() == MANIFEST_SHA
        for line in manifest.decode().splitlines():
            digest, name = line.split("  ", 1)
            got = sha256(candidate / name)
            members.append(dict(name=name, sha256=got, matches=got == digest, bytes=(candidate / name).stat().st_size))
            manifest_ok = manifest_ok and got == digest
        names = sorted(p.name for p in candidate.iterdir() if p.is_file())
        lib = (candidate / "lib.rs").read_text()
        report["integrity"].update(
            manifest_sha256=hashlib.sha256(manifest).hexdigest(),
            manifest_matches=manifest_ok,
            member_count=len(members) + 1,
            content_files=len(members),
            members=members,
            inventory=names,
            crate="mo-stage-b" if 'name = "mo-stage-b"' in (candidate / "Cargo.toml").read_text() else None,
            export="mo_stage_b::StageB" if "pub struct StageB;" in lib and "impl Candidate for StageB" in lib else None,
        )
        report["audit"] = audit(candidate)
        if report["audit"]["blocking"]:
            raise RuntimeError("source audit found a production forbidden pattern")
        env = dict(os.environ, CARGO_TARGET_DIR=str(TARGET))
        TARGET.mkdir(parents=True, exist_ok=True)
        lock_before = sha256(candidate / "Cargo.lock")
        commands = [
            ["cargo", f"+{TOOLCHAIN}", "fetch", "--locked", "--manifest-path", "candidate-stage-b/Cargo.toml"],
            ["cargo", f"+{TOOLCHAIN}", "build", "--locked", "--offline", "--manifest-path", "candidate-stage-b/Cargo.toml"],
            ["cargo", f"+{TOOLCHAIN}", "fetch", "--locked", "--manifest-path", "stage-b-link/Cargo.toml"],
            ["cargo", f"+{TOOLCHAIN}", "build", "--locked", "--offline", "--manifest-path", "stage-b-link/Cargo.toml"],
            ["cargo", f"+{TOOLCHAIN}", "test", "--locked", "--offline", "--manifest-path", "candidate-stage-b/Cargo.toml"],
            ["cargo", f"+{TOOLCHAIN}", "tree", "--locked", "--prefix", "none", "--manifest-path", "candidate-stage-b/Cargo.toml"],
        ]
        builds = []
        for command in commands:
            result = subprocess.run(command, cwd=HERE, capture_output=True, text=True, env=env)
            log_name = "build-" + command[2] + "-" + Path(command[-1]).parent.name + ".log"
            (evidence / log_name).write_text(result.stdout + result.stderr)
            builds.append(dict(command=command, exit_code=result.returncode, log=log_name))
            if result.returncode != 0:
                report["build"] = dict(commands=builds, lock_unchanged=sha256(candidate / "Cargo.lock") == lock_before)
                raise RuntimeError("build command failed: " + " ".join(command))
        tree = (evidence / "build-tree-candidate-stage-b.log").read_text().splitlines()
        packages = sorted({line.split()[0] for line in tree if line.strip()})
        link_lock_after_fetch = sha256(HERE / "stage-b-link" / "Cargo.lock")
        report["build"] = dict(
            commands=builds,
            candidate_lock_unchanged=sha256(candidate / "Cargo.lock") == lock_before,
            linker_lock_sha256=link_lock_after_fetch,
            packages=packages,
            contains_im=any(name == "im" for name in packages),
            contains_sized_chunks=any(name == "sized-chunks" for name in packages),
            contains_imbl="imbl" in packages,
            binary=str(TARGET / "debug" / "rob1333-stage-b-link"),
            binary_sha256=sha256(TARGET / "debug" / "rob1333-stage-b-link"),
        )
        passed_line = [line for line in (evidence / "build-test-candidate-stage-b.log").read_text().splitlines()
                       if line.startswith("test result:")]
        report["build"]["test_results"] = passed_line

        command = [str(TARGET / "debug" / "rob1333-stage-b-link")]
        runs = []
        work = Path("/tmp/stage-b-public-one-run")
        report["candidate_executed"] = True
        for case in examples():
            name = case["name"]
            count = step_count(case)
            terminating = case.get("value", 0) is not None
            plan = [("full", None, [count])]
            for cut in range(count + 1):
                if terminating:
                    plan.append(("resume", cut, [cut, 0, count - cut, 0, 9]))
                else:
                    plan.append(("resume", cut, [cut, 0, count - cut]))
                plan.append(("destroy", cut, [cut]))
            example_failed = False
            for mode, cut, budgets in plan:
                outcome = one_run(command, case, budgets, work)
                row = dict(name=name, mode=mode, cut=cut, steps_expected=count,
                           **{k: v for k, v in outcome.items() if k != "diff"})
                runs.append(row)
                if not outcome["passed"]:
                    example_failed = True
                    if "first_failure" not in report:
                        failed = evidence / "first-failure"
                        if failed.exists():
                            shutil.rmtree(failed)
                        if work.exists():
                            shutil.copytree(work, failed)
                        if outcome.get("diff"):
                            (evidence / "first-difference.json").write_text(
                                json.dumps(outcome["diff"], indent=2) + "\n")
                        report["first_failure"] = row
                    print(f"FAIL {name} {mode} cut={cut} steps={count}: {outcome['error']}", flush=True)
                    break
            if not example_failed:
                print(f"PASS {name} steps={count} runs={sum(1 for r in runs if r['name']==name)}", flush=True)
        report["examples"] = dict(
            examples=len(examples()),
            matched=sum(1 for case in examples() if any(
                r["name"] == case["name"] and r["mode"] == "full" and r["passed"] for r in runs)),
            failed=sum(1 for case in examples() if any(
                r["name"] == case["name"] and r["mode"] == "full" and not r["passed"] for r in runs)),
            runs=len(runs),
            passed_runs=sum(1 for r in runs if r["passed"]),
            full=sum(1 for r in runs if r["mode"] == "full"),
            resume=sum(1 for r in runs if r["mode"] == "resume" and r["passed"]),
            destroy=sum(1 for r in runs if r["mode"] == "destroy" and r["passed"]),
            committed_steps_on_matched_full_runs=sum(
                r["steps"] for r in runs if r["mode"] == "full" and r["passed"]),
        )
        report["passed"] = report["examples"]["failed"] == 0 and report["integrity"]["archive_sha_matches"]
        (evidence / "runs.jsonl").write_text("".join(json.dumps(row) + "\n" for row in runs))
    except Exception:
        report["error"] = traceback.format_exc()
    finally:
        after = {}
        lock = json.loads((HERE / "STAGE_A_LOCK.json").read_text())
        changed = []
        for rel in lock["files"]:
            after[rel] = sha256(HERE / rel)
            if after[rel] != before.get(rel, after[rel]):
                changed.append(rel)
        supplied = []
        if candidate.exists():
            for path in sorted(candidate.rglob("*")):
                if path.is_file() and "target" not in path.parts:
                    supplied.append(str(path.relative_to(candidate)))
        report["unchanged"] = dict(frozen_files=len(lock["files"]), frozen_changed=changed,
                                    supplied_files=len(supplied))
        if changed:
            report["passed"] = False
        report["elapsed_seconds"] = round(time.time() - started, 3)
        (evidence / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
        print(json.dumps({k: report[k] for k in report if k not in ("audit", "integrity")}, indent=2))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
