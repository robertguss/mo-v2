//! CANNED Stage B interface fixture for `def f(): Int = 7 end main = f()`.
//!
//! This is not a parser, a type checker or an evaluator. It replays one
//! hand-written six-action schedule with a real function entry and return, so
//! the frozen acceptance driver and the frozen small-case verifier can be run
//! against a program that Stage A refused. Every byte below was written from
//! the approved English rules; nothing is read from acceptance predictions at
//! run time. Never builder input.
//!
//! `ROB_STAGE_B_CONTROL` selects a deliberate defect compiled into this
//! fixture. Each is named for exactly what it corrupts. They show that the
//! frozen checks reject a real compiled artifact; they are deliberately NOT
//! named after the ten deferred Stage B evaluator control paths, none of which
//! a canned fixture can exercise.
use mo_acceptance_driver::serve;
use mo_acceptance_runtime::*;
use serde_json::{Value as Json, json};

const SOURCE: &[u8] = b"def f(): Int = 7 end main = f()";
const DUMP: &[u8] = br#"{"node":"Program","inputs":[],"functions":[{"name":"f","function":"function/0","parameters":[],"result":"Int","body":{"node":"Int","path":"function/0/body","type":"Int","value":"7"}}],"main":{"node":"Call","path":"main","name":"f","function":"function/0","type":"Int","children":[]}}"#;
const SPANS: &[u8] = br#"[{"path":"root","span":{"start":[1,1],"end":[1,32]}},{"path":"function/0","span":{"start":[1,1],"end":[1,21]}},{"path":"function/0/body","span":{"start":[1,16],"end":[1,17]}},{"path":"main","span":{"start":[1,29],"end":[1,32]}}]"#;

/// Opaque candidate-side frame identity. Deliberately not 1, so the acceptance
/// birth registry has to map it onto the predicted invocation.
const FRAME: u64 = 77;
const LAST: u64 = 6;

struct Stub;
struct Run {
    _cells: RuntimeCells,
    step: u64,
    destroyed: bool,
}

fn control() -> String {
    std::env::var("ROB_STAGE_B_CONTROL").unwrap_or_default()
}

fn status(run: &Run) -> Status {
    if run.step == LAST {
        Status::Finished
    } else {
        Status::Suspended
    }
}

/// The entry event of the single invocation, with its originating call site.
fn enter_event() -> Json {
    let site = if control() == "enter-site-mismatch" {
        "function/0/body"
    } else {
        "main"
    };
    json!(["enter", FRAME, 0, "f", site])
}

fn return_event() -> Json {
    json!(["return", FRAME, ["n", "7"]])
}

fn frame_birth() -> Json {
    let origin = if control() == "entry-birth-origin" {
        "function/0/body"
    } else {
        "main"
    };
    json!({"domain":"frame","id":FRAME,"origin":origin,"invocation":0})
}

/// Committed events visible after `step`.
fn events(step: u64) -> Vec<Json> {
    let mut rows = vec![];
    if step >= 3 && control() != "omitted-enter-event" {
        rows.push(enter_event());
    }
    if step >= 5 {
        rows.push(return_event());
    }
    rows
}

fn births(step: u64) -> Vec<Json> {
    if step >= 3 {
        vec![frame_birth()]
    } else {
        vec![]
    }
}

fn kind(step: u64) -> Option<&'static str> {
    match step {
        1 => Some("start"),
        3 => Some("callEntered"),
        5 => Some("callReturned"),
        6 => Some("end"),
        _ => None,
    }
}

fn frames(step: u64) -> Vec<u64> {
    if (3..=4).contains(&step) {
        vec![FRAME]
    } else {
        vec![]
    }
}

fn control_stack(step: u64) -> Vec<Json> {
    let outer = json!({"site":"main","scope":[],"invocation":0,"operands":[]});
    let inner = json!({"site":"function/0/body","scope":[],"invocation":FRAME,"operands":[]});
    match step {
        2 | 3 | 5 => vec![outer],
        4 => {
            if control() == "duplicate-return-frame" {
                vec![outer.clone(), inner.clone(), inner]
            } else {
                vec![outer, inner]
            }
        }
        _ => vec![],
    }
}

