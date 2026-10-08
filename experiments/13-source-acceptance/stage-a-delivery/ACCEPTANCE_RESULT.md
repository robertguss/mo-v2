# Final-08 Stage A evidence complete — parent review pending

**The applicable frozen Stage A checks pass for the exact final-08 submission.**
No candidate discrepancy was observed. This is finite experimental evidence,
not a proof about all programs, a merge approval or authorization for Stage B.
The original infrastructure-stop report and all its evidence remain unchanged.

## Historical schedule completed without reruns or hidden gaps

The storage preflight found about 53 GiB and 17.3 million free inodes. The exact
submitted source, dependency lock, frozen package and retained binary were checked
before resumption. Locked/offline build preserved binary SHA256
`41f444e2872ef417dd58fcb3d05920705b8c10ba1b45b1dc451287da8259feb9`.

`continue_historical.py plan` reconstructed every request from retained baseline
inputs, committed lengths and observed allocation schedules. Each credited old
run had its saved request checked and its complete transcript replayed through
the unchanged verifier. Filename presence or aggregate counts did not establish
a pass. The first unexecuted request matched the preserved
`deny-1510-frame-010` payload exactly and passed when resumed.

| Historical run family | Previously passed, skipped | New passes | Combined |
| --- | ---: | ---: | ---: |
| Resume cuts | 18,360 | 39,712 | 58,072 |
| Destruction cuts | 18,360 | 39,712 | 58,072 |
| Observed controlled denials | 23,863 | 57,078 | 80,941 |
| Total | 60,583 | 136,502 | 197,085 |

`reconcile.py` passed: every scheduled ID has one successful old/new destination;
zero unexecuted requests, duplicate IDs or orphan new destinations. The plan
preserves the old/new map and canonical request fingerprints; the new completion
ledger pins successful summaries. Each new shard has at most 500 run directories.
Sharding changed storage organization only, not the experiment or work limit.
Commands and outputs are retained in `plan-command.txt`, `run-command.txt` and
`reconcile-command.txt`; `reconciliation.json` gives the exact combined counts.

The original final-08 baseline remains 4,276 source-driven historical native
passes / 53,796 committed actions, with 89 actual Writes, 304 Creates and 5,269
Frees; 1,064 fixtures retain outside roots and observed release depth reaches
three. Those operation counts belong to the uninterrupted historical baselines,
not the sum of repeated cut/denial runs. All prior failure boundaries pass.

## Remaining public-source checks and source review

`public_cuts.py` passed across 135 retained public baselines: 562 additional
resume runs, 562 destruction runs and 830 denial runs. Of those baselines, 77
refuse before execution and therefore have no runtime cuts. Combined historical
and public-source totals are **58,634 resume, 58,634 destruction and 81,771
controlled-denial runs**. Every attempt uses the unchanged native driver/verifier.

The preceding exact-revision evidence also retains 58 applicable diagnostic,
encoding and priority checks, two accepted-source cases, 35 wide-decimal cases,
12 worked sources and 28 selfcheck sources. The 16 expectations specifically
about Stage B semantics stay deferred; they were not rewritten for Stage A.

`ROUTING_REVIEW.md` records the completed source audit: source-driven parsing,
resolution and execution; real Number parse/arithmetic/copy/read routing; actual
Frame continuation storage; staged committed-state selection; ordering of all
controlled gates before native mutations in inspected execution actions; and
iterative ownership-based destruction. It does not impose an all-host allocation
policy on initial bookkeeping or claim host-OOM/deep-stack recovery.

## Compiled controls rejected for their intended faults

All 21 applicable controls have a passing baseline using the same compiled
evaluator with the mutation disabled, followed by a real native run with the
mutation enabled. Recorded markers establish the modified path was reached.
`control-collection.json`, `control-predicate-evidence.json` and
`controls-reviewed.json` retain outcomes, exact differences and classifications.

