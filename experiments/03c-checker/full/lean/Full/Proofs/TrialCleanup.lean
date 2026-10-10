import Full.Proofs.TrialExpressionBinary
import Full.Proofs.TrialExpressionControl
import Full.Proofs.ReleaseQueue
import Proofs.CleanupContract

namespace Full.Proofs.TrialCleanup
open Counted Statements TrialExecution TrialCompatibilitySimulation TrialRelease

theorem giveUp_frame (fuel : Nat) (s : Trial.RunState) (addr : Nat) :
    (Trial.giveUp .approved fuel addr s).2.bindings = s.bindings ∧
    (Trial.giveUp .approved fuel addr s).2.setAside = s.setAside := by
  induction fuel generalizing s addr with
  | zero => exact ⟨rfl, rfl⟩
  | succ fuel ih =>
    cases hf : s.mem.find? addr with
    | none => simp [Trial.giveUp, Trial.getCell, hf]
    | some c =>
      cases hm : (s.mem.updateCell addr (fun d => {d with count := c.count - 1})).release addr
      all_goals simp [Trial.giveUp, Trial.getCell, Trial.memOp, Trial.snapshot,
      Trial.logEvent, Trial.pushPending, Trial.popPending, Trial.Variant.approved,
        Trial.Memory.setCount, hf, hm]
      all_goals repeat' first | split | simp_all | exact ⟨rfl, rfl⟩ | exact ih _ _

theorem any_holding (hr : Reachable p initial s)
    (hb : s.bindings.find? (fun b => b.record.id == bid) = some b) :
    s.bindings.any (fun b => b.record.id == bid && b.record.status == .holding) =
      (b.record.status == .holding) := by
  apply Bool.eq_iff_iff.mpr
  simp only [List.any_eq_true, Bool.and_eq_true, beq_iff_eq]
  constructor
  · rintro ⟨q, hq, hid, hh⟩
    have hf := Initial.find_key_self s.bindings (fun b => b.record.id)
      (BindingIdentity.reachable_unique hr) q hq
    rw [hid, hb] at hf
    cases Option.some.inj hf
    exact hh
  · intro hh
    exact ⟨b, List.mem_of_find?_eq_some hb, by simpa using List.find?_some hb, hh⟩

theorem any_update (bs : List Binding) (released bid : Nat) :
    (bs.map (fun b => if b.record.id == released then
      {b with record := {b.record with status := .givenUp}} else b)).any
      (fun b => b.record.id == bid && b.record.status == .holding) =
    (if bid = released then false else
      bs.any (fun b => b.record.id == bid && b.record.status == .holding)) := by
  induction bs with
  | nil => simp
  | cons b bs ih =>
    by_cases h1 : b.record.id = released <;> by_cases h2 : bid = released
    all_goals simp_all [List.any_cons, List.map_cons]
    all_goals simp only [beq_eq_false_iff_ne.mpr (Ne.symm h2), Bool.false_and, Bool.false_or]

theorem filterMap_congr (xs : List α) (f g : α → Option β)
    (h : ∀ x ∈ xs, f x = g x) : xs.filterMap f = xs.filterMap g := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    simp only [List.filterMap_cons, h x (by simp)]
    rw [ih (fun y hy => h y (by simp [hy]))]

theorem dead_update (bs : List Binding) (env : Env) (rest : List Task) (released : Nat)
    (hn : Task.giveBinding released ∉ dead bs env rest) :
    dead (bs.map (fun b => if b.record.id == released then
      {b with record := {b.record with status := .givenUp}} else b)) env rest =
      dead bs env rest := by
  unfold dead at hn ⊢
  apply filterMap_congr
  intro q hq
  rcases q with ⟨name, bid⟩
  dsimp only
  rw [any_update]
  by_cases he : bid = released
  · subst bid
    have hc : (bs.any (fun b => b.record.id == released && b.record.status == .holding) &&
        !rest.any (taskUses released)) = false := by
      cases hc : bs.any (fun b => b.record.id == released && b.record.status == .holding) &&
          !rest.any (taskUses released) with
      | false => rfl
      | true => exact False.elim (hn (List.mem_filterMap.mpr ⟨(name,released), hq, by simp [hc]⟩))
    simp [hc]
  · simp [he]

