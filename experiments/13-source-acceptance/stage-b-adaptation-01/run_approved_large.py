"""Run the two authorized workloads with the frozen revised verifier.

This is orchestration, not a new predicate or profile. The original small-run
adapter still refuses approved depths. Each run pauses at the deepest boundary
and resumes to completion, retaining all streamed rows compressed. The original
debug binary is the default; another build requires its explicit fingerprint.
No candidate, expectation or frozen file is modified. The earlier executed
orchestrator remains in the sealed continuation evidence.
Usage: python3 run_approved_large.py NEW_EVIDENCE_DIRECTORY VERIFIED_BINARY [SHA256]
"""
import gzip
import hashlib
import json
import os
from pathlib import Path
import resource
import signal
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
sys.path[:0] = [str(HERE.parent / "stage-b-revision-02"), str(HERE.parent)]
from integration import load
from linked import available_bytes, check_clock
from stage_b_large import ENVELOPE_SECONDS, LargeVerifier, check_amended_envelope
from stage_b_workloads import APPROVED_DEPTH, DiscardedList, NonTailSum
from validate_public import frozen, sha


def run(command, workload, destination, *, verifier_type=LargeVerifier, decode=load):
    destination.mkdir(parents=True, exist_ok=False)
    timeout = ENVELOPE_SECONDS[workload.name]
    budgets = [workload.deepest_step(), workload.transitions() - workload.deepest_step()]
    verifier = verifier_type(workload, budgets)
    case = workload.case()
    payload = dict(source=list(case["source"].encode()), cells=case["cells"],
                   inputs=case["inputs"], outside=case["outside"], budgets=budgets,
                   large=True, deny=None)
    with gzip.open(destination / "request.json.gz", "wt", compresslevel=1) as output:
        json.dump(dict(command=command, request=payload), output)
    memory = available_bytes()
    assert memory >= 4 * 1024 ** 3, "four-GiB provisioning floor"
    assert signal.getitimer(signal.ITIMER_REAL) == (0.0, 0.0), "watchdog already owned"
    previous_handler = signal.getsignal(signal.SIGALRM)

    def expired(*_):
        raise TimeoutError("inclusive watchdog")

    def stack_limit():
        _, hard = resource.getrlimit(resource.RLIMIT_STACK)
        resource.setrlimit(resource.RLIMIT_STACK, (8 * 1024 ** 2, hard))

    report = dict(passed=False, candidate_executed=False, fixture_stub=False,
                  workload=workload.name, depth=workload.depth, budgets=budgets,
                  limit_seconds=timeout, available_bytes=memory, stack_bytes=8 * 1024 ** 2)
    proc = None
    phase_count = 0
    digest = hashlib.sha256()
    start = time.monotonic_ns()
    boundary = start
    phase = "launch"
    signal.signal(signal.SIGALRM, expired)
    signal.setitimer(signal.ITIMER_REAL, timeout)
    try:
        with gzip.open(destination / "rows.jsonl.gz", "wb", compresslevel=1) as rows, \
                (destination / "stderr.txt").open("wb") as errors:
            proc = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                    stderr=errors, preexec_fn=stack_limit)
            report["candidate_executed"] = True
            proc.stdin.write(json.dumps(payload).encode() + b"\n")
            proc.stdin.flush()
            del payload, case
            # Buffered reads avoid quadratic copying/scanning of large full
            # observations. The inclusive SIGALRM still interrupts blocked IO.
            for line in proc.stdout:
                assert line.endswith(b"\n"), "partial driver record"
                rows.write(line)
                digest.update(line)
                record = decode(line)
                now = time.monotonic_ns()
                check_clock(boundary, now,
                            [dict(phase=phase, start_ns=boundary, end_ns=now)],
                            int(timeout * 1_000_000_000))
                assert now - start <= int(timeout * 1_000_000_000), "inclusive watchdog"
                phase_count += 1
                boundary = now
                phase = record["phase"]
                answer = verifier.row(record)
                del record
                if answer is not None:
                    proc.stdin.write(json.dumps(answer).encode() + b"\n")
                    proc.stdin.flush()
            _, status, usage = os.wait4(proc.pid, 0)
            proc.returncode = os.waitstatus_to_exitcode(status)
            report.update(exit_code=proc.returncode, peak_rss_kib=usage.ru_maxrss,
                          child_user_seconds=usage.ru_utime, child_system_seconds=usage.ru_stime)
            assert proc.returncode == 0, "linked process abnormal termination"
            report.update(verifier.finish())
        stop = time.monotonic_ns()
        check_clock(boundary, stop, [dict(phase=phase, start_ns=boundary, end_ns=stop)],
                    int(timeout * 1_000_000_000))
        assert stop - start <= int(timeout * 1_000_000_000), "inclusive watchdog"
        elapsed = (stop - start) / 1_000_000_000
        record = verifier.resource_record(elapsed_seconds=elapsed, available=memory,
                                          stack_bytes=8 * 1024 ** 2)
        check_amended_envelope(record)
        report.update(passed=True, elapsed_seconds=elapsed, resource_record=record)
    except Exception as error:
        report.update(error=f"{type(error).__name__}: {error}",
                      elapsed_seconds=(time.monotonic_ns() - start) / 1_000_000_000)
    finally:
        signal.setitimer(signal.ITIMER_REAL, 0)
        signal.signal(signal.SIGALRM, previous_handler)
        if proc is not None:
            if proc.returncode is None:
                proc.kill()
                proc.wait()
            proc.stdin.close()
            proc.stdout.close()
        report.update(phase_count=phase_count, checked_steps=verifier.step,
                      streamed_rows_sha256=digest.hexdigest(),
                      verifier_peak_kib=resource.getrusage(resource.RUSAGE_SELF).ru_maxrss)
        (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    return report


def main(destination, binary, binary_sha256="7b38989835db8ef6fd274477f625caf5c35e6438256d405f4b5242703427491a"):
    destination.mkdir(parents=True, exist_ok=False)
    before = frozen()
    assert sha(binary) == binary_sha256, "binary fingerprint"
    results = []
    for cls in (NonTailSum, DiscardedList):
        workload = cls(APPROVED_DEPTH)
        result = run([str(binary)], workload, destination / workload.name)
        results.append(result)
        print(json.dumps(result), flush=True)
        (destination / "report.json").write_text(json.dumps(dict(
            runs=results, preservation_before=before, preservation_after=frozen(),
            binary_sha256=sha(binary), runner_sha256=sha(Path(__file__)),
            python_version=sys.version, python_executable=sys.executable), indent=2) + "\n")
        if not result["passed"]:
            raise SystemExit("Approved workload did not pass; evidence retained.")


if __name__ == "__main__":
    main(Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve(), *sys.argv[3:])
