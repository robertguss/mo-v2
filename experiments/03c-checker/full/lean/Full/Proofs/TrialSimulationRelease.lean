import Full.Proofs.TrialRelease
import Full.Statements

namespace Full.Proofs.TrialSimulationRelease
open TrialCompatibilitySimulation TrialRelease

theorem reachable_advance (p : Program) (initial : Trial.Start)
    (s t : Counted.State) (n : Nat) (hr : Statements.Reachable p initial s)
    (he : Counted.advance p n s = .ok t) : Statements.Reachable p initial t := by
  obtain ⟨first, k, hb, hk⟩ := hr
  refine ⟨first, k+n, hb, ?_⟩
  rw [advance_add, hk]
  exact he

/-- Successful raw release derives its recursive ghost-edge certificate from
F1 at actual reachable free successors, not from an assumed simulation. -/
theorem cascade_of_success_f1 (hF1 : Statements.F1)
    (p : Program) (initial : Trial.Start) (rest : List Counted.Task)
    (slots : List Counted.Slot) (fuel : Nat) (s : Counted.State) (a : Nat)
    (log : List Trial.LogEvent) (u : Trial.RunState)
    (hr : Statements.Reachable p initial s)
    (v : Counted.Slot) (ht : s.tasks = .givePending :: rest)
    (hs : s.slots = v :: slots) (hv : v.raw = .list (some a))
    (ha : s.answer = none)
    (hsuccess : Trial.giveUp .approved fuel a (input s slots log) = (.ok (), u)) :
    Cascade rest slots fuel s a := by
  induction fuel generalizing s a log u v with
  | zero =>
    simp [Trial.giveUp] at hsuccess
    have h := congrArg Prod.fst hsuccess
    contradiction
  | succ fuel ih =>
    cases hf : s.mem.find? a with
    | none =>
      simp [Trial.giveUp, Trial.getCell, input, logged, observe, hf] at hsuccess
      have h := congrArg Prod.fst hsuccess
      contradiction
    | some c =>
      have hl : c.status = .live := by
        cases hc : c.status with
        | live => rfl
        | setAside =>
          simp [Trial.giveUp, Trial.getCell, input, logged, observe, hf, hc] at hsuccess
          have h := congrArg Prod.fst hsuccess
          contradiction
      have hn : c.count ≠ 0 := by
        intro hn
        simp [Trial.giveUp, Trial.getCell, input, logged, observe, hf, hl, hn] at hsuccess
        have h := congrArg Prod.fst hsuccess
        contradiction
      by_cases hone : c.count = 1
      · obtain ⟨tail, he, hread⟩ := edge_from_invariant initial s a c
          (hF1.2 p initial s hr).1 hf hl
        rw [trial_exclusive s a c tail rest slots log fuel hf hl hone] at hsuccess
        cases hc : c.link with
        | none => exact .last s a c tail fuel hf hl hone he hread hc
        | some b =>
          apply Cascade.next s a b c tail fuel hf hl hone he hread hc
          let f := Counted.commit (freeChange (Counted.commit (giveChange s a c rest slots))
            a { c with count := 0 } tail rest)
          have hex : Counted.advance p 2 s = .ok f :=
            exclusive_steps p s a c tail rest v slots ht hs hv ha hf hl hone he
          apply ih f b (log ++ [.free a]) u
            (reachable_advance p initial s f 2 hr hex) ⟨.list c.link,tail⟩
          · simp [f, Counted.commit, freeChange, hc]
          · simp [f, Counted.commit, freeChange, giveChange, hc]
          · simp [hc]
          · exact ha
          · simpa only [f, hc] using hsuccess
      · exact .shared s a c fuel hf hl (by omega)

theorem pending_release_of_success_f1 (hF1 : Statements.F1)
    (p : Program) (initial : Trial.Start) (rest : List Counted.Task)
    (slots : List Counted.Slot) (fuel : Nat) (s : Counted.State) (a : Nat)
    (u : Trial.RunState) (hr : Statements.Reachable p initial s)
    (v : Counted.Slot) (ht : s.tasks = .givePending :: rest)
    (hs : s.slots = v :: slots) (hv : v.raw = .list (some a))
    (ha : s.answer = none)
    (hsuccess :
      (do Trial.popPending (.list (some a)); Trial.giveUp .approved fuel a : Trial.M Unit)
        (observe s) = (.ok (), u)) :
    ∃ ticks t, 0 < ticks ∧ ticks ≤ 2*fuel ∧
      Counted.advance p ticks s = .ok t ∧ Statements.Reachable p initial t ∧
      t.tasks = rest ∧ t.slots = slots ∧ t.answer = none ∧
      eraseLog u = observe t ∧ u.mem = t.mem ∧
      u.mem.record = t.mem.record ∧ u.snaps = t.landmarks := by
  have hpop : Trial.popPending (.list (some a)) (observe s) =
      (.ok (), input s slots []) := by
    simp [Trial.popPending, observe, input, logged, Counted.pending, hs, hv]
  have hraw := hsuccess
  simp only [Trial.Proofs.m_bind_apply, hpop] at hraw
  have path := cascade_of_success_f1 hF1 p initial rest slots fuel s a [] u
    hr v ht hs hv ha hraw
  obtain ⟨ticks, t, u', hp, hb, hex, ht', hs', ha', htrial, herase, hm, hrec, hsn⟩ :=
    pending_release p rest slots fuel s a path v ht hs hv ha
  have heq : u' = u := congrArg Prod.snd (htrial.symm.trans hsuccess)
  subst u'
  exact ⟨ticks, t, hp, hb, hex, reachable_advance p initial s t ticks hr hex,
    ht', hs', ha', herase, hm, hrec, hsn⟩

end Full.Proofs.TrialSimulationRelease

#print axioms Full.Proofs.TrialSimulationRelease.reachable_advance
#print axioms Full.Proofs.TrialSimulationRelease.cascade_of_success_f1
#print axioms Full.Proofs.TrialSimulationRelease.pending_release_of_success_f1
