# Experiment 3: acceptance

Written by the lead. Robert approves this file, and its fingerprints are then
recorded. The builder may not change it or anything in `acceptance/`.

Status: approved by Robert on 23 Sep 2026 (D50). The lead's script
`acceptance/measure.py` (run with `./run.sh`) applies these rules: it builds
every version from the builder's sources, runs and times them, checks every
output, and scores each claim. Fingerprints are in `LOCK.md`.

## Claim A: the in-place trick makes pure code fast

### The four benchmarks

Every version of a benchmark must print exactly the expected lines below. A
version that prints anything else is wrong, and its time doesn't count.

| #   | Benchmark           | Input                                                                                               | Work                                                                                  | Expected output                                                                                          |
| --- | ------------------- | --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| 1   | Update every item   | The numbers 1 to 1,000,000                                                                          | Add one to every number, 100 times over                                               | sum 500100500000, first 101, last 1000100                                                                |
| 2   | Build a sorted tree | 1,000,000 keys in a scrambled order: key number i is (i × 7919) mod 1,000,003, for i = 0 to 999,999 | Insert every key into a balanced (red-black) tree                                     | count 1000000, sum 499999547508, smallest 0, largest 1000002                                             |
| 3   | Reverse a list      | The numbers 1 to 1,000,000                                                                          | Reverse the list 101 times                                                            | first 1000000, last 1, weighted 166667166667000000 (position × value, summed, counting positions from 1) |
| 4   | Running totals      | 1,000,000 amounts: amount i is (i × 37) mod 1000, for i = 1 to 1,000,000                            | 100 times over, replace the list with its running totals, each kept mod 1,000,000,007 | first 37, last 554962791, sum-mod 491625299 (the sum of the final list, mod 1,000,000,007)               |

The lead computed these expected outputs independently in Python. Benchmark 4
was checked a second way, with a different method.

### The versions

| Version              | Rules                                                                                                                                                          |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Koka, pure           | Linked lists and trees only. No mutable variables (`var`), no references (`ref`), no vectors, and nothing marked unsafe. Built with full optimization (`-O2`). |
| Rust, same container | The same linked lists and red-black tree as the pure versions, edited in place. Built with `--release`. Run twice: once with the mimalloc allocator (the one Koka uses), which is the version the pass rule uses (D49), and once with the standard allocator, as extra data. |
| Rust, best container | What a Rust programmer would naturally use: a `Vec` for benchmarks 1, 3 and 4, and `BTreeSet` for benchmark 2. Built with `--release`, with both allocators. Extra data only (D45, D49). |

### Measuring

- Each version of each benchmark runs 10 times on this Mac, with nothing else
  heavy running. The time is the whole program's run time, including building
  the input.
- The result reports the median, the fastest and the slowest of the 10 runs.
- Raw times go in `data/timings.csv`, along with the machine, operating system,
  Koka and Rust versions, and the mimalloc version.
- `run.sh` rebuilds and re-runs everything from scratch.

### Passing

Claim A passes if, on all four benchmarks, pure Koka's median is no more than 2×
the median of same-container Rust using mimalloc (D37, D45, D48, D49). The
result also reports the actual ratio for every benchmark.

The best-container Rust numbers are reported as extra data only. Lean is not
part of this experiment's benchmarks (D47).

## Claim B: how fragile the trick is

Observational only; there is no pass or fail. The builder makes three
innocent-looking changes to each pure Koka benchmark:

| Change                | What it does                                                                                            |
| --------------------- | ------------------------------------------------------------------------------------------------------- |
| Keep an extra holder  | Keep the starting value alive until the end, for example by printing its length after the work is done. |
| Store and take back   | Each round, put the value into a record, then take it back out.                                         |
| Pass through a helper | Each round, pass the value through a helper function in another file that is not marked in-place.       |

For every change, the result records:

- the median time (10 runs) and the slowdown compared with the unchanged version
- whether Koka printed any warning
- whether the output was still correct

## Claim D: in-place demands on realistic code

The builder writes the ten functions below in Koka, in one file called
`functions.kk`, each marked with the relaxed in-place demand (`fbip`). It must
use the data types in `acceptance/claim-d/types.kk`, which it may not change.

A function counts as a success when **both** of these hold:

- Koka accepts it with no `fbip` warning.
- It passes all of its examples in `acceptance/claim-d/examples.kk`.

The builder may restructure a function so that it passes the demand, which is
normal practice for in-place code, but it must not change what the function
does. It may not use anything marked unsafe. For each function, the result also
records whether it passes the strict demand (`fip`), and gives a one-line note
on how it was written (D46).

