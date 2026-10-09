# Approved resource attempt stopped on a confirmed OOM

The exact reviewed performance checker was frozen before execution. The 19-file
lock SHA256 is `1aca07ef93577513ebe507ec38df65470b7bc153a2c125b6cf5f3a72b25196ef`.
Original/revision-02 locks and candidate source remain unchanged. The two small
explicit-selection smoke runs completed and matched the previous verifier;
their small depths correctly fail the million-element resource-depth predicate.

Executed from `/home/user/workspace/repo`:

```sh
/home/user/.local/share/uv/python/cpython-3.14.7-linux-x86_64-gnu/bin/python3.14 experiments/13-source-acceptance/stage-b-performance-01/run_resources.py /home/user/rob1333-stage-b-performance-01/approved-01/million /home/user/rob1333-stage-b-performance-01/target/release/rob1333-stage-b-link > /home/user/rob1333-stage-b-performance-01/approved-01/million.log 2>&1
```

The shell tool returned exit 137. Kernel records at 2026-10-09 01:16:42 UTC
explicitly identify a memory-cgroup OOM and the killed native linked process,
then the whole execution group. The cgroup limit was 14,763,950,080 bytes
(13.75 GiB); native anonymous RSS was 12,747,092 KiB, Python anonymous RSS
1,382,084 KiB. The native process combines candidate, collector and runtime;
this evidence does not attribute allocations among them.

The kill prevented `summary.json` and `report.json` from being written. Do not
invent replacements: `POSTMORTEM.json` is explicitly a separate inspection
report. It does not claim a completed verdict, full deepest observation, cleanup,
or exact elapsed resource clock. The last retained driver clock is 607.8828899
seconds; it is not the kill time or a successful-run duration. Discard was not run.

The original unfinished gzip is preserved, not repaired. `inspect_partial.py`
streams it with bounded decompression and hashes all recoverable bytes. An
independent `gzip -dc` pipeline counted newlines and hashed the decoded bytes;
its expected exit 1 and unexpected-EOF stderr are retained. Both inspections
agree on 6,134,915,156 decoded bytes, 11,997,683 complete newline-terminated
records, and decoded SHA256
`b11c5c14611387b0ddb6d730d2e1659eb7ce09d308c2e36441aa04dc65ee0f82`.
There are 442 bytes of an incomplete trailing record and no gzip end marker.

The last complete retained row is commit 11,997,679, near but below the required
deepest step 12,000,005. Records are written before verification; this is not
proof that every last retained field completed checking. The required deepest
full observation and 18,000,014-transition completion are not established.
Snapshot construction near maximum depth is a hypothesis to investigate, not a
confirmed allocation source. No candidate was rerun or repaired after the kill.

Kernel evidence was read with `sudo dmesg --ctime`, filtered for the killed PIDs,
OOM lines and memory-cgroup limit. Effective cgroup files were read under
`/sys/fs/cgroup/amp.slice/amp-workload.slice/`; the root cgroup does not expose
`memory.max`. The existing provisioning check reported host available memory,
not this nested limit. The actual 13.75-GiB allocation still exceeds the frozen
four-GiB floor. No memory limit or resource criterion was changed.
