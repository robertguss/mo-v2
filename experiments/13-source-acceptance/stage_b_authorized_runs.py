"""D171 and D172: nine sabotage controls and both million-element runs.

The submitted candidate is not edited. Each sabotage fault is applied only to
a throwaway copy, then the frozen small-case checker judges the original
example. The million-element runs use the frozen streaming checker. The only
difference from `run_large_linked` is that D171 now permits the approved
depth and D162's clocks; the verifier, the watchdog and the envelope check
are the frozen ones. `omitted-entry-create` is not run (D164).
"""
import json
import os
from pathlib import Path
import resource
import selectors
import shutil
import signal
import subprocess
import time

from boundedcheck import DEFS
from cases import examples, fixture
from integration import Origins, load
from linked import available_bytes, check_clock, run_linked
from stage_b_large import ENVELOPE_SECONDS, LargeVerifier, check_amended_envelope
from stage_b_workloads import APPROVED_DEPTH, DiscardedList, NonTailSum


HERE = Path(__file__).resolve().parent
COMMAND_MILLION = "/tmp/mo-stage-b-million/debug/rob1333-stage-b-link"


def patch(text, old, new, label, count=1):
    found = text.count(old)
    if found != count:
        raise SystemExit(f"{label} matched {found}, expected {count}")
    return text.replace(old, new, count)


def prepare_control_copy():
    source = HERE / "candidate-stage-b"
    copy = HERE / "candidate-stage-b-controls"
    link = HERE / "control-link"
    if copy.exists():
        shutil.rmtree(copy)
    if link.exists():
        shutil.rmtree(link)
    shutil.copytree(source, copy)
    lib = (copy / "lib.rs").read_text()
    lib = patch(
        lib,
        "use std::sync::Arc;\n",
        "use std::sync::Arc;\nuse std::sync::atomic::{AtomicBool, Ordering};\n",
        "lib import",
    )
    lib = patch(
        lib,
        "pub struct Run(execution::Machine);\n",
        """pub struct Run(execution::Machine);

pub(crate) fn mutant(name: &str) -> bool {
    let active = std::env::var("ROB_ACCEPT_MUTANT").as_deref() == Ok(name);
    if active {
        static SEEN: AtomicBool = AtomicBool::new(false);
        if !SEEN.swap(true, Ordering::Relaxed) {
            eprintln!("MUTANT:{name}");
        }
    }
    active
}

""",
        "mutant helper",
    )
    execution = (copy / "execution.rs").read_text()
    execution = patch(
        execution,
        "let unique = cell.holders == 1;\n",
        'let unique = cell.holders == 1 && !crate::mutant("always-copy");\n',
        "always-copy",
        count=2,
    )
    execution = patch(
        execution,
        """    fn eligible_reservation(&self) -> Option<usize> {
        let branches: BTreeSet<_> = (self.context_start()..self.contexts.len())
            .filter_map(|i| self.contexts[i].branch)
            .collect();
        (self.reservation_start()..self.aside.len()).find(|&i| branches.contains(&self.aside[i].0))
    }
""",
        """    fn eligible_reservation(&self) -> Option<usize> {
        if crate::mutant("fixture-provenance") {
            return None;
        }
        let branches: BTreeSet<_> = (self.context_start()..self.contexts.len())
            .filter_map(|i| self.contexts[i].branch)
            .collect();
        let start = self.reservation_start();
        if crate::mutant("caller-reservation-theft") {
            if let Some(position) = (0..start).next() {
                return Some(position);
            }
        }
        (start..self.aside.len()).find(|&i| branches.contains(&self.aside[i].0))
    }
""",
        "reservation faults",
    )
    execution = patch(
        execution,
        """            Phase::BranchStart => {
                s.contexts[index].operands.clear();
""",
        """            Phase::BranchStart => {
                if crate::mutant("early-cleanup") {
                    if let Some(branch) = s.contexts[index].branch {
                        if let Some(position) = (s.reservation_start()..s.aside.len())
                            .find(|&i| s.aside[i].0 == branch)
                        {
                            let (_, id) = s.aside[position];
                            cells.free(id).map_err(Fault::cell)?;
                            s.aside.remove(position);
                            s.events.push_back(Event::Cell("free", id));
                        }
                    }
                }
                s.contexts[index].operands.clear();
""",
        "early-cleanup",
    )
    execution = patch(
        execution,
        's.events.push_back(Event::Cell("create", cell));\n',
        """if !(((crate::mutant("omitted-nested-create")
                    || crate::mutant("omitted-transient-create"))
                    && !s.frames.is_empty()))
                {
                    s.events.push_back(Event::Cell("create", cell));
                }
""",
        "omitted creates",
    )
    execution = patch(
        execution,
        """                _ => {
                    s.contexts[index].phase =
                        if matches!(node.expr, Expr::Call { .. }) && node.children.is_empty() {
                            Phase::CallEnter
                        } else {
                            Phase::Child(0)
                        };
                    return Ok(s.action(program, "Dispatch compound", None));
                }
""",
        """                _ => {
                    s.contexts[index].phase = if matches!(node.expr, Expr::Call { .. })
                        && (node.children.is_empty()
                            || crate::mutant("early-enter"))
                    {
                        Phase::CallEnter
                    } else {
                        Phase::Child(0)
                    };
                    return Ok(s.action(program, "Dispatch compound", None));
                }
""",
        "early-enter",
    )
    execution = patch(
        execution,
        """        if self.release.is_empty() {
            while let Some(id) = self.cleanup.pop_front() {
""",
        """        if self.release.is_empty()
            && !(!self.frames.is_empty()
                && !self.cleanup.is_empty()
                && crate::mutant("skipped-return-cleanup"))
        {
            while let Some(id) = self.cleanup.pop_front() {
""",
        "skipped-return-cleanup",
    )
    execution = patch(
        execution,
        """                for (parameter, value) in function.parameters.iter().zip(arguments) {
                    let holding = matches!(value, Val::List(Some(_)));
""",
        """                for (parameter, mut value) in function.parameters.iter().zip(arguments) {
                    if crate::mutant("hidden-entry-copy") {
                        if let Val::List(Some(id)) = &value {
                            let existing = read(cells, *id)?;
                            if let Some(tail) = existing.tail {
                                let meta = read(cells, tail)?;
                                cells
                                    .metadata(tail, meta.holders + 1, meta.aside)
                                    .map_err(Fault::cell)?;
                            }
                            let copy = cells
                                .create(Cell {
                                    item: existing.item,
                                    tail: existing.tail,
                                    holders: 1,
                                    aside: false,
                                })
                                .map_err(Fault::cell)?;
                            s.events.push_back(Event::Cell("create", copy));
                            value = Val::List(Some(copy));
                        }
                    }
                    let holding = matches!(value, Val::List(Some(_)));
""",
        "hidden-entry-copy",
    )
    (copy / "lib.rs").write_text(lib)
    (copy / "execution.rs").write_text(execution)
    link.mkdir()
    (link / "main.rs").write_text((HERE / "stage-b-link" / "main.rs").read_text())
    (link / "Cargo.lock").write_text((HERE / "stage-b-link" / "Cargo.lock").read_text())
    (link / "Cargo.toml").write_text(
        (HERE / "stage-b-link" / "Cargo.toml")
        .read_text()
        .replace('path = "../candidate-stage-b"', 'path = "../candidate-stage-b-controls"')
    )
    return copy, link


