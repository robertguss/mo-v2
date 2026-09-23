# Brief: builder, Experiment 3

You are the builder for Experiment 3. Work only in `experiments/03-in-place` of
the mo-v2 repo. Read `CLAUDE.md` at the repo root first, then `PLAN.md` and
`ACCEPTANCE.md` in this folder. Those two files define the job and how it is
scored. Tools: Koka 3.2.9 (`koka`), Rust 1.98 (`cargo`), both installed.

## Locked: read, never change

`PLAN.md`, `ACCEPTANCE.md`, `LOCK.md`, `run.sh`, and everything under
`acceptance/`. Their fingerprints are recorded. Don't read anything under
`briefs/` except this file.

## Write: only under `bench/`

1. **Pure Koka benchmarks:** `bench/koka/b1.kk` to `b4.kk`, one program per
   benchmark in ACCEPTANCE.md, in that order: update every item, build a sorted
   tree, reverse a list, running totals.
   - Linked lists and trees only. No `var`, no `ref`, no vectors, and nothing
     unsafe; the script rejects any of these.
   - Write them as natural pure code that lets Koka's in-place reuse work.
   - Each program prints exactly the expected lines from ACCEPTANCE.md, one per
     line, as `name value`, and nothing else. For example, `b1` prints
     `sum 500100500000`, then `first 101`, then `last 1000100`.
   - Benchmark 2 is a red-black tree insertion of the 1,000,000 scrambled keys.
2. **Claim B variants:** `bench/koka-b/b{1..4}-{keep,box,helper}.kk`, which is
   12 files, and any helper modules in the same folder. Each file is its
   benchmark from step 1 with exactly one of the three changes in ACCEPTANCE.md
   applied, and it still prints the same expected lines. The "helper" change
   passes the value, each round, through a function in a separate module file in
   `bench/koka-b/` that is not marked in-place.
3. **Rust, same container:** a Cargo project at `bench/rust-same/` with binaries
   `b1` to `b4` in `src/bin/`.
   - Use the same structures as the Koka versions: singly linked lists, and a
     red-black tree, both edited in place.
   - Add an optional Cargo feature named `mimalloc` that switches the global
     allocator to the `mimalloc` crate.
   - The outputs must be the same expected lines.
4. **Rust, best container:** a Cargo project at `bench/rust-best/` with binaries
   `b1` to `b4`, using `Vec` for benchmarks 1, 3 and 4 and `BTreeSet` for
   benchmark 2, and the same `mimalloc` feature.
5. **Claim D:** `bench/claim-d/functions.kk`, `module functions`, with
   `import types`. It holds the ten functions in ACCEPTANCE.md, using exactly
   the names and argument order that `acceptance/claim-d/examples.kk` calls, and
   the types in `acceptance/claim-d/types.kk`.
   - Mark each one `pub fbip fun`.
   - Restructuring a function to pass the demand is fine. Changing what it does
     is not.
   - If a function can't pass the demand, leave it marked `fbip` anyway and
     write the most natural correct version. It is recorded as a failure, and
     that is a valid result.
   - Put a one-line comment above each function saying how it was written.

## Rules

- Don't change any locked file, and don't write outside `bench/`. You can run
  `./run.sh` (or `./run.sh --runs 2` for a quick check) as often as you like to
  see the scores, but you may not change how anything is scored.
- The Rust versions are the yardstick, so write them the way a competent Rust
  programmer would, and make them no slower or clumsier than that. A slow
  baseline makes Koka look better than it is. The lead reviews the Rust code for
  exactly this.
- Don't tune anything to the scoring: no special-casing the benchmark sizes, no
  printing the expected values without computing them, and no timing tricks.
  Every program must really do its work.
- Stop condition: stop when every file above exists and `./run.sh` completes.
  Whatever the scores are, don't try to improve a failing claim by bending these
  rules. If something can't be written as described, stop and say exactly what
  and why.
- No git operations. Never use `tr` in shell commands; use python3.

When you're done, print a short summary: which files you wrote, the final
`./run.sh` output, anything you couldn't do, and how long it took.
