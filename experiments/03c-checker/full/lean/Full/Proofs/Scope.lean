import Full.Inspect
import Proofs.Healthy

namespace Full.Proofs
open Counted

theorem parameter_scope (params : List (String × Kind)) (args : List Slot)
    (next invocation : Nat) (name : String) (hlen : params.length = args.length) :
    (((params.zip args).zipIdx.map fun (((x,_),v),i) =>
      makeBinding (next+i) x v invocation s!"{name}/parameter/{x}").reverse.map
      (fun b => (b.record.name,b.record.id))) =
    (params.zipIdx.map fun ((x,_),i) => (x,next+i)).reverse := by
  rw [List.map_reverse, List.map_map]
  congr 1
  suffices h : ∀ k, ((params.zip args).zipIdx k).map
      (fun q => (q.1.1.1,next+q.2)) =
      (params.zipIdx k).map (fun q => (q.1.1,next+q.2)) by
    simpa only [makeBinding, Function.comp_def] using h 0
  intro k
  induction params generalizing args k with
  | nil => cases args <;> simp_all
  | cons x xs ih =>
    cases args with
    | nil => simp at hlen
    | cons v vs =>
      simp only [List.length_cons, Nat.succ.injEq] at hlen
      simpa only [List.zip_cons_cons, List.zipIdx_cons, List.map_cons] using
        congrArg (fun ys => (x.1,next+k) :: ys) (ih vs hlen (k+1))

set_option maxHeartbeats 2000000 in
theorem transition_scope (p : Program) (s : State) (change : Change)
    (h : Counted.transition p s = .ok change) :
    Inspect.nextScope p s = .ok change.state.entered := by
  cases ht : s.tasks with
  | nil => simp [Counted.transition, ht] at h
  | cons task rest =>
    unfold Counted.transition at h
    unfold Inspect.nextScope
    cases task <;> simp only [ht] at *
    all_goals
      try simp only [Trial.Proofs.except_bind_eq_ok] at h
      repeat any_goals
        first
        | (simp_all [Except.pure, Except.bind, pure, bind, Inspect.link, makeBinding]; done)
        | subst change
        | split at h
        | obtain ⟨_, _, h⟩ := h
        | simp only [Trial.Proofs.except_bind_eq_ok] at h
      all_goals simp_all [Except.pure, pure, Inspect.link, makeBinding]
    case h_2 =>
      rename_i x1 x2 fst id heq1 x3 b heq2 x4 hn
      cases hv : b.record.value <;> simp_all
      rename_i addr
      cases addr <;> simp_all
    case h_1.isFalse =>
      rename_i name arity ctx x f heq hg
      have hl := congrArg List.length hg.2
      simp only [List.length_reverse, List.length_take, List.length_map] at hl
      have hp := parameter_scope f.params (s.slots.take arity).reverse
        s.nextBinding s.nextInvocation name (by simpa using hl.symm)
      have hp' := congrArg List.reverse hp
      simpa only [List.map_reverse, List.reverse_reverse, List.map_map, makeBinding,
        Function.comp_def] using hp'.symm

end Full.Proofs
