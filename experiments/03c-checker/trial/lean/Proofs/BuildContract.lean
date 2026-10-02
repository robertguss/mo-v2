import Proofs.LetContract

namespace Trial.Proofs

theorem StateInvariant.build_reserved {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) :
    ∀ bid a more, s.setAside = (bid, a) :: more →
      enc.contains bid = true ∧ ∃ c, s.mem.find? a = some c ∧ c.status = .setAside := by
  intro bid a more he
  have hp : (bid, a) ∈ s.setAside := by simp [he]
  refine ⟨?_, h.reserved (bid, a) hp⟩
  simpa using List.Sublist.subset h.ordered (List.mem_map.mpr ⟨(bid, a), hp, rfl⟩)

/-- The constructor's exact metadata and reserved-cell effects, read from
the actual allocation/reuse cases. Reuse consumes the stack head only. -/
theorem build_metadata {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (item : Int) (link : Option Addr) (rest : List RawValue)
    (hp : s.pending = match link with | none => rest | some a => .list (some a) :: rest) :
    let t := (buildCell Variant.approved enc item link s).2
    t.nextBinding = s.nextBinding ∧ t.nextBranch = s.nextBranch ∧
      ReservedAllocated t ∧
      (∀ c ∈ t.mem.cells, c.status = .setAside → ∃ bid, (bid, c.addr) ∈ t.setAside) ∧
      (∀ c ∈ t.mem.cells, c.status = .setAside → c.count = 0 ∧ c.link = none) := by
  cases ha : s.setAside with
  | nil =>
    let p : RunState := { s with
      mem := (s.mem.create item link).2
      log := s.log ++ [.alloc s.mem.next]
      pending := .list (some s.mem.next) :: rest }
    let t := (snapshot .newCellBuilt none p).2
    have he : buildCell Variant.approved enc item link s = (.ok (.list (some s.mem.next)), t) := by
      cases link <;> simp [buildCell, ha, popPending, pushPending, logEvent, snapshot, hp, t, p, Memory.create]
    rw [he]
    have hold : ∀ c ∈ t.mem.cells, c.status = .setAside → c ∈ s.mem.cells := by
      intro c hc hs
      change c ∈ s.mem.cells ++ [_] at hc
      rcases List.mem_append.mp hc with hc | hc
      · exact hc
      · have he := List.mem_singleton.mp hc
        subst c
        simp at hs
    refine ⟨rfl, rfl, ?_,
      fun c hc hs => h.tracked c (hold c hc hs) hs,
      fun c hc hs => h.detached c (hold c hc hs) hs⟩
    intro q hq
    have hq' : q ∈ s.setAside := hq
    simp [ha] at hq'
  | cons p more =>
    rcases p with ⟨bid, a⟩
    obtain ⟨henc, c, hf, hs⟩ := h.build_reserved bid a more ha
    simp only [List.contains_iff_mem] at henc
    let m : Memory := { s.mem.updateCell a (fun _ =>
      { addr := a, item := item, link := link, count := 1, status := .live })
      with record := s.mem.record ++ [.written a] }
    have hw : s.mem.writeInPlace a item link = .ok m := by simp [Memory.writeInPlace, hf, hs, m]
    let p : RunState := { s with
      mem := m
      setAside := more
      log := s.log ++ [.reuse a]
      pending := .list (some a) :: rest }
    let t := (snapshot .newCellBuilt none p).2
    have he : buildCell Variant.approved enc item link s = (.ok (.list (some a)), t) := by
      cases link <;> simp [buildCell, ha, henc, Variant.approved, memOp, hw, popPending,
        pushPending, logEvent, snapshot, hp, t, p]
    rw [he]
    have hold : ∀ d ∈ t.mem.cells, d.status = .setAside → d ∈ s.mem.cells ∧ d.addr ≠ a := by
      intro d hd hs
      obtain ⟨q, hq, heq⟩ := List.mem_map.mp hd
      by_cases hi : q.addr = a
      · have hh := congrArg Cell.status heq
        simp [hi, hs] at hh
      · have heq' : q = d := by simpa [hi] using heq
        rw [← heq']
        exact ⟨hq, hi⟩
    refine ⟨rfl, rfl, ?_, ?_, fun d hd hs => h.detached d (hold d hd hs).1 hs⟩
    · intro q hq
      have hqm : q ∈ more := hq
      obtain ⟨d, hd, hds⟩ := h.reserved q (by simp [ha, hqm])
      have hne : q.2 ≠ a := by
        intro hqa
        have huniq : (a :: more.map Prod.snd).Nodup := by simpa [ha] using h.addresses
        exact (List.nodup_cons.mp huniq).1 (List.mem_map.mpr ⟨q, hqm, hqa⟩)
      refine ⟨d, ?_, hds⟩
      change (s.mem.updateCell a _).find? q.2 = some d
      rw [find_update_other s.mem a q.2 _ (by intro d hd; exact hd.symm) hne, hd]
    · intro d hd hs
      obtain ⟨hold, hne⟩ := hold d hd hs
      obtain ⟨bid', hp⟩ := h.tracked d hold hs
      rw [ha] at hp
      rcases List.mem_cons.mp hp with hp | hp
      · have hda := congrArg Prod.snd hp
        exact False.elim (hne hda)
      · exact ⟨bid', hp⟩

/-- Full construction postcondition. The new result's head and tail are exact;
all old meanings and observations survive, and reservations form a suffix. -/
theorem build_contract {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (item : Int) (link : Option Addr) (items : List Int)
    (rest : List RawValue)
    (hp : s.pending = match link with | none => rest | some a => .list (some a) :: rest)
    (hv : readBack s.mem (.list link) = .ok (.list items)) :
    ∃ a t, buildCell Variant.approved enc item link s = (.ok (.list (some a)), t) ∧
      StateInvariant start g enc t ∧ readBack t.mem (.list (some a)) = .ok (.list (item :: items)) ∧
      t.bindings = s.bindings ∧ t.pending = .list (some a) :: rest ∧
      t.nextBinding = s.nextBinding ∧ t.nextBranch = s.nextBranch ∧
      t.setAside.IsSuffix s.setAside ∧ s.snaps.IsPrefix t.snaps ∧
      (∀ v ∈ rest, readBack t.mem v = readBack s.mem v) := by
  obtain ⟨a, t, tail, he, howned, htail, hnew, hpend, hbind, hout, hstack, hread, hsn⟩ :=
    build_cell_safe s enc item link rest h.owned hp h.build_reserved
  have heq : tail = items := PlainValue.list.inj (Except.ok.inj (htail.symm.trans hv))
  subst tail
  have hmeta := build_metadata h item link rest hp
  rw [he] at hmeta
  dsimp only at hmeta
  obtain ⟨hnb, hnbr, hreserved, htracked, hdetached⟩ := hmeta
  have hview := build_cell_views s enc item link rest h.owned hp h.build_reserved
  rw [he] at hview
  change PreservesViews (ownedRoots s) s t at hview
  have hhold : HoldingMeanings t.mem t.bindings (fun id => (g id).1) (fun id => (g id).2) := by
    rw [hbind]
    exact h.holding_meanings.roots
      (fun r hr => hread r (List.mem_append_left _ (List.mem_append_left _ hr)))
  have hrest : ∀ v ∈ rest, v ∈ s.pending := by
    intro w hw
    cases link <;> simp [hp, hw]
  have hpre : s.snaps.IsPrefix t.snaps := by
    rw [hsn]
    exact ⟨_, rfl⟩
  have htailSub : t.setAside.Sublist s.setAside := by rw [hstack]; exact List.tail_sublist _
  refine ⟨a, t, he, {
    owned := howned
    ids := by rw [hbind, h.ids, hnb]
    raw := by simpa [hbind] using h.raw
    kinds := by simpa [hbind] using h.kinds
    readable := ?_
    holding := by simpa [hbind] using h.holding
    pending := ?_
    reserved := hreserved
    tracked := htracked
    detached := hdetached
    addresses := List.Nodup.sublist (htailSub.map Prod.snd) h.addresses
    labels := List.Nodup.sublist (htailSub.map Prod.fst) h.labels
    ordered := (htailSub.map Prod.fst).trans h.ordered
    branches := h.branches
    branchBound := by simpa [hnbr] using h.branchBound
    outside := hout.trans h.outside
    outsideValues := ?_
    history := hview.names (fun _ hr => List.mem_append_left _ (List.mem_append_left _ hr))
      _ _ h.history h.holding_meanings
    historyBound := ?_
    outsideHistory := ?_ }, hnew, hbind, hpend, hnb, hnbr, ?_, hpre, ?_⟩
  · intro b hb hh
    rcases hh with hh | hn
    · exact (hhold b hb hh).2
    · exact (read_back_no_root t.mem s.mem b.value hn).trans
        (h.readable b (hbind ▸ hb) (Or.inr hn))
  · intro v hv
    rw [hpend] at hv
    rcases List.mem_cons.mp hv with he | hm
    · subst v; exact ⟨a, rfl⟩
    · exact h.pending v (hrest v hm)
  · intro r hr
    exact (hread r (List.mem_append_right _ (h.outside ▸ hr))).trans (h.outsideValues r hr)
  · intro sn hsn b hb
    rw [hnb]
    rcases hview.snapshots sn hsn with hp | hn
    · exact h.historyBound sn hp b hb
    · exact h.bound b (List.Sublist.subset hn.1 hb)
  · intro sn hsn
    rcases hview.snapshots sn hsn with hp | hn
    · exact h.outsideHistory sn hp
    · refine ⟨hn.2.1.trans h.outside, ?_⟩
      intro r hr
      exact (hn.2.2 r (List.mem_append_right _ (h.outside ▸ hr))).trans (h.outsideValues r hr)
  · rw [hstack]
    cases s.setAside with
    | nil => exact ⟨[], rfl⟩
    | cons p ps => exact ⟨[p], rfl⟩
  · intro v hv
    apply read_back_root
    exact hread (valueRoot v) (List.mem_append_left _
      (List.mem_append_right _ (List.mem_map.mpr ⟨v, hrest v hv, rfl⟩)))

end Trial.Proofs
