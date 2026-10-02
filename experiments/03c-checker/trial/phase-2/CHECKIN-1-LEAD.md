# Check-in 1: Lead's independent findings

Recorded before reading the Tester's findings, 2 Oct 2026, approximately
04:41 UTC. This is partial-work verification, not completed-proof acceptance.

Candidate: [8c57ccb](https://github.com/robertguss/mo-v2/commit/8c57ccbd4f41dea91f2cda903d9377362f37270a).
Baseline: [787e042](https://github.com/robertguss/mo-v2/commit/787e0427244837fd0f44b76c4a648d07938c3bcc).
Remote branch tip matched the candidate before checking.

## Result in plain English

- Proven promises: none.
- Unfinished: finishing, same answer, no visible changes, no leaks.
- Counterexamples: none reported by Builder; these checks found none. This is
  not an exhaustive search and not evidence that no counterexample exists.
- All four accepted theorems still depend on `sorryAx`: Lean's marker for an
  unfinished proof. A successful build therefore does not prove them.

## Independently executed checks

1. All 25 effective frozen fingerprints match, taking the final table entry
   for each path. `LOCK.md` itself is unchanged from the baseline.
2. Complete baseline-to-candidate diff contains 30 allowed proof paths only.
   The Lead's only untracked path at inspection was the pre-existing,
   Lead-owned `phase-2/CLOCK.md`; it is not a Builder change. A fresh baseline
   archive plus only candidate `Proofs.lean` and `Proofs/` was reconstructed in
   `/tmp/mo-checkin-1-lead`, with no inherited build files.
3. Source inspection and forbidden-construct search found only the four
   original unfinished theorem bodies. Helper declarations use `Trial.Proofs`;
   simp attributes apply to own lemmas, not locked definitions. No parsing,
   kernel, dependency, statement-shadowing or check-meaning change found.
   The local helper conclusions remain conditional on their hypotheses;
   notably `final_no_leak` does not establish whole-evaluator invariants.
4. In the reconstructed `trial/lean`, from no `.lake` directory:
   `lake build Trial Checks Promises Proofs Acceptance` completed successfully,
   48 jobs. Exactly four original `sorry` warnings, no errors.
5. The unchanged `Acceptance.lean` compiled. Printed accepted theorem types
   are precisely `Trial.PromiseA`, `Trial.PromiseB`, `Trial.PromiseC`,
   `Trial.PromiseD`; printed definitions retain universal valid-start
   quantification and `runCounted Rule.approved`.
6. All four accepted theorem axiom lists are `[propext, sorryAx]`. None counts
   as proven. Builder's separate count of 200 helper theorem axiom checks is
   Builder-reported, not independently reproduced as a separate count here.
7. `lake env leanchecker --fresh Acceptance` exited 0. This rechecks the
   compiled terms but does not remove the explicitly reported unfinished
   assumptions.
8. `lake env lean --run Checks/Run.lean` matched `results/run-1.txt` byte for
   byte (`diff -u` exit 0). Approved-rule, control and total mismatch counts
   were each 0.
9. Checks 9–10 were not run: those broken-copy controls remain reserved for
   after completed proof.

Raw Lead output was recorded under `/tmp/mo-checkin-1-raw` before the Tester's
findings were read: integrity, source scan, build, printed types, examples.
These outputs are preserved beside this report when committed.

This checkpoint is suitable to retain as unfinished work. It does not pass
finished-work acceptance and does not justify starting a dependent scientific
stage. The remaining work is to establish the whole-evaluator invariants and
use them to prove the four locked statements.
