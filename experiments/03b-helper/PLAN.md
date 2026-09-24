# Experiment 3b: the in-place helper, built in Rust

**Status: approved by Robert on 23 Sep 2026 (D68).** The lead drafted it and
Codex reviewed it the same day (its review is summarised below). Also decided:
what 3b's result means for 3c (D66) and claim A's speed budget (D67). The
acceptance file and measuring script need their own review and approval
before locking.

## Where it comes from

D42 (the follow-on plan after Experiment 3) says 3b builds the in-place helper
in Rust, counted values that are copied only when shared, on the same four
benchmarks, compared with Koka's numbers; and that 3c, a toy pure language
with a checker for in-place demands, runs "only if 3b looks promising"
(that gate is superseded by D66: 3c runs regardless). D63
(reading 5 of Experiment 3's result) adds one bounded repeated-sharing case to
3b.

## The question

Can hand-written Rust implementations of the four benchmark algorithms use
reference-counted copy-on-write (a value with one holder is updated in place;
a value with more is copied) while preserving old values and meeting the
agreed speed target?

Said carefully: "without Mo-specific compiler analysis", not "with no compiler
analysis". Rust still checks ownership and optimises, and the builder places
the moves, retains and updates by hand. 3b tests a runtime technique used
correctly by hand-written programs. It does not show that Mo can generate such
programs automatically, or enforce demands. Automatic generation remains
future compiler work; 3c investigates demand enforcement within its defined
toy-language scope.

Why it matters: Mo has to implement D26 (fully pure, with invisible in-place
updates) itself. Compiler reuse analysis (Perceus in Koka, similar in Lean)
and runtime uniqueness checks are not rival routes; Koka and Lean combine
both. 3b measures what the runtime part alone, used well by hand, can do.

## Tools (D64)

- **Rust** (1.98, Homebrew): `Rc` with `make_mut`. Single-threaded counting
  only; concurrency, atomic counting and `Arc` are untested and stated as a
  limit. No weak references, so "one holder" means one strong holder and
  nothing subtler.
- **Same container and same mimalloc** as Experiment 3, for continuity with
  its same-container Rust baseline.
- **Koka** (3.2.9) re-run on the same day and machine as the reference for the
  compiler-built version, not numbers reused from Experiment 3. All timing arms
  interleaved.
- What the comparison can isolate: within Rust, same container, same
  allocator, the combined overhead of the counted representation and its
  implementation against plain ownership. Count headers change allocation
  sizes and layout, so it does not isolate counting instructions alone.
- What it cannot isolate: Koka-vs-Rust compiler and runtime differences;
  whether a checker can keep values unique (3c).

## Claims (draft)

| Claim | What it says | How it's measured | Passes when |
| --- | --- | --- | --- |
| A | The helper meets the agreed runtime budget on these four workloads (D67). | Benchmarks 1–4 in helper-Rust against edit-in-place same-container Rust, both with mimalloc. Koka on the same day as extra data. | On each benchmark, the helper's median is no more than 2× the edit-in-place median, compared unrounded (D67). No aggregate decides; spread is reported; any repeat-measurement procedure is fixed before running. Koka ratio recorded, no threshold. |
| B | Measure repeated-sharing costs in this case (D63). | One list case: keep the previous version live while building the new one, read both, release the old before the next round. Sharing against no sharing within each implementation; helper against Koka with the same retention. Time and memory. | Observational, with validity gates: correct outputs, retention verified in compiled code, measurements named for what they count (allocation events are not copy counts), bounded memory. |
| C1 | The helper preserves values in the specified fixed and generated tests: no holder sees another holder's update. (The intended property is D26's promise in general; these tests check it only within their stated domain.) | Property tests over generated sequences of hold, update, read and drop, comparing every live value against a copying reference model after every operation. Fixed cases: a unique update gives the expected value; a shared update changes the chosen version and preserves the other; dropping the other holder restores reuse; two roots sharing a tail, updated through one, preserve the other. Failing seeds and sequences are kept. | Every generated and fixed case matches the reference model. A planted helper that mutates through a shared holder (a safe mutant with defined behaviour, not invalid aliasing) must fail. |
| C2 | A uniquely held value is updated without copying. | Count node allocation events during a fully unshared update and reversal, after input construction, with instrumentation run separately from timing. Tree insertion gets its own operation-specific statement of permitted allocations. | Zero replacement-node allocations during the operation. A planted helper that always copies must fail. |

