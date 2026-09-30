# Brief for the prediction session

**For:** a new Codex session in its own visible Herdr pane, separate from the
Codex session that reviews as oracle. **Written by** the lead, 30 Sep 2026, for
the trial's phase 1, step 2 (`PLAN.md`, "How the trial runs").

## Your job

Write the predictions for the trial's examples, from the approved English rule
alone, before any Lean version of the rule exists. The predictions are the
acceptance criteria the rule's encoding will later be run against, so nobody who
writes that encoding may write or change them. That is why this is your job and
not the lead's.

## Read these, and only these, as the source of truth

1. `CLAUDE.md` at the repo root: the working rules. Robert does not read code;
   write for him in plain English.
2. `experiments/03c-checker/trial/RULE.md`: the approved rule (D91: the reuse
   rule is approved as a whole). Every prediction must follow from this text.
3. `experiments/03c-checker/trial/EXAMPLES.md`: the approved examples (D92: the
   examples are approved): twenty programs, thirteen starting memories,
   twenty-eight runs.
4. `experiments/03c-checker/trial/PLAN.md`, sections "The two meanings", "What
   the promises cover", "The examples" and "How the trial runs".
5. `experiments/03c-checker/trial/INTERFACE.md`, section 6, for what a snapshot
   shows (D93: the interface is approved). You need it only to word the timing
   claims so that they can be checked.

## What to write

One new file: `experiments/03c-checker/trial/PREDICTIONS.md`. Nothing else.

1. **A table with one row for each of the twenty-eight runs:** the run number,
   the predicted answer (a number, true or false, or a list written out), and
   the predicted numbers of allocations, reuses and frees for the whole run.
2. **For each run, a short derivation in plain English of how the rule gives
   those numbers:** the events in order, each tied to the section of `RULE.md`
   that requires it. This is what lets Robert approve a prediction without
   taking it on trust, and what lets a later mismatch be traced to a wrong
   prediction, a wrong encoding, or a fault in the rule. A derivation explains
   the totals; it is not itself a prediction. The order of events in it is not
   checked against the run. Only the answer, the three totals and the timing
   claims of item 3 are.
3. **Timing claims** (D94: predictions include a few timing claims on chosen
   runs). On runs 9, 10 and 11, state what the rule requires at two named
   moments: just after the branch's value is worked out, and just after that
   value is handed on. Say, for each set-aside cell nothing reuses, whether it
   is still allocated at each moment. Word each claim so that it can be checked
   against a snapshot. You may add timing claims on other runs where a decided
   detail changes when something happens and not the totals; say which decision
   each one tests.
4. **Added examples, if you want them** (`PLAN.md`: "Codex may add examples").
   Put each in its own section of the same file, clearly marked as added by you,
   in the form `EXAMPLES.md` uses (program, plain-English description, inputs in
   order, starting memory table), with its prediction. Say what each one tests
   that the twenty-eight do not. Robert approves them with the predictions.
5. **A closing section, "What I was unsure of":** every place where you had to
   read the rule closely to choose between two outcomes, and which words settled
   it.

## What you may not do

- Do not edit any file other than `PREDICTIONS.md`. In particular not `RULE.md`,
  `EXAMPLES.md`, `PLAN.md`, `INTERFACE.md` or `docs/DECISIONS.md`.
- Do not write or run any Lean, or any other program, to work out an answer or a
  count. The predictions come from reading the rule. (A calculator for plain
  arithmetic is fine.)
- Do not ask the lead, or the Codex session acting as oracle, what any
  prediction should be: an answer, a count, a timing claim, an expected state or
  an order of events. Do not read their panes for one either. Robert may talk to
  you directly.
- Do not resolve an unclear rule by guessing. See the stop conditions.
- Do not commit or push. The lead commits the file exactly as you wrote it.

## Stop conditions

Keep `PREDICTIONS.md` up to date as you go, so that whatever ends the work, the
file holds everything you have. Its first lines give its status: **complete**, or
**partial**, with the reason.

Stop and report, in your pane, as soon as one of these holds:

1. **Done:** everything under "What to write" is there. That is: the table row
   and the derivation for each of the twenty-eight runs; the timing claims on
   runs 9 to 11; for every example you added, its full description in the form
   `EXAMPLES.md` uses, its prediction and its derivation; and the closing
   section. The file's status is "complete".
2. **The rule does not decide a case:** for some run, two careful readers could
   follow `RULE.md` and reach different answers, totals or timing, or the rule
   is silent. Do not pick one. Write down the run, the two readings and the
   words of the rule at issue, finish the runs that are not affected, and stop.
   This is a finding about the rule, and what happens next is Robert's decision.
3. **An example is broken:** a program is not well-formed, or a starting memory
   is not valid, under the rule and the plan. Record it, finish the runs that
   are not affected, and stop; do not repair it.

Under conditions 2 and 3 the file's status is "partial". It keeps every row and
derivation you completed, says which condition ended the work, and has a
section, "Findings", with each unresolved case written out in full, even if no
run could be predicted. Nothing that matters should exist only in your pane.

When you stop, your report in the pane says which condition ended the work and
how many runs are predicted, and points at the file.

## What happens afterwards

The lead commits `PREDICTIONS.md` exactly as you wrote it and shows Robert its
tables and derivations.

- If it is complete, Robert decides whether to approve the predictions. Approved
  predictions are frozen with fingerprints before the rule is encoded in Lean.
- If it is partial, the findings go to Robert to resolve. A partial file is not
  frozen and is not treated as a finished set of predictions.

Later, in another session, you write the Lean file that checks the runs against
the frozen predictions (`PLAN.md`, "How the trial runs", step 3). The lead never
edits a prediction.
