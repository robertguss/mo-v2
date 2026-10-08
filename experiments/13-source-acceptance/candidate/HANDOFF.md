# Stage A candidate final-08 — unexpected-token diagnostic spans, not accepted

Crate: `mo-stage-a` (Rust library `mo_stage_a`). Exported implementation:
`mo_stage_a::StageA: mo_acceptance_runtime::Candidate`.

This candidate implements the authorized call-free Stage A contract from the
delivered public requirements, including v15 diagnostics, v16 runtime methods
and v17 match-birth timing, plus the public-safe scope, active-release, Handoff
and decomposition clarifications in the final-04/05/06/07 dispatches, plus the
final-08 unexpected-token diagnostic explanation.
There is no outstanding contract blocker. Native linked
execution still requires independent verification; no acceptance result is claimed.
The source is local to this no-project orb, not committed or present in the
parent repository. Transfer this directory alongside the unchanged `runtime/`.

## Final-08 repair

The parent reports final-07 passed all 4,276 historical native runs / 53,796
actions, including earlier failure boundaries, final/native readback, repeated
terminal destroy and Drop/teardown. Bounded totals were 89 Writes, 304 Creates,
5,269 Frees, 1,064 outside-root fixtures and release depth three. After 26
applicable frozen refusal runs passed, checking stopped on a syntax diagnostic
end position. This is not full Stage A acceptance; further frontend, wide-number,
private, routing, nonterminal, failure and control obligations remain.

expect() now delegates mismatches to the existing error() path rather than
replacing every ordinary token's range with an insertion span. Present tokens
retain their width; EOF's existing empty range still represents missing input.
Encoding, numeral and lexical classes and earliest-source priority are unchanged.
No lookahead, recovery heuristic, native operation or execution code changed.
The public broad distinction is explicit, but does not enumerate every parser
recovery situation; this qualification remains recorded.

Two new tests failed before repair and pass afterward. Independently counted
spans cover grouping, lists, calls, input/function punctuation, main, if and
match delimiters; extended EOF checks retain empty insertion spans. Tests also
cover CRLF/scalar positions and earlier syntax winning over later encoding,
lexical and numeral errors, while those classes remain intact at the current
token. One old self-test assumed an empty span before a present main token;
its expectation was corrected from the public rule before changing production
code, not fitted to a result. These checks are development evidence only.

## Final-07 repair

The parent reports final-06 passed 25 complete native historical cases / 576 actions,
including previous failures, with 18 Writes, 5 Creates, 11 Frees, two retained
fixtures and active release depth two. Checking next stopped solely on shared
Match decomposition's entered-binding exposure. Graph/holders, control and
birth/event prefixes agreed; no corruption, lost holder or wrong final answer
was demonstrated. No full acceptance or native nonterminal/denial result exists.
The public decomposition/completion wording did not explicitly specify the
conditional entered-view timing; that disclosure limitation is retained.

Unique decomposition and shared decomposition that acquires a nonempty used
tail enter the extended scope immediately. Shared decomposition without tail
acquisition preserves its previous entered view through scrutinee release, then
enters at Match complete. Binding creation/births remain at decomposition;
working branch scope, immutable control scope, holder effects, release ordering,
events and action count are unchanged.

Post-native decomposition bookkeeping was extracted into State::decomposed,
analogous to the existing gave_up/freed bookkeeping. The behavior-preserving
extraction passed the existing 37 tests before the timing change. Two new tests
then failed before repair and pass afterward. Their table covers unique/shared,
empty/nonempty tail and used/unused binder combinations; completion coverage
checks separate release bookkeeping, zero-budget resume, a denied Frame's
unchanged prefix and a successful continuation from the same saved state.
Tests supply only a Cell read descriptor to pure logical bookkeeping; no native
store, read, detach or acquisition is constructed or emulated. The native effects
still execute in their original order before that helper in production.

## Final-06 repair

The parent reports thirteen historical native-linked runs completed on final-05,
including native/final readback, repeated terminal destroy, bounded retained-head
and retained-tail protection and release depth two (8 Writes, 4 Creates, 6 Frees).
Checking stopped at a Let Handoff's entered-binding projection, not demonstrated
holder loss, native corruption or wrong output. Nonterminal native resume/destroy
and denial cuts remained unrun. These results are partial evidence, not acceptance.

Only Match Handoff now restores `entered` from its context's outer scope. Let and
If Handoff retain the current entered view until another specified action changes
it. Lexical control scope, result/control boundaries, native operations and all
previous repairs are unchanged. The public action-specific rule supported this
distinction but did not state the Let/If exception verbatim; the precision
qualification is retained, with no claim of changed criteria.

