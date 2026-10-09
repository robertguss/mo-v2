//! Timing-01 instrumentation of the approved memory-optimized collector.
//! Generic over the unchanged candidate; semantic records remain unchanged.
use acceptance_cells::{Cursor, Event, Observer, Phase, fixture};
use mo_acceptance_runtime::{
    Candidate, Cell, CheckFailure, Observation, Resource, Span, Status, Value,
};
use serde_json::{Value as Json, json};
use std::io::{BufRead, Write};
use std::time::Instant;
mod snapshot;
use snapshot::Snapshot;
mod timing;
use timing::{Category::*, CleanupDrop, in_category, scope};

pub type Result<T> = std::result::Result<T, String>;

pub enum Approval {
    Install,
    InvalidFixture { class: String, path: String },
}

/// Internal acceptance inputs; none of budgets, controls, observer or expected
/// data is passed to check_source/begin. Expected data never enters this crate.
pub struct Request {
    pub source: Vec<u8>,
    pub cells: Vec<(u64, Cell)>,
    pub inputs: Vec<(String, Value)>,
    pub outside: Vec<Option<u64>>,
    pub budgets: Vec<u64>,
    pub large: bool,
    pub deny_cell: Option<u64>,
    pub deny_resource: Option<(Resource, u64)>,
}

pub fn pre_run(failure: &CheckFailure) -> Vec<u8> {
    let quote = |s: &str| serde_json::to_string(s).unwrap();
    let text = match failure {
        CheckFailure::Refused(d) => {
            let span = match d.span {
                Span::Text { start, end } => format!(
                    "{{\"start\":[{},{}],\"end\":[{},{}]}}",
                    start.0, start.1, end.0, end.1
                ),
                Span::Bytes { start, end } => format!("{{\"bytes\":[{start},{end}]}}"),
            };
            format!(
                "{{\"status\":\"refused\",\"class\":{},\"span\":{span}}}\n",
                quote(&d.class)
            )
        }
        CheckFailure::Failed { class, .. } => format!(
            "{{\"status\":\"failed\",\"class\":{},\"step\":\"0\"}}\n",
            quote(class)
        ),
    };
    text.into_bytes()
}
pub fn invalid_fixture(class: &str, path: &str) -> Vec<u8> {
    format!(
        "{{\"status\":\"invalid-fixture\",\"class\":{},\"path\":{}}}\n",
        serde_json::to_string(class).unwrap(),
        serde_json::to_string(path).unwrap()
    )
    .into_bytes()
}
fn text(bytes: Vec<u8>) -> Result<String> {
    String::from_utf8(bytes).map_err(|e| e.to_string())
}
fn decode(bytes: &[u8]) -> Result<Json> {
    serde_json::from_slice(bytes).map_err(|e| e.to_string())
}
fn natural(value: &Json) -> Result<u64> {
    value.as_u64().ok_or("non-integer counter".into())
}
fn phase_name(phase: Phase) -> &'static str {
    match phase {
        Phase::Frontend => "frontend",
        Phase::Fixture => "fixture",
        Phase::Begin => "begin",
        Phase::Execution => "execution",
        Phase::Destroy => "destroy",
        Phase::Teardown => "teardown",
    }
}
fn event(e: &Event) -> Json {
    json!([e.kind, e.lifetime, e.pointer, phase_name(e.phase)])
}

fn full_observation(large: bool, step: u64) -> Result<bool> {
    if large && step > 100_000_000 {
        return Err("execution transition cap".into());
    }
    Ok(!large || step.is_multiple_of(10_000))
}

