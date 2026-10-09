# Ownership lookup proposal: remove a quadratic reservation search

**Implemented and validated as a separate proposal, not adopted for acceptance.**
Robert asked to work on the recommended next step after the larger-orb timeout.
This investigation executes no candidate, private case, evaluator control or
million-element workload. The old freezes and failed attempts remain unchanged;
PR #9 stays draft. Approval of this exact checker substitution and a new freeze
must precede acceptance use, as with the prior performance-checker replacement.

## A required full-observation check searches the same list repeatedly

`stage-b-performance-01/stage_b_large.py::check_full` calls the original
`predicates.state_ownership`. After checking duplicate reservations, that
predicate searches the reservation **list** for every memory cell. At the
deepest non-tail-sum state, all N cells are reserved and no holding roots remain.
Successful searches visit \(N(N+1)/2\) list positions, regardless of reservation
order. At one million cells that is **500,000,500,000 positions**.

This is a demonstrated scaling defect in the required verifier path. We did
not capture the exact interrupted instruction in the failed million-element
attempt, so this is not a claim that a stack sample proved its timeout location.
The retained failure at the deepest boundary is consistent with this bottleneck.
Other work still contributes to the inclusive clock.

Three isolated runs on each already-retained native deepest state give:

| Reserved cells | Frozen predicate, median seconds | Proposed predicate, median seconds |
| ---: | ---: | ---: |
| 10,003 | 0.31375 | 0.003176 |
| 20,003 | 1.27642 | 0.006187 |
| 40,003 | 5.32015 | 0.012559 |

Doubling size roughly quadruples the old cost and doubles the proposed cost
over these measured inputs. CProfile of a complete frozen 40,003-element replay
attributes 5.137 seconds cumulative to five `state_ownership` calls, 5.053 seconds
inside that function itself. The profile is diagnostic; it is not compared as
an uninstrumented timing result.

## Preserve duplicate rejection before switching membership representation

`ownership.py` copies the frozen function and adds exactly one executable line:

```python
reserved = [a for _, a in state["aside"]]
require(len(reserved) == len(set(reserved)), "duplicate reservation")
reserved = set(reserved)
```

Snapshot and graph schemas already require natural integer identities. For
these values, set and list membership agree. Duplicate detection still occurs
before conversion, and no code iterates the reservation order afterward. All
holder counts, live/aside checks, dangling reservations, root walks, errors and
their order remain. The input state is not mutated. This is not sampling,
skipping ownership checks or assuming an expected verdict.

The separate verifier copy changes only its header and the ownership import;
an AST comparison verifies all other executable structure is identical. `walk`,
destruction checks, source/schema checks, decoding, equality, predictions,
observation schedules and clocks remain the approved implementations. No frozen
module global is patched. The diagnostic loader selects each verifier explicitly.

**Tradeoff and limits:** the set remains live during this predicate instead of
the list, changing temporary-memory constants. Both use linear-size storage;
no full-run peak-memory improvement is claimed. Lookup speed is measured on
these integer identities, not a universal bound against adversarial hash
collisions. The separate repeated-root-walk cost is unchanged; the deepest sum
has no such roots. No million-element time extrapolation is a passing result.

## Complete retained-stream and rejection comparisons pass

The old and proposed verifiers match **seven native public streams / 1,360,421
rows**, including deepest observations, zero-work advances, resumed completion,
early destruction, repeated destruction and host teardown. Both finish results
also match the original retained summaries. Three scaled runs compare every
reply by digest; the four summary streams compare every reply directly.

Uninstrumented complete-stream replay times (one old/proposal pair per size):

| Sum elements | Frozen replay seconds | Proposed replay seconds |
| ---: | ---: | ---: |
| 10,003 | 6.634 | 6.490 |
| 20,003 | 15.039 | 13.219 |
| 40,003 | 33.669 | 28.422 |

The largest replay improves about 15.6%, not 400× end to end. These runs include
gzip reads, all semantic checks and reply hashing, but no native process or new
evidence writing in the acceptance clock. They cannot establish resource
acceptance. The scaled source runs correctly failed the full-depth predicate.

**2,298 predicate comparisons match**: 2,254 synthetic states plus 44 actual
native full-observation states. Synthetic probes have independently specified
accept/reject expectations and compare exception type/message and input
preservation. Coverage includes shuffled reservation/memory order, identities
beyond 128 bits, shared tails, outside/pending/binding holders, duplicate cells,
duplicate/missing/dangling reservations, holder-count errors, invalid live/aside
states, the permitted `holderGivenUp` boundary, and cycles. A deduplication
witness confirms that deleting duplicate reservations would incorrectly accept
a state that both real predicates reject. These are synthetic predicate checks,
not new compiled evaluator sabotage controls or a universal equivalence proof.

All original/revision-02/performance/collector fingerprints and both pinned
native binaries remain unchanged before and after. The exact CPython 3.14.7
executable was used with JIT disabled. Same-agent implementation and differential
verification are reported as such, not independent acceptance review.

## Reproduce using already-public evidence

First restore the existing collector package from `experiments/13-source-acceptance`:

```sh
python3 stage-b-adaptation-01/package_continuation.py --restore stage-b-collector-01/evidence/public /home/user/NEW-retained
```

With the pinned Python installed, run from the same directory:

```sh
/home/user/.local/share/uv/python/cpython-3.14.7-linux-x86_64-gnu/bin/python3.14 stage-b-ownership-01/profile_replays.py /home/user/NEW-retained/rob1333-stage-b-collector-01 /home/user/NEW-replays
/home/user/.local/share/uv/python/cpython-3.14.7-linux-x86_64-gnu/bin/python3.14 stage-b-ownership-01/check_ownership.py /home/user/NEW-retained/rob1333-stage-b-collector-01 /home/user/NEW-checks
```

Run these sequentially, with no other heavy workload, for comparable diagnostic
timings. The diagnostic loader rechecks the original pinned binary locations;
it does not rebuild or execute them. `evidence/INPUTS.json` maps every used input
to its already-committed public archive, source hash and volume. The entire old
collector archive was restored and hash-verified before reading these inputs.
Their bytes are referenced rather than republished as new scientific evidence.
The new package preserves scripts, synthetic fixtures, raw profile, exact logs,
results and input/source identities, with readback and full restore verification.

The package contains **15 original files in one 89,751-byte volume**. Its index
SHA256 is `931f4aead24fd317ad46daf0761072dc227048f197ddb6351c3bf16bff51aaf0`.
Restore from `experiments/13-source-acceptance` with:

```sh
python3 stage-b-adaptation-01/package_continuation.py --restore stage-b-ownership-01/evidence/public /home/user/NEW-ownership-restored
```

**Next approval:** adopt this exact ownership implementation, freeze it with an
explicit-selection runner, then retry sum under the unchanged inclusive 900
seconds and discard only if sum passes, under 600 seconds. Keep the larger orb,
all full observations and every predicate. Stop again on the first material
failure. No acceptance claim, merge or deployment follows from this proposal.
