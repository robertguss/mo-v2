# ROB-1139 expanded acceptance follow-up

**820 check groups pass, zero fail. No semantic discrepancy found in the
executed finite checks. All 90 full predicted event histories matched on their
first comparison. This is not a scientific freeze or universal proof.**

This directory alone is the new acceptance-author work. Original predictions,
original handoff, and all six first-supplemental files are unchanged. The parent
owns the extracted Lean and adapter sources; this author only read them.
Same-account procedural authorship is the claim, not technical isolation.

## Inputs, prediction recording and reproduction

The evidence is the parent's **uncommitted expanded encoding**, not origin/main.
Its approved public baseline remains the one in the original DERIVATIONS.

| Uploaded archive | SHA-256 |
|---|---|
| `full3c-spec-expanded.tar.gz` | `1a64beccdf6909694c1108034f325ac7ba1ce5d8912d788d6e9edf2cc5f0b97d` |
| `full3c-observations-expanded.tar.gz` | `3bd0de348e764ded21f86e0a7eb043f8d62858dbafa57a8e80c05dbbfe47a7ef` |

Before comparing expanded event histories, `call_predictions.py` and its
`expected-events.json` expansion were recorded at **2026-10-09T20:09:40.345744Z**
in `CALL-CHECKPOINT.txt`. This is an additional prediction record, not a rewrite
of the original pre-model checkpoint. This author had already read the earlier
C-case outputs and expanded schema/control examples, but did not read the new
usefulness event histories to derive expectations. No new model was executed.

The 55 additional histories are finite handwritten call trees from the original
typed programs and derivations. Each node fixes function, raw arguments, result
and nested calls. Integer leaves place an exact number of unchanged checkpoint
cell events between specified calls/returns. They do not evaluate the AST or
consume observations. All 35 C histories reuse the unchanged first-supplemental
predictions; C22 remains the paired C12/C13 comparison.

Examples of independent derivation:

* `merge`: comparisons −3≤−1, 4>−1, 4>2, 4≤8 give argument chains
  `(A,D) → (B,D) → (D,E) → (E,F) → (Nil,F)`. The newest reservations hold the
  reconstructed nonselected heads. Return roots are F,E,D,B,A, with the exact
  preparatory/unwind Writes already in the original ledger.
* `sort`: preserve the earlier singleton while sorting the tail. Inserting 5
  into [1] takes the recursive else branch, reconstructing singleton C; inserting
  −2 into [1,5] takes the nonrecursive then branch. This fixes every insertCell
  Enter/Return and places all nine original Writes.
* `twice` and `both`: argument evaluation finishes before append Enter. The first
  shared bump returns N1; its two Creates remain inside the enclosing invocation.
  `both` then uniquely rebuilds A/B before appending N1 onto A.
* Empty/singleton trees fix the base-case calls rather than merely predict zero
  events. Examples: reverse always enters revAcc; singleton rotate reconstructs
  A before append(Nil,A); singleton sort calls sort(Nil) before insertCell(A,Nil).

Run from `experiments/03c-checker/full/acceptance`:

```sh
python3 -B supplemental-v2/check_expanded.py /path/to/expanded-observations --report /tmp/results.json
python3 -B check.py --observations /path/to/expanded-observations/summary.json
sha256sum -c PREDICTIONS.sha256
sha256sum -c MANIFEST.sha256
sha256sum -c supplemental/INVENTORY.sha256
sha256sum -c supplemental-v2/INVENTORY.sha256
```

Only Python 3 and the unchanged sibling acceptance files are required. The
consumer reads `inputs.json`, `raw.json`, `summary.json` (the last for its hash;
the original summary consumer performs its validation). It never invokes Lean,
Koka, trial, a demand checker, an interpreter or a mutant. Exit zero means the
listed finite checks passed; limits below remain. `results.json` records every
check, precise coverage and input hashes. `verification.log` records execution.
`SOURCE.sha256` inventories the expanded parent source, relative to acceptance/;
all source files were byte-compared with the uploaded archive. The old
supplemental SOURCE inventory intentionally still describes the old archive.

## Expanded evidence closes the named finite gaps

| Obligation | Executed evidence |
|---|---|
| Full trace coverage | All 90 exact input programs/DAGs; **4,591 committed/begun/failure snapshots**, all checked with unchanged first-supplemental inventory, multiplicity, readback, identity, effect and frame assertions. |
| Complete usefulness histories | **90/90 exact interleaved Enter/Return/Create/Write/Free histories**, with raw arguments/results and invocation parents. Every call also checks a source call site and types. Original 90 summary checks pass, covering C1–C22 and all 27 categories. |
| Pre-commit boundaries | **4,498** transfer boundaries checked. Old history/count is retained until commit; every exported semantic/control/ownership/effect field equals the resulting committed field. Counts/readability/protection are checked at the internal boundary too. |
| Independent Plain carrier | **3,008 step** transitions equal supplied Plain.next; **1,490 stutters** preserve Plain and strictly decrease a natural rank; **3 denials** preserve both executions. The Plain carrier cannot reset between adjacent snapshots. The source exporter carries Plain from Plain.begin and applies Plain.step, rather than replacing it with decode. |
| Newest eligible reservation | **126 Cons** operations check executing invocation, static Cons site, independently tracked lexical branch stack and newest eligible branch ID; **7** have multiple eligible reservations. All effect payloads/readbacks match operands and the checkpointed event ledger. |
| C19 | All **8 budget groups / 21 segment comparisons** check full split/whole states, actual statuses/raw results, repeated observation outputs and afterObservation state. Budget17 is Suspended; budget18 finishes immediately; terminal 0/1/23 is inert in these pure exports. |
| C12 | Actual 29+4 split equals advance33 in complete state. It adds only Dispatch/Leaf/Capture/Enter8, stays Suspended, retains eight scalar0 parameters/frames, and has no cell/Return/result. |
| C16 | Actual resumes from cuts **5,6,7,8** equal the full uninterrupted finished state and append exactly the remaining F events. First/second destruction at each cut is equal; cleanup lists are `[A,B]`, `[B]`, `[B]`, `[]`, with evaluation events unchanged. |
| C20 | Full pre-denial and failed execution records are equal for all three gates. Admitted request prefixes, domain/site/ordinal1 and abort order match the source-derived expectation. Successful control records frame outerFail, number add, frame one, cell one, frame choose. |
| Double destruction | Actual first/second lifecycle states compared for all **90 final cuts**, plus four C16 paused cuts: destroyed flag, answer removal, retained failure/request history, exact outside-only graph/counts, separate cleanup and idempotence. |

