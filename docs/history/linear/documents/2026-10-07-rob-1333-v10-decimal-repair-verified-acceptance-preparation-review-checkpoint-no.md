# ROB-1333 v10 — decimal repair verified; acceptance preparation review checkpoint (not frozen)

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/document/rob-1333-v10-decimal-repair-verified-acceptance-preparation-review-ee15e34ec743
> Created: 2026-10-07
> Updated: 2026-10-07
> Author: Robert Guss
> Attached to: ROB-1333

---

# V10 — reviewable preparation checkpoint; final executable acceptance INCOMPLETE

7 October 2026. Prepared by the separate acceptance author, never the Mo builder. Fable is plan-review-only and was not invoked. Previous v1–v9 documents, source exports, original predictions and failed evidence are preserved. This checkpoint supersedes v9's decimal-defect stop under D145, bounded continuation without routine repair approvals. It is NOT a scientific lock, builder brief, accepted package, universal proof or execution approval.

## Current authority, not blanket approval

D139, limited first-language scope including ordinary true/false literals, and D140, exact growing prototype integers, remain approved. Permanent numeric policy is open. The four call constraints remain D127, call-local reservations; D128, unrestricted recursion/resumable bounded observations; D129, continuous live-value protection; D130, creation counting from entry after explicit arguments including nested/transient work. D138 selects this orb, larger only if needed; resources must be rechecked before eventual authorized execution. D141, deliverable-based acceptance preparation, permits reference/checker code and its validation, then a review stop; it adopts neither an eight-hour preparation cap nor mandatory two-hour approvals. D145 permits routine consistent repairs without interrupting Robert, not changes to frozen criteria or wholesale approval of semantics.

D142, earliest lexical/syntax source error, and D143, whole-file syntax before name/type checking including duplicate match binders, override older diagnostic/preparation-status wording. D144 approved only the versioned span correction for main = \[\] == 1: \[\] at columns 8–10, not 1 at 14–15. Detailed spelling/types/names/ownership/transitions/output/failure formats and resource/stage-effort limits below remain PROPOSED. None is made approved by the reference agreeing with its author.

## Exact source/evidence delivery

