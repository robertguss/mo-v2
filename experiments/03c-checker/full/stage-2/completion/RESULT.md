# ROB-1139 slice 1 stage 2 — conditional checker result

**PASS: the executable checker has the exact frozen conditional guarantee.**
Separate same-account verification passed. This completes slice 1 stage 2, not
the whole experiment. Caller ownership enforcement and the unconditional
guarantee remain separately gated slice 2. No new model amendment was required.

Work is local, uncommitted and unpushed on `proofs/rob-1139-stage2`, based exactly
on remote stage-1
[`66f8aac`](https://github.com/robertguss/mo-v2/commit/66f8aac22fbaa31100700a5ca9e5b486efd67c28).
No merge, deployment or delivery-CI run occurred. Stage-1 Buildkite 90 canceled
both jobs without checks; it remains neither a CI pass nor a proof failure.

## Exact guarantee and its boundary

```lean
Full.Demand.Soundness.conditional :
  Full.Statements.Conditional Full.Demand.accepts
```

For an accepted demanded invocation at an actual reachable Enter with the
approved unique/disjoint list arguments, every successful finite execution
prefix has **zero primitive list-cell Creates in that invocation's interval**.
The interval includes descendants, argument preparation within it, and cells
that might later be freed. Prefixes can stop inside a descendant or continue
beyond the target Return. The entry assumption is checked before unused
parameters are released. Callers are not checked or enforced by this result.

The checker validates all demanded declarations simultaneously using syntax,
not assumed recursive no-allocation summaries. Sequential uses add and
alternative branches take maxima; list bindings must be affine. Cons requires
an innermost eligible local match credit. Callee bodies start without caller
credits; argument work is checked in the caller. Ordinary helpers are refused,
even arithmetic-only helpers: a documented conservative usefulness limitation.

The proof preserves continuation affinity, a fixed entry-address region and
the concrete ordered reservation stack. Pending-expiry reservations and the
older caller suffix cannot supply local credits. All entry invariants use the
same pre-Enter binding cutoff. Exact event bookkeeping closes the interval at
Return without dropping later prefixes. This is a mathematical-model theorem,
not Rust/native refinement, a physical-resource guarantee or a divergence test.

## Verification executed on these source bytes

Pinned Lean **4.34.0**, commit
`293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`:

* Cache-free archive of exact stage-1 plus only the 19 permitted checker/proof
  sources: **172 build jobs pass**. No `.lake` cache was copied.
* Exact Conditional gate and **525 public/generated theorem constants** pass
  type/axiom audit. Axiom sets: 34 empty; 116 only `propext`; 295
  `propext`/`Quot.sound`; 80 all three allowed axioms. No extra axioms,
  placeholders or native/unsafe proof bypasses.
* `leanchecker --fresh DemandAudit` and the unchanged eight-target stage-1
  `ProofGate` both exit 0. Separate proof controls reject an invalid term,
  a placeholder and an extra axiom for their intended reasons.
* Frozen acceptance: **90 cases, 84 finished answers/ledgers, 820 expanded
  checks, 12 export-corruption controls, 4,498 internal equalities, 9,680 views,
  3 boundary-corruption controls, 28 Trial comparisons and 21 faulty machine
  routes**, with passing unmodified baselines.
* Six frozen inventories, **423 entries**, pass before/after and in the clean
  reconstruction. Original predictions, historical locks, old failures and
  D191's sole rank-weight amendment remain unchanged.

The checker campaign independently consumes frozen predictions and validates
ASTs, demanded-name sets and input encodings: **253 Enter records** across 90
rows. All **27 categories** remain inventoried. Slice 1's **12 accept families
(38 rows), 6 refusal families (14 rows), 1 observation** meet the frozen
requirements. Slice 2's **3 accept / 3 refuse / 2 observe** remain deferred,
not claimed as caller-enforcement passes.

| Principal refused function | Actual Creates at unique entry |
| --- | ---: |
| duplicate | 3 |
| prepend | 1 |
| insertNew | 1 |
| build | 3 |
| twice | 2 |
| allocHelper (ordinary allocating helper) | 1 |

Actual-source mutations compile and run: **accept-all causes 33 failures**
(14 refusal failures plus 19 accepted allocating intervals); **reject-all loses
38 required accepts**; **missing-affine causes 3 failures**, including accepting
`twice` at unique entry despite 2 Creates. Arithmetic-only helper refusal has
0 Creates and is not counted as an allocating refusal witness.

## Separate review and reproducibility

`verifier/REVIEW.md` records a different verifier's inspection, independent
cache-free execution, source inventory, kernel/axiom checks, controls and
refusal witnesses. This is **same-account procedural separation**, not
independent-account scientific certification or the Stage B exception.
The original independent acceptance author did not implement this checker.

The verifier found one operational defect: the builder's audit gate omitted
`import Lean.Elab.Command`. The initial failure remains in `evidence/gate.log`
and `verifier/reproduction/`. The verifier passed with its own additive gate;
the builder then added that import and reran the stock runner successfully into
`final-evidence/`. No checker/proof bytes or frozen expectations changed for
this correction. The older incomplete CHECKPOINT and auxiliary/preflight
reports remain historical, not retroactive passes.

From repository root, using a **new, nonexistent output directory**:

```sh
python3 -B experiments/03c-checker/full/stage-2/completion/reproduce.py /tmp/rob1139-stage2-rerun
```

The runner preserves commands/exits, exact theorem types, generated axiom audit,
finite results and actual mutated checker sources. It reuses the separately
authored `verification-preflight/verify.py` without semantic changes; only the
output destination is redirected. Do not rerun historical scripts into their
old evidence directories. `verifier/COMMANDS.md` describes separate execution.

`SOURCES.sha256` covers all 19 delivered Lean sources. `MANIFEST.sha256` covers
the complete stage-2 records, including historical evidence and separate review;
both are checked from `experiments/03c-checker/full/`. Final gate/runner hashes
are also in `final-evidence/sources.sha256`.

Required public gzip evidence was restored per `experiments/GZ_ARCHIVE.md` and
checksum-verified. Regenerated raw observations are byte-identical to the
existing D191 release asset: SHA256
`d358ba51249cf260882eb437f1fbc9103260c0ef8f76849da2ed361a057ac78a`.
No new large artifact or `.gz` history object is needed. No private experiment-13
data was accessed. Historical Koka 3.2.9 comparisons and their limitations are
retained, not newly rerun. Finite trace comparisons alone do not prove the
universal guarantee; the separately checked kernel theorem supplies that result.

Stop here at the authorized stage-2 result. ROB-1138 remains Done; ROB-1139 is
not Done for the whole experiment. Publishing this branch and undertaking
slice 2 require their respective authorization.
