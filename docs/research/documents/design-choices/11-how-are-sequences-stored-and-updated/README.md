# 11 How are sequences stored and updated?

Experiment 3 found the linked lists and trees used on both sides 2.6–8.5× slower than Rust's idiomatic collections on benchmarks 1–3. Those figures compare whole programs, so they motivate this question without isolating a cause or showing a general cost of purity. Sequences first; maps and ordered sets have different needs and come later.

Status: Open (D65). First experiment after 3b, with tools chosen per D64 and two workloads: update every element under unique ownership, and change one element while keeping and checking the old version. Time and memory across a few sizes.

The choice has two dimensions that combine, so they are listed separately. D26 (fully pure, invisible in-place updates) limits the second dimension: an update no other holder can observe fits; one another holder can see does not.

## How elements are stored

* [Linked cells](linked-cells.md)
* [Contiguous arrays](contiguous-arrays.md)
* [Trees of chunks](trees-of-chunks.md)

## How updates are handled

* [Copy on every update](copy-on-every-update.md)
* [Counted reuse when uniquely held](counted-reuse-when-uniquely-held.md)
* [Statically checked consumption](statically-checked-consumption.md)
* [Confined mutation](confined-mutation.md)
* [Shared mutable arrays](shared-mutable-arrays.md) (Conflicts with D26)
