import Full.Proofs.ProgressHeap

/-! Universal case reduction for transition progress.

This file does NOT establish unconditional universal progress. All heap and
typing checks have been discharged except four structural readiness facts.
`StructuralReady` names those facts explicitly; it is not an axiom and is not
claimed to follow from reachability. In particular the theorem below must not
be substituted for the unconditional stage-1 progress target.
-/
namespace Full.Proofs.Progress
open Counted

def StructuralTask : Task → Prop
  | .decompose _ _ _ _ _ | .givePending | .free _ | .freeReserved _ => True
  | _ => False

/-- The only remaining premises are source structural readiness, not successful
execution, heap preservation, F1, or a strengthened `validStart`. -/
def StructuralReady (s : State) : Prop :=
  ∀ task rest, s.tasks = task :: rest →
    match task with
    | .decompose _ _ _ _ _ | .givePending =>
      ∃ v slots addr, s.slots = v :: slots ∧ v.raw = .list (some addr)
    | .free addr =>
      ∃ c, s.mem.find? addr = some c ∧ c.status = .live ∧ c.count = 0
    | .freeReserved addr => ∃ r ∈ s.reservations, r.addr = addr
    | _ => True

theorem progress_nonstructural (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : s.tasks = task :: rest) (hn : ¬ StructuralTask task) :
    ∃ c, Counted.transition p s = .ok c := by
  by_cases hh : HeapTask task
  · cases task <;> simp_all [HeapTask,StructuralTask]
    · rename_i e ctx
      cases e <;> simp_all [HeapTask]
      exact variable_progress hr hi ht
    · rename_i op ctx
      cases op <;> simp_all [HeapTask]
      exact cons_progress hr hi ht
    · exact binding_progress hr hi ht
  · exact control_progress hr ht hh

/-- Complete transition case split, conditional only on the explicitly named
structural readiness obligation. Reachability alone supplies all typing,
lexical identity, liveness, arity, frame, and task-existence premises. -/
theorem progress_of_ready (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true) (ha : s.answer = none)
    (hready : StructuralReady s) : ∃ c, Counted.transition p s = .ok c := by
  obtain ⟨task,rest,ht⟩ := Residual.reachable_task hr ha
  by_cases hn : StructuralTask task
  · have hs := hready task rest ht
    cases task <;> simp only [StructuralTask] at hn <;> try contradiction
    · obtain ⟨v,slots,addr,hv,hraw⟩ := hs
      exact decompose_progress hi ht hv hraw
    · obtain ⟨v,slots,addr,hv,hraw⟩ := hs
      exact pending_progress hi ht hv hraw
    · exact free_progress hi ht hs
    · exact reserved_progress hi ht hs
  · exact progress_nonstructural hr hi ht hn

/-- Any counterexample to progress must be one of the four remaining
structural cases. This theorem itself has no structural readiness premise. -/
theorem failure_is_structural (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true) (ha : s.answer = none)
    (he : Counted.transition p s = .error error) :
    ∃ task rest, s.tasks = task :: rest ∧ StructuralTask task := by
  obtain ⟨task,rest,ht⟩ := Residual.reachable_task hr ha
  refine ⟨task,rest,ht,?_⟩
  apply Classical.byContradiction
  intro hn
  obtain ⟨c,hc⟩ := progress_nonstructural hr hi ht hn
  rw [he] at hc
  cases hc

end Full.Proofs.Progress
