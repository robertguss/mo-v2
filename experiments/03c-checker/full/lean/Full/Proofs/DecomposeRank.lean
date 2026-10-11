import Full.Control

namespace Full.Proofs
open Trial

set_option maxHeartbeats 2000000 in
/-- Every successful Decompose transfer decreases the actual amended rank,
without heap invariants, reachability, or restrictions on the body. -/
theorem decompose_rank (p : Program) (s : Counted.State)
    (h t : String) (body : Expr) (bid : Nat) (ctx : Counted.Context)
    (rest : List Counted.Task) (change : Counted.Change)
    (ht : s.tasks = .decompose h t body bid ctx :: rest)
    (hc : Counted.transition p s = .ok change) :
    Control.rank change.state < Control.rank s := by
  simp only [Counted.transition, ht] at hc
  dsimp only [Memory.markSetAside, Memory.setCount, Memory.updateCell,
    pure, Except.pure, bind, Except.bind, Functor.map, Except.map] at hc
  repeat' first
    | simp only [Except.ok.injEq, reduceCtorEq, *] at hc
    | cases hc
    | split at hc
    | contradiction
  -- Both memory updates are maps, hence preserve cell-list length. The
  -- replacement weighs at most 10 (unique) or 11 (shared), versus 12.
  all_goals
    simp only [Control.rank, ← List.sum_eq_foldl_nat, ht, List.map_cons, List.sum_cons,
      List.length_map]
    cases body with
    | call name args =>
      cases args <;> (try simp_all) <;> (try split) <;> (try simp_all) <;> omega
    | _ =>
      try simp_all
      try split
      all_goals try simp_all
      all_goals omega

/-- Commit changes only metadata, so Decompose decreases rank there too. -/
theorem decompose_rank_commit (p : Program) (s : Counted.State)
    (h t : String) (body : Expr) (bid : Nat) (ctx : Counted.Context)
    (rest : List Counted.Task) (change : Counted.Change)
    (ht : s.tasks = .decompose h t body bid ctx :: rest)
    (hc : Counted.transition p s = .ok change) :
    Control.rank (Counted.commit change) < Control.rank s := by
  exact decompose_rank p s h t body bid ctx rest change ht hc

end Full.Proofs
