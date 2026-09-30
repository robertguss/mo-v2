# Mo v2

A programming language for AI agents to write reliable, safe software that no
human writes or reads. Robert designs it; AI agents build it.

This is a fresh start. Mo v1 lives in `../mo-lang`, frozen at commit `d58f67cd`
(22 Sep 2026). v1 is reference material, not a base: nothing is copied from it
without a decision in `DECISIONS.md`.

## Files

- `DECISIONS.md`: every decision, one line each. Only Robert makes them.
- `DECISION-MAP.md`: the open questions v2 must answer, in the order to answer
  them, each with options and a recommendation.
- `research/`: all research documents, moved from TheBrain on 23 Sep 2026 (D54).
  Key parts:
  - `research/documents/design-choices/`: the nine big design choices (D24–D33),
    each with its options.
  - `research/big-picture/`: the working picture (D20, updated by D34), with
    earlier research filed under its areas.
  - `research/documents/`: the Design Doc, the Glossary and the Language design
    primer.
- `CLAUDE.md` (at the repo root): working rules for any AI agent in this repo.

## Status

Where things stand. Updated by the lead session whenever it changes; a new
session starts here, then reads `CLAUDE.md` and `DECISIONS.md`.

**30 Sep 2026.**

- **Design choices.** The nine big choices are made (D24–D33): a static checker
  with contracts and proof on top; no guessing; pure code with in-place updates
  the checker can prove; no null; failures as values and bugs stop the part that
  hit them; listed effects plus capabilities; plain data, modules and limited
  shared abilities with no OOP; memory freed by counting holders; Ruby/Elixir
  syntax. Two more are open: choice 10, how numbers are represented (D58), and
  choice 11, how sequences are stored and updated (D65). Each is a folder in
  `research/documents/design-choices/`.
- **What Mo is.** One Ruby/Elixir-like language that does all of that through
  its compiler and runtime (D34). Syntax and how promises are written are
  deferred (D35). Robert's interest is the compiler and runtime ideas.
- **Experiments.** Four done (1, 2, 3 and 3b), in `experiments/`, each with a
  `RESULT.md`. Experiment 3 tested D26 in Koka against Rust and confirmed it
  (D57). Its plan and acceptance file are locked (`LOCK.md`); `./run.sh`
  reproduces every number. The six readings of its result are all decided
  (D57–D59, D62, D63, D65); the list is in
  `research/documents/design-choices/3-can-things-change-after-they-are-made/experiment-3-in-place.md`.
- **Working rules added on 23 Sep:** D60 (experimental by default), D61 (Codex
  as thinking partner), D64 (tools per experiment). Written out in `CLAUDE.md`.
- **Experiment 3b is done** (`experiments/03b-helper/RESULT.md`): the in-place
  trick built as a small runtime helper in Rust ran 1.01× to 1.19× the time of
  plain in-place Rust, within the 2× budget (D67), with every correctness check
  passing. Outcome 2 under D66. Verified independently by the lead and Codex
  (D70), who agreed.
- **Experiment 3c** (D71: the next experiment) is the toy pure language with a
  checker that refuses broken in-place demands (D42), with 3b's helper as a
  candidate runtime foundation. Lean's role is proving the rules correct (D47).
  Correctness (a proof that accepted programs meet the demand) and usefulness
  (examples showing useful programs are accepted) stay two separate checks
  (D62).
