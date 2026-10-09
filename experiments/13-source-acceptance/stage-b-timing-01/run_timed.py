"""Explicit timing-01 orchestration; caller supplies frozen verifier and decoder.

Native and parent wall intervals overlap and must never be added. The parent
ledger ends before summary persistence; the authoritative watchdog continues
through persistence, close, elapsed recheck and normal child exit. Failure
evidence recovery after expiry is not acceptance work and cannot produce a pass.
"""
import gzip
import hashlib
import json
import math
import os
from pathlib import Path
import resource
import signal
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
sys.path[:0] = [str(HERE), str(HERE.parent)]
from linked import available_bytes, check_clock
from envelope import ENVELOPE_SECONDS, check_amended_envelope

PARENT_PHASES = ("launch_request", "read_wait_framing", "retention_hash", "decode",
                 "predicates", "reply_write", "finalize", "orchestration")
NATIVE_PHASES = {"frontend", "evaluation", "cleanup", "observation", "collector",
                 "transport", "approval_wait"}


def check_native_timing(row):
    assert type(row) is dict and set(row) == {"format", "unit", "completed", "elapsed_ns", "exclusive_wall_ns"}, "native timing keys"
    assert row["format"] == "ROB-1333 native timing 01" and row["unit"] == "ns", "native timing version/unit"
    assert row["completed"] is True, "native timing incomplete"
    assert type(row["elapsed_ns"]) is int and row["elapsed_ns"] >= 0, "native timing elapsed"
    counters = row["exclusive_wall_ns"]
    assert type(counters) is dict and set(counters) == NATIVE_PHASES, "native timing categories"
    assert all(type(n) is int and n >= 0 for n in counters.values()), "native timing counters"
    assert sum(counters.values()) == row["elapsed_ns"], "native timing reconciliation"
    return row