Two new tests failed before repair: nested Let/If prematurely dropped entered
locals, and a shadowed moved-on list local disappeared at Let Handoff. Both now
pass. Coverage compares nested Let/If versus Match, incoming lexical scope versus
entered bindings, single-action resume versus uninterrupted execution, and a
denied Finish that must preserve the Handoff prefix. The list test denies its
first read at the Number gate before native access. A third pure logical Match
Handoff test preserves restoration of its head/tail binding view. No native
storage is constructed or emulated; these are builder-owned development checks.

## Final-05 repair

The parent reports four historical native-linked runs completed on final-04,
including final readback, repeat-safe terminal destruction and three actual
same-allocation writes. Subsequent checking stopped on active-release reporting,
not demonstrated early native effects, corruption or a wrong final answer.
This is partial independent evidence, not full Stage A acceptance. The public
document called release an active chain but did not explicitly specify when
queued work first becomes active; that wording limitation remains recorded.

Release entries now distinguish Queued work from active Give/Free/Waiting frames.
The shared-match scrutinee and a freed cell's protected tail begin Queued, outside
the reported active chain. start_release activates work while preparing its
existing action. gave_up retains a surviving-holder frame through its callback;
freed retains its current frame even without a tail. Completed frames unwind on
the next action, keeping ancestors until descendants finish. No extra commit,
replay, earlier native effect, or fabricated shadow state was added.

Native read/decrement/free order, pending-holder transfers and counted events
are unchanged. Preparation occurs within the existing staged Frame callback, so
denied activation or subsequent work leaves the committed active chain intact.
Destroy drains Free obligations and discards completed Waiting bookkeeping,
without decrementing or freeing completed entries again.

Three lifecycle checks failed before repair: tail activation during Free cell,
premature removal after a no-tail free, and premature removal after a surviving
holder give-up. These now pass, with additional logical-ledger and gate-denial
checks for scheduling, ancestor retention, resume without extra commits, failure
prefixes, and repeat-safe destruction of completed bookkeeping. No native store
is constructed or emulated; native release acceptance remains separate.

## Final-04 repair

The parent reported that final-03 passed both prior boundaries, then stopped on
control-scope reporting. The public explanation clarifies the per-expression
lexical-scope projection in BUILDER_EXECUTION.md; the phrase "incoming environment"
was not previously explicit. This is not a frozen-criterion or language-policy change.

Control now serializes each context's existing immutable `outer_scope`, captured
when that expression is entered, instead of its mutable working `scope`. The
working scope still drives lookup, local binding extensions and child entry.
The separate entered ownership view, handoff restoration, native operations,
action boundaries and birth timing are unchanged. Nearest-name replacement
retains name insertion order in the reported entry scope.

Two builder-owned tests failed before the repair and now pass. One executes
several overlapping let names, checks every active entry scope and Bind's separate
entered binding view, and compares one-action resume against an uninterrupted
run with an independently calculated result. The other is a pure logical Match
projection/child-entry test with overlapping head/tail names; it does not execute
native decomposition or create/read/emulate native storage. These tests are
development evidence only, not independent native acceptance.

## Final-03 repair

The parent reported that final-02 passed the original native control boundary,
then stopped on match-branch birth timing. The parent classified this as a public
disclosure gap, not an unambiguous violation of a previously supplied rule. The
reviewed public v17 supplement discloses the frozen timing; it changes no criteria.

Choose branch no longer creates a match identity. The next action prepares it
in staged state, before outer-holder cleanup. That action first publishes the
birth: Give up holder when cleanup is needed, otherwise empty Branch start or
nonempty Match decompose. Existing branch/head/tail origin and order remain; no
new transition is added. Published identities are not recreated, and denied
actions discard uncommitted birth preparation with the rest of staged state.

Two new development tests and strengthened empty-match assertions first failed
against final-02's early publication. They now cover empty publication, nested
scrutinee execution order, If exclusion, one-action resume, and denial before or
after publication. Tests also inspect the real executor's staged birth before
denied cleanup/decomposition reads using opaque logical holder IDs: the Number
gate denies before any native call. No native cell storage is built or emulated.
Successful native cleanup/decomposition and physical ownership remain for the
separate checker; these development checks do not establish acceptance.

## Final-02 repair

The parent reported that final-01 linked to native storage but failed committed
control reporting: result production popped the child and advanced its parent
before publishing the child's own boundary. This public-safe diagnosis, the
existing public execution document and builder-owned source were the only inputs
to this repair. No private input, expected state, checker or host code was supplied.

Leaf, Primitive result and Handoff now retain their actual context with a Produced
continuation phase and a ready result. The next existing action transfers that
result in staged state before resuming the parent (or finishing main). There is
no extra committed transition, snapshot-only reconstruction, or re-evaluation.
Frame/Number denial continues to preserve the previous committed boundary.

