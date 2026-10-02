# ROB-1137: independent all-ten acceptance findings

Recorded 2026-10-02 UTC in the fresh Tester orb, before seeing any Lead findings.
Tester thread: https://ampcode.com/threads/T-01a0fb79-1151-70bb-8f33-f47c48f26fbd.
No Lead report, Builder report, Oracle finding, or other acceptance run was read.
No reply-back message was sent.

**Result: PASS, all ten locked acceptance checks. All four exact promises are
proven and independently kernel-checked in this run. No partial-proof exception
was used.** This is one Tester's acceptance result, not the Lead's result, a
merge approval, or a declaration that the whole trial has been delivered.

## Pins, reconstruction, and boundaries

- Candidate: [baf1d52649bc7a50ff7df19d0368d182efdb3fbd](https://github.com/robertguss/mo-v2/commit/baf1d52649bc7a50ff7df19d0368d182efdb3fbd).
- Amended baseline: [787e0427244837fd0f44b76c4a648d07938c3bcc](https://github.com/robertguss/mo-v2/commit/787e0427244837fd0f44b76c4a648d07938c3bcc).
- Builder plan: [ad9302cd4aacaf08ca0d82a01c3aaadca92c9201](https://github.com/robertguss/mo-v2/commit/ad9302cd4aacaf08ca0d82a01c3aaadca92c9201).
- Fetch of `rob-1136-trial-proofs-high` returned exactly the candidate. Checkout
  is detached at that candidate. The supplied plan and baseline have identical
  trees (`git diff --exit-code`, exit 0), but reconstruction used the baseline.
- Read candidate `CLAUDE.md`, `ACCEPTANCE.md`, `PROOF-BRIEF.md`, `LOCK.md`,
  `Promises.lean`, `Acceptance.lean`, the frozen example runner/data, the
  language/memory/counted semantics and named controls, `RULE.md`, the broken
  controls section of `INTERFACE.md`, and the plan's checking/stop/limits text.
- Stop condition: finish and record checks 1–10 at these pins, or report an
  integrity/setup/specification blocker without repairing candidate sources.
- Used `git archive` to reconstruct the amended baseline outside the repository
  at `/tmp/rob1137-test/reconstructed`, then overlaid ONLY candidate
  `experiments/03c-checker/trial/lean/Proofs.lean` and `Proofs/`.
  `.lake` did not exist before the build. No source or build tree came from
  another thread. All reconstructed tracked bytes match the exact candidate.
- Separately examined the complete candidate diff, all 59 changed paths, source
  command/declaration surfaces, all-source integrity scan and relevant proof
  connections. All changed files are regular `100644` Lean files. Worktree,
  untracked and ignored-file listings were empty before and after execution,
  before the explicitly requested evidence export.
- No candidate sources, locked acceptance files, Linear records or proofs were
  changed. No Oracle, child agent, commit, push or implementation fix was used.
  External evaluation inputs and four disposable mutation copies are the only
  acceptance code written.

## The four promises checked

| Promise | Plain-English statement | Independent result |
| --- | --- | --- |
| A | Every well-formed program with a valid start finishes with a readable answer. | Exact `Trial.PromiseA` accepted; fresh kernel check passed. |
| B | That answer equals the plain list/number/Boolean meaning. | Exact `Trial.PromiseB` accepted; fresh kernel check passed. |
| C | Outside holders and still-holding names keep their list values at every recorded snapshot. | Exact `Trial.PromiseC` accepted; fresh kernel check passed. |
| D | Final memory has no leaks, duplicate addresses, reserved cells, missing/cyclic reachable cells or wrong holder counts. | Exact `Trial.PromiseD` accepted; fresh kernel check passed. |

All four accepted theorems have precisely `[propext, Classical.choice,
Quot.sound]` as their printed axioms. No `sorryAx` or other axiom appears.

**Proven:** A, B, C, D. **Unfinished:** none. **Counterexamples to the approved
rule:** none found. The counterexamples below are deliberately to the named
unsafe copies, not to the approved rule.

The proof's relevant connection is structural induction over all expression
constructors, preserving ownership, holder counts, readable values and snapshot
history, then discharging final-memory obligations and connecting the actual
public runner to those results. This description is explanatory; acceptance is
grounded in the exact statements, axiom checks and fresh kernel run.

## All ten checks

| Check | Result | Evidence |
| --- | --- | --- |
| 1. Locked fingerprints | PASS | All 25 effective last-row SHA-256 entries match in both reconstruction and candidate. `hashes.json` preserves expected/actual values. |
| 2. Only allowed paths | PASS | Only `Proofs.lean` plus 58 files under `Proofs/` differ. No reports or unrelated files accompany the candidate. Empty untracked/ignored listings. `paths.txt`, `candidate-modes.stdout`, status outputs. |
| 3. Source integrity | PASS | All 59 files scanned, namespaces/imports/declarations reviewed. No banned executable forms, attributes on locked definitions, namespace escapes, parser modifications, options or code-execution directives. New helpers live under `Trial.Proofs`; only the four requested theorems are declared under `Trial`. All 13 `@[simp]` annotations mark the Builder's own theorems. |
| 4. Fresh warning-free build | PASS | `lake build Trial Checks Promises Proofs Acceptance`, exit 0, “Build completed successfully (77 jobs).” No warnings/errors; stderr empty. |
| 5. Exact theorem types | PASS | Locked `Acceptance.lean` compiled. External `Types.lean` prints all four candidate types, accepted types and expanded promise definitions; they match the locked statements with `validStart` and `runCounted Rule.approved`. |
| 6. Standard axioms only | PASS | All four accepted theorems print exactly the permitted three axioms. |
| 7. Fresh kernel recheck | PASS | `lake env leanchecker --fresh Acceptance`, exit 0; stdout/stderr empty. |
| 8. Frozen examples | PASS | `lake env lean --run Checks/Run.lean`, exit 0; all 28 runs and misreport control match. `cmp` with `results/run-1.txt`, exit 0. Both SHA-256: `4b85ff0c0561722d584e8c60b730a25d6f5cdca7d0222dde33fcc2d024ca8847`. |
| 9. Unsafe rule controls | PASS | Each named unsafe rule has a well-formed, valid-start example evaluating a named exact locked promise to false, plus its own independent one-line mutation and failed clean `Acceptance` build (each exit 1). See below. |
| 10. Never-reuse control | PASS | Only the approved branch substituted. Clean `Checks` build exit 0; frozen runner exit 0 but explicitly reports 69 mismatches, including 54 allocation/reuse/free total mismatches across 18 runs. The runner prints mismatches rather than setting a failing exit status. |

Source-scan clarification: the retained original stub comment in `Proofs.lean`
mentions the word `sorry`; comments also contain English “notation” and “prefix.”
These are not executable syntax or proof holes. The scan preserves line positions
while excluding nested comments and strings. There is no unfinished declaration,
and this is not use of the partial-proof exception. Source review includes the
exact accepted-theorem path through `eval_contract`, `promises_of_contract` and
`counted_of_main`, not only a text grep.

## Check 9: exact evaluated unsafe-rule counterexamples

`Counterexamples.lean` is an external evaluation input, imports only `Promises`,
and writes no theorem or proof. It prints the starts, well-formedness,
`validStart`, plain answer, all four exact per-run promise decisions, C1/C2 and
the complete bad outcome including every snapshot. It exits unsuccessfully if
a start is invalid, its approved comparator fails, or its named promised
violation is absent. Execution exit: **0**.

Each start has distinct addresses, no cycles or dangling links, every cell
reachable, and the exact holder counts below. Lean separately evaluates
`wellFormed` successfully and `validStart = Except.ok ()` for all three.

### Reusing a shared cell violates C

Program: `match xs do [] -> []; [h | t] -> [h + 1 | t] end`.
Start: one cell, address 1, item 1, empty link, count 2; input `xs` and an
outside holder both point to address 1.

- Plain answer and unsafe final answer: `[2]`.
- Approved A/B/C/D: `true, true, true, true`.
- `runCounted .reusesShared` A/B/C/D: `true, true, false, false`.
- Exact `NoVisibleChange start outcome`: **false**; C1 false, C2 true.
- At `matchStep4Done`, the outside holder's cell is set aside and unreadable.
  After the write, it reads `[2]` instead of its original `[1]`.
- D also fails: final cell count 1, but answer plus outside holder supply 2.

### Forgetting a freed cell's tail violates D

Program: constant `7`, with unused input `xs`.
Start: address 1 contains 11, links to address 2, count 1; address 2 contains
22, empty link, count 1. Input `xs` points to address 1; no outside holders.

- Plain and unsafe final answer: `7`.
- Approved A/B/C/D: `true, true, true, true`.
- `runCounted .forgetsRest` A/B/C/D: `true, true, true, false`.
- Exact `NoLeak start outcome`: **false**.
- Input cleanup frees address 1 but forgets its link's holder. Address 2 remains
  allocated with count 1, unreachable from the numeric answer or any outside
  holder (there are none). The memory record contains only `released 1`.

### Freeing a still-held cell violates C

Program: constant `7`, with unused input `xs`.
Start: one cell, address 1, item 11, empty link, count 2; input `xs` and an
outside holder both point to address 1.

- Plain and unsafe final answer: `7`.
- Approved A/B/C/D: `true, true, true, true`.
- `runCounted .freesHeld` A/B/C/D: `true, true, false, false`.
- Exact `NoVisibleChange start outcome`: **false**; C1 false, C2 true.
- Input cleanup decrements the count to 1 and nevertheless frees the cell.
  At `cellFreed` and later snapshots the outside holder dangles; final memory
  is empty. D also fails because the outside root cannot be reached/read.

### Three separate clean mutation builds fail

Each copy started outside the repository with no `.lake`. Each preserved all
source bytes except this one line in `Trial/Broken.lean`:

```
  | .approved => Variant.approved
```

It became, separately, the identical record used by the corresponding named
case, e.g. `| .approved => { Variant.approved with reusesShared := true }`.
The other cases and `Variant.approved` stayed unchanged. Exact diff and before/
after SHA-256, plus validation that this was the only changed path, are kept for
each copy in `*-mutation.diff` and `*-copy-validation.json`.

For each of `reusesShared`, `forgetsRest`, `freesHeld`, `lake build Acceptance`
exits **1**, after compiling the modified `Trial.Broken` and `Promises`, at
`Proofs/Final.lean:45:55`, `counted_of_main`: **unsolved goals**. Its hypothesis
describes `runMain Variant.approved`; the goal unfolds the public runner with
the selected unsafe switch set to true. Thus the proof cannot identify the
changed public runner with the original evaluator. There is also an unused
`hr` simp-argument warning at line 46. Full diagnostics are preserved.

These failures are not missing-tool, import, timeout or syntax failures.
Nevertheless, no build failure alone is treated as a semantic counterexample:
the independently executed exact predicate decisions above supply that evidence.
The builds stop at this connection lemma; they do not individually reach and
fail each of the four final theorem declarations.

## Check 10: never-reuse totals are rejected

Fourth fresh copy, same one-line procedure, with
`| .approved => { Variant.approved with neverReuses := true }`.
`lake build Checks` exits 0, and the unchanged frozen runner exits 0 and reports:

```
Approved-rule mismatch count: 69
Control mismatch count: 0
Total mismatch count: 69
```

There are 18 allocation, 18 reuse and 18 free mismatches (54 totals), plus 15
timing mismatches. Example run 1 still answers `[2, 2, 3]`, but reports
allocations/reuses/frees **1/0/1**, versus the frozen **0/1/0**.
The named misreport control remains unchanged and passes its rejection checks.
No universal theorem that `neverReuses` satisfies A–D was attempted or claimed.

## Commands and exits

`commands.jsonl` records exact argv, cwd, UTC start/end and exits for all
acceptance commands and final provenance checks; each has separate raw stdout
and stderr. Main results:

| Command / context | Exit |
| --- | --- |
| `lake env lean --version` | 0 (Lean 4.34.0, pinned release) |
| `lake build Trial Checks Promises Proofs Acceptance`, fresh reconstruction | 0 |
| `lake env lean Types.lean`, external absolute input path | 0 |
| `lake env leanchecker --fresh Acceptance` | 0 |
| `lake env lean --run Checks/Run.lean`, unmodified reconstruction | 0 |
| `cmp` frozen report versus actual stdout | 0 |
| `lake env lean --run Counterexamples.lean`, external absolute input path | 0 |
| `lake build Acceptance`, fresh `reusesShared` substitution | 1 (expected rejection) |
| `lake build Acceptance`, fresh `forgetsRest` substitution | 1 (expected rejection) |
| `lake build Acceptance`, fresh `freesHeld` substitution | 1 (expected rejection) |
| `lake build Checks`, fresh `neverReuses` substitution | 0 |
| `lake env lean --run Checks/Run.lean`, `neverReuses` substitution | 0 (69 printed mismatches) |
| `git rev-parse HEAD`, status, ignored files, candidate file modes | 0 each |
| `git diff --exit-code` baseline versus plan | 0 |
| `git diff --check` baseline versus candidate | 0 |
| `git symbolic-ref -q HEAD` | 1 (expected: detached) |

Preparation/read-only shell tool calls exited 0. An early combined read tried
the nonexistent `lakefile.lean` and `Trial/Promises.lean` paths (both `cat`
errors); the actual locked paths `lakefile.toml` and `Promises.lean` were then
read. That combined shell's last command succeeded, so its tool exit was 0.
The external audit script's first invocation exited 1 because an overly broad
`_root_` substring assertion matched ordinary names such as
`valid_start_root_ends`. The corrected check matches the actual `_root_.`
namespace syntax; audit then exited 0. The initial stderr is retained. Neither
event changed a candidate, proof, locked check or expected acceptance output.
The reconstruction/build driver and controls driver both exited 0; expected
negative-control build exits were captured separately, not suppressed.

## Limits, blockers, and transfer

- **No blockers.** No integrity discrepancy or candidate warning was found.
- These proofs quantify over this finite trial language and valid starts, not
  over Mo in general. No result about recursion, calls, nontermination, speed,
  an in-place checker or the Rust helper follows from this run.
- C covers recorded snapshots and the named observable lists. Whether snapshot
  placement covers every relevant operation, and whether liveness accounting
  captures every needed name, retain the locked document's code-reading limits.
  Intermediate results are not separately covered by C; B covers the answer.
- D concerns final memory, not final bindings/intermediate bookkeeping. The
  proof is about locked Lean definitions. English-rule correspondence remains
  supported by the frozen examples, not universally proved.
- Standard Lean axioms and the correctness of the pinned kernel/evaluation
  tooling are still trusted. A fresh kernel pass is not a proof of the toolchain.
- Evidence export contains this original report, logs, hashes, audit evidence,
  disposable-mutation instructions/diffs and external evaluation inputs. It
  excludes the candidate source tree, complete proof diff and all build trees.
- This Tester performed no delivery changes. Candidate sources remain at the
  requested detached commit. Lead comparison, any project write-up and Robert's
  merge decision remain outside this assignment.
