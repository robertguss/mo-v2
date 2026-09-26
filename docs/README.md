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

**24 Sep 2026.**

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
- **Next: plan Experiment 3c** (D71). 3c is the toy pure language with a checker
  that refuses broken in-place demands (D42), with 3b's helper as a candidate
  runtime foundation. Lean's role is proving the rules correct (D47). Keep
  correctness (a proof that accepted programs meet the demand) and usefulness
  (examples showing useful programs are accepted) as two separate checks (D62).
  Bring the plan to Robert as a proposed experiment (D60, D64), worked through
  with Codex first (D61); the lead's first question to Robert is the first one
  the 3c plan raises.
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
  next steps. Open now: the trial's scope (the lead and Codex propose the reuse
  rule on a tiny language without function calls, run on examples and then
  proven by a builder). Waiting until after the trial: whether the full 3c has
  a time cap (Robert challenged having one; not decided), approving the plan,
  and running builders on a cloud VM instead of Robert's laptop.
- **Still open from 3b's result,** to take with Robert one at a time: proposal 2
  (Rust's `Rc` header spends half its space on a weak-holder count Mo may not
  need; a question for design choice 8) and proposal 3 (sharing cost about 3.8×
  in both the helper and Koka; a starting case for the D59 copy-feedback
  follow-up).
- **Codex** runs in the Herdr pane to the right of the lead (`herdr agent list`
  shows it). The 3b builder's pane can be closed.
- **Parked:** see `research/parking-lot/README.md`.