| Controls | Decisive evidence |
| --- | --- |
| token-reader; wrong-scope | Canonical checked-tree mismatch; wrong-scope changes only the resolved binding path. |
| accept-all; refuse-all | Invalid source accepted / valid source refused. |
| whole-file-span | Refusal class agrees; only the source-span coordinates differ. |
| frontend-list-preallocation | Frozen Rust driver rejects actual frontend managed-cell activity before emitting a check row. |
| fixed-i128 | Produced numeric value differs from the frozen growing-integer result. |
| shared-mutation | Outside-held cell contents change in the actual native graph. |
| shadow-reporter | Claimed reuse differs from native item/tail contents. |
| premature-free | A still-required cell is absent from the native graph at the first rejected callback. |
| tail-leak; physical-leak; outside-drop | Frozen destruction predicate rejects the actual remaining graph/counts. |
| lost-live-holder | Required pending holder is missing at the first rejected callback. |
| wrong-reservation-order | Wrong reserved lifetime is consumed; aside, result and native graph differ. |
| replay | A new Start action replaces the required resumed suffix. |
| counter-reset | Frozen Rust collector rejects nonconsecutive callback numbering after a passing prefix. |
| call-boundary-only | One-step advance makes no progress; frozen exact-cut check rejects undershoot. |
| suspended-as-finished; resource-as-suspended | Frozen terminal/failure classification checks reject incorrect status. |
| double-free | Repeated native free returns UnknownCell; duplicate claimed cleanup fails logical/native comparison and the unchanged destroy free-set/duplicate predicate on captured rows. |

Two wrapper errors say abnormal process termination, but their stderr and frozen
driver sites establish the specific frontend/cumulative-step guards; they are not
generic crashes counted as controls. Premature-free and lost-live-holder stderr
also records later consequences of their injected fault; the first verifier
rejection is the intended missing-cell/pending-holder discrepancy, not that later
cleanup error/panic. Double-free does **not** physically deallocate twice: the
native guard prevents it. The evaluator wrongly suppresses that error and reports
duplicate cleanup; replaying the captured rows through frozen `check_destroy`
also rejects exactly `destroy free set/duplicate`.

The original control preparation is preserved. The sibling control copy was
rebuilt, including its final coarse-boundary adjustment and the explicit repeated
native free attempt. Neither exact candidate bytes nor frozen host/checker bytes
were changed. No synthetic/stub trace was counted as a compiled evaluator control.

Ten exact control paths remain Stage B-deferred: always-copy (C10), hidden-entry
copy, fixture/literal function-route provenance, caller-reservation theft, early
cleanup (C14), omitted entry/nested/transient creates, early function entry and
skipped return cleanup. None is silently retargeted or reported passed here.

## Limits, preservation and delivery state

The 524 private rows retain only their previously observed Stage A capability
refusals; they all contain Stage B features. They establish **no private execution
coverage**. Their raw evidence remains outside the checkout, unchanged. This
continuation did not inspect the seed or deliver private material to the builder.

Denial schedules cover actual baseline attempts during frontend/execution, not
injected failures during destruction, arbitrary allocator failure or unobserved
schedules. Successful/nonterminal/failed-run destruction is covered; these are
different claims. Stage B execution, its semantic expectations and controls,
the large streaming adapter and resource workloads remain separately gated.

`preservation.json` records final fingerprints, counts and measured effort.
All eight submissions, earlier evidence/manifests, 496 frozen files, five
historical dependencies, seven archives and the scientific lock remain unchanged.
Lock SHA256:
`09c64493ba65f94451dc17c5bde7c4b54554d6990b23b8c877f2f9741f120c9e`.
The continuation's `EVIDENCE.sha256` fingerprints its regular files without
following runtime/driver/cells symlinks.

**New evidence is local and uncommitted; the tracked acceptance branch is
unchanged.** Parent review and any subsequent owner authorization remain separate.
No candidate repair, Stage B/resource workload, merge, deployment or builder
delivery occurred. Acceptance work is stopped after this Stage A result.