def build_control_link(link):
    env = dict(os.environ, CARGO_TARGET_DIR="/tmp/mo-stage-b-controls-target")
    result = subprocess.run(
        ["cargo", "+1.98.1", "build", "--locked", "--offline", "--manifest-path", str(link / "Cargo.toml")],
        cwd=HERE,
        env=env,
        capture_output=True,
        text=True,
    )
    log = result.stdout + result.stderr
    if result.returncode != 0:
        raise SystemExit(log)
    binary = Path("/tmp/mo-stage-b-controls-target/debug/rob1333-stage-b-link")
    if not binary.exists():
        raise SystemExit("control binary missing\n" + log)
    return binary


def step_count(case):
    program = __import__("syntax").parse(case["source"])
    limit = 60 if case.get("value", 0) is None else 20000
    reference = Origins(program, case["cells"], case["inputs"], case["outside"], landmark_limit=limit)
    reference.observe(program["main"])
    return len(reference.trace)


def run_case(command, case, dest, env=None):
    if dest.exists():
        shutil.rmtree(dest)
    try:
        report = run_linked(command, case, [step_count(case)], dest, stage="B", env=env, timeout=120)
        stderr = (dest / "stderr.txt").read_text(errors="replace")
        return dict(passed=True, error=None, stderr=stderr, elapsed_ns=report.get("elapsed_ns"))
    except Exception as error:
        stderr = ""
        err_path = dest / "stderr.txt"
        if err_path.exists():
            stderr = err_path.read_text(errors="replace")
        return dict(passed=False, error=f"{type(error).__name__}: {error}", stderr=stderr,
                    elapsed_ns=None)