Two builder-owned tests first failed on final-01's early transfer and now pass.
They independently specify simple arithmetic boundaries and nested arithmetic,
let/if/match handoffs, pause after every commit, check lexical control/consumed
operands/ready, and verify final answers and allocation counts without replay.
The existing exhaustive small-scalar allocation-denial and resume tests also pass.
This does not claim independent acceptance or correctness of later native behavior.

## Implementation and decisions

- Original source bytes feed a full-grammar parser and one shared checked-form
  arena. Ordered lexical/syntax/name/type diagnostics, Stage B refusal, checked
  JSON, declaration identity and source spans follow the public supplements.
- Canonical signed decimal integers support exact arbitrary-length prototype
  arithmetic. Actual numeric parse/arithmetic/copy buffers use Number callbacks.
  Reporting serializes borrowed numerals without numeric String copies.
- The evaluator uses explicit resumable continuations and an ownership ledger,
  including last-use transfer, iterative release chains, unique/shared match
  handling, branch-local reservations and same-allocation Cons reuse.
- Each execution action prepares a cloned logical state inside a Frame callback.
  All Number and cell-denial points precede that action's first native mutation.
  Failed actions leave the committed logical state and event prefix untouched.
- V16 resolved the previous blocker: detach performs reservation bookkeeping but
  emits no counted write; metadata changes no linked holder; write/free/create
  events are reported separately. Tail-holder transfers remain evaluator work.
- Explicit destruction drains run ownership without resuming evaluation; physical
  frees are recorded separately from execution events and successful destruction
  is repeat-safe.

## Development verification and limitations

Forty-one self-authored unit tests pass. They cover frontend diagnostics and
precedence, full-grammar refusal, checked dumps/spans/shadowing, decimal arithmetic,
scalar and empty-list execution, exact/zero budgets, segmented resume, empty-match
landmarks, read-only reporting, every Number/Frame denial ordinal in a small scalar
program, repeat-safe scalar destruction, and pure ownership/release bookkeeping.
These are development tests, not independent accepting checks.

The test-only `Resources::NoCells` variant exercises the same executor's scalar
and empty-list paths with controlled Number/Frame gates. It contains no native
cell storage and panics if a native method is requested. Logical bookkeeping
tests use opaque numeric identities and read descriptors without constructing
or emulating native storage.
No RuntimeCells constructor, host observer, fixture builder, secondary evaluator,
corpus dispatch, replay, or acceptance import was added.

Native linked-list execution, actual allocation identity/reuse, outside-held
storage, cell-create denial and native destruction have NOT been executed here:
the supplied capability intentionally provides no standalone host constructor.
Compilation and code review do not establish those properties. The parent must
rerun this repaired implementation with its separately owned host for independent
checking. The parent's successful final-01 linkage does not certify final-02.
Likewise its reported final-02 control-boundary success does not certify final-03.
The reported prior-boundary success of final-03 likewise does not certify final-04.
Partial historical-run evidence for final-04 likewise does not certify final-05.
Partial historical-run evidence for final-05 likewise does not certify final-06.
Partial historical-run evidence for final-06 likewise does not certify final-07.
Historical-run and partial refusal evidence for final-07 does not certify final-08.

No Stage B execution, recursion or large resource workload ran. The parser,
typechecker and checked-tree serialization use host recursion; evaluation and
cleanup are iterative. Cloning logical state per action is intentionally simple
and makes no large-workload performance claim. Arbitrary host OOM/panic recovery
is not provided, consistent with v16.

## Reproduce

Use Rust/Cargo 1.98.1 from this `candidate/` directory, adjacent to `runtime/`:

```sh
export CARGO_TARGET_DIR=/tmp/rob1333-candidate-target
cargo +1.98.1 check --locked
cargo +1.98.1 test --locked
cargo +1.98.1 clippy --locked --all-targets -- -D warnings
cargo +1.98.1 fmt --check
sha256sum -c CANDIDATE.sha256
```

All four Cargo checks pass; tests report 41 passed, 0 failed. The generated
Cargo.lock is included. Build artifacts are outside this candidate directory.
The final archive contains exactly Cargo.toml, Cargo.lock, lib.rs, frontend.rs,
number.rs, execution.rs, HANDOFF.md and CANDIDATE.sha256; the manifest hashes the
other seven files. No runtime or requirement file is included in the archive.

Earlier development found three incorrect hand-counted test spans; these were
corrected by independently enumerating source characters. No failing check was
suppressed. The final v16 version replaces provisional native-operation handling
from the preserved partial checkpoint.

## Public input integrity and procedural record

All four public archives and earlier candidate checkpoints remain unchanged:

- v14: 19,610 bytes, SHA256
  `3327ee87f52316bec571f91c81b20f556f030614d41a681699a6cdc8f49c94de`.
