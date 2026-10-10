# Stage 1 stopped: verified contradiction to frozen F2

10 October 2026. **Stage 1 cannot pass the unchanged frozen specification.**
The new kernel-checked theorem
`Full.Proofs.RankCounterexample.not_f2 : ¬ Full.Statements.F2` proves a concrete
contradiction, not merely a gap in the attempted positive proof. F5/L1 remain the
only two completed positive target statements. No other target is claimed false
by this result.

Robert requested continued work until stage 1 completes, without another
discretionary partial checkpoint. Work continued until this scientific stop
condition from `stage-1/BRIEF.md` was reached. The approved freeze
[a17f652](https://github.com/robertguss/mo-v2/commit/a17f65215ed14288416c92e8af028078ffb827ff),
all definitions, statements, predictions, acceptance checks and historical
inventories remain unchanged. No rank repair, amended freeze, checker or caller
enforcement has been implemented.

## The smallest retained example

Define a zero-argument function that returns 3. Match the two-element list
[1, 2]; the empty branch returns 0, and the nonempty branch calls the function
without using its head or tail bindings. Start with no input cells or roots.

After 14 counted steps, the next action decomposes the list. Before and after
that action, the frozen decoder says to evaluate the same call. Plain's next
step would instead enter the function, so F2's Plain-step alternative is false.
F2 then requires strict decrease of its frozen natural rank, but both ranks are
19. The actual initialization, reachability, successful step, unfinishedness,
decode equalities and rank values are proved by kernel reduction.

A second example matches an input list also held by an outside root. It reaches
the same issue after four steps; decomposition increases the rank from 19 to 20.

| Case | Counted steps | Frozen rank | Decoded state | Actual next Plain step |
| --- | --- | --- | --- | --- |
| Unique head, unused nonempty tail | 14 → 15 | 19 → 19 | Unchanged | Enters the function |
| Shared head, unused nonempty tail | 4 → 5 | 19 → 20 | Unchanged | Enters the function |

Both examples finish with answer 3, and the source/target data invariants and
final-graph checks pass. This is **not a demonstrated memory-safety failure**.
The full frozen progress/correspondence statement nevertheless fails.

## Why the fixed rank misses this case

The number of stored cells stays two, contributing 8 on both sides. The common
Finish task contributes 1. Frozen Decompose has weight 10. Replacement tasks
before Finish have these weights:

| Task | Unique unused tail | Shared unused tail |
| --- | ---: | ---: |
| GiveBinding / GivePending | 3 | 3 |
| MatchComplete | 0 | 1 |
| BranchStart | 1 | 1 |
| Eval zero-argument call | 2 | 2 |
| BranchResult | 4 | 4 |
| Total replacing Decompose | 10 | 11 |

Changing Decompose to 11 alone would leave the shared case at 20 → 20.
**Proposed, not approved or implemented:** a scoped amendment raising its weight
to 12, retaining these cases as regressions, separately reviewing the amendment,
and recording a new freeze while preserving this failed one. This would make
these two local decreases strict; it is not proof that all other cases or F2
then hold. The remaining universal proof work would still be required.

## Reproduction and verification

From `experiments/03c-checker/full/lean`:

```sh
lake build Full.Proofs.RankCounterexample
lake env lean Full/Proofs/RankCounterexample.lean
lake env leanchecker --fresh Full.Proofs.RankCounterexample
lake env lean --run ../stage-1/counterexample/Reproduce.lean
```

- A clean reconstruction used `git archive` of the frozen revision for full/
  and its Trial dependency, with only RankCounterexample.lean and Reproduce.lean
  overlaid. No `.lake` cache or build output was copied. The negative proof
  imports only frozen Full.Statements, not any new partial proof module.
- Clean build: **14 jobs, exit 0**. Fresh pinned Lean 4.34.0 kernel check:
  **exit 0**. Direct axiom inspection: only
  `propext`, `Classical.choice`, `Quot.sound`. The runtime reproducer confirms
  both exact failures and the successful data checks described above.
- Both source files were byte-compared with the clean checked copies. Proof
  SHA-256: `685178dd0be4dbaf08034f0e116671a795dd2b2b1fc4d42f7994c02586d16468`.
- A different verifier independently inspected the quantifiers, both disjuncts,
  reachability, valid starts, fallback non-vacuity and imports, and reran build,
  fresh kernel, axiom and runtime checks. See REVIEW.md. This is same-account
  procedural separation, not independent-account scientific certification.
- Original FREEZE/PREPARATION/BASELINE and both historical stage-1 inventories
  pass: **2 / 237 / 75 / 17 / 17 entries**.
- The unchanged full ProofGate was run and **exited 1**, still missing
  f1/f2/f3/f4/f6/l2. It has not been replaced by the negative-proof check.

Logs are under evidence/. An empty clean-kernel.log means the checker returned
silently; clean-status.log records successful completion of that command and
the subsequent reproduction and byte comparisons.

## Discovery and preserved partial work

Additional diagnostic generation, not an amendment to frozen acceptance, first
checked 3,000 typed Trial-fragment programs against exact ordered snapshots,
invariants and control/rank. All passed. The generated call-program search then
stopped at its first failure, case index 59 (seed 373), rather than completing
the planned 4,000 cases. Sources and original logs are retained in evidence/;
the larger generated witness was reduced to the examples above. Existing finite
acceptance and mutation controls were not rerun in this continuation; their
historical results remain unchanged and do not establish universal F2.

Eight new proof modules are preserved: independent Plain typing/progress;
structural Finish placement; finite simulation consequences conditional on F1
and the local forward correspondence; outside-only destruction conditional on
F1 and its graph lemmas; Trial embedding/snapshot/future-use and execution base
cases; and the negative F2 result. Combined explicit build passed **88 jobs**.
All **113 public theorem axiom sets** are empty or within the approved allowlist.
These partial results do not supply a positive F1, F2, F3, F4, F6 or L2.
The clean reconstruction and separate review described above certify the
negative result specifically, not full acceptance of these partial modules.

## Delivery state and required decision

The new proofs, reproducer and evidence are **local, uncommitted and unpushed**
on `proofs/rob-1139-stage1`. The previous pushed head remains
[ea0fde9](https://github.com/robertguss/mo-v2/commit/ea0fde992d7f9d59bf5f5bedda6e911f4edb8baf).
Main is unchanged; no PR, merge, deployment or later scientific stage occurred.

The remaining decision is a scoped specification amendment and new freeze,
not another approval of the existing package or a discretionary proof budget.
Preserve this negative result. Do not describe the frozen stage as completed or
silently alter the rank to make it pass.
