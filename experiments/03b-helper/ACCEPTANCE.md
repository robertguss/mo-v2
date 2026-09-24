# Experiment 3b: acceptance

Written by the lead. Robert approves this file, and its fingerprints are then
recorded in `LOCK.md`. The builder may not change it or anything in
`acceptance/`.

**Status: approved by Robert on 23 Sep 2026 (D69).** The plan is approved
(D68). Codex's pre-lock review found nine problems in the first draft and two
more on re-check; all are fixed below (see "Codex's pre-lock review"). The
lead's script `acceptance/measure.py`, run with `./run.sh`, applies every rule
below. Fingerprints are in `LOCK.md`.

## Who writes what

| Who     | Writes                                                                                                                                                   | Why                                                                                                                                                                                                                    |
| ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Builder | The helper: `bench/helper/`, a small Rust library with a list and a red-black tree whose cells carry a holder count (`Rc`).                              | It is the thing being tested.                                                                                                                                                                                          |
| Builder | `bench/koka-share/b1-share.kk`, the Koka version of claim B's sharing case.                                                                              | It is a program being measured.                                                                                                                                                                                        |
| Lead    | The benchmark drivers that call the helper, the correctness checks, the two deliberately broken helpers, and the measuring script, all in `acceptance/`. | No self-certification: the builder cannot write or change what judges its work. Because the lead writes the drivers, the timed programs can only use the helper's own operations, the same ones the checks test (D67). |
| Nobody  | Experiment 3's same-container Rust and pure Koka programs are reused unchanged, from `experiments/03-in-place/bench/`, and fingerprinted.                | Continuity with Experiment 3 (D64), and the builder cannot weaken the yardstick.                                                                                                                                       |

## The helper's operations

Every cell of a list and every node of the tree is its own counted value. Each
operation takes the value it changes and hands back the result. If nothing else
holds the value, the operation changes it in place. If something else does, it
copies only what it must, so the other holder never sees a change.

| Operation        | What it does                                                                                  |
| ---------------- | --------------------------------------------------------------------------------------------- |
| new list         | An empty list.                                                                                |
| push to front    | Adds a value at the front.                                                                    |
| pop from front   | Takes the first value off, giving the value and the rest.                                     |
| add one          | Adds one to every value (benchmark 1).                                                        |
| reverse          | Reverses the list (benchmark 3).                                                              |
| running totals   | Replaces each value with the running total so far, each kept mod 1,000,000,007 (benchmark 4). |
| first, read all  | Reads the list without changing it.                                                           |
| new tree, insert | An empty red-black tree; inserts a key, and an existing key changes nothing (benchmark 2).    |
| read all (tree)  | Reads the keys in ascending order.                                                            |
| hold             | Adds another holder of the same list or tree. It copies nothing and allocates nothing.        |

The exact Rust signatures are in the appendix.

## Rules for the helper

- Plain safe Rust with `Rc` holder counts, single-threaded, one `Rc` per list
  cell and per tree node. No `unsafe`, no interior mutability (`Cell`, `RefCell`
  and the like), no `Weak`, no `Arc`, no raw pointers, no global or static
  state, no locks or atomics, no custom allocator, no build script, and no
  dependencies. (Plan: no weak references, no concurrency.)
- Long lists are freed without running out of stack, whether or not another
  holder shares them, and everything is freed when its last holder lets go.
- No special-casing sizes, and nothing that detects being measured.

The script runs a **preliminary screen** for forbidden constructs. A pattern
screen can be dodged, so it is not the gate. The gate is the lead's recorded
review of the measured source (below).

## The lead's recorded review

Before any outcome is final, the lead reads the exact helper source that was
measured and records in `RESULT.md`, item by item:

1. One `Rc` per list cell and per tree node, updated in place only when its
   count is one.
2. Step-for-step correspondence with Experiment 3's same-container Rust ("The
   same algorithm on both sides"), including Okasaki's four cases.
3. Freeing: long lists in a loop, stopping at a shared cell.
4. No forbidden construct, however written.
5. No size special-casing or measurement detection.
6. Koka's sharing program holds the kept version across the update, checked in
   Koka's compiled C, as Experiment 3 did (D53).

This is the independent verification the lock pattern already requires, not a
new review layer. Until it is recorded, the script marks the outcome
"provisional".

## Claim A: the helper meets the agreed runtime budget (D67)

### The programs and their expected output

Every timed program must print exactly these lines. A program that prints
anything else, crashes or times out is wrong, and its times don't count. The
four benchmarks are Experiment 3's, with the same expected output.

