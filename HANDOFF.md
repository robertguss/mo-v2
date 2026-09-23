# Handoff

Read this first, then `CLAUDE.md`, `PICTURE.md` and `DECISIONS.md`. Last updated
23 Sep 2026, at the end of the session that created this repo.

## Where we are

Mo v2 is Robert's programming language for AI agents to write reliable, safe
software that no human writes or reads (D1–D5). The repo is two days old. It has
two finished experiments and an accepted big picture, and no language code yet.

**The open question to Robert** (ask it first, as the only question in your
first message): _We're about to work through the seven areas in `PICTURE.md` at
the concept level. The recommendation is to start with area 1, the spec layer.
Both experiments showed it's the part everything depends on, it's the part only
Robert writes, and it's what makes Mo different. Should we start there, or with
a different area?_

Robert asked to stay at the conceptual level for now (D19): what Mo is, its
features, and how they fit together. Go granular only after that. Experiments
resume when a concept needs testing.

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
- **Commits:** local git only, no remote (D7). Commit named paths only, with the
  attribution line.
- Never use `tr` in shell commands; use python3.
