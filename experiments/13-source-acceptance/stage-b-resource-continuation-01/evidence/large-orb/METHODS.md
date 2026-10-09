# Larger-orb attempt: timeout at the unchanged inclusive limit

The owner-authorized `a1.3xlarge` continuation used the same pinned CPython
3.14.7, JIT disabled, approved collector release binary and frozen resource
runner. No build or scientific code change preceded the retry. The separate
authorization, environment and second-OOM postmortem were committed before
execution. `command.txt` and `pre-run-commit.txt` retain the exact invocation
and pre-run commit. All paths in these records refer to the continuation orb.

The actual workload cgroup limit is 45,097,156,608 bytes (42 GiB); physical RAM
is 45,217,936 KiB. The filesystem has 68,297,543,680 bytes total, with
52,826,554,368 free at runner preflight. The native child retains the frozen
eight-MiB stack. The same four-GiB provisioning floor, full observations,
every-record checks, source checks, evidence writes, cleanup and process exit
requirements remain. Memory capacity changed by owner authorization; the
900-second sum and 600-second discard clocks did not.

The million-element non-tail sum returned `passed: false`,
`TimeoutError: inclusive watchdog`, at **900.001081354 seconds**. The shell
returned 1. Unlike the old OOM, this runner wrote both `summary.json` and
`report.json`; they are the actual failed-run reports, not postmortem substitutes.
They record 12,000,010 processed phase entries and `checked_steps: 12000005`.
These counters advance before all corresponding predicates finish. They are
not proof of completed verification of the final record. Required completion
is 18,000,014 transitions. Successful deepest full-observation verification,
completion, cleanup and a passing resource result are not established.
Discard was never launched; there is no discard directory. Execution stopped
on this failure and no candidate/checker repair or retry followed.

Verifier peak RSS reported by the runner is 11,873,660 KiB (about 11.32 GiB).
No native peak RSS is reported on the exceptional exit path; do not substitute
the parent cgroup peak. The parent workload cgroup's lifetime peak after the
run is 29,971,828,736 bytes (about 27.91 GiB), including page cache and other
workload processes. That is not isolated candidate or verifier memory.
`memory.events` has zero `max`, `oom`, `oom_kill` and `oom_group_kill` both before
and after. This attempt stopped for timeout, not observed cgroup OOM. It did
not reproduce the prior OOM in the larger environment; it did not satisfy
resource acceptance or establish a universal memory bound.

No separate Python sampler ran during the attempt. A few shell reads of time,
file size, the log and cgroup counters were made for progress reporting. No
packaging, builds, Git pushes or heavyweight validation ran concurrently. This
does not claim zero observer overhead. The old attempt's sampler-triggered OOM
remains documented separately and is not reinterpreted by the new result.

The retained stream has a valid gzip EOF and no partial trailing record.
Independent `gzip -dc` plus `inspect_stream.py` both exit 0 and count
7,114,261,414 decoded bytes and 12,000,010 newline-terminated records. Decoded
SHA256 `01583dc882fb930d9b6966217499011eee8b4a7e96e60ce951c9937f12350102`
matches the runner's streamed-row digest exactly. Byte completeness is not
semantic completion: output is retained before checking. No semantic replay
or new candidate execution is part of this inspection.

`environment-after.txt` retains post-run cgroup counters and disk availability.
`kernel-during-run.txt` is the unfiltered kernel-log window from shell launch
through the post-run capture (including about 25 seconds after shell exit).
It contains repeated clock-pairing hypercall messages, with no OOM message;
no causal claim about those messages is made. The accepted/rejected clock is
the unchanged runner's monotonic watchdog, not the wall-clock timestamps.

All frozen identities are verified before/after the attempt and once more in
the preservation report. Public packaging uses the existing lossless chunked
format, complete archive readback and full restore/hash comparison. Originals
remain external. No private corpus, installed runtime or build binary is
published. Both resource obligations and final acceptance/merge review remain
unsatisfied. PR #9 remains open/draft, not merged or deployed.
