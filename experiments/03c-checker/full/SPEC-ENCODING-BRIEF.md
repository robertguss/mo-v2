# Full-3c specification encoding brief

This is a preparation artifact, not a scientific freeze or proof brief. Live
status and approval remain in [ROB-1139](https://linear.app/robert-guss/issue/ROB-1139).
Robert approved the [v2 English scope](https://linear.app/robert-guss/document/full-3c-post-stage-b-formal-contract-v2-9-october-73682eae811b)
under D185 and the separate author/specification/verifier arrangement under D186.

## Authorship and order

- The [acceptance author](https://ampcode.com/threads/T-01a12211-5ada-7319-991e-59ce08126990)
  owns `acceptance/`: exact programs, starting memories, rule-derived
  predictions, checks and Koka comparisons. Its prediction checkpoint must
  precede any new model execution or specification encoding.
- The [integrating specification author](https://ampcode.com/threads/T-01a121f6-7962-75c6-bb35-922b9a6cc491)
  owns the new Lean definitions and statement interfaces, only after that
  checkpoint. It must not edit the acceptance author's expectations to match
  execution. Discrepancies return to their author with evidence.
- A different verifier checks the resulting exact package and applicable
  controls. This is same-account procedural separation, not technical access
  isolation or a claim that model agreement establishes correctness.

No proof implementation, demand checker, actual scientific freeze, merge or
deployment is authorized. The scope includes preparation comparisons and checks,
not an amendment of the historical trial or Stage A/B.

## Immutable inputs

The preparation starts from the public repository at
[a4056b8](https://github.com/robertguss/mo-v2/commit/a4056b8341122622106fe60f834dbf8e2428295f).
Preserve all files outside this new `full/` directory. In particular, retain:

- `../trial/lean/Trial/{Language,Plain,Memory,Counted}.lean`, the trial statements,
  acceptance, predictions and locks;
- experiment 13's `BUILDER_EXECUTION.md`, Stage B preflight and binding-order
  clarification, approved observation amendment, and accepted-result limits;
- the mathematical-integer meaning and all four settled calls/ownership choices.

Do not retrieve private corpus inputs, seeds or per-case private evidence.
Existing candidate/reference output is not a source of new predictions.

## Definition boundary

Use Lean 4.34.0, the existing trial pin, with no new external dependency or
toolchain upgrade. Work in a new Lake package; do not alter the accepted package.
The root checkout has no default Lean toolchain: invoke Lean/Lake inside a pinned
package rather than changing the user's global default.

The new language and type validation describe the approved first-order function
table, calls, exact integer arithmetic, Boolean values, lists and lexical scopes.
Recursive calls resolve a declaration signature without recursively type-checking
its body; validate every declaration body separately.

Define the plain machine over immutable values independently of counted memory.
Define counted execution with explicit continuations, pending values, invocation
and branch identities, ownership, reservations, release work and primitive events.
No recursive source evaluation may be hidden in one step. A step must be a total
definition, not a partial/unsafe executable substitute for its logical meaning.

Separate the ideal machine's progress/answer claims from externally controlled
allocation denial and destruction. A timeout, an exhausted observation budget
and a controlled denial are not success. Budget partitioning preserves state and
the append-only event prefix; terminal advances and zero-budget advances do no
work. Cleanup retains only outside-root storage and is repeat-safe.

State F1–F6 and L1–L2 against the concrete definitions. Do not assume their
conclusions through an abstract machine parameter, valid-start predicate or an
invariant requiring future correctness. Keep independent plain/control value
correspondence explicit so incorrect liveness flags cannot hide a lost holder.
Define the fixed trial projection before comparing outputs; it may omit only
specified added control actions, never primitive cell effects or old landmarks.

The package must distinguish definitions/statements, executable finite checks,
unproved universal obligations and later proof acceptance. Compiling a proposition
is not proving it. Do not manufacture proof stubs with `sorry`, extra axioms or
default witnesses merely to make an acceptance target compile.

## Validation and stop

Validate concrete definitions through the separately authored expectations and
applicable controls, including asymmetric values and both sides of suspension,
ownership and cleanup boundaries. Retain Koka's exact verdicts separately from
Mo's expected verdicts. Preserve mismatches; do not erase them by changing scope.

Stop at a reviewable, verified preparation package and proposed content inventory,
before a scientific lock or proof/checker dispatch. Stop earlier on an unresolved
semantic contradiction, missing authority or integrity failure. A model/contract
defect is not an unfinished proof and must be reported as such.