[Download v10 source and evidence export](<https://uploads.linear.app/f291a744-db03-47a3-b7a6-4f8fa26fbf09/411c9b3f-570d-4517-85f2-842fab97234b/75f2a2ae-c109-4dc6-aa56-09bbbf7e8db1>), also attached to [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and) as attachment f00905fb-ff64-4dd5-afc7-07f9eb4d8d34. Size 1,435,207 bytes; SHA256 4ac412f32023800480716c8b5913c78aff45a48dd7a515b61f74623c4857a87e. Contains experiments/13-source-acceptance source, README, PROTOCOL.md and all preserved public preparation evidence; excludes private seed/cases/predictions, Python caches and build targets. Review fingerprint, NOT a scientific lock.

Working branch acceptance/[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and)-preparation is based on [origin/main baseline](<https://github.com/robertguss/mo-v2/commit/03705f1dac1de8cbc9efedaf99ad4feeb62c17a3>). Local changes are uncommitted/unpushed. No parent state or files were transferred. This export supplies exact review source now; it is not a commit-pinned Git delivery. No push/merge/deployment, Fable execution, participant trial, Mo implementation or million-depth/resource-envelope run occurred.

Historical corpus SHA256 remains d8d33f795b94e8173b6685462e83a277bfeefad5cc2bfee6bee38a8f63554a8b. Sources: [finite bridge SPEC](<https://github.com/robertguss/mo-v2/blob/a22831f823d2ac7ccbb8726a8d4418fbceb233e0/experiments/10-finite-rust/SPEC.md>), [frozen exporter](<https://github.com/robertguss/mo-v2/blob/a22831f823d2ac7ccbb8726a8d4418fbceb233e0/experiments/10-finite-rust/Export.lean>), [trial English rule](<https://github.com/robertguss/mo-v2/blob/e6a895c8ce2887d9bee6986819a779f8f74b5541/experiments/03c-checker/trial/RULE.md>), [trial snapshot interface](<https://github.com/robertguss/mo-v2/blob/e6a895c8ce2887d9bee6986819a779f8f74b5541/experiments/03c-checker/trial/INTERFACE.md>). Historical model/trials/locks are unchanged; no blanket re-audit of other issues is claimed.

## Verification actually executed

Commands below run with python3 in experiments/13-source-acceptance and write NEW evidence directories. Existing evidence refuses overwriting. These validate preparation, not a Mo candidate.

| Command/evidence | Decisive result and limitation |
| -- | -- |
| [decimalcheck.py](<http://decimalcheck.py>) evidence/decimal-03 | PASS 35 string-derived carry/borrow/negative/cancellation/input/output examples at 1000,4299,4300,4301,5000 digits; source roundtrips. No Mo digit cap. |
| [prioritycheck.py](<http://prioritycheck.py>) evidence/refusal-priority-05 | PASS 14 refusals/2 accepts, including main = (1 2) @ reporting unexpected 2 at 11–12 instead of later @. |
| [phasecheck.py](<http://phasecheck.py>) evidence/refusal-phase-05 | PASS 24 independently annotated mixed-error phase examples; malformed body wins before duplicate names/types; syntax-valid duplicates still refuse. |
| [refusalcheck.py](<http://refusalcheck.py>) evidence/refusals-04; [comparisoncheck.py](<http://comparisoncheck.py>) evidence/comparison-02 | PASS 24 refusal rows; PASS 12 wrong-left/right refusals and 11 valid asymmetric/boundary/wide comparisons. Original mistaken row remains preserved. |
| [selfcheck.py](<http://selfcheck.py>) evidence/public-09 | PASS 16 source accepts/12 refusals/21 public C-family cases/seven synthetic defect controls. Not compiled Mo controls. |
| corpus_tracecheck.py evidence/corpus-trace-04 | PASS all 4276 cases; 53796 predicted committed boundaries project to all 27721 frozen snapshots, every old field/kind/event retained. Full per-case traces in per-case.jsonl.gz. Logical reference, not physical candidate execution. |
| [generated.py](<http://generated.py>) evidence/generated-05 | PASS 500 exploratory compositions/22090 logical snapshots. No unseen-program or universal guarantee. |
| [structurecheck.py](<http://structurecheck.py>) evidence/structure-01 | PASS six canonical Bool/type/name/function/binding examples, with acceptance-derived declaration identities. |
| [acquisitioncheck.py](<http://acquisitioncheck.py>) evidence/acquisition-04 | PASS four hand schedules/18 terminating public/500 generated/four corrupted acquisitions. Immutable tuple evaluator predicts bindings separately from the ownership dump. |
| [controlcheck.py](<http://controlcheck.py>) evidence/control-02 | PASS three hand-derived operand/ready/invocation/release schedules and three nonterminating prefixes. |
| [observationcheck.py](<http://observationcheck.py>) evidence/observation-05 | PASS two synthetic valid bundles; detects pending mutation, wrong action, physical discontinuity, replaced resume identity and omitted required resume. Does not acquire native candidate evidence. |
| [fixturecheck.py](<http://fixturecheck.py>) evidence/fixtures-01 | PASS 4276 original fixtures/eight invalid graph kinds, without changing historical fixtures. |
| [cleanupcheck.py](<http://cleanupcheck.py>) evidence/cleanup-01 | PASS predicates across 1603 synthetic destroy boundaries and repeated destroy; four leak/double-free/outside-replacement/loss controls. real_destroy_executed=false. |
| Fresh-target cargo test --locked --manifest-path cells/Cargo.toml, evidence/native-cells-03/output.txt | 6 passed, 0 failed. Real boxed storage creation/rebuild/detach/free/fault primitives; compiled deliberately wrong storage replacement triggers the intended live-allocation assertion. NOT a compiled evaluator control. cargo fmt --check also passes. |

Private preparation: 500 generated heldout compositions reside outside the repository/export. Private-01 passed; private-02 verifies their old source/answer/event/canonical/binding/trace predictions unchanged and saves new control fields separately. Cases SHA256 d8084068c880a3a2764c42ecf0e15b7f493faad963adba9ff32fd2f7fb2dc41b; separate controls SHA256 9ad28da556d0f038b07ec0659b71a807d35797a1b74dfa01cdaebeffc34aa54c. Seed/exact cases remain private and are not attached here. Not yet frozen or a balanced coverage certification.

## Repairs and failures are preserved, not erased

The v9 archive/failure shows the unhandled 5000-digit Python conversion exception. Acceptance-only processes now set their decimal conversion guard to zero for parsing AND output; user installation settings are unchanged. Independently expected all-nines plus one is one followed by the same number of zeros; borrow/sign/cancellation examples use decimal identities, never observed output as expectation. No unlimited-resource claim follows.

Two further routine preparation repairs: computed numeric primitive results are now committed after computation, keeping old landmarks/predictions unchanged; synthetic observation transport uses plain JSON instead of deepcopy of owner-linked records that appended events into the copied owner. Observation-01 failure remains. Native unique detach now has its own journal action, not a falsely counted rebuild. These are reference/test-storage repairs, not language choices.

Some old runner summaries retain 'missing' lists for obligations that runner did not exercise, even when another later preparation check supplies partial coverage. They are preserved; the table above and gaps below state the current aggregate claim. No old evidence is rewritten to manufacture readiness.

## Proposed candidate-observation contract and real gaps

PROTOCOL.md in the export defines the linked check/dump/begin/advance/snapshot/destroy boundary. The checked program must be produced from complete source, not a supplied acceptance tree. Acceptance alone retains Observer; candidate receives RuntimeCells. Actual fixture and source cells use identical Box storage, and observer reads actual contents/pointers/events. Runtime IDs are available as handles; source inspection must reject provenance/ID special cases and bypass/shadow storage. That is an obligation, not proved noninterference.

Static identities come from declaration paths; runtime identities use one consistent run-wide correspondence covering bindings/cells/branches/frames/events. Never remap per snapshot. Call returns match enter identities. Pointers persist only while live, may recycle after free, and are never compared raw across separate runs. Control/operand/ready/release state is part of the full trace, not just memory totals.

For each small boundary k including zero/terminal: fresh run, advance k transitions, snapshot, resume with zero work, compare unchanged event prefix/live pointers, then compare the independently predicted remaining suffix. Terminal-at-budget is terminal; terminal reobservation is no-op. Separately destroy at every boundary/failure/finish, twice; remaining cells/counts are derived from outside roots/edges, not candidate claims. Numeric/frame allocation hooks are separate from managed-cell counting; a failure injection precedes effects and preserves the last committed state. These actual candidate operations have NOT run.

Missing before final acceptance can be frozen: linked candidate driver/native full-state normalization; executable invalid-encoding and public wire-output checks; numeric/frame failure hooks; separately balanced manual heldouts and measured generated coverage/bounds; complete compiled evaluator controls. Missing until a Mo candidate and separate execution authorization exist: actual physical full traces, every actual resume/destroy/failure boundary and resource envelope. Reference host recursion is deliberately NOT the proposed Mo engine and is forbidden as the implementation.

V5's proposed 24-case balanced heldout layer and depth-5/three-function/four-argument generator bounds are not claimed fulfilled by the current private 500-case preparation. Keep the gaps visible; choose and validate exact coverage before lock. Private seeds/cases and new exact predictions must not be mounted into a builder context. Already public C-family counts cannot be made secret retroactively. This review export is for owner/reviewer, not builder reuse.

For large resource runs, propose streaming native primitive events/frame-heap peaks with predetermined observation checkpoints instead of dumping a million-cell graph each transition. Exact checkpoints and the narrower large-run observation claim need approval before freeze. No large run happened. Depth alone never proves no host stack; inspect explicit evaluator/cleanup paths and retain stack/frame evidence.

## Unresolved owner review choices; no competing approval question

1. Detailed grammar/names/type/ownership/transition rules below, including exact output/encoding/failure contract and observer integration. Recommend the retained finite-trial rules plus split Give up/Free and explicit fine-grained call transitions. True/false and growing integers are already approved; do not reopen them or add Boolean inputs/operators/equality.
2. Exact generated/heldout coverage and builder-visible material. Recommend preserving all Stage A snapshots, keeping newly private cases/predictions isolated, and completing the missing balanced/bounded coverage rather than lowering obligations silently.
3. Proposed million-depth/cleanup resource envelope and checkpoint schedule. This orb is selected; actual resources must be rechecked before eventual execution. Recommend recorded stack limit plus explicit-frame/source inspection; no all-depth theorem or performance claim.
4. Measurable contributor elapsed seconds convention and Stage A/B hard limits. Include build/tool waits, subtract only timestamped owner-wait/stopped intervals, sum concurrent contributors, separate prep/A/B rows. Prior aggregate prep time was not precisely recorded and must not be guessed from mtimes. Neither the old prep cap nor two-hour approval stops was adopted; reporting points are not caps.
5. Completion/approval of the exact candidate-independent checks, then a new scientific lock and separately authorized builder brief. Current checkpoint is INCOMPLETE final acceptance and authorizes none of those actions. Stage A passing would not automatically start Stage B.

No questions requiring routine repair permission are raised. The parent owns owner questions/register/issue-description updates and its all-issues audit. This thread stops at this review checkpoint and remains available; it is not archived.

## Retained detailed English rules — PROPOSED except explicit approved boundaries

The following proposed sections are reproduced from preserved v5 for review continuity. Their 'future' acceptance wording describes obligations, not an assertion that no preparation has since occurred. Authority/status/execution claims are governed by the v10 sections above. No historical model/criterion is amended.

## 2. Proposed common source grammar

This is experiment notation, not Mo's permanent syntax. The proposed deliberately small grammar retains the trial operators and adds program declarations, calls, finite list-literal sugar and the approved true/false literal capability. Stage A corpus and handwritten examples use the same program/parser entry point as Stage B. Stage A must-accept examples have an empty function table; the eventual Stage B frontend still accepts them without a mode flag.

```text
program  := inputDecl* functionDecl* "main" "=" expr EOF
inputDecl := "input" ID ":" inputType ";"
functionDecl := "def" ID "(" params? ")" ":" type "=" expr "end"
params := ID ":" type ("," ID ":" type)*
inputType := "Int" | "ListInt"
type := inputType | "Bool"
expr := "let" ID "=" expr "in" expr
      | "if" expr "then" expr "else" expr "end"
      | "match" expr "do" "[]" "->" expr ";"
          "[" ID "|" ID "]" "->" expr "end"
      | compare
compare := sum (("==" | "<" | "<=") sum)?
sum := atom (("+" | "-") atom)*
atom := INT | "-" INT | "true" | "false" | ID | ID "(" args? ")"
      | "(" expr ")" | "[]"
      | "[" expr "|" expr "]"
      | "[" expr ("," expr)* "]"
args := expr ("," expr)*
ID := ASCII letter or underscore, then ASCII letters/digits/underscores
INT := "0" | nonzero decimal digit followed by decimal digits
```

Whitespace separates tokens but is otherwise ignored; LF/CRLF are accepted, CRLF counts as one newline. A # comment runs through end of line. Reserved words/type names cannot be identifiers. Longest-token lexing distinguishes <= from < and -> from -. Operators + and - have equal precedence and associate left; comparisons have lower precedence and do not chain. Calls and bracketed/parenthesized forms are atoms. A control expression used as an arithmetic operand needs parentheses. Negative syntax is a signed literal, not general unary negation: -7 accepts, -(n) refuses. Signs are separate tokens, so 1-2 means subtraction without a whitespace exception. Leading-zero numerals, hexadecimal, exponents, decimal fractions, strings, Unicode identifiers, trailing commas and additional operators refuse. -0 has value zero.

**Approved feature boundary:** ordinary true/false literals exist, in addition to Boolean results from integer comparisons (D139, limited first-language feature-scope approval including Boolean literals). **Proposed spelling/type rules:** lowercase true and false are reserved whole-word literal tokens, have kind Bool, may be bound, used as conditions, passed to Bool parameters and returned. They are not names, integer 1/0 or truthiness conversions. A longer identifier such as trueish stays an identifier. No not/and/or, Boolean equality, Boolean top-level inputs or Boolean lists have been approved; this draft continues to exclude them. Even/odd may use true/false base branches; the earlier comparison-based and historical integer-answer versions remain separate examples, never rewritten historical records.

Finite literals are syntax sugar only: \[e1,e2,e3\] becomes \[e1 | \[e2 | \[e3 | \[\]\]\]\], \[e\] becomes \[e | \[\]\]. Item expressions evaluate left to right; actual cells are constructed inside-out after their operands finish. Parsing/checking never constructs managed list cells or precomputes list-valued expressions. Number objects used by the frontend are separately measured and are not list cells.

**Structure contract:** acceptance will freeze a tagged parsed-tree dump: Program ordered inputs/functions/main; declaration types and names; Int(decimal value), Bool(JSON true or false), Var(spelling), Add/Sub/Eq/Lt/Le, Nil, Cons, Let, If, Match(scrutinee, empty branch, head name, tail name, cell branch), Call(name, ordered arguments). Literal sugar is expanded before this canonical dump. A separate source-span map retains the original literal/child ranges. The corpus tree is obtained from the frozen wire expression by an acceptance-owned structural decoder, not by parsing the pretty-printer's output with the implementation. Pretty-printed source reparses to that tree; adversarial handwritten source tests precedence, parentheses, comments, spacing and nesting. Checked-tree inspection additionally verifies binding identities and resolved function identities, not just spelling. Acceptance independently resolves the decoded tree by lexical binding and declaration paths, then compares the implementation dump under a fixed correspondence; expected identities never come from that dump.

Example: main = 9 - 4 - 2 dumps Sub(Sub(Int(9),Int(4)),Int(2)) and answers 3, whereas main = 9 - (4 - 2) answers 7. A wire-token reader cannot satisfy these examples.

A concrete Stage B source example under this proposed grammar (empty input table):

```text
def bump(xs: ListInt): ListInt =
  match xs do [] -> []; [h | t] -> [h + 1 | bump(t)] end
end
main = bump([3, -2, 8])
```

It returns \[4,-1,9\]. Source construction creates three cells BEFORE bump entry; unique bump creates zero and writes those three cells on return. The whole-program count is therefore three creations, not zero. Reference helper bodies used below are one(n) = \[n | \[\]\], first(xs) = match xs do \[\] -> 0; \[h | t\] -> h end, choose(a,b) = a, and readBoth(a,b) = first(a) + first(b), with explicit Int/ListInt signatures in the future exact package.

## 3. Names, kinds and refusal rules

Names are case-sensitive: f and F are distinct, both may exist. Function names form a separate namespace from local/input names, so parameter f may coexist with function f; f is a local use and f(...) is a call. All functions are visible throughout the table, including before declaration, permitting mutual recursion. A function sees only its parameters and lexical locals, not main inputs, caller bindings or other functions' parameters. Input names are unique; function names are unique; parameters within a function are unique. Match head/tail names must differ. Local let/match shadowing is allowed and resolves to the nearest lexical binding; a let's new binding begins only in its body, not its initializer. Every execution binding/frame/branch has a fresh identity even if spelling repeats.

Int, Bool and ListInt are distinct, with no coercion/null. +, -, ==, <, <= take Int operands only. Cons takes Int head and ListInt tail. Match takes ListInt; its head binding is Int and tail ListInt. If takes Bool. Both branches must have the same kind. Let uses its initializer kind. Calls require exactly the declared number and ordered kinds of arguments; every function body must match its declared result, even an uncalled function. Main may return any of the three kinds. All names/types/bodies check before evaluation; a statically bad unreachable branch is still refused. No termination check, demands, higher-order calls, overloads, closures or inference beyond determining expression kinds under explicit input/parameter types.

**Must accept, Stage A:** all 4,276 serialized frozen cases with original inputs/starts; all original constructs; shadowing and initializer-scope examples; asymmetric arithmetic/precedence; empty and nested finite literals; Bool answers from comparisons and both literals; literal conditions/bindings; different valid whitespace/comments. Reject-everything must fail these.

**Must refuse, Stage A:** lexical/syntax errors, missing/duplicate match branches, unbound variable, duplicate input, identical match binders, non-Bool condition, unequal branch kinds, list arithmetic/comparison, non-Int head or non-list tail, unsupported literal/operator/type. Accept-everything must fail these. Stage A rejects syntactically valid declarations/calls as stage-unsupported: the span is the whole first function declaration, or the whole first call if there is no function declaration, in source order. This is a checkpoint capability refusal, not a permanent language prohibition. The same parser recognizes the forms; Stage B lifts this capability restriction without an alternative parser/runtime mode.

**Must accept, Stage B:** all Stage A accepts plus direct/mutual calls, all three parameter/result kinds, empty parameter lists, local/function same spelling, forward calls, case-distinct functions, uncalled well-typed recursion, and the C1–C14 execution families below. **Additional must refuse:** unknown function, duplicate function/parameter, wrong arity/argument kind/result kind, caller/main-local capture, function value used without a local binding, invalid parameter/result annotation. An ordinary well-typed aliased call is accepted; there is no demand checker whose usefulness verdict is being tested here.

**Diagnostic contract:** fixed refusal class plus exact smallest explanatory source range, not prose quality. Ranges are 1-based line/column, half-open, measured in Unicode scalar values; tabs count one column. Source with invalid encoding reports byte offset instead. Unknown variable/callee highlights its identifier; duplicate name highlights the second declaration's identifier; wrong condition/operand/tail/argument highlights that expression; arity highlights the entire call; unequal branches highlight the second branch expression; result mismatch highlights body expression; unexpected token highlights token; missing token highlights a zero-width insertion point. The future acceptance package enumerates exact ranges for every negative example and fixes multi-error priority: first lexical/syntax error in source order, otherwise first declaration/body error in source order, recursively left-to-right, then main. No implementation output supplies expected ranges.

Concrete one-line distinguishing examples (end column exclusive): main = ghost → unbound-variable, (1,8)–(1,13); main = if 3 then 1 else 2 end → condition-kind, (1,11)–(1,12); main = 1 + \[\] → operand-kind, (1,12)–(1,14); main = if 0 == 0 then 1 else \[\] end → branch-kind, (1,30)–(1,32). A whole-file-span reporter fails these. Exact multiline/tab/CRLF cases will be fixed before lock, not inferred from builder output.

## 4. Integers and observable output

**Approved prototype numeric meaning:** D140, exact growing integers for this prototype only, requires mathematical integer results without silent overflow, truncation or wrapping, preserving the trial meaning. D139, limited first-language feature scope including Boolean literals, still limits arithmetic to addition/subtraction; the proposed comparison set remains ==, < and <= on integers. No multiplication/division/remainder, new arithmetic operators or divide-by-zero construct is added. A fixed i128 backend rejecting an otherwise in-envelope valid wide result does not implement the approved meaning. Physical resource exhaustion is a distinct failure, not a substitute mathematical answer or observation suspension. Exact failure/cleanup rules and resource thresholds remain proposals. No permanent Mo numeric default, unlimited-resource execution, bounded arithmetic latency or performance superiority is approved.

Proposed wide examples, expectations derived by decimal arithmetic rather than runtime output:

| Main expression | Expected value |
| -- | -- |
| 340282366920938463463374607431768211456 + 7 | 340282366920938463463374607431768211463 |
| 0 - 340282366920938463463374607431768211456 | \-340282366920938463463374607431768211456 |
| 340282366920938463463374607431768211456 < 340282366920938463463374607431768211455 | false |
| let n = 340282366920938463463374607431768211456 in n - (n - 9) | 9 |

Also propose 1,024-bit decimal literals, mixed signs and list items beyond 128 bits, with independent decimal-string addition/subtraction expectations fixed by acceptance. Numeric allocation/bytes and frame/bookkeeping allocation are recorded separately from managed list-cell events. Zero new list cells never means zero heap allocation.

Public output proposal: one UTF-8 LF-terminated compact JSON line, fixed key order, integer values as canonical decimal strings. Finished: {"status":"finished","type":"Int","value":"9"}, Bool uses JSON true/false, ListInt uses an array of decimal strings. Suspended: {"status":"suspended","steps":"N"}; N is cumulative committed transitions, never an answer. Refused: status, class, span. Invalid fixture: status invalid-fixture, class and fixture field path. Failed: status failed, class and last committed step. Detailed event/state evidence is a separate versioned machine-readable stream; no raw pointers or timing data in deterministic public output. Two fresh runs compare public bytes and normalized traces, not ASLR-dependent addresses. Destroy/cleanup records are explicitly a separate phase, not added to successful evaluation counts.

## 5. Fixtures and Stage A compatibility are physical obligations

Acceptance installs original cell items/links/counts and input/outside holders using the same primitive storage/holder API as source construction. Installation is host-only, then its builder/metadata is discarded. Execution receives only the checked program and ordinary roots. No case ID, expected result, wire expression, fixture provenance bit or fixture graph-inspection callback is available. Inputs include original aliasing; do not copy into a unique graph. Valid starts are finite/acyclic, exactly reachable from inputs/outside roots, non-dangling and correctly counted. Invalid fixtures refuse before evaluation; rejection installation rolls back only newly owned fixture resources, not existing external holders.

Parse/check precede fixture/evaluation preparation and create zero list cells. Fixture construction is separately counted. Evaluation counting starts BEFORE unused-input preparation, retaining experiment 10's boundary; pre-evaluation copying cannot hide outside it. Main remains an expression, never wrapped in a synthetic function with entry cleanup.

Retain all 4,276 cases, all 27,721 frozen snapshots, answers/raw identities/final cells/counts, ordered primitive records and rule logs. No snapshot kind or field is omitted. Compare under one correspondence for the whole run, including cells, binding/branch identities, pending/outside holders, reservations, branch values and statuses. New interpreter transitions may add states; a fixed acceptance-owned projection maps mandatory reference landmarks (including branch chosen/start and before/after branch cleanup) to actual sampled runtime states, in order, without computing shadow states or renaming separately at each snapshot. A nonmatching mandatory landmark is a failure, not permission to omit it. If retaining this compatibility is infeasible, stop and seek owner review before changing the proposed obligation; the old checks always remain intact.

Physical creates/writes/frees are recorded inside the sole mutable cell implementation and matched one-for-one against the interpreter's claimed events. Snapshots read actual live storage and roots at those moments. Creation gets a monotonic lifetime identity; allocator address recycling creates a NEW identity. A reuse retains object address and lifetime identity and actually changes that object. A free destroys it. Identity/address continuity is required only while continuously allocated, including set-aside cells; freed cells need not survive to final memory. Acceptance independently walks protected values and counts at every committed state and verifies each physical primitive's precondition; a shadow reporter with shared physical mutation must fail.

Cross-route pair: bump on unique \[3,-2,8\] installed by fixture versus let xs = \[3,-2,8\] in bump(xs). Source creates three cells in construction order 8,-2,3; fixture separately installs three. Compare from bump entry, after parameter-holder transfer: the unique routes must have equivalent callee roots/storage and identical normalized cell-operation suffixes through bump return. Repeat with a source caller alias held for a later use and an outside-retained fixture. Their protected root owners differ, so compare protected contents/counts and callee cell operations through return, not byte-identical caller/outside-root states or whole-program cleanup. Source has no permanent outside-holder API. Whole-program prefixes and later cleanup retain their real route-specific differences.

## 6. Proposed precise call/ownership rules

Carry forward trial move-at-last-use and add-holder-if-used-again, left-to-right evaluation, branch pruning before match uniqueness test, detachment when setting aside, newest eligible reservation after both cons operands finish, and newest-first disposal at owning branch completion. Extend syntactic remaining-use analysis to explicit continuations and all unevaluated arguments, resolved by binding identity, not spelling; never assume what a callee will do. Suspended frames retain all needed roots, pending arguments and reservations.

Arguments evaluate completely in order, even if the callee will discard a parameter. Completed argument holders remain live until transferred at entry. A nonfinishing argument prevents later arguments and entry. Enter moves holders into fresh parameter bindings without copying and precedes entry cleanup. Unused parameters release in declaration order before body evaluation. Return follows body/branch cleanup and transfers the result holder exactly once to the caller. No caller locals become callee locals. No tail-call elimination or speculative early branch/reservation cleanup.

Reservations belong to a fresh (frame,branch) identity and are available only to cons operations in still-running lexical enclosing match branches in that same invocation. A helper cannot consume its caller's reservation, but may match an explicitly passed live list to obtain its own. Caller reservations remain allocated through callee execution and suspension. An endless branch can retain a reservation indefinitely; suspension is not a no-leak-at-completion assertion.

Event stream adds enter(frame,parent,function,call-site) exactly after final argument capture and BEFORE parameter setup/cleanup; return(frame,result-identity) exactly after callee cleanup/result transfer and BEFORE caller continuation. Top-level main is recorded as root execution but not a synthetic invocation. Frames are monotonic and never reused. Per-invocation creations are all physical create events between its enter and return (or observed prefix end), including descendant argument construction/entry and transient creations. An aborted frame emits abort, not return; suspend emits neither. Acceptance computes counts from boundaries, not a runtime-supplied net count. Explicit arguments precede that callee's interval but lie inside any active ancestor's interval.

## 7. Transition granularity makes suspension nonvacuous

Proposal: a deterministic evaluator uses a control item, value temporaries, explicit continuation/frame stacks and a queued cleanup list. One observation unit executes exactly one of the following transitions; the acceptance author freezes exact transition traces before builder work. No transition evaluates a child expression, recursively executes a call, or drains arbitrary cleanup.

| Transition | One committed action |
| -- | -- |
| Dispatch compound | Push its continuation; select first child. No child evaluation. |
| Leaf | Evaluate one numeral/Boolean-literal/empty-list/name; perform that name's move-or-add holder rule. |
| Operand capture | Move one returned operand into its waiting slot; select next child, or mark operation ready. For calls this captures ONE argument; last capture leaves enter pending. |
| Primitive result | Perform one arithmetic/comparison or ONE cons create/reuse after all operands are captured. |
| Bind | Transfer one initializer into its binding; queue unused-holder cleanup, then body dispatch waits for cleanup. |
| Choose branch | Fix chosen if/match branch; queue newly dead bindings oldest-first. No branch executes yet. |
| Match decompose | After pruning, unique case: detach one cell into reservation and tail binding, then expose matchStep4Done. Shared case: install head/tail bindings and, when needed, add ONE tail holder and expose newHolder; a later Give up holder transition removes the match holder; a separate Match complete transition exposes matchStep4Done. No child body executes. Queue unused-tail give-up AFTER matchStep4Done. |
| Give up holder | Remove ONE owning holder and decrement its cell count, then expose holderGivenUp. If the count becomes zero, the still-allocated cell is queued for Free cell; no free event occurs in this transition. No user expression runs before this cleanup task is serviced. |
| Free cell | Release ONE queued zero-count cell and emit its physical/logical free; transfer its old link holder to a pending cleanup temporary and expose cellFreed. Giving up that temporary is a later Give up holder transition. A detached unused reservation is freed by this transition without an old-link transfer. Cascade stays front before tail. |
| Match complete | After shared-case holder give-up and any required cleanup, expose matchStep4Done before unused-tail cleanup/body start. |
| Start | After initial unused-input cleanup, expose start and select main. Counting already began before preparation. |
| Branch start | After required entry cleanup, select chosen body and emit actual landmark snapshot. |
| Branch result/cleanup | Capture/protect branch value and expose before-cleanup landmark; queue reservations newest-first. Cleanup uses release transitions; a separate handoff exposes after-cleanup landmark. |
| Enter | Allocate fresh frame identity, append enter, transfer arguments to parameters, queue unused parameters. Body waits for cleanup. No list copies. |
| Return | After body/required cleanup, transfer result to caller and append return. Caller operand capture is a later transition. |
| Handoff/finish | One completed let/branch continuation hands its value on; root finish only once required cleanup ends and answer can be read. |

Each dispatch/capture/branch/cleanup/enter/return is observable even without a memory event. Required holder changes within one leaf/unique-decompose/cons/enter/return are finite atomic transactions; shared decomposition and give-up/free are split as stated above. A zero-count cell awaiting free remains allocated, retains its lifetime/address and old outgoing link holder, and is owned by the cleanup queue, not a reuse reservation. After free, that link is an ordinary pending cleanup holder. Snapshots show these real states; generic invariants account for cleanup-owned cells/pending links, rather than incorrectly requiring every intermediate allocated cell to be reachable from user roots alone. Required atomic transactions enforce valid ownership at their suboperations and record physical evidence. Only committed states permit suspension. Transition internals may not call user code; releases and frame disposal use iterative queues, not host recursion. Arithmetic on a large integer may take variable host time; this observation budget is NOT a time SLA or allocation cap.

A nonnegative budget counts additional committed transitions. Budget zero leaves state unchanged and reports suspended unless already terminal. At positive budget, execute at most that many; if final action reaches terminal exactly at the boundary report finished/failed, otherwise suspended. Failed/refused states cannot resume. Resuming suspended state adds to cumulative steps and preserves all state/event prefixes. Reobserving terminal state performs no work. A dispatch-only endless cycle is not acceptable correspondence for a program that should finish.

Acceptance will interrupt at EVERY transition boundary of each small finite distinguishing example, including after first argument capture/before second evaluation, after reservation detachment, after each cleanup free, inside callees, before enter, before return and before finish. For each join, saved event bytes remain unchanged and resumed events equal the independently predicted remaining suffix. The physical logger never resets/replaces its prior record; work performed during resume must itself match that suffix. Observe surviving cells' addresses/lifetime IDs on both sides of each join, not only final survivors. A cell legitimately freed later may disappear; any still-live cell must remain the same object. Compare resumed to fresh uninterrupted runs under normalized correspondence, not raw cross-run pointers. Reinstall/replay, hidden counter reset, enlarged-budget restart and call-boundary-only suspend controls must fail.

## 8. Proposed distinguishing predictions, derived from English rules

These are draft predictions for review, not executed results or frozen checks. The separate acceptance author owns full ordered predictions, intermediate roots/states and counters BEFORE seeing builder output. A plain immutable-value reference supplies answers; ownership/event predictions come from the above rules and concrete initial holder tables, not from that answer reference or the interpreter. No mandatory additional predictor author/model is proposed.

Let bump(xs) match empty to empty and \[h|t\] to \[h+1|bump(t)\]; sum similarly returns h+sum(t). For a three-cell unique fixture A(3)→B(-2)→C(8), each count one, bump detaches A/B/C on descent and reuses C/B/A on return. No fresh cells and no frees during evaluation; answer \[4,-1,9\] begins at A. With outside root A, counts A=2,B=C=1 initially, every recursive tail gains protection from its old incoming link; no cell is eligible. Three fresh cells constructed in return order (9,-1,4), zero writes/frees; old A→B→C remains \[3,-2,8\]. Always-copying fails the unique case; shared-mutation fails the retained case.

| Family from calls draft | Proposed discriminating expectation |
| -- | -- |
| C1 caller matches unique \[1\], branch one(h) | one creates fresh D; caller later frees A reservation. Answer D. 1 create, 0 writes, 1 free. Helper cannot steal A. |
| C2 caller builds a cons with head h and tail one(h) | Helper creates D, caller writes A pointing to D. 1 create, 1 write, 0 frees; answer A. Identity/order distinguishes policies. |
| C3 choose(xs,bump(xs)), xs=\[1,2\], choose returns first | First completed argument protects old graph. bump creates 2, writes 0; unused second parameter releases new head then tail at entry. 2 frees; original answer unchanged. |
| C4 let changed=bump(xs) in first(changed)+first(xs), xs=\[1,2\] | Answer 3, old caller input unchanged while needed; bump creates 2, writes 0. At final scalar completion all 4 cells have been freed if no outside roots. Exact interleaving to be predicted before lock. |
| C5 readBoth(xs,xs)=first(a)+first(b), \[1,2\] | Answer 2; 0 creates/writes, 2 frees by scalar completion. Aliasing alone is not an allocation violation. |
| C6 cells A (item 1, link B), B (item 2, empty tail); inputs xs=A, ys=B | In let changed=bump(xs) in first(changed)+first(ys), answer 4. A reused, B protected; 1 create, 1 write; all 3 cells eventually freed without outside holders. |
| C7 makeThenDrop(n)=let unused=one(n) in 0 | 1 create and 1 free within makeThenDrop; no final cells. A net-growth counter fails. |
| C8 identity(\[1\]) | Global create occurs BEFORE identity enter; identity creates 0; result cell survives evaluation. |
| C9 outer(n)=identity(\[n\]) | outer interval contains 1 create; identity contains 0. Entry cannot precede explicit argument construction. |
| C10 bump/sum, empty/singleton/long unique and retained | sum \[3,-2,8\]=9; unique sum reserves then frees C/B/A at branch returns, 0 creates/writes. bump prediction above. |
| C11 even/odd, 0,1,2,7 | Bool answers true,false,true,false; 0 cell operations, distinct fresh invocation identities. |
| C12 spin(0) | All finite nonterminal prefixes suspended, 0 cell operations; observation is not a divergence proof. |
| C13 allocateForever(0) | Each completed iteration creates then frees one cell; observation mid-iteration may show one live transient cell. Cumulative creates grow despite small live heap. |
| C14 match unique \[1\], cell branch spin(h) | A stays allocated/set-aside with (caller,branch) identity throughout prefixes; no premature free or fabricated return. Destroy frees A. |

No C1–C14 execution/accounting question is dropped. Historical demanded/checker/proof verdicts are not imported into a milestone with no demand checker. Additional nested-match examples fix newest-first choice within one call, shared tails, unused-parameter declaration-order cleanup, returned temporary protection, and literal construction under a caller reservation. Example: one reserved A and branch \[4,9\] builds 9 first using A, then allocates the new head; swapping construction order gives equal values/counts but wrong cell identity.

## 9. Finish, failures, destroy and resource envelope

Source refusal is a frontend outcome with no run and zero managed-list evaluation events. Invalid fixture is a pre-run host-input refusal, not a syntax error. Suspension means budget exhaustion only, preserving state and holders. Host resource exhaustion is failed/resource-exhausted, never suspended. Execution ownership violation is failed/invariant; unreadable answer is failed/readback with raw answer and failure evidence retained, never \[\]. For valid in-envelope must-finish cases, none is an acceptable substitute for finished. No normal source-level dynamic arithmetic error exists in the proposed operator set.

On failure preserve last committed state/events and the failed operation; expose that failure before destruction. Fatal allocator/process failure that prevents safe reporting is recorded by the harness as abnormal termination, not a fabricated recoverable status. Acceptance-controlled allocator failure fails the Nth managed allocation before its side effects; acceptance chooses N across relevant execution/allocation boundaries, including fixture setup, nested call argument construction and literal construction. Numeric/frame allocations require separately identified hooks if tested. The builder cannot choose the injection sites or redefine N. This exercises honest classification/cleanup but does not prove arbitrary operating-system OOM recovery. Invariant-damaged states cannot safely follow corrupt links: destruction uses the actual live-object registry for still-owned storage, preserves externally held objects, and reports inability to reclaim safely as failed cleanup rather than certifying success.

Destroying finished, suspended or safely failed runs gives up every run-owned binding/temporary/answer holder and detached reservation exactly once, iteratively. Snapshot/event observation has no holders. Independent host/outside holders are never given up by run destruction. Remaining cells must be exactly those reachable from outside roots with correct counts and unchanged readable values; no outside roots means zero managed cells. Repeated destroy is a no-op. Evaluation, destroy and eventual host-fixture teardown have separate counters; successful answer ownership remains until destroy. Test destruction at every small-example boundary, plus finished/failed/refused/invalid fixture and returned shared tail. Detect leaks, double free, answer released before read and outside-holder damage.

**Proposed measurable recursion envelope, not approved:** non-tail sum over 1,000,000 unique cells (all 1) must finish with answer 1,000,000; also iterative cleanup of a discarded million-cell list must finish. Dedicated run: at least 4 GiB available memory, 8 MiB host stack limit, 600-second harness watchdog and a 100,000,000-transition observation allowance. Harness timeout is experiment failure/partial evidence, not language suspension. Report actual frames/peak managed cells/system bytes, stack configuration and elapsed time. Robert selected this Amp orb, with a larger Amp orb permitted if resources are needed. The inspection recorded in P4 supports this orb’s initial memory/stack provisioning. Recheck adequate resources on the actual execution orb before committing this envelope; do not reduce depth after a failure. If resources are unavailable, bring a revised envelope to Robert BEFORE lock.

Depth alone does not prove no host-stack dependence: inspect the explicit-frame evaluator/cleanup paths, run under the recorded stack limit and retain frame-state evidence. Passing establishes bounded evidence in this envelope, not all-depth safety or a theorem. Smaller budgets still suspend this program mid-expression and can resume. A stack-overflow implementation fails even if it labels the crash resource exhaustion. No speed superiority or production SLA is claimed.

## Review lineage

[Preserved v5 rules](<https://linear.app/robert-guss/document/rob-1333-v5-approved-exact-prototype-integers-proposed-acceptance-5eece5c832ec>), including the thirteen-kind landmark table in P1; [preserved v9 decimal failure](<https://linear.app/robert-guss/document/rob-1333-v9-span-correction-verified-trace-projection-decimal-42c676770e1b>); [Fable initial full review](<https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and#comment-df80ec4f>); [Fable v2 full review](<https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and#comment-9719d936>). Review agreement is not owner approval. No additional reviewer/author/process layer was introduced.
