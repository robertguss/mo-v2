import Full.Proofs.ForwardBindingsEnvironment
import Full.Proofs.Invariance
import Full.Proofs.BranchReservations

namespace Full.Proofs.ForwardCleanup
open Counted Statements Forward

/-- Successful focus decoding depends only on the immutable binding data. -/
theorem focus_success (ht : Counted.transition p s = .ok c)
    (he : Control.focus s n tasks values = .ok a) :
    Control.focus c.state n tasks values = .ok a := by
  induction n generalizing tasks values a with
  | zero => simp [Control.focus] at he
  | succ n ih =>
    unfold Control.focus at he ⊢
    split at he <;> try simp_all only
    all_goals repeat' first | split at he | contradiction
    all_goals try simp only [Trial.Proofs.except_bind_eq_ok] at he ⊢
    all_goals repeat' first | obtain ⟨x, hx, he⟩ := he | cases he
    all_goals simp_all [ForwardBindings.env_success ht,
      ForwardBindings.continuations_success ht, ih]

inductive Giving : Task → Prop
  | binding (id) : Giving (.giveBinding id)
  | pending : Giving .givePending

theorem focus_optional_free (s : State) (b : Prop) [Decidable b] (addr : Nat)
    (rest : List Task) (vs : List Slot) :
    Control.focus s ((if b then .free addr :: rest else rest).length + 2)
      (if b then .free addr :: rest else rest) vs =
      Control.focus s (rest.length + 2) rest vs := by
  by_cases hb : b <;> simp only [hb, ↓reduceIte] <;> rfl

set_option maxHeartbeats 2000000 in
theorem giving_step (hg : Giving task) (hr : Reachable p initial s)
    (hs : s.tasks = task :: rest) (ha : s.answer = none)
    (hrel : Related a s) (ht : Counted.step p s = .ok t) :
    Related a t ∧ Control.rank t < Control.rank s := by
  obtain ⟨c, hc, rfl⟩ := step_commit ha ht
  have hf : ∀ n tasks values, Control.focus s n tasks values = .ok a →
      Control.focus c.state n tasks values = .ok a := fun _ _ _ he => focus_success hc he
  unfold Related Control.decode at hrel
  rw [ha, hs] at hrel
  dsimp only at hrel
  cases hg
  all_goals cases hv : s.slots
  all_goals simp only [hv, List.length_cons, Control.focus] at hrel
  all_goals try contradiction
  all_goals
    simp [Counted.transition, hs, hv] at hc
    dsimp only [Trial.Memory.setCount, Trial.Memory.updateCell,
      pure, Except.pure, bind, Except.bind] at hc
    repeat' first
      | simp only [Except.ok.injEq, reduceCtorEq, *] at hc
      | cases hc
      | split at hc
      | contradiction
  all_goals try solve | simp_all
  all_goals try solve | rename_i h; exact h _ _ (by assumption)
  all_goals
    constructor
    · unfold Related
      rw [decode_commit]
      simp only [Control.decode, ha]
      rw [focus_optional_free]
      apply hf
      simpa only [Control.focus, *] using hrel
    · simp only [Control.rank, commit, hs, ← List.sum_eq_foldl_nat,
        List.map_cons, List.sum_cons, List.length_map]
      split <;> simp_all <;> omega

theorem giveBinding_step (hr : Reachable p initial s)
    (hs : s.tasks = .giveBinding bid :: rest) (ha : s.answer = none)
    (hrel : Related a s) (ht : Counted.step p s = .ok t) :
    Related a t ∧ Control.rank t < Control.rank s :=
  giving_step (.binding bid) hr hs ha hrel ht

theorem givePending_step (hr : Reachable p initial s)
    (hs : s.tasks = .givePending :: rest) (ha : s.answer = none)
    (hrel : Related a s) (ht : Counted.step p s = .ok t) :
    Related a t ∧ Control.rank t < Control.rank s :=
  giving_step .pending hr hs ha hrel ht

theorem handoffMatch_step (hr : Reachable p initial s)
    (hs : s.tasks = .handoffMatch ctx :: rest) (ha : s.answer = none)
    (hrel : Related a s) (ht : Counted.step p s = .ok t) :
    Related a t ∧ Control.rank t < Control.rank s := by
  obtain ⟨c, hc, rfl⟩ := step_commit ha ht
  have hf : ∀ n tasks values, Control.focus s n tasks values = .ok a →
      Control.focus c.state n tasks values = .ok a := fun _ _ _ he => focus_success hc he
  cases hv : s.slots with
  | nil => simp [Counted.transition, hs, hv] at hc
  | cons v vs =>
    simp [Counted.transition, hs, hv] at hc
    cases hc
    simp only [ha] at hf
    constructor
    · unfold Related at hrel ⊢
      rw [decode_commit]
      simp only [Control.decode, ha]
      apply hf
      simpa only [Control.decode, ha, hs, hv, List.length_cons, Control.focus] using hrel
    · simp only [Control.rank, commit, hs, ← List.sum_eq_foldl_nat,
        List.map_cons, List.sum_cons]
      omega

