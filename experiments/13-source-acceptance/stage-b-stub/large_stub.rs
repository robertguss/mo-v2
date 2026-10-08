//! CANNED large-run interface fixture for `input xs: ListInt; main = 0`.
//!
//! Not a parser or an evaluator. It replays the hand-written unused-input
//! cleanup schedule for a list of any length, using the real native cell
//! capability: each cell's holder is actually given up and the cell is
//! actually freed. That is enough to drive the large streaming adapter, the
//! D151 observation schedule and the inclusive watchdog at a scale where no
//! materialised reference trace exists. Never builder input.
//!
//! Depth comes from the installed fixture, so the acceptance host always
//! decides how large a run is. `ROB_STAGE_B_CONTROL` selects a deliberate
//! defect for the control harness.
use mo_acceptance_driver::serve;
use mo_acceptance_runtime::*;
use serde_json::{Value as Json, json};

const SOURCE: &[u8] = b"input xs: ListInt; main = 0";
const DUMP: &[u8] = br#"{"node":"Program","inputs":[{"name":"xs","type":"ListInt","binding":"input/0"}],"functions":[],"main":{"node":"Int","path":"main","type":"Int","value":"0"}}"#;
const SPANS: &[u8] = br#"[{"path":"root","span":{"start":[1,1],"end":[1,28]}},{"path":"input/0","span":{"start":[1,1],"end":[1,19]}},{"path":"main","span":{"start":[1,27],"end":[1,28]}}]"#;

/// Opaque candidate-side binding identity for the single input.
const BINDING: u64 = 555;

struct Stub;
struct Run {
    cells: RuntimeCells,
    chain: Vec<u64>,
    step: u64,
    released: Vec<u64>,
    cleanup: Vec<Json>,
    destroyed: bool,
}

fn control() -> String {
    std::env::var("ROB_STAGE_B_CONTROL").unwrap_or_default()
}

impl Run {
    fn depth(&self) -> u64 {
        self.chain.len() as u64
    }
    fn last(&self) -> u64 {
        3 + 2 * self.depth()
    }
    fn freed(&self) -> u64 {
        self.step.min(2 * self.depth()) / 2
    }
}

fn status(run: &Run) -> Status {
    if run.step == run.last() {
        Status::Finished
    } else {
        Status::Suspended
    }
}

fn transition(run: &Run, step: u64) -> (&'static str, &'static str, Option<u64>) {
    let cleanup = 2 * run.depth();
    if step <= cleanup {
        if step % 2 == 1 {
            ("Give up holder", "root", Some(step - 1))
        } else {
            ("Free cell", "root", Some(step - 1))
        }
    } else {
        match step - cleanup {
            1 => ("Start", "root", Some(cleanup)),
            2 => ("Leaf", "main", None),
            _ => ("Finish", "root", Some(cleanup + 1)),
        }
    }
}

fn binding_row(run: &Run) -> Json {
    let root = run.chain.first().copied();
    let value = json!(["l", root]);
    let status = if run.depth() == 0 {
        "noHolder"
    } else if run.step == 0 {
        "holding"
    } else {
        "givenUp"
    };
    json!([BINDING, "xs", value, status])
}

impl Candidate for Stub {
    type CheckedProgram = ();
    type Run = Run;

