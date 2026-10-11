import Full.Proofs.Basic

namespace Full.Demand.Events
open Counted

/-- The concrete event stream has a stack of open invocation IDs, and Enter
uses the next fresh ID. Cell events do not change that stack. -/
inductive Trace : List Event → List Nat → Nat → Prop
  | empty : Trace [] [] 1
  | create (h : Trace es ids next) : Trace (es ++ [.create a x t]) ids next
  | write (h : Trace es ids next) : Trace (es ++ [.write a x t]) ids next
  | free (h : Trace es ids next) : Trace (es ++ [.free a]) ids next
  | enter (h : Trace es ids next) (fresh : f.id = next) :
      Trace (es ++ [.enter f]) (f.id :: ids) (next+1)
  | returning {id : Nat} (h : Trace es (id :: ids) next) :
      Trace (es ++ [.returning id v]) ids next

def Invariant (s : State) : Prop := Trace s.events (s.frames.map Frame.id) s.nextInvocation

/-- One machine action, projected to invocation bookkeeping and primitive
events. No allocation or checker assumption appears in this relation. -/
inductive Extension (es : List Event) (ids : List Nat) (next : Nat) :
    List Event → List Nat → Nat → Prop
  | same : Extension es ids next es ids next
  | create : Extension es ids next (es ++ [.create a x t]) ids next
  | write : Extension es ids next (es ++ [.write a x t]) ids next
  | free : Extension es ids next (es ++ [.free a]) ids next
  | enter (fresh : f.id = next) :
      Extension es ids next (es ++ [.enter f]) (f.id :: ids) (next+1)
  | returning {id : Nat} (top : ids = id :: tail) :
      Extension es ids next (es ++ [.returning id v]) tail next

