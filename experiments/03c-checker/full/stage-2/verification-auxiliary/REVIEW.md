# Separate auxiliary-prefix verification — ROB-1139

**PASS for this prefix only. Conditional is NOT proved; stage 2 is NOT complete.**
Same-account procedural separation by a separate verifier, not independent-account
certification, not a Stage B single-agent exception. No thread, commit, push,
Linear update, frozen edit, changed expectation, new semantics, or private
experiment-13 access. Builder-owned `stage-2/auxiliary/evidence` was only read.

## Inspection and exact scope

Read all of `Full/Demand.lean`, Certificates, Credits, Events, Scopes, Usage,
UsageTransition, BRIEF.md, check-auxiliary.py, and prior preflight REVIEW.md;
also read the actual frozen Statements.Conditional and Lake configuration.
Checker SHA256 remains
`bcd1d905ae3bac691d43b17c3dd9ce26d6a61131aacc79f71ecb38125da7a2ba`,
exactly the prior finite campaign checker. Seven consumed source hashes are
recorded in `sources.sha256` and were checked unchanged after this execution.

No sorry/admit, added axiom, native_decide, unsafe, extern, implemented_by,
opaque proof bypass, or premise asserting recursive no-allocation was found.
Heartbeat increases affect search limits only. Certificates derive syntactic
facts from the actual accepts result. Credits proves aligned static stacks and
monotonic spending, not concrete reservation availability. Usage's last_use
explicitly requires a continuation-wide bound; expression-local affine checking
alone does not supply it. UsageTransition proves nonincrease for OLD IDs under
`id < nextBinding`, not bounds for all newly introduced bindings. Events derives
invocation/event bookkeeping, fresh entry count zero, and closed interval
stability from actual transitions/reachability. Scopes proves invocation IDs in
saved work, not ownership of cells. These premises are appropriate to their
limited conclusions, not replacements for Conditional's premises.

## Independent execution

Both disposable reconstructions used precisely:

```sh
git archive 66f8aac22fbaa31100700a5ca9e5b486efd67c28 \
  experiments/03c-checker/full experiments/03c-checker/trial
```

Extracted into fresh `/tmp/rob1139-independent-aux-*` directories, asserted no
`.lake` existed, copied only the seven additive Lean sources (plus the verifier
gate), retained the frozen toolchain and local trial dependency. No checkout
build cache, stage-2 runner, builder proof/gate, or external evidence was copied.
Temporary trees were removed on exit. Commands and outputs in `build.log`,
`axioms.log`, `kernel.log`, `commands.log`, and `integrity.log`:

```sh
lake env lean --version
lake build Full.Demand Full.Demand.Certificates Full.Demand.Credits \
  Full.Demand.Events Full.Demand.Scopes Full.Demand.Usage Full.Demand.UsageTransition
lake env lean -o .lake/build/lib/lean/IndependentGate.olean IndependentGate.lean
lake env leanchecker --fresh IndependentGate
git diff --exit-code 66f8aac22fbaa31100700a5ca9e5b486efd67c28 --
sha256sum -c BASELINE.sha256
sha256sum -c FREEZE.sha256
sha256sum -c stage-1/rank-amendment-01/PREPARATION.sha256
```

All final commands exited 0. Lean 4.34.0, commit
`293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`; cache-free build 69 jobs.
Fresh kernel checker exited 0 (silent successful output, preserved command).
Tracked diff empty and the three frozen checksum inventories passed.
Gate SHA256: `91f88ee4bbab97cfffb5a15cb56e18d8c038083fb30b7c5363163919975198e5`.

**Inventory refinement:** builder's regex gate covers all 64 explicit public
theorems, including dotted names and simp declarations. An actual Lean environment
enumeration of theorem constants under `Full.Demand.*` additionally exposed
148 generated equation, recursion, tactic-helper and brecOn constants. Initial
verifier inventory equality intentionally failed on these extras (preserved in
commands.log); expanded the gate and rebuilt from another fresh reconstruction.
Final enumeration matched exactly **212** names, every one #checked and axiom
audited. This is an expanded audit, not 212 handwritten scientific claims.
Private certificate helpers are not public exports and are covered transitively
by the exported proofs and fresh module kernel check.

Distinct axiom sets for all 212: 10 empty; 49 `{propext}`;
133 `{propext, Quot.sound}`; 20 `{propext, Classical.choice, Quot.sound}`.
Nothing outside the complete allowlist. Exact elaborated theorem types, names,
sets and environment enumeration are preserved in axioms.log.

## Missing central proof and limits

Still missing: a preserved semantic ownership/reservation invariant linking
accepted syntax and active credit scopes to the actual machine. It must establish
continuation-wide affine ownership for new bindings/parameters/tails, preserve
unique/disjoint reachable lists from the frozen pre-release entry premise,
justify exclusive usable reservations in the proper invocation/match lifetime,
and show each Cons (including argument preparation and descendant calls) uses
an eligible local reservation rather than causing Create. It must handle
simultaneously validated recursion without assuming recursive no-Create summaries
and without borrowing caller reservations. Old-binding occurrence monotonicity,
stack alignment, and task invocation metadata do not establish these facts.

The required missing gate is an actual theorem of the unchanged type
`Full.Statements.Conditional Full.Demand.accepts`, with its exact type check,
allowlisted transitive axioms and fresh kernel recheck. Nothing inspected proves
that theorem. This is unfinished proof work, NOT a specification defect.

Did not rerun finite acceptance, controls, Koka comparisons, lifecycle gates,
or caller-ownership enforcement; the earlier finite review is context only.
No universal checker soundness or stage-2 completion certification is issued.
