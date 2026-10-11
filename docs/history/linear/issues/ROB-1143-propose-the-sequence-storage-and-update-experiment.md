# ROB-1143: Propose the sequence storage and update experiment

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/issue/ROB-1143/propose-the-sequence-storage-and-update-experiment
> Status at export: Needs Input
> Created: 2026-10-02
> Updated: 2026-10-09
> Comments: 0

---

## Description

## Current checkpoint — 9 October 2026, after Stage B

[ROB-1333](<https://linear.app/robert-guss/issue/ROB-1333>) is accepted, merged and Done. Its linked-list execution/resource evidence does not compare linked cells, arrays and chunked trees or select Mo's permanent sequence representation. This comparison remains unexecuted and Needs Input under its own approval gates. Older references to pending interpreter preparation or a fixed next-work ordering below are historical. No representation decision or new execution is authorized.

## Reconciled current status — 7 October 2026

This sequence comparison remains unexecuted and unapproved. Historical “first after 3b”, “3c next” and live-update priority wording below does not define today’s execution queue. [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and)’s separate preparation/conditional Stage A authorization does not approve this comparison or select a permanent sequence representation.

Earlier records follow, preserved as history.

## Current status — 2026-10-06

Needs Input: the comparison below is prepared for scoped scientific/acceptance approval. It does not choose Mo's sequence representation or alter purity, existing 3b/full3c locks, or the current live-update priority. No experiment ran.

## Proposed sequence comparison

**Question.** How do storage shape and update strategy separately affect time and memory while every retained version stays unchanged?

**Storage comparison.** Implement linked cells, contiguous arrays and a tree of fixed 64-element chunks behind the same logical sequence operations in Rust, with the same allocator and counted copy-on-write strategy. Record that one chunk width is tested, not an optimum. This first comparison holds the update strategy constant.

**Update comparison.** On each representation compare copying on every update, counted reuse when uniquely held, exclusively consumed ownership, and a confined mutable builder that freezes its result before publication. State unsupported combinations explicitly rather than pretending one mechanism has been measured. Rust's ownership check is evidence for the prototype's consumed API; it is not a proof of a future Mo consumption checker. A retained snapshot cannot be consumed or exposed to shared mutation.

**Workloads.** At 100, 10,000 and 1,000,000 elements, update every element under unique ownership, then change one element while retaining and checking the complete old version. Exercise beginning/middle/end updates; check empty/singleton and 63/64/65-element boundaries separately. Include shared tails/subtrees, dropping an old holder before a later update, and reading every live version after each step. Keep construction and traversal costs visible rather than subtracting inconvenient work.

**Acceptance and tools.** A separate author fixes the simple copying reference model and generated operation traces before implementations. Values, ordering and all retained snapshots must match after every operation, and all unreachable storage must be released. Instruments count actual allocations, requested bytes and replaced cells separately; a chunk/path copy is not one logical-element copy. Shared-mutation and hidden pre-copy controls must fail. No existing accepted helper or measuring script is rewritten.

**Measurements.** Pin compiler, allocator, seeds and source. Run correctness/instrumentation separately from ten interleaved timing repetitions. Retain every sample, median, spread, allocation totals, peak requested bytes and separately process peak memory. Report representation/strategy combinations individually. The [historical whole-program ratios](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/documents/design-choices/11-how-are-sequences-stored-and-updated/README.md>) motivate testing; they do not isolate a storage cause.

**Stop and recommendation.** Stop on changed retained values, unsupported ownership being treated as success, leaks, mismatched algorithms or unusable measurement, preserving failures. Slower or larger correct arms remain reportable results. Recommend this two-dimension experiment before choosing storage; maps/sets, concurrency and a full Mo checker remain separate questions.

---

Keep two dimensions separate: linked cells/contiguous arrays/trees of chunks, and copying/counted reuse/checked consumption/confined mutation. Shared mutation observable by another holder would reopen purity. Compare updating every element under unique ownership and changing one while retaining/checking the old version; time and memory across sizes. Tools chosen for this question. Maps/sets later. Historical text says first after 3b; current approved priority is 3c under D71 (3c selected next). No new schedule inferred.

Stop condition: produce a plain-English proposal naming claims, comparison tools and limits, acceptance evidence, and an execution stop rule; wait for Robert’s approval. No implementation is authorized by migration.

Source: [https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/documents/design-choices/11-how-are-sequences-stored-and-updated/README.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/documents/design-choices/11-how-are-sequences-stored-and-updated/README.md>)