The benchmarks must use the same helper path the C checks exercise, so a
builder cannot pass C with one implementation and time A with another.
Optimising the helper, such as checking uniqueness once before a batch of
updates, is allowed; bypassing it is not (D67). Correctness and measurement
validity come before any speed verdict. There is no demands claim: 3b has no
checker.

What passing claim A means (D67): it supports this helper as a candidate for
these four workloads. It does not establish general performance or
performance under sharing. 2× is Robert's chosen budget, kept for continuity
with Experiment 3, not a predicted cost of counting.

## Not in 3b

- **The copy-feedback follow-up** (D59, what Mo says about copying outside
  explicit demands). D59 said "possibly inside 3b". The lead proposes keeping
  it separate: it tests agents using feedback, needs fresh agent sessions per
  condition, and would substantially expand 3b's scope. It can reuse 3b's helper and the
  repeated-sharing case afterwards.
- **Concurrency, atomic counting, `Arc`, weak references.**
- **Whether Mo can generate these programs automatically** (future compiler
  work) **or enforce demands** (3c, within its toy-language scope).

## How the work is split (the lock pattern)

1. The lead writes this plan, `ACCEPTANCE.md` and the measuring script. Codex
   answers one bounded question before locking: "can a builder pass these
   checks while failing the intended task?" Robert approves, and the hashes go
   in `LOCK.md`.
2. A builder, in a visible Herdr pane, writes the helper and the benchmark
   programs only.
3. The lead verifies independently: hashes, a clean rebuild, the compiled code
   for claim B's retention, and the planted broken helpers really failing.

## Stop conditions

The experiment stops when any of these happens:

- **Completed.** Every claim is measured and written up in `RESULT.md`, with
  the raw data.
- **Setup blocked.** Rust, Koka, mimalloc or the instrumentation cannot be
  installed or run on this Mac. We stop and report back.
- **Not measurable as specified.** A claim turns out not to be measurable as
  described. We stop and bring it to Robert, and do not change the claim
  ourselves.

In every case, failures and raw evidence are kept. A run with incorrect output
gets no speed verdict. A valid result outside the 2× budget is a completed
experiment (D66's third outcome), not a reason to keep rewriting the helper
until it passes.

## What 3b's result means for 3c (decided, D66)

Robert replaced D42's gate on 23 Sep 2026 (D66): 3c is valuable regardless
of 3b's result. The record of how the rule was reached:

D42 says 3c runs "only if 3b looks promising". Codex argued that the
usefulness of a demand checker is not logically conditional on this helper
meeting a benchmark target. A slow result requires diagnosis and does not
establish which compiler or runtime changes are needed. The lead's own, and
stronger, reading is that a slow helper would make the checker experiment
more relevant, not less; Codex did not endorse that inference. Both agree the
gate as written should go. The rule now in force:

| Outcome | Interpretation |
| --- | --- |
| Correctness or measurement validity fails | Repair or redesign 3b before drawing conclusions. |
| A valid helper meets the speed target | Supports going on to 3c with this helper as a candidate foundation. |
| A valid helper misses the target | Diagnose the cause and bring Robert a next-step proposal. Neither cancel 3c automatically nor prescribe the compiler-heavy route. |

## Open questions for Robert, in order

1. ~~Replace D42's gate with the three-outcome table above?~~ Decided, D66.
2. ~~Keep the 2× rule for claim A?~~ Decided, D67.
3. ~~Approve the plan~~ Decided, D68. Next: approve the acceptance file and
   measuring script, then lock.

## Codex's review of the draft (23 Sep 2026)

Second review, of the full draft after D66 and D67: Codex supported approval
after wording corrections, all applied: self-contained stop conditions;
claims B and C1 narrowed to what their tests show; no implied expansion of
3c; "substantially expand" instead of an unsupported "double"; the old gate
marked superseded; the status line separating decided parts from draft. It
agreed the copy-feedback follow-up stays out of 3b, since nothing uniquely
valuable is lost.

First review:

Codex accepted the experiment as worth doing and changed the draft in these
ways, all taken into the text above: narrower question; the "two routes"
framing dropped; the gate replaced; C1 compares all live values against the
reference model, with fixed cases including shared tails; C2 counts node
allocation events during the operation, with tree insertion stated
separately; no weak references; a safe mutant for the C1 control; Rc-only
scope stated; the within-Rust comparison described as combined overhead, not
counting alone; the boundary (hand-written programs, not generated ones) made
prominent. One difference of interpretation remains and is recorded above:
what a slow helper would show. Codex: it needs diagnosis and shows nothing
about which changes are needed. Lead: it would make 3c more relevant. The
proposed three-outcome table follows Codex's position.
