# Testing Mo — tools, Rust implementation, and the first live-update milestone

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/document/testing-mo-tools-rust-implementation-and-the-first-live-update-98d9514ae3de
> Created: 2026-10-06
> Updated: 2026-10-06
> Author: Robert Guss
> Attached to: the Mo v2 project

---

# Testing Mo: a sequence of falsifiable experiments

Recorded 5 October 2026. Robert requested: “Capture all of this in linear and then proceed with your recommended next milestone”. This authorizes the bounded first live-update milestone below. Later experiments are recommendations, not an approved execution queue.

## Tool roles and implementation recommendation

* **Lean:** retain selected foundational proofs, including the existing memory/reuse work. A proved model is not automatically a verified implementation.
* **TLA+ with TLC:** explore ordering of requests, migration, activation, failures and retirement. Check safety and progress for explicitly finite configurations; disclose fairness and environmental assumptions. A finite model check is not a universal proof.
* **Rust:** recommended for the compiler and the executable runtime experiment, combining explicit data representations, resource control and useful tooling. Robert authorized proceeding with the Rust-based milestone; a permanent whole-compiler/backend choice remains evidence-led. Rust's own safety does not prove Mo semantics, optimizer correctness, migration safety or generated-code safety. Rust build latency and Mo compile latency are separate measures.
* **Reference execution:** begin with a small typed intermediate representation/interpreter when compiler work is selected. Keep syntax experiments separate from semantic changes.
* **Cranelift:** candidate for native JIT/AOT compilation; evaluate against workload needs before choosing it or LLVM. Neither supplies Mo's update protocol.
* **Quint:** possible alternative specification notation; compare on the same tiny protocol if direct TLA+ becomes an obstacle. Do not maintain two specification languages without a concrete benefit.
* **Proptest:** generated structured cases and shrinking.
* **cargo-fuzz:** parsers, decoding, compiler passes and migration input robustness.
* **Loom:** small Rust synchronization components once real multithreading is introduced, using its instrumented primitives.
* **Kani:** selected Rust helpers and assertions within supported-feature/harness limits; not a whole-runtime concurrency verifier.
* **Elixir/OTP reference:** useful later comparator for the same tiny update service; no superiority claim or compulsory ecosystem bakeoff.

Use tools when a particular question needs them; do not install/build the whole list as infrastructure.

## Proposed experiment sequence

1. **Live-update protocol and implementation (authorized next milestone).** One service, two versions, one state-representation migration and deliberately injected failures. Model first, then implement and challenge observable behavior.
2. **Agent feedback.** Fixed tasks/model conditions, independently checked behavioral outcomes; compare diagnostics, repair attempts, regressions, resource constraints, elapsed time and context. Include tempting incorrect repairs such as weakening a requirement or adding an expensive copy. These are measurements of correct work, not token-only language rankings.
3. **Syntax.** Different syntax over the same semantics and tasks; test rather than assume familiarity or compactness helps.
4. **Memory through composition.** Continue calls/recursion proposals under their own scope; distinguish rule correctness, implementation correspondence and measured cost. The existing full3c locks and approval state are unchanged.

Regeneration/recipes and later ecosystem work remain on the broader research agenda.

## First milestone: continuous queue service, two representations

**Question:** can an in-process service change its state representation at a controlled boundary while preserving accepted work, version consistency and a connected client, and reject unsafe or incomplete transitions?

**Initial implementation boundary:** two version implementations compiled into one Rust executable. Actual dynamic machine-code loading, whole-process/power-loss recovery, distributed upgrades, database migrations and production deployment are excluded. The point is to establish transition semantics before a native loader. The model's logical ticks are not a proof of wall-clock availability.

**Observable obligations:** acknowledged work stays accounted for; no duplicated completion; one authoritative version at a time; no migration while an operation uses the old state; unsuccessful preparation/migration leaves the old state usable; finite update budget produces activation or explicit refusal under stated fairness; bounded admission during pauses; a client connection remains usable across the transition.

