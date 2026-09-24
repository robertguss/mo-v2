# Experiment 3b: Codex's independent verification

Written by Codex on 23 Sep 2026, under D70 (Robert's decision that Codex and
the lead review separately before comparing findings). I did not read
`council/verify-lead.md`, any `RESULT.md`, or the lead's findings before writing
this file. This review is of the three builder files fingerprinted below.

**Conclusion: no blocking implementation finding. The builder's work passes
the locked automated checks in my own clean, full run, and my source review
supports all six required manual checks.** I found no concrete way this
implementation obtains that pass by bypassing the counted helper, changing
the required algorithms, losing old values, leaking the tested structures,
or removing the required Koka retention.

This supports outcome 2 under D66 (a valid helper meets the chosen speed
budget). The script deliberately leaves that outcome provisional pending the
lead's recorded review. This file supplies my independent findings; it does
not claim that the lead's review, comparison, or final result is complete.

## Findings and qualifications

- **No required builder change found.** The result is evidence for these
  hand-written implementations and workloads, not a general proof of the
  helper, a guarantee about shared performance, or evidence that Mo can
  generate or check such programs automatically.
- **One nonblocking description mismatch in the locked acceptance:** the
  shared-tree insertion fixture actually contains 11,000 keys, not 10,000.
  `acceptance/harness/src/bin/c2.rs:104-127` builds 10,000 keys and adds 1,000
  distinct keys before cloning the tree. The 28-allocation ceiling is still
  conservative for that size (`2*log2(11001) < 27`), and this helper uses 13
  allocations. Describe the actual size accurately in the result; this does
  not call for changing the locked threshold or rerunning the experiment.
- The known benchmark-2 readout difference remains: the helper performs
  three full traversals and one left-edge traversal; the baseline performs
  two full traversals and two edge traversals. The helper also uses a small
  iterator stack. These costs are included in its time. Treat the comparison
  as the combined cost of this counted representation and implementation,
  as the plan says, rather than an isolated measurement of counting
  instructions. I found no cached count, cached sum, or shortcut traversal.

## Independent execution and scoring

After the lead explicitly confirmed that his timing run had finished, I ran
the unmodified `./run.sh` with its default ten rounds. It rebuilt from scratch
and exited 0. I did not run another test or build alongside its timings.

Machine: Apple M3 Max, macOS 26.6.2; Rust 1.98.1 (Homebrew); Koka 3.2.9.
Timing-order seed: **1068392794**. The timed Rust builds used the locked
mimalloc configuration, and the script's symbol checks passed.

I independently read `data/timings.csv` and recomputed the medians rather
than relying only on the printed verdict. There are exactly **154 rows**:
14 programs, each with one warm-up and ten timed runs. Each program has
rounds 0 through 10 exactly once. All outputs match their required lines,
all exits are 0, all timeout flags are false, and all stderr tails are empty.
The round order reproduces from the recorded seed. Recomputed full-precision
medians match `data/summary.json`, and all four exact comparisons meet 2x.

Displayed numbers below are rounded; the pass decision used unrounded data.

| Benchmark | Helper median, seconds | Same-container Rust median, seconds | Helper / Rust | Helper / Koka |
| --- | ---: | ---: | ---: | ---: |
| 1: add one | 0.170590 | 0.162701 | 1.048 | 1.250 |
| 2: tree insertion | 0.286580 | 0.260240 | 1.101 | 1.354 |
| 3: reverse | 0.155446 | 0.130705 | 1.189 | 1.127 |
| 4: running totals | 0.306645 | 0.304329 | 1.008 | 0.542 |

Claim C1: all 17 fixed cases pass, with 2,000 list sequences and 2,000 tree
sequences passing and no panics. Claim C2: all 16 checks pass. Unique list
updates allocate zero; list/tree holds allocate zero; the restored unique
tree insert allocates one; 1,000 new unique-tree keys allocate 1,000; existing
keys allocate zero; shared-list push allocates one; shared-tree insert
allocates 13 against a ceiling of 28. Both large structures remain live while
held and return the live-block count to its starting value when released.

I also checked the raw control files, all of which finish with `DONE` and
exit 0. Shared-mutation fails exactly the seven shared fixed cases and all
2,000 generated sequences of each kind, with zero panics. Always-copies
passes C1 and fails the four required unique-update allocation checks with
values correct: 10,013 allocations for add-one, 10,000 for reverse, 10,013
for running totals, and 17,234 for the 1,000 new tree keys. These are actual
value/allocation failures, not incomplete runs being counted as catches.

Claim B's helper gate passes at the timed size for all 100 rounds: the minimum
extra live-block count while the old version is held is 1,000,000, and the
maximum residual after releasing it is zero. Source inspection confirms
those allocations are the new list cells. Koka retention is confirmed below.
The observed time ratios are **3.807x** for helper sharing versus its unique
case, **3.750x** for Koka sharing versus its unique case, and **1.269x** for
helper sharing versus Koka sharing. Peak-RSS ratios are 1.999x and 2.582x
respectively; those are observations, not acceptance thresholds or copy
counts. The script's Koka fields remain marked pending by design; my manual
retention finding supports interpreting them, subject to the lead recording
his own required check.

## The six manual requirements

