# Proposed collector: about 61% less native peak memory in bounded profiles

This is a separately named, **unfrozen implementation proposal**. The submitted
interpreter, frozen revision-02 collector, performance checker, original limits,
and prior evidence remain unchanged. No private cases or million-element runs
were executed. Neither resource obligation is satisfied; PR #9 is still draft.

## Preserve validation and equality without ordinary full-tree retention

`driver/` is copied from the frozen collector. The behavioral comparison is
against that original, not a newly invented criterion. `link/` uses the exact
existing adapted candidate and frozen cells/runtime, with this proposed driver.

* Full observations are still requested and transmitted byte-for-byte.
* A recursive `deserialize_any` visitor validates every snapshot value, retaining
  only the step/status header and original bytes. It does **not** use
  `IgnoredAny`, whose skip parser bypasses overflow, Unicode and depth checks.
* Once validated, identical bytes establish equality without building trees.
  Different bytes fall back to the original `serde_json::Value` comparison.
  Reordered keys, equivalent escapes/floats, duplicate-key behavior and the
  integer/float distinction therefore retain the original semantics.
* The collector moves its already-owned raw/graph values into the output row
  instead of serializing borrowed values into duplicate trees with `json!`.

**Tradeoff:** differently spelled snapshots still incur full-tree comparison on
zero-work/terminal equality checks. This deliberately retains the original
comparison rather than introducing a second canonicalizer or hash-based rule.
Pathological step/status values can also materialize trees. The improvement is
measured for this actual evaluator, not an all-input memory bound.

The lock changes only the driver's direct dependency edge to the already-pinned
serde crate. All registry versions/checksums remain identical. serde_json 1.0.151
has exactly `default,std` enabled; changing features needs a new review.

## Bounded validation passes; full resource acceptance is not claimed

| Public sum elements | Frozen collector peak RSS | Proposed peak RSS | Reduction |
| ---: | ---: | ---: | ---: |
| 10,003 | 211.5 MiB | 81.9 MiB | 61.3% |
| 20,003 | 420.3 MiB | 161.4 MiB | 61.6% |
| 40,003 | 828.4 MiB | 320.8 MiB | 61.3% |

The old measurements use the retained diagnostic build; its 20,003-element
measurement was also checked against the exact uninstrumented binary (430,368
versus 430,236 KiB). The proposal runs are uninstrumented. Every scaled run
finishes its frozen semantic checks, deepest observation, resume and cleanup.
The resource-depth predicate correctly rejects them as **not** full acceptance.
All **1,260,234 rows** match after removing only elapsed clocks and process-local
pointer addresses; each complete stream independently passes the frozen semantic
verifier. No timing or million-element extrapolation is an acceptance result.

The unchanged public validation runner passes **21 examples, 1,624 resumes,
1,624 destruction runs, 42 allocation-denial checks, 4,276 historical cases, and
four real summary-mode runs**. This is 7,591 native runs, plus three profiles.

The same scripted protocol probe was compiled against both collectors;
`check_protocol.py` compares their output. All **2,548 probes** match complete emitted rows and exact errors:
240 accepted, 2,308 rejected. They exercise malformed JSON/UTF-8, numeric overflow,
surrogates, recursion boundaries, duplicate/unknown fields, semantic equality,
step/status mismatches, budgets and callback metadata. These are **synthetic
collector tests, not real evaluator sabotage controls**.

Rust 1.98.1 release locked/offline builds, four collector tests (three existing
plus one public-interface regression), and formatting pass. **Strict Clippy
fails on the same three pre-existing lints in both versions**: type complexity
and two collapsible conditionals. They were not suppressed or cleaned up here.

`verify.py` rechecks the executed source/binary identities, unchanged dependency
versions/features, all 967 original frozen files, five historical dependencies,
41 revision-02 files, and the 19-file performance freeze. No expected answer,
verdict, snapshot requirement, clock or allocation policy changed.

## Reproduce and review before adoption

External originals: `/home/user/rob1333-stage-b-collector-01/`. Reports in
`evidence/` and the lossless public package preserve source copies, commands,
build/test logs, requests, complete outputs, failures and identity records.
Build caches and executables are excluded from the archive, not evidence.
The preceding diagnosis is retained separately in `../stage-b-memory-01/`.

The package preserves **30,416 originals** in 147 independent volumes totaling
**115,522,457 compressed bytes**. Archive read-back and complete restored-content
verification pass. Final index SHA256:
`70ab14fd34f6b1007de59395f563d90214fef6a8a3affacbc7444509b549dfb9`.
The temporary restore and hardlink view were removed; originals remain intact.

Owner-requested disk cleanup removed 2.95 GiB of inactive Cargo caches, retaining
and hash-verifying 153 non-cache files/executables. Sources, frozen files, evidence
and private data were not deleted. The cleanup inventory is in the archive.

From `experiments/13-source-acceptance`:

```sh
CARGO_TARGET_DIR=/home/user/rob1333-stage-b-collector-01/target cargo +1.98.1 build --release --locked --offline --manifest-path stage-b-collector-01/link/Cargo.toml
CARGO_TARGET_DIR=/home/user/rob1333-stage-b-collector-01/target cargo +1.98.1 test --release --locked --offline --all-targets --manifest-path stage-b-collector-01/driver/Cargo.toml
python3.14 stage-b-collector-01/profile.py /home/user/NEW-profiles /home/user/rob1333-stage-b-collector-01/target/release/rob1333-stage-b-link
python3.14 stage-b-adaptation-01/validate_public.py /home/user/NEW-public /home/user/rob1333-stage-b-collector-01/target/release/rob1333-stage-b-link
python3.14 stage-b-collector-01/verify.py /home/user/rob1333-stage-b-collector-01
python3 stage-b-adaptation-01/package_continuation.py --restore stage-b-collector-01/evidence/public /home/user/NEW-collector-restored
```

The selected Python executable was
`/home/user/.local/share/uv/python/cpython-3.14.7-linux-x86_64-gnu/bin/python3.14`.
Baseline probe compilation uses retained `baseline-probe/Cargo.toml` to compile
the new probe against the unchanged frozen driver's `lib.rs`. The proposed probe
is `cargo build --release --locked --offline --example protocol_probe` with the
new driver manifest. `check_protocol.py OLD_PROBE NEW_PROBE NEW_DIRECTORY`
reproduces the differential tests. Use separate Cargo targets for the two builds.

Review and approval of this replacement precede any new freeze or full-size
retry. Full resource timing/memory, private reruns and real evaluator control
reruns were not performed for this proposal. No merge or deployment occurred.
