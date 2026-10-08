# Stage B checker/interface repair — prepared, not frozen

Stop condition: resolve the disputed scoring and prepare a versioned explicit
observation interface and recursive checker, validated at small sizes against
the unchanged reference. Stop before million-element execution, publication,
merge, or a claim of complete Stage B acceptance.

Robert authorized resolving the issues, then explicitly approved the
full-versus-summary interface amendment in
[the acceptance thread](https://ampcode.com/threads/T-01a11697-f670-71bc-bd5d-f6f57958fa55).
No new decision number is assigned here. No Linear record was changed.

## Preservation and scope

All work is additive in this directory. The original 967-file Stage B inventory,
including the Stage A files, five historical dependencies, original lock and
all earlier reports remain unchanged. Original lock SHA256:
`2df4234fd86336b44307bee722972cf9f9c70a89b384d853db31e40d82ba5cbb`.

The copied `candidate-stage-b/` is byte-identical final-03, including its manifest;
it is a validation baseline, not a repaired candidate. `cells/` and the linker
are byte-identical copies resolving their relative dependencies to the revised
runtime. No mock cell store or observer capability is added to the runtime.
The copied canned fixtures remain explicitly non-evaluator protocol tests.
No private corpus or private-run evidence is read or packaged.

`REVISION.json` inventories the prepared files and their provenance. It is not
a replacement scientific freeze and does not silently supersede either lock.

## Repairs and evidence

* `OBSERVATIONS.md` defines an explicit request and the existing summary shape.
  Full snapshots remain compatible. The native collector no longer makes the
  candidate infer the mode, or serializes full host graphs for summary rows.
* Sum predictions now produce constant-size per-step birth/event batches,
  including invocation owners, branches, entry sites and return values. No
  materialized full trace is used by the streaming checker.
* The checker handles call events and opaque branch identities, checks complete
  observed event/birth prefixes, and rejects a run that reaches but never
  photographs its deepest point. Clock segments are checked as they arrive,
  rather than retained per action.
* The verifier bookkeeping guard now accounts for fixture rows, frame/branch/
  binding maps and reverse sets, and saved full-state rows: at most 16 rows per
  input cell plus 64. The old four-row multiplier did not account for recursive
  identity tables. This is a verifier retention guard, not a change to candidate
  memory provisioning, expected results, or timing limits. It measures retained
  bookkeeping rows, not transient serialization memory or a byte-level RSS cap.

Final validation results and raw evidence are indexed under `evidence/`:

* 873 transition/state comparisons at depths 0–8, with exact birth/event-prefix
  comparisons to the original reference at every step.
* 891 passing actual candidate/host runs covering every destruction boundary at
  those depths, with zero-budget joins and the reached deepest observation.
  One additional actual run intentionally omits that observation and is rejected.
* Opaque binding/frame/branch identity relabeling replays successfully. Five
  deliberately corrupted saved streams fail at the intended checker predicate.
* One compiled discard protocol-fixture run crosses two real 10,000-step summary
  checkpoints, with an off-grid pause, zero-work join and deepest observation.
  Five corrupted summary fields are rejected. This is not evaluator evidence.
* Native collector tests exercise full and summary requests at the same step,
  explicit boundary requests, and observation-cursor reset.

Pinned Rust 1.98.1 locked builds pass, as do three collector tests and all 53
unchanged candidate development tests. Formatting checks pass. Clippy with
warnings denied does not pass: both the original and revised collector report
the same three existing warnings (one type-complexity warning and two collapsible
conditionals). Those unrelated frozen-code style issues are preserved, not
suppressed. Logs for both checks are included.

## The two disputed controls are caught

`check_control_scoring.py` freshly builds the existing public sabotage patches
in a throwaway copy and repeats the two disabled/enabled pairs. Both baselines
pass. It replays raw failures with the unchanged small checker and verifies the
actual intended defect: a physical write to the caller's reservation where a
callee creation was required, or entry before the pending argument's Leaf.
Both satisfy the unchanged named control-record predicate.

A downstream panic does not erase a prior decisive rejection. An arbitrary
AssertionError, panic, marker alone or unrelated failure does not qualify.
The original seven-caught/two-uncaught report stays intact as historical evidence.
With these two classifications corrected, the combined reported tally is nine
active controls caught; the other seven were not re-executed here. The separate
entry-allocation control remains not applicable under the original rules.

## Reproduction

Run from this directory, using fresh external evidence paths:

```sh
export CARGO_TARGET_DIR=/tmp/rob1333-revision-target
cargo +1.98.1 build --locked --manifest-path stage-b-link/Cargo.toml
cargo +1.98.1 build --locked --manifest-path stage-b-stub/Cargo.toml
cargo +1.98.1 test --locked --manifest-path driver/Cargo.toml
PYTHONDONTWRITEBYTECODE=1 python3 check_revision.py \
  /tmp/rob1333-revision-check "$CARGO_TARGET_DIR/debug"
PYTHONDONTWRITEBYTECODE=1 python3 check_control_scoring.py \
  /tmp/rob1333-revision-controls
```

All destinations must be new. The checker deliberately refuses million-element
execution. Archive extraction/read-back instructions are in `evidence/INDEX.json`.
The first validation command had a module-name collision before executing a case;
the first scoring replay looked for a request file the original harness does not
write. Both failures and their logs are retained; neither changed an expectation.

## Remaining gates

This repair is same-author validation under Robert's Stage B arrangement, not
independent acceptance. It is local, uncommitted and unpublished. Review and
freeze the replacement package before using it for acceptance. The actual
candidate still needs efficient summary serialization through the new method:
its compatibility default returns full snapshots and cannot pass a summary
checkpoint. Then validate that implementation, repeat affected regressions and
run both approved large workloads under their unchanged limits. No performance,
full Stage B, private-campaign rerun, merge or deployment result is claimed here.