1. **One Rc per cell/node; preserve other holders.** In
   `bench/helper/src/lib.rs:22-48`, each list cell links to the next through
   `Option<Rc<ListCell>>`; the list root is also an Rc link. Tree links are
   `Option<Rc<Node>>` at lines 145-159. Derived container clones only clone
   those root links. Derived cell/node clones retain children, rather than
   recursively deep-copying them. List writes at lines 78-84 and 96-104,
   and tree writes at lines 172-242 and 272-318, go through `Rc::make_mut`.
   Unique pop uses `Rc::try_unwrap`; shared pop retains the tail without
   editing the old cell (lines 65-70). There is no other mutable access to
   shared payloads.

2. **Required algorithms, including all four tree cases.** Input construction
   uses the lead's `build_from_back`, adding one cell per key. Add-one and
   running totals make the same single forward walk as baseline `b1.rs` and
   `b4.rs`. Reverse moves and relinks one cell at a time exactly as baseline
   `b3.rs:20-27`. Benchmark 2 consumes its input list one key at a time.
   Tree descent, red-leaf insertion, balancing while returning, and final
   root blackening correspond to baseline `b2.rs:102-122`. I compared each
   rotation's pointer moves and colors, not merely the function names:

   | Case | Helper lines | Baseline `rust-same/src/bin/b2.rs` lines |
   | --- | --- | --- |
   | left-left | 178-192 | 49-60 |
   | left-right | 193-209 | 61-73 |
   | right-left | 210-226 | 74-86 |
   | right-right | 227-241 | 87-98 |

   In every case the middle key becomes the red subtree root with two black
   children, and the four fringe subtrees keep their ordering. No balancing
   case is omitted. The added `contains` check at helper lines 245-280 runs
   only when descent first encounters a shared node; it avoids copying for
   an existing key. The unique benchmark never takes that additional search.
   This is sharing-handling logic, not an alternate timed algorithm. The
   readout difference is the one already acknowledged above.

3. **Freeing.** `ListCell::drop` at helper lines 30-41 takes each successor
   link and uses `Rc::into_inner`. A last holder yields the cell, whose next
   link is taken before its destructor runs; a shared cell releases this
   holder and stops the walk. Thus the chain is not freed by deep recursion
   and the shared suffix is preserved. There is no `forget`, leaked storage,
   or extra hidden owner. Trees use normal Rc destruction, with depth bounded
   by the red-black structure. The large-list/tree and live-block checks
   support this source reading.

4. **Forbidden constructs, however written.** I read the entire 332-line
   helper and its manifest, not just the regex screen. Its only imports are
   `std::mem` and `std::rc::Rc`; its iterator uses a local `Vec` of borrowed
   nodes. There is no unsafe code, interior mutability, weak/atomic pointer,
   raw pointer, global state, custom allocator, build script, dependency,
   external module, environment/process access, or conditional alternate
   implementation. The derived `Clone` declarations are the ones the
   acceptance explicitly permits. The Koka file has no forbidden mutation
   or vector implementation.

5. **No special-casing or measurement detection.** The helper contains no
   benchmark sizes, round counts, expected outputs, timing access, build-mode
   switches, or allocation-counter access. Its branches concern list/tree
   shape, keys, colors, and actual holder counts. Both timed and correctness
   drivers call the same public operations from this library. The fixed sizes
   in the Koka entry point are the required workload, not a bypass.

6. **Koka really retains the previous version in generated C.** In
   `build/.koka/v3.2.9/clang-drelease-16d152/b1_dash_share.c:136-138`,
   `rounds` duplicates `kept` and passes that owned duplicate into add-one
   while retaining the original. It reads the original at lines 153-158
   after add-one returns. The original is either consumed by the last-round
   sum at line 173 or dropped at line 177, before the next iteration at
   lines 180-186. In add-one, lines 33-44 distinguish unique reuse from
   the shared path: the latter retains the tail, releases the consumed
   holder, and constructs a fresh cell with a null reuse token. That propagates
   sharing down the whole retained list on every round. This meets the
   acceptance's compiled-C retention check; it is not a runtime copy count.

## Identity and retained evidence

All **31 fingerprints in `LOCK.md` matched both before and after my run**.
The builder's three files were unchanged across the review. No builder file,
locked file, or baseline was edited. Apart from this review file, the only
workspace writes I initiated were the explicitly authorized `run.sh` outputs
in `build/` and `data/`.

SHA-256 values for the reviewed sources and this run's principal evidence:

```text
f9592026ad4efa047d239c38b72d530848d6db5e9fdade4b8a04c5a2580c943b  bench/helper/Cargo.toml
6a700842e502c576037ace183c7376f6ce86252dce8258329739b3902b618d05  bench/helper/src/lib.rs
fe5aa2d8d4fd1db1ecb46a557ad050cb9da71f71a3d1068cf6b835f0d3fd9c52  bench/koka-share/b1-share.kk
5266387bd8797850117415de5cba3ad8d5b507302fa0be1c0238bb20eb41915a  data/summary.json
df4e20066ccea2396da46e1fc5f98a23b4fdf5d6a2da58669a25aa0a9363b77e  data/timings.csv
c5568aace70f2282fdf185ad116675c587bbcd2d5076880b757c697497fc8bee  build/.koka/v3.2.9/clang-drelease-16d152/b1_dash_share.c
```

Full check outputs, including all 4,000 failures of the shared-mutation
control, are in `data/checks/`. A later run overwrites these paths; the hashes
and timing seed above identify the run assessed here.
