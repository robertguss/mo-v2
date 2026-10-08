//! Source-driven Stage A implementation. No host fixture or observer access.
mod execution;
mod frontend;
mod number;

use mo_acceptance_runtime::{
    Candidate, CheckFailure, CleanupFailure, Outcome, Resource, RuntimeCells, Value,
};
use std::sync::Arc;

pub struct StageA;
pub struct CheckedProgram(Arc<frontend::Program>);
pub struct Run(execution::Machine);

impl Candidate for StageA {
    type CheckedProgram = CheckedProgram;
    type Run = Run;

    fn check_source(
        source: &[u8],
        allocations: &RuntimeCells,
    ) -> Result<CheckedProgram, CheckFailure> {
        frontend::check(source, &mut |text, negative| {
            allocations
                .allocate(Resource::Number, || number::literal(text, negative))
                .map_err(|_| CheckFailure::Failed {
                    class: "resource-exhausted".into(),
                    domain: Some(Resource::Number),
                })
        })
        .map(|program| CheckedProgram(Arc::new(program)))
    }

    fn checked_dump(program: &CheckedProgram) -> Vec<u8> {
        program.0.dump()
    }
    fn source_spans(program: &CheckedProgram) -> Vec<u8> {
        program.0.spans()
    }
    fn begin(program: &CheckedProgram, inputs: Vec<(String, Value)>, cells: RuntimeCells) -> Run {
        Run(execution::Machine::begin(
            Arc::clone(&program.0),
            inputs,
            cells,
        ))
    }
    fn advance(run: &mut Run, budget: u64, committed: &mut dyn FnMut(&Run, &[u8])) -> Outcome {
        for _ in 0..budget {
            match run.0.step() {
                Some(record) => committed(run, &record),
                None => break,
            }
        }
        run.0.outcome()
    }
    fn snapshot(run: &Run) -> Vec<u8> {
        run.0.snapshot()
    }
    fn public_output(run: &Run) -> Vec<u8> {
        run.0.public_output()
    }
    fn destroy(run: &mut Run) -> Result<(), CleanupFailure> {
        run.0.destroy()
    }
}
