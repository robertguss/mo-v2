# Approved timing amendment 01

Robert explicitly replied **"approved"** to 30 minutes for sum, then the
unchanged 10 minutes for discard only if sum passes, with implementation,
bounded validation and an exact freeze before full execution in the
[continuation thread](https://ampcode.com/threads/T-01a120a8-5f89-72d7-a894-b48b82ed155c).
This supersedes the pending-approval status of [PROPOSAL.md](PROPOSAL.md), whose
historical bytes remain unchanged. It does not accept Stage B or authorize
merging PR #9. Previous 900-second failures and both OOM attempts remain failures
under their original contracts.

## What is frozen

The versioned collector adds exclusive nested monotonic wall attribution around
the unchanged candidate interface. It preserves every semantic row, observation
request, recursive JSON validation and equality check of collector-01. Candidate,
cells/runtime, approved ownership verifier, strict decoder and all prior locks
are unchanged. Release/locked Rust 1.98.1 produced a separate executable; neither
old pinned executable is overwritten. The existing CPython 3.14.7, JIT disabled,
remains pinned transitively.

`envelope.py` preserves all non-time resource predicates, including depth,
answers, transition cap, physical cell counts, zero remaining owned cells,
explicit frames, provisioning floor and child stack. It checks actual elapsed
against 1,800/600 seconds explicitly; it never clamps or fabricates an elapsed
observation to satisfy the original 600-second helper. All other semantic/source
checks stay in the unchanged ownership verifier, selected explicitly.

`LOCK.json` pins these sources, validation evidence and the new native executable,
then transitively verifies the ownership, collector, performance, revision and
original locks plus both old binaries. The full runner rejects changed files,
wrong executables, a changed workload memory cap or insufficient evidence disk.

## Measurement intervals and limitations

Native sidecar schema: exact fields `format = "ROB-1333 native timing 01"`,
`unit = "ns"`, `completed`, `elapsed_ns`, and `exclusive_wall_ns`. The latter has
exactly `frontend`, `evaluation`, `cleanup`, `observation`, `collector`,
`transport`, `approval_wait`. Every duration is a nonnegative integer; their
sum must equal `elapsed_ns`. A fresh path comes from `ROB1333_TIMING_FILE`, not
from candidate inputs. Missing, oversized, duplicate-key, malformed, incomplete
or inconsistent evidence cannot pass. The parent checks the native interval
does not exceed its own elapsed interval.

The native interval starts after environment/path preflight, before request IO,
and ends after the serve body and its local drops return. It excludes sidecar
persistence and process startup/exit; those remain inside the parent watchdog.
Nested callbacks switch from evaluation to collector, then observation/transport
as appropriate. Candidate-generated callback metadata outside the callback stays
in evaluation. This is instrumented candidate-call wall time, not pure evaluator
CPU or a measurement of execution without observers. Descheduling and timer cost
are included. Candidate run/program drops are classified as cleanup, including
error paths. Host observer teardown is collector work.

Parent categories are launch/request, read/wait/framing, retention/hash, decode,
predicates, reply writes, finalization and residual orchestration. Their sum
equals the parent ledger interval. The success ledger ends before summary
persistence; the watchdog continues through both summary writes/closes and the
final elapsed recheck. The saved summary labels its pre-write elapsed snapshot;
the returned result, persisted by the outer runner, records authoritative final
elapsed and finalization remainder. The resource row likewise retains its real
pre-finalization timestamp, never a substitute for final watchdog completion.
Verifier retained-state release, native exit and required evidence closure are
timed. Request construction/retention is also timed, a stronger start boundary
than the previous orchestrator. Failure recovery after a spent watchdog is
labelled separately and cannot turn a failure into a pass. Subsequent preservation
hashes and lossless archive packaging are not workload operations.

Native and parent intervals overlap; **never add their wall totals**. Process CPU
and peak RSS are supplemental whole-process values, not evaluator-only values.
There is no newly invented evaluator speed threshold. The 1,800-second allowance
is an owner-approved operational budget, not a predicted passing time or SLA.

## Bounded evidence before the full run

Six fresh baseline/instrumented pairs at sum depths 64, 10,003, 20,003 and 40,003,
and discard depths 64 and 10,003, each complete all semantic checks, deepest
observation, completion and both destruction calls. All **1,281,570 normalized
rows match**; only elapsed clocks and physical addresses are excluded. Each
stream is independently checked by the unchanged approved verifier. Full-depth
numeric rejection is expected for these scaled runs; they are not acceptance.

**31 envelope assertions** cover both sides of each limit, invalid elapsed types
and unchanged physical/transition checks; AST comparison preserves every original
non-time statement except case-domain spelling and the split transition clause.
**15 harness probes** cover valid/invalid sidecars, duplicate keys, impossible
intervals, abnormal native exit, stalled children, and real delayed-verifier
backpressure/watchdog handling. Synthetic process results are harness checks,
not evaluator controls or scientific resource evidence.

A deliberate 0.8-second source-check delay appears as 0.812214 seconds of native
approval wait; a 0.8-second first-commit check delay appears as 0.831810 seconds
of native transport. Native evaluation stays about 0.012152/0.009143 seconds,
respectively. Both delays are also included in parent predicate time and are
interrupted under a 0.2-second test watchdog. This distinguishes wait attribution
from incorrectly charging it to evaluation.

Single paired sum pipeline measurements (baseline versus timed): 7.320724/8.248496
seconds at 10,003; 14.653086/15.984723 at 20,003; 30.343345/31.916178 at 40,003.
The largest pair is about 5.2% slower, not an optimization. These include runner
and instrumentation differences, vary with scheduling, and are not isolated
timer overhead, latency distributions or full-size predictions. Five Rust tests
and formatting checks pass. Implementation and validation are same-agent work,
not independent acceptance review or universal equivalence proof.

Complete raw public validation inputs, rows, summaries and logs are packaged with
the established bounded-volume archive reader/restore/hash checks. Reproduce:

```sh
PY=/home/user/.local/share/uv/python/cpython-3.14.7-linux-x86_64-gnu/bin/python3.14
CARGO_TARGET_DIR=/home/user/NEW-timing-target cargo +1.98.1 build --release --locked --manifest-path experiments/13-source-acceptance/stage-b-timing-01/link/Cargo.toml
$PY experiments/13-source-acceptance/stage-b-timing-01/validate.py /home/user/NEW-timing-validation /home/user/NEW-timing-target/release/rob1333-stage-b-link
```

Different builds may have different fingerprints; the full runner accepts only
the exact frozen executable. Do not overwrite the tested binary by reproducing.

## Execution boundary

Commit/push this freeze before the single full attempt. Use a fresh external
directory; run sum1800, then discard600 only after a passing sum. Preserve all
full observations and every-record/source/history/ownership checks. Keep the
eight-MiB child stack, four-GiB provisioning floor and existing 42-GiB workload
cap / 64-GiB filesystem. Record actual disk/cgroup state before and after.

Stop at the first material failure, without repair, limit extension or retry.
Use an exclusive launch marker so supervisor restarts cannot rerun the workload.
No separate sampler, concurrent builds, packaging or heavyweight validation;
sparse shell progress reads are disclosed observer overhead. No private cases or
new evaluator controls. Both orbs remain unarchived; no merge or deployment.
