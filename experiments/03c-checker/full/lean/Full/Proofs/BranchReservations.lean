import Full.Proofs.ReservedReadiness

namespace Full.Proofs.BranchReservations
open Counted

/-- Tickets waiting to decompose and reservations share the same globally
fresh branch-id namespace. Consuming a ticket may turn it into a reservation. -/
def pending : List Task → List Nat
  | [] => []
  | .decompose _ _ _ bid _ :: ts => bid :: pending ts
  | _ :: ts => pending ts

theorem pending_append (xs ys : List Task) :
    pending (xs ++ ys) = pending xs ++ pending ys := by
  induction xs with
  | nil => rfl
  | cons x xs ih => cases x <;> simp [pending, ih]

theorem pending_dead (bs : List Binding) (env : Env) (future : List Task) :
    pending (dead bs env future) = [] := by
  obtain ⟨ns, he⟩ := SimulationInitial.dead_is_prefix bs env future
  rw [he]
  clear he
  induction ns with
  | nil => rfl
  | cons n ns ih => simpa [pending] using ih

theorem pending_arguments (args : List (Expr × Nat)) (ctx : Context) :
    pending (args.flatMap (fun (e,i) => [.eval e (child ctx i),.capture])) = [] := by
  induction args with
  | nil => rfl
  | cons a args ih => simpa [pending, pending_append] using ih

theorem pending_reserved (rs : List Reservation) :
    pending (rs.map (fun r => .freeReserved r.addr)) = [] := by
  induction rs with
  | nil => rfl
  | cons r rs ih => simp [pending, ih]

def Invariant (s : State) : Prop :=
  ∀ id, (pending s.tasks).count id +
    (s.reservations.filter (fun r => r.branch == id)).length ≤ 1 ∧
    (id ≥ s.nextBranch → (pending s.tasks).count id +
      (s.reservations.filter (fun r => r.branch == id)).length = 0)

theorem filter_bound (rs : List Reservation) (f : Reservation → Bool) (id : Nat) :
    ((rs.filter f).filter (fun r => r.branch == id)).length ≤
      (rs.filter (fun r => r.branch == id)).length := by
  exact (List.filter_sublist.filter _).length_le

theorem filtered (rs : List Reservation) (f : Reservation → Bool) (id n k : Nat)
    (h : n + (rs.filter (fun r => r.branch == id)).length ≤ 1 ∧
      (id ≥ k → n + (rs.filter (fun r => r.branch == id)).length = 0)) :
    n + ((rs.filter f).filter (fun r => r.branch == id)).length ≤ 1 ∧
      (id ≥ k → n + ((rs.filter f).filter (fun r => r.branch == id)).length = 0) := by
  have hb := filter_bound rs f id
  constructor <;> omega

set_option maxHeartbeats 2000000 in
theorem transition_invariant (hi : Invariant s)
    (ht : Counted.transition p s = .ok c) : Invariant c.state := by
  cases he : s.tasks with
  | nil => simp [Counted.transition, he] at ht
  | cons task rest =>
    cases task
    all_goals simp only [Counted.transition, he, bind, pure, Except.bind, Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals intro id
    all_goals have hh := hi id
    all_goals simp only [he, pending] at hh
    all_goals dsimp only [Invariant]
    all_goals try simp only [pending_append, pending_dead, pending_arguments,
      pending_reserved, pending, List.nil_append, List.append_nil,
      List.filter_cons]
    all_goals try exact hh
    all_goals try exact filtered _ _ _ _ _ hh
    all_goals try simp only [List.singleton_append, List.count_cons] at hh ⊢
    all_goals repeat' first | split | split at hh
    all_goals try simp_all only [List.length_cons, beq_iff_eq]
    all_goals try solve
      | constructor <;> omega
    all_goals by_cases hn : id = s.nextBranch
    all_goals simp_all
    all_goals intro h; exact hh.2 (by omega)

theorem begin_invariant (hb : Counted.begin p initial = .ok first) : Invariant first := by
  obtain ⟨_,_,_,_,_,rfl⟩ := Initial.begin_shape p initial first hb
  intro id
  simp [pending_append, pending_dead, pending]

theorem advance_invariant (hs : Invariant s)
    (ht : Counted.advance p n s = .ok t) : Invariant t := by
  induction n generalizing s with
  | zero => cases ht; exact hs
  | succ n ih =>
    cases ha : s.answer with
    | some v => simp [Counted.advance, ha] at ht; subst t; exact hs
    | none =>
      cases hc : Counted.transition p s with
      | error why => simp [Counted.advance, Counted.step, ha, hc] at ht
      | ok c =>
        simp [Counted.advance, Counted.step, ha, hc] at ht
        exact ih (s := commit c) (transition_invariant hs hc) ht

theorem reachable_invariant (hr : Statements.Reachable p initial s) : Invariant s := by
  obtain ⟨first,n,hb,hn⟩ := hr
  exact advance_invariant (begin_invariant hb) hn

theorem reachable_bound (hr : Statements.Reachable p initial s) (inv bid : Nat) :
    (s.reservations.filter (fun r => r.invocation == inv && r.branch == bid)).length ≤ 1 := by
  have hh := (reachable_invariant hr bid).1
  have hf : (s.reservations.filter (fun r => r.invocation == inv && r.branch == bid)).length ≤
      (s.reservations.filter (fun r => r.branch == bid)).length := by
    have he : s.reservations.filter (fun r => r.invocation == inv && r.branch == bid) =
        (s.reservations.filter (fun r => r.invocation == inv)).filter (fun r => r.branch == bid) := by
      simp [List.filter_filter, Bool.and_comm]
    rw [he]
    exact filter_bound _ _ _
  omega

end Full.Proofs.BranchReservations