theorem dead_cons (bs : List Binding) (name : String) (bid : Nat) (xs : Env) (rest : List Task) :
    dead bs ((name,bid)::xs).reverse rest =
      if bs.any (fun b => b.record.id == bid && b.record.status == .holding) &&
          !rest.any (taskUses bid) then .giveBinding bid :: dead bs xs.reverse rest
      else dead bs xs.reverse rest := by
  simp only [dead, List.reverse_reverse, List.filterMap_cons]
  by_cases hc : (bs.any (fun b => b.record.id == bid && b.record.status == .holding) &&
    !rest.any (taskUses bid)) = true
  all_goals simp only [hc, Bool.false_eq_true, ite_true, ite_false]

theorem cleanup_loop (xs : Env) (p : Program) (initial : Trial.Start)
    (s : State) (rest : List Task) (frames : List Trial.Frame)
    (log : List Trial.LogEvent) (u : Trial.RunState)
    (hr : Reachable p initial s)
    (ht : s.tasks = dead s.bindings xs.reverse rest ++ rest)
    (ha : s.answer = none) (hf : Future rest frames)
    (hu : (forIn xs PUnit.unit (fun q _ => Trial.Proofs.cleanupStep frames q) : Trial.M PUnit)
      (logged s log) = (.ok (), u)) :
    ∃ ticks t, advance p ticks s = .ok t ∧ Reachable p initial t ∧
      t.tasks = rest ∧ t.slots = s.slots ∧ t.answer = none ∧
      eraseLog u = observe t ∧ t.reservations = s.reservations := by
  induction xs generalizing s log with
  | nil =>
    have he : u = logged s log := (congrArg Prod.snd hu).symm
    subst u
    exact ⟨0, s, rfl, hr, by simpa [dead] using ht, rfl, ha, rfl, rfl⟩
  | cons q xs ih =>
    rcases q with ⟨name, bid⟩
    cases hb : s.bindings.find? (fun b => b.record.id == bid) with
    | none =>
      simp [List.forIn_cons, Trial.Proofs.cleanupStep, Trial.getBinding,
        logged, observe, List.find?_map, Function.comp_def, hb] at hu
      cases hu
    | some b =>
      have hfind : (logged s log).bindings.find? (fun q => q.id == bid) = some b.record := by
        simp [logged, observe, List.find?_map, Function.comp_def, hb]
      have hhold := any_holding hr hb
      by_cases hc : (b.record.status == .holding && !Trial.usedLater frames bid) = true
      · have hh : b.record.status = .holding := by simpa using (Bool.and_eq_true_iff.mp hc).1
        have hu0 : Trial.usedLater frames bid = false := by simpa using (Bool.and_eq_true_iff.mp hc).2
        obtain ⟨addr, hv⟩ := HoldingAccounted.reachable_holder_form hr b (List.mem_of_find?_eq_some hb) hh
        have ht' : s.tasks = .giveBinding bid :: (dead s.bindings xs.reverse rest ++ rest) := by
          simpa only [dead_cons, hhold, hf bid, hc, ite_true, List.cons_append] using ht
        cases hrelease : Trial.giveUpBinding .approved bid (logged s log) with
        | mk result w =>
          cases result with
          | error why =>
            simp [List.forIn_cons, Trial.Proofs.cleanupStep, Trial.getBinding,
              hfind, hv, hh, hu0, hrelease] at hu
            cases hu
          | ok result =>
            cases result
            have hu' : (forIn xs PUnit.unit (fun q _ => Trial.Proofs.cleanupStep frames q) : Trial.M PUnit)
                w = (.ok (), u) := by
              simpa [List.forIn_cons, Trial.Proofs.cleanupStep, Trial.getBinding,
                hfind, hv, hh, hu0, hrelease] using hu
            have path := TrialSimulationRelease.binding_cascade_of_success p initial s bid b addr
              (dead s.bindings xs.reverse rest ++ rest) w hr ht' ha hb hh hv hrelease
            obtain ⟨n, t, finalLog, hex, htt, hst, hat, htrial, hbs, hrs⟩ :=
              cascade_binding p s bid b addr _ ht' ha hb hh hv path log
            have hw : logged t finalLog = w := congrArg Prod.snd (htrial.symm.trans hrelease)
            have hrt := Simulation.reachable_advance hr hex
            have hn : Task.giveBinding bid ∉ dead s.bindings xs.reverse rest := by
              have hn := ReleaseQueue.reachable_unique hr
              simp only [ht', ReleaseQueue.ids, List.nodup_cons] at hn
              intro hm
              exact hn.1 (ReleaseQueue.mem_ids.mpr (List.mem_append_left _ hm))
            have hqueue : dead t.bindings xs.reverse rest = dead s.bindings xs.reverse rest := by
              rw [hbs]
              exact dead_update s.bindings xs.reverse rest bid hn
            obtain ⟨m, r, her, hrr, htr, hsr, har, hor, hres⟩ :=
              ih t finalLog hrt (by rw [hqueue]; exact htt) hat (by rw [hw]; exact hu')
            refine ⟨n + m, r, ?_, hrr, htr, hsr.trans hst, har, hor, hres.trans hrs⟩
            rw [advance_add, hex]
            exact her
      · have ht' : s.tasks = dead s.bindings xs.reverse rest ++ rest := by
          simpa only [dead_cons, hhold, hf bid, hc, Bool.false_eq_true, ite_false] using ht
        have hc' : ¬(b.record.status = .holding ∧ Trial.usedLater frames bid = false) := by
          simpa using hc
        have hstep : Trial.Proofs.cleanupStep frames (name,bid) (logged s log) =
            (.ok (.yield PUnit.unit), logged s log) := by
          cases hv : b.record.value with
          | num n | bool b => simp [Trial.Proofs.cleanupStep, Trial.getBinding, hfind, hv]
          | list addr => cases addr <;> simp [Trial.Proofs.cleanupStep, Trial.getBinding, hfind, hv, hc']
        apply ih s log hr ht' ha
        simpa [List.forIn_cons, hstep] using hu

theorem cleanup (p : Program) (initial : Trial.Start) (s : State)
    (rest : List Task) (env : Env) (frames : List Trial.Frame)
    (log : List Trial.LogEvent) (u : Trial.RunState)
    (hr : Reachable p initial s) (ht : s.tasks = dead s.bindings env rest ++ rest)
    (ha : s.answer = none) (hf : Future rest frames)
    (hu : Trial.giveUpDead .approved env frames (logged s log) = (.ok (), u)) :
    ∃ ticks t, advance p ticks s = .ok t ∧ Reachable p initial t ∧
      t.tasks = rest ∧ t.slots = s.slots ∧ t.answer = none ∧
      eraseLog u = observe t ∧ t.reservations = s.reservations := by
  have hloop : (forIn env.reverse PUnit.unit (fun q _ => Trial.Proofs.cleanupStep frames q) : Trial.M PUnit)
      (logged s log) = (.ok (), u) := by
    unfold Trial.giveUpDead at hu
    change ((forIn env.reverse PUnit.unit (fun q _ => Trial.Proofs.cleanupStep frames q)
      : Trial.M PUnit) >>= fun _ => pure ()) (logged s log) = (.ok (), u) at hu
    obtain ⟨v, t, ht, hv⟩ := trial_bind_success _ _ _ _ _ hu
    cases v
    have he : t = u := congrArg Prod.snd hv
    simpa [he] using ht
  exact cleanup_loop env.reverse p initial s rest frames log u hr
    (by simpa using ht) ha hf hloop

theorem cleanup_bridge : CleanupBridge := by
  intro p initial s ctx rest env frames log u hr ht ha hf he hu
  obtain ⟨n, t, hx, hrt, htt, hst, hat, hot, hrs⟩ :=
    cleanup p initial s rest env frames log u hr ht ha hf hu
  exact ⟨n, t, hx, hrt, htt, hst, hat, hot, by simpa only [Enclosing, hrs] using he⟩

end Full.Proofs.TrialCleanup

#print axioms Full.Proofs.TrialCleanup.cleanup
#print axioms Full.Proofs.TrialCleanup.cleanup_bridge
