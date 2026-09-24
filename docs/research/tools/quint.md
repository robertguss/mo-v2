# Quint

**Label:** Candidate tool (agreed 23 Sep 2026; not a decision)

Quint (https://quint.sh) is an executable specification language from Informal
Systems, built on TLA+'s ideas but with typed, programmer-friendly syntax. You
describe how a system should behave, and its tools check that description:

* a simulator and a REPL
* model checkers (Apalache and TLC)
* model-based testing through quint-connect, which produces traces that real
  code must reproduce

Its pitch is "AI Generates Code. Quint Generates Confidence."

## Where it could help Mo

* **Running programs and concurrency experiments:** supervisors, processes,
  where state lives, and the in-place helper when several threads share counts.
  It takes TLA+'s place among the candidate tools listed in
  [Experiment 3's plan](../../../experiments/03-in-place/PLAN.md): it does the same job,
  with readable syntax and a simulator.
* **As a verification method to compare (D38):** checking real code against
  traces from a spec. Experiment 2 didn't test this method.

## Limits

* It checks designs, not code. Whether the code matches the design is tested
  through traces, never proven. This is the same gap Experiment 1 found (D15).
* Model checking explores a finite world. It is strong for protocols and state
  machines, and weak for data-heavy logic.
* It's a separate spec language. Mo is a single language (D34), so Quint is a
  tool for testing ideas, not a design to copy.