Claim D passes if at least 7 of the 10 succeed (D39).

| #   | Function           | What it does                                                                                            | Examples (input → output)                                            |
| --- | ------------------ | ------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| 1   | invoice-total      | Adds up quantity × price, in cents, for every line of an invoice.                                       | no lines → 0; 2 × 500 and 1 × 250 → 1250                             |
| 2   | apply-price-change | Changes every product's price by a percentage. New price = price × (100 + percent) ÷ 100, rounded down. | pen 100 and pad 250, +10% → pen 110, pad 275; cup 101, −50% → cup 50 |
| 3   | update-stock       | Reduces one item's stock count; an unknown item changes nothing.                                        | a 5, b 3; sell 2 of b → a 5, b 1; a 5; sell 1 of z → a 5             |
| 4   | rotate-queue       | Moves the first item in a queue to the back.                                                            | 1, 2, 3 → 2, 3, 1; empty → empty                                     |
| 5   | tree-insert        | Inserts a key into a sorted tree; an existing key changes nothing.                                      | {1, 3, 7} + 5 → {1, 3, 5, 7}; {1, 3, 7} + 3 → {1, 3, 7}              |
| 6   | tree-remove        | Removes a key from a sorted tree; a missing key changes nothing.                                        | {1, 3, 5, 7} − 3 → {1, 5, 7}; {1, 3, 7} − 4 → {1, 3, 7}              |
| 7   | parse-csv-line     | Splits one line of comma-separated values into fields.                                                  | "a,b,,c" → a, b, (empty), c; "" → one empty field                    |
| 8   | merge-sorted       | Merges two sorted lists into one sorted list.                                                           | 1, 4, 6 and 2, 3, 7 → 1, 2, 3, 4, 6, 7                               |
| 9   | sort-ints          | Sorts a list of numbers.                                                                                | 3, 1, 2 → 1, 2, 3; 2, 1, 2 → 1, 2, 2                                 |
| 10  | set-city           | Changes the city in a customer's address, leaving everything else as it was.                            | Ann, 1 Main, Oslo → Ann, 1 Main, Bergen                              |

The lead checked that the example file compiles and works by running it against
a throwaway version of the functions in a scratch folder. That version is not
part of the experiment, and the builder never sees it.

## Claim C: broken in-place demands are detected

Each test is one small Koka function marked `fip` (the in-place demand), in
`acceptance/claim-c/`. Correct ones must be accepted with no `fip` warning.
Broken ones must get at least one `fip` warning, which counts as a refusal
(D41). Claim C passes only if all 12 tests go the expected way.

| Test file              | Expected | What it does, and why that's correct or broken                                            |
| ---------------------- | -------- | ----------------------------------------------------------------------------------------- |
| good-reverse           | Accepted | Reverses a list, reusing each cell it takes apart.                                        |
| good-add-one           | Accepted | Adds one to every number, reusing each cell.                                              |
| good-swap              | Accepted | Swaps the two halves of a stored record, reusing the record.                              |
| good-rotate            | Accepted | Rotates a small tree, reusing both of its nodes.                                          |
| good-running-total     | Accepted | Turns amounts into running totals, reusing each cell.                                     |
| good-map-pairs         | Accepted | Swaps every pair in a list, reusing each list cell.                                       |
| bad-duplicate          | Warned   | Writes every item twice, so it must make new cells.                                       |
| bad-keep-both          | Warned   | Returns the list with a changed copy of it, so the list is used twice and must be copied. |
| bad-calls-normal       | Warned   | Claims to be in place but calls an ordinary function that makes new lists.                |
| bad-build-from-nothing | Warned   | Builds a list from a number, so every cell is new.                                        |
| bad-grow-pair          | Warned   | Turns a two-field record into a three-field one, which needs a bigger, new container.     |
| bad-throw-away         | Warned   | Throws away the rest of the list, so memory is freed rather than reused.                  |

History, recorded for honesty: while checking that the tests were valid, the
lead ran a first draft through Koka before this file was approved. Three draft
tests were fixed with Robert's approval, and none changed its expected verdict:

- **bad-build-from-nothing:** Koka refused the draft for a different reason (it
  couldn't prove the function finishes). Adding Koka's `div` marker leaves only
  the in-place rule being tested.
- **bad-grow-pair:** the draft used a small pair of numbers. Koka holds those
  directly rather than as stored values, so there was nothing to waste. It now
  uses stored records.
- **good-swap:** changed to stored records for the same reason, so the test
  checks real reuse.

Fingerprints (SHA-256) of the test files at approval: to be recorded once Robert
approves.
