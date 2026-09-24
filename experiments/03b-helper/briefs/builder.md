# Brief: builder, Experiment 3b

You are the builder for Experiment 3b. Work only in `experiments/03b-helper` of
the mo-v2 repo. Read `CLAUDE.md` at the repo root first, then `PLAN.md` and
`ACCEPTANCE.md` in this folder. Those two files define the job and how it is
scored. Tools: Rust 1.98 (`cargo`) and Koka 3.2.9 (`koka`), both installed.

## Locked: read, never change

`PLAN.md`, `ACCEPTANCE.md`, `LOCK.md`, `run.sh`, and everything under
`acceptance/`. Their fingerprints are recorded. Don't read anything under
`briefs/` except this file, and don't read anything under `council/`. You may
read Experiment 3's `experiments/03-in-place/bench/` for reference, but never
change anything outside `experiments/03b-helper/bench/`.

## Write: only under `bench/`

1. **The helper:** a Rust library crate at `bench/helper/`.
   - `Cargo.toml` declares `name = "helper"`, `version = "0.1.0"`,
     `edition = "2021"`, and nothing else: no dependencies, no build script.
   - It provides exactly the types and signatures in ACCEPTANCE.md's appendix.
     The lead's harness in `acceptance/harness/` compiles against them, and its
     drivers are the programs that get timed.
   - Every list cell and every tree node is its own `Rc`. An operation changes a
     cell or node in place when its holder count is one, and copies it
     otherwise, so no other holder ever sees a change. `Rc::make_mut`,
     `Rc::get_mut` and `Rc::try_unwrap` are the natural tools.
   - `Clone` adds a holder and must not copy or allocate.
   - Use exactly the algorithms in ACCEPTANCE.md's "The same algorithm on both
     sides" table. Experiment 3's `bench/rust-same/src/bin/` is the reference
     for them; the lead checks the correspondence step for step.
   - With one holder: add one, reverse, running totals and pop from the front
     allocate nothing, and inserting a new key allocates exactly one node. With
     more than one holder, copy only what the operation must change.
   - Free long lists in a loop, not by recursion, and stop at a cell another
     holder still shares.
   - Plain safe Rust only: no `unsafe`, no `Cell`, `RefCell` or other
     interior mutability, no `Weak`, no `Arc`, no raw pointers or `std::ptr`,
     no `static` items, locks or atomics, no `std::alloc`, `env`, `fs`,
     `process`, `time` or `thread`, no `extern`, no macros, no `#[path]`, and
     no `cfg` on features, targets or debug assertions. The script screens for
     these, and the lead reads the source; the lead's reading decides.
   - When the last holder lets go, everything must be freed. The checks count
     live memory blocks.
2. **Claim B, Koka:** `bench/koka-share/b1-share.kk`, `module b1-share`.
   - Start from Experiment 3's `experiments/03-in-place/bench/koka/b1.kk`.
   - Each of the 100 rounds keeps the previous list, builds the new one with
     add one, reads the first value of both and adds (new first minus kept
     first) to a running count, and in the last round sums the kept list. The
     kept list is then no longer used.
   - It prints Benchmark 1's three lines, then `rounds-differ 100` and
     `prev-sum 500099500000`, one per line, as `name value`, and nothing else.
   - No `var`, no `ref`, no vectors, and nothing unsafe.

## Rules

- Don't change any locked file, and don't write outside `bench/`. You can run
  `./run.sh --checks-only` for the correctness checks, or `./run.sh --runs 2`
  for a quick exploratory run with no verdict, as often as you like, but you
  may not change how anything is scored. Finish with one full `./run.sh`.
- Don't tune anything to the scoring: no special-casing sizes, no detecting
  being measured, no printing expected values without computing them.
- Stop condition: stop when both files above exist and `./run.sh` completes.
  Whatever the scores are, don't try to improve a failing claim by bending
  these rules. If something can't be written as described, stop and say
  exactly what and why.
- No git operations. Never use `tr` in shell commands; use python3.

When you're done, print a short summary: which files you wrote, the final
`./run.sh` output, anything you couldn't do, and how long it took.
