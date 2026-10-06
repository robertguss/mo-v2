# Experiment 5: repeated concurrent updates passed

6 October 2026. [ROB-1326](https://linear.app/robert-guss/issue/ROB-1326/repeated-live-updates-under-concurrent-work-and-independent-deadlines).

The queue performed repeated representation changes while four clients submitted
jobs and a background worker completed them. All three required load trials
passed: **480 jobs and 24 successful updates in total**. A separate watchdog
refused a stalled migration without client activity; a newer update succeeded;
the original migration's late result was discarded without replacing newer state.

This closes part of the gap identified in experiment 4: timeouts now advance
autonomously, work really overlaps updates, and update attempts can outlive their
authority. Both implementations are still compiled into the executable. No new
machine code was loaded, and no production software was deployed.

## What ran

One autonomous FIFO worker, multiple TCP clients, eight outstanding-job capacity,
real deque/map representations alternating by epoch, monotonically increasing
attempt IDs, a 200 ms monotonic deadline and a separate watchdog thread. Data
copies and waits occur outside the state mutex. A commit checks the attempt,
base epoch, deadline, quiescence and candidate contents under the mutex.

Work includes an injected minimum **5 ms delay per job**, and migration includes
an injected minimum **20 ms delay**. These exercise overlap and backpressure;
they are not measured costs of an optimized Mo runtime. Admission returns busy
while copying or at capacity; a retained connection does not mean uninterrupted
admission. Clients retry the same job IDs safely.

| Fixed check | Observed result |
| --- | --- |
| Three concurrent load trials | Four producer connections each; 160 jobs and eight activations each; FIFO/payload/receipt checks pass; updates overlap completions |
| Held migration and silent client | Timeout at 200.918 ms; recorded 911.285 ms before the next observation; migration had not returned |
| Late result after newer activation | New attempt activated before the old worker was released; old terminal outcome and newer state remained intact |
| Held old job | Timeout at 201.473 ms; active job remained under epoch 0; release completed old work and a later update succeeded |
| Repeated representation changes | Four successful activations in the dedicated conservation scenario; actual stored values and acceptance order retained |
| Corruption | Nonempty and empty corrupt candidates refused; original state remained usable |
| Duplicate submissions | Same ID/value returns original receipt; different value conflicts; cross-client deduplication checked |
| Two-attempt TLA+ model | All 17 states / 20 changing edges match the lead oracle; safety and fair-timeout termination pass |
| Frozen acceptance | All five hashes unchanged; no threshold or expected result changed |
| Cleanup | All successful scenarios exited gracefully; all deliberately failing mutant runs also exited gracefully and were reaped |

The two timeout observations exceeded the 200 ms budget by 0.918 and 1.473 ms,
within the fixed 750 ms host tolerance. This is observed behavior on one host,
not a real-time guarantee. The OS must still schedule the watchdog, and it still
needs the short state lock.

## A real defect caught and repaired

The first runtime acceptance attempt failed after `hold_work`: the next request
received EOF. The process then required forced cleanup. On this macOS host an
accepted socket inherited the nonblocking listener mode; a read with no bytes
ready returned WouldBlock, and the connection handler exited. A separately
compiled socket probe reproduced immediate WouldBlock despite a one-second
configured read timeout. Source, probe, failed trace and teardown are retained.

The builder explicitly switched accepted sockets to blocking mode, added bounded
read wakeups and handled transient read errors while retaining partial input.
The second complete acceptance run passed unchanged checks. Root authored the
checks before builder implementation and independently ran them. Both agents
shared task context; this is separate authorship, not independent research teams.

## Controls that could have fooled a happy-path test

Every runtime control below changed actual source in a disposable copy, compiled
successfully and executed the unchanged public checks. Compiler failure is not
counted as detection.

| Deliberate defect | Check that rejected it |
| --- | --- |
| Disable watchdog expiration | Held update never reached its terminal outcome |
| Let stale worker publish old candidate | Acknowledged/completed work no longer matched authoritative state |
| Append completion twice | Completion order/uniqueness failed |
| Drop the queue during activation | Acknowledged work disappeared |
| Accept corrupt migration contents | Stored payload rows no longer matched acknowledged rows |

The model's stale-return mutation also violated Safety, producing a retained
counterexample. This model checks only overlapping attempt lifetimes and authority;
it does not model all queues, TCP events, wall-clock timing or Rust schedules.

## Latency observations and a measurement limitation

| Required trial | Busy replies | Request median | Request p95 | Request maximum |
| --- | ---: | ---: | ---: | ---: |
| 1 | 1,412 | 0.263 ms | 1.106 ms | 21.922 ms |
| 2 | 1,387 | 0.259 ms | 0.978 ms | 20.903 ms |
| 3 | 1,408 | 0.240 ms | 1.109 ms | 15.934 ms |

These include submission retries, snapshots, Python parsing and loopback traffic.
They are not job completion latency or throughput comparisons. Snapshot sampling
observed copying spans of approximately 7.384–27.439 ms; it can miss phase
boundaries, so these are not exact admission-pause durations.

The frozen driver's largest observed completion gaps were 769–799 ms. Inspection
showed that the controller stopped sampling while awaiting producer results.
Those numbers are retained but **cannot be interpreted as service outages**.
No acceptance criterion was changed to hide this measurement limitation.

One supplementary run used a dedicated observer connection throughout another
160-job/eight-update workload. It also passed the fixed load checks. It collected
147 observer snapshots; the largest snapshot interval was **31.992 ms**, and the
largest observed interval between completion-count increases was **43.052 ms**.
That sampling granularity remains too coarse to establish an exact maximum
per-job interruption. The observer adds contention and JSON/socket overhead;
its measurements are kept separately, not averaged into the three acceptance
trials. A finer event-time trace would be needed for stronger latency claims.

## What we can conclude

Within these bounds, the prepare/validate/activate protocol still works with
real concurrent clients and autonomous work. Deadline enforcement can remain
responsive while migration or old work is deliberately held. Monotonic attempt
identity prevents an expired worker from overwriting a newer update. Refusal
restores admission and processing without losing already acknowledged jobs.

This is evidence for those mechanisms, not a complete continuously delivered
language. The model is finite; the runtime schedules are observed, not exhaustively
verified. Successful snapshot audits are not a formal Rust refinement proof.
The mutex serializes authority changes, and only one job executes at a time.
Three load trials do not establish fairness, scaling or reliability under all
host scheduling conditions.

Holds use cooperative test gates that release the mutex. This does not establish
hard preemption of arbitrary migration code, safe cancellation of an infinite
CPU loop, or reclaiming resources from an uncooperative native module. Attempts
and retained jobs are bounded (32 and 256), but clients/untrusted input and total
allocation are not hardened or proved bounded. Shutdown proves process exit,
not a universal resource-lifetime theorem for dynamically loaded code.

Still untested: loading a newly compiled artifact, behavior-changing upgrades,
arbitrary user migrations, crashes/power loss, external effects, database changes,
multiple execution workers/nodes, agent-written repair quality or production SLA.
The next proposed milestone should address **code replacement itself and old-code
lifetimes**, while retaining this protocol. Choosing its loader/isolation boundary
and starting that experiment are separate decisions; no further milestone ran.

## Provenance and reproduction

The fixed contract was committed before implementation at
[d75f992](https://github.com/robertguss/mo-v2/commit/d75f9921c9d330ee3ca474d69108015b188784e6).
`LOCK.json` fingerprints the five acceptance files. `evidence/environment.json`
records Rust, Python, Java, TLC hash, host and the unchanged prior experiment.
`evidence/acceptance-01.*` retains the failed attempt; `acceptance-02.*` and its
directory retain the complete passing run. Controls and diffs are under
`evidence/mutations`. The extra observer is under `evidence/continuous-observer`.
Large raw traces and DOT graphs are losslessly gzip-compressed. The manifest
fingerprints all delivered artifacts; the report adds no new test claim.

From this experiment directory, build and reproduce the fixed checks with a fresh
TLC graph (substitute a unique temporary directory and your pinned JAR path):

```sh
cargo build --release --locked --offline --manifest-path runtime/Cargo.toml
```

From `model/`:

```sh
java -Xmx1g -cp /tmp/mo-live-update-tools/tla2tools-1.7.4.jar tlc2.TLC -workers 1 -dump dot,actionlabels /tmp/mo5-graph.dot -metadir /tmp/mo5-states -config RepeatedUpdate.cfg RepeatedUpdate.tla
```

Then from the experiment directory:

```sh
python3 acceptance/run.py --binary "$PWD/runtime/target/release/mo-concurrent-updates" --dot /tmp/mo5-graph.dot --output /tmp/mo5-reproduction
```

In a disposable checkout, `python3 acceptance/mutate.py` rebuilds all five runtime
mutants and the model mutant, writing their traces under evidence. `observe.py`
is supplementary and reads the local binary path from the retained build-02
record; point that record at a fresh local build before rerunning that measurement.
No prior experiment source, specification, acceptance or lock was changed.
