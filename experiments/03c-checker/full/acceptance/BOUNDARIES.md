# Exact boundary predictions and checks still requiring an interface

These predictions precede any new model execution. They complement, rather than
replace, the exact cell-event sequences. Every named cut must be observable by
advance/resume. Observation must not acquire a holder or perform a semantic step.
Actions follow the approved public Stage B schedule. If the formal author adds
specified dispatch steps, a fixed reviewed action projection is required; do not
silently adjust the budget expectations to candidate output.

## Cell/call order

Use E(f,i,parent,args) and R(f,i,result) for Enter/Return. Invocation numbers
follow Enter order. Every normal Return has completed callee branch/free cleanup.

* C1: E(one,1,0,1), C N0, R(one,1,N0), F A. A stays aside throughout one.
* C2: E(one,1,0,1), C N0, R(one,1,N0), W A. Result A→N0.
* C3: E(bump,1,0,A), E(bump,2,1,B), E(bump,3,2,Nil),
  R(bump,3,Nil), C N0, R(bump,2,N0), C N1, R(bump,1,N1),
  E(choose,4,0,A,N1), F N1, F N0, R(choose,4,A).
* C4: the same bump subtree; E(first,4,0,N1), F N0, F N1,
  R(first,4,2); E(first,5,0,A), F B, F A, R(first,5,1).
* C5: E(readBoth,1,0,A,A), E(first,2,1,A), R(first,2,1),
  E(first,3,1,A), F B, F A, R(first,3,1), R(readBoth,1,2).
* C6: bump entries 1/2/3 on A/B/Nil, Return3, C N0, Return2,
  W A, Return1; first4(A) frees N0 then A and returns 2;
  first5(B) frees B and returns 2. Root returns 4.
* C7: E(makeThenDrop,1,0,-6), E(one,2,1,-6), C N0,
  R(one,2,N0), F N0, R(makeThenDrop,1,0).
* C8: C N0, E(identity,1,0,N0), R(identity,1,N0).
* C9: E(outer,1,0,-6), C N0, E(identity,2,1,N0),
  R(identity,2,N0), R(outer,1,N0).
* C10: unary list recursion enters n+1 frames in head-to-tail order and
  returns n+1 in reverse; each Write/Create (bump) or reserved Free (sum)
  occurs after its child's Return and before that owning frame's Return.
* C11: entries exactly the chains written in DERIVATIONS.md; reverse Returns.
  Bool case enters inner notFlag first, returns false, then enters outer and
  returns true. No mutual-call assumption is supplied as a theorem premise.
* C12/C13/C14: only the finite entries/cell effects specified below, no Return.
* C15: first xs argument completes, E(one,1,0,9), C N0,
  R(one,1,N0), E(choose,2,0,A,N0), F N0, R(choose,2,A).
* C16: no named call. C17: E(choose,1,0,A,Y), F Y,F Z,R(choose,1,A).
  Alias control enters with (A,A), has no cell event, then returns A.
* C18: E(shadow,1,0,A); bump entries 2/3/4, Return4, C N0,
  Return3, C N1, Return2; Bind inner xs to N1, R(shadow,1,N1).
  first5(A) frees B/A, returns 1; first6(N1) frees N0/N1, returns 2.
* C19: explicit schedule below. C20: E(outerFail,1,0,A); for number/frame
  denials there is no other Enter. For cell denial, E(one,2,1,23) has committed.
  Successful control: C N0, R(one,2,N0), E(choose,3,1,A,N0), F N0,
  R(choose,3,A), R(outerFail,1,A).
* C21: E weave on A/B/C/Nil at invocations 1/2/3/4, Return4,
  W C,C N0,Return3,W B,C N1,Return2,W A,C N2,Return1.
* C22 is the paired C12/C13 prefix comparison, not a new loop algorithm.