fn ready(step: u64) -> Json {
    if step >= 4 {
        json!(["n", "7"])
    } else {
        Json::Null
    }
}

fn metadata(step: u64) -> Json {
    let (transition, site, landmark) = match step {
        1 => ("Start", "root", Some(0)),
        2 => ("Dispatch compound", "main", None),
        3 => ("Enter", "main", Some(1)),
        4 => ("Leaf", "function/0/body", None),
        5 => ("Return", "main", Some(2)),
        _ => ("Finish", "root", Some(3)),
    };
    let added: Vec<Json> = match step {
        3 if control() != "omitted-enter-event" => vec![enter_event()],
        5 => vec![return_event()],
        _ => vec![],
    };
    let born: Vec<Json> = if step == 3 {
        vec![frame_birth()]
    } else {
        vec![]
    };
    json!({"step":step,"transition":transition,"site":site,
        "event_end":events(step).len(),"landmark":landmark,
        "events_added":added,"births_added":born})
}

impl Candidate for Stub {
    type CheckedProgram = ();
    type Run = Run;

    fn check_source(source: &[u8], cells: &RuntimeCells) -> Result<(), CheckFailure> {
        // A real gated owned buffer, exactly as the Stage A fixture stub does.
        // No managed cell or frame is touched before the fixture is installed.
        cells
            .allocate(Resource::Number, || String::from("0"))
            .map_err(|_| CheckFailure::Failed {
                class: "resource-exhausted".into(),
                domain: Some(Resource::Number),
            })?;
        if source == SOURCE {
            Ok(())
        } else {
            Err(CheckFailure::Refused(Diagnostic {
                class: "stage-b-stub-unsupported-source".into(),
                span: Span::Text {
                    start: (1, 1),
                    end: (1, 1),
                },
            }))
        }
    }

    fn checked_dump(_: &()) -> Vec<u8> {
        DUMP.to_vec()
    }

    fn source_spans(_: &()) -> Vec<u8> {
        SPANS.to_vec()
    }

    fn begin(_: &(), _inputs: Vec<(String, Value)>, cells: RuntimeCells) -> Run {
        Run {
            _cells: cells,
            step: 0,
            destroyed: false,
        }
    }

    fn advance(run: &mut Run, budget: u64, committed: &mut dyn FnMut(&Run, &[u8])) -> Outcome {
        for _ in 0..budget {
            if run.step == LAST {
                break;
            }
            run.step += 1;
            committed(run, metadata(run.step).to_string().as_bytes());
        }
        Outcome {
            status: status(run),
            committed_steps: run.step,
        }
    }

    fn snapshot(run: &Run) -> Vec<u8> {
        let alive = !run.destroyed;
        let step = run.step;
        json!({
            "step": step,
            "status": match status(run) { Status::Finished => "finished", _ => "suspended" },
            "state": {
                "kind": if alive { kind(step).map(Json::from).unwrap_or(Json::Null) } else { Json::Null },
                "bindings": [],
                "pending": [],
                "aside": [],
                "branch": Json::Null,
                "frames": if alive { frames(step) } else { vec![] },
            },
            "control": if alive { control_stack(step) } else { vec![] },
            "ready": if alive { ready(step) } else { Json::Null },
            "release": [],
            "event_end": events(step).len(),
            "events": events(step),
            "births": births(step),
            "failure": Json::Null,
            "cleanup_events": [],
        })
        .to_string()
        .into_bytes()
    }

    fn public_output(run: &Run) -> Vec<u8> {
        match status(run) {
            Status::Finished => {
                b"{\"status\":\"finished\",\"type\":\"Int\",\"value\":\"7\"}\n".to_vec()
            }
            _ => format!("{{\"status\":\"suspended\",\"steps\":\"{}\"}}\n", run.step).into_bytes(),
        }
    }

    fn destroy(run: &mut Run) -> Result<(), CleanupFailure> {
        // This schedule owns no managed cell, so destruction only retires the
        // run's own temporaries. Repeated destruction must stay harmless.
        run.destroyed = true;
        Ok(())
    }
}

fn main() {
    if let Err(error) = serve::<Stub>() {
        eprintln!("{error}");
        std::process::exit(1);
    }
}
