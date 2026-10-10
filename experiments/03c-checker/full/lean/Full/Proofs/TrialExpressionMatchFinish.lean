import Full.Proofs.TrialExpressionMatch

namespace Full.Proofs.TrialExecution
open Counted Statements TrialCompatibilitySimulation TrialRelease TrialSimulationRelease

theorem match_finish_filter_tail (hr : Reachable p initial s)
    (hs : s.reservations = r :: rs) :
    s.reservations.filter (fun q => q.addr != r.addr) = rs := by
  have hn := (ReservedReadiness.reachable_invariant hr).2.1
  simp only [ReservedReadiness.Unique, hs, List.map_cons, List.nodup_cons] at hn
  simp only [hs, List.filter_cons, bne_self_eq_false, Bool.false_eq_true, ite_false]
  apply List.filter_eq_self.mpr
  intro q hq
  have hne : q.addr ≠ r.addr := by
    intro he
    exact hn.1 (List.mem_map.mpr ⟨q, hq, he⟩)
  simpa using hne

theorem match_finish_dispose (fuel : Nat) (p : Program) (initial : Trial.Start)
    (s : State) (bid : Nat) (rest : List Task) (log : List Trial.LogEvent)
    (u : Trial.RunState) (hr : Reachable p initial s)
    (ht : s.tasks = (s.reservations.filter (fun r => r.branch == bid)).map
      (fun r => .freeReserved r.addr) ++ rest)
    (ha : s.answer = none)
    (hu : Trial.disposeSetAside bid fuel (logged s log) = (.ok (), u)) :
    ∃ ticks t, advance p ticks s = .ok t ∧ Reachable p initial t ∧
      t.tasks = rest ∧ t.slots = s.slots ∧ t.answer = none ∧
      logged t u.log = u ∧ (∀ r ∈ t.reservations, r ∈ s.reservations) ∧
      (∀ r ∈ t.reservations, r.branch ≠ bid) := by
  induction fuel using Nat.strongRecOn generalizing s log with
  | ind fuel ih =>
   cases fuel with
   | zero =>
    have hn : ¬ ∃ r ∈ s.reservations, r.branch = bid := by
      intro hn
      simp [Trial.disposeSetAside, logged, observe, hn] at hu
      cases hu
    have hf : s.reservations.filter (fun r => r.branch == bid) = [] := by
      apply List.filter_eq_nil_iff.mpr
      intro r hm
      simpa using (fun he => hn ⟨r, hm, he⟩ : r.branch ≠ bid)
    have he : u = logged s log := by
      simpa [Trial.disposeSetAside, logged, observe, hn] using
        (congrArg Prod.snd hu).symm
    subst u
    refine ⟨0, s, rfl, hr, by simpa [hf] using ht, rfl, ha, rfl,
      fun _ h => h, ?_⟩
    intro r hm
    exact fun he => hn ⟨r, hm, he⟩
   | succ fuel =>
    cases hs : s.reservations with
    | nil =>
      have he : u = logged s log := by
        simpa [Trial.disposeSetAside, logged, observe, hs] using (congrArg Prod.snd hu).symm
      subst u
      exact ⟨0, s, rfl, hr, by simpa [hs] using ht, rfl, ha, rfl,
        by simp [hs], by simp [hs]⟩
    | cons r rs =>
      by_cases hb : r.branch = bid
      · obtain ⟨c, hc, hstatus, hz⟩ := Progress.reservation_ready
          (r := r) (Invariance.reachable_invariant hr) (by simp [hs])
        let mem : Trial.Memory := { s.mem with
          cells := s.mem.cells.filter (fun d => d.addr != r.addr),
          record := s.mem.record ++ [.released r.addr] }
        let change : Change := ⟨{ s with
          mem := mem, reservations := rs,
          tasks := (rs.filter (fun q => q.branch == bid)).map
            (fun q => .freeReserved q.addr) ++ rest,
          events := s.events ++ [.free r.addr] }, ⟨"Free", some .cellFreed⟩, none⟩
        let t := commit change
        have hfilter : rs.filter (fun q => q.addr != r.addr) = rs := by
          simpa [hs] using match_finish_filter_tail hr hs
        have hx : advance p 1 s = .ok t := by
          simp [advance, step, transition, ht, hs, hb, ha, hc, hstatus, hz,
            Trial.Memory.release, hfilter, t, change, mem]
        have he : logged t (log ++ [.free r.addr]) =
            (Trial.snapshot .cellFreed none
              { logged s (log ++ [.free r.addr]) with
                mem := mem,
                setAside := rs.map (fun q => (q.branch,q.addr)) }).2 := by
          have h := commit_snapshot change .cellFreed rfl
          simp only [Trial.snapshot] at h
          simp [t, change, logged, observe, commit, pending] at h ⊢
          rw [h]
          simp [Trial.snapshot]
        have hu' : Trial.disposeSetAside bid fuel (logged t (log ++ [.free r.addr])) =
            (.ok (), u) := by
          rw [he]
          simpa [Trial.disposeSetAside, logged, observe, hs, hb, Trial.logEvent,
            Trial.memOp, Trial.Memory.release, Trial.snapshot, hc, mem] using hu
        obtain ⟨n, f, hf, hrf, htf, hsf, haf, hef, hsub, hn⟩ :=
          ih fuel (by omega) t (log ++ [.free r.addr]) (reachable_advance p initial s t 1 hr hx)
            rfl ha hu'
        refine ⟨1+n, f, ?_, hrf, htf, hsf, haf, hef, ?_, hn⟩
        · rw [advance_add, hx]; exact hf
        · intro q hq
          have hq' := hsub q hq
          exact List.mem_cons_of_mem r hq'
      · have hu' : Trial.disposeSetAside bid 0 (logged s log) = (.ok (), u) := by
          simpa [Trial.disposeSetAside, logged, observe, hs, hb] using hu
        simpa only [hs] using ih 0 (by omega) s log hr ht ha hu'

