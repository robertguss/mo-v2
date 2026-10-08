# Diagnosis of the four non-passing Stage B results

Analysis only. The candidate, the frozen files and the Stage B lock were not changed, and the long runs were not repeated. The saved rows and the frozen text are enough.

## 1. caller-reservation-theft on C1

The frozen checker caught the intended discrepancy, and the crash came afterwards in the sabotaged copy. At step 16 the commit fields match the frozen trace: Primitive result, site `function/1/body`, event end 2, landmark 6. The birth list is one short. The missing birth is the cell `one` should create (`cell` 2, origin `function/1/body`, owned by the callee). The saved event is a write of cell 1, and the caller's reservation is gone; the frozen trace still has that reservation, aside `[[0, 1]]`, and a create of cell 2. That is the theft: the callee wrote the cell its caller had set aside. The checker stops at `assert len(rows)==len(expected), "birth coverage"` in `integration.py` before it compares the reservation list. The crash is the sabotaged copy's own length check on the following Return (`aside` length 0 against the saved start 1). The driver emits a step and keeps going; it does not wait for the checker. Python had already rejected step 16. The frozen caught rule does not require the process to keep running. `stage_b_controls.py` says a control is satisfied when the baseline passes, the mutated path runs, and the named predicate rejects it. `closeoutcheck.check_control` requires `rejected_by` equal to `C1 reservation origin` and `unrelated_failure` false. It says nothing about the process staying up. The Stage A result says a later panic does not replace the first verifier rejection. The "must keep running" rule was added by this run's scorer.

Checker/spec strictness, not a candidate fault. Recommendation: count this control caught on that first rejection, and leave the candidate unchanged.

## 2. early-enter on C11-0

Same shape. The frozen step 3 is Leaf of the argument, site `main/0`, with no call event yet. The sabotaged copy's step 3 is Enter of `even` at `main`, with the frame birth, before that argument. `integration.py` rejects it at `exact(..., "commit metadata")`, which is the first comparison of transition, site, event end and landmark. That is the fault named `arguments before enter`. Public v19 states it: "Evaluate every explicit argument, left to right, including arguments the callee never uses, before entering the invocation." The crash is the next step inside the sabotaged copy: the body looks up a parameter that was never bound, and `unwrap` finds nothing. It is downstream of the rejection, not a harness crash. The frozen caught rule, cited above, does not require the process to keep running.

Checker/spec strictness, not a candidate fault. Recommendation: count this control caught on that first rejection, and leave the candidate unchanged.

## 3. Million-element recursive sum

No candidate could have passed this as frozen. At the begin snapshot `LargeVerifier.phase_begin` calls `register_births`, and that calls `workload.births()`. `DiscardedList.births` returns its one input binding. `NonTailSum` does not define `births`, so the base method raises `NotImplementedError` before any of the candidate's births are compared. The run stopped there, after 68.585 seconds, with the million-cell list installed. D162, the 900-second clock for this workload, was exercised as a projection and a record check. `STAGE_B_PREPARATION.md` says neither million-element workload ran, and the adapter runs only the discard through the large checker. The sum's state rule was compared with the small predictor at depths 0 through 8. The missing birth list was never called.

Checker/spec gap. Recommendation: add the sum's predicted birth list to the frozen workload, in the same role `DiscardedList.births` already has, and re-lock. Do not change the candidate to get past this call.

## 4. Million-element discard

The public builder documents do not tell the builder to send a summary. `BUILDER_BRIEF.md` says large runs "retain every cell event and full state at start/every 10,000 execution steps/suspend/fail/finish/cleanup boundaries," and it lists the snapshot keys as step, status, state, control, ready, release, event_end, events, births, failure, cleanup_events. It also says a large snapshot happens only at the approved checkpoints. Public v19 changes the sum's clock to 900 seconds and says the observation protocol already carries frames. It does not replace the full checkpoint with another shape. Public v20 and public v21 each say they change no schema. The summary shape lives in the frozen checker: every 10,000 steps between boundaries "is a summary", and the checker requires `observation` equal to `summary`. The acceptance stand-in emits that object. A candidate that follows the public snapshot sends the full photograph and fails that check, which is what happened at step 10,000.

Public-spec gap. Recommendation: publish the summary shape and when it replaces the full snapshot, then change the candidate. Do not treat the current full snapshot as a candidate fault.
