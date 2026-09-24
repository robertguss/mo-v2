# Experiment 3 setup review

Yes. The setup can give a misleading answer. Findings below distinguish scoring bugs from experimental controls that are missing before the builder starts. Paths are relative to `experiments/03-in-place`.

## 1. The 2× threshold is applied after rounding

- **Severity:** misleading
- **Claim:** A
- **Where:** `acceptance/measure.py:199–200`.
- **What's wrong:** The script rounds the ratio to three decimal places and then compares it with 2.0. A measured ratio of 2.0004 becomes 2.000 and passes, contrary to the “no more than 2×” rule in `ACCEPTANCE.md:48–50`. This is a narrow but real false pass.
- **Concrete fix:** Compare the unrounded medians directly (`koka_median <= 2 * rust_median`). Round only the displayed ratio.

## 2. A failed strict compilation can be reported as ten strict successes

- **Severity:** misleading
- **Claim:** D, the required strict-demand report
- **Where:** `acceptance/measure.py:146–159`.
- **What's wrong:** The strict compiler's exit status is discarded. Each function is reported as passing strict `fip` merely because its relaxed marker was found and no matching strict warning was found. A strict build that exits with an error before producing those warnings is therefore reported as successful. This does not change the relaxed 7/10 score, but it corrupts the strict result required by `ACCEPTANCE.md:85–87`.
- **Concrete fix:** Retain the strict exit status and require a successful strict build before reporting any strict success. Report failed compilation as unavailable/error, retaining its diagnostic, rather than treating absence of warnings as proof.

## 3. The allocator equality needed for claim A is not established

- **Severity:** misleading
- **Claim:** A
- **Where:** `ACCEPTANCE.md:33`, `briefs/builder.md:36–37`, and `acceptance/measure.py:101–113,180`.
- **What's wrong:** The Rust baseline only has to enable a feature using the `mimalloc` crate. No native mimalloc release or build configuration is required to match Koka's. The reported version is the first Rust wrapper-crate version found in a Cargo lockfile; the script obtains no corresponding Koka allocator version. Matching the allocator family name does not establish that both programs use the same allocator implementation/configuration. A compliant builder can choose a different release without violating these instructions, so an allocation-sensitive ratio can include that difference.
- **Concrete fix:** Before building, identify and record Koka's native allocator release and relevant configuration. Pin Rust's native allocator dependency to a matching implementation/configuration and verify that the allocator feature actually selects it. Record both native versions and the Rust wrapper version separately. If exact matching is unavailable, state that limitation and resolve it before scoring a claim explicitly conditioned on allocator equality.

## 4. Same container does not constrain the work enough for a causal comparison

- **Severity:** misleading
- **Claim:** A
- **Where:** `ACCEPTANCE.md:20–23,32–34` and `briefs/builder.md:25,32–38,59–65`.
- **What's wrong:** The two sides must use linked lists and red-black trees, but their algorithms are not fixed. For example, top-down and bottom-up red-black insertion can both be competent, correct implementations while doing different searches, recolorings, and rotations. Neither the output checks nor the “competent Rust programmer” rule requires equivalent work. A builder can choose different legitimate algorithms on the two sides and change the ratio without breaking the brief. That ratio then measures an algorithm choice as well as the in-place technique.
- **Concrete fix:** Freeze shared algorithm descriptions before implementation, particularly the red-black insertion/balancing procedure. Require corresponding traversals, arithmetic, validation work, and cleanup responsibilities on both sides. Have the lead review those correspondences before timing. Keep independently idiomatic alternatives as separately labelled extra data.

## 5. The extra-holder variant does not prove that an extra holder survives the update

- **Severity:** misleading
- **Claim:** B
- **Where:** `ACCEPTANCE.md:62`, `briefs/builder.md:26–31`, and `acceptance/measure.py:204–212`.
- **What's wrong:** The intended treatment is an additional live holder, but the suggested observation is only the original value's length. That observation does not need the original contents: it can in principle be computed before the updates, allowing the original value to be released. The scoring script checks output and time, not whether the alias survives. A source-level extra variable alone cannot establish the runtime condition being tested. There is also a direct protocol conflict: printing an extra length after the work, as suggested, violates the builder's requirement to print exactly the original expected lines. A correct treatment can consequently be labelled output-incorrect, or a treatment optimized away can look reassuringly cheap.
- **Concrete fix:** Define a separate expected output for this variant that observes the retained original contents after the transformed result has been computed. Inspect generated code or use suitable allocation/reference-count instrumentation to verify the intended overlapping lifetimes. State which snapshot is retained and over which rounds, including what this means for tree insertion, so the reported slowdown has a precise interpretation.

## 6. The ordinary-call test has an independent reason to warn

- **Severity:** misleading
- **Claim:** C
- **Where:** `acceptance/claim-c/bad-calls-normal.kk:2–6`, `ACCEPTANCE.md:125`, and `acceptance/measure.py:121–125`.
- **What's wrong:** `add-marker` both calls an unmarked helper and constructs the fresh list `[0]`. That new list cell is already an allocation with no explicitly dismantled cell available in the caller. The scorer accepts any `fip` warning in the file. Thus a warning about the list literal alone can make this test pass even if detection of the ordinary call is absent. The test establishes that this combined example warns, not that the checker detects the particular ordinary-call problem it is meant to exercise.
- **Concrete fix:** Remove the independent allocation from the caller, for example by taking both list arguments as parameters, and isolate the unmarked helper call. Retain and check the full diagnostic for the intended violation, with a matched accepted control that changes only the helper's demand/implementation. Do not count an unrelated warning as evidence for this case.

## 7. Every version occupies a different uninterrupted timing block

- **Severity:** misleading
- **Claim:** A and B
- **Where:** `acceptance/measure.py:58–67,186–191`.
- **What's wrong:** Sorting builds and running all repetitions of each executable consecutively places the Koka baseline, Koka variants, and Rust baselines in separate fixed-order blocks. Any sustained change in machine temperature, power state, or background load is confounded with version. Ten measurements inside each block and “nothing else heavy running” do not remove that confound. A ratio near 2× can cross the threshold because of run order; a variant's apparent slowdown can have the same problem. This is a design risk, not evidence that this Mac has already produced biased timings.
- **Concrete fix:** Run comparisons in interleaved rounds, using a recorded randomized or counterbalanced order, with consistent warm-up policy and power conditions. Preserve chronological order in the raw data. Review instability before declaring a threshold result; do not infer a particular M3 Max scheduling or thermal failure without measurement.

## Checks and limits

I read all files requested by the brief, including all twelve claim C programs and both claim D files. Every SHA-256 entry in `LOCK.md` matches its current file. Independent in-memory Python calculations reproduced every expected benchmark output, including the running-total results using binomial weights for repeated prefix sums.

The rounding example above was checked directly. An in-memory probe of the actual claim D scoring body, replacing only compilation with synthetic outcomes, supplied a successful relaxed run and a strict exit status of 1 with an error and no warnings. It reported all ten functions as passing strict `fip`. This verifies the scoring defect; it is not a real Koka compilation result.

I did not run the experiment or compile the Koka fixtures, because compilation would create files other than this verdict. I therefore do not claim that a specific fixture actually emits a particular diagnostic, or that any measured performance or allocator mismatch has already occurred. No files other than this verdict were created or changed.
