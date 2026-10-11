# ROB-1333 v11 — candidate-independent closeout, evidence and remaining review gates

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/document/rob-1333-v11-candidate-independent-closeout-evidence-and-remaining-a7a30569a722
> Created: 2026-10-07
> Updated: 2026-10-07
> Author: Robert Guss
> Attached to: ROB-1333

---

# [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and) v11 — candidate-independent closeout; final review stop

**PREPARATION REVIEW CANDIDATE, NOT ACCEPTED SCIENTIFIC ACCEPTANCE. Detailed rules/formats/thresholds remain PROPOSED. No Mo implementation or resource run.**

## What is delivered and what Robert still decides

The requested bounded closeout after [v10](<https://linear.app/robert-guss/document/rob-1333-v10-decimal-repair-verified-acceptance-preparation-review-ee15e34ec743>) is prepared: existing balanced/bounded coverage, encoding/public-output predicates, numeric/frame denial hooks and expectations, and an acceptance-owned full-state bridge exercised with actual native storage and scripted execution records. Every runtime obligation below names its independent expectation, executable predicate and candidate capability still awaited. This is not a claim that a future candidate passes them or that an unreviewed contract is approved.

D141, deliverable-based acceptance preparation, authorizes reference/checker work and its validation, then a final review stop. D145, routine consistent repair continuation, removes repeated routine-repair approval interruptions, not this final stop. D139, limited language features including Bool literals, and D140, exact growing prototype integers, are retained. D146, encoding participates in earliest-source lexical/syntax ordering, is implemented; D143, complete syntax before name/type checking, remains unchanged. D127–D130 mean call-local reservations, resumable recursive observations, continuous live-value protection and per-call creation counting from entry after explicit arguments including descendants/transients. D138 selects this acceptance orb, larger only if needed, not the resource thresholds. D137 assigns separate acceptance authorship here; Fable only reviews plans when Robert brings them. No Fable invocation.

No preparation cap or mandatory two-hour approvals were adopted. Permanent number policy remains open. Historical sources/locks and all prior document/export versions remain unchanged. No register/issue-description edits; parent's whole-project audit remains parent-owned.

**Delivery:** local uncommitted/unpushed acceptance/[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and)-preparation versus origin/main baseline [03705f1](<https://github.com/robertguss/mo-v2/commit/03705f1dac1de8cbc9efedaf99ad4feeb62c17a3>). [Source/evidence review archive attached to ROB-1333](<https://uploads.linear.app/f291a744-db03-47a3-b7a6-4f8fa26fbf09/7986cacc-c676-45e4-99e7-6d25c64ebfb9/067c4ec9-01a8-4e32-9a48-58c387ac9de9>): 2,170,046 bytes; SHA256 e169c9957fbb2440092e74a298a90709102d90628150f5c10fcf9c17e23378b1. Private seed/source/predictions and build/cache files excluded. Fingerprint is a review snapshot, not a scientific lock. Exact source/evidence paths below are relative to experiments/13-source-acceptance in this archive.

## Independently expected diagnostic reconciliation

For ASCII main = (1 2) followed by space and ff, unexpected 2 at columns 11–12 wins over encoding offsets 13–14. For main = (1 followed by invalid byte before later 2, encoding offsets 10–11 win. Encoding-first spans use zero-based half-open bytes, not character columns. Later encoding still wins over earlier name/type/duplicate-name errors because the lexical/syntax phase completes first. Invalid bytes inside comments cannot be hidden. The original encoding-priority-01 witness and older evidence remain preserved.

Source parse accepts bytes and defers a strict UTF-8 refusal until token scanning reaches that boundary; no decode-first exception. [wirecheck.py](<http://wirecheck.py>) evidence/wire-03: PASS 12 independently annotated encoding cases, nine exact public byte records and seven corrupt-output controls. Literal/data Bool remains distinct from Int; no Boolean equality/operators/inputs added.

## Validation results — preparation, not candidate execution

* corpus_tracecheck.py evidence/corpus-trace-06: PASS 4,276 cases; every one of 27,721 historical snapshots/fields; 53,796 proposed committed boundaries. Unchanged corpus SHA256 d8d33f795b94e8173b6685462e83a277bfeefad5cc2bfee6bee38a8f63554a8b. The projection is rule-derived, not copied expected snapshots.
* [decimalcheck.py](<http://decimalcheck.py>) evidence/decimal-05: PASS 35 carry/borrow/sign/cancellation/input-output examples at 1000/4299/4300/4301/5000 digits, independently decimal-string derived. No Mo digit cap.
* [boundedcheck.py](<http://boundedcheck.py>) /home/user/[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and)-private-v11 evidence/bounded-04 verify: PASS 24 manually balanced heldouts (eight families × three) and 500 unchanged generated predictions; three bound violations rejected and arity-four positive boundary accepted. Measured generated maxima depth 5, functions 3, arity 2; allowed bounds 5/3/4, initial list ≤4. There are **404 distinct generated program/fixture combinations, 96 repeats**, retained/reportable, not silently filtered or regenerated. Private fingerprint 0f176c60d30d30fffd4d7fb25d982cd3517d1a847840027ad3e99f9c572f41f0.
* [bridgecheck.py](<http://bridgecheck.py>) evidence/bridge-06: PASS native storage plus hand-authored execution stub; six rejects for Boolean step, physical shadow contents, intermediate pointer replacement, lifetime rebirth, normalization alias and wrong checked lexical scope. All identity-bearing state/control/event fields translate through typed run-wide maps; actual cell readback and pointer/event consistency are checked at every supplied boundary. This is **not source execution by Mo**.
* [faultcheck.py](<http://faultcheck.py>) evidence/faults-04: PASS both Number/Frame failure-prefix fixtures and twelve corrupt controls. One-based domain counters, denied attempt before effects, correct classification/step and unchanged committed state/events are independently specified. Strict JSON equality prevents Python True == 1 from hiding a numeric holder-count change; it does not alter expected outcomes.
* CARGO_TARGET_DIR=/tmp/rob1333closeout-cells cargo test --locked --manifest-path cells/Cargo.toml: **7 passed, 0 failed**. Native-cells-05 retains logs and toolchain; cargo fmt --check passes. Actual boxed-cell storage and separately controlled Number/Frame allocation gates are exercised. The storage replacement control is compiled; it is not a compiled Mo evaluator mutant.
* [closeoutcheck.py](<http://closeoutcheck.py>) evidence/closeout-04: PASS 163 bad control/resource evidence records; 31 retained evaluator-control classes have specific intended target predicates. Fixture/literal inc \[3,-2,8\] → \[4,-1,9\]: independent create/write/free counts \[0,3,0\] versus \[3,3,0\]; each of four invocations creates zero. Resource records are synthetic: **no million-depth workload ran**.
* Final unchanged regressions: public-11 (16 source accepts/12 refusals/21 public call cases/seven controls), phase-07 (24), priority-07 (14 refusals/two accepts), comparison-04 (12 wrong-kind refusals/11 valid comparisons), refusals-06 (24), control-04 (three worked control/release schedules and three nonterminating prefixes), observation-07 (two synthetic bundles/five bad controls), acquisition-06 (four worked/18 public/500 generated/four bad acquisition controls), fixtures-03 (4,276 valid/eight invalid), cleanup-03 (1,603 synthetic boundaries/four bad controls). Runner-local historical missing lists describe that runner's narrower coverage, not disappearance of later separate checks.

**Retained routine failures:** bounded-02 failed only on numeric versus JSON-string binding-key sorting; round-trip transport normalization repaired verification, predictions unchanged. Bridge-05 failed on a local loop variable shadowing the canonical helper; rename repairs the harness, no expectation change. V6–v10 failures/archives, original refusal-span row and encoding witness remain preserved. These are disclosed preparation defects, not candidate failures or permission to retune scientific checks.

## Requirement → expectation → predicate → actual candidate capability awaited

| Requirement | Independent expected outcome / executable preparation check | Candidate capability and evidence still required |
| -- | -- | -- |
| Grammar/Bool/static resolution | structurecheck canonical paths/types, accepts/refusals, comparison spans; bridgecheck.check_checked catches lexical shadow binding error | Actual frontend parses original bytes, supplies checked form; common A/B entry points, no corpus dispatch |
| Encoding/diagnostics/output | prioritycheck/phasecheck/wirecheck hand ranges and exact byte records | Actual diagnostics and compact public output; no decode-first masking |
| Exact integers | decimalcheck independently derived 35 decimal cases | Real growing numeric backend/input/output, allocation and failure integration |
| Stage A compatibility | corpus_tracecheck/validate all old states/records under thirteen-kind projection | Actual compiled source evaluator/native cells for all 4,276 sources, repeated after Stage B |
| Fixture isolation | fixturecheck graph/count refusals; closeoutcheck fixture/literal predictions; native cell tests | Actual installation/rollback, no provenance dispatch; frontend creates zero managed cells |
| Calls/protection/accounting | C families, acquisition/control predictions, predicates for live values/counts/invocation creations | Actual enter/return, pending operands, reservation origin and every committed boundary |
| Heldout/generated shapes | boundedcheck 24/500 unchanged expectations, explicit bounded coverage | Isolated candidate execution using same generic answer/protection/reachability/physical predicates |
| Physical state/identities | bridgecheck typed correspondence, native readback/pointer journal versus independent hand stub | Linked acceptance collector with real births, retained retired IDs, actual roots/control and all-state comparisons |
| Resume/terminal joins | observationcheck.check_bundle predicts suffix/prefix and zero-budget invariance | Actual fresh run at every small cut k, zero-work join, real suffix; no replay or prefix reset |
| Destroy/outside retention | cleanupcheck.check_destroy derives graph/free set from outside roots; native stub cleanup | Actual destroy twice at every boundary/terminal/failure, exact surviving outside graph and separate teardown |
| Number/frame/cell denial | faultcheck.check_failure; native allocate gates deny before callback/effects | Candidate routes actual buffers/frames/cells through acceptance hooks; inspect bypasses, run failure/destroy boundaries |
| Compiled negative controls | closeoutcheck.CONTROLS/PREDICATES: 31 specific targets, evidence-record rejection controls | Actual source patch/build log/baseline success/intended path; named predicate must reject actual bad run, not unrelated crash |
| Resource/no host recursion | closeoutcheck.check_resource hand million-depth answer/count/envelope records | Owner-approved actual-machine provisioning/run, streaming physical events/peaks, explicit-frame/cleanup source inspection, stack/frame evidence |
| Effort | Proposed contributor elapsed-seconds convention below; unknown earlier preparation totals disclosed | Owner-approved ledger/limits and actual execution timestamps; no adopted preparation cap or inferred historical total |

## Proposed linked observer contract and remaining physical gates

Candidate operations: check source bytes, dump checked program, begin checked program with ordinary fixture roots, advance same run by nonnegative committed-transition budget, destroy run. Snapshot performs no work or holder acquisition. Acceptance retains Observer; candidate receives RuntimeCells without pointers/provenance/events/predictions/fault choices. Source/check occurs before fixture/run setup and creates zero managed list cells. Candidate may not consume acceptance's parsed tree as its evaluator input instead of checking source.

Read/create/write/detach/metadata/free touch sole actual boxed storage and are journaled. Detach is not a counted rebuild. Fixture and source storage share implementation. Live lifetime/address continuity is required only while allocated; addresses may recycle after free with a fresh lifetime ID. No per-snapshot renumbering or cross-run raw-pointer equality. Normalization covers cells, bindings, branches, invocations, operands, ready/release, enter and return. Acceptance independently derives lexical paths and expected acquisition identities. Runtime birth registration must extend actual typed maps without reviving retired identities. Source inspection must check shadow graphs, unlogged/bypass operations and identity/provenance special cases.

Number/Frame allocation uses RuntimeCells.allocate(domain, closure), with acceptance-only independent one-based denial counters; callback cannot run on denial. Candidate numeric/frame routing is **not yet verified**. Numeric/frame allocations/bytes are separate from managed-cell counts; zero list creation is not zero heap usage. Tagged denial is not proof of intercepting all host allocations or recovering arbitrary OS OOM. Fatal process failure is abnormal termination, not invented safe recovery.

For every small public transition boundary, run fresh to k (including 0/terminal), read actual state/prefix/live pointers, resume budget 0 unchanged, then compare the actual remaining normalized suffix to independently predicted transitions/events. Reobserve terminal at zero/positive budget with no work. Destroy a separate fresh run at every boundary/terminal/failure twice; outside-root reachability/counts derive surviving storage, free exactly the complementary run-owned lifetimes, preserve outside contents/identity. Separate evaluation/destroy/host teardown counters. Real candidate checks await linked execution; synthetic bundles/native scripted cleanup do not satisfy them.

For every compiled evaluator control retain exact patch/build/viability evidence, passing baseline and actual intended path, then rejection by its named predicate. A record asserting compiled=true is not compilation evidence. The 163 preparation controls only validate such record requirements and envelope predicates.

## Consolidated owner review — no default approval

These topics are for one final review; parent/Robert sequences any questions. No competing question is raised here.

1. **Detailed language:** approve/revise proposed grammar, comparison spellings, namespaces/shadowing/types/spans and fixture notation. Recommend retain the small experiment notation. Bool literal capability and exact prototype numeric meaning are settled; permanent Mo choices are not.
2. **Detailed ownership/transitions:** approve/revise exact remaining-use/arguments/entry/return/reservation/cleanup, especially separate Give up holder/Free cell states. Recommend validated projection/C predictions without weakening historical snapshots.
3. **Observer/failure formats:** approve/revise exact public/state/control formats, numeric/frame tagged gates, last-committed-prefix failures and iterative destroy. Recommend native-observed bridge with explicit limitations, no OS-OOM recovery claim.
4. **Coverage/privacy:** approve/revise retained 24/500 bounds, explicit 404-unique/96-repeat policy and builder visibility. Recommend keep/report fixed cases, no new targets or mandatory extra predictor. Public review material includes disclosed rules/counts; cannot undo prior disclosure. Builder gets approved rules/interfaces/public examples, not newly exact predictions/private sources/seeds/controls; verify delivered context/checkout isolation before builder work.
5. **Resource envelope/streaming:** approve/revise proposed two million-depth workloads, ≥4 GiB floor, 8 MiB stack, 600 seconds, 100 million transitions. Proposed streaming schedule: every primitive event plus full state at 0, every 10,000 committed transitions, terminal, suspension/failure and before/after destroy; maintain live-set/event consistency and frame/heap peaks throughout. This reduced large-run observation claim needs approval; tiny every-state evidence does not cover unseen million-run states. Recheck actual orb resources before authorized execution; do not reduce depth after failure. Depth alone is insufficient without source/path and stack/frame evidence.
6. **Effort/caps/stages:** proposed unit is contributor elapsed seconds start→stop including tool/build/test waits, minus timestamped owner-wait/stopped intervals; sum concurrent contributors, separate preparation/A/B rows. Historical preparation total was not precisely recorded; do not reconstruct from mtimes. Choose A/B caps or explicitly defer, no preparation cap/two-hour interruption assumed. Recommendation retain the unit with honest unknown history; explicit later A and B authorizations. Passing A never automatically starts B.

Remaining gates: Robert reviews/approves exact contract/checks/package, scientific freeze is separately authorized, implementation belongs to a separate builder, candidate-linked execution/compiled controls/actual resources require subsequent authorization. No lock/builder/stage/resource/trial/merge/deployment follows publication.

## Detailed proposed English rules retained from v5, with priority reconciliations above

The following sections retain the reviewed v5 rules; the approved D142/D143/D146 phase-priority reconciliation and current preparation status above supersede older future-preparation wording. These detailed rules remain proposals except expressly approved boundaries. They are included here so review does not depend on historical status prose.

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

## Thirteen historical landmarks — projection validation completed in preparation

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

All 27,721 snapshots/fields and ordered primitive records were reproduced from rule-derived states (corpus-trace-06). Real candidate correspondence remains unrun. No omitted snapshot kind; holderForgotten belongs only to the historical broken variant, not approved corpus.

## Exact historical source links and preserved scope

[Finite SPEC](<https://github.com/robertguss/mo-v2/blob/a22831f823d2ac7ccbb8726a8d4418fbceb233e0/experiments/10-finite-rust/SPEC.md>), [structural exporter](<https://github.com/robertguss/mo-v2/blob/a22831f823d2ac7ccbb8726a8d4418fbceb233e0/experiments/10-finite-rust/Export.lean>), [trial RULE](<https://github.com/robertguss/mo-v2/blob/e6a895c8ce2887d9bee6986819a779f8f74b5541/experiments/03c-checker/trial/RULE.md>), [trial INTERFACE](<https://github.com/robertguss/mo-v2/blob/e6a895c8ce2887d9bee6986819a779f8f74b5541/experiments/03c-checker/trial/INTERFACE.md>), [calls draft](<https://linear.app/robert-guss/document/full-3c-calls-and-recursion-specification-draft-5-october-73682eae811b>), [v5 preserved](<https://linear.app/robert-guss/document/rob-1333-v5-approved-exact-prototype-integers-proposed-acceptance-5eece5c832ec>), [live approvals](<https://linear.app/robert-guss/document/decisions-and-approvals-live-register-360d6e9c3d64>). Archive contains acceptance source/README/PROTOCOL and every retained public run/failure. Private files stay on this acceptance orb, not transferred to parent/builder. No new Lean/demand proof, native compiler, concurrency/hot reload, participant study, unlimited-resource guarantee or universal-safety claim.

**STOP FOR OWNER REVIEW.** Candidate-independent closeout delivered for review, not scientific acceptance or approval to implement.
