# Experiment 3b: the lead's verification

Written by the lead on 23 Sep 2026, independently of Codex's review (D70). The
lead did not read `council/verify-codex.md` before writing this.

## What the builder wrote

Exactly three files, all under `bench/`, in about 10 minutes (22:41 to 22:51):

- `bench/helper/Cargo.toml`: name `helper`, version `0.1.0`, edition 2021,
  nothing else.
- `bench/helper/src/lib.rs`: 332 lines.
- `bench/koka-share/b1-share.kk`: 44 lines.

Nothing else in the repo changed. All 31 fingerprints in `LOCK.md` verify after
the builder stopped. The only file dated after the lock is `PLAN.md`, from the
lead's own reverted edit; its fingerprint matches.

## The recorded review (ACCEPTANCE.md, six items)

1. **One `Rc` per list cell and per tree node, updated in place only when its
   count is one.** Holds. `ListCell` and `Node` are each behind their own `Rc`.
   Every change goes through `Rc::make_mut`, which changes the cell in place
   with one holder and copies that one cell otherwise, or through
   `Rc::try_unwrap` and `Rc::into_inner`, which take the cell only when this is
   its last holder. `Clone` on `List` and `Tree` is derived over a single
   `Option<Rc<…>>`, so it only raises a count.

2. **Step-for-step correspondence with Experiment 3's same-container Rust.**
   Holds, with two small additions, both disclosed by the builder:
   - List building, pop from the front, add one, running totals and reverse
     follow Experiment 3's `build`, key loop, `add_one`, `running` and `reverse`
     step for step, with `make_mut` in place of a direct edit.
   - `balance` is Experiment 3's four Okasaki cases line for line, the same
     comparisons, the same re-pointing and the same `mem::swap`, with `make_mut`
     on each node before it is changed. The builder's claim that the three nodes
     involved are always on the insertion path, and so already single-holder, is
     right: a red child with a red grandchild can only arise on the path that
     was just inserted into.
   - **Addition 1.** On the way down, `ins` checks each node's holder count
     until it meets a shared node; there it looks once for the key and copies
     nothing if the key is already present. Experiment 3's Rust never shares, so
     it has no equivalent. In benchmark 2 the tree is never shared, so the check
     always comes out false: one extra comparison per level, which counts
     against the helper, not for it.
   - **Addition 2.** `insert` makes the root black only if it is red, where
     Experiment 3 sets it black every time. Same result.

3. **Freeing.** Holds. `ListCell`'s `Drop` walks the rest of the list in a loop,
   taking each cell only if it was the last holder, and stops at the first cell
   someone else still holds. Trees use the default recursive drop, as Experiment
   3's Rust does; a balanced tree of a million keys is about 40 levels deep.

4. **No forbidden construct, however written.** Holds. The file imports only
   `std::mem` and `std::rc::Rc`. No `unsafe`, no interior mutability, no `Weak`,
   `Arc`, pointers, statics, globals, macros other than `#[derive]`, or
   dependencies. `Rc::strong_count` is read, never written.

5. **No size special-casing or measurement detection.** Holds. The helper
   contains no numeric constants at all, and nothing that inspects its
   environment.

6. **Koka's sharing program holds the kept version across the update.** Holds.
   In Koka's compiled C (`build/.koka/…/b1_dash_share.c`, function
   `kk_b1_dash_share_rounds`), the kept list gets an extra holder
   (`kk_std_core_types__list_dup(kept)`) before add-one is called, and its first
   value is read after add-one returns; it is summed in the last round and let
   go otherwise. So add-one meets a shared list every round and must copy it.
   The Koka source follows the brief: Experiment 3's `b1.kk` with the kept list
   read after the update.

## The official run

A clean full run, 10 rounds, seed 659084380, on an Apple M3 Max, macOS
26.6.2, Rust 1.98.1, Koka 3.2.9, started after the builder stopped. Every
build was from scratch. Raw data: `data/timings.csv` and `data/summary.json`
(Codex may overwrite these with its own run; the lead's copy is kept outside
the repo and goes into `RESULT.md`).

