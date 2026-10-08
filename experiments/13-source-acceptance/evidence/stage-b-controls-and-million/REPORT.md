# Stage B controls and million-element runs

D171, Robert's decision to run the remaining Stage B checks on this pull request before any talk of merging, covers the sabotage controls and the two million-element runs recorded here. D172, his follow-up the same afternoon, leaves the 524 private cases with the old acceptance thread. Those private cases were not run for this record.

The candidate is the imported final-03 at `experiments/13-source-acceptance/candidate-stage-b/`. These runs did not edit it. The Stage B lock is still `2df4234fd86336b44307bee722972cf9f9c70a89b384d853db31e40d82ba5cbb`. Frozen files, expected outputs, and verdict logic were left as they are.

A control is counted as caught when three things all hold: the original example passes, the sabotaged copy marks the faulty path, and the frozen checker rejects that copy while the process keeps running. The numbers are in `summary.json`. The run is `stage_b_authorized_runs.py`.

## Controls

Caught, seven:

- **always-copy**, on C10-unique. The frozen checker rejected the sabotaged copy: full committed execution and physical state.
- **hidden-entry-copy**, on C8. Rejected: commit metadata.
- **fixture-provenance**, on both the fixture route and the literal route. Both rejected: birth coverage.
- **early-cleanup**, on C14. Rejected: commit metadata.
- **omitted-nested-create**, on C9. Rejected: commit metadata.
- **omitted-transient-create**, on C7. Rejected: commit metadata.
- **skipped-return-cleanup**, on C7. Rejected: commit metadata.

Left uncaught, two. In both, the frozen checker rejected the sabotaged run, and the throwaway copy then crashed. A crash after the rejection keeps the control out of the caught count. The submitted candidate was left unchanged.

- **caller-reservation-theft**, on C1. The checker said birth coverage. The sabotaged copy then failed an internal length check, 0 against 1.
- **early-enter**, on C11-0. The checker said commit metadata: the program entered `even` before its argument. The sabotaged copy then crashed looking up a missing value.

Not run, one:

- **omitted-entry-create**. D164, the decision that the frozen predictor never allocates on Enter, leaves this control unreachable. It stays not applicable.

## Million-element runs

Recursive sum, one million elements. The frozen limit is 900 seconds (D162, the clocks for these two workloads).

- Wall time: 68.585 seconds.
- Result: did not finish.
- The candidate started after the million-cell list was installed. The frozen sum schedule has no birth list, so the checker stopped with `NotImplementedError`. The candidate was left unchanged.

Discard, one million elements. The frozen limit is 600 seconds.

- Wall time: 73.324 seconds.
- Result: did not finish.
- The candidate started. At the 10,000th step the frozen large schedule requires a short summary. This candidate sent a full photograph, and the checker stopped with "large full-observation schedule". The candidate was left unchanged.

Neither run reached its time limit. Both stopped because the frozen checker refused what it was given.
