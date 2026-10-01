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

**1 Oct 2026.**

**Current action:** Robert approved proceeding with phase 2, all four locked
promises and the two-hour check-ins (D101: approval to proceed with proof work).
Builder selection and any replacement of the Herdr arrangement are pending. No
proof work or timed interval has begun. This session is in an Amp orb:
`HERDR_ENV` is unset and `herdr` is unavailable. Orb setup now installs Lean
and Lake from the experiment pins, Rust 1.98.1, Koka 3.2.9, C build tools,
and locked Cargo dependencies. Run Lean commands inside an experiment's Lake
directory, where its `lean-toolchain` selects the version. The
pane and machine descriptions below are historical, from 30 Sep, not verified
current sessions. Robert requested `driving-amp-development`; its Oracle reviews
do not by themselves replace the locked requirement for separate acceptance
runs. Settle the working arrangement before starting the builder.

**Orb setup verification:** `.agents/setup` installed the tools in about 40
seconds; repeated warm runs took about 0.3 seconds without downloads.
`.agents/resume` requires no services or authentication and finishes immediately.
A clean login shell built the trial's five Lake targets; the existing four
unfinished proofs still report `sorryAx`, so this is toolchain verification,
not proof acceptance. The Rust counting harness built offline with its lockfile,
and Koka compiled benchmark 1 without running it (with a bundled mimalloc C
compiler warning). The older benchmark runners still assume macOS/Homebrew
paths and measurement tools; installing their compilers does not make those
locked runners portable to Linux. No experiment sources, locks, or data changed.

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
  off by Codex as oracle. At that point it was documents only: nothing had been
  built or run.
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
  must give the same kind of value). Approval fixes the English text the predictions must follow; at approval nothing was
  proven, built or run.
