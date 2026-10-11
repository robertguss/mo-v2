# Separate verifier review — ROB-1139 / D186

## Follow-up disposition (current uncommitted preparation)

The three historical findings below are resolved in the reviewed revision; they
are retained verbatim as the first review's evidence, not current defects.
See `verification/REVIEW-FOLLOWUP.md` for the boundary audit, control limitations,
fresh command results and conditional proposed-freeze recommendation. The old
destructive-pop reproduction has been replaced with a checked source/output/commit
reproduction because `Counted.pop` no longer exists. No proofs or checker acceptance
are claimed. Final exact-package readiness still awaits the separate acceptance
author's supplemental-v2 integration and review.

## Historical first review (unchanged)

**Disposition: do not freeze yet.** Reviewed the local, untracked preparation,
not an origin/main artifact. No proofs or demand checker were implemented. Read
the encoding brief and live approved v2 document `73682eae811b` (updated
2026-10-09 19:05:29Z), and inspected all seven requested Full modules and Export.
Acceptance files and the old trial were not edited. The separate boundary-consumer
task was not duplicated. This is procedural same-account separation, not
independent scientific certification.

## Findings

### 1. Conditional checker statement omits the demanded-declaration restriction

`lean/Full/Statements.lean:121–126` quantifies over **every** entered function
whose `checker p f.name` is true, rather than accepted demanded functions.
Unlike `Enforced` at lines 130–135, it has no declaration/demanded premise.
The approved contract explicitly permits ordinary calls to allocate.

Reproduction: `verification/ReviewCases.lean` enters ordinary, non-demanded
`ordinary(xs : List) := Cons(7,xs)` with `xs=[]`. It reports last action Enter,
`uniqueEntry=true`, and `creates=1` after advancing. All runtime premises of
Conditional hold; assigning acceptance=true to this ordinary function would
force the false conclusion `1=0`. An ordinary type-validation success is not a
zero-Create demand acceptance. This is a theorem-domain mismatch, **not** a
counterexample to an implemented checker (there is none). Add the approved
demanded-declaration restriction or explicitly resolve the meaning of the
checker's result for ordinary declarations before freezing the interface.
The entry timestamp itself correctly precedes unused-parameter release.

### 2. Helper-local ownership/protection is outside the proposed interfaces

`Statements.Reachable` (lines 9–10), F1 (19–25) and F3 (46–49) quantify only
over completed Counted ticks. `Counted.step` (438–444) hides all intermediate
StateT states. `Inspect.owners` (9–12) and `protection` (20–31) have no ownership
category for helper-local values.

Concrete boundary: immediately before Cons in `Cons(8,xs)`, with singleton
`xs=[11]` at address 5/count 1, the invariant is true. Run the actual first
helper operation `Counted.pop.run before` (`Counted.primitive:228–230`): the
invariant becomes false, owners are `[none, none]`, and the removed list operand
is still readable and required in the local variable. Equivalent transfers
occur while Enter removes slots before parameter birth (285–295), and Free
removes the old edge before pushing its tail (413–421).

This is **not observed value corruption** and does not refute the current
committed-state F1/F3. It demonstrates that proving those declarations would
leave the contract's explicit helper-inside-atomic-step requirement uncovered.
Specify an extended local-holder relation/obligation for these helper prefixes,
or split the transfers into specified microsteps. Merely labeling the outer
tick transactional does not state continuous internal protection. The retained
reproduction deliberately prints `local readable=true` to distinguish a missing
formal boundary from a fabricated use-after-free claim.

### 3. F1's event clause is narrower than the approved effects obligation

`Statements.F1:24` requires only existence of a suffix of `mem.record`.
`Inspect.invariant:46–50` equates address-only create/write/free projections to
that record. Neither states append-only call events or preservation of the full
`Counted.events` prefix and payloads (Enter frame, Return result, Create/Write
item/link). The concrete helpers appear to append events correctly, but the
proposed F1 interface does not express “appends exactly its primitive cell/call
effects.” Resolve the explicit effects relation before claiming F1 covers the
whole approved obligation. This is an encoding coverage issue, not a witnessed
bad trace in the baseline.

