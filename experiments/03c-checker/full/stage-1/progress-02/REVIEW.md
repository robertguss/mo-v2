# Separate procedural verification — progress-02

Reviewed 2026-10-10, concluding at approximately 11:18 UTC. This is the
different-verifier role prescribed by D186/D188 and stage-1/BRIEF.md,
within the same account: **not independent-account scientific certification**.
Review scope is exactly the six new proof files listed below; frozen definitions
and inventory files were read as reference inputs. No proof source was edited.

## Conclusion and precise limits

No concrete defect was found in the six delivered files. The assertions are
valid partial results against the frozen definitions, not completion of stage 1.
The delivery explicitly continues to claim only F5 and L1 as complete; F1, F2,
F3, F4, F6 and L2 remain open. This review does not re-certify the prior F5/L1
proofs or establish any of those six open targets.

- `SimulationInitial.initial_simulation` is exactly F2's **first conjunct**:
  successful Counted.begin implies successful plainBegin and Related. Related
  unfolds to the stated decoder equality; there is no added validity,
  reachability, bounded-program or ghost-correctness hypothesis. My temporary
  Lean file checked this exact interface. It proves none of F2's remaining
  step, eventual-step or answer-equivalence conjuncts.
- `transition_effects` quantifies over every successful transition whose source
  answer is none, without a reachability or invariant hypothesis. Its equations
  use the frozen `Inspect.effects` and `Inspect.cellEffects`, with full list
  equality, exact payloads and order, not projections or matching subsequences.
  Create uses mem.next/head/tail; Write uses the eligible reservation address
  and head/tail; both Free forms use the actual address; Enter uses the full
  invocation/name/parent/reversed arguments/site frame; Return uses frame.id
  and the actual slot. Other actions have empty prescribed effects. Memory
  records append created/written/released as prescribed. `commit_effects`
  establishes the same equations at metadata commit, which does not alter
  memory or events. This is F1's effect-accounting component, not its totality,
  invariant preservation, scope or uniqueness obligations.
- `executionRoots` consists of slots, outside roots and holding bindings only.
  Live-cell links are counted separately by Trial.holders. The proved
  `executionRoots_holders` equation agrees exactly with frozen Inspect.owners,
  including multiplicity, without counting live links twice. `invariant_heap`
  derives address uniqueness, external-root finite readability, exact live-cell
  counts, finite paths for every live cell (including unrooted cells), and the
  frozen FreshBound from Inspect.invariant. These are not extra assumptions;
  positivity is not imposed on live zero-count cells awaiting Free. Reserved
  cells are not spuriously claimed to be live paths.
- `free_from_invariant` explicitly requires a head pending Free, a successful
  lookup of its live cell and count zero, as well as Inspect.invariant. It
  derives the edge association and heap premises, proves transition success,
  heap/path/freshness preservation and old external-root readback, unchanged
  decoded control, and strict decrease of the frozen Control.rank at transfer
  and commit. It does **not** conclude Inspect.invariant for the output or prove
  reachability-to-control-shape preservation, observer correctness, or universal
  step availability. `release_zero`'s standalone heap assumptions are visible
  local premises, not hidden assumptions in invariant_heap.
- The control fuel hypotheses bound decoder traversal by task-list length;
  they do not restrict source programs. ProgressGate is explicitly a partial
  gate, not a replacement or weakening of the frozen eight-target ProofGate.

## Checks performed by this verifier

1. Read all six sources and compared the relevant signatures/bodies with
   frozen Full.Statements, Full.Inspect, Full.Counted and the imported Trial
   HeapSafe/LivePaths definitions. No new axiom, sorry/admit, native_decide,
   unsafe or opaque bypass, redefinition of a frozen symbol, source shadowing,
   or weakened frozen theorem statement was found. The one new root-view
   definition lives in Full.Proofs; frozen namespaces are not replaced.
2. Waited until the **existing local** Effects build was complete: its olean
   existed with timestamp 11:17:11 UTC, later than Effects source 11:14:38 UTC,
   and no local Effects compiler remained. Did not duplicate that build.
