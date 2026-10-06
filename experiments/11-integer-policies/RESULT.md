# Integer policies: the bounded comparison passed

6 October 2026, ROB-1142. The finite Lean/Rust bridge was merged first at
`a22831f823d2ac7ccbb8726a8d4418fbceb233e0`. This experiment is delivered on
`codex/integer-policy-comparison` for review; it is not merged and selects no
Mo numeric default. Experiment 9 remains separately unmerged.

## What the result means

Checked 64-bit arithmetic stopped at overflow, wrapping arithmetic produced the
specified modular result, and big integers preserved the exact mathematical
answer. Explicit fixed/big types rejected implicit mixing and unsafe narrowing.
Both release builds matched all **12,563 frozen cases**. All four compiled broken
variants were caught. All **627 measured executions** returned the expected answer
and stayed within the experimental resource limits.

On this machine and implementation, the million-step common workloads took about
10–13 times longer for big-integer arithmetic than checked arithmetic. Checked and
wrapping arithmetic were much closer; wrapping did not improve every workload.
Big integers also incurred heap allocation during arithmetic where fixed integers
incurred none. These results support considering checked fixed integers with an
explicit big-integer option, and wrapping as a deliberate operation. This is a
recommendation for discussion, not an adopted language rule. Defaults, overflow
error delivery, resource policy and developer/agent repair behavior remain open.

## Readable behavior

`MAX` means 9,223,372,036,854,775,807; `MIN` is -9,223,372,036,854,775,808.

| Operation | Checked fixed | Wrapping fixed | Big |
|---|---|---|---|
| MAX + 1 | overflow refusal | MIN | 9,223,372,036,854,775,808 |
| (MAX + 1) - 1 | overflow refusal at first step | MAX | MAX |
| MIN / -1 | overflow refusal | MIN | 9,223,372,036,854,775,808 |
| MIN remainder -1 | overflow refusal | 0 | 0 |
| -7 / 3 | -2 | -2 | -2 |
| -7 remainder 3 | -1 | -1 | -1 |
| divide by zero | refusal | refusal | refusal |
| parse MAX + 1 as decimal text | range refusal | range refusal | exact value |

Explicit fixed values behave like the checked column; explicit big values behave
like the big column. `f:1 + b:2` refuses: first convert the fixed value with
`asbig`, then add. Converting `b:9223372036854775808` with `asfixed` refuses unsafe
narrowing. Overflow repair can therefore widen the inputs before the overflowing
step, or reject the input according to the application's requirement. Choosing
wrapping changes the mathematical contract; it is not a general overflow repair.
These are observable examples, not tested agent guidance or proposed Mo syntax.

## Timing and memory

Rust 1.99.0, aarch64 Apple Darwin, macOS 26.6.2; Python 3.13.7 reference;
num-bigint 0.4.6 and num-traits 0.2.19 with pinned transitive dependencies. Release
optimization, explicit overflow checks, `-D warnings`. The uninstrumented binary
supplies timings; a separate binary supplies allocation counts. No benchmark
was repeated to replace a sample. Ten interleaved timing repetitions for each of
57 combinations, plus one allocator run each: 570 + 57 = 627.

Tables below show one million values/steps. Times are median [minimum–maximum]
in milliseconds over ten runs. Memory is decimal MB. Complete results for 1,000,
100,000 and 1,000,000 steps, including all phase live baselines/endpoints,
cumulative requested bytes and spreads, are in
[evidence/measure-01/summary.json](evidence/measure-01/summary.json); all raw samples
and process measurements are in [samples.json](evidence/measure-01/samples.json).

“Parse” includes creating the typed input vector; total converts small integers,
parse converts decimal strings, wide converts repeated 128/1,024-bit strings.
Counter has no input vector. Setup prepares the decimal string pool, if needed.
These choices matter: this is not an optimized streaming parser comparison.

