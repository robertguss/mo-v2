# Trial result: all four locked promises proved

2 October 2026. The Lead and a fresh Tester each passed all ten locked
acceptance checks on [the same proof candidate](https://github.com/robertguss/mo-v2/commit/baf1d52649bc7a50ff7df19d0368d182efdb3fbd),
recording their findings before seeing the other's. Oracle reviewed the proof
changes and found no blocking issue. **Four promises proven, none unfinished.**
No counterexample to the approved rule was found.

This is technical acceptance of the finite trial language, not full Mo or
full Experiment 3c. The proof and evidence are committed on dedicated branches;
merge and any next scientific stage remain separate delivery/authorization
steps. Linear holds live status, not this result snapshot.

## What was proved

For every well-formed trial program and every valid starting memory—including
shared lists—the locked approved counted rule satisfies:

| Promise | Plain-English result |
| --- | --- |
| Finishes | Execution reaches an answer that can be read from memory. |
| Same answer | The answer equals execution with ordinary lists, without memory bookkeeping. |
| No visible changes | Outside holders and still-holding names retain their list values at every recorded snapshot. |
| No leaks | Final memory contains exactly the cells reachable from the answer and outside holders, with correct counts, no duplicate addresses, reserved cells, missing links or cycles. |

These are universal Lean proofs, not a claim inferred from passing examples.
One structural induction establishes the complete evaluator contract;
initialization and finalization connect it to the four exact locked statements.
The Lead and Tester did not write the proofs or change the acceptance checks.

## What the independent checks showed

Both workers reconstructed the amended baseline plus only the permitted proof
files, and separately checked the entire candidate diff and worktree.

- All **25 effective frozen fingerprints** match. Only **59 permitted proof
  paths** changed; no scientific specification or check changed.
- From an empty build cache, `lake build Trial Checks Promises Proofs Acceptance`
  completed **77 jobs, exit 0, no warnings or errors**, on pinned Lean 4.34.0.
- Exact accepted theorem types matched. Every accepted axiom list was precisely
  `[propext, Classical.choice, Quot.sound]`: standard Lean axioms, no unfinished
  proof marker or extra assumption.
- `lake env leanchecker --fresh Acceptance` exited 0 independently in both orbs.
- All 28 frozen example runs and the existing misreport control produced a
  byte-identical report to `results/run-1.txt`: zero mismatches.

Each worker then executed valid-start counterexamples to the unsafe copies,
and independently replaced just the approved choice of rule in disposable
copies. They used different concrete examples with the same conclusion:

| Deliberately broken rule | Observable failure | Required acceptance result |
| --- | --- | --- |
| Reuse a shared cell | A still-held list changes or becomes unreadable: visibility fails. | Exact promise evaluates false; clean proof build fails. |
| Forget the rest of a freed list | A tail cell remains allocated without a reachable holder: no-leak fails. | Exact promise evaluates false; clean proof build fails. |
| Free a held cell | An outside pointer refers to freed storage: visibility fails. | Exact promise evaluates false; clean proof build fails. |
| Never reuse | Correct answers but wrong frozen allocation/reuse/free totals and timing. | Frozen report records 69 mismatches: 54 totals and 15 timing. |

The three unsafe builds failed at the public-rule/runner connection. A failed
build alone would not establish unsafe behavior; the separately evaluated
false promises do. The never-reuse runner exits 0 even with mismatches, so both
workers checked its report rather than mistaking the exit status for success.

## What remains unproved

- The theorem is about the frozen Lean encoding. Agreement with the approved
  English rule is supported by independently predicted examples, not a proof
  of English/formal correspondence for every program.
- Visibility covers the recorded snapshots and the specified outside/holding
  names. Snapshot placement and liveness coverage retain the locked
  code-reading limitations. Temporary-only values are not a separate part of
  that visibility promise; the final answer is covered by the answer promise.
- The no-leak promise concerns final memory, not every intermediate bookkeeping
  structure. Lean's kernel, pinned toolchain and standard axioms remain trusted.
- No calls, recursion, nontermination, in-place demand checker, performance,
  Rust-helper correctness or universally optimal reuse has been established.

## Evidence and elapsed time

- [Builder](https://ampcode.com/threads/T-01a0fa71-4bff-779d-9439-83059a968a65),
  [Lead](https://ampcode.com/threads/T-01a0f9e2-cd4f-7408-a467-ecdb636cdeb7),
  [fresh final Tester](https://ampcode.com/threads/T-01a0fb79-1151-70bb-8f33-f47c48f26fbd).
- Amended baseline: [787e042](https://github.com/robertguss/mo-v2/commit/787e0427244837fd0f44b76c4a648d07938c3bcc).
- Original findings: `phase-2/final-lead/LEAD.md` and
  `phase-2/final-tester/ORIGINAL-FINDINGS.md`. Raw outputs, external control
  inputs, mutation diffs, diagnostics and hashes are retained alongside them.
- Original Builder report transcribed in `phase-2/checkin-3-builder-report.txt`;
  the thread remains the original source. Two unfinished checkpoint reports
  and separate checks are retained, not retroactively relabelled as proofs.
- Tester export SHA-256:
  `c0d3b14e9d3d6f8e369ce7f6ee359fa565d27ea39832db527dc98e3b10cc6338`.
- `phase-2/CLOCK.md`: 4h08m34s authorized elapsed proof work; 31 minutes between
  intervals for reporting/review. Setup/recovery and final verification are
  separate. This is not active-CPU time or a model-capability comparison.

The Grok47 readiness attempt did no proof work; Lead/Oracle selected the
high-mode fallback under Robert's AFK delegation. Operational amendments and
their replacement hashes preserve the original lock history and did not change
the four promises, ten checks or predictions. Oracle's review supplements the
two acceptance executions; agreement among models is not extra experimental
evidence. Any follow-on extension needs its own scope, acceptance and lock.