## Positive review and focused validation

- Plain is a genuinely separate immutable-value CEK machine; it does not read
  counted memory. Type validation checks every body/branch and resolves recursive
  signatures without body unfolding. Inputs remain integer/list; Bool is admitted
  at function boundaries. Counts/addresses are mathematical, not wrapping words.
- F2 includes initialization, forward and reverse simulation, readable answer
  equivalence and a fixed natural administrative rank. F3 adds plain-prefix
  control correspondence rather than relying only on holding flags. No concrete
  committed-state counterexample was found in the additional tests below.
- F4 checks exactly the answer/outside retained graph and absence of unfinished
  frames/reservations/cleanup. F5 includes zero, partitioning and inert terminal
  advance. F6 is universal over Trial.validStart, fixes the embedding, and compares
  complete ordered old landmark fields and primitive records, not a subsequence.
- L1 compares the entire execution by preserving the enclosing record on denial;
  L2 releases the answer and retains the outside graph with recomputed counts,
  separate cleanup and idempotence. Enforced has no uniqueness assumption and
  does restrict its conclusion to demanded declarations.
- Export's syntax-depth bound and hardcoded denial policy are adapter/fixture
  limitations, not bounds on logical F1–F6/L1–L2. Its runtime comparisons use
  `reprStr`; they are finite evidence, not kernel proofs of structural equality.
- No `sorry`, axiom, unsafe or partial implementation was found in the reviewed
  new logical modules/adapter (the search match is a documentation disclaimer).

Commands run successfully:

```sh
# From repository root:
python3 experiments/03c-checker/full/run_spec.py /tmp/full3c-verifier-evidence
# From experiments/03c-checker/full/lean:
lake env lean --run TrialCompatibility.lean
lake env lean --run ../verification/ReviewCases.lean
```

The first command built the package and passed 40 typed declarations, 16 starts,
90 exact summaries, 84 finished ledgers/answers/graphs, and its fixture-negative
checks. Its own output explicitly says boundary/lifetime/F5/lifecycle checks are
still required; do not promote this to their completion. The second passed all
28 old answers, primitive events and complete ordered snapshots.

The verifier reproduction additionally passed per-action invariant/control/rank
and final-graph checks over 300-action budgets for zero-arity forward Bool calls,
three heterogeneous arguments (answer `[-17]`), sparse addresses/shared tails,
and outside-only repeated roots. Answers were respectively true, `[-17]`, 7 and 3.
It also emitted the two boundary/domain witnesses above. This small executable
is retained only as a clearly marked reproduction, not a new acceptance corpus.

## Remaining limits / freeze recommendation

Compilation establishes definitions and proposition well-formedness, not their
truth. No universal theorem was proved, no transitive-axiom acceptance or kernel
recheck of exported proofs was possible because these are proposition definitions,
and no native Rust refinement is claimed. Additional finite language/start tests
do not exhaust recursion or valid graphs. Koka evidence remains the acceptance
author's evidence; it was not rerun here. The independently authored boundary
consumer and applicable mutation/control results still need integration/review.

**Hold exact-spec freeze** pending resolution of findings 1–3 and the outstanding
boundary/control evidence. Keep the untouched predictions and old artifacts;
return discrepancies to their authors rather than adapting expectations. No
semantic contradiction in the sampled committed executions was found, but the
current interfaces do not yet encode every approved boundary obligation.

## 2026-10-09 final integration note

The final current-package disposition is in `verification/FINAL-REVIEW.md`.
Supplemental-v2 and all 19 Controls routes pass. Verifier-owned complete internal
equality/visible-formula checks and their three corruption controls pass; evidence
is in `verification/final-results.json`. Historical findings above remain intact.
Universal lifetime proofs are future stage 1; no proof/checker work was run.
Hold proposed exact-spec freeze for the newly identified missing full-language
source-scope/ordered-observer relation, with concrete C12 Enter witness in the
final report. No current baseline semantic failure, push, freeze or approval is
claimed.
