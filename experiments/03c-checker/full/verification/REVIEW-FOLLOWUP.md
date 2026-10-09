# D186 separate verifier — follow-up

Reviewed the **current uncommitted full/** preparation, not origin/main, against
SPEC-ENCODING-BRIEF.md and live approved document 73682eae811b (updated
2026-10-09 19:05:29Z). Same-account procedural separation only. This is a
definition/interface and finite-execution review, not proof or checker work.

## Findings 1–3: resolved

1. `lean/Full/Statements.lean:125–130` now requires a declaration with
   `demanded=true`. The retained ordinary-function example still has unique entry
   and one Create, but no longer satisfies Conditional's domain. Enter still
   precedes unused-parameter release. This fixes the theorem-domain mismatch;
   it does not establish a future checker's soundness.
2. `lean/Full/Counted.lean:161` now calculates a complete `Change` from immutable
   source `s`. There is no StateT/pop or running state in which an operand has
   disappeared into a helper-local variable. Boundary covers source, installed
   transfer output, and metadata commit. F1 (Statements:19–28) checks invariants
   at those boundaries; F3 (:49–52) checks protection **and** correspondence to
   an independently begun Plain prefix there. This is a real change in the
   modeled transfer, not simply a new name for the old destructive-pop gap.
3. `Inspect.effects` independently specifies complete ordered events from source
   tasks/operands, including Enter frame and Return result, and Cons item/link.
   F1 requires exact append of those events and their cell-event projection.
   It no longer merely asks for an address-only suffix.

## Continuous lifetime and transfer internals

Read all transition branches, Control, Inspect and Statements, and the updated
Export trace path. Cons retains both source slots while computing the new memory;
its complete output transfers the tail slot to a live edge and creates the result
slot. Enter retains the source arguments until installing parameters, frame and
remaining slots together. Unique Decompose transfers the old edge to the tail
binding while installing the reservation. Shared Decompose retains the scrutinee
slot until GivePending and acquires a tail only when required. Free retains the
source live edge until installing the pending cleanup tail with the released heap.
GiveUp similarly installs the count, holder status and queued Free together.
Return keeps the result slot; its frame/event views are not additional owners.

Intermediate proposed Memory/list data are not semantic execution states and
do not replace `s`. Keeping their source reachable is the crucial distinction
from the historical reproduction. This conclusion applies to the immutable Lean
model, not a native destructive implementation or physical allocation behavior.

Slot/Binding immutable values and edge suffixes provide associated values;
readback is checked against them, not used to invent them after mutation.
Control decodes source continuations independently of holding flags and readback.
F3 requires an actual Plain prefix, not only a successful decoder or flags.
F2 fixes the initialization and step/stutter relation and administrative rank;
commit alters observation metadata only, so transfer output has the same control
as the committed successor. Thus the combined F1/F2/F3 obligations cover the
required continuous relation at every modeled state, including transfer output.
F1 alone is not the independent-control theorem. There is no new quantified
helper-state gap in this implementation. These remain unproved propositions.

Export starts its saved Plain state with Plain.begin and advances it only by
Plain.step when the decoded counted state changes, checking equality both before
and after each trace action. Decoded counted answers are not used as Plain values.
The stutter choice uses counted control, but the next Plain state is independently
computed; Inspect.trace separately checks strict rank decrease for stutters.
The finite adapter uses reprStr comparisons; they are not structural kernel proofs.

## Fresh execution evidence

All commands succeeded on this stack:

```sh
# repository root
python3 experiments/03c-checker/full/run_spec.py /tmp/full3c-followup-verifier
# full/lean
lake env lean --run TrialCompatibility.lean
lake env lean -o .lake/build/lib/lean/Export.olean Export.lean
FULL3C_INPUTS=/tmp/full3c-followup-verifier/inputs.json lake env lean ../verification/Controls.lean
lake env lean --run ../verification/ReviewCases.lean
```

- 40 typed declarations, 16 valid starts, 90 exact summaries, 84 finished
  ledgers/answers/retained graphs and all fixture-negative checks passed.
- All 28 historical answers, ordered primitive events and full ordered landmark
  snapshots passed. Historical trial files were not edited.
- ReviewCases passed its four prior focused programs (true, [-17], 7, 3) and
  checked source/output/commit invariants, source operand readability, exact
  full effects, and independent Plain step at the old Cons witness. Source
  owners were `[some 5, none, none]`; output owners were
  `[some 6, none, some 5]`. The tail owner is transferred, not lost.
- The ordinary-function witness remains recorded but is no longer a defect.

## Controls audit: 16 routes execute, with scoped conclusions

Controls ran, rather than being rejected by compilation or corrupting JSON.
JSON only supplies fixtures; faulty routes operate on logical states/memory or
accounting functions. Each of the nine transition probes requires a reached route,
a passing ordinary successor and a failing faulty successor for its named property.

| Route | Executed action / check |
| --- | --- |
| caller reservation | C1 action 16: actual wrong reservation Write instead of expected Create |
| shared reuse | C3 action 12: forced unique detach makes retained required value unreadable |
| pending holder | C3 action 8: removes older slot after Enter; decode/invariant check fails |
| suspended holder | C4 action 6: marks required caller binding givenUp and adjusts count; protection fails |
| administrative loop | C19 action 5: actual repeated Capture; rank fails to decrease |
| omitted Free | C16 action 6: skips action effects; exact event check fails |
| hidden entry copy | C8 action 10: actually creates/replaces singleton before Enter; source-derived effects reject it |
| Return payload | C7 action 23: logical event has result 1 instead of 0; exact payload check rejects |
| cell payload | C8 action 8: logical event has item 2 instead of 1; exact payload check rejects |

The remaining seven are three executed faulty counters (C7/C9/C13, correct
counts 1/1/2 versus 0/0/0), false Finish (C12 unfinished frames), restarted resume
(C19 steps 1 versus correct 18), late denial (C20-number commits step 15 instead
of preserving 14), and identity/no-op destruction (retains failed control).
These are applicable logical controls, not proof/checker mutants.

Do not overstate the coverage: pendingHolder's property tests decoder success and
the invariant, **not equality with the independently advanced Plain successor**.
Its rejection can be due to count/ownership mismatch; this run alone does not
establish the independent continuation comparison catches a count-consistent
deleted slot. SuspendedHolder does test source-required protection despite its
count-consistent dead-flag lie. skipFree tests exact effects, not a complete
branch/return/unused-parameter cleanup mutation matrix. The hidden-copy control
tests whole-step effects, not that Statements.creates itself counts a pre-Enter
event (it does not); the fixed model disallows that extra entry effect via F1.
False Finish, denial and destroy checks are intentionally narrower than full
universal F4/L1/L2. Supplemental-v2/acceptance review must not promote these 16
passes into coverage of every contract clause.

## Proposed freeze recommendation and limits

No concrete failing baseline sequence or new boundary/type/spec defect blocking
a **proposed** definition freeze was found in this follow-up. The three first-review
blockers should be closed. This is not approval to freeze the whole exact package:
the separately authored supplemental-v2 and its consumer/control integration still
need review, including the above scoped evidence limitations. The known old
supplemental whole-dictionary metadata mismatch is an interface integration issue
already returned to its author; it was not patched, bypassed or counted as passing
here. No duplicate consumer or call-history work was done.

Compilation is not a proof. Universal F1–F6/L1–L2 proofs, permitted-axiom inspection,
kernel acceptance and actual checker mutants are pending. No demand checker exists.
No proof/checker execution, push, merge, lock or freeze was performed. Only
reviewer-owned VERIFIER.md, ReviewCases.lean and this report were edited.

## 2026-10-09 final integration note

See `FINAL-REVIEW.md` and `final-results.json`. Supplemental-v2 rerun passes
820 groups/90 histories/4,591 snapshots/12 controls; current Controls passes all
19 routes, including independent pending-holder correspondence and three actual
cleanup-to-Finish mutations. New verifier checks pass 4,498 complete internal
equalities and 9,680 exact visible projections, rejecting three corruptions.
The finite hidden-field and prior control limitations are closed. Existing
F1/F2/F3 universal lifetime discharge remains stage 1, not preparation proof work.
The final review identifies a narrower new preparation blocker: no proposed
obligation relates entered scope/full-language ordered observer view to lexical
source scope (C12 Enter scalar n can be hidden without affecting F1/F2/F3 checks).
Hold proposed exact-spec freeze for that specification coverage resolution;
do not treat this as a baseline runtime failure or as proof approval.
