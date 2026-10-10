import Full.Proofs.TrialSimulationRelease
import Full.Proofs.ReleaseQueue

/-! Whole-prefix composition for dead-binding execution. The checked Trial API
calls its environment loop `giveUpDead`, not `cleanDead`. This module isolates
the remaining loop-selection obligation from real reachable execution; it does
not assume reachability of a synthetic pending state. -/
namespace Full.Proofs.TrialExecutionDead
open TrialCompatibilitySimulation TrialRelease TrialExecution

/-- A successful Trial release at every real reachable binding boundary.
This is a semantic success premise, not an execution correspondence premise. -/
def ReleaseSuccess (p : Program) (initial : Trial.Start) : Prop :=
  ∀ (s : Counted.State) (id : Nat) (rest : List Counted.Task),
    Statements.Reachable p initial s → s.tasks = .giveBinding id :: rest →
    s.answer = none →
    ∃ (b : Counted.Binding) (a : Nat) (u : Trial.RunState),
      s.bindings.find? (fun q => q.record.id == id) = some b ∧
      b.record.status = .holding ∧ b.record.value = .list (some a) ∧
      Trial.giveUpBinding .approved id (observe s) = (.ok (), u)

/-- Exact per-binding boundaries, retaining all fields except the textual log.
The intermediate states are real machine states, including recursive frees. -/
inductive Boundaries : List Nat → Counted.State → Counted.State → Prop
  | nil (s) : Boundaries [] s s
  | cons (id : Nat) (ids : List Nat) (s t r : Counted.State) (u : Trial.RunState)
      (release : Trial.giveUpBinding .approved id (observe s) = (.ok (), u))
      (exactState : eraseLog u = observe t)
      (tail : Boundaries ids t r) : Boundaries (id :: ids) s r

/-- Run a whole binding prefix without touching its arbitrary saved suffix or
operands. Each recursive call uses the actual reachable release successor. -/
theorem execute_prefix (p : Program) (initial : Trial.Start)
    (success : ReleaseSuccess p initial) (ids : List Nat)
    (s : Counted.State) (rest : List Counted.Task)
    (hr : Statements.Reachable p initial s)
    (ht : s.tasks = ids.map Counted.Task.giveBinding ++ rest)
    (ha : s.answer = none) :
    ∃ ticks t, Counted.advance p ticks s = .ok t ∧
      Statements.Reachable p initial t ∧ t.tasks = rest ∧
      t.slots = s.slots ∧ t.answer = none ∧ Boundaries ids s t := by
  induction ids generalizing s with
  | nil =>
      exact ⟨0, s, rfl, hr, ht, rfl, ha, .nil s⟩
  | cons id ids ih =>
      have hhead : s.tasks = .giveBinding id :: (ids.map Counted.Task.giveBinding ++ rest) := ht
      obtain ⟨b, a, u, hb, hh, hv, hu⟩ := success s id _ hr hhead ha
      obtain ⟨n, t, hex, hrt, htt, hst, hat, he, _, _, _⟩ :=
        TrialSimulationRelease.binding_release_of_success p initial s id b a
          (ids.map Counted.Task.giveBinding ++ rest) u hr hhead ha hb hh hv hu
      obtain ⟨m, r, her, hrr, htr, hsr, har, trace⟩ := ih t hrt htt hat
      refine ⟨n + m, r, ?_, hrr, htr, hsr.trans hst, har,
        .cons id ids s t r u hu he trace⟩
      rw [advance_add, hex]
      exact her

/-- The actual `Counted.dead` queue is executed in its original oldest-first
order. Future equality is retained for the entire queued state. -/
theorem execute_dead (p : Program) (initial : Trial.Start)
    (success : ReleaseSuccess p initial) (s : Counted.State)
    (env : Trial.Env) (rest : List Counted.Task) (frames : List Trial.Frame)
    (hr : Statements.Reachable p initial s)
    (ht : s.tasks = Counted.dead s.bindings env rest ++ rest)
    (ha : s.answer = none) (hf : Future rest frames) :
    Future s.tasks frames ∧
    ∃ ids ticks t, Counted.dead s.bindings env rest = ids.map Counted.Task.giveBinding ∧
      Counted.advance p ticks s = .ok t ∧ Statements.Reachable p initial t ∧
      t.tasks = rest ∧ t.slots = s.slots ∧ t.answer = none ∧ Boundaries ids s t := by
  refine ⟨?_, ?_⟩
  · rw [ht]
    exact future_dead s.bindings env hf
  · obtain ⟨ids, hid⟩ := SimulationInitial.dead_is_prefix s.bindings env rest
    obtain ⟨ticks, t, hex, hrt, htt, hst, hat, trace⟩ :=
      execute_prefix p initial success ids s rest hr (by rw [ht, hid]) ha
    exact ⟨ids, ticks, t, hid, hex, hrt, htt, hst, hat, trace⟩

