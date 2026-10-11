# ROB-1323: Live-update milestone: model and test a two-version queue transition

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/issue/ROB-1323/live-update-milestone-model-and-test-a-two-version-queue-transition
> Status at export: Done
> Created: 2026-10-06
> Updated: 2026-10-07
> Completed: 2026-10-06
> Comments: 0

---

## Description

## Reconciled current status — 7 October 2026

Merged and Done. The concurrent-update recommendation below was subsequently authorized and delivered as [ROB-1326](https://linear.app/robert-guss/issue/ROB-1326/repeated-live-updates-under-concurrent-work-and-independent-deadlines). Original result/merge-time statements remain historical; they do not describe today’s queue or authorize further work.

Earlier records follow, preserved as history.

## Merged and verified

6 October 2026: Robert explicitly instructed “Merge it” in this conversation. Fast-forwarded main from e6a895c8ce2887d9bee6986819a779f8f74b5541 to 3253cf27062b36a76e186c6ead24182275e71ee8, pushed origin/main, and fetched to verify the exact remote tip. The reviewed artifact manifest and acceptance lock still match; the worktree is clean. No source or criteria changed during merge, so the retained acceptance results were not rerun. No deployment or next experiment was started.

## Result

A stdlib Rust queue migrates live state from a deque to an ordered map, preserving accepted jobs, FIFO and actual payloads. It refuses incomplete/corrupt/expired updates and retains the same client connection. Both versions are compiled in; native machine-code loading is not tested.

* TLC completed all 1,170 finite states, safety and termination under weak fairness of budget ticks.
* The entire model state set and all 3,955 labeled changing edges match the independently authored contract.
* Rust matched 22,230 state/command cases (19 commands from every reachable contract state), with 230,510 responses including replay setup.
* One TCP connection remained usable across 1,800 compared commands and 25 repetitions, with clean EOF exit.
* All five deliberately broken Rust implementations compiled and were rejected for wrong behavior: lost work, duplicate completion, premature activation, corrupt activation, expired activation.
* Two corresponding TLA+ safety mutants produced counterexamples. Removing fair budget ticks also produced a termination counterexample.
* All five original acceptance/spec/config hashes are unchanged. First acceptance failed on collapsed enqueue action labels; builder corrected only model labels, then full acceptance passed. Both attempts retained.

Local measurements: median command round trip 0.286 ms; median observed begin-to-activation 1.822 ms. These include harness/socket overhead and concurrent mutation builds, and are not runtime-only benchmarks or timing guarantees.

## Scope and evidence

[Plain-English result, interpretation and reproduction](<https://github.com/robertguss/mo-v2/blob/3253cf27062b36a76e186c6ead24182275e71ee8/experiments/04-live-update/RESULT.md>). [Raw logs, graphs, mutations and manifest](<https://github.com/robertguss/mo-v2/tree/3253cf27062b36a76e186c6ead24182275e71ee8/experiments/04-live-update/evidence>). [Frozen contract/check commit](<https://github.com/robertguss/mo-v2/commit/3d65740b2c67bab109afe9b017ebf7a44dd94741>).

Three IDs, capacity two, one update attempt, three logical ticks, one explicit-command event loop. Runtime checks replay a shortest path to every observable state; no formal refinement proof or exhaustive hidden-history claim. No multi-client/concurrent execution, autonomous real-time timer, repeated updates, process-crash durability, external effects, native loader or production rollout. Prior Lean/full3c locks unchanged.

The next recommendation is repeated updates under concurrent work with an independently progressing timeout and measured admission pauses. It is recorded as a recommendation, not a newly approved execution queue.

## Authorization and authorship

Robert: “Capture all of this in linear and then proceed with your recommended next milestone”. Then: “Yes—one local builder, separate checks”. Root fixed and hashed the contract/checks before the local builder implemented TLA+ and Rust. Both shared task context; this is separate authorship, not independent research teams. Retired Amp/Herdr workflow remains retired. Baseline `e6a895c8ce2887d9bee6986819a779f8f74b5541` was current with remote main before work. Merge authorized by Robert’s “Merge it” on 6 October 2026 and completed as recorded above.
