# Check I/O for the specification author

This is an acceptance export contract, not a prescribed Lean representation.
The prediction checkpoint remains unchanged. `check.py` is executable Python
without third-party dependencies; it does not evaluate expression trees.

## Input programs

`programs.json`, `starts.json`, and `predictions.json` are the fixed inputs.
`check.all_cases()` expands the table notation into 90 rows without executing a
program. Its row shape is `predictions.json.schema`. `check.function_table(main)`
computes the syntactic transitive declaration closure, preserving library order.
Those two helpers may be used to generate an input file; they do not calculate
expected answers. Do not select cases based on the candidate's ability to run.

Each included declaration and both its branches must validate. Resolve lexical
identities before execution as described in DERIVATIONS.md; function bodies see
parameters/locals only. Start identity letters map to the specified naturals.
For summary export, map fresh lifetimes back to N0,N1,... in Create order,
consistently across the entire run/history, never just at the final snapshot.

## Executable summary consumer

Run from this directory:

```
sha256sum -c PREDICTIONS.sha256
python3 -B check.py
python3 -B check.py --observations /path/to/formal-observations.json
```

The observation file is a JSON object keyed by all 90 expanded case IDs, exactly
once, with no omitted or additional cases. Each value has:

```
{
  "status": "finished",
  "kind": "L",
  "answer": [1],
  "rawListRoot": "N0",
  "cellEvents": ["C N0 1 -", "F A"],
  "finalCells": [["N0", 1, null, 1, "live"]]
}
```

This illustrates the expected C1 summary; it is NOT an observed run or test
result. Kinds are `I`, `L`, `B`. Answers are JSON mathematical integers,
integer arrays, or booleans; failed/suspended rows have null answers. Scalars
have null rawListRoot. Encode large integers losslessly (the Python reader
supports them; do not route through an IEEE-754-only intermediary).

`status` equals the prediction row's status string. For a nonfinished row the
suffix identifies the required tested cut/denial, e.g.
`suspended:after-7th-spin-Enter;action-29`. The adapter must establish that the
actual state is Suspended at that cut before exporting the label; merely copying
the label is not evidence. This is deliberately distinct from the formal
machine's own status representation. The evidence described below is required
to validate it.

Cell events are the full primitive cell projection, with item/tail fields read
from the committed cell operation, not filled from the expectation. Do not omit
events that occurred before demand entry or after result computation. Frees do
not erase earlier Creates. Call events are separate evidence below. `finalCells`
lists every allocated cell `[identity,item,tail-or-null,count,status]`; ordering
is ignored, no other field is ignored. It is checked only for Finished summaries.
Prefix/failure cells are checked against boundary evidence, not Finish rules.

The consumer rejects a mismatching kind/answer/root/event/order/final graph with
nonzero exit. A zero exit reports only a SUMMARY pass and still explicitly says
that boundary/lifetime/F5/lifecycle checks are required. No adapter exists yet;
the summary-observation path has not been run against a formal model.

## Required boundary export — adapter target, not implemented integration

In a separate `formal-boundaries.json`, provide entries keyed by `caseId/cut`:

* `caseId`, `cut` (the named action/occurrence from BOUNDARIES.md), `actionCount`,
  `status` (`suspended`, `finished`, `failed`, `destroyed`), current action kind.
* `cells`: all `[id,item,tail,count,live-or-aside]` entries, including zero-count
  live queued cells. `outside`: full ordered multiset of outside roots.
* `bindings`: ordered identity/origin/invocation/value/status records, preserving
  acquisition order across active and still-holding suspended bindings.
* `holders`: unique ownership records (`binding`, `operand-slot`, `pending`,
  `cell-link`, `outside`, `answer`, or `cleanup`) with identity/root and the
  independently associated plain value. `ready` and `control` aliases must
  refer to these holders without adding owners.
* `requiredValues`: independent plain-continuation obligation IDs, value,
  lifetime start/end rule, and their counted owner correspondence. Do not
  generate this list by filtering the counted machine's holding flags.
* `frames`, `reservations` including owner invocation/branch and eligibility,
  `control`, ordered `completedOperands`, `pending`, `release`, `ready`, answer.
  Preserve saved scalar operands as well as list holders.
* `evaluationEvents`: complete ordered primitive cell + Enter/Return events,
  with invocation parent, function and call-site identities. `cleanupEvents`:
  separate destruction effects. A memory-operation provenance trace must show
  that the event stream corresponds to actual cell operations, not a second
  unchecked candidate log.
* For denial: request domain/site/occurrence, pre-request committed snapshot ID,
  cause and abort order. The failed evaluation state must equal that snapshot;
  the lifecycle status/cause is separate. Number/frame gates at C20's sites must
  be explicit, not inferred from an implementation allocation counter.
* For resume comparisons: begun-state ID, exact budget sequence, complete
  histories and cumulative action counts. Supply each prefix and the matching
  uninterrupted state. Include terminal and zero-budget calls.
* For destruction: pre-state, first destroy and second destroy, including
  outside readbacks/counts, all run-owned holders/frames/reservations and both
  event streams. C14/C16 ensure a no-op destroy cannot pass C20's no-free graph.

This boundary schema lists necessary data and semantic fields; serialization of
the nested formal records is not fixed without the Lean types. The author must
publish a total, reviewable projection (including which fields are non-owning)
before the acceptance author can implement these assertions. Do not pretend the
summary consumer validates this richer export. Exact Lean declaration names,
old-trial embedding/projection and transitive-axiom inspection targets also
remain specification-author outputs.

## What has actually been checked

`checks.log`: 40 declaration types, 16 valid starts, 90 cases covering C1–C22 and
all 27 categories, 84 finished manually authored ledgers consistent with manual
answers/outside graphs. Eight malformed-fixture negative controls execute and
are rejected. These are tests of this fixture checker, NOT semantic mutants.

`consumer-unit.log` separately exercises the summary consumer with a synthetic
complete payload and rejects wrong Bool/Int representation, wrong answer,
missing Create, wrong final count, a suspended prefix labeled Finished, a
missing case and duplicate JSON keys. Synthetic data is explicitly not model
evidence; temporary payloads were removed. JSON comparisons preserve types
instead of accepting Python's `True == 1` equivalence.

The ledger consistency check applies the supplied manual C/W/F ledger to the
supplied initial item/link table. It does not execute the AST, check intermediate
reservation eligibility or derive scalar answers. It can catch an omitted Free
or mismatched final list, but not validate the semantic schedule. Rule-derived
reasoning remains in DERIVATIONS/BOUNDARIES until actual integration is run.

No new Lean, Rust, trial, plain/counting reference, proof or demand checker was
executed by this author. Koka comparison is separately recorded after the hash.
