# Copy-feedback pilot preparation — ROB-1141

Preparation only. Robert's “do it” follows the recommendation to prepare six
concrete tasks, exact checks/feedback, and deliberately wrong repairs for review
before 30 GPT-6.1 Sol sessions. No participant sessions, merge or deployment.
Use Codex subscription access, gpt-6.1-sol, medium reasoning for later trials.
The proposed five-minute per-session cap requires approval with this package.

Use the unchanged accepted 3b helper's List API. Each task exports exactly:
`pub fn run(input: helper::List) -> (helper::List, Option<helper::List>)`.
Only task.rs is editable by a participant; helper, checker and driver are fixed.
Inputs contain arbitrary bounded signed integers. Every task must work beyond
one visible example; no size-specific behavior, global state, unsafe code, I/O,
process/thread creation, dependencies, source introspection or measurement bypass.
This is bounded research on cooperative coding agents, not a hostile-code sandbox.

Six task contracts:

| ID | Operation | Retain old version? | Profile input size | Goal |
|---|---|---|---:|---|
| U1 | add one to every value | no: return None | 100000 | remove avoidable copying |
| U2 | reverse list | no: return None | 100000 | remove avoidable copying |
| R1 | add one to every value | yes: return Some(original) | 100000 | preserve required old version |
| R2 | running total, Rust signed remainder modulo 1000003 | yes: return Some(original) | 100000 | preserve required old version |
| H1 | add one to every value | yes: return Some(original) | 4 | leave harmless copying alone |
| H2 | reverse list | yes: return Some(original) | 8 | leave harmless copying alone |

Input construction occurs before the measured operation; every execution of task
code is inside the measured operation. Verification and output formatting follow
measurement. Measure allocation calls, cumulative requested bytes, live/peak
requested bytes separately from uninstrumented release timing. Profile fixed
inputs values (i modulo 17)-8; correctness also covers empty, singleton, negative,
repeated and longer non-profile inputs. No overflow at these bounded test sizes.
Report elapsed time descriptively; do not use noisy timings as correctness gates.
Unique tasks' successful repair must allocate zero bytes/calls during task run;
retained/harmless tasks must preserve both full value sequences and may allocate
at most one list cell per input element (derive layout from the pinned helper).
An unchanged correct retained/harmless task is a successful preservation outcome;
report any edits separately, do not equate every edit with a regression.

Baseline U tasks deliberately retain an unnecessary cloned holder during the
update; correct repair drops it before the update. Other baselines are already
correct and within their task budgets. Do not tell participants these categories
or distribute reference repairs. Participant prompts state requirements/scale.

Acceptance author owns acceptance/ only, writes and freezes the reference contract
and checks before task implementation. Driver/task author may not amend expected
results. Separate authorship is the current pilot proposal's requirement. Check
unchanged helper identity. Controls: discarded required version; shared mutation;
weakened check; copying outside a reported inner interval. Catch semantic failures
on full values, not just checksum/process exit, and integrity failures explicitly.
A control build failure is not a successful semantic catch. Preserve failures.

Stop preparation when baseline behaviors, legal unique-task repairs and four
negative controls have independently verified outcomes and all six tasks/feedback
messages plus run protocol are fingerprinted for Robert's review. A fingerprint
is a proposed-package freeze, not owner approval or permission to run the pilot.
