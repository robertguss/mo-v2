# Acceptance fixed before builder implementation

Lead owns SPEC.md, this file, acceptance/oracle.py, acceptance/run.py and
model/LiveUpdate.cfg. Builder owns runtime/ and model/LiveUpdate.tla. No builder
edits to acceptance. Owner explicitly approved one local builder and separate
checks. The old trial workflow is not in use.

1. Hash these five files before handing off implementation. Preserve hashes.
2. Run pinned official TLC 1.7.4 release JAR (reports TLC 2.19), SHA256
   `936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88`.
   Use `java -Xmx1g -cp <jar> tlc2.TLC -workers 1 -dump dot,actionlabels
   <evidence>/graph.dot -metadir <temporary-states> -config LiveUpdate.cfg
   LiveUpdate.tla` from model/. Retain stdout/stderr and exit status. Require
   completed search, safety and temporal-property success, no unexplored limit.
   A timeout/error is inconclusive, never passing. Bound each run to five minutes.
3. Independently enumerate the contract in acceptance/oracle.py. Its hand-written
   examples include non-numeric FIFO, active drain timeout and incomplete copy.
   Compare the complete TLC reachable state set AND labeled command-edge set
   to the oracle; missing/extra states or edges fail. This model-to-oracle check
   is evidence of finite correspondence, not formal refinement of Rust.
4. Clean build the stdlib Rust executable. For EVERY oracle state and EVERY
   command (including blocked, duplicate, busy and invalid input), reset/replay
   a shortest path through the public stdio interface and compare the response.
   Reject missing output, exceptions, timeouts, extra/missing JSON fields, wrong
   status or state. Do not weaken checks for implementation convenience.
5. Keep ONE loopback connection open across 25 repetitions of positive examples,
   failure traces and successful transitions. Compare every response. Require
   clean exit on EOF. Retain timings as observations; no latency threshold or
   resource-control claim is set in this first finite experiment.
6. The five fixed public-response negative controls must differ from the
   contract's expected response. These establish checker sensitivity only.
   Additionally make disposable source mutations at actual implementation/model
   sites for those same faults where feasible; root chooses the exact sites
   after reading builder code. Run the UNCHANGED trace checks/model invariants
   against each, preserve diffs/errors and report the actual control coverage.
   No source mutation may be counted solely because it fails compilation.
7. Retain attempts, failures, tool versions, logs, lock verification, correspondence
   counts and limits in evidence/ and RESULT.md. Reject any fabricated/skipped
   success. If the check harness itself needs a mechanical parser/runner repair,
   preserve its original lock and report/relock that repair; a semantic change
   needs owner input. Compiler warnings, source representation/payload checks and
   absence of non-stdlib dependencies are reviewed independently by the lead.

Stop when this bounded experiment is reported, or when a specification conflict
or unrepairable blocker needs Robert. Building the full compiler, native loader,
production rollout, later research experiments and merging are not authorized
by this milestone. Delivery is a dedicated branch push; Linear remains the live
record. Acceptance is experimental evidence, not permission for autonomous
production changes.
