# Approved collector implementation freeze

Robert replied **“do it”** to reviewing and approving this collector replacement,
freezing it and retrying the full resource workloads in
[the acceptance thread](https://ampcode.com/threads/T-01a11697-f670-71bc-bd5d-f6f57958fa55).
This record adopts the already-tested bytes. Their historical proposal headers
and the prior evidence remain unchanged; this freeze supersedes their pending
adoption status, not their recorded results or limitations.

Review confirms that full observations and raw output are unchanged. Recursive
normal serde deserialization preserves validation of unknown/duplicate values;
the validated-byte equality fast path falls back to the original semantic
comparison. Moving owned output values removes copies without changing fields.
Dependency versions/checksums and serde_json features match the tested build.
The three inherited strict-Clippy lints are unchanged style/type-complexity
findings, not new semantic failures. This is same-author review, not an
independent new review or proof of universal equivalence.

The tested Rust 1.98.1 locked release binary is
`cb2045431f7086a6a63c47e5e7f4b5a1beabeb2fe08fef1557280f9220dee72a`.
The new `LOCK.json` pins this collector, linkage, validation tools/reports and
explicit-selection runner. The previous performance lock remains unchanged and
is checked transitively with the original and revision-02 locks. Candidate,
native cells/runtime, checker, decoder and scientific requirements are unchanged.

Run the million-element non-tail sum first, pausing at its required deepest full
observation and resuming to completion, under the unchanged **900-second**
inclusive clock. Only after a passing sum run the million-element discard under
the unchanged **600-second** clock. Source checking, fixtures, all observations,
every-record verification, compressed evidence writes, cleanup and process exit
remain timed. The eight-MiB child stack, four-GiB provisioning floor, predictions
and all other checks remain unchanged. No orb memory limit is raised.

The new runner explicitly selects the already-frozen performance verifier and
decoder with the tested collector binary. It does not modify module globals or
the old runner's default. Infrastructure preflight records effective cgroup and
disk availability; disk headroom is not a new scientific acceptance predicate.
Stop at the first material failure. Preserve all prior failures and this attempt
separately, without repairs or retries under the same attempt identifier.

This freeze authorizes execution, not a passing acceptance claim, merge or
deployment. No private cases or real evaluator controls are newly authorized by
this resource-run step.
