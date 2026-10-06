# Fixed acceptance, separate from builder implementation

The lead owns this file, SPEC.md, acceptance/run.py, acceptance/model_oracle.py
and model/RepeatedUpdate.cfg. Hash those five before builder implementation.
Builder owns runtime/ and model/RepeatedUpdate.tla only. Do not alter experiment 4.

1. Clean offline Rust release build. No external crates, no compiler warnings.
2. Pinned TLC JAR from experiment 4 (release 1.7.4, reports 2.19; SHA256
   936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88) must finish
   complete safety/liveness exploration within five minutes. Export raw DOT with
   action labels; compare the complete 17-state/20-edge token model against the
   lead oracle. No full-Rust or wall-clock model correspondence claim.
3. Run the frozen TCP scenarios: held migration expires before release during a 1.1-second client-silent interval
   (recorded timeout at least 50 ms before observation), newer
   update succeeds, stale result discarded; held old operation times out safely;
   FIFO/payload/retry conservation across four activations; nonempty and empty
   corrupt candidates refused. Inspect coherent snapshots against independently
   collected submission receipts. Each terminal outcome stays immutable.
4. Run all three load repetitions: four persistent producer connections, 40 jobs
   each, eight normal updates. Require 160 completions, eight successful epoch
   transitions, completion overlap with updates, and all receipt/ledger checks.
   Record every request/reply/timing, busy replies, sampled copying windows and
   completion gaps. No averaging away a failed run. All sockets bounded; cleanup
   reaps the child even when acceptance fails. Successful runs require graceful
   server exit. A deliberately failing runtime control also exercises cleanup.
5. All five SPEC source mutants must compile and fail unchanged public checks
   for the intended wrong behavior. Root chooses unique actual source sites in
   disposable copies after reading code. A build error is not detection. Also
   mutate stale-return authority in the model and retain the invariant failure.
6. Retain every attempt and defect; builder repairs code without changing expected
   output. A mechanical harness repair requires preserving the original lock and
   documenting/relocking the repair. A semantic change or threshold relaxation
   requires owner input. Stop on an unresolved specification conflict.
7. Record versions, hashes, complete TLC output, build output, source review,
   negative controls, runtime evidence, timing limits and conclusions. Check lock
   and prior experiment manifest unchanged before delivering the branch.

Success only supports this bounded workload on this host. Both versions remain
compiled in. No exhaustive schedule proof, timing SLA, unbounded service, native
loader, arbitrary migrations, crash/external-effect recovery or production
deployment is implied. Stop after the report; merge remains an owner decision.
