# Integer policies — ROB-1142

Authorized comparison under D125; no Mo numeric default is selected. Same-author
implementation and checks under the current owner preference. Freeze this contract,
Python exact-integer expectations/checks, dependency lock and toolchain identity
before Rust implementation. Prior experiments remain unchanged.

## Four policies, five homogeneous execution paths

- checked: signed i64, refuse out-of-range input and overflowing arithmetic.
- wrapping: signed i64, refuse out-of-range input; arithmetic wraps modulo 2^64.
- big: signed arbitrary-size integers via pinned num-bigint 0.4.6.
- explicit: fixed (f) and big (b) types; fixed arithmetic is checked. Binary mixed
  types refuse with type_mismatch. asbig widens; asfixed refuses unsafe narrowing.
  Benchmarks select homogeneous fixed/big types before their loop. They measure
  these two representations, not a tagged union dispatch overhead or agent burden.

All policies parse ASCII decimal with optional +/-, at least one digit; no spaces,
separators, decimal point or exponent. Negative zero becomes zero. Invalid text
is invalid_literal; representable syntax outside i64 is range. No implicit input
wrapping. Divide by zero is always divide_by_zero. Division truncates toward zero;
remainder is a - trunc(a/b)*b and follows the dividend's sign. For MIN/-1 checked
and explicit-fixed division AND remainder report overflow (Rust checked API
contract); wrapping returns MIN for division and zero for remainder; big is exact.
Negating MIN checks/wraps/grows according to policy. Cancel computes a*b then /b;
roundtrip computes a+1 then -1, with policy applied at each step, not just the final
answer. Explicit conversions are the only way to mix widths. Big input cases use
128 and 1,024 bits; arbitrary-size does not promise infinite resources.

Compare boundary grids, common representable cases, invalid input, signed
arithmetic and intermediate overflow to the Python exact integer reference. Check
both sides of 2^31/2^32 and signed i64 boundaries, narrowing and explicit mixing.
Run real compiled source controls: wrong wrapping, unchecked overflow success,
silent narrowing, mixed-type arithmetic accepted. Control build failures are not
successful catches. Stop and preserve evidence on disagreement or unspecified
outcomes; do not retune expected results. Setup/build failures may be repaired.

## Measurement protocol

One Rust driver, same System allocator. Three common workloads: running total of
(i%1000)+1; decimal parsing/aggregation of i%1000; bounded counter update
(x*1664525+1013904223)%1000003 starting at 1. n is 1,000 / 100,000 / 1,000,000.
Two additional parsing/aggregation workloads repeat fixed positive 128-bit or
1,024-bit decimal input 2^(bits-1)+17. Fixed paths refuse these inputs; that refusal
is reported separately and never scored as faster successful computation.

Separate setup, parsing/conversion and arithmetic phases. Setup prepares a pool of
1,000 decimal strings or the one wide string; parsing materializes n typed values;
arithmetic consumes those values. Running total also materializes n typed values
from small integers; counter uses n loop steps and no input vector. Keep those
choices visible: results do not compare an optimized streaming parser or every
BigInt implementation. Every final answer checked against Python expectations.
Use black_box on loop inputs/results to retain work.

Ten deterministically interleaved repetitions for every successful path/workload/
size, retaining every sample, median and spread. Uninstrumented release binary for
timing; separately compiled instrumented release binary for one allocator sample
per combination. Allocation/reallocation request count, cumulative requested bytes,
phase baseline/end live requested bytes and absolute peak live requested bytes
are distinct from whole-process peak resident bytes measured by macOS time -l.
Allocator measurements include driver-owned buffers; no libc/stack memory claim.
Realloc accounting uses requested layouts, not internal allocator transient peaks.
Verify instrumentation with known allocate/reallocate/free operations before runs.

Per subprocess: 30-second timeout, 512MiB requested-live ceiling in instrumented
runs, observed 2GiB process RSS ceiling; refuse >1,000,000 workload steps. These are
experimental limits, not future Mo policy. A timeout or cap breach is a failed
measurement, not a valid fast result. No repeated retries or sample deletion.

Pin num-bigint/num-traits and transitive versions in Cargo.lock, compiler/target,
release options and source identities. Reference sources:
https://doc.rust-lang.org/std/primitive.i64.html (checked/wrapping operations)
https://docs.rs/num-bigint/0.4.6/num_bigint/ (arbitrary integers)

Report correctness, observations, examples of refusal/repair choices and limits.
No floats, financial decimal policy, language-wide speed claim or agent-usability
claim. Deliver pushed reviewable branch, no automatic merge or next experiment.