- v15: 21,271 bytes, SHA256
  `fa7969d102fb1607b81059522307982e5aa180ed509bbb4fc9ad3d588070a898`.
- v16: 24,605 bytes, SHA256
  `52ee52f3304f80c23c7f7b60c323491e97cb9961d7a2eb44e2700832d18ddc1c`.
- v17: 26,074 bytes, SHA256
  `95570ef6a4003c1322005afd5492365de997c5e5742b5a0ea9c355b04b84ec08`.
- Partial checkpoint: 20,658 bytes, SHA256
  `e68b5c01dfff2029036b5c63e66ee7de1736adb77eecc858d8f36e2c8fa244ac`.
- Final-01: 24,780 bytes, SHA256
  `22ab6d216977176e34859d5101f1783fa8523058baf46cdf1bf4175a1f4ec002`.
- Final-02: 26,454 bytes, SHA256
  `7332eaad9ade0984b68a97a97e638dd339e69660340b8b9fd99e61b3067644a4`.
- Final-03: 28,515 bytes, SHA256
  `df35cb0a094d84f494d43c0f192c1aab0f7f158526bc708fb8bd44f7f8048718`.
- Final-04: 30,073 bytes, SHA256
  `1069848d4cf78d66b6ff33646a5a8cab08558b7e52fee366b73ab06222d46a30`.
- Final-05: 31,827 bytes, SHA256
  `c6b8ac01150bdca10815e631e3af9d9be0f7d053eba50eee92a3ab65027ba9eb`.
- Final-06: 33,246 bytes, SHA256
  `4e560790cde6482296b671f2f5fa87e4052e79187e740bf4234434a7dae62783`.
- Final-07: 35,180 bytes, SHA256
  `9fe792c138a6900a7c32f76ee36f051c08410163d693b0d7601b85f0918158cd`.

V17 exact thirteen-file membership, all twelve content hashes and preservation
of all eleven v16 content files were verified. Its new 4,228-byte supplement has
SHA256 `41b286ba9654c1833ffcacc8aad8fb4ddf1aea8e7deef6cdae8966898bab78cf`.
It was extracted separately into `/home/user/workspace/stage-a-v17`.

V16 exact membership is seven requirements documents, four runtime crate files,
and DELIVERY.sha256. All eleven content hashes pass; the original ten v15 content
files are unchanged. The v16 supplement SHA256 is
`e0e866953b4fbf3af4f5af6f238c7663902b70a4ca4f7976d1d39ad9c0221938`.
The v15 supplement SHA256 is
`c0d44cf9869ad1a1b93dd5b5d74f21ca7ecde5e2a051d8ea585d794d3e8528fa`.
All extracted delivered requirements/runtime remain unchanged.

No excluded repository/history, Linear, parent/prior conversations, acceptance
material, private cases, seeds, predictions, controls, or reviewer archives were
retrieved. No accidental exposure was observed. No other thread was created.
Only official Rust toolchain and ordinary Cargo package downloads supplemented
the public delivery. No acceptance edits, Fable, merge, deployment or release.

## Contributor elapsed time

UTC on 2026-10-07; active intervals include build/test waits and packaging:

- Active 21:57:22–21:57:53: 31 seconds.
- Stopped for diagnostic clarification 21:57:53–22:03:47: 5m54s excluded.
- Active 22:03:47–22:16:11: 12m24s.
- Stopped for native-method clarification 22:16:11–22:22:16: 6m05s excluded.
- Active 22:22:16–22:33:03: 10m47s, through final-01 transfer.
- Stopped pending independent review 22:33:03–22:44:14: 11m11s excluded.
- Active final-02 repair 22:44:14–22:47:15: 3m01s.
- Stopped for independent review/public clarification 22:47:15–22:59:40: 12m25s excluded.
- Active final-03 repair 22:59:40–23:02:38: 2m58s.
- Stopped pending independent review 23:02:38–23:09:08: 6m30s excluded.
- Active final-04 repair 23:09:08–23:11:44: 2m36s.
- Stopped pending independent review 23:11:44–23:18:07: 6m23s excluded.
- Active final-05 repair 23:18:07–23:23:19: 5m12s.
- Stopped pending independent review 23:23:19–23:29:19: 6m00s excluded.
- Active final-06 repair 23:29:19–23:33:42: 4m23s.
- Stopped pending independent review 23:33:42–23:40:08: 6m26s excluded.
- Active final-07 repair 23:40:08–23:43:20: 3m12s.
- Stopped pending independent review 23:43:20–23:52:53: 9m33s excluded.
- Final-08 repair resumed at 23:52:53. Its final UTC stop and cumulative active
  elapsed are in the delivery thread report, after packaging, verification and transfer.

Total active through final-07 was 45m04s. No arbitrary hour cap was applied.