Usefulness rows require their listed entire cell projection and properly nested
source-derived Enter/Return sequence. In particular, no Create may be assigned
outside an enclosing demand merely because it occurs in an ordinary descendant
or that descendant's argument evaluation. S2A01's two Creates and S2O02's one
Create are before the first demanded entry. S1R05's two Creates occur during
bump while twice is active. S2R02's two Creates occur during the first bump
while both is active. These are accounting checks, not counter-field assertions.

## Independent holder and lifetime claims

| Boundary | Required cells, owners and protected values |
|---|---|
| C1/C2 one Enter | A is allocated aside/count0/link Nil; reservation belongs to root branch, suspended and ineligible to one. No readable holder claims [1] from A. |
| C3 first argument completed | Completed slot owns A=[1,2]; input xs still owns A for later argument, A count2, B count1. No double-count through ready/control views. |
| C3 first bump Match complete | A count1 (earlier argument), B count2 (A link and bump tail). Both required [1,2] at A and [2] at B read correctly. |
| C3 before choose Enter | Completed arguments own A and N1; graphs A→B=[1,2], N1→N0=[2,3]. Four live cells, each count1. |
| C4 bump Enter | Root binding xs and callee parameter both own A. Root future first(xs) independently requires [1,2] even though root is suspended. |
| C5 first first Return | readBoth b still owns A count1; B count1 from A. No hidden returned list holder (result is scalar1). |
| C6 bump(B) Enter | Root ys and parameter own B count2. A is reserved in suspended bump(A), not an incoming B link anymore. B=[2] protected until first(ys) consumes it. |
| C10 outside cases | Outside A always reads [-2,5,1], count at least1. New answer never aliases changed contents onto A/B/C. |
| C14 selected cut | A aside0 detached, one root-branch reservation, three spin frames. No live list holder; reservation must not be freed before this branch returns (which this finite prefix has not done). |
| C15 one execution | Earlier pending A=[1] preserved; N0=[9] distinct. At choose Enter both parameter identities and frame exist, b holding N0. |
| C17 Enter | a→A count1; b→Y count1; Y→Z count1. No parameter released yet. Alias control has a→A,b→A,count2, despite eventual zero-allocation execution. |
| C18 bump Enter inside shadow | Root xs acquired first, then shadow parameter xs, then bump parameter xs. Root remains holding; transferred shadow parameter is movedOn, not a new root. Entered bump parameter and still-holding root are shown in acquisition order (root first). Inner let xs does not exist until bump Return. |
| C21 before recursive descent | Each ancestor h+10 scalar is saved separately: 8,15,11, not merely depth. A/B/C reservations belong to distinct invocations. After child's Return, recursive list value is a pending/let-owned value before being transferred as a Cons tail. |
| S2O01 before bump Enter | alias no longer holds A; xs owns it alone, B has only A's edge. The first call's read-only alias has been consumed, not assumed unique retroactively. |
| S2R03 bump(C) Enter | C count2: ys's B edge plus callee parameter. Distinct input roots do not make reachable graphs disjoint. B=[9,4] remains protected. |

All assertions bind protected plain values when produced/acquired. They must
also check that the plain continuation still requires the owner: a candidate
cannot evade protection by deleting an owner or calling it movedOn. Selected
claims do not weaken F3's requirement at every semantic and internal boundary.

## C16, C17: cleanup pauses are real states

C16 action list:
1 Start; 2 Dispatch let; 3 Leaf xs (move); 4 Bind discarded;
5 GiveUp discarded/A; 6 Free A; 7 GiveUp B; 8 Free B;
9 Leaf 7; 10 Handoff let; 11 Finish.

At action 5: A live count0, link B; B live count1. The A cleanup obligation is
queued, A not yet freed and not aside. No readable holder owns A now.
At action 6: A absent; B live count1, owned by pending cleanup, representing
[2]. The prior A-edge holder was transferred, not duplicated. The ordered
release chain retains its parent entry while descending.
At action 7: B live count0 queued, not freed; at 8 heap empty. Resume from
each cut must append exactly the remaining F events once. Destroy at cuts 5/6
frees A,B / B in cleanup events only, not evaluation events; a second destroy
does nothing. A destroy may choose a different *general* cleanup order unless
the interface fixes one, but here the remaining acyclic chain fixes the order.