- **The trial's examples and interface, 30 Sep.** Each was reviewed and signed
  off by Codex as oracle. `experiments/03c-checker/trial/EXAMPLES.md` is
  approved (D92: the examples are approved): twenty programs, thirteen starting
  memories and twenty-eight runs, with no answers or counts (those are Codex's
  predictions). `experiments/03c-checker/trial/INTERFACE.md` is approved (D93: the
  interface is approved): what the checks can run and read, as plain-English
  promises with proposed Lean names; at approval nothing was built or compiled.
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
  `experiments/03c-checker/trial/LOCK.md`. Nobody edits it. At the time nothing
  had been run; the run of step 4 (below) later tested them.
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
    criteria. The interface (section 7) keeps the three unsafe broken copies
    and the copy that never reuses for after the proof, and neither the lead nor
    the oracle has run them. **A departure from that schedule:** the worker
    reported, when the lead asked on 30 Sep, that it had run all five broken
    copies on small programs of its own while building part 2 and part 3,
    including programs and memories that the lead's after-the-proof rows K2 to
    K5 use (never P1 to P20), although its brief (`WORKER-BRIEF.md`, "Smoke rows
    for the broken copies") says those four copies run only after the proof. It
    looked only at filtered output, which is partial evidence: it does not
    establish how the copies behave in full, nor that they behave the same
    before and after the D98 change. Taken to Robert as a departure: he chose to
    record it and carry on, with the worker told plainly not to run those four
    copies from now on, and the same worker kept (D99).
  - The brief for Codex's check-writing session:
    `experiments/03c-checker/trial/CHECKS-BRIEF.md`. That session writes the
    checks but does not run the comparison.
  - A working precaution, kept until the run: neither the lead nor the worker
    opened `PREDICTIONS.md` or ran any of the twenty example programs through
    the counted meaning before the encoding was committed, so that a mismatch at
    the run would be seen and classified, not tuned away. Later the lead saw
    predicted values in the check-writing session's reports (below) and ran the
    examples at step 4; the worker still has not seen them. The oracle has read the predictions; it reviews and does not
    encode.
- **Step 1 of the checks, 30 Sep (evening).** The check-writing session
  (`checker-w4-t1`, a new Codex session in its own pane below the lead, started
  after a plan the oracle signed off) wrote the four check files but stopped
  under its brief's condition 2: the snapshots could not show the number a
  `match` branch works out as it finishes (runs 10 and 11), nor that run 11's
  unneeded list was given up before its branch ran. The oracle confirmed both
  gaps and, in a bounded look at coverage, found no others (its full review
  came later, below). The stop report quoted two predicted values, so the lead
  then saw those two, nothing else of the predictions. Robert chose to
  record more (D98: the snapshots also show a finishing `match` branch's value,
  and a snapshot is taken as each chosen branch starts; nothing a run does
  changes), which amends `INTERFACE.md` section 6 (its fingerprint in `LOCK.md`
  is updated, the old one kept). The worker made the change in
  `Trial/Counted.lean` (`WORKER-BRIEF.md`, part 3); the lead checked that runs
  are otherwise unchanged and that the recorded values are right, on its own
  programs, with four broken copies of the change caught
  (`experiments/03c-checker/trial/lead-checks/D98/`), and the oracle reviewed
  it. The check-writing session then finished its checks, closing both gaps
  (the values at every finishing moment on runs 10 and 11; run 11's list given
  up and its cells freed by the moment its branch starts):
  `experiments/03c-checker/trial/lean/Checks.lean` and `lean/Checks/`. Its
  final report in its pane printed a table of predicted answers and totals for
  most runs, so from then on the lead had seen those predictions (the worker has
  not). No encoding was changed after that. The oracle's full review found one
  more gap (the final holder count ignored names still holding), which the
  session fixed in its own file; after the oracle's sign-off the lead committed
  the four files exactly as written (`774c58f`).
- **Step 4, the run, done (30 Sep).** Planned and signed off by Codex as
  oracle. The lead ran `main` in a visible shell pane at `774c58f`: all
  twenty-eight runs matched the frozen predictions (438 report items, no
  mismatch), answers, totals from memory's own record and every timing claim on
  runs 9 to 11; both promise checks held on every run; the misreport control
  was rejected on its counts with the right answer. A second run gave the same
  output byte for byte. Record: `experiments/03c-checker/trial/RUN-1.md`;
  output: `experiments/03c-checker/trial/results/run-1.txt`. Nothing to
  classify, so no mismatch question for Robert. The two finished panes (the
  check-writing session and the shell the run used) were closed at Robert's
  request; nothing depends on them.
- **Robert has been told the run's result** (30 Sep evening, in the lead's
  terminal, with what it does not show: not the rule for every program, and a
  misreading shared by the predictions and the encoding would look like
  agreement). No question from the run is waiting on him.
- **Step 5, the promises and the full lock, done (30 Sep, late evening).** Each
  piece was planned, reviewed and signed off by Codex as oracle before its
  commit. The four promises of Q2 as Lean statements, typed by the worker from
  `experiments/03c-checker/trial/WORKER-BRIEF.md` part 4: `lean/Promises.lean`;
  `lean/Proofs.lean`, the stub (four `sorry`s) a builder would replace; and
  `lean/Acceptance.lean`, which restates them with every name written from the
  root (the oracle showed that otherwise a builder's `notation` could swap in a
  weaker statement). The lead's checks are in `lead-checks/step5/`: the promises
  hold on all twenty-eight runs, fail on outcomes broken by hand, and three
  broken copies of the statements were caught. `ACCEPTANCE.md` gives them in
  plain English with their limits (promise (c) is about the moments the run
  records; lists not yet handed on are not covered; the proof is about the
  Lean, whose fidelity to the English rests on run 1), the examples as a table
  with the predicted answers and totals, the ten checks a proof must pass, and
  when a single promise counts as proven at a check-in. `PROOF-BRIEF.md` is the
  builder's brief. Codex, restarted fresh, answered the plan's bounded question
  ("can a builder pass these checks while failing the intended task?"): no way
  found beyond the stated limits (a reading, not a proof). Robert approved the
  three (D100: the promises, the acceptance file and the builder's brief are
  approved and locked), and the full lock is in
  `experiments/03c-checker/trial/LOCK.md`: twenty-five frozen files; only
  `lean/Proofs.lean` and `lean/Proofs/` are writable.
