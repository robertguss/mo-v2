# Acceptance integration resumed under D154

D154 (acceptance-owned external-root and independently observed physical-memory
reporting) resolves the blocked field-ownership discrepancy. The blocked checkpoint
and original INTEGRATION.md remain historical. BUILDER_AMENDMENT_D154.md versions
the amended interface; no interpreter implementation is authorized in this thread.

Stop: deliver validated bounded acceptance integration for parent review before
freeze/dispatch, or stop on a substantive contract discrepancy. D155 (procedural
builder separation for Stage A) now resolves the isolation-policy choice. Actual
clean-file/context delivery and recorded-access verification remain parent-owned
dispatch obligations. Same-account retrieval remains technically available; no
hard-access restriction or security framework is claimed or required.

Effort: previous recorded interval 19:52:44Z–20:08:19Z, 935 contributor seconds.
Resumed first clock read 2026-10-07T20:57:55Z; initial live-register read before
that timestamp is unmeasured. Exclude the stopped interval. Earlier preparation
remains unknown. This interval includes code, builds, tests and reporting waits.

## Stage A small-case integration is ready for review, not frozen

The public dependency and host-only linked driver now compile and run together.
The driver exercises source-check results, same-store fixture install/rollback,
callbacks, full-state/native readback, resume, destruction twice, pre-run formatting,
cell/Number/Frame denial evidence, phase-separated counters and inclusive timing.
The implementation under test is a canned interface fixture, NOT a Mo interpreter.
No source-driven candidate has run, and no scientific acceptance is claimed.

`BUILDER_HANDOFF.md` is the sanitized delivery index. Its allowlist has four
requirements documents and four runtime crate files, plus DELIVERY.sha256.
`BUILDER_EXECUTION.md` makes the existing transition/ownership reporting schedule
explicit rather than requiring a builder to retrieve acceptance code. The exact
v12 brief/protocol/index and every fixed prediction remain unchanged. Original
v12 omission of `givenUp` is documented, not copied into revised expectations.

Acceptance owns actual external-root order and reads actual native memory under
D154 (external-root/physical-memory field ownership). `integration.Observation`
normalizes those readings together with candidate execution state through one
run-wide identity mapping. It never substitutes predicted cells for observations.
Birth source/invocation, call site/result, failure abort order, physical lifetimes,
outside contents/counts, cleanup free sets and public bytes are checked separately.

## Executed validation and precise evidence

Run from experiments/13-source-acceptance with Python 3 and Rust/Cargo 1.98.1.
Use ordinary Python, not `python -O` (the checks intentionally use assertions).

| Check | Decisive result | Retained evidence |
| --- | --- | --- |
| `cargo test --locked --manifest-path cells/Cargo.toml` | 13 passed, including all seven original storage tests | evidence/integration-02/storage-final.txt |
| `cargo test --locked --manifest-path driver/Cargo.toml` | 2 passed: exact four-way pre-run formatting; periodic observation and 100-million cap boundaries | evidence/integration-02/driver-final.txt |
| `python3 integrationcheck.py evidence/integration-05 /home/user/rob-1333-private-v11` after building fixture_stub into /tmp/rob1333integration | 23 successful native stub runs; 49 rejected controls; 545 unchanged reference traces/outcomes; large-schedule three-step fixture passed | evidence/integration-05/summary.json and individual raw JSONL/summary/stderr files |
| `python3 corpus_tracecheck.py evidence/integration-regression-corpus_tracecheck` | 4,276 cases, 27,721 historical snapshots, 53,796 committed reference transitions | evidence/integration-regression-corpus_tracecheck/summary.json |
| Unchanged wirecheck / bridgecheck / faultcheck | 12 encoding + 9 output + 7 controls; 1 native bridge + 6 controls; 2 fault domains + 12 controls | evidence/integration-regression-{wirecheck,bridgecheck,faultcheck}/summary.json |
| Unchanged cleanupcheck / controlcheck / structurecheck | 1,603 synthetic cleanup boundaries + 4 controls; 3 worked control examples + 3 bounded prefixes; 6 structure examples | corresponding evidence/integration-regression-*/summary.json |
| Unchanged phasecheck / refusalcheck / decimalcheck / closeoutcheck | 24 phase cases; 24 refusals; 35 wide-decimal cases; 31 controls specified/163 record controls, both source/fixture routes | corresponding evidence/integration-regression-*/summary.json |

