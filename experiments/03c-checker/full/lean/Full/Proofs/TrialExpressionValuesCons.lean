import Full.Proofs.TrialExpressionBinary
import Full.Proofs.ReservedReadiness

namespace Full.Proofs.TrialExecution
open Counted Statements TrialCompatibilitySimulation TrialRelease TrialSimulationRelease

theorem values_eligible (ctx : Context) (s : State) (he : Enclosing ctx s) :
    s.reservations.find? (fun r =>
      r.invocation == ctx.invocation && ctx.branches.contains r.branch) =
      s.reservations.head? := by
  cases h : s.reservations with
  | nil => rfl
  | cons r rs =>
    obtain ⟨hi,hb⟩ := he r (by simp [h])
    simp [hi, hb]

theorem values_filter_head (r : Reservation) (rs : List Reservation)
    (hu : ReservedReadiness.Unique (r :: rs)) :
    (r :: rs).filter (fun q => q.addr != r.addr) = rs := by
  have hn : r.addr ∉ rs.map Reservation.addr := (List.nodup_cons.mp hu).1
  simp only [List.filter_cons, bne_iff_ne, ne_eq, not_true_eq_false, ↓reduceIte]
  apply List.filter_eq_self.mpr
  intro q hq
  have hne : q.addr ≠ r.addr := by
    intro hh
    exact hn (List.mem_map.mpr ⟨q,hq,hh⟩)
  simpa using hne

/-- All enclosing reservations are eligible. Address uniqueness makes Full's
filter exactly Trial's head removal. Actual progress supplies the Plain result
and successful write, without any additional value-consistency assumption. -/
theorem values_cons_primitive
    (p : Program) (initial : Trial.Start) (s : State) (ctx : Context)
    (rest : List Task) (vx vy : Slot) (slots : List Slot) (n : Int)
    (link : Option Nat) (log : List Trial.LogEvent) (raw : Raw) (u : Trial.RunState)
    (hr : Reachable p initial s) (ht : s.tasks = .primitive .cons ctx :: rest)
    (hv : s.slots = vy :: vx :: slots) (hx : vx.raw = .num n)
    (hy : vy.raw = .list link) (ha : s.answer = none) (he : Enclosing ctx s)
    (hu : (do Trial.enter ctx.env; Trial.buildCell .approved ctx.branches n link)
      (logged s log) = (.ok raw,u)) :
    ∃ t v, advance p 1 s = .ok t ∧ Reachable p initial t ∧
      t.tasks = rest ∧ t.slots = v :: slots ∧ v.raw = raw ∧
      t.answer = none ∧ eraseLog u = observe t ∧ Enclosing ctx t := by
  obtain ⟨t, hs, _⟩ := (Full.Proofs.f1.2 p initial s hr).2.2 ha
  cases hc : transition p s with
  | error why => simp [step, ha, hc] at hs
  | ok c =>
    have htc : t = commit c := by simpa [step, ha, hc] using hs.symm
    cases hp : Plain.primitive .cons vx.value vy.value with
    | error why => simp [transition, ht, hv, hp] at hc
    | ok value =>
      have eligible := values_eligible ctx s he
      cases hrs : s.reservations with
      | nil =>
        have hcc : c = ⟨{ s with
          tasks := rest
          mem := (s.mem.create n link).2
          entered := ctx.env
          edges := ((s.mem.create n link).1,vy.value) ::
            s.edges.filter (fun q => q.1 != (s.mem.create n link).1)
          slots := ⟨.list (some (s.mem.create n link).1),value⟩ :: slots
          events := s.events ++ [.create (s.mem.create n link).1 n link] },
          ⟨"Primitive",some .newCellBuilt⟩,none⟩ := by
          simpa [transition, ht, hv, hp, hx, hy, hrs] using hc.symm
        have snap := commit_snapshot c .newCellBuilt (by rw [hcc])
        subst c
        cases link <;>
          simp [Trial.enter, Trial.buildCell, logged, observe, hrs, Trial.logEvent,
            Trial.popPending, Trial.pushPending, pending, hv, hx, hy] at hu
        all_goals
          obtain ⟨hraw, hu⟩ := hu
          refine ⟨t, ⟨.list (some (s.mem.create n _).1),value⟩,
            ?_, ?_, ?_, ?_, rfl, ?_, ?_, ?_⟩
          · simp [advance, ha, hs]
          · exact reachable_advance p initial s t 1 hr (by simp [advance, ha, hs])
          · simp [htc, commit]
          · simp [htc, commit]
          · simpa [htc, commit] using ha
          · simp only [Trial.snapshot] at snap
            simp [htc, eraseLog, observe, commit, pending, hrs] at snap ⊢
            exact snap.symm
          · simpa [htc, Enclosing, commit] using he
      | cons r rs =>
        have hinv := (he r (by simp [hrs])).1
        have hbranch := (he r (by simp [hrs])).2
        have hfilter : s.reservations.filter (fun q => q.addr != r.addr) = rs := by
          rw [hrs]
          exact values_filter_head r rs (by
            simpa [hrs] using (ReservedReadiness.reachable_invariant hr).2.1)
        rw [hrs] at eligible
        cases hm : s.mem.writeInPlace r.addr n link with
        | error why => simp [transition, ht, hv, hp, hx, hy, hrs, hinv, hbranch, hm] at hc
        | ok mem =>
          have hcc : c = ⟨{ s with
            tasks := rest
            mem := mem
            entered := ctx.env
            reservations := rs
            edges := (r.addr,vy.value) :: s.edges.filter (fun q => q.1 != r.addr)
            slots := ⟨.list (some r.addr),value⟩ :: slots
            events := s.events ++ [.write r.addr n link] },
            ⟨"Primitive",some .newCellBuilt⟩,none⟩ := by
            simpa [transition, ht, hv, hp, hx, hy, hrs, hinv, hbranch, hm,
              values_filter_head r rs (by simpa [hrs] using
                (ReservedReadiness.reachable_invariant hr).2.1)] using hc.symm
          have snap := commit_snapshot c .newCellBuilt (by rw [hcc])
          subst c
          cases link <;>
            simp [Trial.enter, Trial.buildCell, logged, observe, hrs, hbranch,
              Trial.Variant.approved, Trial.memOp, hm, Trial.logEvent, Trial.popPending, Trial.pushPending,
              pending, hv, hx, hy] at hu
          all_goals
            obtain ⟨hraw, hu⟩ := hu
            refine ⟨t, ⟨.list (some r.addr),value⟩,
              ?_, ?_, ?_, ?_, rfl, ?_, ?_, ?_⟩
            · simp [advance, ha, hs]
            · exact reachable_advance p initial s t 1 hr (by simp [advance, ha, hs])
            · simp [htc, commit]
            · simp [htc, commit]
            · simpa [htc, commit] using ha
            · simp only [Trial.snapshot] at snap
              simp [htc, eraseLog, observe, commit, pending] at snap ⊢
              exact snap.symm
            · intro q hq
              apply he q
              simp [htc, commit] at hq
              simp [hrs, hq]

end Full.Proofs.TrialExecution

#print axioms Full.Proofs.TrialExecution.values_cons_primitive
