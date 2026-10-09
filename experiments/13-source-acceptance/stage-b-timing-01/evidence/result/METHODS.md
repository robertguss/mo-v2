# Timing-01 full resource evidence

One owner-approved attempt used the committed timing-01 freeze. Sum ran under
1,800 seconds; only its completed pass allowed discard under 600 seconds. The
candidate, runtime, approved ownership verifier and decoder were unchanged.
No private corpus or evaluator sabotage control ran. No repair/retry followed.

`execute.sh` records the pre-run commit, exact command, start/stop, process cgroup,
environment limits and actual runner exit. A noclobber start marker rejects any
supervisor restart before a second workload launch. The supervisor tried to
restart after the successful exit; the marker rejected those attempts before
any workload could run again. The service is stopped and its journal preserved.
Sparse shell progress reads are disclosed
observer overhead; no separate sampler, build or packaging job ran in this orb
concurrently with either workload. Hosted Buildkite CI uses different machines.

The full runner rechecks exact identities before/after each run. The reports
include every semantic result and both reconciled timing ledgers. Native category
wall totals partition its measured interval; they overlap Python work and must
not be added to parent totals. Evaluation includes candidate callback metadata
generation, timer overhead and descheduling, not pure language evaluation CPU.
Transport includes blocked writes, not merely serialization CPU. See the frozen
methods for exact intervals, summary snapshots and timed finalization remainder.

The unchanged 42-GiB workload cap did not OOM. Native peak RSS is per child from
wait4. Python peak RSS is a process-lifetime high-water mark, so discard inherits
the earlier sum peak and it must not be presented as discard-only memory use.
Cgroup peak is lifetime usage including page cache and other earlier workloads,
not isolated native RSS or a universal resource bound.

After both workloads exited, `gzip -dc` checked each stream through EOF/CRC while
the preserved `inspect_tail.py` independently hashed every decoded byte, counted
newlines, rejected no content by selection, and retained only a bounded 256-KiB
tail. Both pipeline statuses must be zero. `postmortem.py` reconciles each digest
and count with the runner, checks no partial tail, verifies final drop/teardown
records, checks actual final elapsed against the amended envelope, reconciles
the timing ledgers and rechecks all frozen identities. This byte inspection is
not another full semantic replay; the semantic checks occurred in the timed run.

The public package uses the established packager's explicit allowlist and bounded
volumes. Every archive member is read back, every original is rehashed, and full
restore verifies every reconstructed file. Original files remain untouched.
Installed runtimes, build/cache files and private evidence are excluded. The
archive is preservation, not a new scientific result. Old failures stay intact.

Reproduce post-run inspection with a fresh output filename:

```sh
gzip -dc RESTORED/million/non-tail-sum/rows.jsonl.gz | PINNED_PYTHON RESTORED/inspect_tail.py > NEW-sum-inspection.json
printf '%s\n' "${PIPESTATUS[*]}"
gzip -dc RESTORED/million/discarded-list/rows.jsonl.gz | PINNED_PYTHON RESTORED/inspect_tail.py > NEW-discard-inspection.json
printf '%s\n' "${PIPESTATUS[*]}"
```

These are finite resource successes under the amended operational guards, not
passing results under the earlier 900-second sum contract. They do not establish
a universal memory, speed, safety or host-stack-independence theorem. Final
acceptance/integration review and PR-branch reconciliation remain separate from
this resource result. No merge or deployment is part of this attempt.
