# Larger-orb Stage B continuation: resource gate still fails

**Stopped on the first material failure.** The unchanged million-element
non-tail sum timed out at **900.001081354 seconds** in the owner-authorized
42-GiB workload cgroup. The runner reported `passed: false` and
`TimeoutError: inclusive watchdog`, with step counter 12,000,005 of the required
18,000,014 transitions. No cgroup OOM event occurred. **Discard was not run.**
There was no candidate/checker repair or retry. Both resource obligations and
final acceptance/merge review remain unsatisfied; PR #9 remains open/draft.

The actual failure report exists for this attempt. Its counters advance before
all predicates on the corresponding row finish, so the final reached step and
retained full record do not establish completed deepest-observation verification.
Completion, cleanup and a passing resource verdict are not established.

## Exact handoff and a separately recorded environment change

The continuation checked out the exact source branch at
[`7037f90`](https://github.com/robertguss/mo-v2/commit/7037f90dbac3b9d7cc5e1f41b52942228d07251e),
not `origin/main`. Robert's larger-orb instruction, measured environment and
second-OOM postmortem were committed before execution in
[`6fa5adb`](https://github.com/robertguss/mo-v2/commit/6fa5adb).
See [authorization](AUTHORIZATION.md) and
[pre-run environment](evidence/large-orb/environment-before.json).

This `a1.3xlarge` orb provides a measured **42-GiB workload cgroup**, about 43 GiB
physical RAM and a 64-GiB filesystem, with 52,826,554,368 disk bytes free at runner
preflight. No local cgroup or swap controls were changed. The old freeze's
statement that its memory limit was not raised remains correct and unchanged.
The later owner-authorized environment change is recorded separately, not
retroactively applied to earlier attempts.

Both transfer archives were hash-verified and member paths inspected before
restoration. The 615-MiB failed-attempt tar exceeded the transfer tool's 100-MiB
read limit; ten checked parts reassembled to its exact original hash. Both tar
comparisons passed. The pinned CPython installation and both release binaries
were restored without rebuilding or overwriting different installed files.
All three executable SHA256s and the collector's transitive integrity checks
match. The 35-GiB private corpus/evidence was not transferred or rerun. The
transfer tar itself is transport, not a new experimental result.

## Preserve the second OOM without claiming a completed observation

The earlier approved-collector attempt stopped at 2026-10-09T12:23:46.802 UTC,
exit 137, under a **13.75-GiB** workload cap. The verifier had 7,328,164 KiB
anonymous RSS and the native linked process 6,889,832 KiB. An external sampling
Python process invoked the allocation that triggered OOM; the kernel selected
the verifier and killed the whole execution scope. This observer effect does
not prove an unmonitored run would fail at precisely that point.

The original incomplete gzip remains intact. Two bounded inspections agree on
7,114,414,775 decoded bytes, 12,000,009 complete records and their decoded hash.
The new independent counter measures 978,398,346 trailing partial-record bytes,
refining the old inspector's “over-2-MiB” report. Gzip EOF is absent. Last
retained commit is 12,000,005; retention precedes verification. The last driver
clock, 570,223,188,952 ns, is neither kill time nor a passing runtime. No completed
deepest observation, completion, cleanup, final verifier verdict or discard run
is established. See [postmortem methods](evidence/second-oom/METHODS.md) and
[postmortem record](evidence/second-oom/POSTMORTEM.json).

The first native-process OOM remains in
[the earlier report](../stage-b-performance-01/evidence/approved-01/METHODS.md),
and the initial debug-build timeout remains in
[the adaptation report](../stage-b-adaptation-01/README.md). None is erased.

## The new run timed out without reproducing the OOM

The [new summary](evidence/large-orb/summary.json) reports verifier peak RSS
11,873,660 KiB (about 11.32 GiB). The parent workload cgroup's lifetime peak was
29,971,828,736 bytes (about 27.91 GiB), including cache and other processes;
it is not isolated native/verifier RSS. Native peak RSS is unavailable on this
exceptional exit path. Cgroup `max`, `oom`, `oom_kill` and `oom_group_kill` all
remained zero. No universal memory bound or completed-run memory result follows.

The valid gzip holds 7,114,261,414 decoded bytes and 12,000,010 complete records,
with no partial tail. Independent GNU gzip inspection matches the runner's
streamed digest exactly. All records remain retained; none is sampled away.
The timeout does not isolate candidate execution from collection, verification
and evidence-write cost. No new profiling campaign or semantic replay was run.
See [exact methods and limitations](evidence/large-orb/METHODS.md),
[actual runner report](evidence/large-orb/report.json) and
[preservation recheck](evidence/large-orb/preservation.json).

## Reproduce byte inspection and restore public evidence

Both packages use the existing public evidence format: lossless offset chunks,
independent under-20-MiB volumes, archive readback and full restored-file hashes.
They exclude private data, installed runtimes and build/cache files. Originals
remain outside the repository; no incomplete scientific record is repaired.

| Package | Original files | Volumes | Compressed bytes | Restore |
| --- | ---: | ---: | ---: | --- |
| Second OOM, including separate postmortem | 27 | 40 | 448,249,725 | All source hashes match |
| Larger-orb timeout | 22 | 40 | 447,286,604 | All source hashes match |

The second-OOM index SHA256 is
`58f0628a2a5a90356432f10e5041a011be56e96e69151d1eff5eff81c27cb3a4`;
the larger-orb index is
`3e2e57746755f49a7f8bf9bf7875ac5c1fbb5a159df70a8a3d851761d5128800`.
The 49 files include 22 transferred originals and five new postmortem files,
plus 22 larger-orb evidence files. The runtime/transport archives are excluded.

From `experiments/13-source-acceptance`:

```sh
python3 stage-b-adaptation-01/package_continuation.py --restore stage-b-resource-continuation-01/evidence/second-oom/public /home/user/NEW-second-oom-restored
python3 stage-b-adaptation-01/package_continuation.py --restore stage-b-resource-continuation-01/evidence/large-orb/public /home/user/NEW-large-orb-restored
```

From the repository root, inspect a retained gzip without executing a candidate:

```sh
gzip -dc ORIGINAL_ROWS.gz 2> NEW_STDERR | python3 experiments/13-source-acceptance/stage-b-resource-continuation-01/inspect_stream.py > NEW_REPORT
printf '%s\n' "${PIPESTATUS[*]}"
```

Expected gzip status is 1 for the second OOM's truncated stream and 0 for the
larger-orb timeout's closed stream. The byte inspector exits 0 in both cases;
its success alone must not be reported as valid gzip or semantic acceptance.
`PRE_RUN.sha256` seals the pre-execution checkpoint without rewriting it.

No private cases, evaluator controls, candidate changes, new scientific lock,
time-limit change, merge or deployment followed the move. Both orbs remain
unarchived. Further work must investigate the remaining resource bottleneck
without weakening the frozen checks; no passing Stage B acceptance is claimed.
