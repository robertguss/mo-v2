"""Private continuation for the adapted candidate; frozen per-run checks unchanged.

Usage: python3 run_private.py NEW_PRIVATE_DIRECTORY VERIFIED_BINARY
Only aggregate output is printed. Evidence must remain outside the checkout.
The schedule and conservative pilot/projection are retained from the earlier
owner-approved private runner; no new cases or predicates are introduced.
"""
import ast
import concurrent.futures
import gzip
import hashlib
import json
import multiprocessing
import os
from pathlib import Path
import sys
import time
import traceback

sys.dont_write_bytecode = True
SOURCE = Path(__file__).resolve().parent
HERE = Path(sys.argv[1]).resolve()
BASE = SOURCE.parent
sys.path.insert(0, str(BASE))
from integration import Origins
from linked import run_linked
from syntax import parse

CORPUS = Path("/home/user/rob-1333-private-v11/cases.jsonl.gz")
COMMAND = [str(Path(sys.argv[2]).resolve())]
WORKERS = 4
EXPECTED_CORPUS = "0f176c60d30d30fffd4d7fb25d982cd3517d1a847840027ad3e99f9c572f41f0"
EXPECTED_BINARY = "7b38989835db8ef6fd274477f625caf5c35e6438256d405f4b5242703427491a"
EXPECTED_MANIFEST = "cc1e09dac565f67341bffee062fa0abbd080f9c60ebeac2fed522f56ff14317e"
EXPECTED_WRAPPER = "3687b77bf2f65081eb6535da2c2acfc3018fa986ace783c8b18e2087f2c00b43"


def digest(path):
    with path.open("rb") as f:
        return hashlib.file_digest(f, "sha256").hexdigest()


def verify_integrity():
    assert digest(CORPUS) == EXPECTED_CORPUS and CORPUS.stat().st_size == 1003653
    assert digest(Path(COMMAND[0])) == EXPECTED_BINARY
    assert digest(SOURCE / "candidate/CANDIDATE.sha256") == EXPECTED_MANIFEST
    for candidate in (SOURCE / "candidate", BASE / "candidate-stage-b"):
        for line in (candidate / "CANDIDATE.sha256").read_text().splitlines():
            h, name = line.split("  ", 1)
            assert digest(candidate / name) == h
    revision = BASE / "stage-b-revision-02"
    assert digest(revision / "LOCK.json") == "5749ccb78db090744b9e96c6030e92a80b83776accbf21f5a1dc66e32fa523fc"
    for name, record in json.loads((revision / "LOCK.json").read_text())["files"].items():
        assert digest(revision / name) == record["sha256"]
    assert digest(BASE / "stage_b_public_check.py") == EXPECTED_WRAPPER
    for name, want in (("STAGE_A_LOCK.json", "09c64493ba65f94451dc17c5bde7c4b54554d6990b23b8c877f2f9741f120c9e"),
                       ("STAGE_B_LOCK.json", "2df4234fd86336b44307bee722972cf9f9c70a89b384d853db31e40d82ba5cbb")):
        assert digest(BASE / name) == want
        lock = json.loads((BASE / name).read_text())
        for path, h in lock["files"].items():
            assert digest(BASE / path) == h
        for path, h in lock.get("historical_dependencies", {}).items():
            assert digest(BASE.parent.parent / path) == h


def step_count(case):
    program = parse(case["source"])
    limit = 60 if case.get("value", 0) is None else 20000
    reference = Origins(program, case["cells"], case["inputs"], case["outside"], landmark_limit=limit)
    reference.observe(program["main"])
    return len(reference.trace)


def schedule(case, count):
    terminating = case.get("value", 0) is not None
    plan = [("full", None, [count])]
    for cut in range(count + 1):
        if terminating:
            plan.append(("resume", cut, [cut, 0, count - cut, 0, 9]))
        else:
            plan.append(("resume", cut, [cut, 0, count - cut]))
        plan.append(("destroy", cut, [cut]))
    return plan


