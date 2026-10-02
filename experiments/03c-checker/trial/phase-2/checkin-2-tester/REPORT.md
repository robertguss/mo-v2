# ROB-1137 independent partial-checkpoint verification

Original findings recorded 2026-10-02 UTC, before seeing any Lead findings.
Tester thread: https://ampcode.com/threads/T-01a0fb61-cefb-720f-b823-afd990316243

## Outcome: valid partial checkpoint, zero promises proven

- **Promises proven:** none (0/4).
- **Unfinished:** A, the run finishes; B, the answer equals the plain meaning;
  C, outside lists and still-held names remain unchanged at recorded moments;
  D, no leaked cells or incorrect final holder counts. Their original `sorry`
  bodies remain in `experiments/03c-checker/trial/lean/Proofs.lean` at lines
  11, 13, 15 and 17 respectively. Every accepted theorem depends on
  `[propext, sorryAx]`. These are not completed proofs.
- **Counterexamples:** none found in this verification. No independent exhaustive
  counterexample search was performed. Unfinished proofs do not establish that
  a promise is false.
- **Integrity violations:** none found. No setup blocker encountered.
- **Final acceptance:** not granted. Check 6 fails for all four as completed
  promises; checks 3 and 4 satisfy only the approved partial-work exceptions.
  Checks 9–10 were deliberately not executed before proof completion.

## Exact candidate and reconstruction

Fetched `origin rob-1136-trial-proofs-high`; `FETCH_HEAD` was exactly
`38c4b7accc32cea8a3714eeb93c5917b4431ab8c`. Required that equality before an
exact detached checkout. Unshallowed the checkout before ancestry inspection.

- Candidate: https://github.com/robertguss/mo-v2/commit/38c4b7accc32cea8a3714eeb93c5917b4431ab8c
- Amended baseline: https://github.com/robertguss/mo-v2/commit/787e0427244837fd0f44b76c4a648d07938c3bcc
- Plan: https://github.com/robertguss/mo-v2/commit/ad9302cd4aacaf08ca0d82a01c3aaadca92c9201
- Prior checkpoint: https://github.com/robertguss/mo-v2/commit/8c57ccbd4f41dea91f2cda903d9377362f37270a

All three supplied earlier commits are ancestors of this candidate
(`git merge-base --is-ancestor`, exit 0 for each).

Read candidate `CLAUDE.md`, trial `ACCEPTANCE.md`, `PROOF-BRIEF.md`, `LOCK.md`,
`Promises.lean`, `Acceptance.lean`, and every proof file. No Lead report,
Linear, Oracle, other thread, or Builder report was consulted.

Reconstructed `/tmp/rob1137-verification/fresh` with `git archive` of the
amended baseline, then copied only candidate `lean/Proofs.lean` and
`lean/Proofs/` into the matching trial directory. Confirmed `.lake` did not
exist before the build. All 57 copied proof files compare byte-for-byte with
the detached candidate. All 56 helper modules are transitively imported by
`Proofs.lean`, so the build and Acceptance kernel recheck include them.

## Checks 1–8