The 545 annotation regressions are the existing 21 public examples plus the fixed
524 private rows, not new case generation. No private source, seed or expected
output is included in the integration summary or delivery. Number/Frame attempt
sequences depend on a future candidate's actual implementation; only denial and
unchanged-prefix obligations are fixed. The canned native fixture performs real
gated buffers/reads and physical cleanup, but has only three supplied states.

The 49 controls comprise four compiled STUB controls, 26 required-array type
controls, call/birth/abort/duplicate-key controls, physical/state/cursor/clock
corruptions and an actual watchdog interruption of an owned sleeping process.
They are not the 31 future compiled evaluator controls. Storage replacement is
separately rejected by the original native storage test. The large-schedule test
does not run 10,000 or 100 million transitions: the boundary unit test supplies
counter values to the scheduling predicate and the callback fixture runs three.

## Repairs and failures retained, not erased

- The original outside-root counterexample and blocked checkpoint remain in
  INTEGRATION.md and evidence/integration-01, plus their separately retained archive.
- Cell create denial previously had no incremental attempt record. Added an
  acceptance-only cursor/log, without changing managed events, fixture counts,
  public runtime signatures or predictions. Native denial leaves graph, pointers,
  next lifetime and committed primitive prefix unchanged.
- Parent review found ignored frontend Number denial could be hidden by a later
  invalid fixture. Confirmed with a real broken stub: the old verifier accepted
  invalid-fixture after ignored denial. It now requires a typed failed step-zero
  outcome before fixture handling. The correct and broken twins distinguish this.
- Parent review found empty objects/strings could pass required-array fields and
  normalize to empty lists. Confirmed the old schema accepted the witness. Required
  arrays/nested rows now receive explicit type checks before normalization. All
  26 object/string controls reject without modifying correct expected outcomes.

Pre-repair source, accepted wrong-output evidence and schema witness are retained
in evidence/integration-review-defects. Earlier passing integration-03/04 captures
remain, with their older schema; they are not represented as checks of final code.

## Remaining gates — distinguish implementation work from an unrun check

1. Parent review of this exact integrated source, supplemental public requirements,
   fingerprints and evidence, then the conditional scientific freeze. This handoff
   inventory is NOT an accepted scientific lock. No dispatch has occurred.
2. Actual fresh builder files/context plus prohibited-retrieval instructions and
   recorded tool-use review under D155 (procedural Stage A separation). Compiling
   the clean allowlisted dependency and rejecting forbidden API imports verifies
   the package/API surface only; it does not prove technical tool inaccessibility.
3. A future candidate must supply its exported Candidate implementation. Acceptance
   then links the generic driver to that type, inspects complete allocation/read
   routing and source independence, runs original-source historical comparisons,
   every required real small-case resume/destroy/failure cut, and compiles/runs the
   deliberate evaluator controls. These are genuinely candidate-dependent, unrun.
4. Stage B remains separately gated after Stage A review. Full call/recursion
   native execution, protected caller arguments and actual aborts have not run;
   only reference predictions, metadata/normalization checks and interface stubs
   have run here. This author will never implement the candidate.
5. **The end-to-end large streaming adapter is NOT implemented.** `linked.run_linked`
   explicitly sends `large=false`; `integration.Verifier` stores/checks complete
   small traces. The Rust collector has incremental event cursors and periodic
   snapshots, and its schedule/cap are tested, but connecting a bounded-memory
   large-workload verifier and workload-specific result/memory/frame measurements
   remains acceptance preparation before any later authorized resource run. This
   is an unfinished executable gate, not merely an unrun candidate check. No claim
   of resource readiness, million-depth success or scalable reference execution.

The implemented watchdog starts before process launch and includes request/setup,
source/fixture checks, acknowledgement/verification waits, every observed advance,
two destroys, native readback/outside checks, host teardown, process exit and final
verification. Offline predictions and compilation are before the clock. Internal
queued cleanup remains execution transitions; destroy/teardown events are labeled
separately inside that same timer. An 8 MiB child stack and actual available memory
are recorded, with per-child peak RSS from wait4. The 4 GiB provisioning floor must
be rechecked/enforced in the future large-workload adapter; it is not a ceiling or
a guard currently applied to small stub runs. No resource workloads were run.

All work remains local/uncommitted on acceptance/rob-1333-preparation. HEAD and
origin/main remain at the original baseline; no parent changes were imported.
No lock, Mo implementation, Stage B/resource execution, Fable, push, merge,
deployment, extra agent/framework or archival occurred.