struct Collector<'a> {
    observer: &'a Observer,
    cursor: Cursor,
    step: u64,
    event_end: u64,
    observed_event_end: u64,
    started: Instant,
    large: bool,
    outside: &'a [Option<u64>],
    sink: &'a mut dyn FnMut(Json) -> Result<()>,
}
impl Collector<'_> {
    fn emit(&mut self, phase: &str, raw: Json, full: bool) -> Result<()> {
        let _collector = scope(Collector);
        let delta = self.observer.since(self.cursor).map_err(str::to_owned)?;
        let graph = if full {
            Some(
                self.observer
                    .graph()
                    .into_iter()
                    .map(|(id, c, p)| {
                        json!([
                            id,
                            c.item,
                            c.tail,
                            c.holders,
                            if c.aside { "aside" } else { "live" },
                            p
                        ])
                    })
                    .collect::<Vec<_>>(),
            )
        } else {
            None
        };
        let mut row = json!({"phase":phase,"elapsed_ns":self.started.elapsed().as_nanos(),"step":self.step,
            "raw":null,"graph":null,"outside":self.outside,
            "from":[self.cursor.events,self.cursor.mutations,self.cursor.resources,self.cursor.creates],
            "to":[delta.cursor.events,delta.cursor.mutations,delta.cursor.resources,delta.cursor.creates],
            "events":delta.events.iter().map(event).collect::<Vec<_>>(),
            "mutations":delta.mutations.iter().map(event).collect::<Vec<_>>(),
            "creates":delta.creates.iter().map(|(n,allowed,p)|json!([n,allowed,phase_name(*p)])).collect::<Vec<_>>(),
            "resources":delta.resources.iter().map(|r| json!([if r.domain == Resource::Number {"number"} else {"frame"},r.ordinal,r.allowed,phase_name(r.phase)])).collect::<Vec<_>>()});
        // json! serializes borrowed expressions into fresh trees. Move these
        // already-owned values instead of cloning the full snapshot/graph.
        row["raw"] = raw;
        row["graph"] = graph.map(Json::Array).unwrap_or(Json::Null);
        (self.sink)(row)?;
        self.cursor = delta.cursor;
        Ok(())
    }
    fn committed<C: Candidate>(&mut self, run: &C::Run, bytes: &[u8]) -> Result<()> {
        let metadata = decode(bytes)?;
        let step = natural(&metadata["step"])?;
        if step != self.step.checked_add(1).ok_or("step overflow")? {
            return Err("nonconsecutive callback".into());
        }
        let end = natural(&metadata["event_end"])?;
        let added = metadata["events_added"]
            .as_array()
            .ok_or("missing events_added")?
            .len() as u64;
        if end
            != self
                .event_end
                .checked_add(added)
                .ok_or("event counter overflow")?
        {
            return Err("event prefix counter".into());
        }
        self.step = step;
        self.event_end = end;
        let full = full_observation(self.large, step)?;
        let snapshot = if full {
            let request = if self.large {
                Observation::Summary {
                    since_event: self.observed_event_end,
                }
            } else {
                Observation::Full
            };
            let result = text(in_category(Observation, || C::observe(run, request)))?;
            self.observed_event_end = end;
            Some(result)
        } else {
            None
        };
        // Preserve original bytes as strings. Python checks duplicates/strict
        // schema; serde's map parser must not erase duplicate-key evidence.
        self.emit(
            "commit",
            json!({"metadata":text(bytes.to_vec())?,"snapshot":snapshot}),
            full && !self.large,
        )
    }
    fn boundary<C: Candidate>(&mut self, phase: &str, run: &C::Run) -> Result<Snapshot> {
        let bytes = in_category(Observation, || C::observe(run, Observation::Full));
        let snapshot = Snapshot::parse(bytes)?;
        if snapshot.step != self.step {
            return Err("boundary step mismatch".into());
        }
        self.emit(
            phase,
            json!({"snapshot":snapshot.raw,"public":if phase.starts_with("destroy") { None } else { Some(text(in_category(Observation, || C::public_output(run)))?) }}),
            true,
        )?;
        self.observed_event_end = self.event_end;
        Ok(snapshot)
    }
}