**Method:** freeze a small protocol/acceptance specification before implementation; TLC checks finite models and planted protocol errors; a Rust prototype is driven by independently prepared operation traces and failure cases. Compare model and implementation observable transitions, and measure actual pauses/resource behavior separately where feasible.

**Controls:** lost accepted work, duplicate completion, premature activation while work is in flight, accepting a corrupt migration, and reporting success after budget exhaustion must be distinguishable from passing behavior. Expected outputs cannot be retuned to fit the implementation.

**Stop condition:** report model outcomes, executed implementation checks, caught/uncaught controls, correspondence limits and measurements. Stop rather than weaken an obligation to obtain a pass. Retain counterexamples. No claim of universal safety, production readiness or complete hot reload follows from this milestone.

**Execution:** [ROB-1323](https://linear.app/robert-guss/issue/ROB-1323/live-update-milestone-model-and-test-a-two-version-queue-transition) is the current milestone. Robert approved “Yes—one local builder, separate checks”. The lead fixes the bounded protocol and acceptance before builder implementation. The retired Amp/Herdr workflow is not restored. Model and prototype findings will be reported with their limits before selecting a further milestone.

## References

[TLA+ tools](<https://lamport.azurewebsites.net/tla/tools.html>), [Lean reference](<https://lean-lang.org/doc/reference/latest/>), [Quint](<https://quint.sh/>), [Cranelift](<https://cranelift.dev/>), [Kani](<https://model-checking.github.io/kani/>), [Proptest](<https://proptest-rs.github.io/proptest/intro.html>), [cargo-fuzz](<https://rust-fuzz.github.io/book/cargo-fuzz.html>), [Loom](<https://github.com/tokio-rs/loom>).

Related: [agent-first direction and continuous delivery](<https://linear.app/robert-guss/document/mo-direction-agent-first-development-and-native-continuous-delivery-0766ce6f46cb>).

## First milestone result — 5 October 2026

[ROB-1323](https://linear.app/robert-guss/issue/ROB-1323/live-update-milestone-model-and-test-a-two-version-queue-transition) is **Done**, merged and pushed to main at `3253cf27062b36a76e186c6ead24182275e71ee8` on 6 October 2026 after Robert explicitly instructed “Merge it”. Remote main and unchanged acceptance artifacts were verified; no deployment occurred. [Commit-pinned report](<https://github.com/robertguss/mo-v2/blob/3253cf27062b36a76e186c6ead24182275e71ee8/experiments/04-live-update/RESULT.md>) and [retained evidence](<https://github.com/robertguss/mo-v2/tree/3253cf27062b36a76e186c6ead24182275e71ee8/experiments/04-live-update/evidence>).

The finite queue transition passed: TLC checked 1,170 states; all 3,955 labeled edges match the separate contract; Rust matched 22,230 state/command cases; a single TCP connection survived 1,800 compared commands. All five real Rust source mutations were rejected; two TLA+ safety mutations and removal of tick fairness produced counterexamples. Frozen checks unchanged. An initial model-label observability defect was repaired, with both attempts retained.

This supports the bounded transition protocol, not native hot code loading or production readiness. Both versions are compiled in, work is command-driven, only one update is allowed per reset, and logical time advances only when ticks are supplied. Runtime state replay is not a formal refinement proof. Actual payload/FIFO preservation and refusal behavior were checked. Local harness timings are reported without SLA claims.

The strongest next question is repeated upgrades under real concurrent work with an independent timeout. The fairness counterexample shows why progress cannot depend on the upgrading work continuing to cooperate. This is the next recommendation, not authorization to begin another milestone.

## Experiment 5 — concurrent updates, 6 October 2026

Robert subsequently authorized “Continue with the next experiment” (D115, concurrent-update continuation). [ROB-1326](https://linear.app/robert-guss/issue/ROB-1326/repeated-live-updates-under-concurrent-work-and-independent-deadlines) is now **Done**, merged and pushed to main at `515d63e90e1bf5a87bbf7489f99dc511b443b274` after Robert’s 6 October 2026 merge approval, with [commit-pinned results](<https://github.com/robertguss/mo-v2/blob/568c432e63e6ca65b63fbd008b71126f8cebb7a5/experiments/05-concurrent-updates/RESULT.md>) and [evidence](<https://github.com/robertguss/mo-v2/tree/568c432e63e6ca65b63fbd008b71126f8cebb7a5/experiments/05-concurrent-updates/evidence>). All three required load trials passed: 480 jobs and 24 updates with four producer connections per trial. An independent watchdog expired a held migration during client silence; a newer update succeeded before the stale result returned, and the stale result was discarded. Held old work and corrupt candidates were handled without losing acknowledged jobs. All five actual runtime mutants and the stale-return model mutant were rejected; the 17-state/20-edge model matched the independent oracle. Frozen checks and prior experiment artifacts unchanged.

A macOS accepted-socket defect was caught on the first attempt and repaired. Timing observations include simulated work/migration delays; a controller sampling gap was exposed and separately investigated with a continuous observer. No exact outage bound or production SLA is established. This supports the bounded concurrent transition mechanism, while newly compiled code loading, old-code lifetime, arbitrary migration preemption and crash/external effects remain untested. The next proposed question is actual code replacement; no further experiment execution is authorized. Experiment 5’s approved merge is complete.

## Experiment 6 — actual native loading and retirement, 6 October 2026

Robert authorized this next experiment, then permitted same-author implementation and verification (D117, native-loading execution; D118, self-verification here). [ROB-1327](https://linear.app/robert-guss/issue/ROB-1327) is In Review, pushed at a1c032fa7fa2b1061ce79f9fd13403061640bb5b. [Report](<https://github.com/robertguss/mo-v2/blob/a1c032fa7fa2b1061ce79f9fd13403061640bb5b/experiments/06-native-loading/RESULT.md>). Three final clean builds/processes completed 249 jobs. V2 was compiled after startup and loaded while clients remained connected and old native code was held in flight. Old admitted/queued work retained v1; new work used v2. Premature retirement refused; actual old-image removal and destructor execution observed once references ended. Six compiled source controls were caught. Original failed path check and all attempts retained.

This is a small trusted synchronous C ABI experiment on macOS, not the final Mo architecture or independent acceptance. The host-owned queue is stable here; representation migration and the prior watchdog are not integrated with native loading. Slow/stuck loader code can still block the state mutex. No arbitrary native-code safety, bounded loading deadline, crash recovery, external-effects guarantee or production readiness. Stop at branch review; no merge/deployment/next milestone authorized.

## Experiment 6 merge and experiment 7 result — 6 October 2026

Robert authorized “merge it and continue” (D119, native-loading merge and stalled-native continuation). Experiment 6 / ROB-1327 merged unchanged at a1c032f, remote main verified. [ROB-1328](https://linear.app/robert-guss/issue/ROB-1328) now Needs Input: original no-retry criterion failed because loading could exhaust the 200ms budget before native preparation entered. Safe refusal is retained as a failure to complete the required scenario; checks and deadline unchanged. Snapshot lock order was repaired with original evidence retained.

[Experiment 7 report](<https://github.com/robertguss/mo-v2/blob/78b3be720af76ad011557cd1b96b6b5c4861c727/experiments/07-stalled-native/RESULT.md>). Retry-assisted supplemental diagnostic passed three trials, 288 jobs, two types of native stall, independent timeout, newer activation, late-result refusal and real eventual unloading. Five source controls were caught against that diagnostic; it is not original acceptance. Branch 78b3be720af76ad011557cd1b96b6b5c4861c727 pushed, not merged. Same-author verification. Proposed next scope: separate staging/loading from timed preparation; no owner decision yet. No arbitrary native preemption or bounded OS-loader guarantee.

## Experiment 7 staged revision — approved and passed

Robert approved separating loading/staging from the preparation clock (D120). [ROB-1328](https://linear.app/robert-guss/issue/ROB-1328) is In Review at 3e8da6423a13386d81bb8e188fa2839ba4c03f88. [Report](<https://github.com/robertguss/mo-v2/blob/3e8da6423a13386d81bb8e188fa2839ba4c03f88/experiments/07-stalled-native/staged/RESULT.md>). Three no-retry trials completed 300 jobs with five persistent connections each, and six real source controls were caught. Deliberate staging longer than 400ms did not block old jobs; held/native-sleep preparation expired about 200–201ms after staging. New versions activated before stale native returns, which were discarded and safely unloaded afterward. Invalid staging did not arm a clock. Original failed experiment and hashes remain unchanged. Same-author verification; no merge/deployment. Staging remains unbounded, and forever-hung native code retains its resources.

## Experiment 7 merge — 6 October 2026

6 October 2026: Robert explicitly instructed “merge it”. Fast-forwarded main from a1c032fa7fa2b1061ce79f9fd13403061640bb5b to 3e8da6423a13386d81bb8e188fa2839ba4c03f88, pushed and fetched to verify remote main. Reviewed source and both original/staged evidence manifests unchanged. Original failed end-to-end result remains preserved alongside the approved passing staged revision. Same-author verification retained; no new tests needed for this content-preserving merge. Unrelated unstaged CLAUDE.md edit preserved. No deployment or next experiment authorized or started.

[ROB-1328](https://linear.app/robert-guss/issue/ROB-1328) is Done under D121 (approved staged-experiment merge).

## Experiment 8 — native code plus real queue-state migration

Robert approved “sounds good. do it” (D122, combined native/state experiment). [ROB-1329](https://linear.app/robert-guss/issue/ROB-1329) is In Review, pushed at 6de1d55f25a5451ef21b24afa6e8d92ee4dcc121. [Report](<https://github.com/robertguss/mo-v2/blob/6de1d55f25a5451ef21b24afa6e8d92ee4dcc121/experiments/08-native-migration/RESULT.md>). Actual native array queue becomes linked queue; host validates complete copied rows before atomic publication of queue and code. Three final trials preserve 291 jobs, old admission-code ownership, FIFO and two-step results across corrupt/stalled refusal and newer successful migration before stale return. Independent timeouts resume old dequeue before native return. All observed module unloads follow zero live queue objects, including shutdown. Six actual source controls caught; first broad stale mutant and all attempts retained. Same-author checks, no prior artifact changes, no merge/deployment. Trusted ABI and bounded queue only; no arbitrary preemption, external-effect/crash guarantee, general heap proof or bounded staging.

## Experiment 9 — retained migration resource limit, 6 October 2026

Experiment 9 passed at 87e3a9dc458f03de9c511511f8aa61f05a3d1be9 on `codex/native-migration-resource-limit`; pushed branch verified. [Report](<https://github.com/robertguss/mo-v2/blob/87e3a9dc458f03de9c511511f8aa61f05a3d1be9/experiments/09-migration-limit/RESULT.md>). Three no-retry trials: 270 jobs, 240 excess updates explicitly refused, five persistent clients each; external thread count 8 baseline / 10 with two permanent native hangs. Returning workers reclaimed capacity; timed-out workers retained it. No new attempt or candidate load at capacity. Native code remained pinned, old queue resumed and ordinary work continued; permanent timeout times 200.124–201.215ms after staging. Five compiled broken-source controls caught; initial overly broad unsafe-retire control failed too early and is retained, corrected control targeted executing ownership without changing acceptance. Unchanged experiment-8 trial passed another 97 regression jobs. Forced-failure cleanup killed/reaped hung process; no in-process reclamation claim. Same-author verification. Prior manifests unchanged; unrelated CLAUDE.md edit excluded. Resource cap is host updater count under trusted ABI, not arbitrary heap/native preemption or production SLA. No merge or deployment.

Practical outcome: two permanent stalls exhaust update capacity while serving ordinary work. Continued updating then requires process replacement; recovery/replacement is not implemented. This is the limit of this bounded experiment, not an automatic next milestone. Robert requested Needs Input discussion next.

## Experiment 10 — finite-model/Rust correspondence, 6 October 2026

The finite-model/Rust comparison passed at a22831f823d2ac7ccbb8726a8d4418fbceb233e0 on `codex/finite-rust-correspondence`, pushed and remote verified. [Report](<https://github.com/robertguss/mo-v2/blob/a22831f823d2ac7ccbb8726a8d4418fbceb233e0/experiments/10-finite-rust/RESULT.md>). All 4,276 cases (28 original + 4,248 generated), 27,721 snapshots and physical cell accounting matched; five compiled broken variants rejected. 304 evaluation cell creations, 89 in-place writes, 5,269 releases, with 9,617 initial fixture cells separately counted. Inputs/exporter/checks/expectations frozen at 77b208b before Rust implementation. Fresh disposable Lean rebuild reproduced expectations exactly; 270 original trial/helper file hashes unchanged. New code/checks are same-author verification, with unchanged independently authored historical model/predictions. Initial exporter setup error, Rust compile error and overly narrow control-runner assumption retained; no behavioral mismatch in the first compiled baseline run and no acceptance retuning. Finite i128 corpus and valid fixture inputs only; no universal refinement proof, arbitrary integer policy, calls/recursion, full3c or production runtime claim. Unrelated CLAUDE.md edit preserved. New branch not merged; experiment 9 also remains separately In Review.

This supports a finite executable bridge to the accepted memory model. It does not satisfy full3c calls/recursion or universal backend refinement. Return to remaining Needs Input discussion.

## Integer-policy comparison — 6 October 2026

Integer comparison passed at 03705f1dac1de8cbc9efedaf99ad4feeb62c17a3 on `codex/integer-policy-comparison`, pushed and remote verified. [Report](<https://github.com/robertguss/mo-v2/blob/03705f1dac1de8cbc9efedaf99ad4feeb62c17a3/experiments/11-integer-policies/RESULT.md>). Both builds passed 12,563 frozen cases; four real compiled broken variants caught; 627 checked measurement executions (570 interleaved timing + 57 allocator), 18 fixed-width wide-input refusals. Expectations frozen at 955187b before Rust. Calibrated allocator, separate uninstrumented timing, complete raw evidence, all caps satisfied. Same-author verification, not independent acceptance. Common million-step big-integer arithmetic took approximately 10–13 times checked i64 time for these specific implementations/workloads; checked versus wrapping much closer. Explicit benchmark routes reuse the same homogeneous backends, so no typing-overhead claim. No streaming/in-place BigInt optimization or agent study. Recommend discussing checked fixed integers with explicit big integers and deliberate wrapping; no Mo default chosen. Prior fingerprints unchanged; unrelated CLAUDE.md edit excluded. New branch is In Review, not merged; experiment 9 remains separately In Review. Return to remaining Needs Input discussion, no next experiment authorized.

## Copy-feedback pilot preparation

Preparation package pushed and remote verified at 60448b8e2cd08d81d3b5a3ece2ed1e51be61983d on `codex/copy-feedback-package`. [Readable report](<https://github.com/robertguss/mo-v2/blob/60448b8e2cd08d81d3b5a3ece2ed1e51be61983d/experiments/12-copy-feedback/RESULT.md>). Six tasks, exact feedback, 30-pair run order and proposed protocol frozen in PACKAGE_LOCK.json. Separate acceptance author froze checks at 44f05de before task source; all six baselines and two legal repairs passed 20 full-value cases each. Unique baseline updates each allocated 100,000 cells/3.2MB; legal repairs allocated zero; required old values preserved. Four negative controls caught (three compiled semantic/cost failures, one pre-build integrity rejection). Separate baseline profiling: 120 instrumented cases and 60 full-answer-checked uninstrumented timing runs. Independent review re-evaluated saved baseline/repair/timing outputs and ran controls plus all 30 delivery setups, 60 requests, six public checks and two forced cleanup paths. No blocking findings. Actual timing-run execution was by the parent, not independently repeated; checks/control/delivery authorship is separate. Large raw JSON archived losslessly with original hashes. Prior files/locks unchanged; unrelated CLAUDE.md edit excluded. No participant sessions, no merge.

Review gate: approve this concrete package and proposed five-minute limit per session before 30 gpt-6.1-sol/medium Codex-subscription trials. Actual launcher context isolation and process-group failure cleanup must be implemented and verified before any approved trials; current delivery utility launches no model. No paid fallback/top-up. Existing historical criteria remain unchanged.
