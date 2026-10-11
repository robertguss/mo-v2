import Full.Proofs.ControlShape

namespace Full.Proofs.ReservationAccounted
open Counted

/-- Every reservation has saved work which will discharge it. -/
def Cleans (r : Reservation) : Task → Prop
  | .freeReserved addr => addr = r.addr
  | .branchResult bid inner _ => inner.invocation = r.invocation ∧ bid = r.branch
  | _ => False

def Accounted (s : State) : Prop :=
  ∀ r ∈ s.reservations, ∃ task ∈ s.tasks, Cleans r task

theorem begin_accounted (hb : Counted.begin p initial = .ok first) : Accounted first := by
  obtain ⟨_,_,_,_,_,rfl⟩ := Initial.begin_shape p initial first hb
  simp [Accounted]

theorem saved (hs : Accounted s) (he : s.tasks = task :: rest)
    (hr : r ∈ s.reservations) : Cleans r task ∨ ∃ t ∈ rest, Cleans r t := by
  obtain ⟨t,hm,hc⟩ := hs r hr
  rw [he] at hm
  rcases List.mem_cons.mp hm with rfl | hm
  · exact Or.inl hc
  · exact Or.inr ⟨t,hm,hc⟩

theorem suffix (rs : List Reservation) (ts : List Task)
    (hs : Accounted s) (he : s.tasks = task :: rest)
    (hhead : ∀ r, ¬ Cleans r task)
    (hrs : ∀ r ∈ rs, r ∈ s.reservations)
    (hts : ∀ t ∈ rest, t ∈ ts) :
    ∀ r ∈ rs, ∃ t ∈ ts, Cleans r t := by
  intro r hr
  rcases saved hs he (hrs r hr) with hc | ⟨t,hm,hc⟩
  · exact False.elim (hhead r hc)
  · exact ⟨t,hts t hm,hc⟩

set_option maxHeartbeats 2000000 in
theorem transition_accounted (hs : Accounted s)
    (ht : Counted.transition p s = .ok c) : Accounted c.state := by
  cases he : s.tasks with
  | nil => simp [Counted.transition, he] at ht
  | cons task rest =>
    cases task
    all_goals simp only [Counted.transition, he, bind, pure, Except.bind, Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals unfold Accounted
    all_goals dsimp only
    all_goals try solve |
      apply suffix _ _ hs he
      · intro r; simp [Cleans]
      · intro r hr
        first | exact hr | exact (List.mem_filter.mp hr).1
      · intro t hm; simp [hm]
    all_goals intro r hr
    all_goals try simp only [List.mem_cons, List.mem_filter] at hr
    all_goals first
      | (rcases hr with rfl | hr
         · simp [Cleans]
         · rcases saved hs he hr with hc | ⟨t,hm,hc⟩
           · simp [Cleans] at hc
           · exact ⟨t,by simp [hm],hc⟩)
      | (rcases saved hs he hr with hc | ⟨t,hm,hc⟩
         · simp only [Cleans] at hc
           refine ⟨.freeReserved r.addr, ?_, by simp [Cleans]⟩
           apply List.mem_append_left
           apply List.mem_append_left
           apply List.mem_map.mpr
           exact ⟨r,List.mem_filter.mpr ⟨hr,by simp [hc.1,hc.2]⟩,rfl⟩
         · exact ⟨t,by simp [hm],hc⟩)
      | (rcases hr with ⟨hr,hne⟩
         rcases saved hs he hr with hc | ⟨t,hm,hc⟩
         · simp_all [Cleans]
         · exact ⟨t,hm,hc⟩)

theorem commit_accounted (c : Change) : Accounted (commit c) ↔ Accounted c.state := by
  rfl

theorem advance_accounted (hs : Accounted s)
    (ht : Counted.advance p n s = .ok t) : Accounted t := by
  induction n generalizing s with
  | zero => cases ht; exact hs
  | succ n ih =>
    cases ha : s.answer with
    | some v => simp [Counted.advance,ha] at ht; subst t; exact hs
    | none =>
      cases hc : Counted.transition p s with
      | error why => simp [Counted.advance,Counted.step,ha,hc] at ht
      | ok c =>
        simp [Counted.advance,Counted.step,ha,hc] at ht
        exact ih (s := commit c) (transition_accounted hs hc) ht

theorem reachable_accounted (hr : Statements.Reachable p initial s) : Accounted s := by
  obtain ⟨first,n,hb,hn⟩ := hr
  exact advance_accounted (begin_accounted hb) hn

theorem no_reservations_of_empty (hs : Accounted s) (ht : s.tasks = []) :
    s.reservations = [] := by
  apply List.eq_nil_iff_forall_not_mem.mpr
  intro r hr
  obtain ⟨t,hm,_⟩ := hs r hr
  simp [ht] at hm

/-- Terminal cleanup follows from actual reachability, without F1. -/
theorem answered_no_reservations (hr : Statements.Reachable p initial s)
    (ha : s.answer.isSome = true) : s.reservations = [] :=
  no_reservations_of_empty (reachable_accounted hr) ((ControlShape.reachable_shape hr).2 ha)

end Full.Proofs.ReservationAccounted
