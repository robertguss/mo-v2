# Full-3c exact preparation — proposed acceptance, not a freeze

This package prepares ROB-1139 under D185/D186. It contains definitions,
statement interfaces, independent predictions, finite checks and comparisons.
It contains **no proofs or demand checker**. No preparation result authorizes a
scientific lock, proof campaign, checker campaign, merge or deployment.

The unchanged historical baseline, author ordering and access boundaries are
in `SPEC-ENCODING-BRIEF.md`. The independent prediction checkpoint is
`acceptance/CHECKPOINT.md`; its original manifest and expectations must not be
rewritten to match this model. Review history is retained in `VERIFIER.md`.

## Exact obligations

All names below currently denote `Prop` definitions, not proved theorems.

| English obligation | Locked-candidate declaration | Proposed later proof name |
| --- | --- | --- |
| Invariant/progress, exact cell/call effects, source-prescribed observer scope/order and internal boundaries | `Full.Statements.F1` | `Full.Proofs.f1` |
| Independent Plain correspondence, both directions, no administrative divergence | `Full.Statements.F2` | `Full.Proofs.f2` |
| Every finite prefix and transfer boundary protects source-required live values | `Full.Statements.F3` | `Full.Proofs.f3` |
| Finish leaves exactly the answer/outside graph | `Full.Statements.F4` | `Full.Proofs.f4` |
| Zero/split/terminal budget laws | `Full.Statements.F5` | `Full.Proofs.f5` |
| Universal finite-trial embedding and full ordered landmark projection | `Full.Statements.F6` | `Full.Proofs.f6` |
| Controlled denial preserves the last committed execution | `Full.Statements.L1` | `Full.Proofs.l1` |
| Terminating, outside-preserving, idempotent destruction | `Full.Statements.L2` | `Full.Proofs.l2` |
| Later conditional checker, demanded declarations with unique/disjoint entry | `Full.Statements.Conditional` | Not part of stage 1 |
| Later whole-program checker, without a uniqueness premise | `Full.Statements.Enforced` | Not part of stage 1 |

`Counted.begin` validates the entire typed function table and the old valid-start
graph contract. `Reachable` is actual finite execution, not a predicate assuming
future correctness. Integers, counts and identities are mathematical. Counted
control is an explicit task list; recursive source evaluation is not hidden in a
single step. `Plain` is independently defined over immutable values.

Each transfer reads the unchanged source State and constructs one complete new
State. No destructive pop or partly installed ownership/frame is a running
State. `Counted.Boundary` exposes the source, transfer output and metadata commit;
F1/F3 quantify over all of them. Pure proposed Memory/list data are not installed
machine states. This is a logical immutable-model property, not native refinement.

F1 fixes initial entered scope from input declarations, then requires the
source-prescribed `Inspect.nextScope` at both transfer output and committed
successor. The boundary invariant requires the complete entered-or-holding view,
including scalar/noHolder records, in acquisition-ID order. Enter switches to
fresh parameter identities; Return restores saved caller scope. Shared match
without tail acquisition deliberately delays scope entry until MatchComplete.
Administrative actions preserve the last entered scope. This closes the missing
full-language observer obligation recorded in `verification/FINAL-REVIEW.md`;
that historical report is retained, not rewritten as a passing review.

The address-only memory record is not the effect contract: F1 also equates the
whole event prefix and exact source-prescribed Enter/Return/Create/Write/Free
payloads. `creates` counts every descendant Create during an invocation, including
later-freed cells, beginning with Enter after explicit arguments. An extra hidden
entry copy is forbidden by F1's exact Enter transition, not silently ignored by
the interval counter.

## Reproduce finite preparation checks

Use the pinned Lean 4.34.0 package; do not change the global toolchain. Python
uses only its standard library. Generated observations belong outside the source
tree. From the repository root:

```sh
python3 experiments/03c-checker/full/run_spec.py /tmp/full3c-evidence
```

From `experiments/03c-checker/full/lean`:

```sh
lake build
lake env lean --run TrialCompatibility.lean
lake env lean --run ../verification/ReviewCases.lean
lake env lean -o .lake/build/lib/lean/Export.olean Export.lean
FULL3C_INPUTS=/tmp/full3c-evidence/inputs.json lake env lean ../verification/Controls.lean
```