def run(command, workload, destination, *, verifier_type, decode, timeout=None):
    limit = ENVELOPE_SECONDS[workload.name]
    timeout = limit if timeout is None else timeout
    assert type(timeout) in (int, float) and math.isfinite(timeout) and 0 < timeout <= limit, "bounded watchdog only"
    assert __debug__, "predicates require assertions"
    assert signal.getitimer(signal.ITIMER_REAL) == (0.0, 0.0), "watchdog already owned"
    destination = Path(destination).resolve()
    destination.mkdir(parents=True, exist_ok=False)
    previous_handler = signal.getsignal(signal.SIGALRM)
    proc = verifier = None
    phase_count = 0
    digest = hashlib.sha256()
    report = dict(passed=False, candidate_executed=False, fixture_stub=False,
                  workload=workload.name, depth=workload.depth,
                  limit_seconds=limit, watchdog_seconds=timeout)
    start = tick = boundary = time.monotonic_ns()
    totals = dict.fromkeys(PARENT_PHASES, 0)
    active = "orchestration"
    wire_phase = "launch"
    error_kind = "checking"
    fired = False

    def switch(phase):
        nonlocal tick, active
        now = time.monotonic_ns()
        totals[active] += now - tick
        tick, active = now, phase

    def clock():
        now = time.monotonic_ns()
        if fired or now - start > int(timeout * 1_000_000_000):
            raise TimeoutError("inclusive watchdog")
        return now

    def expired(*_):
        nonlocal fired
        fired = True
        raise TimeoutError("inclusive watchdog")

    def stack_limit():
        _, hard = resource.getrlimit(resource.RLIMIT_STACK)
        resource.setrlimit(resource.RLIMIT_STACK, (8 * 1024 ** 2, hard))

    def cleanup():
        if proc is not None:
            if proc.returncode is None:
                proc.kill()
                _, status, usage = os.wait4(proc.pid, 0)
                proc.returncode = os.waitstatus_to_exitcode(status)
                report.update(exit_code=proc.returncode, peak_rss_kib=usage.ru_maxrss,
                              child_user_seconds=usage.ru_utime, child_system_seconds=usage.ru_stime)
            proc.stdin.close()
            proc.stdout.close()

    def persist():
        with (destination / "summary.json").open("w") as output:
            json.dump(report, output, indent=2)
            output.write("\n")

    signal.signal(signal.SIGALRM, expired)
    signal.setitimer(signal.ITIMER_REAL, timeout)
    try:
        budgets = [workload.deepest_step(), workload.transitions() - workload.deepest_step()]
        verifier = verifier_type(workload, budgets)
        case = workload.case()
        payload = dict(source=list(case["source"].encode()), cells=case["cells"],
                       inputs=case["inputs"], outside=case["outside"], budgets=budgets,
                       large=True, deny=None)
        with gzip.open(destination / "request.json.gz", "wt", compresslevel=1) as output:
            json.dump(dict(command=command, request=payload), output)
        memory = available_bytes()
        report.update(budgets=budgets, available_bytes=memory, stack_bytes=8 * 1024 ** 2)
        assert memory >= 4 * 1024 ** 3, "four-GiB provisioning floor"
        with gzip.open(destination / "rows.jsonl.gz", "wb", compresslevel=1) as rows, (destination / "stderr.txt").open("wb") as errors:
            switch("launch_request")
            proc = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                    stderr=errors, preexec_fn=stack_limit,
                                    env=dict(os.environ, ROB1333_TIMING_FILE=str(destination / "native-timing.json")))
            report["candidate_executed"] = True
            proc.stdin.write(json.dumps(payload).encode() + b"\n")
            proc.stdin.flush()
            del payload, case
            while True:
                switch("read_wait_framing")
                line = proc.stdout.readline()
                if not line:
                    break
                switch("retention_hash")
                rows.write(line)
                digest.update(line)
                switch("predicates")
                assert line.endswith(b"\n"), "partial driver record"
                switch("decode")
                record = decode(line)
                switch("predicates")
                now = clock()
                check_clock(boundary, now, [dict(phase=wire_phase, start_ns=boundary, end_ns=now)], int(timeout * 1_000_000_000))
                phase_count += 1
                boundary, wire_phase = now, record["phase"]
                answer = verifier.row(record)
                del record, line
                if answer is not None:
                    switch("reply_write")
                    proc.stdin.write(json.dumps(answer).encode() + b"\n")
                    proc.stdin.flush()
            switch("finalize")
            _, status, usage = os.wait4(proc.pid, 0)
            proc.returncode = os.waitstatus_to_exitcode(status)
            report.update(exit_code=proc.returncode, peak_rss_kib=usage.ru_maxrss,
                          child_user_seconds=usage.ru_utime, child_system_seconds=usage.ru_stime)
            assert proc.returncode == 0, "linked process abnormal termination"
            switch("predicates")
            report.update(verifier.finish(), semantic_completed=True)
            switch("finalize")
        cleanup()
        error_kind = "sidecar"
        with (destination / "native-timing.json").open("rb") as sidecar:
            raw = sidecar.read(16385)
        assert len(raw) <= 16384, "native timing size bound"
        switch("decode")
        native = decode(raw)
        switch("predicates")
        report["native_timing"] = check_native_timing(native)
        assert native["elapsed_ns"] <= clock() - start, "native interval exceeds parent interval"
        report["native_interval"] = "native measured interval excludes process startup/exit and sidecar write; wall totals overlap parent"
        error_kind = "resource"
        now = clock()
        check_clock(boundary, now, [dict(phase=wire_phase, start_ns=boundary, end_ns=now)], int(timeout * 1_000_000_000))
        record = verifier.resource_record(elapsed_seconds=(now - start) / 1e9,
                                          available=memory, stack_bytes=8 * 1024 ** 2)
        report["resource_record"] = record
        check_amended_envelope(record)
        switch("finalize")
        report.update(phase_count=phase_count, checked_steps=verifier.step,
                      streamed_rows_sha256=digest.hexdigest(),
                      verifier_peak_kib=resource.getrusage(resource.RUSAGE_SELF).ru_maxrss)
        # Releasing the final verifier state is required work, not deferred to
        # function return after the watchdog has been disabled.
        del verifier
        verifier = None
        switch("finalize")
        report["parent_timing"] = dict(start_ns=start, end_ns=tick, elapsed_ns=tick-start,
                                      exclusive_wall_ns=dict(totals),
                                      interval="runner entry through ledger snapshot before summary persistence")
        assert sum(totals.values()) == tick - start
        report.update(elapsed_seconds=(clock()-start)/1e9,
                      elapsed_scope="snapshot before summary write; persistence/close and remainder guarded and rechecked; returned elapsed is authoritative")
        # First complete the required evidence write/close without claiming pass.
        persist()
        clock()
        report["passed"] = True
        persist()
        end = clock()
        report.update(elapsed_ns=end-start, elapsed_seconds=(end-start)/1e9,
                      finalization_remainder_ns=end-tick)
    except BaseException as error:
        report.update(passed=False, error_kind="timeout" if isinstance(error, TimeoutError) else error_kind,
                      error=f"{type(error).__name__}: {error}")
    finally:
        # Success has already closed every required output and rechecked time.
        # On failure disable the spent guard solely to recover failure evidence.
        signal.setitimer(signal.ITIMER_REAL, 0)
        signal.signal(signal.SIGALRM, previous_handler)
        if not report["passed"]:
            try:
                cleanup()
            except Exception as error:
                report["cleanup_error"] = f"{type(error).__name__}: {error}"
            switch("finalize")
            report.setdefault("parent_timing", dict(
                start_ns=start, end_ns=tick, elapsed_ns=tick-start,
                exclusive_wall_ns=dict(totals),
                interval="runner entry through failure recovery ledger snapshot before summary persistence"))
            report.update(phase_count=phase_count, checked_steps=getattr(verifier, "step", report.get("checked_steps", 0)),
                          streamed_rows_sha256=digest.hexdigest(),
                          elapsed_seconds=(time.monotonic_ns()-start)/1e9)
            persist()
    return report
