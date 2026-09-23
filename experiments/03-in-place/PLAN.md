# Experiment 3: pure code, updated in place

Approved by Robert on 23 Sep 2026 (D44).

## The idea being tested (D26)

- No value is ever changed in place, from the program's point of view.
- The compiler counts who holds each value. When only one holder exists, it
  updates the value in place instead of copying it, and the program can't tell.
- A function can demand in-place updating. The checker either proves the demand
  or refuses the program.

## The tool

Koka (version 3.2.9, from Homebrew). Koka already implements this idea: its
counting is called Perceus, and its in-place demand is the `fip` marker. We test
the idea in Koka before Mo builds its own version (D40).

Baseline: the same programs written with ordinary in-place edits in Rust.

Lean 4 is not part of this experiment's benchmarks (D47). Its role is proving
that the in-place rules are correct, in 3c and later in Mo.

## The claims and how each one passes

| Claim | What it says                             | How it's measured                                                                                                        | Passes when                                                                                                                                                                                                              |
| ----- | ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| A     | The in-place trick makes pure code fast. | Each benchmark program is run in pure Koka and in edit-in-place Rust.                                                    | Pure Koka is within 2× of Rust on every program (D37).                                                                                                                                                                   |
| B     | We know how fragile the trick is.        | Small, innocent-looking changes are made to each program, such as keeping an extra copy of a value. We time each change. | Observational: for every change, the result records whether it slowed the program, by how much, and whether anything warned about it. There is no pass or fail.                                                          |
| C     | The checker enforces demands.            | Correct `fip` functions are written, plus planted broken ones that secretly copy or allocate.                            | The checker accepts every correct function and refuses every broken one. Accepting a broken one fails. So does refusing a correct one, because a checker that refuses everything proves nothing (Experiment 1's lesson). |
| D     | Demands work on realistic code.          | Try `fip` on 10 realistic functions (list below).                                                                        | At least 7 of the 10 succeed (D39).                                                                                                                                                                   |

Note on claim C (D41): Koka only warns about a broken demand; it still
accepts the program. The experiment counts that warning as a refusal, so claim C
tests detection. `RESULT.md` must say that Koka only warns and that Mo must
refuse.

## Benchmark programs

Each program is small, and each updates a large value many times.

1. **Update every item:** add one to each of 1,000,000 numbers in a list.
2. **Build a sorted tree:** insert 1,000,000 numbers into a balanced tree. This
   is the standard benchmark for this technique.
3. **Reverse a list:** reverse a 1,000,000-item list, 100 times.
4. **Running totals:** turn a list of 1,000,000 amounts into a list of running
   balances.

## Realistic functions for claim D

These cover invoice totals, a price change applied to a product list, stock
updates on an inventory record, reordering a queue, inserting into a sorted
tree, removing from a sorted tree, parsing a line of comma-separated values,
merging two sorted lists, sorting, and updating one field in a nested record.

## Data captured (D38)

- Every run is repeated 10 times, and the median and spread are reported.
- Raw timings are kept in a data file next to the result, along with the
  machine, operating system, and Koka and Rust versions.
- One script re-runs every benchmark, so anyone can reproduce the numbers.
- `RESULT.md` gives each claim in plain English, the numbers as a table, and
  what the numbers mean for D26.

## How the work is split (the lock pattern)

1. The lead writes this plan and the acceptance files. Robert approves them, and
   their fingerprints (hashes) are recorded.
2. A builder, in a visible Herdr pane, writes the programs only. It may not
   touch the plan, the acceptance files or the thresholds.
3. The lead checks the builder's work independently. It re-runs every benchmark
   from scratch, confirms each planted broken function really is broken, and
   compares the hashes.

## Stop condition

The experiment stops when any of these happens:

- All four claims have measured results written up in `RESULT.md` with the raw
  data.
- Koka can't be installed or run on this Mac. We stop and report back.
- A claim turns out not to be measurable as described. We stop and bring it to
  Robert, and do not change the claim ourselves.

## What this won't tell us

- It tests the idea in Koka, not Mo's own implementation.
- It doesn't test D26 combined with proofs (D24) or with effects (D30).

## Follow-on experiments (D42)

- **3b:** the in-place helper built in Rust, using counted values that are
  copied only when shared (`Rc` with `make_mut`). It runs the same four
  benchmarks and is compared with Koka's numbers. It also serves as the
  Swift-style alternative.
- **3c:** a toy pure language with a checker for in-place demands, following
  Koka's published rules, with Lean used to prove those rules correct (D47). It
  runs only if 3b looks promising.

## Afterwards (D38)

The realistic alternatives are tested the same way and compared with these
results: Rust's ownership, Swift-style value semantics, and a pure language with
a garbage collector (such as OCaml or Haskell).

Candidates, not commitments (agreed 23 Sep 2026):

- **Swift:** the copy-when-shared helper built into the language, as a native
  version of the 3b comparison.
- **OCaml or Haskell:** pure code with a garbage collector instead of counting.
  This is the main alternative for the comparison.
- **Futhark:** an in-place demand whose violations are refused, not just warned
  about. A reference for claim C and for 3c.
- **Idris 2:** "used exactly once" expressed in the type and proven by the
  checker. A reference for 3c.
- **Roc:** a third implementation of the same trick, used only once it is
  stable.
- **TLA+:** not for this experiment. It is for running programs (supervisors,
  processes, where state lives) and for checking the helper when several
  threads share counts.
