# Finite model / Rust correspondence

**Passed the bounded comparison:** 4,276 cases and 27,721 exposed snapshots matched
the accepted Lean model. Five actual compiled incorrect variants were rejected.
This is finite execution evidence, not a proof of the Rust implementation or of a
future Mo compiler. New harness and Rust implementation are same-author work under
the owner's earlier self-verification preference; the unchanged accepted Lean
model and original predictions retain their separate historical authorship.

ROB-1146; owner authorization recorded in D124. Frozen inputs, specification,
exporter and checks committed at `77b208b` before Rust implementation. The accepted
trial and 3b helper remain unchanged (270 tracked file fingerprints verified).
Experiment 9 is still separately unmerged; this branch starts from main.

## What was compared

A small stdlib Rust interpreter executes the existing finite language over real
boxed list cells. It never reads the expected results. The Lean exporter supplies
only programs/starting memories as its input; the harness compares the output.
Each logical creation constructs a boxed cell, reuse modifies that same object,
and release drops it. Physical pointer traces and separate allocation/drop
counters check these operations, alongside the model's logical event records.

| Corpus | Cases | Scope |
| -- | -- | -- |
| Original accepted examples | 28 | All programs, starting memories and original frozen predictions, including values beyond signed 64-bit range |
| Generated cases | 4,248 | 177 expression templates × 8 memory shapes × 3 numeric inputs |
| Total | 4,276 | 27,721 snapshots |

Generated expressions have depth at most three (leaves depth zero), at most three
initial cells and two list input names, xs/ys, plus numeric input n in -1/0/1.
Memory shapes cover empty, unique one/two/three-cell lists, two names sharing a
head, two heads sharing a tail, and outside holders on the head or tail. Cell
items follow fixed -1/0/1 prefixes. Templates exercise all existing expression
constructors/operators, branch choices, unused names, nested matching and
shadowing. The 28 original examples are not constrained by these generated bounds.

This is **not** all well-formed expressions or all valid heaps in those bounds.
Excluded: arbitrary combinations of templates, arbitrary identifier spellings,
all item permutations, more outside holders, every sharing graph, invalid programs,
calls, recursion, concurrency and native loading. Names/inputs use a fixture wire
format, not a Mo parser. Arithmetic is checked i128 for this corpus; overflow
would stop the run. This neither implements arbitrary-size integers nor selects
Mo's number policy.

Comparison covered raw and readable answers, final cell identities/links/counts,
ordered memory events and rule logs, and every exposed snapshot including bindings,
pending/outside holders, reservations and finishing-branch values. A single global
identity bijection per run maps initial cells in fixture order and new cells in
creation order; mappings survive frees. It cannot relabel each snapshot separately
to hide changed sharing. Native addresses are checked for same-object reuse but
are not compared with Lean's logical IDs. This prototype mirrors reference snapshot
scheduling to enable a stronger finite trace comparison; that schedule is not a
permanent language or backend requirement.

Independent Python walks (separate from the Rust interpreter) checked readable,
unchanged outside and holding-name lists, exact final reachability and holder
counts, and no leftover reservation. They are independently implemented checks,
not independently authored acceptance. Initial fixture setup was excluded from
the evaluation interval and counted separately; all evaluation preparation was
included.

| Observed operation | Count across corpus |
| -- | -- |
| Fixture cells constructed | 9,617 |
| Evaluation cell creations | 304 |
| In-place cell writes | 89 |
| Evaluation cell releases | 5,269 |

The Rust allocator also observed 1,481,440 allocation/reallocation requests and
53,429,971 requested bytes during the measured intervals. These include evaluator
bookkeeping, snapshots and their serialization. Bytes are cumulative requests,
**not** live or peak memory; these totals are not a performance benchmark. Final
result/fixture cells are dropped when each run state is destroyed, outside this
evaluation interval. Physical cell counters matched logical creates/releases for
every individual case, not just aggregate totals.

## Deliberately incorrect implementations

All controls changed actual Rust source, compiled successfully and reused the
frozen predicates without changed expectations:

| Broken behavior | Observed rejection |
| -- | -- |
| Reuse a shared cell | Original example 5 exposes an outside holder pointing to a reserved/unreadable cell |
| Free a still-held cell | Original example 5 fails while accessing a freed cell |
| Forget to release the tail | Original example 11 leaves unreachable live storage |
| Always allocate instead of reusing | Original example 1 returns a different cell identity/trace |
| Copy before evaluation and hide it from the logical record | Original example 1's physical allocation counter exceeds recorded creations |

`controls-01` preserves an invalid control-runner assumption: it expected the
shared mutation to panic immediately in example 5. It actually emitted the
unreadable-holder snapshot there and later formed a cycle in example 14. The
runner initially refused to count that as the intended catch. `mutate-01.py`
retains the first runner. The corrected runner applies the **same frozen safety
predicate** to already emitted reports, finding example 5's direct defect; it
separately records the later crash. It does not accept an arbitrary crash or
compilation failure as this control's witness. All five controls were then run
in `controls-02`.

## Attempts and integrity

- Export setup attempt 1 failed on a Lean namespace ambiguity and an imported
  main-name collision. Its source and output are retained. The corrected exporter
  ran the unchanged model and original prediction checks, yielding all 4,276 cases.
- Rust attempt 1 did not compile: an IO error type was captured across a panic
  boundary. Moving the stdin unwrap outside that boundary repaired setup. No
  behavioral comparison ran in that attempt; its complete source/log are retained.
- The first compiled behavioral comparison (`run-02`) matched every case. No
  implementation behavior or acceptance expectation was repaired after a mismatch.
- A fresh disposable copy rebuilt the Lean reference and reproduced the frozen
  exported expectations byte for byte (`reference-rebuild-01`).
- `LOCK.json` verifies the preimplementation specification/exporter/check/expected
  fingerprints. `reference-sha256.json` verifies all 270 original tracked files.
  Prior accepted source, proofs, checks and locks were not edited. This work adds
  no Lean axioms or proof promises; it imports the existing executable model.

## Reproduction and evidence

From repository root, with the trial's pinned Lean 4.34.0 toolchain, Rust and
Python installed (each output directory must be new):

```sh
python3 experiments/10-finite-rust/reproduce_reference.py /tmp/mo-reference-new
python3 experiments/10-finite-rust/check.py /tmp/mo-correspondence-new
python3 experiments/10-finite-rust/mutate.py /tmp/mo-correspondence-controls-new
```

`evidence/expected.jsonl.gz` retains every input and reference trace.
`evidence/run-02` retains Rust's complete output, source and per-case allocator
samples. `evidence/controls-*` retain mutated sources, failed reports and witnesses.
`evidence/verification.json` aggregates counts without replacing those records.
`evidence/MANIFEST.json` fingerprints retained artifacts. No binary is committed.

The result connects the finite proof model to one executable Rust interpreter on
this corpus. It does not establish universal refinement, general Rust memory
safety, a demand checker, compiler optimization correctness, an efficient runtime,
or full3c. No further experiment or merge was performed. Next is the remaining
Needs Input discussion with Robert.
