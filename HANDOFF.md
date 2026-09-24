# Handoff

Read this first, then `CLAUDE.md`, `docs/research/documents/design-choices/`
and `docs/DECISIONS.md`. Last
updated 23 Sep 2026, in the session that made the design choices, ran and
verified Experiment 3, and moved the research from TheBrain into this repo.

## Where we are

- **Design choices, D24–D33.** Robert worked through nine big design choices
  from a blank slate:
  - a static checker, with contracts and proof on top
  - no guessing
  - pure code, with in-place updates the checker can prove
  - no null
  - failures returned as values, bugs stop the part that hit them
  - listed effects plus capabilities
  - plain data, modules and limited shared abilities, with no OOP
  - memory freed by counting holders, with pools to explore
  - Ruby/Elixir syntax

  Each choice is a folder in `docs/research/documents/design-choices/`, with its
  options inside.
- **What Mo is now, D34 and D35.** Mo is one Ruby/Elixir-like language that
  does all of that through its compiler and runtime. The two-languages picture
  in D20 is superseded. Syntax and how promises are written are deferred.
  Robert's interest is the compiler and runtime ideas.
- **How decisions are made, D38.** Every decision rests on real tests,
  measurements and data. Each idea is tested, then the realistic alternatives
  are tested the same way and compared.
- **Experiment 3,** in `experiments/03-in-place`, tests D26 in Koka against
  Rust. The plan (D44) and acceptance file (D50) are approved and locked; the
  fingerprints are in `LOCK.md`. The lead's `acceptance/measure.py`, run with
  `./run.sh`, does all building, timing and scoring. The builder brief is
  `briefs/builder.md`.
- **Follow-ons (D42).** 3b builds the in-place helper in Rust. 3c is a toy
  language with a checker for in-place demands, only if 3b looks promising.
  Lean's role is proving the rules (D47).

**Next step:** Experiment 3 is done. Claims A, C and D pass, and claim B is
observational; see `experiments/03-in-place/RESULT.md`. Codex verified it
(`council/verify-codex.md`), and the reporting corrections are made (D55). Still
open, each needing Robert's approval:

1. The locked-file fixes from that verification: the strict-demand scoring bug,
   the plan's stale claim D and reversal wording, the warm-up output check, and
   the acceptance file's fingerprint placeholder. After those, a re-run and a
   new lock.
2. The lead's readings in RESULT.md's last section. Bring them to Robert one at
   a time; none is decided.
3. Then Experiment 3b, the in-place helper in Rust (D42).

## How to work with Robert

These are his stated preferences. Follow them exactly.

- **One question per message.** Wait for the answer.
- **Guide him (D9).** He is new to language design and formal methods, and he
  doesn't know what he doesn't know. For each decision, explain the concept in
  plain words, lay out the real range of options (not a narrow list), give the
  tradeoffs and name real languages that chose each option, then make one
  recommendation. He pushed back when options were too narrow. Show him the
  whole design space.
- **He decides; you propose (D6).** Record only decisions he actually made, as
  one line in `DECISIONS.md`. v1 failed because AIs made about 85% of its
  decisions.
- **He never reads code (D5).** Show him specs, promises in plain English,
  examples as tables, and results. Explain every theorem in plain English.
- **Small steps, quick feedback (D10), and the big picture first (D19).** Avoid
  large upfront brainstorms, and avoid getting lost in detail.
- **Evaluation (D13).** Models will write Mo worse than Go or Python because
  they've never seen it. Never compare writing cost or token counts. What
  matters is fast, helpful feedback that leads agents to correct Mo.
- **Builders run in visible Herdr panes (D14),** never as hidden subagents:
  `herdr agent start <name> --kind claude --pane <id> -- --dangerously-skip-permissions`.
  A new folder triggers a trust prompt, and Robert must approve each one.
- **AI council (D21):** use Codex (`--kind codex`) for independent review. Don't
  use Gemini. Give the council a single, clear question, such as "find a
  loophole in this spec". Don't add review layers.
- When he asks something basic, answer it plainly and without condescension.
  Checking in with a comprehension question is fine, but make it concrete; an
  abstract one confused him.

## Why v2 exists

v1 (`../mo-lang`, frozen at `d58f67cd`) was archived on 22 Sep after an honest
assessment:

- In 11 days it produced 1,235 commits, about 64k lines of AI-written Zig and C,
  and a 700-row decision log, about 85% of it decided by AIs alone.
- Its central claim (that contracts and `never` clauses catch bugs tests miss)
  caught zero bugs in its experiments.
- Its type checker was unsound, and every feature was implemented twice.
- It drifted into home-made crypto and TLS, and layers of AI process.

**Worth keeping from v1:** Robert's syntax taste (Ruby's look, `end` blocks, no
OOP, immutable by default, errors as values, no nulls, crash on overflow),
diagnostics designed to teach, deterministic simulation, capabilities, and the
idea that a human is pulled in when the spec changes. `DECISION-MAP.md` Q8 has
the keep/drop table. It's a parking lot: nothing from it is decided.

## What the experiments showed

- **Experiment 1** (`experiments/01-tiny-safe`, `RESULT.md`): Lean proved a tiny
  type checker safe. Two lessons:
  - A safety promise alone lets a checker that rejects everything pass; examples
    Robert approves close that gap.
  - Lean proves "won't break in these ways", not "does what was meant" (D15,
    Robert's own conclusion).
- **Experiment 2** (`experiments/02-withdraw`, `RESULT.md`): seven verification
  methods against ten planted bugs in `withdraw`.
  - The Lean proof (10/10) and a Codex review (10/10, with caveats) caught
    everything.
  - Example tests, property testing, exhaustive small-range checking, contracts
    and differential testing caught 5–7 each. All five missed the bugs that
    appear only on rare, large inputs.
  - The key lesson: **a proof is only as strong as its spec.**
- Parked follow-ups: spec-gap testing, a harder council test (one version,
  larger code), correct-by-construction types.

## Practical notes

- **Lean:** 4.34.0 via elan (installed with Homebrew). Each experiment is a Lake
  project. Run `lake build` inside it; for Experiment 2, `lake exe score` prints
  the scoreboard.
- **The lock pattern that worked:**
  1. The lead writes the spec and acceptance files, and Robert approves them.
  2. Record their hashes.
  3. The builder writes only its own file.
  4. The lead verifies independently: hashes, a clean rebuild, `#print axioms`,
     and a deliberately broken copy that must fail.
- **Koka:** 3.2.9 via Homebrew. Its `fip`/`fbip` in-place checks only *warn*;
  they never refuse a program (D41). **Rust:** 1.98 via Homebrew.
- **Commits:** the repo is public at https://github.com/robertguss/mo-v2.
  Refer to repo docs by URL. Commit named paths only, with the attribution
  line, and push only when Robert asks.
- **This session ran in the Claude desktop app,** not inside Herdr, so it could
  not open Herdr panes itself. Check `HERDR_ENV` before trying.
- Never use `tr` in shell commands; use python3.
