# Decisions

One line per decision. Robert makes every decision; an AI may propose, never
decide. A row states the decision, not the argument; the argument lives in
`DECISION-MAP.md` or the conversation it came from.

| #   | Date        | Decision                                                                                                                                                                               |
| --- | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| D1  | 22 Sep 2026 | v2 is Robert's own language. If "build my own language" and "make AI-written code verifiably correct" ever conflict, building the language wins.                                       |
| D2  | 22 Sep 2026 | Purpose: a language designed for AI agents, not human authors, so they can write reliable, safe software that no human writes or reads. Verification is the central problem it solves. |
| D3  | 22 Sep 2026 | Guiding principle (Robert's words): make it really hard to do the wrong thing and very easy to do the right thing.                                                                     |
| D4  | 22 Sep 2026 | General purpose. No single target domain.                                                                                                                                              |
| D5  | 22 Sep 2026 | Robert does not read v2's code, including the code of the language itself. He verifies through specs, tests, simulation and proofs. v2 has to prove its own premise.                   |
| D6  | 22 Sep 2026 | Robert makes every design decision. AI agents propose options and build what is decided.                                                                                               |
| D7  | 22 Sep 2026 | v2 starts in a fresh repo, `~/Projects/startups/mo-v2`, local git only; a remote comes when Robert chooses. v1 is archived as reference.                                               |
| D8  | 22 Sep 2026 | ~~Answer the decision map before building anything.~~ Superseded by D10 the same day.                                                                                                                                      |
| D9 | 22 Sep 2026 | Robert is new to language design and formal methods. For every decision, the AI guides: it explains the concepts, lays out options and tradeoffs, and makes a recommendation. Robert still decides. |
| D10 | 22 Sep 2026 | Build in small steps with quick feedback: pick a small idea, then implement, validate and verify it before adding the next. No large upfront brainstorming. |