| Check | Independent result |
| --- | --- |
| 1 — locked fingerprints | PASS. Last table row per path is effective. All 25 paths match in candidate and reconstructed baseline. |
| 2 — allowed paths | PASS. Full baseline-to-candidate comparison: only Proofs.lean and 56 new Proofs/*.lean files, 57 changed paths, 7,240 insertions. No accompanying non-proof reports. Candidate checkout has no modified, untracked, or ignored files before evidence export. |
| 3 — source integrity | PASS under partial-work exception only. Read all 7,258 lines across 57 files; only four original executable sorry occurrences remain, all in the top-level stub. No new unfinished helpers or forbidden constructs found. |
| 4 — clean build | PASS under partial-work exception only. Pinned Lean 4.34.0, empty .lake, all 75 build jobs succeeded. Exactly four warnings, one for each original unfinished promise, no other warnings/errors. |
| 5 — exact types | PASS. Locked Acceptance compiles; fully qualified printed types are Trial.PromiseA/B/C/D respectively. Printed definitions retain universal Expr/Start quantification, validStart, and runCounted Trial.Rule.approved. |
| 6 — accepted axioms | NOT SATISFIED for every promise: accepted_a/b/c/d each depend on [propext, sorryAx]. Thus zero accepted promises. |
| 7 — kernel recheck | PASS. lake env leanchecker --fresh Acceptance, exit 0, no diagnostic output. This does not turn sorryAx into a proof. |
| 8 — frozen examples | PASS. Runner exit 0; cmp exit 0; approved, control, total mismatch counts all 0. Exact frozen output SHA-256 below. |

Frozen report SHA-256:
`4b85ff0c0561722d584e8c60b730a25d6f5cdca7d0222dde33fcc2d024ca8847`.

The locked example runner includes its historical misreport control. Running
that unchanged check 8 is distinct from broken-copy checks 9–10. No rule variant
was substituted and none of their throwaway mutation checks were performed.

## Reading findings and remaining proof work

All helper declarations are within `Trial.Proofs`. Imports resolve only to
the locked Promises module and the candidate's own proof modules. The only
attributes are simp attributes on the helper's own theorems; no locked
definition receives an attribute. No parser extensions, replacement locked
definitions, unsafe evaluation, extra axioms, option changes, kernel bypass,
or export/renaming trick was found. Keyword hits for "notation" and "prefix"
are prose comments, not commands. The top-level Proofs.lean is byte-identical
to the baseline stub after removing its one added import.

The helper work supplies memory ownership/read-back lemmas and strengthened
evaluator contracts, including liveness, immutable binding meanings and
snapshot preservation. `promises_of_contract` connects a completed expression
contract to all four locked per-run predicates, but explicitly requires the
expression contract as a hypothesis. It is not a universal proof. The candidate
has contracts for literals, variables, arithmetic, if, let, construction, the
empty-list match, and shared/exclusive nonempty-match setup. It still lacks
the completed general match composition/structural evaluator argument and
the four final promise bodies. This is helper progress, not promise progress.

Compared with the prior checkpoint there are 28 changed paths, 3,474 insertions
and 1 deletion: 27 new helpers and the import update. No claim that this predicts
time to completion or that helper size measures scientific progress is made.

## Commands and exits

Git and reconstruction commands ran in `/home/user/workspace/repo`.

```text
git fetch origin rob-1136-trial-proofs-high                         exit 0
test "$(git rev-parse FETCH_HEAD)" = <candidate>                    exit 0
git checkout --detach <candidate>                                 exit 0
git fetch --quiet --unshallow origin                              exit 0
git archive <baseline> | tar -x -C /tmp/rob1137-verification/fresh   exit 0
cp Proofs.lean and cp -R Proofs into reconstructed trial/lean       exit 0
test ! -e reconstructed trial/lean/.lake                          exit 0
git diff --name-status <baseline> HEAD                            exit 0
git diff <baseline> HEAD                                         exit 0
git diff --stat <prior> HEAD                                      exit 0
git diff --check <baseline> HEAD                                  exit 0
git status --porcelain=v1 --untracked-files=all                     exit 0, empty
git ls-files --others --exclude-standard                          exit 0, empty
git ls-files --others --ignored --exclude-standard                 exit 0, empty
Python last-row lock, permitted-path and original-stub assertions  exit 0
Python proof byte-comparison and transitive-import assertions      exit 0
```

All Lean commands ran inside the reconstructed
`experiments/03c-checker/trial/lean`, with the pinned local toolchain and no
global-default change:

```text
lean --version                                      exit 0, Lean 4.34.0
lake build Trial Checks Promises Proofs Acceptance   exit 0, 75 jobs
lake env lean --stdin                                exit 0, types/axioms
lake env leanchecker --fresh Acceptance              exit 0
lake env lean --run Checks/Run.lean                   exit 0
cmp examples.txt ../results/run-1.txt                 exit 0
```

The stdin inspection imported Acceptance and printed the fully qualified types
of its four accepted theorems, the four Promise definitions and accepted axioms.
No theorem was added or changed. Raw build, type/axiom, kernel, example, lock,
path, import/hash and scan evidence is preserved alongside this report.

Stop condition met: independent applicable partial-work checks complete and
original findings preserved. No source edits, proof writing, commits, pushes,
Linear changes, Oracle calls, child threads or reply-back messages were made.
Only verification copies and evidence/report files were created. The evidence
export excludes the full source diff and reconstructed source/build tree; it
contains reports and inspection output only, not code for integration.