def one_control(command, name, cases, work):
    baseline = []
    for case in cases:
        outcome = run_case(command, case, work / name / "baseline" / case["name"])
        baseline.append(dict(name=case["name"], passed=outcome["passed"], error=outcome["error"]))
    mutant = []
    for case in cases:
        outcome = run_case(
            command, case, work / name / "mutant" / case["name"],
            env={"ROB_ACCEPT_MUTANT": name},
        )
        mutant.append(dict(
            name=case["name"], passed=outcome["passed"], error=outcome["error"],
            marker=f"MUTANT:{name}" in outcome["stderr"],
            panic="panicked at" in outcome["stderr"],
        ))
    baseline_ok = all(row["passed"] for row in baseline)
    rejected = [row for row in mutant if not row["passed"]]
    clean_rejection = [
        row for row in rejected
        if row["marker"] and not row["panic"] and (row["error"] or "").startswith("AssertionError:")
    ]
    return dict(
        control=name,
        applicable=True,
        baseline_passed=baseline_ok,
        baseline=baseline,
        mutant=mutant,
        caught=baseline_ok and len(clean_rejection) == len(cases) and len(cases) > 0,
    )


def controls(command):
    by_name = {case["name"]: case for case in examples()}
    cells, inputs, outside = fixture([3, -2, 8])
    routes = [
        dict(name="fixture-route", source="input xs: ListInt; " + DEFS["inc"] + "main = inc(xs)",
             cells=cells, inputs=inputs, outside=outside, value=[4, -1, 9]),
        dict(name="literal-route", source=DEFS["inc"] + "main = inc([3, -2, 8])",
             cells=[], inputs=[], outside=[], value=[4, -1, 9]),
    ]
    plan = [
        ("always-copy", [by_name["C10-unique"]]),
        ("hidden-entry-copy", [by_name["C8"]]),
        ("fixture-provenance", routes),
        ("caller-reservation-theft", [by_name["C1"]]),
        ("early-cleanup", [by_name["C14"]]),
        ("omitted-nested-create", [by_name["C9"]]),
        ("omitted-transient-create", [by_name["C7"]]),
        ("early-enter", [by_name["C11-0"]]),
        ("skipped-return-cleanup", [by_name["C7"]]),
    ]
    work = Path("/tmp/stage-b-control-runs")
    if work.exists():
        shutil.rmtree(work)
    rows = [one_control(command, name, cases, work) for name, cases in plan]
    rows.append(dict(
        control="omitted-entry-create",
        applicable=False,
        caught=None,
        reason=("Not applicable under D164. The frozen predictor never allocates on Enter, "
                "so this control cannot be reached. It was not run."),
    ))
    return rows


