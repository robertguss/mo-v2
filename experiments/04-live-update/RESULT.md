# Experiment 4: the bounded transition passed

5 October 2026. [ROB-1323](https://linear.app/robert-guss/issue/ROB-1323/live-update-milestone-model-and-test-a-two-version-queue-transition).

A small Rust queue successfully switched its live state from a deque to an
ordered map. Within the fixed experiment, it preserved acknowledged jobs,
their order and payloads, refused incomplete/corrupt/expired updates, and kept
the same TCP connection usable. This supports testing the protocol further.
It does not establish a production hot-reloading language or eliminate CD yet.

## What was actually tested

Three possible job IDs, capacity two including active work, one update attempt,
and a three-tick budget. The old representation stays authoritative while the
candidate is copied and checked. Activation rechecks it, including corruption
injected after validation. A refusal discards the candidate and resumes the old
state. An active job must finish before copying can begin; a drain timeout keeps
that job intact so it can finish under the old version.

Both versions are compiled into one executable. Work and update progress are
explicit commands in one event loop. Payloads are real stored values, observed
on completion. The ordered map uses sequence numbers, not job IDs, so submitting
job 3 before job 1 still completes 3 before 1 after migration.

## Evidence

| Check | Result |
| --- | --- |
| Complete TLC exploration | 1,170 distinct states; safety and fair-tick termination pass; no states left to explore |
| Model versus independent contract | All 1,170 states and 3,955 labeled changing edges match |
| Rust public-interface replay | 22,230 state/command cases: 19 commands at every contract state |
| Responses including path setup | 230,510 compared, including fixed examples and failure traces |
| TCP continuity | One connection, 25 repetitions, 1,800 compared commands, clean exit on EOF |
| Broken Rust implementations | All five compiled, ran and were rejected for wrong behavior |
| Broken TLA+ implementations | Lost work and duplicate completion each violate Safety |
| Fairness assumption removed | Termination fails; TLC supplies a forever-paused counterexample |
| Frozen checks | All five original file hashes unchanged |
| Build | Clean release build, offline/locked, no dependencies or compiler warnings; formatting check passes |

The lead wrote and committed the contract/checks before the local builder wrote
the model/runtime: [contract commit](https://github.com/robertguss/mo-v2/commit/3d65740b2c67bab109afe9b017ebf7a44dd94741).
The builder did not author or edit acceptance. Both agents shared the task
context; this is separation of authorship, not a claim of independent teams.

The first acceptance attempt failed before runtime replay because TLC collapsed
three enqueue wrapper names into one edge label. The builder inlined those
actions; no expected state, transition, threshold or check was changed. The
second complete acceptance run passed. Both attempts and both TLC logs/graphs
are retained. This was an observability repair, not a change to queue behavior.

## Deliberately broken controls

| Actual source mutation | Expected observation | Outcome |
| --- | --- | --- |
| Drop queue contents at activation | Acknowledged job missing | Rust check and TLC Safety reject |
| Append a completion twice | Duplicate completion | Rust check and TLC Safety reject |
| Permit activation during draining with a live old job | Wrong version/pinned work boundary | Rust check rejects |
| Skip candidate validation at activation | Corrupt candidate activated | Rust check rejects |
| Permit activation after refusal on timeout | Expired update activated | Rust check rejects |
| Remove weak fairness of budget ticks | Update can remain pending forever | TLC temporal-property check rejects |

These controls mutate real transition sites in disposable source copies, not
just response formatting. Diffs, compiler outputs, wrong responses and TLC
counterexamples are in [evidence/mutations](evidence/mutations). Five additional
fixed public-response mutations establish basic comparator sensitivity; they
are not counted as five further implementation defects discovered.

## Measurements and limits

On this local macOS run, command round-trip median was **0.286 ms**, p95
**0.309 ms**, and maximum **0.416 ms**. For the 25 explicitly timed successful
updates, observed begin-to-activation median was **1.822 ms**, maximum
**1.882 ms**. This includes Python, snapshots and socket overhead. Mutation
builds ran concurrently on the same machine. These are observations, not
isolated runtime benchmarks, service-level objectives or real-time guarantees.

TLC checks this finite model. The oracle checks the complete finite labeled
graph. Rust is checked by a shortest-path replay to every observable state and
every command from there; this is not a formal refinement proof and does not
enumerate every possible hidden implementation history. Source review verified
the two actual representations, payload copies, commit point and guards.
The model abstracts physical representation and corruption; no proof about
compiled Rust, the OS or arbitrary data follows from the matching graph.

An update finishes or refuses only if budget ticks continue to run. Removing
that assumption produces a counterexample. The executable does not yet supply
an autonomous real-time timer. Capacity bounds acknowledged work; the transport
is a test harness, not a hardened API with bounded untrusted-input memory.

Not tested: dynamically loading new machine code, repeated upgrades in one
service lifetime, concurrent clients/workers, sustained traffic, crash/power-loss
recovery, database changes, external side effects, allocator failure, realistic
memory/CPU bounds, supervision, agent-generated migration quality, or whether
behavioral changes meet a user's intent. No external exactly-once effect or
post-activation rollback guarantee is made. Existing Lean experiments and their
locks remain unchanged.

## What this suggests next

Keep the explicit prepare/validate/activate boundary and refusal semantics as
experimental candidates. Treat update progress and admission control as part of
the runtime contract. A validated snapshot alone is insufficient: activation
must still ensure it is the right candidate at the right boundary.

The next recommended experiment is repeated updates under real concurrent work,
with an independently progressing timeout, measured admission pauses and failure
injection. That closes the largest gap between this command-driven model and a
continuously evolving service. Actual code loading then adds a separate lifetime
problem: old functions, stacks and resources must retire safely. Neither next
experiment is started or approved by this result.

Rust was practical for this prototype. This is no compiler/backend benchmark
and does not settle Rust versus other implementation languages permanently.
TLA+ earned a role here by checking ordering and exposing the fairness assumption;
Lean remains appropriate for selected universal semantic claims. There is no
reason to add Quint, Loom, Kani or a JIT until the next specific question needs it.

## Reproduction and retained files

Tool identities, official TLC download URL/SHA256 and original lock verification
are in [environment-and-initial-lock.json](evidence/environment-and-initial-lock.json).
The successful run is [acceptance-02.stdout](evidence/acceptance-02.stdout), with
its command/exit status in the adjacent JSON file. Final TLC output is
[tlc-02.log](evidence/tlc-02.log). All DOT graphs are losslessly gzip-compressed;
the final graph is `evidence/graph.dot.gz`. The prior graph only differs in its
enqueue labels. Tool-generated liveness graph is retained for the final run.

From this directory, with the pinned JAR available, a fresh reproduction can use
temporary output paths (substitute an absolute JAR path):

```sh
cargo build --release --locked --offline --manifest-path runtime/Cargo.toml
python3 -c 'import gzip; open("/tmp/mo-graph.dot", "wb").write(gzip.open("evidence/graph.dot.gz", "rb").read())'
python3 acceptance/run.py --binary "$PWD/runtime/target/release/mo-live-update" --dot /tmp/mo-graph.dot
```

For a fresh model exploration, run from `model/`:

```sh
java -Xmx1g -cp /tmp/mo-live-update-tools/tla2tools-1.7.4.jar tlc2.TLC -workers 1 -dump dot,actionlabels /tmp/mo-fresh.dot -metadir /tmp/mo-fresh-states -config LiveUpdate.cfg LiveUpdate.tla
```

Then pass `/tmp/mo-fresh.dot` to the same acceptance command. In a disposable
checkout, `python3 acceptance/mutate.py` reproduces five Rust and two safety-model
controls. The separate no-fairness control removes ` /\ WF_vars(Tick)` from
`Spec` and reruns the unchanged TLC configuration; its exact patch is retained.
Checks need Java 21, Python 3 and Rust supporting edition 2024; the observed
versions are recorded. Generated build directories and TLC state stores are
excluded from Git. No code was merged or deployed.
