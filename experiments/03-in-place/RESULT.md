# Experiment 3: result

Tests D26 in Koka: pure code, invisible in-place updates, and provable in-place
demands. Run on 23 Sep 2026 by the lead, from a clean build with `./run.sh`,
after the builder finished. All numbers below come from that run, except where a
line is marked as a diagnostic.

**Summary: claims A, C and D pass. Claim B is observational by design (no
pass or fail); its observations are complete but limited.** The in-place trick
makes pure Koka about as fast as Rust editing the same linked structures in
place, and on two of the four benchmarks it is faster. The one benchmark near
the 2× line, benchmark 4, is dominated by arithmetic. Switching Koka to
fixed-size numbers substantially reduces its gap. Caveats:

- two of claim B's three changes were removed by the compiler
- the strict demand covers only 3 of the 10 realistic functions
- the allocator's build settings differ between the two sides (see Setup)

*Corrected on 23 Sep 2026 after an independent verification by Codex
(`council/verify-codex.md`, D55). The first version said "all four claims pass"
and stated some conclusions more broadly than the data supports.*

## Setup

- Apple M3 Max, macOS 26.6.2, Koka 3.2.9, Rust 1.98.1.
- Both sides use mimalloc 3.5.3, compiled from the same source (D49, D51). The
  script confirmed each build contained the right allocator.
- **Limitation:** the allocator's source matches, but its build settings don't.
  Koka builds mimalloc with 8-byte alignment (`KK_MIMALLOC=8`) at `-O2`. Rust's
  build scripts use mimalloc's default 16-byte alignment at `-O3`. This was
  found by the verification; it isn't controlled for in these numbers.
- 10 timed rounds after one warm-up run, with the versions in a fresh random
  order each round (seed 251389865). Raw times are in `data/timings.csv`; the
  full summary is in `data/summary.json`.

## Lead's checks before the run

- **Fingerprints:** every locked file matches `LOCK.md`, and git history shows
  no locked file changed after the lock. The builder reported writing source
  files only under `bench/`, and it also ran `./run.sh`, which writes `build/`
  and `data/`. That report can't be independently confirmed file by file,
  because there is no separate builder commit.
- **Same algorithm on both sides (D52):** checked line by line. Both sides use:
  - lists built from the back
  - one walk per round for benchmarks 1 and 4
  - cell-by-cell reversal for benchmark 3
  - Okasaki red-black insertion for benchmark 2, with the same comparisons and
    the same four cases. Rust re-points the existing nodes; Koka rebuilds them
    in reused memory.

  Koka's final summary makes two full walks of the list, plus a constant-time
  look at its first item, where Rust makes one walk. That's under 1% of the
  work, and it counts against Koka. Beyond the prescribed algorithms, the
  programs differ in representation and runtime, so these are whole-program
  comparisons, not identical machine instructions.

- **Rust fairness:** the same-container Rust is a competent in-place
  implementation. It is built with full optimization, including link-time
  optimization, and has no deliberate slowness. Best-container Rust is plain
  idiomatic `Vec` and `BTreeSet` code.
- **Kept value is really held (D53):** in Koka's generated C for all four "keep"
  versions, the kept value is shared (its count goes up) before the work starts
  and read after it ends. So the extra holder really does survive the whole
  time.

## Claim A: speed. PASS

Median seconds. The ratio is pure Koka ÷ same-container Rust with mimalloc.

| Benchmark            | Pure Koka | Rust, same container, mimalloc | **Ratio** | Rust, same container, standard allocator | Rust, best container, mimalloc | Rust, best container, standard allocator |
| -------------------- | --------- | ------------------------------ | --------- | ---------------------------------------- | ------------------------------ | ---------------------------------------- |
| 1. Update every item | 0.137     | 0.163                          | **0.84**  | 0.171                                    | 0.016                          | 0.016                                    |
| 2. Sorted tree       | 0.217     | 0.262                          | **0.83**  | 0.281                                    | 0.084                          | 0.086                                    |
| 3. Reverse           | 0.138     | 0.131                          | **1.06**  | 0.068                                    | 0.017                          | 0.017                                    |
| 4. Running totals    | 0.555     | 0.304                          | **1.82**  | 0.314                                    | 0.293                          | 0.294                                    |

What this shows:

- **The trick works.** For the same linked structures, pure Koka ranged from 17%
  faster to 6% slower than Rust editing in place, on the three benchmarks that
  stress memory.
- **Benchmark 4 is dominated by arithmetic.** Rust's plain array is barely
  faster than its linked list there (0.293 against 0.304), so most of the time
  goes to the `mod` arithmetic rather than memory. Koka's numbers are
  unlimited-size by default.

  **Diagnostic, not scored** (`diagnostics/`): the same Koka program with
  fixed-size 64-bit numbers (`b4i64.kk`), run by `run_b4i64.py` with its raw
  data in `b4i64-timings.csv` and `b4i64-summary.json` (seed 44891071, 10
  interleaved rounds, all outputs correct):

  | Comparison | Ratio |
  |---|---|
  | Koka `int` ÷ Koka `int64` | 1.68 |
  | Koka `int64` ÷ Rust | 1.12 |
  | Koka `int` ÷ Rust | 1.88 |

  So fixed-size numbers substantially reduce this benchmark's gap. They don't
  remove all of it. An earlier, unarchived run of this diagnostic gave 1.16×
  against Rust, and its raw data wasn't kept. The verification's independent
  run gave 1.11×.