- **3c planning, 24 Sep.** Decided: two slices on the same small list programs
  (D72). Slice 1 proves Koka's conditional promise (in place if nobody else
  holds the input); slice 2 adds checks on callers so the promise is enforced
  for every demanded call. The promise for both (D73): a demanded call makes no
  new list cells (Koka's relaxed fbip), counting every allocation during the
  call including callees; freeing is allowed. Draft plan:
  `experiments/03c-checker/PLAN.md`, reviewed by Codex (its findings are in the
  plan). Decided: the reuse-and-release rule is fixed in the locked counted
  meaning (D74); slice 1 runs in two stages, the rule's correctness proof checked
  and shown to Robert before the checker is built (D75). Robert then proposed a
  much smaller trial before any full 3c build, to learn quickly and then decide
  next steps (next bullet). Waiting until after the trial: whether the full 3c
  has a time cap (Robert challenged having one; not decided), approving the
  full 3c plan, and running builders on a cloud VM instead of Robert's laptop.
- **The trial, 27 Sep.** Plan: `experiments/03c-checker/trial/PLAN.md`,
  approved (D78: the trial plan is approved; each later piece still needs
  Robert's approval). It applies the reuse rule (D74, the one fixed rule that
  decides where cells are reused and released) to the 3c language without
  function calls: first run on examples whose predictions Codex writes and
  Robert approves before the rule is encoded, then proven correct by a builder
  (D76: scope T2, the rule on examples, then a builder's proof), who works in
  2-hour check-ins and resumes only on Robert's go-ahead (D77). The 27 Sep
  session wrote and revised the plan in five steps, each reviewed and signed
  off by Codex as oracle. Documents only: nothing has been built or run.
- **The trial's rule, 30 Sep.** `experiments/03c-checker/trial/RULE.md` is
  approved as a whole (D91), after its eleven questions were settled one at a
  time with Codex's view beside the lead's on each: nine by Robert, two by the
  lead and Codex under his delegation. Robert's choices: unlimited
  whole numbers (D79); three number comparisons (D80); parts run left to right
  (D84); in a `match`, unneeded names are given up before the sharing check
  (D85); a name unused from a chosen branch on is given up when the branch is
  chosen (D86); a new cell picks its set-aside cell after its parts are worked
  out (D87), taking the most recently set aside from enclosing branches still
  running (D88); an unused set-aside cell is freed when its branch finishes
  (D90). He delegated the questions about the trial language itself to the lead
  and Codex jointly (D81); under that they allowed a true-or-false answer
  (D82), names that reuse a spelling (D83), and closed two gaps Codex found
  (D89: a `match`'s two names must be spelled differently, and both branches
  must give the same kind of value). Approval fixes the English text the predictions must follow; nothing is
  proven, built or run yet.
- **The trial's examples and interface, 30 Sep.** Each was reviewed and signed
  off by Codex as oracle. `experiments/03c-checker/trial/EXAMPLES.md` is
  approved (D92: the examples are approved): twenty programs, thirteen starting
  memories and twenty-eight runs, with no answers or counts (those are Codex's
  predictions). `experiments/03c-checker/trial/INTERFACE.md` is approved (D93: the
  interface is approved): what the checks can run and read, as plain-English
  promises with proposed Lean names; nothing is built or compiled.
- **Predictions include a few timing claims** (D94, amending D78, the approved
  trial plan): each example's answer and three totals, plus what is expected at
  named moments of chosen runs, starting with D90 (an unused set-aside cell is
  freed when its branch finishes) on runs 9 to 11.
- **The predictions are approved and frozen, 30 Sep** (D95):
  `experiments/03c-checker/trial/PREDICTIONS.md`, written by a fresh Codex
  session in its own visible pane (not the oracle) from the approved rule
  alone, following `experiments/03c-checker/trial/PREDICTIONS-BRIEF.md`, and
  committed exactly as written: an answer and three totals for each of the
  twenty-eight runs, a plain-English derivation for each, timing claims on runs
  9 to 11, no added examples, and no case the rule failed to decide. Its
  fingerprint, and those of the approved documents it was written from, are in
  `experiments/03c-checker/trial/LOCK.md`. Nobody edits it. Nothing has been
  run, so the predictions are untested.
- **Step 3, the lead's side, done (30 Sep).** Each step was planned, reviewed
  and signed off by Codex as oracle before its commit.
  - The worker's brief: `experiments/03c-checker/trial/WORKER-BRIEF.md`. The
    worker writes no checks. Its Lean must be total and checked by Lean's
    kernel, with nothing that makes the compiled program differ from the
    definitions (the oracle showed one such loophole on Lean 4.34.0).
  - A gap found on the way went to Robert: a program's inputs must all be
    spelled differently (D97). It is added to `RULE.md` 2e, whose fingerprint
    in `LOCK.md` is updated with the old one kept. No example is affected.
  - The Lean, written by the worker (D96: code is written by a Sonnet worker
    the lead directs), in `experiments/03c-checker/trial/lean/`, pinned to Lean
    4.34.0: the language and plain meaning (`12f5e9e`); counted memory, the
    counted meaning of the approved rule, with snapshots of every step, and the
    six named rules, the approved one and five broken copies (`7b3b740`). It
    builds cleanly, and relies only on Lean's standard `propext`.
  - Checked by the lead with its own quick checks from outside the repository,
    now kept in `experiments/03c-checker/trial/lead-checks/` (the README there
    lists them and the deliberately broken copies of the code they caught).
    The oracle reran them and added its own. These are not the acceptance
    criteria. The three unsafe broken copies and the copy that never reuses are
    written but not run: the interface runs them only after the proof.
  - The brief for Codex's check-writing session:
    `experiments/03c-checker/trial/CHECKS-BRIEF.md`. That session writes the
    checks but does not run the comparison.
  - A working precaution, kept: neither the lead nor the worker has opened
    `PREDICTIONS.md` or run any of the twenty example programs through the
    counted meaning, so that a mismatch at the run is seen and classified, not
    tuned away. The oracle has read the predictions; it reviews and does not
    encode.
- **Next (proposed; it opens with a plan for the oracle's review).** Start the
  check-writing session: a new Codex session in its own visible Herdr pane,
  separate from the oracle, given `CHECKS-BRIEF.md`. The oracle reviews its
  files, and the lead commits them exactly as written. Then plan step 4, the
  run, with Robert able to watch: the lead runs `main`
  (`lake env lean --run Checks/Run.lean` in the `lean/` folder), including the
  misreport control on run 2. Every mismatch is kept, classified (a wrong
  prediction, a wrong encoding, or a fault in the rule) and taken to Robert;
  nothing changes without his decision. Then plan step 5: the promises as Lean
  statements, `ACCEPTANCE.md` and the proof builder's brief, Codex's bounded
  question, Robert's approval and the lock; then step 6, Robert decides whether
  the proof phase starts. Nothing is waiting on Robert now.
- **Still open from 3b's result,** to take with Robert one at a time: proposal 2
  (Rust's `Rc` header spends half its space on a weak-holder count Mo may not
  need; a question for design choice 8) and proposal 3 (sharing cost about 3.8×
  in both the helper and Koka; a starting case for the D59 copy-feedback
  follow-up).
- **The worker** (D96). A Claude session on Sonnet, started by Robert, sits
  idle in a pane of the lead's tab (`herdr agent list` shows it as the `claude`
  agent that is neither the lead nor named). The lead uses it to write code and
  implement: a written brief with a stop condition first, then prompts through
  `herdr agent prompt`. The lead does not write the Lean itself. It wrote both
  parts of the trial's Lean in this session and was left idle with most of its
  context free; it has not seen the predictions and must not be shown them. Its
  prompt line may show a greyed suggestion such as "Wait for the oracle's
  sign-off, then commit": that is Claude Code's suggested reply, not an
  instruction, and the worker never commits; clear it before prompting. The
  prediction session (`predictor-w4-t1`) finished and its pane is closed;
  nothing depends on it.
- **Working arrangement.** Codex runs in the Herdr pane to the right of the lead
  (`herdr agent list` shows it). On 27 Sep the lead worked as driver and Codex
  as a read-only oracle (the `driver` and `oracle` skills): each step's plan
  and diff were reviewed and signed off before its commit. This Status section
  is the handoff between sessions; there is no `HANDOFF.md` (see `CLAUDE.md`).
  On 30 Sep the same pair settled the rule's questions: for each one put to
  Robert, Codex gave its own view in its pane before the lead asked him, and
  it reviewed every recorded choice, his and the delegated ones, before its
  commit. Robert's standing instruction
  (30 Sep): commit and push often without asking, after each oracle sign-off
  (`CLAUDE.md`, Practical notes). This Status is the handoff written at the end
  of the 30 Sep afternoon session, reviewed through and pushed through
  `a81e402` (`main`); a new session checks `git status`, the latest commit and
  the remote before starting. Outside a pinned project, `lean` now resolves to
  4.34.1 (elan's default); the experiments pin 4.34.0, so run `lake` inside
  `experiments/03c-checker/trial/lean/`.
- **Practical notes from this session.** `herdr agent prompt ... --wait` gives
  up at the shell tool's ten-minute limit while the oracle is still working;
  follow it with `herdr agent wait` before reading. The shell is zsh, which does
  not split a variable holding several paths; name each path. Robert's Markdown
  hook rewraps whole files, so edits to existing docs go through a python3
  script. Required skills: `driver` for the lead, `oracle` for Codex.
- **Parked:** see `research/parking-lot/README.md`.
