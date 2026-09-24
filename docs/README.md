# Mo v2

A programming language for AI agents to write reliable, safe software that no
human writes or reads. Robert designs it; AI agents build it.

This is a fresh start. Mo v1 lives in `../mo-lang`, frozen at commit `d58f67cd`
(22 Sep 2026). v1 is reference material, not a base: nothing is copied from it
without a decision in `DECISIONS.md`.

## Files

- `HANDOFF.md`: where things stand and how to continue. Read first.
- `DECISIONS.md`: every decision, one line each. Only Robert makes them.
- `DECISION-MAP.md`: the open questions v2 must answer, in the order to answer
  them, each with options and a recommendation.
- `research/`: all research documents, moved from TheBrain on 23 Sep 2026 (D54).
  Key parts:
  - `research/documents/design-choices/`: the nine big design choices
    (D24–D33), each with its options.
  - `research/big-picture/`: the working picture (D20, updated by D34), with
    earlier research filed under its areas.
  - `research/documents/`: the Design Doc, the Glossary and the Language design
    primer.
- `CLAUDE.md` (at the repo root): working rules for any AI agent in this repo.

## Status

23 Sep 2026: three experiments done (`experiments/`). The nine big design
choices are made (D24–D33). Mo is one Ruby/Elixir-like language that does
everything through its compiler and runtime (D34). Experiment 3 tested D26 in
Koka: claims A, C and D passed, and claim B is observational
(`experiments/03-in-place/RESULT.md`). Next: Robert
decides what the result means for D26, then Experiment 3b.