/// `checked` is acceptance's independent source/fixture validator, called before
/// installing a single fixture cell. It receives no candidate mutable capability.
/// `sink` may verify each record synchronously; verification waits remain timed.
pub fn collect<C: Candidate>(
    request: Request,
    checked: &mut dyn FnMut(&[u8], &[u8]) -> Result<Approval>,
    sink: &mut dyn FnMut(Json) -> Result<()>,
) -> Result<()> {
    let (cells, observer) = fixture(vec![]);
    if let Some(n) = request.deny_cell {
        observer.fail_create(n);
    }
    if let Some((d, n)) = request.deny_resource {
        observer.fail_resource(d, n);
    }
    let mut out = Collector {
        observer: &observer,
        cursor: Cursor::default(),
        step: 0,
        event_end: 0,
        observed_event_end: 0,
        started: Instant::now(),
        large: request.large,
        outside: &request.outside,
        sink,
    };
    let checked_program =
        in_category(Frontend, || C::check_source(&request.source, &cells)).map(CleanupDrop::new);
    if !observer.frontend_clean() {
        return Err("frontend managed-cell/frame activity".into());
    }
    let program = match checked_program {
        Ok(program) => program,
        Err(failure) => {
            let classification = match &failure {
                CheckFailure::Refused(_) => json!({"kind":"refused"}),
                CheckFailure::Failed { class, domain } => json!({"kind":"failed","class":class,
                    "domain":domain.map(|d| if d == Resource::Number {"number"} else {"frame"})}),
            };
            return out.emit(
                "pre-run",
                json!({"public":text(pre_run(&failure))?,"failure":classification}),
                true,
            );
        }
    };
    let dump = in_category(Observation, || C::checked_dump(&program));
    let spans = in_category(Observation, || C::source_spans(&program));
    let approval = in_category(ApprovalWait, || checked(&dump, &spans))?;
    out.emit(
        "frontend",
        json!({"checked":text(dump)?,"spans":text(spans)?}),
        true,
    )?;
    if let Approval::InvalidFixture { class, path } = approval {
        return out.emit(
            "invalid-fixture",
            json!({"public":text(invalid_fixture(&class,&path))?}),
            true,
        );
    }
    // A poisoned input kind/name is refused before begin by the independent
    // checked callback/fixture validation, not inferred from candidate answers.
    let mut roots = request.outside.clone();
    for (_, value) in &request.inputs {
        if let Value::ListInt(root) = value {
            roots.push(*root);
        }
    }
    if let Err(error) = observer.install(request.cells, &roots) {
        return out.emit(
            "invalid-fixture",
            json!({"public":text(invalid_fixture(error.class,&error.path))?}),
            true,
        );
    }
    out.emit("fixture", json!({}), true)?;
    observer.phase(Phase::Begin);
    let mut run = CleanupDrop::new(in_category(Evaluation, || {
        C::begin(&program, request.inputs, cells)
    }));
    let mut prior = out.boundary::<C>("begin", &run)?;
    for budget in request.budgets {
        observer.phase(Phase::Execution);
        let before_step = out.step;
        let mut error = None;
        // Candidate-generated callback metadata outside the callback remains
        // evaluation. This is intentionally not an evaluator-only benchmark.
        let outcome = in_category(Evaluation, || {
            C::advance(&mut run, budget, &mut |state, metadata| {
                let _collector = scope(Collector);
                if error.is_none() {
                    if let Err(e) = out.committed::<C>(state, metadata) {
                        error = Some(e);
                    }
                }
            })
        });
        if let Some(e) = error {
            return Err(e);
        }
        if out.step - before_step > budget || outcome.committed_steps != out.step {
            return Err("budget/cumulative outcome mismatch".into());
        }
        let after = out.boundary::<C>("advance", &run)?;
        let status = match outcome.status {
            Status::Suspended => "suspended",
            Status::Finished => "finished",
            Status::Failed => "failed",
        };
        if after.status != status {
            return Err("outcome/snapshot status".into());
        }
        if budget == 0 || prior.status != "suspended" {
            if !after.same_state(&prior)? || before_step != out.step {
                return Err("zero-work/terminal state changed".into());
            }
        }
        prior = after;
    }
    observer.phase(Phase::Destroy);
    // Each boundary remains full; incremental native mutations/events are
    // distinct from execution callbacks and execution step accounting.
    for phase in ["destroy", "destroy-again"] {
        in_category(Cleanup, || C::destroy(&mut run))
            .map_err(|e| format!("cleanup failure: {}", e.class))?;
        out.boundary::<C>(phase, &run)?;
    }
    drop(run); // destruction must not postpone observable frees until Drop
    out.emit("drop", json!({}), true)?;
    observer.teardown();
    out.emit("teardown", json!({}), true)
}

/// Acceptance-only executable adapter. Link by calling serve::<BuilderType>();
/// no Candidate implementation or interpreter is provided by this crate.
pub fn serve<C: Candidate>() -> Result<()> {
    let path = std::env::var_os("ROB1333_TIMING_FILE")
        .filter(|path| !path.is_empty())
        .ok_or("ROB1333_TIMING_FILE is required")?;
    timing::measured(std::path::Path::new(&path), serve_body::<C>)
}