3. Ran my own `/tmp/rob1139-verifier-axioms.lean` using `lake env lean`, importing
   Free, SimulationInitial and Effects, issuing all 26 public theorem
   `#print axioms` requests and the exact F2-first-conjunct example. Exit 0.
   Output is `/tmp/rob1139-verifier-axioms.log`. Lean reported pinned version
   4.34.0, commit 293d5d0c0c3f3dded4688b3ccd6a33939ac5102b.
4. Ran `lake env lean Full/Proofs/ProgressGate.lean` directly, without a build
   or source edits: exit 0, output `/tmp/rob1139-verifier-gate.log`.
   LEAN_PATH contained the existing local Trial and Full build libraries and
   the pinned toolchain library, not the parent's clean archive.
5. From full/, ran `sha256sum -c` for FREEZE.sha256 (2 entries),
   PREPARATION.sha256 (237), BASELINE.sha256 (75), and stage-1/MANIFEST.sha256
   (17), before and again after the Lean checks. Every check passed, exit 0.
   These inventories protect the old package, not the new files; their hashes
   are separately recorded below. Logs remain in /tmp/rob1139-verifier-*.log.
6. Git unstaged and staged tracked diffs were empty. The observed untracked
   work was the six new proof files and stage-1/progress-02 evidence. Thus the
   observed source writes are within the authorized proof scope; integrator
   evidence is outside the frozen package. This verifier adds only this file.

### Exact transitive axiom results (all 26)

Names below are relative to Full.Proofs. Every set is a subset of the permitted
propext/Classical.choice/Quot.sound set; no sorryAx or custom axiom appeared.

- `{propext}`: SimulationInitial.focus_giveBinding_prefix.
- `{propext, Classical.choice, Quot.sound}`: continuations_fuel, focus_fuel,
  release_zero, free_preserves_heap, free_from_invariant,
  SimulationInitial.input_lookup, SimulationInitial.input_environment,
  SimulationInitial.initial_simulation, transition_effects, commit_effects.
- `{propext, Quot.sound}`: control_env_bindings, continuations_bindings,
  focus_bindings, callTail_rest_length, decode_commit, executionRoots_holders,
  invariant_heap, invariant_live_edge, free_transition, free_decode, free_rank,
  SimulationInitial.mapM_map_ok, SimulationInitial.mapM_transfer,
  SimulationInitial.input_values, SimulationInitial.dead_is_prefix.

## Source SHA-256

All six hashes were independently recorded at review start and rechecked after
the Lean checks; unchanged. Paths are relative to full/lean/Full/Proofs/.

```text
c8cb7ea0b28a011956c4b03ca939c4b9263cb7a45bcf1f6d0dbb046561ddd658  Control.lean
e1ae210bb42af3843c3bf09d566e654ed3d6d0f609e1500e1d93ef4ba6357062  Heap.lean
21f0af4df2633b77ca1faf19067154bc1753ac1643716ace2eae5a1684e7a87f  Free.lean
e813b578062cdcee0b7f3d7c1aca1a070c53034303f77a66f451799033d2e0b8  Effects.lean
fd82735df8370352b614bac65a016914ac86d8c6e041ada3f4c0f5cb24dc8267  SimulationInitial.lean
03aac1afcf279d61c2f51eb82c7eed16e24f9a03189ac7b0abc322de0a91d3c7  ProgressGate.lean
```

## Parent-owned verification is separate

The parent's clean archive-plus-proof-overlay build at
`/tmp/rob1139-stage1-progress.8NnzWc` was still compiling Effects at my last
process observation. I did not modify, launch commands in, or otherwise touch
that clean build. Its completion, clean source-to-object reconstruction and
fresh kernel/leanchecker verification are **not results of this review**.
My axiom run consumed existing local compiled imports; source inspection and
stable hashes accompany it, but do not substitute for the parent's fresh clean
verification. I did not rerun finite acceptance, controls, or the full frozen
ProofGate. No complete eight-target or end-to-end correctness claim is made.