| Path | Work | Setup ms | Parse/convert ms | Arithmetic ms |
|---|---|---:|---:|---:|
| big | counter | 0.000 [0.000–0.000] | 0.000 [0.000–0.000] | 48.096 [46.995–49.541] |
| big | parse | 0.019 [0.017–0.026] | 45.604 [44.053–47.567] | 22.287 [21.501–23.623] |
| big | total | 0.000 [0.000–0.000] | 15.341 [14.903–15.905] | 22.418 [21.538–24.342] |
| big | wide1024 | 0.007 [0.006–0.013] | 613.825 [603.385–628.984] | 39.071 [38.247–42.598] |
| big | wide128 | 0.004 [0.003–0.006] | 110.157 [107.579–112.535] | 31.007 [29.362–31.669] |
| checked | counter | 0.000 [0.000–0.000] | 0.000 [0.000–0.000] | 4.877 [4.774–5.396] |
| checked | parse | 0.020 [0.019–0.028] | 3.463 [3.428–3.774] | 1.902 [0.434–1.976] |
| checked | total | 0.000 [0.000–0.000] | 0.478 [0.441–0.571] | 1.741 [1.727–1.987] |
| explicit-big | counter | 0.000 [0.000–0.000] | 0.000 [0.000–0.000] | 47.884 [47.315–51.189] |
| explicit-big | parse | 0.020 [0.017–0.031] | 45.646 [44.207–46.311] | 22.199 [21.541–22.878] |
| explicit-big | total | 0.000 [0.000–0.000] | 15.356 [14.914–16.076] | 22.288 [21.462–22.688] |
| explicit-big | wide1024 | 0.007 [0.006–0.011] | 613.628 [607.790–628.975] | 38.755 [38.210–44.297] |
| explicit-big | wide128 | 0.004 [0.003–0.007] | 109.470 [107.331–114.490] | 31.110 [29.461–33.383] |
| explicit-fixed | counter | 0.000 [0.000–0.000] | 0.000 [0.000–0.000] | 4.994 [4.812–5.287] |
| explicit-fixed | parse | 0.019 [0.017–0.023] | 3.555 [3.412–4.551] | 1.899 [0.443–2.051] |
| explicit-fixed | total | 0.000 [0.000–0.000] | 0.521 [0.458–0.568] | 1.811 [1.735–2.129] |
| wrapping | counter | 0.000 [0.000–0.000] | 0.000 [0.000–0.000] | 4.914 [4.738–5.237] |
| wrapping | parse | 0.019 [0.017–0.024] | 3.511 [3.302–3.729] | 1.571 [1.495–1.692] |
| wrapping | total | 0.000 [0.000–0.000] | 0.620 [0.552–0.666] | 1.458 [1.405–1.622] |

| Path | Work | Arithmetic alloc/realloc calls | Arithmetic cumulative requested MB | Absolute peak live requested MB | Maximum timing-process RSS MB |
|---|---|---:|---:|---:|---:|
| big | counter | 1,999,999 | 40.000 | 0.001 | 1.720 |
| big | parse | 999,999 | 8.000 | 41.589 | 52.134 |
| big | total | 1,000,000 | 8.000 | 64.001 | 65.929 |
| big | wide1024 | 1,000,001 | 136.000 | 161.556 | 164.577 |
| big | wide128 | 1,000,001 | 24.000 | 57.555 | 68.157 |
| checked | counter | 0 | 0.000 | 0.001 | 1.638 |
| checked | parse | 0 | 0.000 | 8.423 | 11.960 |
| checked | total | 0 | 0.000 | 8.001 | 9.683 |
| explicit-big | counter | 1,999,999 | 40.000 | 0.001 | 1.720 |
| explicit-big | parse | 999,999 | 8.000 | 41.589 | 52.118 |
| explicit-big | total | 1,000,000 | 8.000 | 64.001 | 65.913 |
| explicit-big | wide1024 | 1,000,001 | 136.000 | 161.556 | 164.577 |
| explicit-big | wide128 | 1,000,001 | 24.000 | 57.555 | 68.125 |
| explicit-fixed | counter | 0 | 0.000 | 0.001 | 1.638 |
| explicit-fixed | parse | 0 | 0.000 | 8.423 | 11.960 |
| explicit-fixed | total | 0 | 0.000 | 8.001 | 9.683 |
| wrapping | counter | 0 | 0.000 | 0.001 | 1.638 |
| wrapping | parse | 0 | 0.000 | 8.423 | 11.960 |
| wrapping | total | 0 | 0.000 | 8.001 | 9.683 |

