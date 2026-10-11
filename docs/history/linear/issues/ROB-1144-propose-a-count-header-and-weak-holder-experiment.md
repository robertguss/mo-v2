# ROB-1144: Propose a count-header and weak-holder experiment

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/issue/ROB-1144/propose-a-count-header-and-weak-holder-experiment
> Status at export: Needs Input
> Created: 2026-10-02
> Updated: 2026-10-06
> Comments: 0

---

## Description

## Current status — 2026-10-06

Needs Input: the proposal below is ready for Robert's scoped scientific execution approval. Preparing it does not select Mo's memory representation, replace Rust Rc, or amend any existing lock. No experiment was run.

## Proposed bounded experiment

**Question.** For the acyclic, single-threaded lists and trees already exercised by Experiment 3b, can a strong-holder-only header preserve every live value and release memory correctly while reducing measured allocation size? Separately, which prospective Mo behaviors would actually require non-owning references?

**Evidence and limits.** The unchanged [3b result](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03b-helper/RESULT.md>) reports two eight-byte counts in its tested Rc layout and no weak-holder use. That is historical evidence for that toolchain and workload, not a stable Rust ABI or a general Mo conclusion. Current helper/result bytes match the imported snapshot. Rust documents that [Weak permits non-owning references and breaks ownership cycles](<https://doc.rust-lang.org/std/rc/index.html>); removing it changes available semantics.

**Comparison.** Keep the accepted helper untouched. In an isolated new experiment compare standard Rc with one strong-count candidate using the same list/tree algorithms, allocator, payloads and retain/update/drop traces. The candidate exposes no weak references and makes no concurrency claim. First inventory requirements for parent backlinks, caches and runtime handles: classify each as required, optional or unknown, with its source. Do not infer that all Mo values or the runtime can omit weak references from the 3b case alone.

**Checks before measurements.** An acceptance author separate from the implementation author fixes and hashes the copying reference model, retained-snapshot cases, generated traces and drop/allocation checks before building. Exercise shared tails/subtrees, update after retaining an old root, reuse after dropping aliases, varied drop order, destructor counts and iterative release of long structures. Shared-mutation and always-copy controls must fail their intended checks. Any custom unsafe implementation receives a bounded [Miri](<https://github.com/rust-lang/miri>) run; passing is evidence for executed paths, not a universal memory-safety proof.

**Measurements.** Record requested allocation bytes, alignment, live/peak requested bytes and allocation counts separately from process peak memory. Include several payload sizes so padding and allocator size classes cannot masquerade as header savings. Instrumentation runs are separate from timing. Pin compiler, target, allocator, source and seeds; run ten interleaved timing repetitions per workload and retain every sample, median and spread. Repeat the existing unique and retained-version workloads. Timing is observational; no adoption threshold or new Mo semantics is silently chosen.

**Stop.** Stop on wrong values, lost live holders, premature/double destruction, leaks after final release, undefined behavior, a required unsupported weak-reference behavior, or instrumentation that cannot distinguish requested bytes from process memory. Preserve failed controls and raw evidence; do not change expected answers to pass. A valid result showing no memory benefit or a slowdown completes the experiment and must be reported.

**Recommendation.** Approve this isolated comparison first. Keep Rc as the reference and leave a permanent one-count representation undecided until the semantic inventory and measurements support it. The approval covers a new contract/check set and experiment only, with separately authored acceptance; existing 3b/full3c files and scientific locks remain unchanged.

---

3b proposal 2: Rust Rc spends part of its header on a weak-holder count Mo may not need. Investigate whether weak holders are needed and measure realistic alternatives before approving a one-count implementation. This is a research question, not permission to replace Rc.

Stop condition: produce a plain-English proposal naming claims, comparison tools and limits, acceptance evidence, and an execution stop rule; wait for Robert’s approval. No implementation is authorized by migration.

Source: [https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03b-helper/RESULT.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03b-helper/RESULT.md>)
