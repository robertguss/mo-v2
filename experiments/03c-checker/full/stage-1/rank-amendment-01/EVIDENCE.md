# Additive D191 verification evidence

This record supplements, and does not edit, the amended FREEZE.md. The seal
commit is `1a8a18c55886ad99cc4b5bc75c33df0a080fa009`; its exact candidate remains
`7800eab109caca85b9d2c03d0abf18df3701e856`. Both are local on
`proofs/rob-1139-stage1`, not pushed or merged.

The frozen record accurately stated that additional call diagnostics were
continuing. That run subsequently completed. `evidence/calls-search.log` ends:

```
PASS 4000 generated typed multi-function programs, invariants, control/rank and final graphs
```

These are generated finite checks, not the universal F1–F6/L1–L2 proofs.
F5/L1 remain the only two completed exact positive targets at this record.

The evidence directory also preserves the amendment's clean build, fresh kernel,
axiom and regression checks; original/amended inventory checks; unchanged finite
suite and corruption controls; exact Trial comparisons; and boundary checks.
`raw.json.gz` is the losslessly compressed observation export; `inputs.json`,
`summary.json`, `expanded-results.json` and `boundary-results.json` retain the
corresponding inputs and results. The prior FREEZE.md lists their counts and
the separate REVIEW.md states the procedural-verification limitations.

`EVIDENCE.sha256` inventories this additive record and these evidence bytes.
Verify it from `experiments/03c-checker/full` using:

```sh
sha256sum -c stage-1/rank-amendment-01/EVIDENCE.sha256
```

Proof construction resumes under the existing scope. No frozen statement,
prediction, acceptance check, decoder or execution rule is changed by this
evidence record. No full stage-1 acceptance, checker work or deployment is
claimed.
