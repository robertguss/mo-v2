# Errors

Mo splits all errors into two kinds that never mix.

Failure: The world misbehaved: a missing file, a dropped network, bad user input. Declared in a function's signature; the compiler forces every caller to handle it. Not a bug.

Defect: The program misbehaved: a broken contract, an impossible state, a wrong result. A bug in agent-written code. Never handled or caught; it stops the unit of work and produces a defect report.

Defect report: The structured diagnostic a defect produces: which contract failed, the values involved, and where. Always sent somewhere a human or agent will see it, even when the system recovers.

Fail fast: Stop at the first sign of a defect instead of continuing with bad state.

Supervision: Erlang-style recovery: when a unit of work hits a defect, only that unit stops, and a supervisor keeps the rest of the program running. Decided for Mo.

Supervisor: The part of a program that watches units of work and restarts or replaces them after a defect. If a unit fails too often in a short window, the supervisor escalates instead of retrying.

Compiler bug: A defect in Mo's own compiler or tooling. Distinct from a defect in a Mo program.
