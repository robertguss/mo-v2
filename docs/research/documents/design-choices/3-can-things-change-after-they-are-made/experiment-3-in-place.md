# Experiment 3: in place

**Label:** Planned

Tests D26 (D36). Plan: https://github.com/robertguss/mo-v2/blob/main/experiments/03-in-place/PLAN.md

* Tool: Koka, with edit-in-place Rust as the baseline (D40).
* Claim A: the in-place trick makes pure code fast; passes within 2x of Rust (D37).
* Claim B: how fragile the trick is; observational.
* Claim C: every broken demand detected, every correct one accepted; Koka only warns, which counts as a refusal (D41).
* Claim D: demands work on at least 7 of 10 realistic functions (D39), counting Koka's relaxed demand fbip (D46).
* Claim A compares against Rust with the same container; Rust's best container is extra data (D45).
* Lean 4 is not in the benchmarks; its role is proving the in-place rules correct, in 3c and in Mo (D47, superseding D43).
* Follow-ons (D42): 3b, the helper in Rust; 3c, a toy language with a demand checker, if 3b looks promising.
* Principle (D38): decisions rest on measured data; alternatives are tested the same way and compared.

Found while setting up: Koka's fip check only warns and still accepts the program.

Candidates for later comparison (not commitments): Swift, OCaml or Haskell, Futhark, Idris 2, Roc; TLA+ for running programs and concurrency.

## Published evidence on speed (read 23 Sep 2026, from the papers' own figures)
* Perceus paper (Reinking, Xie, de Moura, Leijen; MSR-TR-2020-42, Fig. 9; AMD 3600XT, Linux; times relative to Koka): rbtree, C++ std::map 0.92, so Koka is about 1.09x C++ ("within 10%"). nqueens: C++ 0.79, so Koka about 1.27x. OCaml 1.26, Java 1.67, Haskell 2.40 on rbtree. Koka with reuse turned off: 2.45.
* FP2 paper (Lorenzen, Leijen, Swierstra; ICFP 2023, Fig. 11; AMD 7950X, Linux; relative to Koka fip): rbtree, C++ std::map 1.44 with the standard allocator and 0.95 with mimalloc. tmap (a shared tree, so no reuse is possible): C 1.25 with the standard allocator and 0.56 with mimalloc, so fip is about 1.8x the fastest C. No C versions for ftree, msort or qsort.
* Takeaways: tree insertion is about 1x of C or C++; the published worst case is about 1.8x, where reuse is impossible; the memory allocator alone moves C++ by about 1.5x.
* Sources: https://www.microsoft.com/en-us/research/wp-content/uploads/2020/11/perceus-tr-v4.pdf and https://www.microsoft.com/en-us/research/wp-content/uploads/2023/05/fip-tr-v2.pdf

## Result (23 Sep 2026): claims A, C and D pass; claim B is observational

Full write-up, corrected after the Codex verification (D55): [RESULT.md](../../../../../experiments/03-in-place/RESULT.md).

* A (speed, pass): pure Koka vs same-container Rust with the same mimalloc: b1 0.84x, b2 0.82x, b3 1.06x, b4 1.84x (re-run after the D56 scoring fixes). b4 is dominated by arithmetic. In a diagnostic, Koka with fixed-size int64 numbers was 1.68x faster than with its default int, leaving 1.12x against Rust. The allocator's build settings differ between the sides (8- vs 16-byte alignment).
* B (fragility, observational): keeping an extra holder cost 1-4% on lists, with no warning. The helper and store-and-take-back changes were optimised away by the compiler, so B tested less than planned.
* C (detection, pass): all 12 as expected, each broken test with its specific warning. Koka only warns.
* D (realistic code, pass): 7 of 10 with the relaxed demand; 3 of 10 with the strict one (invoice-total fails through its helper). Failures: tree-insert and parse-csv-line (inherent), update-stock (library gap).
* Idiomatic Rust collections were about 2.6-8.5x faster than the linked versions on b1-b3.
* The lead's readings are proposals for Robert to decide.

## What the result means for D26: the six readings, all decided (23 Sep 2026)

1. **D26 confirmed as tested** (D57): the invisible in-place trick is real and fast, and demands can be checked.
2. **Numbers** (D58): how Mo represents numbers is design choice 10, open, to be tested. Koka's unlimited-size numbers were 1.68x slower than fixed-size int64 on benchmark 4.
3. **Copying outside explicit demands** (D59): what Mo says about it is an experimental question, not a decision. Experiment 3 showed copying is silent, not that it is costly (claim B: 2% faster to 4% slower). The follow-up, possibly inside 3b, as shaped with Codex: success is better speed with correct behaviour, not fewer copies; "no change needed" on a harmless case is a pass; fresh agent sessions per feedback condition; separate the information question (static note against runtime profile) from the delivery question (always-on against on request); the lead writes the checks first, Robert approves them in plain English, the repairing agent cannot touch them.
4. **Demands must refuse, not warn** (D62): already D26; nothing new to decide. Whether Mo's own checker enforces it (a proof) and whether useful programs can meet it (examples and experiments) are two separate checks for 3c. Experiment 3 showed feasibility on Koka's twelve cases only.
5. **Claim B retest** (D63): one bounded repeated-sharing list case inside 3b, observational with validity gates.
6. **Sequences** (D65): the 2.6-8.5x gap to idiomatic Rust collections motivates design choice 11, how sequences are stored and updated, without isolating a cause. Its first experiment comes after 3b.

The 3b draft plan is at https://github.com/robertguss/mo-v2/blob/main/experiments/03b-helper/PLAN.md.
