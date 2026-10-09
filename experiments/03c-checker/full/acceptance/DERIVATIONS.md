# Independent prediction derivations — ROB-1139

Preparation, not a scientific freeze. Author: this acceptance context,
T-01a12211-5ada-7319-991e-59ce08126990. Specification author: parent
T-01a121f6-7962-75c6-bb35-922b9a6cc491. A third verifier is still required.
Same-account procedural authorship is claimed, not technical isolation.

Authority: Linear document `73682eae811b`, v2 updated 2026-10-09 19:05:29.542Z,
D185; ROB-1139 preparation brief updated 19:08:18.838Z, D186. Public source
baseline: `a4056b8341122622106fe60f834dbf8e2428295f`. Read sources:
`experiments/03c-checker/PLAN.md`, trial `RULE.md`, `INTERFACE.md`,
`lean/Trial/{Language,Memory,Counted}.lean` (read only, no execution), and
`experiments/13-source-acceptance/BUILDER_EXECUTION.md`,
`BUILDER_STAGE_B_PREFLIGHT.md`, `BUILDER_STAGE_B_BINDING_ORDER.md`.
No private corpus, seeds, raw private evidence or candidate output was used.

## Representation and identity rules

The three JSON files are an exact finite public corpus. The expression notation
is an interchange notation for acceptance, not approved Mo surface syntax or a
formal-machine implementation. All functions have explicit parameter/result
kinds. A case's exact finite table is the transitive syntactic call closure of
its main, in programs.json library order (both branches count, recursion closed),
plus its main, ordered start and demanded-function metadata. Non-demanded
declarations are ordinary. Unrelated library declarations are not smuggled into
a whole-program acceptance example: an unused bad caller must not contaminate it.

Resolve variables lexically. Static identities are `(function-name or main,
JSON path to binder)`, parameters `(function-name, parameter-index)` and inputs
`(main,input-index)`; occurrences resolve to the nearest enclosing binder.
Dynamic binding identity is that static identity plus its invocation instance.
Invocations are numbered in Enter order, starting at 1 (root is 0). Bindings are
numbered in creation order, inputs first, parameters in declaration order and
match head before tail. Branch identities are numbered in Choose order for
matches only, empty branches included. These prescriptions fix identities
without requiring a particular Lean representation. Any adapter must preserve
lifetime and order with one consistent bijection, never reassign at each state.

Cell tables are exact, not just list values. `C`, `W`, `F` are the entire ordered
cell-event projection. For a finished row, the final allocated set and
item/link fields are exactly those remaining after its stated cell writes and
frees; roots are the raw answer and the unchanged outside multiset. Every final
count equals root multiplicity plus incoming links; all final cells are live.
No binding, frame, reservation, pending value or cleanup obligation owns another
holder. This also specifies final cell/holder tables without duplicating them.
Failure/prefix rows do NOT use that Finish rule. BOUNDARIES.md specifies them.

## Rule-level calculation, without executing a machine

1. A unique match consumes its scrutinee holder, detaches its link into the tail
   binder and reserves the head for this branch/invocation. No cell event.
2. A shared match acquires a tail holder only when used, then drops its own
   scrutinee holder. It creates no reservation. A retained ancestor's link is
   why a tail may still be shared after a shared head match.
3. Cons finishes head then tail. It writes the newest eligible reservation or
   creates one cell. It moves the tail holder into the link. No cross-call use.
4. An unused tail is released before the branch body. Releasing a holder to
   zero precedes Free; cascading frees run head to tail. An unused reservation
   is freed after the branch result, before handoff/return.
5. Every explicit argument finishes before Enter. A completed argument remains
   held while later arguments run. Enter transfers holders, not cells. Return
   transfers the result after cleanup. Only an active demanded interval counts
   a Create; descendants' Creates count for all its demanded ancestors.

These rules derive the following calculations. Counts are `(Create,Write,Free)`;
GiveUp and detach are separate ownership actions, not hidden cell events.

## Preserved C1–C14 and added C15–C22