- **Idiomatic Rust was much faster than the linked versions on benchmarks 1–3:**
  about 8.5× on benchmark 1 and 8.2× on benchmark 3 (Rust's `Vec`, a solid
  array), and 2.6× on benchmark 2 (Rust's `BTreeSet`, which also builds its keys
  directly). This is extra data (D45) about these implementations and
  whole-program workloads, not a general law. It raises a separate question
  from the trick: what building on linked structures costs.
- **Unexplained:** on benchmark 3, Rust with the standard allocator ran faster
  than with mimalloc (0.068 against 0.131), and its runs varied widely (0.066 to
  0.127). The pass rule doesn't use this number, but it isn't understood.

## Claim B: fragility. Observational

Slowdown compared with the unchanged Koka program. No change produced any Koka
warning, and every output was correct.

| Change                | b1    | b2    | b3    | b4    |
| --------------------- | ----- | ----- | ----- | ----- |
| Keep an extra holder  | 1.035 | 0.974 | 1.041 | 1.014 |
| Store and take back   | 1.005 | 0.982 | 0.997 | 1.015 |
| Pass through a helper | 1.003 | 0.987 | 1.000 | 1.011 |

What this shows, and its limits:

- **Keeping an extra holder cost about 1–4% on the lists.** That fits: only the
  first round has to copy, and the rest reuse cells (99 more rounds for b1 and
  b4, 100 for b3). The tree result (0.974,
  slightly _faster_) is within noise, and isn't explained.
- **The other two changes tested almost nothing.** The helper just hands back
  its value, and Koka's generated code has no call to it at all, because it was
  inlined away. Storing and taking back was removed as well: the compiled rounds
  loop never creates the record at all.
- **So claim B shows the trick survives these mild changes, but not how fragile
  it is under harder ones.** It also shows that when copying does happen (the
  "keep" change), **Koka gives no warning**. The slowdown is silent.

## Claim C: broken demands detected. PASS

All 12 tests went the expected way. The 6 correct functions were accepted, and
each of the 6 broken ones got the specific warning for its own violation. Koka
only **warns**, though: every broken program still compiled and ran. Mo must
refuse instead (D41).

## Claim D: demands on realistic code. PASS (7 of 10)

| Function           | Relaxed demand (fbip) | Strict demand (fip)     | Note                                                 |
| ------------------ | --------------------- | ----------------------- | ---------------------------------------------------- |
| invoice-total      | ✅                    | ❌ (through its helper) | Running total over the lines                         |
| apply-price-change | ✅                    | ✅                      |                                                      |
| update-stock       | ❌                    | ❌                      | Comparing text isn't in-place in Koka's library      |
| rotate-queue       | ✅                    | ✅                      | Restructured: the first cell is reused as the last   |
| tree-insert        | ❌                    | ❌                      | A new key needs a new node; this can't be avoided    |
| tree-remove        | ✅                    | ❌                      | Restructured: the smallest key is rotated up         |
| parse-csv-line     | ❌                    | ❌                      | Splitting text makes new text; this can't be avoided |
| merge-sorted       | ✅                    | ✅                      |                                                      |
| sort-ints          | ✅                    | ❌                      | Restructured as an insertion sort                    |
| set-city           | ✅                    | ❌                      |                                                      |

All 18 examples pass.

The locked plan still says claim D tries the strict demand; D46 changed that to
the relaxed demand, and the acceptance file follows D46. Correcting the plan is
part of the separate locked-file step.

**Correction by the lead:** the script reported invoice-total as passing the
strict demand, because it checks only the named function. Its helper
(`total-from`) fails the strict demand, so it is recorded here as ❌. The
builder flagged this gap. With that corrected, **3 of 10** pass the strict
demand. The relaxed results were checked the same way: every helper is itself
marked, and none has a relaxed warning, so the 7 relaxed successes stand.

What this shows:

- Two of the failures are **inherent**: inserting a new key and splitting text
  have to make new memory.
- The third, update-stock, is a **library gap**: Koka's text comparison isn't
  marked in-place.
- **Getting there took restructuring.** Four of the seven successes had to be
  rewritten into in-place-friendly shapes, such as an insertion sort instead of
  a merge sort.
- **The strict demand is narrow** (3 of 10). The relaxed demand is what makes
  demands practical on ordinary code.

## What the result means for D26 (for Robert to decide)

These are the lead's proposals; nothing here is decided.

1. **The invisible in-place trick is real and fast.** The evidence supports
   keeping it.
2. **Number type matters.** On benchmark 4, Koka with unlimited-size numbers
   was 1.68× slower than the same program with fixed-size numbers. How Mo
   represents numbers deserves its own decision and test.
3. **Silent slowdowns are real.** When copying happened, nothing warned about
   it. That supports making in-place demands, or compiler notes about where
   copying happens, a first-class part of Mo.
4. **Demands must refuse, not warn** (D41). The relaxed demand is the useful
   one, and it still needs restructuring.
5. **Claim B should be retested with harder changes,** ones the compiler can't
   remove. That could happen in 3b or in a follow-up.
6. **Linked structures were 2.6–8.5× slower** than idiomatic Rust collections
   on these benchmarks. How Mo stores collections is a separate question the
   data raises.

Next in the plan (D42) is 3b, the in-place helper built in Rust, on the same
benchmarks.