| #   | Benchmark                                                                               | Expected output                                              |
| --- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| 1   | Update every item: add one to each of 1,000,000 numbers, 100 times                      | sum 500100500000, first 101, last 1000100                    |
| 2   | Build a sorted tree: insert 1,000,000 scrambled keys, key i is (i × 7919) mod 1,000,003 | count 1000000, sum 499999547508, smallest 0, largest 1000002 |
| 3   | Reverse a list of 1,000,000, 101 times                                                  | first 1000000, last 1, weighted 166667166667000000           |
| 4   | Running totals of 1,000,000 amounts, amount i is (i × 37) mod 1000, 100 times           | first 37, last 554962791, sum-mod 491625299                  |

### The same algorithm on both sides

The helper must do the same work as Experiment 3's same-container Rust, step for
step, so the ratio measures the holder counts and not a choice of algorithm:

| Benchmark          | Algorithm, identical on both sides                                                                                                                                                |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Building the input | A list built from the back, one cell at a time (the lead's drivers do this with push to front). Benchmark 2 builds its keys as a list and takes them off the front one at a time. |
| 1, 4               | One walk of the list per round.                                                                                                                                                   |
| 3                  | Move cells one at a time from the front of one list to the front of another.                                                                                                      |
| 2                  | Okasaki's red-black insertion: go down to the insertion point, add a red node, fix the four standard imbalance cases on the way back up, and make the root black.                 |
| Cleanup            | Everything is freed at the end, long lists in a loop, not by recursion.                                                                                                           |

**One known difference, stated rather than hidden.** After building the tree,
Experiment 3's Rust reads it with two full walks (count, sum) and two walks down
one edge (smallest, largest). The helper offers only "read all", so the lead's
driver uses three full walks and one edge walk. The difference is small next to
a million insertions, and it counts against the helper, not for it.

### The versions timed

| Version             | Source                                            | Built with                                                                                 |
| ------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Helper              | The builder's helper, through the lead's drivers. | `--release`, mimalloc compiled from the exact source Koka 3.2.9 ships, as in Experiment 3. |
| Same-container Rust | Experiment 3's, unchanged.                        | The same, with its `mimalloc` feature.                                                     |
| Pure Koka           | Experiment 3's, unchanged, re-run today.          | `-O2`.                                                                                     |

### Measuring

As in Experiment 3 (D51, D56): every program gets one untimed warm-up run whose
output is checked too; then 10 rounds, each running every program once in a
fresh random order drawn from a recorded seed. The time is the whole program's
run. Each run's peak memory, exit status and the end of its error output are
recorded too, and each run has a 600-second limit. Every run is written to
`data/timings.csv` as soon as it finishes, with full-precision times; the
machine, versions and seed go in `data/summary.json`. The script checks that
every timed Rust program really contains mimalloc.

**Only a full 10-round run gets an acceptance verdict.** A shorter run, such as
the builder's quick checks, reports numbers marked "exploratory" with no
verdict. The procedure is fixed here and is not changed after seeing results.

### Passing

**Correctness and measurement validity come first (D67).** Claim A gets a
verdict only if all of these hold: the helper passes the preliminary screen; all
three controls behave; claims C1 and C2 pass; claim B's copying gate passes;
every one of the 14 specified programs built, ran and gave the right output,
including Koka's; and every timed Rust program contains mimalloc. Otherwise the
result is "no verdict", with the reasons listed.

With a verdict, claim A passes if, on **each** of the four benchmarks, the
helper's median is no more than 2× the median of Experiment 3's same-container
Rust, compared exactly, not rounded. No average decides. The result also reports
every ratio, the spread of the runs, and the helper's ratio to Koka, which has
no threshold.

What a pass means (D67): it supports this helper as a candidate for these four
workloads. It does not establish general performance or performance under
sharing.

## Claim B: what repeated sharing costs, in this one case (D63)

Observational; there is no pass or fail. Benchmark 1, but every round keeps the
previous version live while building the new one, reads both, and releases the
old one before the next round, so every round has to copy.

| Program                | Written by                           | Expected output                                                                                                                                                                           |
| ---------------------- | ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Helper sharing version | Lead's driver                        | Benchmark 1's lines, then `rounds-differ 100` (each round, the new first value minus the kept first value, summed) and `prev-sum 500099500000` (the kept version's sum in the last round) |
| Koka sharing version   | Builder, from Experiment 3's `b1.kk` | The same lines                                                                                                                                                                            |

**Reported:** each sharing program's time against its own benchmark 1 without
sharing, and the helper's sharing time against Koka's. Peak memory is reported
for both, as data, not judged. The raw numbers are always kept, but a ratio is
interpreted only once its gates hold: the helper's after its copying gate
passes, and Koka's and the cross-language ratio only after the lead's recorded
retention check.

**Validity gates.** If any fails, claim B's numbers are not interpreted:

- **Correct output** from both sharing programs.
- **The copying really happens, and nothing piles up (helper).** The lead's
  counting allocator tracks blocks allocated minus blocks freed while running
  the same loop at the timed size, 1,000,000 cells for 100 rounds. In every
  round, at least 1,000,000 more blocks must be live once the new version exists
  alongside the kept one. After the kept version is released, live blocks must
  be back exactly where the round started. This runs under the counting
  allocator, not mimalloc, so it checks the mechanism, not the timing.
- **The kept version is really held (Koka).** The lead's recorded review,
  item 6.

## Claim C1: the helper preserves values in these tests

The intended property is D26's promise: no holder ever sees another holder's
update. These tests check it only within the domain they cover.

**How it's checked.** After every operation, every live value is compared with a
simple copying reference model (a plain Rust vector or sorted set, which copies
on every change).

**Fixed cases**, each one pass or fail:

| Case                                                               | What it checks                                                                                                   |
| ------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------- |
| unique add one, reverse, running totals, push, pop                 | A value with one holder gives the right new value. This also rejects a helper that does nothing.                 |
| empty list                                                         | Empty lists behave.                                                                                              |
| unique tree insert; insert an existing key                         | The tree gives the right keys.                                                                                   |
| shared add one, reverse, running totals, push and pop, tree insert | With two holders, the updated version is right and the other holder is unchanged.                                |
| shared tail                                                        | Two lists share the same tail. Updating one leaves the other unchanged, both ways.                               |
| shared subtree                                                     | Two trees share subtrees. Inserting into one leaves the other unchanged.                                         |
| drop a long list; drop a large tree                                | A list of 1,000,000 and a tree of 100,000 are freed without crashing, alone and while another holder keeps them. |

**Generated sequences:** exactly 2,000 random sequences of 60 operations on
lists (new, hold, drop, add one, reverse, running totals, push to front with or
without keeping the original, pop from front) and exactly 2,000 on trees (new,
hold, drop, insert with or without keeping the original, keys 0 to 39 so repeats
happen). The seeds are fixed, starting at 20260923. Every failing seed and its
operations are saved in `data/checks/`.

**Passes when** the check program finishes, every fixed case and every one of
the 4,000 sequences matches the reference model.

## Claim C2: one holder means no copying; sharing copies only what it must; memory is freed

**How it's checked.** A counting allocator counts allocation events during each
operation, after the input is built; allocating and then freeing a replacement
still counts. It also tracks live blocks, so the checks can see what is kept and
what is freed. Values are checked afterwards too, so a helper that does nothing
cannot pass.

| Check                                                                      | Allowed                                                                                                                                                               |
| -------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| add one, reverse, running totals on a unique list of 10,000                | 0 allocations                                                                                                                                                         |
| add a holder to a list, then remove it                                     | 0 allocations                                                                                                                                                         |
| add a holder to a tree, then remove it                                     | 0 allocations                                                                                                                                                         |
| pop from the front of a unique list                                        | 0 allocations                                                                                                                                                         |
| push to the front of a shared list of 10,000                               | exactly 1 allocation: the new cell; the rest stays shared                                                                                                             |
| after the other holder is dropped, add one on the list again               | 0 allocations                                                                                                                                                         |
| after the other holder is dropped, insert one new key into a tree of 1,000 | exactly 1 allocation                                                                                                                                                  |
| insert 1,000 new keys into a unique tree of 10,000                         | exactly 1,000 allocations, one new node per key                                                                                                                       |
| insert the same 1,000 keys again                                           | 0 allocations                                                                                                                                                         |
| insert a new key into a shared tree of 10,000                              | at most 28 allocations: a red-black tree of 10,000 is under 27 levels deep, so copying only the path costs at most 27 copies plus the new node; the rest stays shared |
| drop one of two holders of a list of 1,000,000, or a tree of 100,000       | nothing freed: the other holder still has it all                                                                                                                      |
| drop the last holder                                                       | everything allocated while building it is freed                                                                                                                       |

**Passes when** the check program finishes and every check meets its allowance
with the right values.

## Controls: the checks must tell right from wrong

The lead wrote two deliberately broken helpers with the same operations. They
show the checks catch what they claim to catch. Each control must finish its run
and fail in the specific way it was built to; a crash or timeout does not count
as a catch. If any control misbehaves, the checks cannot be trusted and claim A
gets no verdict.

| Control         | What it does wrong                                                                                                           | Must                                                                                                                                                              |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| shared-mutation | Every holder shares one changeable store, so an update through one holder is seen by all. Safe Rust, with defined behaviour. | Finish C1 without any panic, give wrong values in every "shared" fixed case, and give wrong values in some generated sequences of both kinds. A panic is not a catch. |
| always-copies   | Every value stays right, but every update builds new cells or nodes, even with one holder.                                   | Pass C1, which shows C1 does not reject a correct helper just for being slow. Finish C2 with every value right and fail every unique-update check on allocations. |

## What the result means for 3c (D66)

The script reports which outcome applies, marked provisional until the lead's
recorded review:

1. **Correctness or measurement validity failed:** repair or redesign 3b before
   drawing conclusions.
2. **A valid helper meets the budget:** supports going on to 3c with this helper
   as a candidate foundation.
3. **A valid helper misses the budget:** diagnose the cause and bring Robert a
   next-step proposal. A valid result over 2× is a finished experiment, not a
   reason to keep rewriting the helper until it passes.

## How the lead validated the checks

The lead ran the whole pipeline in a scratch folder against a throwaway helper
written only for that purpose. It is not part of the experiment, it is not in
the repo, and the builder never sees it. Its numbers are not evidence and are
not reported.

- Both controls failed exactly where intended. shared-mutation failed all 7
  shared cases and all 4,000 generated sequences. always-copies passed C1 and
  failed every unique-update check on allocations, with its values right.
- The lead then sabotaged the throwaway on purpose: a tree whose "hold" secretly
  deep-copies, a tree that leaks instead of freeing, and a missing Koka program.
  Each was caught, and each blocked the verdict with its reason.
- A full 10-round run and a short exploratory run both scored as described.
- Two problems found this way were fixed: two C1 cases counted allocations,
  which is C2's job, so they moved to C2; and Experiment 3's Koka programs would
  not build from another folder, so each now builds with its own folder on
  Koka's search path.

## Codex's pre-lock review (23 Sep 2026)

Codex answered the agreed question, "can a builder pass these checks while
failing the intended task?", and found nine problems in the first draft. All are
fixed above:

1. Missing or wrong Koka results could still produce outcome 2. Now every
   specified program must be present and correct, and the Koka retention check
   is shown as pending until recorded.
2. A tree "hold" that deep-copies would have gone unnoticed. Tree hold and
   shared-tree insertion are now measured.
3. A helper that leaks instead of freeing would have passed. Freeing is now
   checked.
4. A crashed control counted as a catch. Controls must now finish and fail in
   their specific way, and the generated-sequence counts are required.
5. A quick run could print an official-looking verdict. Only a full 10-round run
   gets one now.
6. Claim B's gates overclaimed: allocation events are not copied cells, the gate
   ran at a different size, and the 3× memory ceiling had no basis. The gate now
   tracks live blocks at the timed size; peak memory is reported, not judged.
7. The source screen was overstated and dodgeable. It is now called a
   preliminary screen, and the lead's recorded review is the gate.
8. The tree readout did different work from the baseline. It is now as close as
   the operations allow, and the remaining difference is stated and counts
   against the helper.
9. Runs could hang, lose error output, lose data on a crash, round times, or
   drop failure records. Each run now has a time limit, keeps its exit status
   and error output, and is saved as it finishes at full precision, and every
   failure is kept.

Codex then re-checked the fixes. It judged the nine adequately fixed within
the stated test scope, and found two remaining gaps, both now fixed:

- A control that failed only by panicking still counted as a catch. Now the
  shared-mutation control must finish without any panic and be caught by
  wrong values.
- Claim B still printed "sharing costs" when a gate had failed or was
  pending. Raw ratios are kept, but a ratio is interpreted only once its gates
  hold.

## Appendix for the builder: exact signatures

The lead's harness compiles against exactly these. The crate is named `helper`,
version `0.1.0`.

```rust
#[derive(Clone)] pub struct List { /* private */ }   // Clone adds a holder; it must not copy
impl List {
    pub fn new() -> List;
    pub fn push_front(self, value: i64) -> List;
    pub fn pop_front(self) -> Option<(i64, List)>;
    pub fn add_one(self) -> List;
    pub fn reverse(self) -> List;
    pub fn running_totals(self, modulus: i64) -> List;   // total = (total + value) % modulus, from 0
    pub fn first(&self) -> Option<i64>;
    pub fn iter(&self) -> impl Iterator<Item = i64> + '_;
}

#[derive(Clone)] pub struct Tree { /* private */ }   // Clone adds a holder; it must not copy
impl Tree {
    pub fn new() -> Tree;
    pub fn insert(self, key: i64) -> Tree;
    pub fn iter(&self) -> impl Iterator<Item = i64> + '_;   // ascending
}
```
