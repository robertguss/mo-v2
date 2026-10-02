import Proofs.RunContract

namespace Trial.Proofs

theorem StateInvariant.fresh_branch {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) :
    StateInvariant start g (s.nextBranch :: enc) { s with nextBranch := s.nextBranch + 1 } := by
  refine { h with
    ordered := h.ordered.cons _
    branches := List.nodup_cons.mpr ⟨?_, h.branches⟩
    branchBound := ?_ }
  · intro hm
    exact Nat.lt_irrefl _ (h.branchBound _ hm)
  · intro b hb
    rcases List.mem_cons.mp hb with he | hm
    · subst b; exact Nat.lt_succ_self _
    · exact Nat.lt_trans (h.branchBound b hm) (Nat.lt_succ_self _)

/-- Removing the one unused reservation of the current branch preserves the
complete invariant. The cell is detached, so no further holder is released. -/
theorem dispose_head_contract {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (bid : Nat) (a : Addr) (rest : List (Nat × Addr))
    (hs : s.setAside = (bid, a) :: rest) (hn : ∀ p ∈ rest, p.1 ≠ bid) :
    ∃ t, disposeSetAside bid s.setAside.length s = (.ok (), t) ∧
      StateInvariant start g enc t ∧ t.setAside = rest ∧
      t.bindings = s.bindings ∧ t.pending = s.pending ∧
      t.nextBinding = s.nextBinding ∧ t.nextBranch = s.nextBranch ∧
      s.snaps.IsPrefix t.snaps ∧
      (∀ v, valueRoot v ∈ ownedRoots s → readBack t.mem v = readBack s.mem v) := by
  obtain ⟨c, hf, hc⟩ := h.reserved (bid, a) (by simp [hs])
  let m : Memory := { s.mem with
    cells := s.mem.cells.filter (fun d => d.addr != a)
    record := s.mem.record ++ [.released a] }
  have hm : s.mem.release a = .ok m := by simp [Memory.release, hf, m]
  obtain ⟨hh, hv⟩ := h.owned.release_reserved hf hc hm
  let p : RunState := { s with mem := m, setAside := rest, log := s.log ++ [.free a] }
  have hr : ∀ v, valueRoot v ∈ ownedRoots s → readBack p.mem v = readBack s.mem v :=
    fun v hroot => read_back_root _ _ v (hv _ hroot)
  have hrest : rest.Sublist s.setAside := by rw [hs]; exact List.sublist_cons_self _ _
  have hp : StateInvariant start g enc p := by
    refine { h with
      owned := hh
      readable := ?_
      reserved := ?_
      tracked := ?_
      detached := fun d hd hds => h.detached d (List.mem_filter.mp hd).1 hds
      addresses := List.Nodup.sublist (hrest.map Prod.snd) h.addresses
      labels := List.Nodup.sublist (hrest.map Prod.fst) h.labels
      ordered := (hrest.map Prod.fst).trans h.ordered
      outsideValues := ?_ }
    · intro b hb hbstatus
      rcases hbstatus with hbstatus | hnone
      · exact (hr b.value (holding_root_mem s b hb hbstatus)).trans (h.readable b hb (Or.inl hbstatus))
      · exact (read_back_no_root p.mem s.mem b.value hnone).trans (h.readable b hb (Or.inr hnone))
    · intro q hq
      have hqr : q ∈ rest := hq
      obtain ⟨d, hd, hds⟩ := h.reserved q (by simp [hs, hqr])
      have hne : q.2 ≠ a := by
        intro he
        have huniq : (a :: rest.map Prod.snd).Nodup := by simpa [hs] using h.addresses
        exact (List.nodup_cons.mp huniq).1 (List.mem_map.mpr ⟨q, hq, he⟩)
      refine ⟨d, ?_, hds⟩
      change ({ s.mem with cells := s.mem.cells.filter (fun d => d.addr != a) } : Memory).find? q.2 = some d
      rw [find_filter_other s.mem a q.2 hne, hd]
    · intro d hd hds
      have hd' := List.mem_filter.mp hd
      obtain ⟨b, hb⟩ := h.tracked d hd'.1 hds
      rw [hs] at hb
      rcases List.mem_cons.mp hb with he | hb
      · have he' := congrArg Prod.snd he
        have hne : d.addr ≠ a := by simpa using hd'.2
        exact False.elim (hne he')
      · exact ⟨b, hb⟩
    · intro r hr'
      exact (hv r (List.mem_append_right _ (h.outside ▸ hr'))).trans (h.outsideValues r hr')
  let t := (snapshot .cellFreed none p).2
  have hnone : t.setAside.any (fun q => q.1 == bid) = false := by
    apply List.any_eq_false.mpr
    intro q hq
    simpa using hn q hq
  have hdone := dispose_none t bid rest.length hnone
  refine ⟨t, ?_, hp.snapshot .cellFreed none, rfl, rfl, rfl, rfl, rfl,
    snapshot_prefix p .cellFreed none, hr⟩
  simpa [disposeSetAside, hs, memOp, hm, logEvent, p, t, snapshot] using hdone

/-- Exiting a branch removes its label; any remaining reservations belong to
outer branches. An outer reservation may already have been consumed. -/
theorem dispose_branch_contract {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (bid : Nat) (h : StateInvariant start g (bid :: enc) s) :
    ∃ t, disposeSetAside bid s.setAside.length s = (.ok (), t) ∧
      StateInvariant start g enc t ∧ t.setAside.IsSuffix s.setAside ∧
      t.bindings = s.bindings ∧ t.pending = s.pending ∧
      t.nextBinding = s.nextBinding ∧ t.nextBranch = s.nextBranch ∧
      s.snaps.IsPrefix t.snaps ∧
      (∀ v, valueRoot v ∈ ownedRoots s → readBack t.mem v = readBack s.mem v) := by
  have hb := List.nodup_cons.mp h.branches
  rcases List.sublist_cons_iff.mp h.ordered with houter | ⟨labels, heq, houter⟩
  · have hn : s.setAside.any (fun q => q.1 == bid) = false := by
      apply List.any_eq_false.mpr
      intro q hq
      have hm : q.1 ∈ enc := houter.subset (List.mem_map.mpr ⟨q, hq, rfl⟩)
      have hne : q.1 ≠ bid := fun he => hb.1 (he ▸ hm)
      simpa using hne
    exact ⟨s, dispose_none s bid s.setAside.length hn,
      { h with
        ordered := houter
        branches := hb.2
        branchBound := fun b hm => h.branchBound b (List.mem_cons_of_mem _ hm) },
      ⟨[], rfl⟩, rfl, rfl, rfl, rfl, ⟨[], by simp⟩, fun _ _ => rfl⟩
  · cases hs : s.setAside with
    | nil => simp [hs] at heq
    | cons q rest =>
      have hq : q.1 = bid := by simpa [hs] using congrArg List.head? heq
      have htail : rest.map Prod.fst = labels := by simpa [hs] using congrArg List.tail heq
      have hn : ∀ p ∈ rest, p.1 ≠ bid := by
        intro p hp he
        have hm : p.1 ∈ enc := houter.subset (htail ▸ List.mem_map.mpr ⟨p, hp, rfl⟩)
        exact hb.1 (he ▸ hm)
      have hs' : s.setAside = (bid, q.2) :: rest := by simpa [← hq] using hs
      obtain ⟨t, ht, hst, hstack, hbind, hpend, hnb, hnbr, hsn, hread⟩ :=
        dispose_head_contract h bid q.2 rest hs' hn
      refine ⟨t, by simpa [hs] using ht, { hst with
        ordered := by simpa [hstack, htail] using houter
        branches := hb.2
        branchBound := fun b hm => hst.branchBound b (List.mem_cons_of_mem _ hm) },
        ?_, hbind, hpend, hnb, hnbr, hsn, hread⟩
      exact ⟨[q], by simp [hstack]⟩

/-- The complete finishing operation preserves the branch result and all
other owners while removing this branch's label and unused reservation. -/
theorem finish_branch_contract {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (bid : Nat) (h : StateInvariant start g (bid :: enc) s) (inner outer : Env) (raw : RawValue) :
    ∃ t, finishBranch bid inner outer raw s = (.ok raw, t) ∧
      StateInvariant start g enc t ∧ t.setAside.IsSuffix s.setAside ∧
      t.bindings = s.bindings ∧ t.pending = s.pending ∧
      t.nextBinding = s.nextBinding ∧ t.nextBranch = s.nextBranch ∧
      s.snaps.IsPrefix t.snaps ∧
      (∀ v, valueRoot v = none ∨ valueRoot v ∈ ownedRoots s →
        readBack t.mem v = readBack s.mem v) := by
  let s0 := { s with scope := inner.reverse.map Prod.snd }
  let s1 := (snapshot .branchValueWorkedOut (some raw) s0).2
  have hs1 : StateInvariant start g (bid :: enc) s1 :=
    (h.scope _).snapshot .branchValueWorkedOut (some raw)
  obtain ⟨s2, hd, hs2, hstack, hbind, hpend, hnb, hnbr, hsn, hr⟩ := dispose_branch_contract bid hs1
  let s3 := { s2 with scope := outer.reverse.map Prod.snd }
  let t := (snapshot .branchValueHandedOn (some raw) s3).2
  have ht : StateInvariant start g enc t := (hs2.scope _).snapshot .branchValueHandedOn (some raw)
  refine ⟨t, ?_, ht, hstack, hbind, hpend, hnb, hnbr,
    (snapshot_prefix s0 .branchValueWorkedOut (some raw)).trans
      (hsn.trans (snapshot_prefix s3 .branchValueHandedOn (some raw))), ?_⟩
  · have hsnap : snapshot .branchValueWorkedOut (some raw) s0 = (.ok (), s1) := rfl
    simp only [finishBranch, enter, m_bind_apply, m_modify_apply]
    rw [hsnap]
    dsimp only
    simp only [m_get_apply]
    rw [hd]
    rfl
  · intro v hv
    rcases hv with hn | hm
    · exact read_back_no_root t.mem s.mem v hn
    · exact hr v hm

/-- A suffix of a stack with a new head, once that head's label is absent,
is a suffix of the old stack. Outer reservations need not remain unchanged. -/
theorem suffix_without_new_head (bid : Nat) (a : Addr) (old new : List (Nat × Addr))
    (hs : new.IsSuffix ((bid, a) :: old)) (hn : bid ∉ new.map Prod.fst) : new.IsSuffix old := by
  rcases List.suffix_cons_iff.mp hs with he | ht
  · simp [he] at hn
  · exact ht

end Trial.Proofs
