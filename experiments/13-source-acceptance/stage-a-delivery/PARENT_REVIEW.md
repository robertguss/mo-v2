# Final-08 parent review

The reviewed final-08 submission passes the applicable frozen Stage A checks.
No blocking finding remains in this bounded review. This is not a proof for all
programs, Stage B authorization, merge approval or a resource/scaling result.

The separate builder authored the implementation. The separate acceptance author
ran the complete campaign. The parent inspected the source/routing review,
schedule reconstruction/reconciliation and compiled control mutations, checked
retained raw control evidence, and performed the fresh checks below. The parent
did not rerun the complete lifecycle campaign or retrieve private inputs.

## Identity and preservation

- Submitted archive: final-08, 36,392 bytes, SHA256
  `f79ea749d7a0ed2b7b1d94bd9daf1ebc6997845a1d2d3dcd4726128eb64f2eb8`.
- Candidate manifest: `943d259f1b81aaf3b572d032499ca3019676d5b459ed0eed0b4b51d628b0cd8b`;
  all seven content hashes verified; the eighth submitted file is the manifest.
- Frozen lock: `09c64493ba65f94451dc17c5bde7c4b54554d6990b23b8c877f2f9741f120c9e`;
  all 496 files and five historical dependencies independently checked.
- Reviewer control archive: `492f13896aefd16b30c743e4daed4b327db56b3ddfe62e7250826aea09aa0f1f`;
  all 219 regular members checked against the separately supplied exact inventory.

## Fresh parent checks

The parent extracted the frozen acceptance revision into a disposable directory,
extracted the exact submitted candidate beside the frozen runtime, and copied the
acceptance author's three native-link crate files without changing their content.
Rust 1.98.1 built the native link with `--locked --offline`. The initial offline
attempt lacked six locked registry crates; `cargo fetch --locked` fetched those
exact versions, after which the offline build succeeded. No lockfile was changed.

`cargo +1.98.1 test --locked --offline --manifest-path candidate/Cargo.toml`
passed all 41 builder-owned development tests. This is separate from acceptance.
The captured build/test command files are later cached build and test checks;
the first clean compilation is recorded in the parent thread.

`python3 spotcheck.py` passed 25 fresh native-linked checks: historical indices
0, 4, 12, 13, 25 and 4275 each ran uninterrupted, with resume, with nonterminal
destruction and with a first Frame denial; the retained phase-14 diagnostic also
passed. These repeat existing inputs through unchanged frozen predicates. Exact
requests, rows, summaries and stderr are retained in `parent-evidence/`.

After a fresh control build, `python3 controlcheck.py` ran the separate
acceptance-owned copy with all 21 mutations disabled/enabled. All 21 baselines passed and
all 21 intended rejections reproduced. The entire independently inspected
predicate-evidence JSON reproduced byte-equivalent parsed content. The two
abnormal-process wrappers correspond to specific frozen Rust guards, not generic
crashes. The double-free variant actually called native free twice; the second
call returned UnknownCell rather than deallocating twice, and its duplicate
cleanup report was rejected by the logical/native and destruction predicates.
Exact requests and output are retained in `parent-controls/`.

Parent native binary SHA256:
`f9d7eefc629a089cdf34fd0d6ccc77052f19a66b701c3043db5c943e7e10aff7`.
Parent control binary SHA256:
`68edc17ec0d9abd5c36e31e9d67734e139013c3e0a7688c8611f24a55ab74a2b`.
Different build paths produce different binaries from the acceptance orb; these
are fresh builds of the checked sources/locks, not a claim of identical binaries.

The review scripts record the exact disposable paths used. Their inputs are the
frozen checkout and reviewer-only archive, not builder-deliverable material.
No accepting predicate, prediction or submitted source was edited. This review
has no separate measured effort total; do not invent one from transcript gaps.

## Boundaries retained

The full campaign's counts belong to the acceptance author, not these spot checks.
Private coverage consists only of 524 Stage A capability refusals, not execution.
Observed frontend/execution denial schedules do not cover denial during
destruction, arbitrary allocator failure or host-stack exhaustion. Initial
bookkeeping is not reclassified under a new all-host allocation rule. Ten exact
Stage B controls, sixteen Stage B semantic expectations, private execution and
streaming/resource workloads remain deferred. Earlier public-wording precision
limitations and original failed attempts remain part of the record.

At review completion, delivery packaging is in progress. No merge, Stage B work,
deployment or builder delivery of acceptance evidence is authorized by this file.