set_option maxHeartbeats 2000000 in
theorem freeReserved_step (hr : Reachable p initial s)
    (hs : s.tasks = .freeReserved addr :: rest) (ha : s.answer = none)
    (hrel : Related a s) (ht : Counted.step p s = .ok t) :
    Related a t ∧ Control.rank t < Control.rank s := by
  obtain ⟨c, hc, rfl⟩ := step_commit ha ht
  have hf : ∀ n tasks values, Control.focus s n tasks values = .ok a →
      Control.focus c.state n tasks values = .ok a := fun _ _ _ he => focus_success hc he
  simp only [Counted.transition, hs] at hc
  dsimp only [Trial.Memory.release, pure, Except.pure, bind, Except.bind] at hc
  repeat' first
    | simp only [Except.ok.injEq, reduceCtorEq, *] at hc
    | cases hc
    | split at hc
    | contradiction
  all_goals
    constructor
    · unfold Related at hrel ⊢
      rw [decode_commit]
      simp only [Control.decode, ha]
      apply hf
      simpa only [Control.decode, ha, hs, List.length_cons, Control.focus] using hrel
    · have hle := List.length_filter_le (fun d : Trial.Cell => d.addr != addr) s.mem.cells
      simp only [Control.rank, commit, hs, ← List.sum_eq_foldl_nat,
        List.map_cons, List.sum_cons]
      omega

theorem focus_reserved_prefix (s : State) (rs : List Reservation)
    (ctx : Context) (rest : List Task) (vs : List Slot) :
    Control.focus s ((rs.map (fun r => Task.freeReserved r.addr) ++ Task.handoffMatch ctx :: rest).length + 2)
      (rs.map (fun r => .freeReserved r.addr) ++ .handoffMatch ctx :: rest) vs =
      Control.focus s (rest.length + 2) rest vs := by
  induction rs with
  | nil => rfl
  | cons r rs ih =>
    simpa only [List.map_cons, List.cons_append, List.length_cons, Control.focus] using ih

theorem branchResult_related (hr : Reachable p initial s)
    (hs : s.tasks = .branchResult bid inner outer :: rest) (ha : s.answer = none)
    (hrel : Related a s) (ht : Counted.step p s = .ok t) : Related a t := by
  obtain ⟨c, hc, rfl⟩ := step_commit ha ht
  have hf : ∀ n tasks values, Control.focus s n tasks values = .ok a →
      Control.focus c.state n tasks values = .ok a := fun _ _ _ he => focus_success hc he
  cases hv : s.slots with
  | nil => simp [Counted.transition, hs, hv] at hc
  | cons v vs =>
    simp [Counted.transition, hs, hv] at hc
    cases hc
    simp only [ha] at hf
    unfold Related at hrel ⊢
    rw [decode_commit]
    simp only [Control.decode, ha]
    rw [focus_reserved_prefix]
    apply hf
    simpa only [Control.decode, ha, hs, hv, List.length_cons, Control.focus] using hrel

theorem rank_reserved_prefix (s : State) (rs : List Reservation)
    (ctx : Context) (rest : List Task) :
    Control.rank {s with tasks := rs.map (fun r => .freeReserved r.addr) ++ .handoffMatch ctx :: rest} =
      Control.rank {s with tasks := rest} + 2 * rs.length + 1 := by
  simp only [Control.rank, ← List.sum_eq_foldl_nat, List.map_append,
    List.sum_append, List.map_cons, List.sum_cons, List.map_map, Function.comp_def]
  induction rs with
  | nil => simp; omega
  | cons r rs ih => simp only [List.map_cons, List.sum_cons, List.length_cons] at ih ⊢; omega

/-- Rank decrease under the branch reservation bound. -/
theorem branchResult_step_of_bound (hr : Reachable p initial s)
    (hs : s.tasks = .branchResult bid inner outer :: rest) (ha : s.answer = none)
    (hrel : Related a s) (ht : Counted.step p s = .ok t)
    (hb : (s.reservations.filter (fun r => r.invocation == inner.invocation && r.branch == bid)).length ≤ 1) :
    Related a t ∧ Control.rank t < Control.rank s := by
  refine ⟨branchResult_related hr hs ha hrel ht, ?_⟩
  obtain ⟨c, hc, rfl⟩ := step_commit ha ht
  cases hv : s.slots with
  | nil => simp [Counted.transition, hs, hv] at hc
  | cons v vs =>
    simp only [Counted.transition, hs, hv, pure, Except.pure] at hc
    cases hc
    simp only [List.append_assoc, List.cons_append, List.nil_append]
    change Control.rank {s with entered := inner.env, tasks := (s.reservations.filter (fun r => r.invocation == inner.invocation && r.branch == bid)).map (fun r => .freeReserved r.addr) ++ .handoffMatch outer :: rest} < Control.rank s
    rw [rank_reserved_prefix {s with entered := inner.env} _ outer rest]
    simp only [Control.rank, hs, ← List.sum_eq_foldl_nat, List.map_cons, List.sum_cons]
    omega

/-- Actual reachability supplies branch uniqueness; no external bound is needed. -/
theorem branchResult_step (hr : Reachable p initial s)
    (hs : s.tasks = .branchResult bid inner outer :: rest) (ha : s.answer = none)
    (hrel : Related a s) (ht : Counted.step p s = .ok t) :
    Related a t ∧ Control.rank t < Control.rank s :=
  branchResult_step_of_bound hr hs ha hrel ht
    (BranchReservations.reachable_bound hr inner.invocation bid)

end Full.Proofs.ForwardCleanup