def run_approved(command, workload, destination, timeout):
    """The frozen large-run loop at the depth D171 authorizes."""
    verifier = LargeVerifier(workload, [workload.transitions()])
    destination = Path(destination)
    destination.mkdir(parents=True, exist_ok=False)
    case = workload.case()
    source = case["source"].encode()
    memory = available_bytes()
    previous_handler = signal.getsignal(signal.SIGALRM)
    assert signal.getitimer(signal.ITIMER_REAL) == (0.0, 0.0), "watchdog already owned"

    def expired(*_):
        raise TimeoutError("inclusive watchdog")

    def stack_limit():
        _, hard = resource.getrlimit(resource.RLIMIT_STACK)
        resource.setrlimit(resource.RLIMIT_STACK, (8 * 1024 ** 2, hard))

    proc = None
    phases = []
    start = time.monotonic_ns()
    boundary = start
    phase = "launch"
    report = dict(
        passed=False, candidate_executed=False, depth=workload.depth, workload=workload.name,
        limit_seconds=timeout, available_bytes=memory, stack_bytes=8 * 1024 ** 2,
    )
    signal.signal(signal.SIGALRM, expired)
    signal.setitimer(signal.ITIMER_REAL, timeout)
    try:
        with (destination / "stderr.txt").open("wb") as errors:
            proc = subprocess.Popen(
                command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=errors,
                env=os.environ.copy(), preexec_fn=stack_limit,
            )
            report["candidate_executed"] = True
            payload = dict(
                source=list(source), cells=case["cells"], inputs=case["inputs"],
                outside=case["outside"], budgets=[workload.transitions()], large=True, deny=None,
            )
            proc.stdin.write(json.dumps(payload).encode() + b"\n")
            proc.stdin.flush()
            pending = b""
            selector = selectors.DefaultSelector()
            selector.register(proc.stdout, selectors.EVENT_READ)
            try:
                while True:
                    if not selector.select(timeout):
                        raise TimeoutError("inclusive watchdog")
                    block = os.read(proc.stdout.fileno(), 1 << 20)
                    if not block:
                        break
                    pending += block
                    while b"\n" in pending:
                        line, pending = pending.split(b"\n", 1)
                        record = load(line)
                        now = time.monotonic_ns()
                        phases.append(dict(phase=phase, start_ns=boundary, end_ns=now))
                        boundary = now
                        phase = record["phase"]
                        answer = verifier.row(record)
                        del record
                        if answer is not None:
                            proc.stdin.write(json.dumps(answer).encode() + b"\n")
                            proc.stdin.flush()
                if pending:
                    raise AssertionError("partial driver record")
                _, status, usage = os.wait4(proc.pid, 0)
                proc.returncode = os.waitstatus_to_exitcode(status)
                report.update(exit_code=proc.returncode, peak_rss_kib=usage.ru_maxrss)
                if proc.returncode != 0:
                    raise AssertionError("linked process abnormal termination")
                report.update(verifier.finish())
            finally:
                selector.close()
        stop = time.monotonic_ns()
        phases.append(dict(phase=phase, start_ns=boundary, end_ns=stop))
        check_clock(start, stop, phases, int(timeout * 1_000_000_000))
        elapsed = (stop - start) / 1_000_000_000
        record = verifier.resource_record(
            elapsed_seconds=elapsed, available=memory, stack_bytes=8 * 1024 ** 2,
        )
        check_amended_envelope(record)
        report.update(passed=True, elapsed_seconds=elapsed, result="finished inside the limit",
                      resource_record=record)
    except BaseException as error:
        elapsed = (time.monotonic_ns() - start) / 1_000_000_000
        report.update(
            error=f"{type(error).__name__}: {error}",
            elapsed_seconds=elapsed,
            result="did not finish",
            phase_count=len(phases),
        )
    finally:
        signal.setitimer(signal.ITIMER_REAL, 0)
        signal.signal(signal.SIGALRM, previous_handler)
        if proc is not None:
            if proc.returncode is None:
                proc.kill()
                proc.wait()
            if proc.stdin:
                proc.stdin.close()
            if proc.stdout:
                proc.stdout.close()
        (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    return report


def million_runs(command):
    work = Path("/tmp/stage-b-million-runs")
    if work.exists():
        shutil.rmtree(work)
    rows = []
    for workload in (NonTailSum(APPROVED_DEPTH), DiscardedList(APPROVED_DEPTH)):
        timeout = ENVELOPE_SECONDS[workload.name]
        report = run_approved(command, workload, work / workload.name, timeout)
        rows.append({
            "case": workload.name,
            "depth": APPROVED_DEPTH,
            "limit_seconds": timeout,
            "elapsed_seconds": report.get("elapsed_seconds"),
            "passed": report.get("passed"),
            "result": report.get("result"),
            "error": report.get("error"),
            "available_bytes": report.get("available_bytes"),
            "phase_count": report.get("phase_count"),
            "committed_steps": report.get("committed_steps"),
            "candidate_executed": report.get("candidate_executed"),
        })
        print(workload.name, rows[-1]["result"], rows[-1]["elapsed_seconds"], rows[-1].get("error"), flush=True)
    return rows


def main():
    started = time.time()
    _, link = prepare_control_copy()
    binary = build_control_link(link)
    control_rows = controls([str(binary)])
    for row in control_rows:
        print(row["control"], "caught" if row.get("caught") else row.get("reason") or row, flush=True)
    million = million_runs([COMMAND_MILLION])
    for leftover in (HERE / "candidate-stage-b-controls", HERE / "control-link"):
        if leftover.exists():
            shutil.rmtree(leftover)
    evidence = HERE / "evidence" / "stage-b-controls-and-million"
    if evidence.exists():
        shutil.rmtree(evidence)
    evidence.mkdir(parents=True)
    report = dict(
        candidate="experiments/13-source-acceptance/candidate-stage-b",
        candidate_source_edited=False,
        controls=control_rows,
        million_element_runs=million,
        elapsed_seconds=round(time.time() - started, 3),
    )
    (evidence / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