C17 actions:
1 Start; 2 Dispatch call; 3 Leaf xs; 4 Capture arg0; 5 Leaf ys;
6 Capture arg1; 7 Enter; 8 GiveUp b/Y; 9 Free Y; 10 GiveUp Z;
11 Free Z; 12 Leaf a; 13 Return; 14 Finish.
At 7 frame1 and both parameter bindings exist; at 8 Y is live0 queued.
Precondition is tested at 7, not 11. In the alias variant, Enter count A=2
is already enough to refute that precondition; the later release cannot alter
that recorded entry fact. There is no claim the alias variant allocates.

## C19: exact finish and resume boundaries

| Action | Committed work |
|---:|---|
| 1 | Start |
| 2 | Dispatch identity call |
| 3 | Dispatch one call |
| 4 | Leaf 7 |
| 5 | Capture one's argument |
| 6 | Enter one, invocation1 |
| 7 | Dispatch Cons |
| 8 | Leaf n=7 |
| 9 | Capture Cons head |
| 10 | Leaf Nil |
| 11 | Capture Cons tail |
| 12 | Cons primitive: C N0=[7], pending result |
| 13 | Return one (frame removed, N0 pending in caller) |
| 14 | Capture identity's argument |
| 15 | Enter identity, invocation2, parameter owns N0 |
| 16 | Leaf xs transfers N0 |
| 17 | Return identity |
| 18 | Finish, returned answer owns N0 |

From the same begun state, budgets 0,17,18,23 respectively mean unchanged
Suspended at count0; Suspended count17 with pending result [7] but no Finish;
Finished count18; Finished count18. Last-action Finish is not delayed.
Split `[6,6,3,2,1]`, `[0,6,0,11,0,1]` and `[17,1]` must equal advance18 in
complete state, event prefix, identities, history and cumulative count. Every
prefix of each split equals the corresponding uninterrupted sum. Repeated
observer calls between segments are inert. Terminal advance0/1/23 is inert.

## C12/C13/C22: explicit finite prefixes

spin first Enter is action5; subsequent Enters at 9,13,17,21,25,29. At 29,
seven frames exist, each scalar parameter0; no reservation/list/pending-list
holder, result, Return or cell event. A further budget4 adds exactly one Enter.

allocateForever first Enter action5. Actions6–15: Dispatch let; Dispatch Cons;
Leaf n; Capture; Leaf Nil; Capture; Create; Bind ignored; GiveUp; Free.
Actions16–19: Dispatch recursive call; Leaf n; Capture; Enter. Second Create
at26, Bind27, GiveUp28, Free29. At29 frames1 and2 exist, heap empty, cell
events C N0,F N0,C N1,F N1. Ancestor1 creation total2, ancestor2 total1.
At action28 N1 is still allocated live0 queued: heap size is not creation count.
Continued finite prefixes remain evidence about those prefixes only.

## C20: explicit proposed lifecycle requests

These three gates are a precise interface requirement, not an assertion that
native Rust allocates at them or that an unwritten Lean wrapper already has them:

* `number`: before committing Primitive(add 20 3) inside one's argument;
  this named site/first occurrence is denied. Other requests allowed.
* `frame`: before committing Enter(one); deny first occurrence of this site,
  after scalar23 completed/captured. Outer frame request is allowed.
* `cell`: before committing Create in one's Cons; deny first occurrence of
  this site. Number/frame requests allowed.

The request is a failure-layer boundary. Denial changes lifecycle status to
Failed, records a separate cause/site/domain/occurrence and abort report, and
does not commit that semantic action or its evaluation effects. Compare the
entire saved execution state and evaluation events with the immediately prior
state of the *same prefix*, not merely the heap. Abort order is [outerFail] for
number/frame, [one,outerFail] for cell. No Return or choose Enter occurs.
Domain ordinals/site selectors must be mapped explicitly by the spec author;
the corpus does not invent a hidden implementation allocation count.