/-- Full memory, operation record and ordered snapshots at every boundary. -/
theorem boundary_fields (t : Counted.State) (u : Trial.RunState)
    (h : eraseLog u = observe t) :
    u.mem = t.mem ∧ u.mem.record = t.mem.record ∧ u.snaps = t.landmarks :=
  exact_fields t u h

/-- A real queued boundary needs no separately assumed binding-shape premise. -/
theorem dead_binding_of_success (p : Program) (initial : Trial.Start)
    (s : Counted.State) (id : Nat) (rest : List Counted.Task) (u : Trial.RunState)
    (hr : Statements.Reachable p initial s)
    (ht : s.tasks = .giveBinding id :: rest) (ha : s.answer = none)
    (hsuccess : Trial.giveUpBinding .approved id (observe s) = (.ok (), u)) :
    ∃ ticks t, Counted.advance p ticks s = .ok t ∧
      Statements.Reachable p initial t ∧ t.tasks = rest ∧
      t.slots = s.slots ∧ t.answer = none ∧ eraseLog u = observe t ∧
      u.mem = t.mem ∧ u.mem.record = t.mem.record ∧ u.snaps = t.landmarks := by
  obtain ⟨b, a, hb, hh, hv⟩ := ReleaseQueue.reachable_binding (bid := id) hr (by simp [ht])
  exact TrialSimulationRelease.binding_release_of_success p initial s id b a rest u
    hr ht ha hb hh hv hsuccess

/-- Exact whole-loop correspondence for a singleton selected environment.
The success premise is the actual `giveUpDead` call, not global release success. -/
theorem dead_singleton_of_success (p : Program) (initial : Trial.Start)
    (s : Counted.State) (name : String) (id : Nat) (rest : List Counted.Task)
    (frames : List Trial.Frame) (u : Trial.RunState)
    (hr : Statements.Reachable p initial s)
    (ht : s.tasks = .giveBinding id :: rest) (ha : s.answer = none)
    (hf : Future rest frames) (hused : Trial.usedLater frames id = false)
    (hsuccess : Trial.giveUpDead .approved [(name,id)] frames (observe s) = (.ok (), u)) :
    Future s.tasks frames ∧
    ∃ ticks t, Counted.advance p ticks s = .ok t ∧
      Statements.Reachable p initial t ∧ t.tasks = rest ∧
      t.slots = s.slots ∧ t.answer = none ∧ Future t.tasks frames ∧
      eraseLog u = observe t ∧ u.mem = t.mem ∧
      u.mem.record = t.mem.record ∧ u.snaps = t.landmarks := by
  obtain ⟨b, a, hb, hh, hv⟩ := ReleaseQueue.reachable_binding (bid := id) hr (by simp [ht])
  have hfind : (observe s).bindings.find? (fun q => q.id == id) = some b.record := by
    simpa [observe, List.find?_map, Function.comp_def, hb]
  have hrelease : Trial.giveUpBinding .approved id (observe s) = (.ok (), u) := by
    cases he : Trial.giveUpBinding .approved id (observe s) with
    | mk result state =>
      cases result <;>
        simp [Trial.giveUpDead, List.forIn_cons, Trial.getBinding, hfind, hv, hh,
          hused, he] at hsuccess
      all_goals exact hsuccess
  obtain ⟨ticks, t, hex, hrt, htt, hst, hat, he, hm, hrec, hsn⟩ :=
    dead_binding_of_success p initial s id rest u hr ht ha hrelease
  refine ⟨?_, ticks, t, hex, hrt, htt, hst, hat, ?_, he, hm, hrec, hsn⟩
  · rw [ht]
    exact future_silent (.giveBinding id) (fun _ => rfl) hf
  · simpa [htt] using hf

/-- The prefix above uses precisely the supplied Trial future decisions. -/
theorem dead_selection (bindings : List Counted.Binding) (env : Trial.Env)
    (tasks : List Counted.Task) (frames : List Trial.Frame) (h : Future tasks frames) :
    Counted.dead bindings env tasks = env.reverse.filterMap (fun (_, id) =>
      if bindings.any (fun b => b.record.id == id && b.record.status == .holding) &&
          !Trial.usedLater frames id then some (.giveBinding id) else none) :=
  dead_future bindings env tasks frames h

end Full.Proofs.TrialExecutionDead

#print axioms Full.Proofs.TrialExecutionDead.execute_prefix
#print axioms Full.Proofs.TrialExecutionDead.execute_dead
#print axioms Full.Proofs.TrialExecutionDead.boundary_fields
#print axioms Full.Proofs.TrialExecutionDead.dead_selection
#print axioms Full.Proofs.TrialExecutionDead.dead_binding_of_success
#print axioms Full.Proofs.TrialExecutionDead.dead_singleton_of_success
