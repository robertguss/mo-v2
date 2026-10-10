# Stage-1 continuation — 10 October 2026

**Partial progress, not stage-1 acceptance. F5 and L1 remain the only two of
eight complete targets.** No concrete frozen-specification defect was found.

Robert requested “Commit and push then continue” in the
[working thread](https://ampcode.com/threads/T-01a121f6-7962-75c6-bb35-922b9a6cc491).
The prior reviewed checkpoint was pushed and remote-verified at
[cd33b7c](https://github.com/robertguss/mo-v2/commit/cd33b7cbfd59ea9a3a8e424b3212e7432637f7d0)
on `proofs/rob-1139-stage1`; [Buildkite 53](https://buildkite.com/robert-guss/mo-v2/builds/53)
passed. That CI checks historical experiments, not full-3c proof acceptance.
Work then continued under D188, without changing the frozen scope. No PR, merge,
deployment, demand checker, caller enforcement, or new scientific freeze occurred.
Earlier local-only wording in stage-1/RESULT.md is historical and preserved.

## New proved components

- `SimulationInitial.initial_simulation` proves exactly F2's first conjunct:
  every successful counted initialization corresponds to the independently
  initialized Plain machine. Ghost lookup, environment ordering, validation
  and erasure of initial release tasks are derived, not assumed.
- `transition_effects` and `commit_effects` prove F1's exact event and memory
  ledger equations for every successful transition with source answer `none`.
  No reachability or heap-invariant assumption is needed. Effects include the
  complete Create/Write/Free/Enter/Return payloads and their order.
- `invariant_heap` derives unique heap addresses, readable external roots,
  exact live counts, finite live paths, and allocator freshness from the frozen
  `Inspect.invariant`. The root view excludes live links because Trial's holder
  function already counts them; an equality to frozen `Inspect.owners` is proved.
- `free_from_invariant` derives the heap and immutable-edge premises for a
  valid pending live-zero Free. The actual transition preserves heap safety,
  closure, freshness, every old external root's readback, and decoded Plain
  control, while strictly decreasing the frozen rank. These results cover
  both atomic transfer and metadata commit, including empty/nonempty tails.
  It **does not** prove full output `Inspect.invariant`, or derive pending-Free
  lookup/status/count from reachability. Those control premises remain explicit.
- General decoder lemmas establish dependence on ghost bindings only,
  metadata-commit equality, and independence of traversal fuel above task-list
  length. This is not a bound on source programs, recursion or execution.

There are 26 new public theorems, plus their private proof dependencies, in
five proof modules. ProgressGate imports those and the preserved prior gate.
The initial-correspondence and effects units were written by distinct bounded
proof workers; the integrating author reviewed their source, removed unused
effect-proof simp arguments, and performed combined clean verification. A
different verifier then checked all six final source files; see REVIEW.md.
These roles provide same-account procedural separation, not independent-account
scientific certification.

## Reproduction and evidence

From `experiments/03c-checker/full/lean`:

```sh
lake build Full.Proofs.ProgressGate
lake env lean Full/Proofs/ProgressGate.lean
lake env leanchecker --fresh Full.Proofs.ProgressGate
lake env lean ProofGate.lean # exits 1: six exact targets still absent
```

A clean reconstruction used `git archive` of the approved freeze
[a17f652](https://github.com/robertguss/mo-v2/commit/a17f65215ed14288416c92e8af028078ffb827ff)
for full/ and its unchanged Trial dependency. Only the 11 proof files (five
prior, six additional) were overlaid. No `.lake` cache or output was copied.

- Clean `lake build Full.Proofs.ProgressGate`: **61 jobs, exit 0**.
- Clean `leanchecker --fresh Full.Proofs.ProgressGate`: **exit 0**.
- Direct axiom inspection of all 26 new public theorems: **exit 0**, only
  `propext`, `Classical.choice`, `Quot.sound` appear. Private dependencies are
  covered transitively. The separate verifier repeated this inspection locally.
- All 11 working proof files were byte-compared to the clean kernel-checked
  sources; every comparison passed.
- FREEZE, PREPARATION, BASELINE and the prior partial manifest remain valid:
  **2 / 237 / 75 / 17 entries**. No old proof, statement, model, prediction,
  checker, acceptance file or inventory was changed.
- The frozen full ProofGate was rerun and **exited 1** for the six missing
  proof names. It is not replaced or represented as passing by ProgressGate.

Logs are in evidence/. This continuation did not rerun finite acceptance or
controls: no execution definition changed, and their prior evidence is retained
unchanged under stage-1/evidence/. No new finite-run or full-stage acceptance
claim is made. MANIFEST.sha256 inventories this additive checkpoint only; it
does not alter the frozen acceptance or prior checkpoint inventories.

## Remaining construction

F1/F2/F3/F4/F6/L2 remain unproved as complete statements. The next substantive
task is the joint typed residual-control/slot invariant and its preservation:
typed name/ID environments, exact operand/capture/argument/return segments,
holding bindings versus future uses or queued releases, and well-bracketed
reservations. It must establish legal transition operands and cleanup tasks
from every finite Reachable witness, including recursive calls, rather than
assume future correctness. The new initial correspondence, exact effects and
zero-count Free lemmas are components of that construction, not a substitute.

Stage 1 remains authorized; there is no new package-approval gate. Checker and
caller-enforcement work still require their later separate approvals.