theorem Extension.trace (hs : Trace es ids next) (h : Extension es ids next es' ids' next') :
    Trace es' ids' next' := by
  cases h with
  | same => exact hs
  | create => exact Trace.create hs
  | write => exact Trace.write hs
  | free => exact Trace.free hs
  | enter hf => exact Trace.enter hs hf
  | returning htop => rw [htop] at hs; exact Trace.returning hs

theorem begin_invariant (hb : Counted.begin p initial = .ok s) : Invariant s := by
  simp only [Counted.begin, bind, pure, Except.bind, Except.pure] at hb
  repeat' first | split at hb | cases hb | contradiction
  exact Trace.empty

set_option maxHeartbeats 2000000 in
theorem transition_extension (ht : Counted.transition p s = .ok c) :
    Extension s.events (s.frames.map Frame.id) s.nextInvocation
      c.state.events (c.state.frames.map Frame.id) c.state.nextInvocation := by
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    cases task
    all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals try first
      | exact Extension.same
      | exact Extension.create
      | exact Extension.write
      | exact Extension.free
      | (apply Extension.enter; rfl)
    all_goals simp_all [bne_iff_ne]
    all_goals exact Extension.returning rfl

theorem transition_invariant (hs : Invariant s)
    (ht : Counted.transition p s = .ok c) : Invariant c.state :=
  (transition_extension ht).trace hs

theorem step_invariant (hs : Invariant s) (ht : Counted.step p s = .ok t) :
    Invariant t := by
  unfold Counted.step at ht
  split at ht
  · cases ht; exact hs
  · simp only [bind, pure, Except.bind, Except.pure] at ht
    split at ht
    · cases ht
    · cases ht
      exact transition_invariant hs (by assumption)

theorem advance_invariant (hs : Invariant s) (ht : Counted.advance p n s = .ok t) :
    Invariant t := by
  induction n generalizing s with
  | zero => cases ht; exact hs
  | succ n ih =>
    unfold Counted.advance at ht
    split at ht
    · cases ht; exact hs
    · simp only [bind, pure, Except.bind, Except.pure] at ht
      split at ht
      · cases ht
      · exact ih (step_invariant hs (by assumption)) ht

theorem reachable_invariant (hr : Statements.Reachable p initial s) : Invariant s := by
  obtain ⟨first,n,hb,ha⟩ := hr
  exact advance_invariant (begin_invariant hb) ha

theorem frame_bound (h : Trace es ids next) : ∀ id ∈ ids, id < next := by
  induction h with
  | empty => simp
  | create _ ih | write _ ih | free _ ih => exact ih
  | enter _ hf ih =>
    intro id hm
    rcases List.mem_cons.mp hm with rfl | hm
    · omega
    · have := ih id hm; omega
  | returning _ ih => exact fun id hm => ih id (List.mem_cons_of_mem _ hm)

theorem next_positive (h : Trace es ids next) : 0 < next := by
  induction h <;> omega

theorem frames_ordered (h : Trace es ids next) : ids.Pairwise (fun a b => b < a) := by
  induction h with
  | empty => exact .nil
  | create _ ih | write _ ih | free _ ih => exact ih
  | enter h hf ih =>
    exact .cons (fun id hm => by have := frame_bound h id hm; omega) ih
  | returning _ ih => exact ih.tail

theorem head_ge {id top : Nat} (h : Trace es (top::ids) next) (hm : id ∈ top::ids) :
    id ≤ top := by
  rcases List.mem_cons.mp hm with rfl | hm
  · exact Nat.le_refl _
  · exact Nat.le_of_lt ((List.pairwise_cons.mp (frames_ordered h)).1 _ hm)

theorem frames_nodup (h : Trace es ids next) : ids.Nodup := by
  induction h with
  | empty => simp
  | create _ ih | write _ ih | free _ ih => exact ih
  | enter h hf ih =>
    apply List.nodup_cons.mpr
    exact ⟨fun hm => by have := frame_bound h _ hm; omega, ih⟩
  | returning _ ih => exact (List.nodup_cons.mp ih).2

/-- The exact fold in the frozen Creates definition, retaining its active bit. -/
def tally (id : Nat) (es : List Event) : Bool × Nat :=
  es.foldl (fun (active,n) event => match event with
    | .enter f => (active || f.id == id,n)
    | .returning i _ => (active && i != id,n)
    | .create _ _ _ => (active,n + if active then 1 else 0)
    | _ => (active,n)) (false,0)

theorem creates_eq (id : Nat) (es : List Event) : Statements.creates id es = (tally id es).2 := rfl

theorem tally_active {id : Nat} (h : Trace es ids next) : (tally id es).1 = ids.contains id := by
  induction h with
  | empty => rfl
  | create _ ih | write _ ih | free _ ih => simpa [tally,List.foldl_append] using ih
  | enter _ _ ih =>
    simp only [tally,List.foldl_append,List.foldl_cons,List.foldl_nil] at ih ⊢
    rw [ih]
    apply Bool.eq_iff_iff.mpr
    simp only [Bool.or_eq_true, beq_iff_eq, List.contains_iff_mem, List.mem_cons]
    grind
  | returning h ih =>
    have hn := (List.nodup_cons.mp (frames_nodup h)).1
    simp only [tally,List.foldl_append,List.foldl_cons,List.foldl_nil] at ih ⊢
    rw [ih]
    rename_i _ returned
    by_cases he : returned = id
    · subst id; simp_all
    · simp_all [List.contains_cons, beq_iff_eq, Ne.symm he]

theorem future_zero {id : Nat} (h : Trace es ids next) (hf : next ≤ id) :
    tally id es = (false,0) := by
  induction h with
  | empty => rfl
  | create _ ih | write _ ih | free _ ih | returning _ ih =>
    simp only [tally,List.foldl_append,List.foldl_cons,List.foldl_nil] at ih ⊢
    simp [ih hf]
  | @enter es ids next f _ fresh ih =>
    have hn : next ≤ id := by omega
    have hne : f.id ≠ id := by omega
    simp only [tally,List.foldl_append,List.foldl_cons,List.foldl_nil] at ih ⊢
    simp [ih hn,hne]

theorem Extension.closed {id : Nat} (hs : Trace es ids next)
    (h : Extension es ids next es' ids' next') (hf : id < next) (hn : id ∉ ids) :
    id < next' ∧ id ∉ ids' ∧ tally id es' = tally id es := by
  have ha : (tally id es).1 = false := by simpa [hn] using tally_active (id := id) hs
  cases h with
  | same => exact ⟨hf,hn,rfl⟩
  | create | write | free =>
    refine ⟨hf,hn,?_⟩
    apply Prod.ext <;> simp_all [tally,List.foldl_append]
  | @enter f fresh =>
    have hne : f.id ≠ id := by omega
    refine ⟨by omega, by simp [hne,Ne.symm hne,hn], ?_⟩
    apply Prod.ext <;> simp_all [tally,List.foldl_append]
  | returning htop =>
    refine ⟨hf, fun hm => hn (htop ▸ List.mem_cons_of_mem _ hm), ?_⟩
    apply Prod.ext <;> simp_all [tally,List.foldl_append]

theorem step_closed {id : Nat} (hs : Invariant s) (hf : id < s.nextInvocation)
    (hn : id ∉ s.frames.map Frame.id) (ht : Counted.step p s = .ok t) :
    id < t.nextInvocation ∧ id ∉ t.frames.map Frame.id ∧ tally id t.events = tally id s.events := by
  unfold Counted.step at ht
  split at ht
  · cases ht; exact ⟨hf,hn,rfl⟩
  · simp only [bind,pure,Except.bind,Except.pure] at ht
    split at ht
    · cases ht
    · cases ht
      exact (transition_extension (by assumption)).closed hs hf hn

/-- Once an invocation has returned, arbitrary later caller actions (including
Creates) cannot reopen its interval or change its already accumulated count. -/
theorem advance_closed {id : Nat} (hs : Invariant s) (hf : id < s.nextInvocation)
    (hn : id ∉ s.frames.map Frame.id) (ht : Counted.advance p n s = .ok t) :
    id < t.nextInvocation ∧ id ∉ t.frames.map Frame.id ∧ tally id t.events = tally id s.events := by
  induction n generalizing s with
  | zero => cases ht; exact ⟨hf,hn,rfl⟩
  | succ n ih =>
    unfold Counted.advance at ht
    split at ht
    · cases ht; exact ⟨hf,hn,rfl⟩
    · simp only [bind,Except.bind] at ht
      split at ht
      · cases ht
      · rename_i next hstep
        obtain ⟨hf',hn',he⟩ := step_closed hs hf hn hstep
        obtain ⟨hf'',hn'',he'⟩ := ih (step_invariant hs hstep) hf' hn' ht
        exact ⟨hf'',hn'',he'.trans he⟩

theorem transition_history (ht : Counted.transition p s = .ok c) :
    c.state.history = s.history := by
  unfold Counted.transition at ht
  simp only [bind,pure,Except.bind,Except.pure] at ht
  repeat' first | split at ht | cases ht | rfl

theorem begin_history (hb : Counted.begin p initial = .ok s) : s.history = [] := by
  simp only [Counted.begin,bind,pure,Except.bind,Except.pure] at hb
  repeat' first | split at hb | cases hb | rfl

/-- Recover the actual transfer behind the frozen last-action premise, even
when the advance witnessing reachability includes terminal stuttering. -/
theorem last_enter (hr : Statements.Reachable p initial s)
    (hl : s.history.getLast?.map Action.name = some "Enter") :
    ∃ before c, Statements.Reachable p initial before ∧
      Counted.transition p before = .ok c ∧ c.action.name = "Enter" ∧ s = commit c := by
  obtain ⟨first,n,hb,ha⟩ := hr
  induction n generalizing s with
  | zero => cases ha; simp [begin_history hb] at hl
  | succ n ih =>
    rw [Full.Proofs.f5.2.1 p first n 1] at ha
    cases hm : Counted.advance p n first with
    | error why => simp [hm,Except.bind] at ha
    | ok mid =>
      simp only [hm,Except.bind] at ha
      cases hans : mid.answer with
      | some v =>
        simp [Counted.advance,hans,pure,Except.pure] at ha
        subst s
        exact ih hl hm
      | none =>
        cases ht : Counted.transition p mid with
        | error why => simp [Counted.advance,Counted.step,hans,ht,Functor.map,Except.map] at ha
        | ok c =>
          simp [Counted.advance,Counted.step,hans,ht,Functor.map,Except.map] at ha
          subst s
          refine ⟨mid,c,⟨first,n,hb,hm⟩,ht,?_,rfl⟩
          simpa [commit] using hl

set_option maxHeartbeats 2000000 in
theorem transition_enter_zero (hs : Invariant s)
    (ht : Counted.transition p s = .ok c) (ha : c.action.name = "Enter")
    (hf : c.state.frames.head? = some f) : tally f.id c.state.events = (true,0) := by
  have hz := future_zero hs (Nat.le_refl s.nextInvocation)
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    cases task
    all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals simp only at ha hf
    all_goals try contradiction
    all_goals simp only [List.head?_cons, Option.some.injEq] at hf
    all_goals subst f
    all_goals simp only [tally,List.foldl_append,List.foldl_cons,List.foldl_nil] at hz ⊢
    all_goals simp [hz]

theorem entry_zero (hr : Statements.Reachable p initial s)
    (hl : s.history.getLast?.map Action.name = some "Enter")
    (hf : s.frames.head? = some f) : tally f.id s.events = (true,0) := by
  obtain ⟨before,c,hr',ht,ha,rfl⟩ := last_enter hr hl
  exact transition_enter_zero (reachable_invariant hr') ht ha hf

end Full.Demand.Events