def verify_schedule_copy():
    public = ast.parse((BASE / "stage_b_public_check.py").read_text())
    own = ast.parse(Path(__file__).read_text())
    f = lambda tree, name: next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == name)
    assert ast.dump(f(public, "step_count")) == ast.dump(f(own, "step_count"))
    main = f(public, "main")
    loop = next(n for n in ast.walk(main) if isinstance(n, ast.For) and isinstance(n.target, ast.Name) and n.target.id == "case")
    # The three statements defining termination, full run, and every-boundary cuts.
    public_plan = loop.body[2:5]
    assert ast.dump(ast.Module(body=public_plan, type_ignores=[])) == ast.dump(
        ast.Module(body=f(own, "schedule").body[:3], type_ignores=[]))


def run_case(job):
    ordinal, case, group = job
    started = time.monotonic()
    folder = HERE / "private-evidence" / f"case-{ordinal:04d}"
    folder.mkdir(parents=True, exist_ok=False)
    result = dict(ordinal=ordinal, group=group, passed=False, blocked=False,
                  runs={k: dict(passed=0, failed=0) for k in ("full", "resume", "destroy")})
    try:
        count = step_count(case)
        result["steps"] = count
        result["planned_runs"] = 1 + 2 * (count + 1)
        for number, (mode, cut, budgets) in enumerate(schedule(case, count)):
            destination = folder / f"shard-{number // 500:04d}" / f"run-{number:05d}"
            try:
                run_linked(COMMAND, case, budgets, destination, stage="B", fixture_stub=False)
            except Exception as error:
                result["runs"][mode]["failed"] += 1
                # Like the public wrapper, stop this case at its first failed run.
                # Infrastructure failures stop the campaign instead of being scored.
                result["blocked"] = (not destination.exists() or
                    (isinstance(error, OSError) and not isinstance(error, TimeoutError)))
                result["failure_category"] = (
                    "infrastructure-or-preparation" if result["blocked"] else
                    "watchdog" if isinstance(error, TimeoutError) else
                    "frozen-verdict-rejection" if isinstance(error, AssertionError) else
                    "protocol-or-harness-rejection")
                (folder / "failure-private.txt").write_text(traceback.format_exc())
                break
            else:
                result["runs"][mode]["passed"] += 1
        else:
            result["passed"] = True
    except Exception:
        result["blocked"] = True
        result["failure_category"] = "preparation-error"
        (folder / "failure-private.txt").write_text(traceback.format_exc())
    result["elapsed_seconds"] = time.monotonic() - started
    (folder / "result.json").write_text(json.dumps(result, indent=2) + "\n")
    return result


def aggregate(results, elapsed):
    groups = {f"reserved-family-{n}": dict(total=3, passed=0, failed=0, not_run=3) for n in range(1, 9)}
    groups["generated-unlabelled"] = dict(total=500, passed=0, failed=0, not_run=500)
    run_counts = {k: dict(passed=0, failed=0) for k in ("full", "resume", "destroy")}
    failures = {}
    for r in results:
        if not r["blocked"]:
            groups[r["group"]]["passed" if r["passed"] else "failed"] += 1
            groups[r["group"]]["not_run"] -= 1
        for mode in run_counts:
            for verdict in run_counts[mode]:
                run_counts[mode][verdict] += r["runs"][mode][verdict]
        if "failure_category" in r:
            key = r["failure_category"]
            failures[key] = failures.get(key, 0) + 1
    return dict(passed=sum(g["passed"] for g in groups.values()),
                failed=sum(g["failed"] for g in groups.values()),
                not_run=sum(g["not_run"] for g in groups.values()),
                groups=groups, runs=run_counts, failure_categories=failures,
                completed_cases=len(results), elapsed_seconds=round(elapsed, 3))


