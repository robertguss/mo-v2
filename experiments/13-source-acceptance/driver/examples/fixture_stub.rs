//! CANNED interface fixture, NOT a source parser or Mo evaluator. Three supplied
//! states model the existing main=xs bridge fixture. Never builder input.
use mo_acceptance_driver::serve;
use mo_acceptance_runtime::*;
use serde_json::{Value as Json, json};

struct Stub;
struct Run {
    cells: RuntimeCells,
    root: Option<u64>,
    step: u64,
    failed: Option<&'static str>,
    destroyed: bool,
    answer: Vec<String>,
    cleanup: Vec<Json>,
    frame: Option<Vec<u8>>,
}
fn control() -> String {
    std::env::var("ROB_STUB_CONTROL").unwrap_or_default()
}
fn status(r: &Run) -> Status {
    if r.failed.is_some() {
        Status::Failed
    } else if r.step == 3 {
        Status::Finished
    } else {
        Status::Suspended
    }
}
impl Candidate for Stub {
    type CheckedProgram = ();
    type Run = Run;
    fn check_source(source: &[u8], cells: &RuntimeCells) -> Result<(), CheckFailure> {
        if source == b"main = @" {
            return Err(CheckFailure::Refused(Diagnostic {
                class: "lexical".into(),
                span: Span::Text {
                    start: (1, 8),
                    end: (1, 9),
                },
            }));
        }
        // Real gated owned buffer, but no syntax is interpreted by this stub.
        let allocation = cells
            .allocate(Resource::Number, || String::from("0"))
            .map_err(|_| CheckFailure::Failed {
                class: "resource-exhausted".into(),
                domain: Some(Resource::Number),
            });
        if control() != "ignored-frontend-denial" {
            allocation?;
        }
        Ok(())
    }
    fn checked_dump(_: &()) -> Vec<u8> {
        br#"{"node":"Program","inputs":[{"name":"xs","type":"ListInt","binding":"input/0"}],"functions":[],"main":{"node":"Var","path":"main","name":"xs","binding":"input/0","type":"ListInt"}}"#.to_vec()
    }
    fn source_spans(_: &()) -> Vec<u8> {
        br#"[{"path":"root","span":{"start":[1,1],"end":[1,29]}},{"path":"input/0","span":{"start":[1,1],"end":[1,19]}},{"path":"main","span":{"start":[1,27],"end":[1,29]}}]"#.to_vec()
    }
    fn begin(_: &(), inputs: Vec<(String, Value)>, cells: RuntimeCells) -> Run {
        let Value::ListInt(root) = inputs[0].1 else {
            panic!("fixture kind")
        };
        Run {
            cells,
            root,
            step: 0,
            failed: None,
            destroyed: false,
            answer: vec![],
            cleanup: vec![],
            frame: None,
        }
    }
    fn advance(r: &mut Run, budget: u64, committed: &mut dyn FnMut(&Run, &[u8])) -> Outcome {
        for _ in 0..budget {
            if r.step == 3 || r.failed.is_some() {
                break;
            }
            if r.step == 1 {
                if control() == "cell-denial-probe" {
                    // Only a denied native operation; not an evaluator or a
                    // successful extra allocation in the prescribed trace.
                    let item = r
                        .cells
                        .allocate(Resource::Number, || String::from("17"))
                        .unwrap();
                    assert_eq!(
                        r.cells.create(Cell {
                            item,
                            tail: None,
                            holders: 1,
                            aside: false
                        }),
                        Err(Error::InjectedAllocationFailure)
                    );
                    r.failed = Some("cell");
                    break;
                }
                let frame = match r.cells.allocate(Resource::Frame, || vec![0; 8]) {
                    Ok(value) => value,
                    Err(_) => {
                        r.failed = Some("frame");
                        break;
                    }
                };
                let mut values = vec![];
                let mut here = r.root;
                while let Some(id) = here {
                    let cell = match r.cells.allocate(Resource::Number, || r.cells.read(id)) {
                        Ok(Ok(cell)) => cell,
                        Err(_) => {
                            r.failed = Some("number");
                            break;
                        }
                        _ => panic!("fixture read"),
                    };
                    here = cell.tail;
                    values.push(cell.item);
                }
                if r.failed.is_some() {
                    break;
                }
                r.frame = Some(frame);
                r.answer = values;
            }
            r.step += 1;
            let mut metadata = json!({"step":r.step,"transition":match r.step {1=>"Start",2=>"Leaf",_=>"Finish"},
                "site":if r.step==2 {"main"} else {"root"},"event_end":0,"landmark":r.step-1,"events_added":[],"births_added":[]});
            if control() == "counter" {
                metadata["step"] = json!(r.step + 1);
            }
            committed(r, metadata.to_string().as_bytes());
        }
        Outcome {
            status: status(r),
            committed_steps: r.step,
        }
    }
    fn snapshot(r: &Run) -> Vec<u8> {
        let alive = !r.destroyed;
        let mut snapshot = json!({"step":r.step,"status":match status(r) {Status::Finished=>"finished",Status::Failed=>"failed",_=>"suspended"},
            "state":{"kind":match r.step {0=>None,1=>Some("start"),2=>Some("holderMoved"),_=>Some("end")},
                "bindings":if alive {json!([[901,"xs",["l",r.root],if r.step<2 {"holding"} else {"movedOn"}]])} else {json!([])},
                "pending":if alive && r.step>=2 && r.root.is_some() {json!([["l",r.root]])} else {json!([])},
                "aside":[],"branch":null,"frames":[]},
            "control":if alive && r.step==2 {json!([{"site":"main","scope":[["xs",901]],"invocation":0,"operands":[]}])} else {json!([])},
            "ready":if alive && r.step>=2 {json!(["l",r.root])} else {Json::Null},"release":[],"event_end":0,"events":[],
            "births":[{"domain":"binding","id":901,"origin":"input/0","invocation":0}],
            "failure":r.failed.map(|d|json!({"class":"resource-exhausted","step":r.step,"domain":d,"aborts":[]})),
            "cleanup_events":r.cleanup});
        if control() == "shadow-state" && r.step == 2 {
            snapshot["ready"] = json!(["n", "999"]);
        }
        snapshot.to_string().into_bytes()
    }
    fn public_output(r: &Run) -> Vec<u8> {
        match status(r) {
            Status::Failed => format!(
                "{{\"status\":\"failed\",\"class\":\"resource-exhausted\",\"step\":\"{}\"}}\n",
                r.step
            )
            .into_bytes(),
            Status::Suspended => {
                format!("{{\"status\":\"suspended\",\"steps\":\"{}\"}}\n", r.step).into_bytes()
            }
            Status::Finished => format!(
                "{{\"status\":\"finished\",\"type\":\"ListInt\",\"value\":{}}}\n",
                serde_json::to_string(&r.answer).unwrap()
            )
            .into_bytes(),
        }
    }
    fn destroy(r: &mut Run) -> Result<(), CleanupFailure> {
        if r.destroyed {
            return Ok(());
        }
        if control() == "leak" {
            r.destroyed = true;
            return Ok(());
        }
        let mut here = r.root;
        while let Some(id) = here {
            let c = r
                .cells
                .allocate(Resource::Number, || r.cells.read(id))
                .unwrap()
                .unwrap();
            r.cells.metadata(id, c.holders - 1, false).unwrap();
            if c.holders > 1 {
                break;
            }
            here = c.tail;
            r.cells.free(id).unwrap();
            r.cleanup.push(json!(["free", id]));
        }
        r.destroyed = true;
        r.frame = None;
        r.answer.clear();
        Ok(())
    }
}
fn main() {
    if let Err(error) = serve::<Stub>() {
        eprintln!("{error}");
        std::process::exit(1);
    }
}
