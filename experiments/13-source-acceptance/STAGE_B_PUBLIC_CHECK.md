# Stage B public check — final-02 fails

This is the independent public check of the builder's final-02 archive. It is
not acceptance. Private cases, the nine sabotage controls, and both
million-element runs were not run. The candidate source was not imported.

D168, Robert's decision that checking starts at final-02 and that `im` may be
replaced by the maintained `imbl` library, is the submission this check used.
Final-01 was not opened.

## Results

| Check | Result |
| --- | --- |
| Integrity | PASS. 8 files. Archive and manifest hashes match. All 7 content files match the manifest. |
| Toolchain build | PASS. `fetch --locked`, then `build --locked --offline`, for the candidate and for the acceptance linker. The candidate lock did not change. |
| Source audit | PASS. No production forbidden pattern. |
| Public examples | FAIL. 18 of 21 matched. C4, C5 and C6 failed. |
| Files unchanged | PASS. All 496 frozen files still match. All 7 supplied content files still match the manifest after the runs. |

The candidate's own development suite, which is not an acceptance check, passed
52 tests. There are no doc-tests.

## Integrity

Archive `rob1333-stage-b-candidate-final-02.tar.gz`, 38,678 bytes, SHA256
`7babb36cd741b44354157ee33fc1fd741f882c6bab314ebe9217197813fed590`.

Manifest `candidate/CANDIDATE.sha256`, SHA256
`9387747ac744896aa6eb9a906bcddb6c4597eed406fe2b9e47d1bbc7090e616e`.
The seven files it names all match. The eighth file is the manifest itself.
The crate is `mo-stage-b`. It exports `mo_stage_b::StageB`.

## Build

Rust 1.98.1. The candidate sits beside the public runtime and is built from
its own lock. The acceptance linker is `stage-b-link/`; it names
`mo_stage_b::StageB` and does not contain an interpreter. The locked tree
contains `imbl` 7.0.2. It does not contain `im` or `sized-chunks`.

## Source audit

Production code has one lexer and one checker, both in `frontend.rs`, and one
execution machine in `execution.rs`. The execution file does not parse source.
Nothing in the production code names an acceptance checker, an acceptance
crate, or a public example by its case identifier.

`NoCells` occurs nine times in `execution.rs`, every one of them under
`#[cfg(test)]`. The linked acceptance build does not compile that test code.
The handoff mentions `NoCells`, `mock`, and the old `im::` path in prose about
what was removed. Those words are not a second store or a second evaluator.

## Public examples

Each of the 21 public examples was run through the frozen Stage B checker.
For every example that got through an uninterrupted run, every pause boundary
and every destroy boundary was run as well: resume with a zero-work join, then
the rest of the steps, and a separate destroy at that boundary. The frozen
verifier checked the per-step record and the event schema on every row.

18 examples matched, including all of those boundaries: C1, C2, C3, C7, C8,
C9, C10-unique, C10-retained, C10-sum, C10-empty, C10-single, C11-0, C11-1,
C11-2, C11-7, C12, C13, C14. That is 1,379 resume runs and 1,379 destroy runs,
all matching, plus the 18 uninterrupted runs.

Three examples failed on the uninterrupted run, so their boundaries were not
continued.

The first failure is C4, whose main expression is
`let changed = bump(xs) in first(changed) + first(xs)`, with `xs` the list
1, 2. At committed step 6 the frozen comparison
"full committed execution/physical state" fails. The call has been entered.
Every field matches except the order of the two live bindings, both named
`xs` and both holding list cell 1:

| | First binding | Second binding |
| --- | --- | --- |
| Frozen reference | id 0, name `xs`, list cell 1, holding | id 1, name `xs`, list cell 1, holding |
| Candidate | id 1, name `xs`, list cell 1, holding | id 0, name `xs`, list cell 1, holding |

The candidate's standard error was empty. The whole snapshot is in
`evidence/stage-b-public-check-01/first-difference.json`.

C5 fails the same comparison at step 12. Its first two bindings are swapped:
the candidate lists `xs` at id 3 and then `b` at id 2; the reference lists
`b` at id 2 and then `xs` at id 3. C6 fails it at step 6: the candidate lists
`xs` holding cell 1 and then `ys` holding cell 2; the reference lists `ys`
holding cell 2 and then `xs` holding cell 1.

## What remains before acceptance

- Private execution of the 24 reserved examples and the 500 generated ones.
  They were not opened. The preparation records no duration for them. They
  are the same small bounds as the public examples. The uninterrupted public
  runs that matched finished in a fraction of a second each.
- The nine sabotage controls. The harness is ready and none of them has run.
  They are not the million-element runs.
- The million-element recursive sum. The preparation projects about 12
  minutes, inside the 900-second limit from D162, the decision that gives the
  sum 900 seconds and leaves the discard at 600. The million-element discard
  is projected at about 98 seconds, inside its 600-second limit.

This check took 332 seconds. No frozen file and no supplied file was edited.
