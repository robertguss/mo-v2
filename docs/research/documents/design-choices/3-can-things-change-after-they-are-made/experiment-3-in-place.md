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

## Result (23 Sep 2026): all four claims pass

Full write-up: [RESULT.md](../../../../../experiments/03-in-place/RESULT.md).

* A (speed, pass): pure Koka vs same-container Rust with the same mimalloc: b1 0.84x, b2 0.83x, b3 1.06x, b4 1.82x. b4 is arithmetic-bound; a diagnostic with fixed-size int64 numbers ran at 1.16x, so the gap is Koka's unlimited-size numbers, not the trick. Idiomatic Rust arrays are 3-9x faster than any linked structure.
* B (fragility, observational): keeping an extra holder cost 1-4% on lists, with no warning. The helper and store-and-take-back changes were optimised away by the compiler, so B tested less than planned.
* C (detection, pass): all 12 as expected, each broken test with its specific warning. Koka only warns.
* D (realistic code, pass): 7 of 10 with the relaxed demand; 3 of 10 with the strict one (the lead corrected invoice-total, which fails through its helper). Failures: tree-insert and parse-csv-line (inherent), update-stock (library gap).
* The lead's readings are proposals for Robert to decide.
