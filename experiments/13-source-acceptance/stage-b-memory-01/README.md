# Memory diagnosis — collector snapshot expansion, not resource acceptance

Robert authorized isolating native memory growth after the confirmed OOM. This
investigation changes no submitted candidate, frozen file, criterion or earlier
evidence. It runs no private cases and no million-element workload. PR #9 remains
blocked; neither full resource obligation has passed.

## The collector materializes and retains a large decoded snapshot

Three bounded public sum runs show the same scaling:

| Elements | Live allocations before deepest observation | Additional decoded snapshot tree | Native peak RSS over full run |
| ---: | ---: | ---: | ---: |
| 10,003 | 52.4 MiB | 75.1 MiB | 211.5 MiB |
| 20,003 | 104.6 MiB | 150.1 MiB | 420.3 MiB |
| 40,003 | 209.2 MiB | 300.2 MiB | 828.4 MiB |

`stage-b-revision-02/driver/lib.rs`, `Collector::boundary`, calls
`C::observe(Full)` and then `decode(&bytes)`. The second call constructs a complete
owned `serde_json::Value` tree while the candidate state and serialized snapshot
still exist. The allocator delta across that call is exactly **78,715,785;
157,404,377; and 314,781,561 bytes** in the three runs. At 40,003 elements, snapshot
bytes add another 32 MiB before decoding. Graph/row construction adds further
temporary allocations.

`collect` assigns the decoded result to `prior` and retains it across the next
`advance`. On completion it constructs `after` before dropping the deepest
`prior`, increasing the peak again. This tree is used for status/step checks and
semantic equality on zero-work/terminal advances; it is not the candidate's
execution stack. The Python verifier separately checks the full transmitted
snapshot. Complete snapshots and those equality checks remain required.

These measurements isolate a substantial **collector-owned memory multiplier**.
The decoded-tree growth is approximately linear over the measured range; simple
extrapolation would put that tree alone around 7.3 GiB at a million elements,
before candidate/native-store retention, snapshot bytes, allocator overhead,
and Python. This is consistent with the original 13.75-GiB cgroup OOM, not proof
of its exact failing instruction or a successful million-element prediction.
Candidate and native-store/log allocations remain grouped in the pre-observation
number. This investigation does not establish a candidate memory leak.

## Instrumentation is separate and cross-checked

The source copy is outside the checkout at
`/home/user/rob1333-stage-b-memory-01/source/`. Only its driver differs: a counting
wrapper forwards to the same Rust `System` allocator and reports requested live
bytes, interval peaks, and `/proc/self/status` RSS at named boundaries. It adds
no allocation headers or retained trace buffers. Candidate, runtime, cells and
link source copies are byte-identical to their originals. `driver.patch` and
`memory_probe.rs` preserve the complete diagnostic change.

Allocation totals exclude allocator metadata, fragmentation, stacks and Python.
`realloc` accounting records final requested capacity, not transient overlap
inside the allocator. RSS can remain high after allocations are freed. Python
max RSS is cumulative within the profiling process, not isolated by run.
Diagnostic caps (4 GiB native address space, 180 native CPU seconds, and a
6-GiB cgroup-headroom preflight) are safety guards, not acceptance-limit changes.

Rust 1.98.1 built with `--release --locked --offline`. The copied collector's
three existing tests pass. The three instrumented runs and a separate exact
baseline binary run at 20,003 elements each complete the frozen semantic checks,
deepest full observation, both advances, and both destruction calls. They cover
1,620,272 committed transitions in total. The resource predicate intentionally
rejects every scaled run with `resource completion/depth`; none is counted as
passing full resource acceptance.

`analyze.py` compares **360,078 complete rows** at 20,003 elements: phase, step,
raw candidate bytes, cursor ranges, resource/create attempts and outside roots
match exactly. Clock fields and physical pointer-bearing graph/event fields are
excluded from cross-process byte comparison; both entire streams independently
pass the frozen semantic verifier. Native peak RSS is 430,368 KiB instrumented
versus 430,236 KiB baseline. Instrumented timing is not a resource verdict.

Preservation checks before and after every run verify all 967 original frozen
files, five historical dependencies, 41 revision-02 files, the 19-file performance
freeze and the original candidate/binary. Original failed evidence is untouched.

## Reproduction and proposed next change

The public evidence package includes exact source copies, locked manifests,
build/test logs, scripts, requests, complete compressed rows, allocation markers,
summaries and analysis. Targets/caches are omitted. Its `INDEX.json` provides
source and member hashes; full read-back and restored-content verification pass.
The package preserves 54 original files as 58 members in eight independent
volumes totaling **64,939,060 compressed bytes**. Index SHA256:
`829b4d9072fef02cad45803e956a0db83282f94c972c4e58f8bc256bc804ade8`.
Restore into a new directory from `experiments/13-source-acceptance`:

```sh
python3 stage-b-adaptation-01/package_continuation.py --restore stage-b-memory-01/evidence/public /home/user/NEW-memory-restored
```

Retained executed commands (scripts use the original absolute paths):

```sh
CARGO_TARGET_DIR=/home/user/rob1333-stage-b-memory-01/target cargo +1.98.1 build --release --locked --offline --manifest-path /home/user/rob1333-stage-b-memory-01/source/stage-b-adaptation-01/link/Cargo.toml
/home/user/.local/share/uv/python/cpython-3.14.7-linux-x86_64-gnu/bin/python3.14 /home/user/rob1333-stage-b-memory-01/profile.py
/home/user/.local/share/uv/python/cpython-3.14.7-linux-x86_64-gnu/bin/python3.14 /home/user/rob1333-stage-b-memory-01/analyze.py
CARGO_TARGET_DIR=/home/user/rob1333-stage-b-memory-01/target cargo +1.98.1 test --release --locked --offline --manifest-path /home/user/rob1333-stage-b-memory-01/source/stage-b-revision-02/driver/Cargo.toml
```

The next implementation target is a separately reviewable collector that avoids
full owned-tree expansion/retention while preserving full output, step/status
checks, zero-work/terminal semantic equality, malformed-output detection and
every existing verdict. Graph/row copies are secondary targets. No replacement
collector, new freeze or full-size retry has been made in this investigation.
