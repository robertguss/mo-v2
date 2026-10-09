# Verifier optimization proposal — resource acceptance still blocked

This is a performance investigation and reviewable implementation proposal,
**not a new scientific freeze or passing Stage B resource result**. Original
submissions, the failed 900-second attempt and all frozen files are unchanged.
No private corpus was accessed in this investigation. PR #9 stays draft.

## The scaled bottleneck is predominantly verification

The unchanged candidate and frozen collector were built with Rust 1.98.1,
`--release --locked --offline`. All 54 candidate tests and three collector
tests pass. All seven candidate-manifest entries verify. The release binary
fingerprint and source identities are in `evidence/IDENTITY.json`.

The orchestration's repeated concatenation and scanning of incomplete JSON
records is quadratic in a large record's length. `run_approved_large.py` now
uses buffered line reads. The same inclusive SIGALRM covers blocked reads,
verification, evidence writes, process exit and stream closure. Every complete
record is retained and checked, and unterminated final records are rejected.
Alternate builds require an explicit binary SHA256; the old debug hash remains
the default. The executed original runner remains in sealed prior evidence.

With CPython 3.14.7 and the release binary, the public 20,003-element sum
completed all 360,068 transitions, including deepest pause, resume and cleanup:

| Measurement | Seconds |
| --- | ---: |
| Native run, old reader and frozen verifier | 28.329 |
| Native run, buffered reader and frozen verifier | 27.193 |
| Retained-stream replay, frozen verifier, no candidate | 26.506 |
| Independent repeat of that frozen replay | 25.473 |
| Same replay with the proposed helpers | 16.745 |

The last result is a 34–37% verifier-replay improvement, **not a measured
million-element speedup**. It does not establish a 900-second pass; large
boundary observations and memory behavior remain unmeasured at full depth.
PyPy 3.11.15 and CPython's experimental JIT did not improve the tested replays
and were not adopted. No global Python default was changed.

## The proposal changes JSON mechanics, not expected answers

`stage_b_large.py` is a separately named copy of the frozen revision-02 module.
Only its header, JSON helper imports and digest encoder call differ. The frozen
copy remains the comparison oracle. `fast_json.py`:

* Compares plain primitives/lists without serializing them, retaining exact
  type distinctions; other shapes and floats use the original canonical JSON
  comparison, including the distinction between positive and negative zero.
* Reuses a decoder while retaining duplicate-key and non-JSON-number rejection,
  the standard byte-encoding detection, and the original BOM/error behavior.
* Caches only field-name sets, with a bounded cache, not observations or expected
  values; every row still checks its complete field set.
* Reuses the same configured JSON encoder for byte-identical digest input.

No schedule, expected value, ownership predicate, observation requirement,
retention bound, stack limit, transition cap or 900/600-second limit changes.
The helper's equality fast path targets the decoded JSON and fixed-shape
predictions used by this verifier, not arbitrary Python objects or cycles.

## Validation is bounded and reproducible

`check_equivalence.py` passes under CPython 3.11.6 and 3.14.7: 11,728 equality
comparisons, 20,090 parsing comparisons, 42 field-set comparisons and 5,000
digest comparisons. These include Boolean/integer and signed-zero distinctions,
malformed input, duplicate keys, Unicode/encoding boundaries and reuse following
a decoder error. Counts are differential checks, not independent language cases.

`check_replays.py` matches every reply and complete verdict on **895 retained
native streams**: 891 small lifecycle streams and four real summary streams.
Opaque identity relabeling also passes. All 15 rejection probes match the first
rejected row, exception type and message: the existing birth/call/prefix and
summary corruptions, plus JSON/type probes for these fast paths. Synthetic
corruptions are checker tests, **not compiled evaluator controls**. No new
candidate cases or private execution are claimed by this replay.

The framing comparison separately executed both readers for 360,068 sum and
20,009 discard transitions, replayed and hashed every row, and matched their
complete frozen verdicts. Both appropriately failed the resource-depth predicate
at these scaled depths. Synthetic EOF and blocked-read probes verify framing and
SIGALRM interruption only; their generic raw runner flags do not turn them into
native candidate evidence. See `evidence/framing.json` and archived `METHODS.md`.

From `experiments/13-source-acceptance`:

```sh
python3 stage-b-performance-01/check_equivalence.py
python3 stage-b-performance-01/check_replays.py /home/user/rob1333-stage-b-adaptation-checks /tmp/NEW-replay-report.json
```

The second command requires the retained public evidence (or its fully restored
equivalent). Neither command starts a candidate or changes frozen inputs.

## Evidence is preserved; adoption is a separate gate

The package in `evidence/public/` preserves 66 original public files, represented
by 68 members across five independent volumes, totaling **32,269,096 bytes**.
Largest volume: 12,284,199 bytes. Read-back, full restore and original-content
hash verification pass; there are no omitted links. Build/cache directories are
excluded. Private directories are not traversed. The index SHA256 is
`ad0bd8db76f750376770c3aae208265d611023ac4386f80dc936cfc38be26bc2`.

```sh
python3 stage-b-adaptation-01/package_continuation.py --restore stage-b-performance-01/evidence/public /home/user/NEW-performance-restored
```

The originals remain outside the checkout. Hashes reverify all 967 original
frozen files, five historical dependencies and 41 revision-02 files. The candidate
is unchanged. Investigation and preparation took approximately 40 minutes of
elapsed agent work, including compilation, benchmarks, checks and preservation;
this is not an acceptance execution-time claim.

**Remaining gate:** review/approve this separately versioned checker
implementation before freezing or using it for acceptance. Then run both full
resource obligations with the unchanged limits and review the complete result
before merging PR #9. No million-element run, new freeze, new acceptance claim
or merge follows from this proposal.