| Case | Independent derivation and exact distinguishing consequence |
|---|---|
| C1 | A is detached in root. `one(1)` has no eligible reservation, so creates N0; returns it; root branch frees A. `(1,0,1)`, raw N0, answer [1]. |
| C2 | Same nested Create, but the root Cons runs after `one` returns and writes A with tail N0. `(1,1,0)`, raw A, answer [1,1]. |
| C3 | First argument holds A while bump traverses the second argument. A is shared; acquiring B protects it alongside A's link, so both bump frames must create on return. N0=[3], N1=[2,3]. Only after bump returns can choose Enter. Its unused second parameter releases N1 then N0. A/B remain [1,2]. `(2,0,2)`. |
| C4 | Root still needs xs after bump. Same two Creates. `first(changed)` uniquely detaches N1 and frees its unused tail N0 before freeing reserved N1. `first(xs)` similarly frees B before A. 2+1=3, `(2,0,4)`. |
| C5 | First `first(a)` sees b holding A; it reads h and releases only its shared scrutinee holder. No tail holder needed. Second `first(b)` uniquely detaches A, frees unused tail B, then A. 1+1=2, `(0,0,2)`, despite overlapping arguments. |
| C6 | A is unique but B has ys as well as the transferred tail holder. B cannot be overwritten, so N0=[3] is created; A is written [2|N0]. `first(changed)` frees N0 then A; `first(ys)` frees B. 2+2=4; `(1,1,3)`. |
| C7 | No list/reservation enters makeThenDrop. Ordinary one creates N0 inside its interval; unused binding later releases/frees it. Answer 0; `(1,0,1)`. Net growth zero is not zero creation. |
| C8 | Cons creates before identity enters. Whole-run Create=1, identity interval Create=0; result [1]. No preparation copy exists. |
| C9 | outer enters before its Cons, so outer interval Create=1. identity enters after that Cons and its interval Create=0. Answer [-6]. |
| C10 | For unique length n, bump's matches reserve each original cell; deepest Cons writes first, then outward, n Writes and no Creates/Frees. Sum constructs nothing, so its branch-end frees occur deepest-first, n Frees. Empty yields []/0, singleton -2 yields [-1]/-2, mixed -2+5+1=4 and [-1,6,2]. With outside A, each accessed suffix is shared, bump creates three cells instead; sum leaves the outside graph untouched and frees none. |
| C11 | even(4): even4→odd3→even2→odd1→even0=1; even5 ends odd0=0. odd(-3)=0 immediately. Returns unwind in reverse entry order. No cell event. notFlag(notFlag(true)) executes inner false, outer true, testing Bool parameter/result and both literals. |
| C12 | Each spin Enter is followed by dispatch, scalar leaf, argument capture, another Enter. Start and first call take five actions, then four per entry. Action 29 has seven frames, no Return/cell event/result; Suspended. This is a finite-prefix assertion, not an executed divergence proof. |
| C13 | Each loop allocates [0], binds/discards it, GivesUp, Frees, then recursively enters. Action 29 is the second Free, two cells cumulatively created/freed, zero currently allocated, two loop frames. No result/Return. |
| C14 | Root uniquely detaches A, then enters spin(1). No Cons and no completed enclosing branch: A remains allocated aside, count 0, detached, owned by root's match. Three spin frames at the selected cut. Do not apply Finish garbage freedom. |
| C15 | Earlier A=[1] stays pending while one(9) creates N0=[9]. choose Enter occurs after one Return, then drops its unused b and frees N0. Answer [1], `(1,0,1)`; choose interval Create=0. |
| C16 | Last-use xs transfers to discarded; unused binding releases A. GiveUp to zero is not Free. Free A transfers B's edge holder to pending cleanup; only the later GiveUp/Free consumes B. Answer 7, `(0,0,2)`. |
| C17 | Enter has a→A and b→Y, with frame present. Only later is b dropped, freeing Y then Z. Result [1]. Alias variant has both parameters on A (count 2), violates entry uniqueness even though dropping b leaves count 1 and this read-only run allocates nothing. |
| C18 | Root xs must survive shadow's entire invocation. Its parameter xs feeds bump, then a new local also named xs receives changed N1; neither name displaces the root binding identity. first(root xs)=1, first(z)=2. Old B/A freed before changed N0/N1 because that is the source order. |
| C19 | Exactly 18 approved actions; identity(one(7)) yields N0=[7]. See the explicit action list and splits in BOUNDARIES.md. |
| C20 | outerFail has entered; earlier choose argument A is held during later one(20+3) argument evaluation. Deny number before add result, frame before one Enter, or cell before one Create. None has a Create. Failed state preserves its last committed execution prefix. Two outside A holders survive destruction, A count 2 and B count 1. Successful control briefly creates/frees [23], returns A; destroy releases that answer too. |
| C21 | Each weave frame saves h+10 before recursing; after return it writes its reservation with h−10 and recursive tail, then creates the h+10 cell. For h=-2,5,1, the saved heads are 8,15,11; tail items -12,-5,-9. Unwind C then B then A. Result [8,-12,15,-5,11,-9]; `(3,3,0)`, raw N2. |
| C22 | Same budget 29 for C12/C13: heaps both empty, but Create totals 0 and 2. The second C13 Free cannot decrement either active ancestor's Create count. This tests finite prefixes only; no theorem about looping is authored here. |