- **Step 6 started, then paused for the night (30 Sep, night).** A fresh
  driver took over and sent the oracle a plan for the chunk; the oracle asked
  for two changes, then signed it off with no P1 or P2 finding left. Robert was
  asked question 1 and stopped for the night without answering. He answered on 1 Oct
  (D101: approval to proceed with proof work); builder selection is still
  pending, and no proof work or timed interval has begun.
  - **The chunk, as signed off.** Step 6 (`PLAN.md`, "How the trial runs",
    step 6), questions put to Robert one per message, in order, each recorded
    (a row in `docs/DECISIONS.md` and this Status), reviewed by the oracle,
    then committed and pushed: (1) does phase 2, the proof, start? (2) if so,
    who builds it? (3) only if he picks the existing worker, are its
    restrictions lifted (`PROOF-BRIEF.md`, "Before this brief is handed
    over")? Then, if phase 2 starts, a short plan for starting the builder,
    reviewed by the oracle first; then the builder's first two-hour interval
    (D77: two-hour check-ins, resuming only on Robert's go-ahead). The chunk
    ends at whichever comes first: Robert says phase 2 does not start or
    pauses it (after recording it); the end of the first interval (the
    builder's report checked, shown to Robert, and his answer recorded); or
    an earlier phase-2 stop condition (ready for checking, a promise false,
    the spec wrong, setup blocked). The full checks 1 to 10 of
    `ACCEPTANCE.md`, with the oracle's independent review, are the next
    chunk; so is any `RESULT.md` for phase 1 if Robert stops the trial there.
  - **Question 1, as asked on 30 Sep** (answered on 1 Oct): (1) start phase 2
    as planned, all four promises, with the D77 check-ins; (2) start, but
    prioritize (a) finishes and (b) same answer first, the target staying all
    four (only the order changes; no locked file changes, whereas dropping a
    promise would need a new lock); (3) stop the trial at phase 1 and write
    up its result (the trial's main question stays unanswered); (4) pause and
    do something else first, such as the 3b proposals below. Nearest
    precedent: FP2's Theorem 6, a paper proof of nearly (b) to (d) for
    another language. The check-ins limit each stretch of work; they do not
    predict the total. The lead recommended option 1. Codex, in its plan
    review, gave its own view: start phase 2, because "it addresses what the
    examples cannot establish".
  - **Question 2, prepared, not asked.** The options: the existing Sonnet
    worker (D96); a fresh Claude Code session; a fresh Codex session; or
    another (for example a dedicated Lean prover service; availability not
    checked). Each in a visible pane (D14). Make no claim about which model
    proves better. Before naming models, check what this machine's Claude
    Code and Codex can actually start, and present only those; say what is
    unverified. On a Codex builder: its family is context, but review
    independence comes mainly from separate findings and runnable checks.
    The lead and Codex both lean to a fresh Claude session, for clean context
    and no restrictions to lift.
  - **Agreed details for when the builder runs.** Records go in
    `experiments/03c-checker/trial/phase-2/`: `CLOCK.md` (the lead's clock:
    each interval's start and end, working and waiting time kept apart),
    `checkin-1-builder-report.txt` (the builder's report as printed, never
    edited) and `CHECKIN-1.md` (the lead's marks of which claims it checked).
    Interval 1 starts when the builder, told phase 2 has started, confirms
    `lake build Trial Checks Promises Proofs Acceptance` works in
    `experiments/03c-checker/trial/lean/`; the stub's four "declaration uses
    `sorry`" warnings are expected and are not a setup failure. At a
    check-in, a promise counts as proven by `ACCEPTANCE.md`, "Partial work",
    checked in a copy outside the repository: a fresh checkout of the lock
    commit `8f1ab40` with only `lean/Proofs.lean` and `lean/Proofs/` copied
    in from the live tree, so check 2 runs as written. Separately, the full
    diff of the live repository from `8f1ab40`, untracked files included, is
    compared path by path with the lead's reviewed changes; any other path is
    a finding, and one outside both lists stops the check-in and goes to
    Robert. If Robert says continue, interval 2 starts at his answer: record
    its start and end in `CLOCK.md` at once and tell the builder to resume;
    a handoff names the next driver as the clock's keeper and neither resets
    nor extends the interval. If he wants a later start, that timing is his.
  - **A fresh session's first action:** check the checkout and the current
    environment, then resolve the pending builder/workflow choice above.
    Question 1 is answered (D101: approval to proceed with proof work); do not
    ask it again or start the clock before builder selection and setup.
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
  parts of the trial's Lean, part 3 (D98: snapshots also record a finishing branch's value and each
  branch's start) in the 30 Sep evening session, and
  part 4 (the promises' Lean statements, step 5) in the late-evening session;
  it is idle with most of its context free (about 80% left). It has not seen
  the predictions and must not be shown them, nor `ACCEPTANCE.md` (which holds
  them) nor anything under `lean/Checks/` (which holds a copy), unless Robert
  lifts that (step 6, question 3). Under D99 it runs neither the three unsafe copies nor
  the copy that never reuses on any program until the lead says the proof
  phase has reached them; it confirmed this. Its
  prompt line may show a greyed suggestion such as "Wait for the oracle's
  sign-off, then commit": that is Claude Code's suggested reply, not an
  instruction, and the worker never commits; clear it before prompting. The
  prediction session (`predictor-w4-t1`) and the check-writing session
  (`checker-w4-t1`) finished and their panes are closed; nothing depends on
  them.
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
  of the 30 Sep night session (step 6 planned, question 1 asked and
  unanswered), reviewed through and pushed through `d715f76` (`main`); a new session checks `git status`, the latest commit and the remote
  before starting. The lead's tab holds three panes: the lead (left), the
  oracle (top right) and the worker (bottom right). Outside a pinned project, `lean` now resolves to
  4.34.1 (elan's default); the experiments pin 4.34.0, so run `lake` inside
  `experiments/03c-checker/trial/lean/`.
- **Practical notes from this session.** `herdr agent prompt ... --wait` gives
  up at the shell tool's ten-minute limit while the oracle is still working;
  follow it with `herdr agent wait` before reading. The shell is zsh, which does
  not split a variable holding several paths; name each path. Robert's Markdown
  hook rewraps whole files, so edits to existing docs go through a python3
  script. `herdr agent prompt` takes `--timeout` only with `--wait`. To run
  something where Robert can watch, split a plain shell pane and use
  `herdr pane run <pane> "<command>"`, redirecting output to a file with no
  pipe and saving the exit status at once; then verify the status file, check
  the captured file exists and is complete, and report that. Stop
  reports from Codex sessions can quote predicted values: read them knowing
  that. Lean's kernel re-checker ships with the pinned toolchain: inside
  `experiments/03c-checker/trial/lean/`, `lake env leanchecker --fresh
  Acceptance`. A new Markdown file written by a script is formatted with the
  hook's own command, `bunx prettier --write --print-width 80 --prose-wrap
  always <file>`. To restart the oracle fresh (as for the bounded question),
  follow the driver skill's end-of-chunk notes: interrupt its pane, then
  `herdr agent start oracle-<tab> --kind codex --pane <pane> -- --yolo`. Required skills: `driver` for the lead, `oracle` for Codex.
- **Parked:** see `research/parking-lot/README.md`.
