# Second full-depth attempt: verifier OOM, no completed verdict

This postmortem concerns the approved collector run in the source orb, not the
new larger-orb attempt. The unchanged collector freeze is
`ebe29d7c59d03a3b8d9467c62640212bde8d4fc41ce0cff970e13827ad90ecd5`.
The original request, incomplete gzip, preflight, smoke records, memory samples,
kernel log and first inspection remain byte-identical under `originals/`.

The source shell returned exit 137. At 2026-10-09T12:23:46.802 UTC the kernel
reported the 14,763,950,080-byte (13.75-GiB) workload cgroup exhausted and selected
the CPython verifier for killing. Verifier anonymous RSS was 7,328,164 KiB;
native linked anonymous RSS was 6,889,832 KiB. The whole execution scope was
killed. Native RSS includes candidate, collector and runtime; this log does not
isolate allocation ownership.

**Observer effect:** an external sampling Python process invoked the allocation
that triggered the OOM. The verifier was the selected victim, not the invoking
process. This does not establish that an unmonitored run would fail at precisely
the same point. No candidate repair, checker change or discard execution
followed this failure.

The original 640,032,858-byte gzip has SHA256
`7ca4f8f79c0c60e27848b8c6c0e7ace98e1ddd91dafec23eda45242f17c2683b`.
The source inspection uses bounded zlib decompression and caps its retained
record tail at two MiB. In this orb an independent GNU gzip decompressor feeds
a separate 256-KiB streaming byte counter/hash implementation. Both agree on
7,114,414,775 recovered decoded bytes, 12,000,009 complete newline-terminated
records and decoded SHA256
`8d315a7ad530520cce4aacdddced1b73ae1700d268f8e6dd11b05e3d98b9e366`.
The independent counter measures **978,398,346 trailing partial-record bytes**;
this refines, rather than contradicts, the source's “over-2-MiB” bound. GNU gzip
exits 1 with unexpected EOF; the counter exits 0. No trailer was reconstructed.

The last complete retained row is commit step 12,000,005, the deepest boundary;
the incomplete following observation is not a completed deepest observation.
Retention happens before verification. No claim is made that the last retained
row finished checking. Driver clock 570,223,188,952 ns is neither the kill time
nor a passing runtime. There is no completed deepest observation, completion,
cleanup, final verifier verdict or discard execution. Missing runner summary
and report files were not fabricated; `POSTMORTEM.json` is separate analysis.

Reproduce the independent read from repository root, retaining PIPESTATUS:

```sh
gzip -dc /home/user/rob1333-stage-b-second-oom-01/originals/million/non-tail-sum/rows.jsonl.gz 2> NEW_STDERR | python3 experiments/13-source-acceptance/stage-b-resource-continuation-01/inspect_stream.py > NEW_REPORT
printf '%s\n' "${PIPESTATUS[*]}"
```

The inspector was probed on empty input, asymmetric complete/partial lines and
a partial line spanning several chunks. It does not parse records, evaluate a
candidate or semantically replay evidence. This is independent implementation
of a byte inspection by the same continuation agent, not an independent human
or agent acceptance review.

The frozen runner's `verify()` rechecks the exact Python and both native binary
fingerprints, the collector/performance locks, 967 original files, five
historical dependencies and 41 revision-02 files, plus unchanged candidate.
The postmortem records its equality with the retained preflight identity.
Transfer-tar comparison and complete file hashes recheck original preservation.
The established public packager splits large files losslessly by offset into
under-20-MiB volumes, hashes all members and sources, reads all archives back,
and restores every source file for complete hash verification. Private data,
build caches, installed runtimes and native binaries are not included.
