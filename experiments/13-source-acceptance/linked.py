"""Acceptance-owned process driver and inclusive watchdog, not an evaluator.
Linux orb execution only. Resource workloads are NOT authorized by this module.
"""
import json
import os
from pathlib import Path
import resource
import selectors
import signal
import subprocess
import time

from integration import Verifier, load


def available_bytes():
    entries=dict(line.split(":",1) for line in Path("/proc/meminfo").read_text().splitlines())
    available=int(entries["MemAvailable"].split()[0])*1024
    for root in (Path("/sys/fs/cgroup"),):
        limit=root/"memory.max"; current=root/"memory.current"
        if limit.exists() and current.exists() and limit.read_text().strip()!="max":
            available=min(available,int(limit.read_text())-int(current.read_text()))
    return max(available,0)


def check_clock(start, stop, phases, limit_ns=600_000_000_000):
    assert type(start) is int and type(stop) is int and stop>=start, "clock endpoints"
    assert stop-start<=limit_ns, "inclusive watchdog"
    previous=start
    for row in phases:
        assert set(row)=={"phase","start_ns","end_ns"}, "phase timing schema"
        assert type(row["start_ns"]) is int and type(row["end_ns"]) is int, "phase timing kind"
        assert row["start_ns"]==previous and row["end_ns"]>=previous, "phase clock gap/reset"
        previous=row["end_ns"]
    assert previous==stop, "untimed workload suffix"


def run_linked(command, case, budgets, destination, *, deny=None, stage="B", env=None, timeout=600, fixture_stub=False):
    """Precompute independent expectations before the workload clock. Then include
    process launch, request/setup, verification/ack waits, all observations,
    two destroys, teardown, process exit and final evidence checks in ONE clock.
    `timeout` exists for watchdog unit tests; approved workloads use exactly 600.
    """
    verifier=Verifier(case,budgets,deny,stage)
    destination=Path(destination); destination.mkdir(parents=True,exist_ok=False)
    assert 0<timeout<=600, "watchdog range"
    source=case["source"].encode() if isinstance(case["source"],str) else case["source"]
    memory=available_bytes()
    previous_handler=signal.getsignal(signal.SIGALRM)
    assert signal.getitimer(signal.ITIMER_REAL)==(0.0,0.0), "watchdog already owned"
    def expired(*_): raise TimeoutError("inclusive watchdog")
    def stack_limit():
        _,hard=resource.getrlimit(resource.RLIMIT_STACK)
        resource.setrlimit(resource.RLIMIT_STACK,(8*1024**2,hard))
    proc=None; phases=[]; start=time.monotonic_ns(); boundary=start; phase="launch"
    report=dict(passed=False,candidate_executed=not fixture_stub,fixture_stub=fixture_stub,available_bytes=memory,stack_bytes=8*1024**2)
    signal.signal(signal.SIGALRM,expired);signal.setitimer(signal.ITIMER_REAL,timeout)
    try:
        with (destination/"rows.jsonl").open("wb") as rows, (destination/"stderr.txt").open("wb") as errors:
            proc=subprocess.Popen(command,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=errors,
                env=dict(os.environ,**(env or {})),preexec_fn=stack_limit)
            payload=dict(source=list(source),cells=case["cells"],inputs=case["inputs"],outside=case["outside"],budgets=budgets,large=False,deny=deny)
            proc.stdin.write(json.dumps(payload).encode()+b"\n");proc.stdin.flush()
            pending=b""
            selector=selectors.DefaultSelector();selector.register(proc.stdout,selectors.EVENT_READ)
            try:
                while True:
                    if not selector.select(timeout): raise TimeoutError("inclusive watchdog")
                    block=os.read(proc.stdout.fileno(),65536)
                    if not block: break
                    pending+=block
                    while b"\n" in pending:
                        line,pending=pending.split(b"\n",1);rows.write(line+b"\n")
                        row=load(line)
                        now=time.monotonic_ns()
                        phases.append(dict(phase=phase,start_ns=boundary,end_ns=now));boundary=now;phase=row["phase"]
                        answer=verifier.row(row)
                        if answer is not None:
                            proc.stdin.write(json.dumps(answer).encode()+b"\n");proc.stdin.flush()
                assert not pending, "partial driver record"
                _,status,usage=os.wait4(proc.pid,0);proc.returncode=os.waitstatus_to_exitcode(status)
                report.update(exit_code=proc.returncode,peak_rss_kib=usage.ru_maxrss)
                assert proc.returncode==0, "linked process abnormal termination"
                report.update(verifier.finish())
            finally: selector.close()
        stop=time.monotonic_ns();phases.append(dict(phase=phase,start_ns=boundary,end_ns=stop))
        check_clock(start,stop,phases,int(timeout*1_000_000_000))
        report.update(passed=True,elapsed_ns=stop-start,start_ns=start,stop_ns=stop,phases=phases)
    except BaseException as error:
        report.update(error=f"{type(error).__name__}: {error}",elapsed_ns=time.monotonic_ns()-start,phases=phases)
        raise
    finally:
        signal.setitimer(signal.ITIMER_REAL,0);signal.signal(signal.SIGALRM,previous_handler)
        if proc is not None:
            if proc.returncode is None:
                proc.kill();proc.wait()
            if proc.stdin: proc.stdin.close()
            if proc.stdout: proc.stdout.close()
        (destination/"summary.json").write_text(json.dumps(report,indent=2)+"\n")
    return report