def main():
    os.umask(0o077)
    assert not HERE.is_relative_to(BASE.parent.parent), "private evidence must remain outside checkout"
    HERE.mkdir(parents=True, exist_ok=False)
    started = time.monotonic()
    verify_integrity()
    verify_schedule_copy()
    runner_hash = digest(Path(__file__))
    binary_hash = digest(Path(COMMAND[0]))
    assert not (HERE / "private-evidence").exists()
    with gzip.open(CORPUS, "rt") as f:
        cases = [json.loads(line) for line in f]
    assert len(cases) == 524
    families, jobs = {}, []
    for ordinal, case in enumerate(cases):
        if "index" in case:
            group = "generated-unlabelled"
        else:
            family = case["family"]
            if family not in families:
                families[family] = len(families) + 1
            group = f"reserved-family-{families[family]}"
        jobs.append((ordinal, case, group))
    assert len(families) == 8 and sum(j[2] == "generated-unlabelled" for j in jobs) == 500
    # Four cases selected deterministically by retained trace length: median and
    # longest from each group. No new examples, expectations or verdicts.
    pilot = []
    for generated in (False, True):
        group = sorted((j for j in jobs if (j[2] == "generated-unlabelled") == generated),
                       key=lambda j: (len(j[1]["expected"]["trace"]), j[0]))
        pilot.extend((group[len(group) // 2], group[-1]))
    weights = {j[0]: max(1, len(j[1]["expected"]["trace"])) *
               (1 + 2 * (len(j[1]["expected"]["trace"]) + 1)) for j in jobs}
    results = []
    projection = None
    stop = None
    ledger = (HERE / "private-completed.jsonl").open("x")

    def collect(result):
        results.append(result)
        ledger.write(json.dumps(result) + "\n")
        ledger.flush()
        summary = aggregate(results, time.monotonic() - started)
        (HERE / "aggregate-progress.json").write_text(json.dumps(summary, indent=2) + "\n")
        print(json.dumps({k: summary[k] for k in ("completed_cases", "passed", "failed", "not_run", "elapsed_seconds")}), flush=True)

    with concurrent.futures.ProcessPoolExecutor(max_workers=WORKERS,
            mp_context=multiprocessing.get_context("spawn")) as pool:
        futures = [pool.submit(run_case, job) for job in pilot]
        for future in concurrent.futures.as_completed(futures):
            collect(future.result())
        if any(r["blocked"] for r in results):
            stop = "pilot-infrastructure-or-preparation-blocker"
        else:
            # A conservative factor of two; no speculative scaling beyond the
            # same four worker processes used by the measured pilot.
            seconds_per_weight = max(r["elapsed_seconds"] /
                max(1, max(1, r["steps"]) * sum(sum(c.values()) for c in r["runs"].values()))
                for r in results)
            remaining = sum(w for ordinal, w in weights.items() if ordinal not in {r["ordinal"] for r in results})
            projection = time.monotonic() - started + 2 * seconds_per_weight * remaining / WORKERS
            (HERE / "projection.json").write_text(json.dumps(dict(pilot_cases=4, workers=WORKERS,
                projected_total_seconds=projection, safety_factor=2,
                method="slowest pilot seconds per step-weighted attempted run; all remaining planned cuts; same worker count"), indent=2) + "\n")
            print(json.dumps(dict(pilot_cases=4, workers=WORKERS, projected_total_seconds=round(projection, 3))), flush=True)
            if projection > 7200:
                stop = "projection-exceeds-two-hours"
        if stop is None:
            pending_jobs = iter(j for j in jobs if j[0] not in {r["ordinal"] for r in results})
            pending = {pool.submit(run_case, next(pending_jobs)) for _ in range(WORKERS)}
            while pending:
                done, pending = concurrent.futures.wait(pending, return_when=concurrent.futures.FIRST_COMPLETED)
                for future in done:
                    result = future.result()
                    collect(result)
                    if result["blocked"]:
                        stop = "infrastructure-or-preparation-blocker"
                if stop is None:
                    for _ in done:
                        job = next(pending_jobs, None)
                        if job is not None:
                            pending.add(pool.submit(run_case, job))
    ledger.close()
    verify_integrity()
    assert digest(Path(__file__)) == runner_hash and digest(Path(COMMAND[0])) == binary_hash
    report = aggregate(results, time.monotonic() - started)
    report.update(runner_sha256=runner_hash, binary_sha256=binary_hash,
                  schedule_source_sha256=EXPECTED_WRAPPER, projected_total_seconds=projection,
                  stop_reason=stop, workers=WORKERS, integrity_preserved=True,
                  caveats=["Families anonymized in first-occurrence order; generated rows have no family labels.",
                           "Each case stops at its first failed run, matching the public wrapper.",
                           "Pilot cases count once and are not rerun.",
                           "Runtime is runner wall time, including pilot/projection/integrity checks, excluding compilation."])
    with (HERE / "aggregate-final.json").open("x") as f:
        json.dump(report, f, indent=2)
        f.write("\n")
    print(json.dumps(report), flush=True)


if __name__ == "__main__":
    main()