- **Controls:** all three behaved.
- **Claim C1:** pass. Every fixed case, and 0 failures in 2,000 list and
  2,000 tree sequences.
- **Claim C2:** pass, all 16 checks. Inserting into a shared tree of 10,000
  copied 13 nodes (the limit is 28).
- **Claim B gates:** pass. Each round 1,000,000 more blocks were live while
  both versions existed, and exactly none were left after the kept one was
  released.
- **Claim A:** PASS on every benchmark.

| Benchmark | Helper (s) | Same-container Rust (s) | Ratio | Helper ÷ Koka |
| --- | --- | --- | --- | --- |
| 1 update every item | 0.1710 | 0.1630 | 1.049 | 1.244 |
| 2 sorted tree | 0.2880 | 0.2605 | 1.106 | 1.352 |
| 3 reverse | 0.1561 | 0.1308 | 1.194 | 1.127 |
| 4 running totals | 0.3066 | 0.3036 | 1.010 | 0.555 |

Medians of 10 runs. Spread was small: the slowest helper run was at most 8% above its fastest
(benchmark 2; 3 to 4% on the others).

- **Claim B, observational:** keeping the previous version each round made
  the helper's benchmark 1 take 3.80× as long and use 2.0× the peak memory.
  Koka's took 3.74× as long and 2.58× the memory. Koka's retention is
  confirmed (item 6), so its ratios can be read too. The helper's sharing
  version took 1.27× Koka's.
- **Agreement with the builder's own run:** the builder's run (seed
  604783276) gave ratios 1.049, 1.107, 1.196 and 1.006, within 0.004 of
  these.

Observations the claims did not ask about, reported as data:

- **Memory.** The helper's lists peaked at about 34 MB against 18 MB for
  Experiment 3's Rust and 27 MB for Koka. Each Rust `Rc` carries two counts
  (holders and weak holders, 16 bytes) next to a 16-byte cell. The helper
  never uses weak holders, so half that header is unused. Koka's header is
  8 bytes.
- **Koka was faster than the helper** on benchmarks 1 and 2, and faster than
  Experiment 3's Rust on benchmarks 1 and 2 as well, as in Experiment 3.
  Benchmark 4 is the exception, where Koka's unlimited-size numbers cost it
  (reading 2 of Experiment 3, design choice 10).
- **The outcome printed by the script** is 2, provisional: a valid helper
  meets the budget. With items 1 to 6 above recorded as holding, the lead
  finds nothing that blocks making it final, subject to comparison with
  Codex's review (D70).

## Can this work pass the checks while failing the intended task?

The lead found no way. The timed programs are the lead's drivers, which can only
call the helper's public operations, the same ones C1 and C2 exercise. The
helper has no special cases, no hidden state and no dependence on size, so the
behaviour the checks see is the behaviour that was timed.

Limits that stay, as stated in the plan: this is hand-written Rust used
correctly; it shows nothing about whether Mo could generate such programs or
enforce demands (3c), and nothing about threads.

## After comparing with Codex's review

Added after both files were written. The text above is unchanged apart from
two corrections noted here.

- **Codex caught a mistake the lead missed.** The shared-tree insertion check
  in `c2.rs` runs on a tree of 11,000 keys (10,000, then 1,000 more), not the
  10,000 that `ACCEPTANCE.md` states. The 28-allocation limit still holds at
  that size, since 2 × log2(11,001) is under 27, and the helper used 13. The
  locked files are not changed; `RESULT.md` records the correct size.
- The helper file is 332 lines, not 333 as first written here.
- The raw data of the lead's run is in `data/lead-run/`; the builder's and
  Codex's runs are in `data/builder-run/` and `data/codex-run/`.
- The shared-tree check allocated 13 nodes, the copied path plus the new
  node; "copied 13 nodes" above overstates it (Codex).
