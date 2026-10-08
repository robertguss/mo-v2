# Explicit observation candidate adaptation — bounded checks pass, local only

Robert approved freezing the reviewed replacement acceptance package and then
adapting the candidate in the acceptance thread. The additive freeze is
`../stage-b-revision-02/LOCK.json`, SHA256
`5749ccb78db090744b9e96c6030e92a80b83776accbf21f5a1dc66e32fa523fc`.
The original lock, reviewed revision and final-03 baseline remain unchanged.

Stop condition: implement explicit summary observations in this separate copy,
check them through the frozen revised native host/verifier at small sizes,
check ordinary-run regression and allocation-denial behavior, and report the
actual result. Do not change the frozen checks to match this implementation.
No private cases, million-element workloads, commit, push, merge or deployment.

Summary observations must be read-only. The implementation counts
distinct input-reachable cells once during begin using the existing allocation
gates, then updates cell counters only after committed operations. Summary
serialization reads these counters and the requested logical-event suffix;
it performs no native reads or allocation-gate calls. The two approved large
workloads have no external roots. This is not a general observer for hidden,
disconnected host-held storage.

## Results

Rust 1.98.1 locked build, 54 candidate development tests, three frozen collector
tests, candidate Clippy with warnings denied, and formatting checks pass. The
one new candidate development test checks repeated full/summary observations,
invocation-event filtering and unchanged state/allocation gates. No acceptance
test, expected value or threshold was changed during this adaptation.

The frozen revised `check_revision.py` passed 891 small native destruction-cut
runs (depths 0–8) and rejected its deliberate missing-deepest-observation run.
It also passed 873 comparisons against the unchanged reference, opaque identity
replay, and the ten existing corrupted-stream/summary probes. The additional
compiled protocol-stub run is explicitly not evaluator evidence.

`validate_public.py` invokes only the frozen revised large verifier and original
per-run small verifier; it introduces no acceptance predicate. Its retained
report has `passed: true`:

| Public validation | Passing extent |
| --- | ---: |
| Real evaluator summary runs | 4, including 9 periodic summaries |
| Full public examples | 21 |
| Resume at every public boundary | 1,624 |
| Destruction at every public boundary | 1,624 |
| Every observed public begin-allocation denial | 42 |
| Historical public corpus, full runs | 4,276 |

Real summary runs used discard depth 10,003 and recursive-sum depth 2,003, each
with both a deepest-destruction and completed schedule. Every schedule includes
the deepest full observation, exact-grid/off-grid pauses and zero-budget joins.
They checked 100,123 committed actions in total. These are real native evaluator
runs, not the earlier protocol stub, but are not million-element resource tests.
The public campaign took 650.812 seconds; the separate small suite took 23.719
seconds. These durations include verifier/evidence overhead, not a benchmark.

All 967 originally frozen files, five historical dependencies and all 41 files
of the replacement freeze verified unchanged before/after the public campaign.
The preservation field `candidate_byte_identical` refers to the retained
final-03 baseline, not this explicitly modified adaptation.

## Evidence and reproduction

Raw requests, per-run rows, stderr, ledger, summaries and logs are preserved at
`/home/user/rob1333-stage-b-adaptation-checks/` in this orb. `evidence/` retains
copies of the small/public result summaries and build/test logs. The runner
uses new destinations only and stops on the first rejection. No private input
or private-run evidence is included or consulted.

The campaign and final rebuilt native binary have identical SHA256:
`7b38989835db8ef6fd274477f625caf5c35e6438256d405f4b5242703427491a`.
Runner SHA256:
`4a6aa55bf812fb9a7a97cd8e1d108b73e7f0348f432ad2564dc0d0dffac2e281`.
Candidate manifest SHA256:
`cc1e09dac565f67341bffee062fa0abbd080f9c60ebeac2fed522f56ff14317e`.
The final build includes the new development test's source; that test-only
addition did not change the native executable bytes used throughout the runs.

From this directory, with a fresh external target/evidence directory:

```sh
export CARGO_TARGET_DIR=/tmp/rob1333-adaptation-target
cargo +1.98.1 build --locked --manifest-path link/Cargo.toml
cargo +1.98.1 build --locked --manifest-path ../stage-b-revision-02/stage-b-stub/Cargo.toml
cargo +1.98.1 test --locked --manifest-path candidate/Cargo.toml
cargo +1.98.1 test --locked --manifest-path ../stage-b-revision-02/driver/Cargo.toml
cargo +1.98.1 clippy --locked --manifest-path candidate/Cargo.toml --all-targets -- -D warnings
cargo +1.98.1 fmt --manifest-path candidate/Cargo.toml -- --check
python3 ../stage-b-revision-02/check_revision.py /tmp/rob1333-adaptation-small "$CARGO_TARGET_DIR/debug"
python3 validate_public.py /tmp/rob1333-adaptation-public "$CARGO_TARGET_DIR/debug/rob1333-stage-b-link"
```

## Limits and remaining gates

This is same-author implementation verification using already frozen checks,
not a new independent review or complete Stage B acceptance. The original
submission, original locks and previous failure/scoring evidence stay intact.
The full collector's strict Clippy remains subject to the three pre-existing
warnings documented in revision 02; candidate Clippy passing does not erase them.

No private cases or million-element workloads ran here. All active sabotage
controls have not been rerun against this adapted candidate. Original obligations
and further execution/delivery approvals remain separate. There is no arbitrary
program summary promise, general OOM/deep-stack claim, commit, push, merge or
deployment. Both the replacement freeze and this adaptation are local only.
