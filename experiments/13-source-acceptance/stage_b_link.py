"""The Stage B candidate-linking path, exercised for the first time.

Stage A linked a call-free candidate through `stage-a-link`. Nothing had ever
been linked and run as Stage B: `syntax.check(program, "A")` refuses any
function declaration or call outright, so no call-bearing program had reached
the driver, the birth registry, the invocation normaliser or the enter/return
event comparison.

This module closes that gap without implementing Mo. A canned Stage B interface
fixture replays one hand-written six-action schedule for

    def f(): Int = 7 end main = f()

which Stage A refuses and Stage B accepts. The run goes through the *frozen*
`linked.run_linked` and the *frozen* `integration.Verifier` at stage "B",
unchanged, so what passes or fails is decided by the locked checks.

It also writes out the proposed `stage-b-link` crate and shows that it differs
from the frozen `stage-a-link` only in which candidate crate and type it names.
No Stage B candidate exists, so those files are produced as a reviewable
proposal in the evidence directory, not added to the build.
"""
import json
from pathlib import Path
import sys
import traceback

from linked import run_linked
from syntax import Refusal, check, parse


HERE = Path(__file__).resolve().parent

# The witness program: refused by Stage A, accepted by Stage B, and small
# enough that its whole predicted schedule can be written by hand.
WITNESS = "def f(): Int = 7 end main = f()"
WITNESS_CASE = dict(source=WITNESS, cells=[], inputs=[], outside=[])
WITNESS_TRANSITIONS = 6

# Deliberate defects compiled into the canned fixture. Each is named for what
# it actually does. They demonstrate that the frozen checks reject a real
# compiled artifact; they are NOT the ten deferred evaluator control paths.
STUB_CONTROLS = {
    "omitted-enter-event": "commit metadata",
    "enter-site-mismatch": "extended call/event prefix",
    "entry-birth-origin": "birth origin/domain/order",
    "duplicate-return-frame": "full committed execution/physical state",
}

LINK_CARGO = """[package]
name = "rob1333-stage-b-link"
version = "0.0.0"
edition = "2024"
publish = false

[[bin]]
name = "rob1333-stage-b-link"
path = "main.rs"

[dependencies]
mo-stage-b = { path = "../candidate-stage-b" }
mo-acceptance-driver = { path = "../driver" }
"""

LINK_MAIN = """fn main() {
    if let Err(error) = mo_acceptance_driver::serve::<mo_stage_b::StageB>() {
        eprintln!("{error}");
        std::process::exit(1);
    }
}
"""


def stage_boundary():
    """Stage A must refuse the witness; Stage B must accept it."""
    program = parse(WITNESS)
    try:
        check(program, "A")
    except Refusal as error:
        refused = error.kind
    else:
        refused = None
    accepted = check(parse(WITNESS), "B")
    assert refused == "stage-unsupported", "Stage A must refuse the witness"
    assert accepted == "Int", "Stage B must accept the witness"
    return dict(stage_a=refused, stage_b_result_type=accepted)


def link_proposal():
    """The proposed Stage B link crate, next to the frozen Stage A one."""
    stage_a = dict(cargo=(HERE / "stage-a-link" / "Cargo.toml").read_text(),
                   main=(HERE / "stage-a-link" / "main.rs").read_text())
    differences = []
    for key, proposed, existing in (("Cargo.toml", LINK_CARGO, stage_a["cargo"]),
                                    ("main.rs", LINK_MAIN, stage_a["main"])):
        changed = [(a, b) for a, b in zip(existing.splitlines(), proposed.splitlines()) if a != b]
        differences.append(dict(file=key, changed_lines=changed,
                                same_line_count=len(existing.splitlines()) == len(proposed.splitlines())))
    return dict(cargo=LINK_CARGO, main=LINK_MAIN, differences=differences)


def reject(fn, message):
    try:
        fn()
    except (AssertionError, ValueError, KeyError, TypeError) as error:
        assert message in str(error), (message, str(error))
        return str(error)
    raise AssertionError("control accepted: " + message)


def run(destination, command):
    destination = Path(destination)
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, candidate_executed=False, stage_b_linked_stub_runs=0,
                  resume_cuts=0, destroy_cuts=0, controls={})
    try:
        report["stage_boundary"] = stage_boundary()
        proposal = link_proposal()
        (destination / "stage-b-link.Cargo.toml").write_text(proposal["cargo"])
        (destination / "stage-b-link.main.rs").write_text(proposal["main"])
        report["link_proposal"] = proposal["differences"]

        # One whole run first, then every cut: resume from each boundary with a
        # zero-work join, and destroy from each boundary. Terminal included.
        whole = run_linked(command, WITNESS_CASE, [WITNESS_TRANSITIONS],
                           destination / "whole", fixture_stub=True)
        assert whole["committed_steps"] == WITNESS_TRANSITIONS and whole["destroy_calls"] == 2
        report["stage_b_linked_stub_runs"] += 1
        for cut in range(WITNESS_TRANSITIONS + 1):
            resumed = run_linked(command, WITNESS_CASE, [cut, 0, WITNESS_TRANSITIONS - cut, 0, 9],
                                 destination / f"resume-{cut}", fixture_stub=True)
            assert resumed["committed_steps"] == WITNESS_TRANSITIONS, "resume reached terminal"
            destroyed = run_linked(command, WITNESS_CASE, [cut], destination / f"destroy-{cut}",
                                   fixture_stub=True)
            assert destroyed["destroy_calls"] == 2, "repeated destroy"
            report["resume_cuts"] += 1
            report["destroy_cuts"] += 1
            report["stage_b_linked_stub_runs"] += 2
        for name, message in STUB_CONTROLS.items():
            report["controls"]["compiled-stub/" + name] = reject(
                lambda name=name: run_linked(command, WITNESS_CASE, [WITNESS_TRANSITIONS],
                                             destination / f"broken-{name}",
                                             env={"ROB_STAGE_B_CONTROL": name}, fixture_stub=True),
                message)
        report["qualification"] = (
            "A canned interface fixture, not a Mo interpreter. These runs show that the frozen "
            "Stage B link, birth registry, invocation normalisation and enter/return comparison "
            "work end to end. They are not evidence about any candidate's semantics, and none of "
            "the ten deferred Stage B evaluator control paths ran.")
        report["passed"] = True
    except Exception:
        report["error"] = traceback.format_exc()
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({k: v for k, v in report.items() if k != "link_proposal"}, indent=2))
    return report["passed"]


if __name__ == "__main__":
    sys.exit(not run(Path(sys.argv[1]), [sys.argv[2]]))
