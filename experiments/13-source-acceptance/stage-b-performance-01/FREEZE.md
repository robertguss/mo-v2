# Approved performance implementation freeze

Robert replied **“Yes”** to freezing this separately versioned performance-only
checker and running both full resource checks under unchanged 900/600-second
limits in [the acceptance thread](https://ampcode.com/threads/T-01a11697-f670-71bc-bd5d-f6f57958fa55).

`LOCK.json` freezes the exact reviewed `fast_json.py` and `stage_b_large.py`,
explicit-selection orchestration, validation scripts, candidate and linkage.
The reviewed files' historical “proposal” headers remain unchanged to preserve
their exact bytes. This record supersedes their adoption-pending status; it does
not change scientific requirements or claim a passing resource result.

The runner explicitly supplies this verifier and decoder to the previously
validated buffered orchestration. Its default still selects revision 02. No
frozen module globals are replaced. All other predicates, schedules and resource
checks come from the unchanged original and revision-02 locks, reverified before
and after execution. Candidate source is unchanged; use the previously tested
Rust 1.98.1 locked release build and CPython 3.14.7 without experimental JIT.

Run the million-element non-tail sum first, with a full observation at its
deepest pause and then resume; run the million-element discard only after a
passing sum. The inclusive clock retains source checking, fixture installation,
execution, observations, checking, compressed evidence writes, cleanup and
process exit. The eight-MiB child stack, four-GiB provisioning floor, exact
predictions and every-record checks remain in force. Stop at the first material
discrepancy, preserving prior failures and the new attempt separately.

```sh
python3.14 stage-b-performance-01/run_resources.py NEW_EXTERNAL_DIRECTORY VERIFIED_RELEASE_BINARY
```

The runner verifies locked fingerprints, interpreter version and binary before
starting. This freeze and its execution authorization do not by themselves
authorize an acceptance claim or make PR #9 ready to merge.
