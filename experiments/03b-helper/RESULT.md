# Experiment 3b: result

Run and verified on 23 Sep 2026. Plan approved by Robert (D68), acceptance file
approved (D69), both locked in `LOCK.md`. Verified independently by the lead and
by Codex (D70); the two reviews are compared below.

**Summary: outcome 2 under D66. A valid helper meets the speed budget.**
Hand-written Rust that updates a value in place when it has one holder, and
copies it when it has more, ran between 1.01× and 1.19× the time of plain
in-place Rust on all four benchmarks, against a budget of 2× (D67). All
correctness checks passed, all three controls behaved, and both independent
reviews found no way the work passes the checks while failing the task.

Under D66 this supports going on to 3c with this helper as a candidate
foundation. What that means for Mo is for Robert to decide; the lead's proposals
are at the end.

## What was tested

Mo's design choice D26 says values never change from the program's point of
view, and the compiler updates them in place when nothing else holds them.
Experiment 3 tested that trick where the compiler does the work (Koka). 3b
tested the simpler route: a small runtime helper that counts holders and checks
the count before each update, with no Mo-specific compiler analysis.

The builder wrote only the helper, a list and a red-black tree in which every
cell and node carries a holder count (Rust's `Rc`), plus one Koka program. The
lead wrote everything that judged it. The yardsticks were Experiment 3's own
Rust and Koka programs, reused unchanged.

## Claim A: speed. PASS

Each number is the median of 10 runs, whole program, in seconds. From the lead's
official run (seed 659084380).

| Benchmark              | Helper | Plain in-place Rust | Helper ÷ Rust | Helper ÷ Koka |
| ---------------------- | ------ | ------------------- | ------------- | ------------- |
| 1. Update every item   | 0.1710 | 0.1630              | **1.05**      | 1.24          |
| 2. Build a sorted tree | 0.2880 | 0.2605              | **1.11**      | 1.35          |
| 3. Reverse a list      | 0.1561 | 0.1308              | **1.19**      | 1.13          |
| 4. Running totals      | 0.3066 | 0.3036              | **1.01**      | 0.55          |

The budget was 2× on each benchmark, compared on exact medians. The runs were
tight: the slowest helper run was at most 8% above its fastest.

Three separate full runs gave the same answer:

| Run             | Seed       | Ratios to plain Rust, benchmarks 1 to 4 |
| --------------- | ---------- | --------------------------------------- |
| Builder's own   | 604783276  | 1.049, 1.107, 1.196, 1.006              |
| Lead's official | 659084380  | 1.049, 1.106, 1.194, 1.010              |
| Codex's         | 1068392794 | 1.048, 1.101, 1.189, 1.008              |

What a pass means (D67): it supports this helper as a candidate for these four
workloads. It does not establish general performance, or performance when values
are shared.

## Claim B: what repeated sharing costs, in one case. Observational

Benchmark 1, but each round keeps the previous version while building the new
one, so every round has to copy the whole list of a million.

|        | Time, sharing ÷ not sharing | Peak memory, sharing ÷ not sharing |
| ------ | --------------------------- | ---------------------------------- |
| Helper | 3.80×                       | 2.00×                              |
| Koka   | 3.74×                       | 2.58×                              |

The helper's sharing version took 1.27× Koka's time.

Both validity gates held. For the helper, the lead's counting allocator showed a
full new copy of 1,000,000 cells alive alongside the kept one in every round,
and nothing left over once the kept one was released. For Koka, the compiled C
shows the kept list gains a holder before each update and is read afterwards, so
every update meets a shared list and copies it (checked by both the lead and
Codex).

## Claim C1: values preserved. PASS

Every fixed case passed, including two lists sharing a tail and two trees
sharing subtrees, and 4,000 random sequences of operations (2,000 on lists,
2,000 on trees) matched a simple copying model after every step. A list of a
million and a tree of 100,000 were freed without crashing.

## Claim C2: no copying with one holder; sharing copies only what it must; memory freed. PASS

All 16 checks passed:

- With one holder, add one, reverse, running totals and pop allocated nothing,
  and each new tree key allocated exactly one node.
- Adding and removing a holder allocated nothing, for lists and trees.
- Pushing onto a shared list allocated one cell. Inserting into a shared tree
  allocated 13 nodes, the copied path plus the new one, against a limit of 28.
- Everything stayed alive while any holder had it, and was all freed with the
  last holder.

**Correction to the acceptance file's description.** The shared-tree check runs
on a tree of 11,000 keys, not the 10,000 that `ACCEPTANCE.md` states. Codex
found this. The 28-node limit still holds at that size: a red-black tree of
11,000 is under 27 levels deep. The locked files are not changed.

## Controls. Behaved

- **shared-mutation** (every holder shares one changeable store) finished,
  failed all 7 shared cases and all 4,000 generated sequences on wrong values,
  with no panics.
- **always-copies** (right values, but a copy on every update) passed C1, and
  failed C2 on allocations with every value right: 10,013 allocations for add
  one, where the helper used 0.

## Independent verification (D70)

The lead and Codex each reviewed the builder's work without seeing the other's
findings: `council/verify-lead.md` and `council/verify-codex.md`.

| Question                                                             | Lead                                                                  | Codex                                       |
| -------------------------------------------------------------------- | --------------------------------------------------------------------- | ------------------------------------------- |
| Builder's files as reviewed; 31 fingerprints hold | Yes; only three files changed, all under `bench/` | Yes for the reviewed files and all 31 fingerprints, before and after its run; did not audit the builder's full activity |
| One counted cell or node each, changed in place only with one holder | Holds                                                                 | Holds                                       |
| Same algorithm as Experiment 3's Rust, all four tree cases           | Holds, with two small disclosed additions that do not help the helper | Holds; compared every rotation line by line |
| Freeing in a loop, stopping at shared cells                          | Holds                                                                 | Holds                                       |
| Forbidden constructs, however written                                | None                                                                  | None                                        |
| Size special-casing or measurement detection                         | None                                                                  | None                                        |
| Koka keeps the old version across the update                         | Holds, from the compiled C                                            | Holds, and traced add-one's shared path too |
| Can the work pass the checks while failing the task?                 | No way found                                                          | No way found                                |
| Outcome                                                              | 2                                                                     | 2                                           |

**Where they differed.** Codex found the 11,000-key description error; the lead
missed it. Codex also corrected four wordings in a draft of this file, all taken:
the scope of 3c, what the 1% to 19% measures, \"allocated\" rather than
\"copied\" for the shared-tree check, and the limits of its bounds check. The lead reported the memory and Koka observations below; Codex did
not comment on them. There were no disagreements.

**The two additions the builder made, both disclosed:**

- On the way down a tree insertion, the helper checks each node's holder count
  until it meets a shared node, and there looks once for the key, so inserting a
  key that is already present into a shared tree copies nothing. Benchmark 2 is
  never shared, so the check always comes out false: one extra comparison per
  level, which counts against the helper.
- The root is made black only when it is red. The result is the same.

**One known difference in the drivers, stated in the acceptance file.** Reading
out the tree takes three full walks in the helper's driver against two in
Experiment 3's, and it counts against the helper.

## Observations the claims did not ask about

- **Memory.** The helper's lists peaked at about 34 MB, against 18 MB for plain
  Rust and 27 MB for Koka. Each Rust `Rc` stores two counts (holders and weak
  holders) of 8 bytes each next to a 16-byte cell. The helper never uses weak
  holders, so half of that header is unused. Koka's header is 8 bytes.
- **Koka was faster than both Rust versions** on benchmarks 1 and 2, as in
  Experiment 3. Benchmark 4 is the exception, where Koka's unlimited-size
  numbers cost it (design choice 10). The two sides' allocators are built with
  different alignment (8 against 16 bytes, noted in Experiment 3), so this is
  not isolated.

## Limits

- The helper is hand-written Rust used correctly. This says nothing about
  whether Mo could generate such programs automatically, which remains future
  compiler work, or enforce in-place demands, which 3c investigates within its
  toy-language scope.
- Single-threaded counting only. Threads, atomic counts and weak holders were
  not tested.
- Four workloads and one sharing case. Passing claim A is not a general
  performance result.
- The comparison measures the combined cost of the counted representation and
  its implementation, not the counting instructions alone.

## What the result means (for Robert to decide)

These are the lead's proposals; nothing here is decided.

1. **The simple runtime route works on these workloads.** This counted
   helper ran 1% to 19% slower than plain in-place Rust. That is the combined
   overhead of the counted representation and its implementation, not the
   isolated cost of checking counts. Under D66
   this supports going on to 3c, with this helper as a candidate foundation for
   Mo's runtime.
2. **The count header is a cost Mo can design away.** Half of each Rust `Rc`
   header counts weak holders, which Mo's values may never need. Mo's own
   counted values could carry one count, as Koka's do. That belongs with design
   choice 8 (memory), as a question to test.
3. **Sharing costs about the same with the helper as with Koka's compiler.**
   Copying every round cost about 3.8× in both. That gives the D59 copy-feedback
   follow-up a measured case to start from.

## Data

- `data/lead-run/`: the official run (timings, summary, check outputs, and the
  printed output).
- `data/builder-run/` and `data/codex-run/`: the two other full runs.
- `council/verify-lead.md` and `council/verify-codex.md`: the two independent
  reviews.
- `./run.sh` rebuilds and re-runs everything from scratch.
