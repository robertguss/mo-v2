# D191 amended rank freeze — 10 October 2026

Robert approved the specific Decompose weight change **10 → 12**, separate
review, preservation of the old failure, an amended freeze and resumption of
stage 1. AUTHORIZATION.md records the source and limits of that approval.

## Exact candidate and unchanged obligations

The amended artifact revision is local Git commit
`7800eab109caca85b9d2c03d0abf18df3701e856` on `proofs/rob-1139-stage1` in
`robertguss/mo-v2`. It is not pushed or merged. This record and its seal are
additive after that artifact commit. Remote delivery is not required to identify
the exact bytes, and no additional push is implied by the amendment approval.

The inherited 237-entry preparation inventory has exactly one changed entry:
`lean/Full/Control.lean`, whose only source change is the authorized coefficient.
Its amended SHA-256 is
`c4f95e4d50044803b6daa6b5800bbd86850ce32995c9a221b908ff8afd1edde1`.
The amended inventory is `stage-1/rank-amendment-01/PREPARATION.sha256`, SHA-256
`821da5b1897b4b09245887fa27ac8d16d826998b15a283a4bb26771c349982db`.
The other 236 entries, all 75 Trial dependency entries, toolchain, interfaces,
decoder, execution semantics, original predictions and acceptance checks remain
unchanged. Lean remains 4.34.0. No theorem quantifier or requirement was weakened.

Both original counterexample programs/starts are retained as exact regression
witnesses in `lean/Full/Proofs/RankRegression.lean`, with successful actual
initialization, reachability and step equalities. Their local decreases are
kernel-proved as 21 → 19 and 21 → 20. `Regression.lean` here also checks decoded
stuttering, the different Plain successor, data invariants, answer 3, final graph
and the complete traces. These two regression files are included in this seal;
do not retune them during subsequent proof construction.

## Preserved old failure

Original FREEZE.md, FREEZE.sha256, PREPARATION.sha256 and all old evidence and
manifests are unchanged. They describe the old model, not this amendment.
The old preparation inventory intentionally fails exactly Control in this tree;
the old freeze seal and Trial dependency inventory still pass. Use the amended
preparation below for the current model.

Local checkpoint `37914e13e175a2f0ad1eec19aa83ac0c2e87a16f` preserves the complete
old counterexample at its original import path and all 33 counterexample
manifest entries. Its negative theorem is additionally preserved byte-for-byte
at `stage-1/counterexample/frozen/RankCounterexample.lean`, with SHA-256
`685178dd0be4dbaf08034f0e116671a795dd2b2b1fc4d42f7994c02586d16468`.
Run old reproductions in an archive of that checkpoint, not by importing its
negative theorem into the amended model. No historical failure became a pass.

## Completed verification before resuming proofs

- Separate review approved only this scoped amendment; see REVIEW.md. The
  reviewer inspected preservation, exact inventory/source differences,
  reachability non-vacuity, arithmetic, imports and transitive axioms, and ran
  build, runtime regression and fresh kernel checks independently. This is
  same-account procedural separation, not independent-account certification.
- A clean archive of the original frozen model plus the amended Control and
  regression sources, without copied Lake outputs, built 14 jobs and passed
  `leanchecker --fresh Full.Proofs.RankRegression`. Working model/proof bytes
  match the clean checked files. Both regression proof axiom sets are exactly
  `{propext, Quot.sound}`.
- Existing partial proofs and the new regression build together: 93 jobs pass.
  This is not the full eight-target ProofGate.
- Unchanged finite checks pass: 90 cases, 84 finished answer/ledger/graph
  checks, 820 expanded groups, 12/12 consumer-corruption controls, all 28 Trial
  comparisons, and 21/21 actual faulty routes with passing baselines.
- The unchanged boundary consumer passes 4,498 complete internal equalities
  and 9,680 visible views across 90 traces. Raw amended observations are retained
  compressed under evidence/, with the original expectations unchanged.

Logs under evidence/ record these checks. Additional generated-call diagnostics
continue separately; they are not a substitute for the universal proofs or a
condition silently added to the language. Any new concrete defect still triggers
the established stop condition.

From `experiments/03c-checker/full`, verify the active model and amendment:

```sh
sha256sum -c stage-1/rank-amendment-01/FREEZE.sha256
sha256sum -c stage-1/rank-amendment-01/PREPARATION.sha256
sha256sum -c BASELINE.sha256
sha256sum -c FREEZE.sha256
```

## Resume scope

Stage 1 resumes against this amended model, with the exact F1–F6/L1–L2 types
and the same no-bypass policy, standard-axiom allowlist, full ProofGate, clean
kernel check, finite controls and separate verification required for completion.
F5/L1 remain the only two complete positive targets at this freeze. Proof-only
writes resume in Full/Proofs.lean and Full/Proofs/, except the sealed regression
file; evidence remains additive under stage-1/. No discretionary partial-stop
budget is introduced. No checker, caller enforcement, PR, merge or deployment
is authorized, and this freeze is not stage-1 acceptance.
