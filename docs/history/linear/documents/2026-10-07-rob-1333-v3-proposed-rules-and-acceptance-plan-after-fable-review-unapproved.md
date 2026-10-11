# ROB-1333 v3 — proposed rules and acceptance plan after Fable review (UNAPPROVED)

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/document/rob-1333-v3-proposed-rules-and-acceptance-plan-after-fable-review-244d9ffcee25
> Created: 2026-10-07
> Updated: 2026-10-07
> Author: Robert Guss
> Attached to: ROB-1333

---

# [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and) v3 — proposed rules and separate acceptance plan

**PROPOSED / UNAPPROVED — 7 October 2026. Reviewable English plan only; not a builder brief, executable acceptance package or lock.**

Robert authorized proposal preparation. D137, Fable reviews plans only and a separate Amp thread prepares acceptance, assigns this thread acceptance preparation; Fable is neither author nor executor. Only four experimental call constraints are already approved: D127, call-local reservations; D128, unrestricted recursion with resumable bounded observations; D129, continuous live-value protection; D130, counting creations from entry after explicit arguments, including entry, descendants and transient cells. Every detailed rule and numerical/resource/effort choice below remains a proposal. Historical model, trials, predictions and locks remain unchanged.

**Immediate stop condition:** publish this revised plan and unresolved owner choices on [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and), notify the parent, and stop. No implementation, executable checks, lock, Fable invocation, push, merge, trial or deployment. The existing issue description remains v1 history. This document is v3, superseding the proposed v2 for review only, not an amendment of full 3c. V2 remains preserved at [https://linear.app/robert-guss/document/rob-1333-v2-proposed-rules-and-separate-acceptance-plan-unapproved-ec72e7c3afc4](<https://linear.app/robert-guss/document/rob-1333-v2-proposed-rules-and-separate-acceptance-plan-unapproved-ec72e7c3afc4>).

## 1. The result and the two gates

One genuine source parser produces a checked intermediate form; one explicit-state interpreter evaluates it. Stage A compares call-free programs with the frozen finite Lean/Rust corpus. Stage B extends that same interpreter with first-order named functions, direct/mutual recursion and suspension between expression operations. Stage A alone is a checkpoint, not delivery of the recursive capability.

Source → common parsed tree → name/type checking → checked program → explicit execution state → finished, suspended or failed.

Input declarations are a test facility; a standalone program uses literals and has no input declarations. The test-only fixture supplies starting cells/holders, never an expression or expected answer. There is no corpus reader in the implementation, case-ID dispatch, alternate runtime mode or source-to-prewritten-example route. Stage A approval and execution, then Stage B go-ahead, remain separate owner gates. The later exact acceptance package must be reviewed, approved and fingerprinted before builder work. This plan does not grant any of those gates.

## 2. Proposed common source grammar

This is experiment notation, not Mo's permanent syntax. The proposed deliberately small grammar retains the trial operators and adds only program declarations, calls and finite list-literal sugar. Stage A corpus and handwritten examples use the same program/parser entry point as Stage B. Stage A must-accept examples have an empty function table; the eventual Stage B frontend still accepts them without a mode flag.

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
atom := INT | "-" INT | ID | ID "(" args? ")"
      | "(" expr ")" | "[]"
      | "[" expr "|" expr "]"
      | "[" expr ("," expr)* "]"
args := expr ("," expr)*
ID := ASCII letter or underscore, then ASCII letters/digits/underscores
INT := "0" | nonzero decimal digit followed by decimal digits
```

Whitespace separates tokens but is otherwise ignored; LF/CRLF are accepted, CRLF counts as one newline. A # comment runs through end of line. Reserved words/type names cannot be identifiers. Longest-token lexing distinguishes <= from < and -> from -. Operators + and - have equal precedence and associate left; comparisons have lower precedence and do not chain. Calls and bracketed/parenthesized forms are atoms. A control expression used as an arithmetic operand needs parentheses. Negative syntax is a signed literal, not general unary negation: -7 accepts, -(n) refuses. Signs are separate tokens, so 1-2 means subtraction without a whitespace exception. Leading-zero numerals, hexadecimal, exponents, decimal fractions, strings, Unicode identifiers, trailing commas and additional operators refuse. -0 has value zero.

Proposed Boolean policy: no true/false literals, no not/and/or, no Boolean equality, no Boolean top-level inputs. Bool values arise from integer comparisons, can be bound, passed to functions and returned. Thus even/odd may return (0 == 0)/(0 == 1); the old integer-answer version remains a separate example, not silently rewritten history. This avoids adding Boolean expression forms beyond the trial. Bool lists refuse.

Finite literals are syntax sugar only: \[e1,e2,e3\] becomes \[e1 | \[e2 | \[e3 | \[\]\]\]\], \[e\] becomes \[e | \[\]\]. Item expressions evaluate left to right; actual cells are constructed inside-out after their operands finish. Parsing/checking never constructs managed list cells or precomputes list-valued expressions. Number objects used by the frontend are separately measured and are not list cells.

**Structure contract:** acceptance will freeze a tagged parsed-tree dump: Program ordered inputs/functions/main; declaration types and names; Int(decimal value), Var(spelling), Add/Sub/Eq/Lt/Le, Nil, Cons, Let, If, Match(scrutinee, empty branch, head name, tail name, cell branch), Call(name, ordered arguments). Literal sugar is expanded before this canonical dump. A separate source-span map retains the original literal/child ranges. The corpus tree is obtained from the frozen wire expression by an acceptance-owned structural decoder, not by parsing the pretty-printer's output with the implementation. Pretty-printed source reparses to that tree; adversarial handwritten source tests precedence, parentheses, comments, spacing and nesting. Checked-tree inspection additionally verifies binding identities and resolved function identities, not just spelling. Acceptance independently resolves the decoded tree by lexical binding and declaration paths, then compares the implementation dump under a fixed correspondence; expected identities never come from that dump.

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

**Must accept, Stage A:** all 4,276 serialized frozen cases with original inputs/starts; all original constructs; shadowing and initializer-scope examples; asymmetric arithmetic/precedence; empty and nested finite literals; Bool answers from comparisons; different valid whitespace/comments. Reject-everything must fail these.

**Must refuse, Stage A:** lexical/syntax errors, missing/duplicate match branches, unbound variable, duplicate input, identical match binders, non-Bool condition, unequal branch kinds, list arithmetic/comparison, non-Int head or non-list tail, unsupported literal/operator/type. Accept-everything must fail these. Stage A rejects syntactically valid declarations/calls as stage-unsupported: the span is the whole first function declaration, or the whole first call if there is no function declaration, in source order. This is a checkpoint capability refusal, not a permanent language prohibition. The same parser recognizes the forms; Stage B lifts this capability restriction without an alternative parser/runtime mode.

**Must accept, Stage B:** all Stage A accepts plus direct/mutual calls, all three parameter/result kinds, empty parameter lists, local/function same spelling, forward calls, case-distinct functions, uncalled well-typed recursion, and the C1–C14 execution families below. **Additional must refuse:** unknown function, duplicate function/parameter, wrong arity/argument kind/result kind, caller/main-local capture, function value used without a local binding, invalid parameter/result annotation. An ordinary well-typed aliased call is accepted; there is no demand checker whose usefulness verdict is being tested here.

**Diagnostic contract:** fixed refusal class plus exact smallest explanatory source range, not prose quality. Ranges are 1-based line/column, half-open, measured in Unicode scalar values; tabs count one column. Source with invalid encoding reports byte offset instead. Unknown variable/callee highlights its identifier; duplicate name highlights the second declaration's identifier; wrong condition/operand/tail/argument highlights that expression; arity highlights the entire call; unequal branches highlight the second branch expression; result mismatch highlights body expression; unexpected token highlights token; missing token highlights a zero-width insertion point. The future acceptance package enumerates exact ranges for every negative example and fixes multi-error priority: first lexical/syntax error in source order, otherwise first declaration/body error in source order, recursively left-to-right, then main. No implementation output supplies expected ranges.

Concrete one-line distinguishing examples (end column exclusive): main = ghost → unbound-variable, (1,8)–(1,13); main = if 3 then 1 else 2 end → condition-kind, (1,11)–(1,12); main = 1 + \[\] → operand-kind, (1,12)–(1,14); main = if 0 == 0 then 1 else \[\] end → branch-kind, (1,30)–(1,32). A whole-file-span reporter fails these. Exact multiline/tab/CRLF cases will be fixed before lock, not inferred from builder output.

## 4. Integers and observable output

Recommend exact arbitrary-size signed integers for this bounded prototype, preserving the trial meaning. Only addition/subtraction and the three integer comparisons are present; no multiplication/division/remainder or divide-by-zero rule is smuggled in. No overflow, wrap, truncation or i128 rejection on well-formed in-envelope input. This is not selection of permanent Mo arithmetic or unlimited host resources.

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
| Leaf | Evaluate one numeral/empty-list/name; perform that name's move-or-add holder rule. |
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

## 10. Acceptance package to prepare only after owner review

Later preparation would produce: exact grammar/parsed/check dump formats and source-span tests; common pretty-printer/structural decoder; immutable pinned Stage A corpus/reference adapter with all snapshots; concrete Stage B source/initial graphs; complete independently derived answer/event/state/transition predictions; answer reference plus ownership/event checker; fixture/physical instrumentation/resume/destroy interface; resource protocol; refusal sets; source controls; reproducible commands/fingerprints. This is a list of future deliverables, not authorization to write them now.

Required real controls on valid relevant inputs: shared physical mutation (including shadow-model reporting), premature free, unreleased tail, always-copying, hidden preparation copy, wrong lexical scope, fixture provenance leak, frontend preallocated literal, caller-reservation theft, lost pending/caller holder, incorrect reservation order/early cleanup, omitted entry/nested/transient creates, early enter, skipped return cleanup, replay/reset on resume, call-boundary-only suspension, suspended-as-finished/resource-failure-as-suspended, accept-all/refuse-all, whole-file spans and fixed-i128 arithmetic. Controls compile and exercise intended paths; each must fail the obligation it targets, not merely crash or fail an unrelated check. A deliberate physical leak/drop defect must fail destruction checks. Preserve exact control sources/outcomes and all failed candidates; never retune predictions to fit them.

Final later evidence would include clean build, pinned unchanged fingerprints, Stage A rerun on final Stage B implementation, every must-accept/refuse result, actual physical state/event validation, every resume join/cleanup state, resource-envelope result, control reasons and unresolved limitations. Finite success is not a universal memory-safety/refinement/termination proof. Acceptance author never implements Mo or changes accepting checks to accommodate builder output. Fable may review the plan only when Robert brings it; no additional review layer is required here.

## 11. Effort is measurable only after Robert chooses its rule

All previous 8/12/20/40-hour numbers and two-hour suggestions remain UNAPPROVED. No historical proof interval is active. A report is not permission to continue past a cap; an approval interval is not inferred from a report cadence.

Proposed convention: elapsed wall-clock contributor time, from explicit authorized brief/start timestamp to stop timestamp, inclusive of tool/build/test/debug waits. Pause only for a recorded owner-wait or explicitly stopped task, with timestamps/reason; not for inconvenient computation. Sum concurrent contributor intervals separately. Track preparation, Stage A and Stage B in separate ledger rows; stage implementation totals include implementation fixes and separate acceptance execution/reporting, so parallelism cannot hide effort. This is elapsed engaged-session time, not estimated model thinking time or token counts. The current draft's interval is evidence of proposal work, not debited against an unapproved execution cap.

Recommendation: retain a hard preparation stop for initial containment rather than quietly replace it with unlimited preparation. Robert could keep the v1 8-hour preparation/12-hour A/20-hour B caps, or approve a larger preparation cap after reviewing this scope. At a preparation cap, deliver incomplete coverage and request more time; never thin acceptance or lock unfinished rules. Fable's alternative caps builder stages and uses a 16-hour acceptance-preparation reporting point rather than an automatic preparation stop. This is a reporting-point proposal, not a spending cap or an implied general authorization; Robert must explicitly choose the preparation continuation/spending boundary. A total 40-hour cap conflicts with raising prep to 16 while preserving 12/20; Robert must choose revised totals/no-borrowing explicitly.

Optional two-hour progress reports can state usage, completed/unmet checks and defects without requiring approval each time. A two-hour stop-and-reauthorize arrangement is a different owner choice. Neither is currently accepted. Stage B stopping with only call-boundary suspension is partial/unmet, never a redefined success. Stop earlier for ambiguous rules, reference failure, changed fingerprint, counterexample or unauthorized scope; preserve evidence and ask one concrete owner question.

## 12. Owner choices, in review order (no assumed answers)

These are unresolved choices to take one at a time, not a multi-question approval request and not recorded decisions.

**Q1 — Experimental rules/syntax scope.** Recommend sections 2–3/6–7: one Ruby/Elixir-like notation, trial-only arithmetic/Boolean forms, finite-list sugar, separate function/local namespaces, explicit types and fine-grained transitions. Alternatives include true/false literals and Boolean inputs (Rust/Python-like broader core), Boolean operators/equality (larger grammar/type/reference burden), or retaining strict cons-only literals (smaller frontend, less convenient examples). Calls can instead share a single namespace with locals (fewer ambiguities but more refusals), or use higher-order function lookup (outside this first-order scope). None has agent-effectiveness evidence here; test grammar/structure and distinguishing examples first, defer syntax superiority/agent study.

**Q2 — Numeric semantics.** Recommend exact integers for the prototype to keep Lean arithmetic meaning. Checked i64/i128 (Rust-style) gives explicit overflow/refusal and less growth; wrapping (explicit Rust wrapping operations) changes arithmetic meaning; fixed integers plus explicit big type (Rust-like explicit libraries) adds types/conversions. Any fixed policy requires an explicitly reviewed Stage A compatibility account, not silent discarded cases. Experiment 11 supports only its measured workloads, not a permanent Mo default.

**Q3 — Compatibility and resource envelope.** Recommend retaining every frozen Stage A snapshot with actual-state landmarks and the proposed million-depth explicit-frame envelope. Alternative is a new explicitly narrower snapshot contract for this milestone, preserving old checks separately; it weakens this proposed compatibility claim and needs Robert's approval. Smaller resource envelope reduces cost but produces weaker recursion evidence; depth alone is never a stack-independence proof. Confirm available resources before freeze.

**Q4 — Effort unit/caps/continuation.** Recommend measured contributor elapsed time and explicit hard stage/preparation stops, with optional reports distinct from approvals. Keep 8/12/20/40, raise preparation with a revised total, or choose reporting-only/no-prep-cap deliberately. Decide whether reports permit continuation within a cap or every interval stops for approval; two-hour approval intervals have not been accepted. No proposed number is a reliable completion estimate.

**Q5 — Next authorization.** After plan review, Robert must explicitly authorize exact acceptance preparation; then separately approve the finished package/lock and Stage A builder brief. Passing Stage A does not start Stage B. No such authorization is sought or assumed by publication of this draft.

Risks earliest visible in preparation: snapshot landmarks cannot reproduce frozen holder states; transition rules admit differing predictions; million-depth envelope exceeds resources on the confirmed execution machine; fine-grained resumption exceeds containment. These mean stop/revise with owner review, not omit tests. The acceptance author assignment itself is settled by D137, separate Amp acceptance preparation and Fable plan-only review; it is not an open choice again.

## 13. Provenance and exclusions

Read: current Start here; live register including corrected D136, Fable-authorship mistaken interpretation, and D137, separate Amp acceptance preparation/Fable plan review; [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and) description and full review comment df80ec4f-93aa-4c5d-8ec0-07392cd07588; calls draft C1–C14; origin/main fetched at 03705f1dac1de8cbc9efedaf99ad4feeb62c17a3. Working tree was clean; no local change transferred or made.

Pinned sources: [finite bridge SPEC](<https://github.com/robertguss/mo-v2/blob/a22831f823d2ac7ccbb8726a8d4418fbceb233e0/experiments/10-finite-rust/SPEC.md>), [exporter/structural corpus](<https://github.com/robertguss/mo-v2/blob/a22831f823d2ac7ccbb8726a8d4418fbceb233e0/experiments/10-finite-rust/Export.lean>), [trial English RULE](<https://github.com/robertguss/mo-v2/blob/e6a895c8ce2887d9bee6986819a779f8f74b5541/experiments/03c-checker/trial/RULE.md>), [trial INTERFACE and snapshots](<https://github.com/robertguss/mo-v2/blob/e6a895c8ce2887d9bee6986819a779f8f74b5541/experiments/03c-checker/trial/INTERFACE.md>), [integer-policy result](<https://github.com/robertguss/mo-v2/blob/03705f1dac1de8cbc9efedaf99ad4feeb62c17a3/experiments/11-integer-policies/RESULT.md>), [calls draft](<https://linear.app/robert-guss/document/full-3c-calls-and-recursion-specification-draft-5-october-73682eae811b>), [Fable review](<https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and#comment-df80ec4f>).

This plan excludes new Lean proofs/demand checker/Koka gates; it neither replaces nor certifies full 3c. Native compilation, processes, concurrency, hot reload/code versions, I/O other than output, strings/records/other lists, host answer-handle API, error-explanation quality, performance superiority and agent studies remain outside. Project goals stay intact. The parent's all-issues audit remains its task. No executable verification was run: this is a proposed acceptance plan, not acceptance evidence.

## 14. V3 review corrections and preparation gates (PROPOSED, NOT RUN)

Read the full [Fable v2 review](<https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and#comment-9719d936>). The reviewer reports re-deriving the fourteen C predictions, bump counts and four spans without finding errors; this is reviewer evidence, not an executed acceptance result. V3 fixes the reported release contradiction and records the remaining deliverables as gates. Owner choices Q1–Q5 remain unresolved; review agreement is not owner approval.

### P1 — A proposed landmark table must be validated before the brief

There are thirteen snapshot kinds in the approved corpus, not a required one-to-one match to thirteen evaluator transition kinds. The Lean StepKind enum also contains holderForgotten for a deliberately broken variant; it is not an approved-corpus kind. Several transition phases can project to the same kind, and internal dispatch/capture states project to no Lean landmark. Exact transition predictions and the landmark projection are frozen together: extra states mean the specified non-landmark transitions, not builder-invented steps.

| Lean corpus kind | Proposed actual-state landmark |
| -- | -- |
| start | Start after unused-input preparation/cleanup, before main evaluation |
| holderMoved | Leaf name use moving its holder to pending user |
| newHolder | Leaf repeated name use OR shared Match decompose adding the tail holder; preserve which operation/source/frame caused it |
| nameBound | Bind when a nonempty list initializer is transferred to a holding binding; unused binding cleanup follows |
| branchChosen | Choose branch before dead-binding releases |
| holderGivenUp | Give up holder after count decrement, BEFORE zero-count free |
| cellFreed | Free cell after physical release, with old link now in pending cleanup, or detached reservation disposal |
| matchStep4Done | Unique Match decompose, or shared Match complete after matched-holder give-up; BEFORE unused-tail release |
| branchStarts | Branch start after dead-binding/match/unused-tail cleanup, before evaluating the body |
| newCellBuilt | Primitive result after ONE cons allocation or write, with result holder and moved tail link |
| branchValueWorkedOut | Branch result capture before reservation disposal, with observed branch value but no extra observation holder |
| branchValueHandedOn | Branch handoff after reservation disposal, with observed branch value |
| end | Root finish with answer pending for caller, after required cleanup |

**Future acceptance-preparation deliverable:** derive the proposed source-driven call-free transition states independently from the English rules/decoded corpus, execute the projection against every one of the 4,276 cases and 27,721 frozen snapshots, and retain a per-case/per-snapshot report including every field and one whole-run identity correspondence. Do not validate only kind counts or fabricate copied reference states. Check primitive event order as well. Zero missing/extra required landmarks or field mismatches is the proposed criterion. This run must finish BEFORE the builder receives its brief. It has NOT run during this plan-only revision. If it fails, preserve the mismatch and return the compatibility choice to Robert before lock or builder work.

### P2 — Held-out examples and generated calls test unseen compositions

Keep the public C1–C14 families as visible capability examples. Separately propose at least 24 held-out Stage B cases with concrete source/fixtures, balanced across nested calls/arguments, lexical shadowing, shared heads/tails, overlapping aliases, returned temporaries, reservation nesting, mutual recursion and destruction/resume boundaries. Acceptance fixes these from the rules before builder work; they are not shown to the builder until the candidate is delivered. Held-out exact programs/expected traces are not written in this publicly visible plan. General categories are public.

Add a proposed fixed-seed generator producing 500 small well-typed call-bearing programs/starts, maximum expression depth 5, at most 3 functions and 4 arguments per call, with input lists of length 0–4 and asymmetric signed integers. Every retained case must execute at least one call; include nested/mutual calls and shadowed binding identities, not only call-free expressions wrapped in identity. Seed and exact generated corpus remain acceptance-private until candidate delivery; fingerprint them BEFORE builder access, not after observing failures. Use a bounded terminating subset (acyclic call graph or explicitly decreasing bounded counter/list recursion) for must-finish answer/cleanup predicates; separate recursive nontermination candidates get only prefix safety checks and an honest suspended/finished classification, never a fabricated answer-reference termination claim. Budget and duplicate-removal policy are fixed before lock. Numbers 24/500/depth 5 are new unapproved containment proposals, not achieved coverage.

For generated finite cases use generic predicates, with no expected detailed trace: answer equals the independent immutable-value reference; every protected live value remains unchanged at each committed state; holder counts include user roots, cell links, temporaries and queued cleanup; no dangling read/reuse of protected storage; physical and logical events agree; finished storage is exactly reachable from answer/outside roots with correct counts and no reservations/cleanup tasks. Check split-run versus uninterrupted normalized suffix/state and destruction at selected generated boundaries. These predicates do not replace C-case exact event predictions: always-copying can satisfy generic safety while violating the specified reuse counts. Record generation coverage, executed cases, suspensions, failures and retained counterexamples; no silent filtering of a difficult valid case. A generic checker accepting corrupted ownership or wrong answers must fail negative controls. This is bounded evidence, not protection against every possible unseen program.

### P3 — Builder visibility is an explicit brief boundary

Builder receives approved English rules/grammar/interfaces, public example source and answers, refusal classes, and the four worked span examples. Builder does NOT receive the private event/transition predictions, additional exact span tables, held-out cases, generated seeds/corpus, or exact control implementations/triggers until candidate delivery. Separate acceptance files are not mounted into the builder checkout/context; later failed checks provide the concrete counterexample needed for repair, preserving the frozen original. No extra author/model is needed.

**Honest limitation:** v1/v2 and this review already publicly describe C counts and control categories. That disclosure cannot be undone. The privacy rule governs newly authored exact predictions/controls and held-out material; it is not a claim that a builder reading [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and) has never seen any prediction. The later brief records exactly what was shared. Do not pretend keeping the source of checks private establishes independence if it was already supplied.

### P4 — Resource confirmation and owner choices still block execution

**Owner environment choice, 7 October 2026:** Robert said “this amp orb or a larger amp orb if you need the resources” in [the acceptance thread](<https://ampcode.com/threads/T-01a11697-f670-71bc-bd5d-f6f57958fa55>). Use this orb first; a larger Amp orb is permitted if necessary. This settles the environment choice only, not semantic rules, resource-test thresholds, effort caps or acceptance execution. The parent owns recording the decision in the live register.

Read-only inspection on this orb: Linux 6.1.158+ x86_64; 8 online CPUs; total memory 16,785,420,288 bytes and available memory 16,274,792,448 bytes at inspection; no swap. The effective workload cgroup memory.max is 15,032,385,536 bytes (14 GiB), memory.current 145,260,544 bytes at inspection, memory.high max; examined ancestors have no smaller visible cap. Process soft stack limit is 8,388,608 bytes (8 MiB), hard stack unlimited; data/address-space limits unlimited. Rust 1.98.1 and Cargo 1.98.1 are present. Commands: free -b, /proc/self/cgroup plus ancestor memory.max/current/high, /proc/self/limits, ulimit -s, getconf and toolchain version queries. No secrets printed or environment changes made.

This exceeds the proposed 4 GiB initial resource floor and matches the proposed 8 MiB stack limit; **no larger orb is needed on provisioning evidence now**. It does not demonstrate that the actual million-depth implementation fits or finishes within the proposed watchdog/transition allowance. Recheck available memory/cgroup/stack limits immediately before the later authorized run, record toolchain/configuration, and preserve the actual test outcome. If resizing becomes necessary, retain failed/incomplete evidence and inspect the replacement orb; do not reuse this host’s measurements for it or silently change thresholds. Machine inspection is distinct from running the million-depth acceptance case, which remains unauthorized.

Six blocker dispositions: (1) Q1–Q5 stay pending owner answers; (2) Give up holder and Free cell split in proposed English rules; (3) landmark table now written, full-corpus validation pending authorized preparation; (4) held-out/generated layer proposed, exact cases/checks not authored; (5) builder visibility rule specified with prior-disclosure limitation; (6) machine selected by Robert and initial memory/stack provisioning inspected; actual million-depth execution remains pending authorization. No completed gate is claimed from prose alone.

Optional fixes incorporated without new process: acceptance-owned resolution expectations, named Stage A unsupported-form refusal, acceptance-controlled allocation failure, input declarations described as fixtures, and corrected corpus-reader/preparation-cap wording. No mandatory second-reader session is added. That optional ambiguity check remains Robert’s choice if wanted.
