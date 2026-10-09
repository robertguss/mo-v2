"""Run existing frozen verifiers against this adaptation; no private inputs.

Usage: python3 validate_public.py NEW_EVIDENCE_DIRECTORY BINARY
No predicates or expectations are defined here. Every request and result stays
in its own directory. Stop on the first verifier rejection.
"""
import gzip
import hashlib
import json
from pathlib import Path
import sys
import time
import traceback

HERE = Path(__file__).resolve().parent
ORIGINAL = HERE.parent
REVISION = ORIGINAL / "stage-b-revision-02"
sys.path[:0] = [str(REVISION), str(ORIGINAL)]

from check_revision import preservation
from stage_b_large import run_large_linked
from stage_b_workloads import DiscardedList, NonTailSum
from cases import examples
from finite_reference import decode
from integration import Origins
from linked import run_linked
from syntax import parse, pretty
from validate import CORPUS


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def frozen():
    result = preservation()
    lock = json.loads((REVISION / "LOCK.json").read_text())
    for name, record in lock["files"].items():
        path = REVISION / name
        assert path.stat().st_size == record["bytes"] and sha(path) == record["sha256"], name
    return dict(**result, revised_files=len(lock["files"]), revised_lock=sha(REVISION / "LOCK.json"))


def main(destination, binary):
    destination.mkdir(parents=True, exist_ok=False)
    command = [str(binary)]
    started = time.monotonic()
    report = dict(passed=False, public_cases=0, full=0, resume=0, destroy=0,
                  denials=0, historical=0, real_summary_runs=0,
                  private_cases=0, million_element_runs=0,
                  runner_sha256=sha(Path(__file__)), binary_sha256=sha(binary))
    serial = 0
    try:
        report["preservation_before"] = frozen()
        with (destination / "ledger.jsonl").open("x") as ledger:
            def record(data):
                ledger.write(json.dumps(data) + "\n")
                ledger.flush()

            def ordinary(case, budgets, group, *, deny=None):
                nonlocal serial
                folder = destination / f"shard-{serial // 500:03d}" / f"run-{serial:06d}"
                serial += 1
                folder.parent.mkdir(exist_ok=True)
                request = dict(case=case, budgets=budgets, deny=deny, stage="B", command=command)
                folder.with_suffix(".request.json").write_text(json.dumps(request) + "\n")
                result = run_linked(command, case, budgets, folder, deny=deny, stage="B")
                record(dict(group=group, directory=str(folder.relative_to(destination)),
                            committed_steps=result["committed_steps"], passed=result["passed"]))
                report[group] += 1
                return folder

            # Real evaluator at the frozen 10,000-step summary grid. Off-grid,
            # zero-budget and exact-grid pauses exercise cursor resets; both
            # complete and deepest-destruction schedules retain the required
            # deepest full observation. No approved-depth workload is run.
            for cls, depth in ((DiscardedList, 10003), (NonTailSum, 2003)):
                workload = cls(depth)
                for finish in (False, True):
                    cut = workload.transitions() if finish else workload.deepest_step()
                    stops = sorted({0, 10000, 10001, workload.deepest_step(), cut})
                    budgets = [0]
                    for a, b in zip(stops, stops[1:]):
                        budgets.extend([b - a, 0])
                    folder = destination / f"summary-{cls.__name__}-{finish}"
                    folder.with_suffix(".request.json").write_text(json.dumps(dict(
                        command=command, case=workload.case(), budgets=budgets, large=True)) + "\n")
                    result = run_large_linked(command, workload, budgets, folder, keep_rows=True)
                    report["real_summary_runs"] += 1
                    record(dict(group="real_summary_runs", directory=folder.name, **result))
                    print(f"summary runs passed: {report['real_summary_runs']}", flush=True)

            for case in examples():
                reference = Origins(parse(case["source"]), case["cells"], case["inputs"],
                                    case["outside"], landmark_limit=60 if case.get("value", 0) is None else 20000)
                reference.observe(reference.program["main"])
                count = len(reference.trace)
                baseline = ordinary(case, [count], "full")
                for cut in range(count + 1):
                    budgets = [cut, 0, count - cut]
                    if case.get("value", 0) is not None:
                        budgets += [0, 9]
                    ordinary(case, budgets, "resume")
                    ordinary(case, [cut], "destroy")
                # Reuse observed successful begin gate ordinals, not guessed
                # positions: covers census Frame storage and every Number read.
                for line in (baseline / "rows.jsonl").read_text().splitlines():
                    row = json.loads(line)
                    if row.get("phase") == "begin":
                        for domain, ordinal, allowed, phase in row["resources"]:
                            assert allowed and phase == "begin"
                            ordinary(case, [count], "denials", deny=[domain, ordinal])
                report["public_cases"] += 1
                print(f"public cases passed: {report['public_cases']}", flush=True)

            with gzip.open(CORPUS, "rt") as stream:
                for line in stream:
                    original = json.loads(line)
                    expr, cells, inputs, outside = decode(original["input"])
                    source = "".join(f"input {name}: {'ListInt' if value[0] == 'l' else 'Int'};\n"
                                     for name, value in inputs) + "main = " + pretty(expr)
                    ordinary(dict(source=source, cells=cells, inputs=inputs, outside=outside),
                             [100000], "historical")
                    if report["historical"] % 500 == 0:
                        print(f"historical cases passed: {report['historical']}", flush=True)
        report["passed"] = True
    except BaseException:
        report["error"] = traceback.format_exc()
        raise
    finally:
        report["preservation_after"] = frozen()
        report["elapsed_seconds"] = time.monotonic() - started
        (destination / "report.json").write_text(json.dumps(report, indent=2) + "\n")
        print(json.dumps(report, indent=2), flush=True)


if __name__ == "__main__":
    main(Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve())
