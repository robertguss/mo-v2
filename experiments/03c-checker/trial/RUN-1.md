# The trial's run: the counted meaning against the frozen predictions

**Run 1, 30 Sep 2026.** Phase 1, step 4 of `PLAN.md` ("How the trial runs").
Written by the lead. The run's own output is `results/run-1.txt`, kept exactly
as the program printed it. Nothing here is a decision.

## The result in plain English

Every one of the twenty-eight example runs came out exactly as Codex predicted
from the English rule, before any Lean version of the rule existed. That covers
each answer, the numbers of allocations, reuses and frees (counted from memory's
own record of what it did, not from the rule's log), and every timing claim on
runs 9, 10 and 11. The report has 438 items (431 for the twenty-eight runs,
7 for the control) and no mismatch.

On every run the two promise checks held too: at the end, the cells still
allocated are exactly those reachable from the answer and the outside holders,
with every holder count right (promise (d)); and every list an outside holder
can see reads the same in every snapshot (promise (c)). The counted answer also
equalled the plain meaning's answer every time.

The misreport control did what it must. The deliberately broken copy that frees
a cell and builds a replacement but logs a reuse, run on run 2, gave the right
answer, `[2]`, and the checks rejected it on the counts: memory's record showed
1 allocation, 0 reuses and 1 free where 0, 1 and 0 were predicted. In the
report, the control's item "log versus memory record" is marked `MATCH` although
the two differ: there `MATCH` means the expected disagreement was seen (the log
says a reuse; memory's record says a free and an allocation). The control passes
because its answer is right and readable while its totals from memory's record
fail the comparison with the predictions.

So there is nothing to classify: no wrong prediction, wrong encoding, fault in
the rule, fault in the checks, or setup failure showed up.

## What this shows, and what it does not

- **It shows** that the Lean encoding of the approved rule (D91, with D97)
  agrees with predictions written independently from the same English text, on
  these twenty-eight runs, down to the order of events the timing claims name;
  and that the checks reject the one known misreport they were built to catch.
- **It does not show** that the rule is right for every program. That is the
  proof, phase 2, which Robert decides whether to start (`PLAN.md` step 6).
- **The agreement is not fully independent.** The predictions and the encoding
  both come from the same English rule, so a misreading of the rule shared by
  both would show up as agreement. What keeps them apart: the predictions were
  written by a separate Codex session from the English alone and frozen (D95)
  before the Lean existed; the checks were written by another separate Codex
  session (`CHECKS-BRIEF.md`), not by the lead or the worker who wrote the
  encoding.
- **What the lead saw before the run.** As the Status recorded at the time, the encoding was committed in `7b3b740`
  without the lead or the worker having opened the predictions. The only change
  to it since, D98's extra recording in the snapshots (`c92119f`), changes
  nothing a run does (the lead's checks in `lead-checks/D98/`). In order: the
  check-writing session's first stop report quoted two predicted values (on runs
  10 and 11); the D98 change was then made, adding what the snapshots record and
  changing nothing a run does; after it, the session's final report printed a
  table of most predicted answers and totals. No encoding changed after that
  table was seen.
- **Not run:** the three unsafe broken copies and the copy that never reuses.
  `INTERFACE.md` section 7 keeps them for after the proof. (The worker ran them
  early on programs of its own; D99 records that departure.)

## What was run

| Item          | Value                                                                                                                                                               |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Commit        | `774c58f` on `main`, clean                                                                                                                                          |
| Toolchain     | Lean 4.34.0 (`lean-toolchain`: `leanprover/lean4:v4.34.0`), arm64 macOS                                                                                             |
| Build         | `lake build Trial Checks` in `lean/`: no errors, no warnings                                                                                                        |
| Command       | in `lean/`: `lake env lean --run Checks/Run.lean > ../results/run-1.txt 2>&1`, in a visible shell pane                                                              |
| Exit status   | 0, saved to a file straight after the run                                                                                                                           |
| Output        | `results/run-1.txt`, 940 lines, program output and error stream together, unedited                                                                                  |
| Completeness  | run sections 1 to 28 each exactly once; the separate misreport-control section; the three mismatch counts at the end, all 0; 438 items, all `MATCH`                 |
| Repeatability | a second run on the same setup gave byte-for-byte the same output (on this setup only; it does not show that the output depends on nothing but the committed files) |

Fingerprints (SHA-256) at the run. The frozen and approved documents match
`LOCK.md`:

| File                           | SHA-256                                                            |
| ------------------------------ | ------------------------------------------------------------------ |
| `PREDICTIONS.md`               | `f4ad4897030fc558b100ace0f65163fe36234833e4300925ebc97d66310c7658` |
| `EXAMPLES.md`                  | `2052d414d621549691913badc90025085a5888bc1cd505b7d0bb26ac87d85f54` |
| `RULE.md`                      | `ea918fb4899b7f540fc42743831b824b8fadad45b1d95b4a2b4faa9079926d40` |
| `INTERFACE.md`                 | `91297547225831666507036b41b1e3c2a0fc6723223584a0553cf5411c709320` |
| `PLAN.md`                      | `3f110af9f3798662921ecae44d8d9c934339cf51d53209cebd12096c892e76f3` |
| `lean/Checks.lean`             | `6ffad427c10183edc8dc632786d57374b5a260488232290c6a7c69474d79a3ce` |
| `lean/Checks/Examples.lean`    | `02d0cbc814d9533211a0fc0010a8b2dffee16a44dc74f2206406ebb3fcd4e846` |
| `lean/Checks/Predictions.lean` | `c2c0f0b81c92bef06fa4ff3c803b602c01f44b2ba25c14fb9ef270a770d57408` |
| `lean/Checks/Run.lean`         | `92ec0acfbffc150a354aa7e74ef9ea91c5805c7b9678b7ac9ddeea0e8f48c24b` |
| `lean/Trial.lean`              | `9bc52e4245a1bdf8fd8f7be8d8bb5e23248b033fc95aa82734b0d612014fdbe8` |
| `lean/Trial/Broken.lean`       | `fb4f1f26a4584e217eea0be9c4c49f33eca946480c9ff23c79c6ee45fd046a5b` |
| `lean/Trial/Counted.lean`      | `fe299d069daf6be3cdce68633e891cd5133a35404ca5378ffbe93690594d26f2` |
| `lean/Trial/Language.lean`     | `2aef4053975808559849881c376cc88b7dd290269a73c571d0c605ed42492913` |
| `lean/Trial/Memory.lean`       | `fefb1d40ba9e5d08eb986d5c3174889e1f2f0b7127c94e12dce54230df729355` |
| `lean/Trial/Plain.lean`        | `bac8b5df8920396ddccd351548a4fad7a880d3c6d89336015dccaa56f7d2b0c2` |

## Mismatches

None. Had there been any, each would be listed here with what was predicted,
what happened, and the lead's proposed classification with Codex's review, and
put to Robert one at a time.

## Next

`PLAN.md` step 5, in a fresh session: the promises as Lean statements,
`ACCEPTANCE.md` (the same in plain English, with the examples as tables) and the
proof builder's brief; Codex's one bounded question ("can a builder pass these
checks while failing the intended task?"); Robert's approval; and the full lock
in `LOCK.md`. Then step 6: Robert sees these results and decides whether the
proof phase starts.