## All 27 inherited categories

`A` requires acceptance, `R` refusal, `O` an observed verdict with no mandated
acceptance. Verdict requirements are future checker tests, not claims that a
checker has run. The ideal machine executes refused examples normally to expose
the allocation witness. Rejecting a type-invalid example would not count.

| ID | Category / exact main row | Derivation, `(C,W,F)` on principal start |
|---|---|---|
| S1A01 | Increment / C10-bump-mixed | One local reservation per Cons, unwind C/B/A, [-1,6,2], `(0,3,0)`. |
| S1A02 | Reverse / U-reverse | revAcc reconstructs the current head onto accumulator BEFORE recursive entry; A then B then C, [1,5,-2], `(0,3,0)`. |
| S1A03 | Running totals / U-totals | Accumulators entering frames: 0,-2,3,4. Return writes C=4, B=3, A=-2, `(0,3,0)`. |
| S1A04 | Append / U-append | Empty first suffix returns second input D; B then A are rebuilt using their own suspended reservations, [-2,5,1,7], `(0,2,0)`. |
| S1A05 | Swap neighbours / U-swap | Odd last C is rebuilt once. At outer two-cell branch, inner Cons(-2,C) takes newest B, outer Cons(5,B) takes A. [5,-2,1], `(0,3,0)`. |
| S1A06 | Rotate / U-rotate | Rebuild detached A as singleton [-2] before append enters with t and A. append reconstructs C then B onto A. [5,1,-2], `(0,3,0)`. Not cross-call reservation transfer. |
| S1A07 | Merge / U-merge | Matches take two heads. Reconstruct the nonselected head before recursing; newest reservation may change its physical identity. Branch decisions are true,false,false,true. Preparatory writes D=-1, D=4, E=4, F=8; unwind writes E=4,D=2,B=-1,A=-3. Final A/B/D/E/F=[-3,-1,2,4,8], `(0,8,0)`. |
| S1A08 | Insertion sort using existing cells / U-sort | Rebuild singleton A,B,C before sorting each tail; insertCell gets a live singleton, not a reservation. Insert 1 into []; insert 5 into [1] (else path), then -2 into [1,5] (then path). Reconstructing 5 uses the newer matched sorted head C, leaving B for 1. Nine Writes listed exactly; [-2,1,5], `(0,9,0)`. |
| S1A09 | Total / C10-sum-mixed | Sum 4; unused reservations free C,B,A after recursion; `(0,0,3)`. |
| S1A10 | Keep first/drop rest / U-keep-first | A detached; unused tail release frees B then C before reconstructing A. [-2], `(0,1,2)`. |
| S1A11 | Remove first match / U-remove | Match at B returns C without construction, frees B before outer A Cons. [-2,1], `(0,1,1)`. |
| S1A12 | Keep positives / U-positive | 1 and 5 branches rebuild C/B on unwind; -2 branch returns B and then frees A. [5,1], `(0,2,1)`. |
| S1R01 | Duplicate / U-duplicate | Two Cons but one eligible cell per frame. Inner Cons writes reservation, outer must Create. [-2,-2,5,5,1,1], `(3,3,0)`. |
| S1R02 | Prepend / U-prepend | No match, no reservation: N0=[-7|A]. `(1,0,0)`. |
| S1R03 | Insert new number / U-insert-new | -3 branch recurses; at 4, reconstruct 4 onto C using B, then create 2 onto B. Outer -3 uses A. [-3,2,4,8], `(1,2,0)`. |
| S1R04 | Build from number / U-build | No initial cells/reservations. Base 0=[], unwind creates 1 then 2 then 3. [3,2,1], `(3,0,0)`. n≤0 is a nonallocating control, not a declaration-level exemption. |
| S1R05 | Same list twice requiring new cells / U-twice | append's first argument holds original xs while bump's second argument copies both cells. append later receives disjoint original/changed graphs, writes B then A. [1,2,2,3], `(2,2,0)`. Read-only C5 is the contrary control. |
| S1R06 | Ordinary allocating helper / U-ordinary-alloc | allocHelper has no reservation and calls ordinary one(-9). One Create is inside both intervals, [-9], `(1,0,0)`. |
| S1O01 | Ordinary arithmetic helper / U-ordinary-arithmetic | (-2+3)-7=-6; no cell operation. Refusal is a usefulness limit, not witnessed allocation. |
| S2A01 | Fresh construction then demand / U-fresh-demand | Two Creates finish before bump Enter, then two Writes inside. [-1,6], global `(2,2,0)`, demanded Create=0. |
| S2A02 | Chained demands / U-chain | bump returns a uniquely held list; reverse receives it by transfer. Six Writes total, [2,6,-1], `(0,6,0)`. |
| S2A03 | Ordinary call with retained data / U-ordinary-shared | Same actual allocation as C4, but bump ordinary. No demanded invocation violated; must not globally forbid ordinary copying. `(2,0,4)`, answer 3. |
| S2R01 | Old version retained after demand / U-retained-demand | Same program/memory as S2A03 except bump demanded. Its two Creates violate the demand. Old value remains [1,2] until first(xs). |
| S2R02 | Same list passed twice to change both / U-alias-demand | both enters with two holders on A. First bump must copy; second can reuse originals after its alias is consumed. append receives two disjoint changed graphs. [2,3,2,3], `(2,4,0)`; both's active interval includes both Creates. |
| S2R03 | Shared tail retained / U-tail-demand | Distinct roots A and B, shared C. bump reuses A but must create replacement tail N0=5; later sum(ys) remains 9+4=13. first(changed)=-1, total 12, `(1,1,4)`. Root-only disjointness is insufficient. |
| S2O01 | Extra holder dropped first / U-drop-extra | first(alias) releases its shared A holder without allocating or detaching; by bump Enter only xs holds A. Two Writes, [2,3], `(0,2,0)`. |
| S2O02 | Ordinary forwarding helper / U-forward | Caller builds [-4], forward transfers it into demanded bump. bump writes -3, interval Create=0; global `(1,1,0)`. Conservative refusal is a usefulness limitation. |

Empty/singleton predictions are separately tabulated in predictions.json.
They test the genuine branch boundaries, including removing the singleton when
it matches and retaining it when it does not. Sorting/merge principal inputs
use distinct values and force both comparison outcomes. Mixed signs distinguish
running totals from bump and positive filtering from mere nonzero filtering.

The generic zero-Create reasoning above is a proposed informal acceptance
justification, not a proof and not permission to assume recursive summaries.
The future simultaneous-recursion proof must justify all demanded declarations.