/-- Local F6 branch completion, including the ordered successful disposal run. -/
theorem match_finishBranch (p : Program) (initial : Trial.Start) (s : State)
    (bid : Nat) (inner outer : Context) (rest : List Task) (v : Slot)
    (older : List Slot) (log : List Trial.LogEvent) (raw : Raw) (u : Trial.RunState)
    (hr : Reachable p initial s) (ht : s.tasks = .branchResult bid inner outer :: rest)
    (hv : s.slots = v :: older) (ha : s.answer = none)
    (hi : inner.invocation = outer.invocation)
    (hb : inner.branches = bid :: outer.branches) (he : Enclosing inner s)
    (hu : Trial.finishBranch bid inner.env outer.env v.raw (logged s log) = (.ok raw, u)) :
    ∃ ticks t, advance p ticks s = .ok t ∧ Reachable p initial t ∧
      t.tasks = rest ∧ t.slots = s.slots ∧ t.answer = none ∧
      eraseLog u = observe t ∧ Enclosing outer t ∧ raw = v.raw := by
  let c : Change := ⟨{ s with
    entered := inner.env,
    tasks := (s.reservations.filter (fun r => r.branch == bid)).map
      (fun r => .freeReserved r.addr) ++ [.handoffMatch outer] ++ rest },
    ⟨"BranchResult",some .branchValueWorkedOut⟩,some v.raw⟩
  let a := commit c
  have hx : advance p 1 s = .ok a := by
    simp [advance, step, transition, ht, hv, ha, c, a,
      match_reservation_filter inner s bid he]
  have hlog : logged a log =
      (Trial.snapshot .branchValueWorkedOut (some v.raw)
        { logged s log with scope := inner.env.reverse.map Prod.snd }).2 := by
    have h := commit_snapshot c .branchValueWorkedOut rfl
    simp only [Trial.snapshot] at h
    simp [a, c, logged, observe, commit, pending] at h ⊢
    rw [h]
    simp [Trial.snapshot]
  have hu' : ((Trial.disposeSetAside bid a.reservations.length) >>= fun _ => do
      Trial.enter outer.env
      Trial.snapshot .branchValueHandedOn (some v.raw)
      pure v.raw) (logged a log) = (.ok raw, u) := by
    rw [hlog]
    simpa [Trial.finishBranch, Trial.enter, Trial.snapshot, a, c, commit, logged, observe] using hu
  obtain ⟨done, w, hd, hw⟩ := trial_bind_success _ _ _ _ _ hu'
  cases done
  obtain ⟨n, b, hxb, hrb, htb, hsb, hab, hwb, hsub, hn⟩ :=
    match_finish_dispose a.reservations.length p initial a bid (.handoffMatch outer :: rest)
      log w (reachable_advance p initial s a 1 hr hx)
        (by simp [a, c, commit, List.append_assoc]) ha hd
  have heb : Enclosing outer b := by
    intro r hm
    have hmem := hsub r hm
    have hinner := he r hmem
    refine ⟨hinner.1.trans hi, ?_⟩
    have hbranch := hinner.2
    rw [hb] at hbranch
    exact (List.mem_cons.mp hbranch).resolve_left (hn r hm)
  have hvb : b.slots = v :: older := hsb.trans hv
  let d : Change := ⟨{ b with tasks := rest, entered := outer.env },
    ⟨"Handoff",some .branchValueHandedOn⟩,some v.raw⟩
  let t := commit d
  have hxt : advance p 1 b = .ok t := by
    simp [advance, step, transition, htb, hvb, hab, t, d]
  have hlt : logged t w.log =
      (Trial.snapshot .branchValueHandedOn (some v.raw)
        { logged b w.log with scope := outer.env.reverse.map Prod.snd }).2 := by
    have h := commit_snapshot d .branchValueHandedOn rfl
    simp only [Trial.snapshot] at h
    simp [t, d, logged, observe, commit, pending] at h ⊢
    rw [h]
    simp [Trial.snapshot]
  have hout : ((Except.ok v.raw : Except String Raw), logged t w.log) = (.ok raw, u) := by
    rw [hlt, hwb]
    apply Prod.ext
    · simpa [Trial.enter, Trial.snapshot] using congrArg Prod.fst hw
    · simpa [Trial.enter, Trial.snapshot] using congrArg Prod.snd hw
  have hraw : raw = v.raw := (Except.ok.inj (congrArg Prod.fst hout)).symm
  have hut : u = logged t w.log := (congrArg Prod.snd hout).symm
  refine ⟨1+n+1, t, ?_, reachable_advance p initial b t 1 hrb hxt,
    rfl, hsb, hab, ?_, heb, hraw⟩
  · rw [advance_add, advance_add, hx]
    simpa only [bind, Except.bind, hxb] using hxt
  · rw [hut]; rfl

end Full.Proofs.TrialExecution

#print axioms Full.Proofs.TrialExecution.match_finish_filter_tail
#print axioms Full.Proofs.TrialExecution.match_finish_dispose
#print axioms Full.Proofs.TrialExecution.match_finishBranch