At every denial, A→B=[1,2] remains with three holders on A (two outside plus
one run-owned); B count1. Destroy releases the one run-owned holder, all scalar
frames/control and cleanup work, leaving A count2/B count1 with the same
contents. No cell is freed here and no cleanup cell event is needed. Second
destroy leaves everything unchanged. Successful control has exactly one
Create/Free for N0=[23], then answer A; destroy must release the answer holder,
again leaving counts2/1. Pair with C16/C14 destruction so a no-op destroy cannot
pass: C14 destroy frees reserved A, clears all frames, no source evaluation.

## Theorem/control interface checklist, not executed integration

The specification author must supply exact fully qualified declarations for
F1–F6, L1–L2, later conditional and enforced checker statements. No names are
fabricated here. Before freeze, acceptance needs:

* Program/start validation and independent plain start/advance; counted
  begin/advance, cumulative committed action counts, status, history, raw result.
* Readable allocated cell tables, statuses and primitive memory events;
  holder owners including completed operands, pending cleanup, outside roots;
  resolved lexical/binding/branch/invocation identities and ordered views.
* The independent plain/control required-value relation and its lifetime
  obligations, not only candidate holding flags or counted readback.
* Lifecycle request observation/injection and destroy, separated evaluation/
  cleanup events, cause and abort report; definition of each number/frame gate.
* An explicit universal call-free embedding/landmark projection preserving
  every approved old field and timing, with all 28 frozen runs preserved.
  No trial run was rerun here; that integration is still required.
* Theorems over every well-typed finite program/valid start (acyclic DAGs,
  repeated outside roots included), not only these cases; both simulation
  directions and a well-founded administrative ranking; no termination premise
  hidden in validStart. Conditional entry precondition before cleanup, and
  simultaneous recursion soundness. Enforced theorem quantifies over every
  entered demand of accepted whole programs, all finite prefixes.
* Explicit standard-axiom allowlist, fresh locked reconstruction with Lean
  4.34.0 unless separately approved, transitive `#print axioms` for every export,
  kernel recheck, no sorryAx or hidden expected conclusion. No proof files or
  checker are authored here.

| Faulty route that later must execute | Independent rejection and positive control |
|---|---|
| Reuse shared cell | C3 earlier A value and C6 ys tail value must change/fail; ordinary baseline preserves them. |
| Consume caller reservation | C1 cannot emit required Create before Return; C2 must not use A in one. |
| Lose/mark dead pending or suspended holder | C3/C4/C18 plain continuation still requires old [1,2], regardless of counted flags. |
| Net-growth or reset-descendant counter | C7 global heap0/Create1; C9 outer1/identity0; C22 ancestor1=2/ancestor2=1. |
| Suspension as Finish, or restart | C19 budget17 is Suspended; segment histories retain one Create and stable N0. |
| Administrative loop | C19 plain result and F2 ranking/correspondence cannot justify a counted run stuck forever in bookkeeping. No bounded timeout alone proves this universal defect. |
| Skip branch/return/free cleanup | C1 A must free before branch handoff; C16/C17 required frees; F4 forbids unfinished holders/frames. |
| Hide entry copy | Inject a copy of C8's [1] at identity entry AFTER explicit argument completion but label/exclude it as preparation. Memory must expose the second Create, identity interval count1 and failure of zero-create accounting. Use explicit fault provenance; do not call Stage B's inapplicable omitted-entry-create control executed. |
| Accept-all | S1R01–R06 contain actual ideal Creates. |
| Reject-all | S1A01–A12, S2A01–A03 mandated usefulness. |
| Omit caller ownership check | S2R01/02/03 allocate; C5/S2A03 prevent confusing all sharing with violation. |
| No-op destroy / frees external graph | C16/C14 demand real cleanup; C20 demands two external A holders preserved and run answer released. |

These routes are test obligations, not executed mutants or successful proof
checks. Each later report must identify the faulty route actually reached and
the intended property that failed. Compiler/name/type failures do not count.
