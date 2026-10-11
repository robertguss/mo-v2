# ROB-1326: Repeated live updates under concurrent work and independent deadlines

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/issue/ROB-1326/repeated-live-updates-under-concurrent-work-and-independent-deadlines
> Status at export: Done
> Created: 2026-10-06
> Updated: 2026-10-07
> Completed: 2026-10-06
> Comments: 0

---

## Description

## Reconciled current status — 7 October 2026

Merged and Done. Native loading was subsequently authorized and delivered as [ROB-1327](https://linear.app/robert-guss/issue/ROB-1327/load-newly-compiled-queue-code-and-retire-old-native-modules-safely). Statements below that the next milestone was unstarted describe this experiment’s original completion boundary, not current project status.

Earlier records follow, preserved as history.

## Merged and verified

6 October 2026: Robert explicitly instructed “merge it”. Merged reviewed experiment commit 568c432e63e6ca65b63fbd008b71126f8cebb7a5 into current main 29a3f004de21a2b58551ef6f2334a091cc64df4b, producing [515d63e](<https://github.com/robertguss/mo-v2/commit/515d63e90e1bf5a87bbf7489f99dc511b443b274>). Pushed and fetched to verify origin/main at that exact merge commit. The reviewed experiment tree, artifact manifest and acceptance lock are unchanged. The independent workflow-document update and identical local CLAUDE.md edit were preserved. Worktree is clean; no new tests were needed for this content-preserving merge. No deployment or next experiment ran.

[Plain-English result and reproduction](<https://github.com/robertguss/mo-v2/blob/568c432e63e6ca65b63fbd008b71126f8cebb7a5/experiments/05-concurrent-updates/RESULT.md>). [Retained attempts, raw traces, controls and manifest](<https://github.com/robertguss/mo-v2/tree/568c432e63e6ca65b63fbd008b71126f8cebb7a5/experiments/05-concurrent-updates/evidence>).

## Results

* All three required concurrent trials passed: four producer connections × 40 jobs, eight successful updates per trial — 480 jobs and 24 updates total. Receipt/FIFO/payload checks and update/completion overlap passed.
* Held migration timed out autonomously at 200.918 ms, while clients were silent. Its timeout was already 911.285 ms old when observed, and migration had not returned. A newer update succeeded; the stale worker's later result was discarded.
* Held old work timed out at 201.473 ms without losing the active job; release completed the work and a later update succeeded.
* Repeated swaps, deduplication/conflict handling, and refusal of both nonempty and empty corrupt candidates passed.
* Complete 17-state/20-edge TLA+ authority model matches the separately authored oracle. Safety and fair-timeout termination pass.
* All five deliberately wrong runtime source variants compiled and were rejected: disabled watchdog, stale publication, duplicate completion, lost work and accepted corruption. The stale-return model mutant produced an invariant counterexample. Failed-control processes were all reaped gracefully.
* All five pre-implementation acceptance hashes and experiment 4's artifact manifest remain unchanged.

## Defect and measurement limits

First acceptance exposed early TCP closure on macOS. A retained probe reproduced inherited nonblocking accepted sockets. Builder explicitly configured connection mode and bounded reads; second full acceptance passed unchanged checks. First source, failure, cleanup and repair diff are retained.

Runtime injects 5 ms work and at least 20 ms migration delays. Required-trial request medians: 0.240–0.263 ms; p95: 0.978–1.109 ms; maxima: 15.934–21.922 ms. Busy replies show backpressure; connection continuity does not mean uninterrupted admission.

The frozen controller's 769–799 ms observed completion gaps included a sampling stop while awaiting producers and cannot be interpreted as outages. One supplementary continuous-observer run passed another 160 jobs/eight updates. Its largest sampling interval was 31.992 ms and observed progress interval 43.052 ms; observer overhead and coarse sampling prevent exact outage/SLA claims. Kept separately from the three acceptance trials.

## Scope and next question

One execution worker, four concurrent producers, capacity eight, maximum 256 jobs and 32 attempts, 200 ms deadline with fixed 750 ms host tolerance. Both representations compiled in. Model covers authority tokens only; runtime schedules are observed, not exhaustively proven. No native loading, arbitrary migration preemption, crash/database/external-effect recovery or production assurance.

Next proposed question is loading newly compiled code and retiring old-code references while preserving this protocol. It has not been started. No unrelated parked experiment is authorized.

## Authorization and delivery

Robert: “Continue with the next experiment” (D115, the concurrent-update continuation). Existing one-local-builder/separate-lead-checks arrangement retained. Root froze and committed checks at d75f992 before builder implementation. Dedicated branch based on merged commit 3253cf2. Only experiments/05-concurrent-updates was committed; a concurrent unrelated CLAUDE.md edit was left untouched.
