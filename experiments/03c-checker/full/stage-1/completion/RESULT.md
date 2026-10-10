# Stage 1 complete — 10 October 2026

**All eight exact F1–F6/L1–L2 obligations pass the unchanged ProofGate against
the approved D191 amended model.** This supersedes earlier partial-progress
reports without changing them. No new model amendment or weakened statement
was needed. The original failed rank freeze remains a failure, with its
counterexample and historical evidence intact.

## What is proved

The closed exports `Full.Proofs.f1` through `f6`, `l1` and `l2` have exactly the
types in frozen `Full.Statements`. They establish reachable invariants,
progress and exact effects; two-way independent Plain correspondence and
decreasing administrative stuttering; live-value protection at every boundary;
the exact finished graph; budget/resumption laws; universal finite-Trial
compatibility including full ordered landmarks; transactional denial; and
terminating, outside-preserving, idempotent destruction.

The strengthened intermediate invariants are proved from actual initialization
and reachable transitions, not added as public assumptions. F6 uses structural
induction on every Trial expression constructor, including empty, unique and
shared match branches, complete cleanup, and finalization. It is not a fixture
enumeration or a theorem conditional on successful Full evaluation.

## Executed acceptance

| Check | Result |
| --- | --- |
| Cache-free `lake build Full Full.Proofs` | 153 jobs, exit 0 |
| Unchanged `ProofGate.lean` | All eight exact types, exit 0 |
| Complete transitive axiom sets | Only `propext`, `Classical.choice`, `Quot.sound`; L1 needs only the first and last |
| Clean `lake env leanchecker --fresh ProofGate` | Exit 0 |
| Every auxiliary proof module in clean tree | 155 build jobs, exit 0 |
| Different verifier's own gate/kernel audit | Eight exact targets; fresh kernel exit 0 |
| Proof rejection controls with passing baseline | Invalid term, placeholder and extra axiom: 3/3 rejected by elaboration or axiom policy |
| Unchanged fixture acceptance | 90 cases, 84 finished answer/ledger/graph checks |
| Expanded acceptance | 820 passed, 0 failed; 12/12 export corruptions rejected |
| Boundary/view acceptance | 4,498 internal equalities, 9,680 views; 3/3 corruptions rejected |
| Historical Trial comparison | All 28 answers, primitive events and complete ordered landmarks |
| Executed faulty logical routes | 21/21 rejected, all corresponding baselines pass |
| Frozen inventories | 6 amended seal, 237 amended preparation, 75 dependency, 2 original seal, 22 amended evidence entries pass |
| Proof-source inventory | All 81 files match working and clean checked sources |

Builds retain non-fatal linter warnings about unused arguments and simplification;
they contain no placeholder acceptance. Proof mutations are scratch controls,
not changes to the real proof sources. The kernel allows declared axioms;
the separate transitive-axiom policy correctly rejects the placeholder and
extra-axiom controls even though those candidates elaborate.

## Reproduction and exact bytes

Run `bash stage-1/completion/reproduce.sh` from this package after restoring the
historical gzip assets as documented in `experiments/GZ_ARCHIVE.md`. The script
reconstructs original rewritten freeze
[`f427d0f`](https://github.com/robertguss/mo-v2/commit/f427d0fe1a4badb9d1fd470e6e3ef83a06f2f6a5),
overlays only the approved Control from
[`ca4a020`](https://github.com/robertguss/mo-v2/commit/ca4a020a6c66ea54aead82c63662a9edb7220bf0),
and copies the permitted proof files. No `.lake` directory or old compiled proof
is copied. Both packages use pinned Lean 4.34.0. Frozen inventories and the proof
manifest are checked before and after. `PROOFS.sha256` identifies the exact 81
proof sources, including the unchanged sealed RankRegression.

The executed reconstruction is recorded in `evidence/clean-directory.txt`.
Two orchestration omissions were corrected, with no source/model repair:
the first default build omitted the separate proof target; the subsequent clean
proof build/kernel/finite checks passed but the Trial comparison needed its
separate `Checks` library built. Execution resumed in that same clean tree at
the added `lake -d ../../trial/lean build Checks` command and completed all
remaining checks. The reproduction script includes both prerequisites.

After the main script, all auxiliary sources were also built in that clean
`full/lean` directory:

```sh
mapfile -t modules < <(find Full/Proofs -name '*.lean' -printf '%p\n' |
  sed 's/\.lean$//; s@/@.@g' | sort)
lake build "${modules[@]}"
```

Logs and compact JSON reports are under `evidence/`. The regenerated raw export
has SHA-256 `d358ba51249cf260882eb437f1fbc9103260c0ef8f76849da2ed361a057ac78a`.
It was byte-compared to the decompressed D191 archived raw export, not merely
compared by summary. Therefore no duplicate large raw file or new gzip asset
is required: restore `gz-03c-checker-rank-amendment-01.tar` from the existing
`gz-evidence-archive` release. Its checksum remains in `GZ_ARCHIVE.sha256`.
The new input, summary and report files are retained; the full raw export can
also be regenerated by the script. `MANIFEST.sha256` inventories this additive
completion record, logs and reports; it does not replace an old freeze.

## Different verification and limits

`verifier/REVIEW.md` and `verifier/COMMANDS.md` record the different verifier's
direct source/contract inspection, 401-entry before/after audit, eight-target
type/axiom audit, fresh kernel execution, and proof rejection controls. Its
conditional verdict required the integrator's clean reconstruction and finite
suite to succeed; those checks have now succeeded as recorded above. This is
same-account procedural separation, not independent-account certification or a
line-by-line independent derivation of every helper.

This completes **slice 1, stage 1 only**. It proves the frozen mathematical
model, not a Rust/native refinement, physical-stack bound, physical unbounded
storage, or an algorithm deciding divergence. No demand checker, accept-all/
reject-all checker controls, conditional allocation guarantee, caller ownership
enforcement, merge or deployment is claimed. Those checker controls remain
inapplicable until the separately authorized checker exists.

The checkpoint belongs on `proofs/rob-1139-stage1`; delivery is recorded in
Linear and the working thread. ROB-1139 is not wholly Done: Robert's explicit
stage-2 go-ahead is required before conditional checker construction, and
caller enforcement remains a separate slice-2 gate. Stop here and show this
stage-1 result.