    fn check_source(source: &[u8], cells: &RuntimeCells) -> Result<(), CheckFailure> {
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

    fn begin(_: &(), inputs: Vec<(String, Value)>, cells: RuntimeCells) -> Run {
        let Value::ListInt(mut here) = inputs[0].1 else {
            panic!("fixture kind")
        };
        // Walk the installed list once, through the ordinary read capability.
        let mut chain = vec![];
        while let Some(id) = here {
            let cell = cells
                .allocate(Resource::Number, || cells.read(id))
                .expect("number gate")
                .expect("installed cell");
            chain.push(id);
            here = cell.tail;
        }
        Run {
            cells,
            chain,
            step: 0,
            released: vec![],
            cleanup: vec![],
            destroyed: false,
        }
    }

    fn advance(run: &mut Run, budget: u64, committed: &mut dyn FnMut(&Run, &[u8])) -> Outcome {
        for _ in 0..budget {
            if run.step == run.last() {
                break;
            }
            let step = run.step + 1;
            let mut freed = None;
            if step <= 2 * run.depth() {
                let index = ((step - 1) / 2) as usize;
                let id = run.chain[index];
                if step % 2 == 1 {
                    // Give up the holder: bookkeeping only, never a cell event.
                    run.cells.metadata(id, 0, false).expect("holder bookkeeping");
                    run.released.push(id);
                } else if control() == "physical-leak" {
                    // Report the free without performing it.
                    freed = Some(id);
                } else {
                    run.cells.free(id).expect("free");
                    freed = Some(id);
                }
            }
            run.step = step;
            let (name, site, landmark) = transition(run, step);
            let added: Vec<Json> = freed.map(|id| json!(["free", id])).into_iter().collect();
            let metadata = json!({"step":step,"transition":name,"site":site,
                "event_end":run.freed(),"landmark":landmark,
                "events_added":added,"births_added":[]});
            committed(run, metadata.to_string().as_bytes());
        }
        Outcome {
            status: status(run),
            committed_steps: run.step,
        }
    }

    fn snapshot(run: &Run) -> Vec<u8> {
        let alive = !run.destroyed;
        let step = run.step;
        let cleanup = 2 * run.depth();
        let kind = if !alive {
            Json::Null
        } else if step == 0 {
            Json::Null
        } else if step <= cleanup {
            json!(if step % 2 == 1 { "holderGivenUp" } else { "cellFreed" })
        } else if step == cleanup + 1 {
            json!("start")
        } else if step == cleanup + 3 {
            json!("end")
        } else {
            Json::Null
        };
        let pending: Vec<Json> = if alive && step > 0 && step <= cleanup && step % 2 == 0 {
            let next = (step / 2) as usize;
            run.chain
                .get(next)
                .map(|id| json!(["l", id]))
                .into_iter()
                .collect()
        } else {
            vec![]
        };
        let events: Vec<Json> = run.chain[..run.freed() as usize]
            .iter()
            .map(|id| json!(["free", id]))
            .collect();
        let control_stack: Vec<Json> = if alive && step == cleanup + 2 {
            vec![json!({"site":"main","scope":[["xs",BINDING]],"invocation":0,"operands":[]})]
        } else {
            vec![]
        };
        let release: Vec<Json> = if alive && step > 0 && step <= cleanup {
            run.released.iter().map(|id| json!(id)).collect()
        } else {
            vec![]
        };
        json!({
            "step": step,
            "status": match status(run) { Status::Finished => "finished", _ => "suspended" },
            "state": {
                "kind": kind,
                "bindings": if alive { vec![binding_row(run)] } else { vec![] },
                "pending": pending,
                "aside": [],
                "branch": Json::Null,
                "frames": [],
            },
            "control": control_stack,
            "ready": if alive && step >= cleanup + 2 { json!(["n","0"]) } else { Json::Null },
            "release": release,
            "event_end": run.freed(),
            "events": events,
            "births": [{"domain":"binding","id":BINDING,"origin":"input/0","invocation":0}],
            "failure": Json::Null,
            "cleanup_events": run.cleanup,
        })
        .to_string()
        .into_bytes()
    }

    fn public_output(run: &Run) -> Vec<u8> {
        match status(run) {
            Status::Finished => b"{\"status\":\"finished\",\"type\":\"Int\",\"value\":\"0\"}\n".to_vec(),
            _ => format!("{{\"status\":\"suspended\",\"steps\":\"{}\"}}\n", run.step).into_bytes(),
        }
    }

    fn destroy(run: &mut Run) -> Result<(), CleanupFailure> {
        if run.destroyed {
            return Ok(());
        }
        // Whatever the run still holds is released iteratively, head first.
        for &id in &run.chain[run.freed() as usize..] {
            run.cells.metadata(id, 0, false).ok();
            run.cells.free(id).map_err(|_| CleanupFailure {
                class: "unknown-cell".into(),
            })?;
            run.cleanup.push(json!(["free", id]));
        }
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
