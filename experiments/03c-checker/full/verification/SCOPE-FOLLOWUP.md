# D186 / ROB-1139 separate scope follow-up — 2026-10-09

**Disposition: the precise ordered-observer specification gap in FINAL-REVIEW.md
is closed in the reviewed source. That gap no longer blocks consideration of
proposed exact-spec freeze. This is not freeze authorization or a proof.**
Reviewed current untracked `full/` directly, not a git diff or origin/main.
Same-account procedural separation is not independent scientific certification.
Historical reports, model, acceptance and expectations were not changed.

## Source adjudication

- `Inspect.initialScope` derives input identities/order from the start. F1 now
  requires it for every successful begin, not merely selected exports.
- `Inspect.nextScope` independently matches the **source** task, signature,
  contexts, source operands and fresh identity counter. It never executes
  `transition` or reads its result. Enter uses callee parameters; Return restores
  the saved caller environment. Bind, Cons, list-variable transfer, choice,
  branch and match actions have explicit scope rules; administrative actions
  preserve the last entered scope. Scalar-variable evaluation correctly does
  not itself introduce a scope event.
- F1 requires the next committed scope to equal this prescription and **every**
  successful precommit transfer's scope to equal that committed scope. Together
  with initial scope, this is an inductive source-scope obligation, rather than
  a filter formula that trusts arbitrary `entered`. Boundary invariant checks
  cover source, transfer output and metadata commit; commit changes only steps,
  history and landmarks. There is no running helper State between those cuts.
- `observer`, folded into `invariant`, requires entered name/ID membership and
  exact complete Binding records sorted by acquisition ID. Its required set
  includes all entered IDs regardless of status, including scalar/noHolder,
  plus holding bindings outside scope. Suspended caller holders therefore remain
  visible; caller scalar locals need not remain visible while the callee runs.
  Reversing storage cannot silently reverse the observer view.
- Historical shared-match timing is preserved: shared Decompose enters early
  only if a used, nonempty tail acquires a holder. Otherwise the old scope remains
  during GiveUp/Free cuts until MatchComplete. This agrees with the immutable
  Trial source's `enter env'` after `giveUpLink`, not a naive next-task context.
  Empty tails do not acquire holders merely because the tail name is used.
- Export checks initial scope; Inspect.trace checks the prescribed scope at both
  transfer and commit, with invariants at the running boundaries.

The scalar witness still passes `observer` alone when `entered=[]`: this is
expected, not a residual gap. It now fails F1's independent nextScope equation.
The ordering witness instead fails observer/invariant. These are complementary
obligations, and neither should be described as replacing the other.

## Fresh verifier execution

From `full/lean`:

```sh
lake build
lake env lean -o .lake/build/lib/lean/Export.olean Export.lean
FULL3C_INPUTS=/tmp/full3c-scope-evidence/inputs.json lake env lean ../verification/Controls.lean > /tmp/full3c-scope-verifier-controls.log
lake env lean --run TrialCompatibility.lean
```

All succeeded. Controls executed **21** faulty routes with passing counterparts,
including hiddenScope **C12/action 5** and observerOrder **C4/action 6**. All 28
Trial answers, primitive events and complete ordered landmark snapshots passed.

Additionally, a temporary verifier-owned Lean inspection (removed after use)
parsed all 90 supplied starts and, for each fixture budget until Finish, compared
independent nextScope with actual transition output and actual step, checking
observer at source/output/commit. It checked initialScope for every start.
**4,542 action boundary triples passed**, including 30 Enter actions with visible
suspended holding bindings, 13 shared Decompose actions retaining old scope,
and 24 MatchComplete actions. This scan deliberately ran Counted directly,
without the export denial policy, so totals are not acceptance trace totals.

The independently isolated C12/action 5 witness printed:

```text
expected=[("n", 0)]
good=[{ id := 0, name := "n", value := Trial.RawValue.num 0,
        status := Trial.BStatus.noHolder }]
bad=[]
observer(bad)=true protection(bad)=true nextScope rejects=true
```

The baseline passed the same scope property; clearing only entered failed it.
No acceptance predictions or observed JSON were modified to obtain this result.
The parent's 820-group integration result is not claimed as a fresh rerun here.

## Exact reviewed-source SHA-256

Paths below are relative to `full/` unless explicitly noted.

```text
2e506524f368171b5749526cccf06e5917bc1824b80e658dbd639d3af5ae20a0  lean/Full/Inspect.lean
b178b3c5af611f7a90f45113e01bdb521bfbf2ecd5134ef6903d1bceb9065178  lean/Full/Statements.lean
f2288ca4c6a72ca7e1193454ee0141208e3c6ad6854a523cf3fd99621a67e699  lean/Full/Counted.lean
5e805da8c2b7f86fbf4e3f4fffb0f192aa773e5774a1f96c13eaea1d79a3ba15  lean/Full/Control.lean
20958d381dce14478b02ad1062dc26f2969fc6f6225e81d3dfaac3930af45541  lean/Full/Plain.lean
36e6caeb5ecfa2dc019ca5b52c689ce4d4b9c99270bb451ef8a39eae25ac0f63  lean/Full/Lifecycle.lean
226ae9db76d0a78ff5094679c2595847bc4ca0b910b7c18e572b0685e7a37fa4  lean/Full/Language.lean
f8b74a6a9184f3ce6661acdb6caa3790099903ed0b68eb186a66045b0701d76d  lean/Export.lean
9cdd63097ae2c8d2404cbc07fe821266609a8c5e5af1479972737966ae14f9a2  verification/Controls.lean
7d5bc3fee2b3f179df55b0aaf98bb689c9e7748628cc73557c604d890722e049  verification/FINAL-REVIEW.md
fe299d069daf6be3cdce68633e891cd5133a35404ca5378ffbe93690594d26f2  ../trial/lean/Trial/Counted.lean
```

Evidence hashes (temporary files are not a frozen package):

```text
9a604ff2a932c32c5715c99bf7e69a53dd82f44117c2a4d8c4e6a06505a14ec1  /tmp/full3c-scope-evidence/inputs.json
6221791c815e685fa0f803cab9cd938164b6c09369c23e801db6fe9b02c5b73e  /tmp/full3c-scope-verifier-controls.log
bcd852cc6f9fb96401ebd69e12d2a2af57ac376773ccc5cd95d633a57464e1ea  /tmp/full3c-scope-verifier-focused.log
2d110f5b5c1c050b58f749ce928f58c77138ad0964966533180a6e04a6cad37c  temporary ScopeVerifier.lean (removed)
```

## Limits and authority

Compilation/finite tests do not discharge F1 or other universal propositions.
The full-record equality is a specification of the running observer, not an
independent theorem that every stored field implements source semantics.
No new concrete scope/order contradiction was found. Universal proofs, frozen
revision/hash inventory, transitive-axiom inspection and kernel recheck remain
future separately authorized gates. No proof, checker, freeze, push or merge
work was performed or authorized by this review.