The first-supplemental checks are reused via a projection dropping only newly
added fields. The new fields are checked separately. For pre-commit snapshots,
the reused checker needs committed metadata solely to classify an answer holder;
a copy receives the post-step history/count after the original pre-commit
history/count and all nonmetadata fields have been checked. No ownership field
is altered or synthesized for that check.

Lean Repr layout is not semantic data: wrapping a Plain state in Except.ok
changes its pretty-print line wrapping. The initial consumer therefore had 67
formatting mismatches. Only whitespace **outside quoted strings** is normalized
for cross-representation Plain comparisons; all quoted contents and tokens
remain exact. The original failure count and a representative actual/expected
pair are retained in `consumer-development.json`. No prediction changed.
Full lifecycle/resume `completeState` strings still compare byte-for-byte.

**12/12 negative export-consumer controls are rejected**, with reasons recorded:
reset Plain carrier, nondecreasing stutter rank, missing internal operand,
forged active branches, choosing an older eligible reservation, changed hidden
resume state, changed observer state, duplicated second-destroy cleanup,
evaluation during pause destruction, restarting spin, wrong usefulness argument,
and changed pre-denial hidden state. The untouched positive data passes first.
These are corrupted observation objects, **not executed machine mutants**.

## What remains unestablished and what evidence is still necessary

The supplied evidence is sufficient for the **named finite C12/C16/C19/C20
comparisons and all 90 predicted call/cell histories**. No extra cases or export
changes are needed to rerun those passes. No English contradiction or semantic
discrepancy was exposed. Stronger claims still need the following:

1. **Full independent lifetime correspondence:** `requiredBindings` still comes
   from counted taskUses. It is checked at every exported boundary, with separately
   carried Plain correspondence and independent selected source-owner assertions,
   but this does not enumerate independent Plain obligation IDs, lifetime rules
   and their bijection to every counted binding/operand/edge. Supply that relation
   or have the verifier establish it from the definitions before claiming the
   original complete F3 obligation discharged. The finite pass is not that proof.
2. **All hidden internal metadata:** pre-commit exports omit `completeState`.
   The 20 structured/Repr projection fields are compared; hidden next-ID counters,
   entered scopes, edge-association table and landmarks are not directly compared
   at those internal cuts. For a full-field consumer claim, export them (or a
   complete internal state) and the specified metadata-only commit projection.
   The read source installs complete immutable transfers and commit only changes
   steps/history/landmarks; that source observation is not an executed comparison
   of omitted fields.
3. **Complete ordered active-scope view:** visible IDs are unique/acquisition
   ordered and contain all holding bindings; C18's exact suspended/entered view
   and selected identities pass. A separately derived entire entered-scope view
   at every cut is not reconstructed. `entered`/resolved scope correspondence
   should be exposed or checked by the independent verifier for that claim.
4. **Universal correctness/native fidelity:** neither separately carried Plain
   nor rank descent on these finite traces proves F1–F6/L1–L2 or recursion/checker
   soundness. Plain.next/decode are parent-authored definitions, not independently
   reimplemented here. No universal backward simulation, termination result,
   kernel/axiom audit or native allocator/observer fidelity follows. The pure
   repeated-observation check only checks the pure mathematical observer.
5. **Remaining scientific work belongs elsewhere:** the parent owns actual
   machine-mutant execution and the separate verifier. Later checker verdicts,
   proof exports and their audit remain future work. Parent-reported 28 complete
   trial landmark comparisons were not rerun by this author. Definition changes
   to Boundary/F1/F3/Conditional were read, not certified as theorems.

**Further evidence is necessary before a scientific freeze**, particularly for
the independent lifetime/ordered-view claims and proofs above. These are not
reported as failures of the finite examples or as newly discovered model bugs.
No proof, machine encoding, demand checker, or historical/private artifact was
authored or altered by this acceptance follow-up.

## Delivery

`rob1139-acceptance-boundaries-v2.tar.gz` at the workspace root contains only this
new directory. Extract from the repository root. `INVENTORY.sha256` is relative
to acceptance/ and excludes itself. The archive excludes parent source, input
archives, old acceptance files, binaries and build products. Exact archive and
inventory hashes are in the final handoff. Nothing was committed, pushed or
merged; the parent must transfer the archive.
