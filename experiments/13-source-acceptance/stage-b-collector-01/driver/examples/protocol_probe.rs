//! Synthetic collector-protocol probe, NOT a Mo evaluator or native acceptance control.
use mo_acceptance_driver::{Approval, Request, collect};
use mo_acceptance_runtime::{
    Candidate, CheckFailure, CleanupFailure, Observation, Outcome, RuntimeCells, Status, Value,
};
use serde_json::{Value as Json, json};
use std::cell::Cell;
use std::io::{BufRead, Write};

struct Scripted;
struct Run {
    specification: Json,
    observation: Cell<usize>,
    advance: usize,
}

fn bytes(value: &Json) -> Vec<u8> {
    match value {
        Json::String(s) => s.as_bytes().to_vec(),
        Json::Array(a) => a
            .iter()
            .map(|b| u8::try_from(b.as_u64().unwrap()).unwrap())
            .collect(),
        _ => panic!("probe input must supply raw bytes"),
    }
}

impl Candidate for Scripted {
    type CheckedProgram = Json;
    type Run = Run;
    fn check_source(source: &[u8], _: &RuntimeCells) -> Result<Json, CheckFailure> {
        Ok(serde_json::from_slice(source).unwrap())
    }
    fn checked_dump(_: &Json) -> Vec<u8> {
        b"{}".to_vec()
    }
    fn source_spans(_: &Json) -> Vec<u8> {
        b"{}".to_vec()
    }
    fn begin(program: &Json, _: Vec<(String, Value)>, _: RuntimeCells) -> Run {
        Run {
            specification: program.clone(),
            observation: Cell::new(0),
            advance: 0,
        }
    }
    fn advance(run: &mut Run, _: u64, callback: &mut dyn FnMut(&Run, &[u8])) -> Outcome {
        let entry = &run.specification["advances"][run.advance];
        if let Some(callbacks) = entry["callbacks"].as_array() {
            for metadata in callbacks {
                callback(run, &bytes(metadata));
            }
        }
        let status = match entry["status"].as_str().unwrap_or("suspended") {
            "suspended" => Status::Suspended,
            "finished" => Status::Finished,
            "failed" => Status::Failed,
            _ => panic!("unknown probe status"),
        };
        let committed_steps = entry["step"].as_u64().unwrap_or(0);
        run.advance += 1;
        Outcome {
            status,
            committed_steps,
        }
    }
    fn snapshot(run: &Run) -> Vec<u8> {
        let snapshots = run.specification["snapshots"].as_array().unwrap();
        let index = run.observation.get();
        run.observation.set(index + 1);
        bytes(&snapshots[index.min(snapshots.len() - 1)])
    }
    fn observe(run: &Run, _: Observation) -> Vec<u8> {
        Self::snapshot(run)
    }
    fn public_output(_: &Run) -> Vec<u8> {
        Vec::new()
    }
    fn destroy(_: &mut Run) -> Result<(), CleanupFailure> {
        Ok(())
    }
}

fn probe(specification: Json) -> Json {
    let budgets = specification["budgets"]
        .as_array()
        .map(|a| a.iter().map(|n| n.as_u64().unwrap()).collect())
        .unwrap_or(vec![0]);
    let request = Request {
        source: serde_json::to_vec(&specification).unwrap(),
        cells: vec![],
        inputs: vec![],
        outside: vec![],
        budgets,
        large: specification["large"].as_bool().unwrap_or(false),
        deny_cell: None,
        deny_resource: None,
    };
    let mut rows = Vec::new();
    let outcome = collect::<Scripted>(
        request,
        &mut |_, _| Ok(Approval::Install),
        &mut |mut row| {
            row.as_object_mut().unwrap().remove("elapsed_ns");
            rows.push(row);
            Ok(())
        },
    );
    json!({"error":outcome.err(),"rows":rows})
}

fn main() {
    let mut stdout = std::io::stdout().lock();
    for line in std::io::stdin().lock().lines() {
        let result = probe(serde_json::from_str(&line.unwrap()).unwrap());
        writeln!(stdout, "{result}").unwrap();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn boundary_validation_and_semantic_equality_remain_strict() {
        let base = r#"{"step":0,"status":"suspended","x":{"a":1,"b":["A",0.0]}}"#;
        // Equal despite key order, whitespace, escaped strings and signed float zero.
        let reordered = r#"{ "x":{"b":["\u0041",-0.0],"a":1},"status":"suspended","step":0}"#;
        let result = probe(json!({"snapshots":[base,reordered]}));
        assert!(result["error"].is_null());
        assert_eq!(result["rows"][3]["raw"]["snapshot"], reordered);
        let changed = base.replace("[\"A\",0.0]", "[\"A\",0]");
        assert_eq!(
            probe(json!({"snapshots":[base,changed]}))["error"],
            "zero-work/terminal state changed"
        );
        for invalid in [
            "1e400".to_string(),
            r#""\uD800""#.to_string(),
            format!("{}0{}", "[".repeat(128), "]".repeat(128)),
        ] {
            let raw = format!(r#"{{"step":0,"status":"suspended","unused":{invalid}}}"#);
            let result = probe(json!({"snapshots":[raw]}));
            assert!(result["error"].is_string());
            assert_eq!(result["rows"].as_array().unwrap().len(), 2);
        }
        assert_eq!(probe(json!({"snapshots":[base,base]}))["error"], Json::Null);
    }
}