The independent consumers live under `acceptance/`. Their inventories identify
the exact source/export revision each review consumed. Supplemental-v1 remains
historical: its whole-dictionary comparisons predate added trace metadata, so
it is not the current expanded-export consumer. Preserve its original evidence
rather than overwriting it with a later run.

Exports include all 90 action traces, internal transfer boundaries, independently
advanced Plain prefixes, ranks, C12's 29+4 continuation, C16's actual cut/resume and
double destruction, complete C19 split/whole/observation states, full C20 denial
transactions, and both actual destruction results. `reprStr` comparisons are
finite executable evidence, not equality proofs. Budgets bound observations,
not language recursion or mathematical theorem domains. Observation is a pure
projection; no claim is made about a native observer or arbitrary OS failure.

## Executed controls and controls that cannot run yet

`verification/Controls.lean` executes deliberately faulty logical transitions or
accounting algorithms on reached fixture states. Each transition requires a
passing unmodified control and a rejection for the intended property. A route
not reached, compiler failure or unexpected candidate error fails the control;
it is not counted as a successful rejection. These are not corruptions of
exported JSON. The independent consumer's data-corruption controls are separate.

The 21 routes cover shared detach, caller-reservation consumption, count-consistent
pending/suspended holder loss, administrative repetition, omitted Free/branch/frame/
unused-parameter cleanup, hidden entry copying, wrong Return/cell payloads, three
wrong interval counters, false Finish, restarted resume, late denial and no-op
destruction, hidden scalar parameter scope and reversed binding order. The
pending-holder route is checked against the independently computed
Plain successor; counts alone cannot certify it. Cleanup variants actually resume
to Finish and then fail the retained-graph check. None proves universal coverage.

**Not applicable until a checker exists:** accept-all, reject-all and omitted
caller-ownership checker mutations. Keep the 27 category expectations unchanged
and rerun those controls against the actual checker at the separately approved
later stages. No placeholder checker or runtime-denial substitute is accepted.

**Not executed until proofs exist:** proof mutation, transitive proof-axiom audit
and fresh kernel proof recheck. Passing definitions or this finite suite cannot
stand in for them. `lean/ProofGate.lean` records the exact future stage-1 type and
axiom-printing target. It intentionally imports the absent future proof module;
it is not in the preparation build and is not reported as passing.

## Proposed future proof gate — requires Robert's separate approval

Freeze the shared language/meanings/examples for both slices together only after
the acceptance-author supplements and separate verifier findings are resolved.
The preparation inventory is a review aid, **not** a scientific lock. At actual
freeze, record exact Git revision, full hashes, dependency/toolchain pins, the
approved brief and write boundaries. Never alter the old trial/Stage A/B locks.

For stage 1, proposed builder write scope is only `lean/Full/Proofs.lean` and
`lean/Full/Proofs/`. Definitions, statements, adapters, examples, controls and
acceptance machinery remain frozen. No `sorry`/`admit`, additional `axiom`,
unsafe/partial/opaque bypass, `native_decide`, `implemented_by`, `extern`, `csimp`,
syntax/elaborator changes, attributes changing locked definitions, shadowing,
or kernel-check bypass is permitted. The verifier must inspect meaning, not
only search for these strings.

The proposed **complete transitive axiom allowlist** is the old trial's:
`propext`, `Classical.choice`, `Quot.sound`. `sorryAx` or any other axiom rejects
the result. This is a proposed acceptance policy, not a report that new proofs
already satisfy it.

Fresh verification must reconstruct the exact frozen spec plus only permitted
proof files without old build outputs; compile the fully qualified type checks
in ProofGate; print and inspect all eight proof types and their transitive
axioms; run the pinned `leanchecker --fresh ProofGate`; rerun the unchanged
examples and applicable controls; and preserve logs and a readable result.
The kernel checker resolves to the approved Lean 4.34.0 toolchain's bundled
`bin/leanchecker`; no extra dependency or toolchain upgrade is proposed. The
concrete campaign brief/budget still requires approval before dispatch, not
invention by a proof author.

Stop after stage 1 and show the result. Conditional checker work needs a separate
stage-2 go-ahead; enforced caller checking needs separate slice-2 approval. A
counterexample or specification defect stops work and is reported, not weakened
away or described as merely an unfinished proof. No native Rust correctness,
physical-stack bound, unbounded physical storage or divergence proof follows
from the finite preparation evidence.