fn serve_body<C: Candidate>() -> Result<()> {
    let mut line = String::new();
    std::io::stdin()
        .lock()
        .read_line(&mut line)
        .map_err(|e| e.to_string())?;
    let input: Json = serde_json::from_str(&line).map_err(|e| e.to_string())?;
    let array = |v: &Json| {
        v.as_array()
            .cloned()
            .ok_or_else(|| "request array".to_string())
    };
    let string = |v: &Json| {
        v.as_str()
            .map(str::to_owned)
            .ok_or_else(|| "request string".to_string())
    };
    let root = |v: &Json| {
        if v.is_null() {
            Ok(None)
        } else {
            natural(v).map(Some)
        }
    };
    let source = array(&input["source"])?
        .iter()
        .map(|v| u8::try_from(natural(v)?).map_err(|_| "source byte".into()))
        .collect::<Result<Vec<_>>>()?;
    let cells = array(&input["cells"])?
        .iter()
        .map(|v| {
            Ok((
                natural(&v[0])?,
                Cell {
                    item: string(&v[1])?,
                    tail: root(&v[2])?,
                    holders: natural(&v[3])?,
                    aside: match v[4].as_str() {
                        Some("live") => false,
                        Some("aside") => true,
                        _ => return Err("cell status".into()),
                    },
                },
            ))
        })
        .collect::<Result<Vec<_>>>()?;
    let inputs = array(&input["inputs"])?
        .iter()
        .map(|v| {
            Ok((
                string(&v[0])?,
                match v[1][0].as_str() {
                    Some("n") => Value::Int(string(&v[1][1])?),
                    Some("l") => Value::ListInt(root(&v[1][1])?),
                    Some("b") => Value::Bool(v[1][1].as_bool().ok_or("Boolean input kind")?),
                    _ => return Err("input value kind".into()),
                },
            ))
        })
        .collect::<Result<Vec<_>>>()?;
    let outside = array(&input["outside"])?
        .iter()
        .map(root)
        .collect::<Result<Vec<_>>>()?;
    let budgets = array(&input["budgets"])?
        .iter()
        .map(natural)
        .collect::<Result<Vec<_>>>()?;
    let deny = &input["deny"];
    let deny_cell = if deny[0] == "cell" {
        Some(natural(&deny[1])?)
    } else {
        None
    };
    let deny_resource = match deny[0].as_str() {
        Some("number") => Some((Resource::Number, natural(&deny[1])?)),
        Some("frame") => Some((Resource::Frame, natural(&deny[1])?)),
        _ => None,
    };
    let request = Request {
        source,
        cells,
        inputs,
        outside,
        budgets,
        large: input["large"].as_bool().ok_or("large Boolean")?,
        deny_cell,
        deny_resource,
    };
    let send = |record: Json| -> Result<()> {
        let _transport = scope(Transport);
        let mut stdout = std::io::stdout().lock();
        writeln!(stdout, "{record}")
            .and_then(|_| stdout.flush())
            .map_err(|e| e.to_string())
    };
    collect::<C>(
        request,
        &mut |dump, spans| {
            send(
                json!({"phase":"check","checked":text(dump.to_vec())?,"spans":text(spans.to_vec())?}),
            )?;
            let mut answer = String::new();
            std::io::stdin()
                .lock()
                .read_line(&mut answer)
                .map_err(|e| e.to_string())?;
            let approval: Json = serde_json::from_str(&answer).map_err(|e| e.to_string())?;
            match approval["status"].as_str() {
                Some("install") => Ok(Approval::Install),
                Some("invalid-fixture") => Ok(Approval::InvalidFixture {
                    class: string(&approval["class"])?,
                    path: string(&approval["path"])?,
                }),
                _ => Err("independent frontend check rejected".into()),
            }
        },
        &mut |record| send(record),
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use mo_acceptance_runtime::Diagnostic;

    struct ObservationProbe;
    struct ProbeRun {
        step: u64,
        requests: std::cell::RefCell<Vec<Observation>>,
    }
    impl Candidate for ObservationProbe {
        type CheckedProgram = ();
        type Run = ProbeRun;
        fn check_source(
            _: &[u8],
            _: &mo_acceptance_runtime::RuntimeCells,
        ) -> std::result::Result<(), CheckFailure> {
            unreachable!()
        }
        fn checked_dump(_: &()) -> Vec<u8> {
            unreachable!()
        }
        fn source_spans(_: &()) -> Vec<u8> {
            unreachable!()
        }
        fn begin(
            _: &(),
            _: Vec<(String, Value)>,
            _: mo_acceptance_runtime::RuntimeCells,
        ) -> ProbeRun {
            unreachable!()
        }
        fn advance(
            _: &mut ProbeRun,
            _: u64,
            _: &mut dyn FnMut(&ProbeRun, &[u8]),
        ) -> mo_acceptance_runtime::Outcome {
            unreachable!()
        }
        fn snapshot(_: &ProbeRun) -> Vec<u8> {
            panic!("collector must request the observation explicitly")
        }
        fn observe(run: &ProbeRun, request: Observation) -> Vec<u8> {
            run.requests.borrow_mut().push(request);
            json!({"step":run.step}).to_string().into_bytes()
        }
        fn public_output(_: &ProbeRun) -> Vec<u8> {
            Vec::new()
        }
        fn destroy(
            _: &mut ProbeRun,
        ) -> std::result::Result<(), mo_acceptance_runtime::CleanupFailure> {
            unreachable!()
        }
    }

    #[test]
    fn same_step_gets_explicit_mode_and_boundaries_reset_only_the_observation_cursor() {
        for large in [false, true] {
            let (_cells, observer) = fixture(vec![]);
            let mut rows = Vec::new();
            let mut sink = |row| {
                rows.push(row);
                Ok(())
            };
            let mut collector = Collector {
                observer: &observer,
                cursor: Cursor::default(),
                step: 9_999,
                event_end: 7,
                observed_event_end: 3,
                started: Instant::now(),
                large,
                outside: &[],
                sink: &mut sink,
            };
            let mut run = ProbeRun {
                step: 10_000,
                requests: Default::default(),
            };
            let meta = json!({"step":10_000,"event_end":7,"events_added":[]});
            collector
                .committed::<ObservationProbe>(&run, &serde_json::to_vec(&meta).unwrap())
                .unwrap();
            assert_eq!(
                run.requests.borrow()[0],
                if large {
                    Observation::Summary { since_event: 3 }
                } else {
                    Observation::Full
                }
            );
            collector
                .boundary::<ObservationProbe>("advance", &run)
                .unwrap();
            assert_eq!(run.requests.borrow()[1], Observation::Full);
            assert_eq!(collector.observed_event_end, 7);
            collector.step = 19_999;
            collector.event_end = 11;
            run.step = 20_000;
            let meta = json!({"step":20_000,"event_end":11,"events_added":[]});
            collector
                .committed::<ObservationProbe>(&run, &serde_json::to_vec(&meta).unwrap())
                .unwrap();
            assert_eq!(
                run.requests.borrow()[2],
                if large {
                    Observation::Summary { since_event: 7 }
                } else {
                    Observation::Full
                }
            );
            assert_eq!(rows[0]["graph"].is_null(), large);
            assert!(rows[1]["graph"].is_array());
        }
    }

    #[test]
    fn large_schedule_and_execution_cap_have_exact_boundaries() {
        for (step, full) in [
            (0, true),
            (1, false),
            (9_999, false),
            (10_000, true),
            (10_001, false),
            (99_999_999, false),
            (100_000_000, true),
        ] {
            assert_eq!(full_observation(true, step), Ok(full));
            assert_eq!(full_observation(false, step), Ok(true));
        }
        assert_eq!(
            full_observation(true, 100_000_001),
            Err("execution transition cap".into())
        );
        assert_eq!(full_observation(false, 100_000_001), Ok(true));
    }
    #[test]
    fn pre_run_outputs_are_distinct_and_exact_without_a_run() {
        assert_eq!(pre_run(&CheckFailure::Refused(Diagnostic {class:"syntax".into(),span:Span::Text {start:(1,11),end:(1,12)}})),
            b"{\"status\":\"refused\",\"class\":\"syntax\",\"span\":{\"start\":[1,11],\"end\":[1,12]}}\n");
        assert_eq!(
            pre_run(&CheckFailure::Failed {
                class: "resource-exhausted".into(),
                domain: Some(Resource::Number)
            }),
            b"{\"status\":\"failed\",\"class\":\"resource-exhausted\",\"step\":\"0\"}\n"
        );
        assert_eq!(
            pre_run(&CheckFailure::Refused(Diagnostic {
                class: "encoding".into(),
                span: Span::Bytes { start: 13, end: 14 }
            })),
            b"{\"status\":\"refused\",\"class\":\"encoding\",\"span\":{\"bytes\":[13,14]}}\n"
        );
        assert_eq!(
            invalid_fixture("dangling", "inputs/0"),
            b"{\"status\":\"invalid-fixture\",\"class\":\"dangling\",\"path\":\"inputs/0\"}\n"
        );
    }
}
