import Full.Inspect

/-! Local F1 effect accounting at the atomic transfer and metadata boundaries.
No reachability, heap invariant, or progress hypothesis is required. -/
namespace Full.Proofs
open Counted

set_option maxHeartbeats 4000000 in
theorem transition_effects (p : Program) (s : State) (change : Change)
    (ha : s.answer = none) (h : Counted.transition p s = .ok change) :
    ∃ effects, Inspect.effects s = .ok effects ∧
      change.state.events = s.events ++ effects ∧
      change.state.mem.record = s.mem.record ++ Inspect.cellEffects effects := by
  unfold Counted.transition at h
  simp only [Trial.Memory.setCount, Trial.Memory.markSetAside,
    Trial.Memory.writeInPlace, Trial.Memory.release,
    bind, pure, Except.bind, Except.pure] at h
  repeat' first
    | (simp_all [Inspect.effects, Inspect.cellEffects, Trial.Memory.create,
        Trial.Memory.updateCell, pure, Except.pure,
        throw, -List.find?_eq_none]; done)
    | split at h
    | cases h
  all_goals try cases (show Op from by assumption)
  all_goals simp_all [Inspect.effects, Inspect.cellEffects,
    Trial.Memory.updateCell, pure, Except.pure, throw,
    -List.find?_eq_none]
  all_goals subst_vars
  all_goals repeat' first
    | (simp_all [-List.find?_eq_none]; done)
    | split at *
  all_goals subst_vars
  all_goals simp_all
  all_goals
    rename_i hm
    exact (congrArg Trial.Memory.record hm).symm

theorem commit_effects (p : Program) (s : State) (change : Change)
    (ha : s.answer = none) (h : Counted.transition p s = .ok change) :
    ∃ effects, Inspect.effects s = .ok effects ∧
      (Counted.commit change).events = s.events ++ effects ∧
      (Counted.commit change).mem.record = s.mem.record ++ Inspect.cellEffects effects := by
  exact transition_effects p s change ha h

end Full.Proofs