Explicit fixed and explicit big use exactly the same homogeneous benchmark
functions as checked and big respectively; type selection happens before the
loop. Their small timing differences are measurement variation, not evidence
about the cost of explicit typing or dynamic tagged values. The semantics checker
separately exercises tags and conversions.

Big integer addition here constructs a result each step; this experiment does not
compare in-place BigInt accumulation, other BigInt libraries or optimized Mo
code generation. Allocation counts and relative speed are properties of these
workloads and implementations, not inherent lower bounds. No language-wide speed
claim follows. Peak requested bytes count driver-owned heap buffers too, exclude
stack/libc allocations, and are distinct from whole-process RSS. Reallocation
counts requested new layouts; it does not measure allocator internal transient
peaks. Cumulative requested bytes are not retained bytes.

All 18 fixed-path/size/wide-input combinations refused with `err range`; they are
recorded separately in [fixed-wide-refusals.json](evidence/fixed-wide-refusals.json)
and never scored as successful fast execution. Every instrumented run restored
the measured allocation baseline after discarding benchmark data, subtracting
the still-retained answer string's allocation. Known 64-byte allocation,
128-byte reallocation and free calibrated exactly: two requests, 192 cumulative
bytes, 128 extra peak bytes, restored live baseline.

## Verification, controls and scope

The contract, Python exact-integer reference, expected corpus, dependency lock
and toolchain record were frozen in commit `955187b` before Rust implementation.
All LOCK.json fingerprints still match. Python and Rust are separate
implementations, but **the same author wrote both** under Robert's current
self-verification instruction. This is not independently authored acceptance.
Finite boundary grids are not a universal integer implementation proof.

Both timing and allocator builds passed 12,563/12,563 cases. Four variants compiled
successfully and failed against unchanged expectations:

| Broken implementation | Observed counterexample |
|---|---|
| Saturate instead of wrap addition | MIN + MIN should wrap to 0; returned MIN |
| Wrap instead of reject checked overflow | MIN + MIN should refuse; returned 0 |
| Silently replace unsafe narrowing with 0 | big MIN-1 narrowed to fixed 0 |
| Permit mixed fixed/big arithmetic | fixed 1 + big MIN-1 returned big MIN instead of refusing |

Each mutated source, successful build log, complete output and counterexample is
retained under [evidence/controls-01](evidence/controls-01). Cases, controls and
measurement ran without semantic mismatch in the correct baseline, uncaught
control, timeout or resource-cap breach. Experimental caps were 30 seconds per
subprocess, 512 MiB instrumented live requested bytes and 2 GiB observed RSS.
They do not define future Mo resource behavior.

Initial dependency-lock setup failed because the not-yet-implemented package had
no target declaration; adding the explicit target path repaired setup before
freezing. No expected value was changed. A final cleanup-comment correction was
rebuilt in both modes; both executable SHA-256 values remained byte-identical to
the measured binaries (evidence/build-02/identity.json). No timing rerun was needed.
Prior experiment files were unchanged and the finite-bridge manifest reverified.
The unrelated local CLAUDE.md edit is excluded.

Reproduction (use a fresh evidence destination for each execution):

```sh
RUSTFLAGS='-D warnings' CARGO_TARGET_DIR=target/timing cargo build --release --locked
RUSTFLAGS='-D warnings' CARGO_TARGET_DIR=target/allocator cargo build --release --locked --features measure
python3 check.py cases target/timing/release/integer-policies evidence/new-cases
python3 check.py cases target/allocator/release/integer-policies evidence/new-allocator-cases
target/allocator/release/integer-policies calibrate
python3 check.py measure target/timing/release/integer-policies target/allocator/release/integer-policies evidence/new-measure
```

Run from this experiment's directory. `controls.py` uses its own fixed first-run
evidence destination; reproduce it in a disposable checkout without that retained
directory, preserving this original evidence. The report's summary is derived by
grouping raw samples by policy/work/size, taking each phase's median/minimum/maximum
across ten timing repetitions, and carrying the single allocator sample unchanged.

Primary API references: [Rust i64 checked/wrapping operations](https://doc.rust-lang.org/std/primitive.i64.html)
and [num-bigint 0.4.6](https://docs.rs/num-bigint/0.4.6/num_bigint/).
No floats, financial decimal policy, agent study, universal proof or production
runtime claim is included. Stop here for review and remaining Needs Input discussion.
