import Full.Proofs.TrialRelease
import Full.Proofs.Invariance
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

/-- Unconditional reachable pending cleanup, using the proved F1 theorem. -/
theorem pending_release_of_success
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
      u.mem.record = t.mem.record ∧ u.snaps = t.landmarks :=
  pending_release_of_success_f1 Full.Proofs.f1 p initial rest slots fuel s a u
    hr v ht hs hv ha hsuccess

/-- Binding release's synthetic pending boundary need not itself be reachable.
Its first transition is the real binding transition; after that transition the
recursive free successors are genuinely reachable. -/
theorem binding_cascade_of_success
    (p : Program) (initial : Trial.Start) (s : Counted.State) (id : Nat)
    (b : Counted.Binding) (a : Nat) (rest : List Counted.Task) (u : Trial.RunState)
    {log : List Trial.LogEvent}
    (hr : Statements.Reachable p initial s)
    (ht : s.tasks = .giveBinding id :: rest) (ha : s.answer = none)
    (hb : s.bindings.find? (fun q => q.record.id == id) = some b)
    (hh : b.record.status = .holding) (hv : b.record.value = .list (some a))
    (hsuccess : Trial.giveUpBinding .approved id (logged s log) = (.ok (), u)) :
    Cascade rest s.slots s.mem.cells.length (bindingInput s id b rest) a := by
  let q := bindingInput s id b rest
  have hraw := hsuccess
  rw [binding_trial s id b rest a log hb hv] at hraw
  change Trial.giveUp .approved s.mem.cells.length a (input q s.slots log) = (.ok (), u) at hraw
  cases hfuel : s.mem.cells.length with
  | zero =>
    rw [hfuel] at hraw
    simp [Trial.giveUp] at hraw
    have h := congrArg Prod.fst hraw
    contradiction
  | succ fuel =>
    rw [hfuel] at hraw
    cases hf : s.mem.find? a with
    | none =>
      simp [Trial.giveUp, Trial.getCell, input, logged, observe, q, bindingInput, hf] at hraw
      have h := congrArg Prod.fst hraw
      contradiction
    | some c =>
      have hqf : q.mem.find? a = some c := hf
      have hl : c.status = .live := by
        cases hc : c.status with
        | live => rfl
        | setAside =>
          simp [Trial.giveUp, Trial.getCell, input, logged, observe, hqf, hc] at hraw
          have h := congrArg Prod.fst hraw
          contradiction
      have hn : c.count ≠ 0 := by
        intro hn
        simp [Trial.giveUp, Trial.getCell, input, logged, observe, hqf, hl, hn] at hraw
        have h := congrArg Prod.fst hraw
        contradiction
      by_cases hone : c.count = 1
      · obtain ⟨tail, he, hread⟩ := edge_from_invariant initial s a c
          (Invariance.reachable_invariant hr) hf hl
        have hqe : q.edges.find? (fun q => q.1 == a) = some (a,tail) := he
        have hqr : Inspect.readable q ⟨.list c.link,tail⟩ = true := hread
        rw [trial_exclusive q a c tail rest s.slots log fuel hqf hl hone] at hraw
        cases hc : c.link with
        | none => exact .last q a c tail fuel hqf hl hone hqe hqr hc
        | some next =>
          apply Cascade.next q a next c tail fuel hqf hl hone hqe hqr hc
          let f := Counted.commit (freeChange (Counted.commit (giveChange q a c rest s.slots))
            a { c with count := 0 } tail rest)
          have hexq : Counted.advance p 2 q = .ok f :=
            exclusive_steps p q a c tail rest ⟨b.record.value,b.value⟩ s.slots
              rfl rfl hv ha hqf hl hone hqe
          have hex : Counted.advance p 2 s = .ok f := by
            have hfirst := binding_first p s id b rest ht hb hh
            change Counted.transition p s = Counted.transition p q at hfirst
            have hqa : q.answer = none := ha
            simpa [Counted.advance, Counted.step, ha, hqa, ← hfirst] using hexq
          apply cascade_of_success_f1 Full.Proofs.f1 p initial rest s.slots fuel f next
            (log ++ [.free a]) u (reachable_advance p initial s f 2 hr hex)
            ⟨.list c.link,tail⟩
          · simp [f, Counted.commit, freeChange, hc]
          · simp [f, Counted.commit, freeChange, giveChange, hc]
          · simp [hc]
          · exact ha
          · simpa only [f, hc, List.nil_append] using hraw
      · exact .shared q a c fuel hqf hl (by omega)

theorem binding_release_of_success
    (p : Program) (initial : Trial.Start) (s : Counted.State) (id : Nat)
    (b : Counted.Binding) (a : Nat) (rest : List Counted.Task) (u : Trial.RunState)
    {log : List Trial.LogEvent}
    (hr : Statements.Reachable p initial s)
    (ht : s.tasks = .giveBinding id :: rest) (ha : s.answer = none)
    (hb : s.bindings.find? (fun q => q.record.id == id) = some b)
    (hh : b.record.status = .holding) (hv : b.record.value = .list (some a))
    (hsuccess : Trial.giveUpBinding .approved id (logged s log) = (.ok (), u)) :
    ∃ ticks t, Counted.advance p ticks s = .ok t ∧ Statements.Reachable p initial t ∧
      t.tasks = rest ∧ t.slots = s.slots ∧ t.answer = none ∧
      eraseLog u = observe t ∧ u.mem = t.mem ∧
      u.mem.record = t.mem.record ∧ u.snaps = t.landmarks := by
  have path := binding_cascade_of_success p initial s id b a rest u hr ht ha hb hh hv hsuccess
  obtain ⟨ticks, t, finalLog, hex, ht', hs', ha', htrial, _, _⟩ :=
    cascade_binding p s id b a rest ht ha hb hh hv path log
  have heq : logged t finalLog = u := congrArg Prod.snd (htrial.symm.trans hsuccess)
  subst u
  exact ⟨ticks, t, hex, reachable_advance p initial s t ticks hr hex,
    ht', hs', ha', erase_logged t finalLog, rfl, rfl, rfl⟩

end Full.Proofs.TrialSimulationRelease

#print axioms Full.Proofs.TrialSimulationRelease.reachable_advance
#print axioms Full.Proofs.TrialSimulationRelease.cascade_of_success_f1
#print axioms Full.Proofs.TrialSimulationRelease.pending_release_of_success_f1
#print axioms Full.Proofs.TrialSimulationRelease.pending_release_of_success
#print axioms Full.Proofs.TrialSimulationRelease.binding_cascade_of_success
#print axioms Full.Proofs.TrialSimulationRelease.binding_release_of_success
