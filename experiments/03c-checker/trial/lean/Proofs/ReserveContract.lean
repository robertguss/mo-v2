import Proofs.MatchBindings

namespace Trial.Proofs

def reservedState (s : RunState) (a : Addr) (c : Cell) (bid tid : Nat) (rest : List RawValue) : RunState :=
  { s with
    mem := s.mem.updateCell a (fun d => { d with status := .setAside, count := 0, link := none })
    pending := rest
    setAside := (bid, a) :: s.setAside
    bindings := match c.link with
      | none => s.bindings
      | some _ => s.bindings.map (fun b => if b.id == tid then { b with status := .holding } else b) }

def reserveAction (a : Addr) (c : Cell) (bid tid : Nat) : M Unit := do
  popPending (.list (some a))
  memOp (fun m => m.markSetAside a)
  modify fun s => { s with setAside := (bid, a) :: s.setAside }
  match c.link with
  | some _ => setBindingStatus tid .holding
  | none => pure ()

theorem reserve_action_run (s : RunState) (a : Addr) (c : Cell) (bid tid : Nat) (rest : List RawValue)
    (hf : s.mem.find? a = some c) (hp : s.pending = .list (some a) :: rest) :
    reserveAction a c bid tid s = (.ok (), reservedState s a c bid tid rest) := by
  cases hh : c.link <;>
    simp [reserveAction, popPending, hp, memOp, Memory.markSetAside, hf,
      setBindingStatus, reservedState, hh]

theorem reserve_action_saved (s : RunState) (a : Addr) (c : Cell) (bid tid : Nat)
    (b : Binding) (rest : List RawValue) (h : Owned s) (hu : (s.bindings.map Binding.id).Nodup)
    (hf : s.mem.find? a = some c) (hl : c.status = .live) (hc : c.count = 1)
    (hb : s.bindings.find? (fun d => d.id == tid) = some b)
    (hs : b.status = .noHolder) (hv : b.value = .list c.link)
    (hp : s.pending = .list (some a) :: rest) :
    ∀ v ∈ rest, readBack (reservedState s a c bid tid rest).mem v = readBack s.mem v := by
  obtain ⟨u, _, he, _, _, _, _, _, hread⟩ :=
    match_reserve_owned s a c bid tid b rest h hu hf hl hc hb hs hv hp
  have he' : reserveAction a c bid tid s = (.ok (), u) := he
  have hut : u = reservedState s a c bid tid rest :=
    congrArg Prod.snd (he'.symm.trans (reserve_action_run s a c bid tid rest hf hp))
  subst u
  intro v hv
  apply read_back_root
  exact hread _ (List.mem_append_left _ (List.mem_append_right _ (List.mem_map.mpr ⟨v, hv, rfl⟩)))

/-- The exclusive match step consumes its pending holder and transfers the
tail's holder to the new tail binding, preserving all historical meanings. -/
theorem reserve_contract {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (bid : Nat) (h : StateInvariant start g (bid :: enc) s) (a : Addr) (c : Cell)
    (tid : Nat) (b : Binding) (rest : List RawValue)
    (hf : s.mem.find? a = some c) (hl : c.status = .live) (hc : c.count = 1)
    (hb : s.bindings.find? (fun d => d.id == tid) = some b)
    (hs : b.status = .noHolder) (hv : b.value = .list c.link)
    (hp : s.pending = .list (some a) :: rest)
    (hr : readBack s.mem (.list c.link) = .ok (g tid).2)
    (ho : (s.setAside.map Prod.fst).Sublist enc) :
    StateInvariant start g (bid :: enc) (reservedState s a c bid tid rest) := by
  let t := reservedState s a c bid tid rest
  have hca : c.addr = a := by simpa using List.find?_some hf
  have hbi : b.id = tid := by simpa using List.find?_some hb
  have hbm := List.mem_of_find?_eq_some hb
  have hmark : s.mem.markSetAside a = .ok t.mem := by
    simp [Memory.markSetAside, hf, t, reservedState]
  obtain ⟨u, items, he, hown, _, _, htail, htail', hreads⟩ :=
    match_reserve_owned s a c bid tid b rest h.owned h.unique hf hl hc hb hs hv hp
  have hrun : (do
      popPending (.list (some a))
      memOp (fun m => m.markSetAside a)
      modify fun u => { u with setAside := (bid, a) :: u.setAside }
      match c.link with
      | some _ => setBindingStatus tid .holding
      | none => pure () : M Unit) s = (.ok (), t) := by
    cases hh : c.link <;>
      simp [popPending, hp, memOp, hmark, setBindingStatus, t, reservedState, hh]
  have hut : u = t := congrArg Prod.snd (he.symm.trans hrun)
  subst u
  have htailg : readBack t.mem (.list c.link) = .ok (g tid).2 :=
    htail'.trans (htail.symm.trans hr)
  have hpres : ∀ d ∈ s.bindings, d.status = .holding ∨ valueRoot d.value = none →
      readBack t.mem d.value = .ok (g d.id).2 := by
    intro d hd hread
    rcases hread with hh | hn
    · have hroot : valueRoot d.value ∈ bindingRoots s.bindings := by
        simp [bindingRoots]
        exact ⟨d, hd, by simp [hh]⟩
      exact (read_back_root _ _ d.value (hreads _
        (List.mem_append_left _ (List.mem_append_left _ hroot)))).trans (h.readable d hd (Or.inl hh))
    · exact (read_back_no_root t.mem s.mem d.value hn).trans (h.readable d hd (Or.inr hn))
  have hsame : ∀ d ∈ s.bindings, d.id = tid → d = b := by
    intro d hd hi
    have hd' : s.bindings.find? (fun q => q.id == tid) = some d := by
      simpa [hi] using binding_find_self s.bindings h.unique d hd
    exact Option.some.inj (hd'.symm.trans hb)
  have haddress : a ∉ s.setAside.map Prod.snd := by
    intro ha
    obtain ⟨p, hp', heq⟩ := List.mem_map.mp ha
    obtain ⟨d, hd, hds⟩ := h.reserved p hp'
    rw [heq, hf] at hd
    have heq' := Option.some.inj hd
    subst d
    simp [hl] at hds
  have hlabel : bid ∉ s.setAside.map Prod.fst :=
    fun hm => (List.nodup_cons.mp h.branches).1 (ho.subset hm)
  refine {
    owned := hown
    ids := ?_
    raw := ?_
    kinds := ?_
    readable := ?_
    holding := ?_
    pending := fun v hv => h.pending v (hp ▸ List.mem_cons_of_mem _ hv)
    reserved := ?_
    tracked := ?_
    detached := ?_
    addresses := List.nodup_cons.mpr ⟨haddress, h.addresses⟩
    labels := List.nodup_cons.mpr ⟨hlabel, h.labels⟩
    ordered := ho.cons_cons bid
    branches := h.branches
    branchBound := h.branchBound
    outside := h.outside
    outsideValues := fun r hr' => (hreads r (List.mem_append_right _ (h.outside ▸ hr'))).trans (h.outsideValues r hr')
    history := h.history
    historyBound := h.historyBound
    outsideHistory := h.outsideHistory }
  · cases hlink : c.link with
    | none => simpa [reservedState, hlink] using h.ids
    | some r =>
      simp only [reservedState, hlink]
      rw [status_update_ids, h.ids]
  · intro d hd
    cases hlink : c.link with
    | none => exact h.raw d (by simpa [reservedState, hlink] using hd)
    | some r =>
      simp only [reservedState, hlink] at hd
      obtain ⟨q, hq, heq⟩ := List.mem_map.mp hd
      by_cases hi : q.id = tid <;> simpa [hi, ← heq] using h.raw q hq
  · intro d hd
    cases hlink : c.link with
    | none => exact h.kinds d (by simpa [reservedState, hlink] using hd)
    | some r =>
      simp only [reservedState, hlink] at hd
      obtain ⟨q, hq, heq⟩ := List.mem_map.mp hd
      by_cases hi : q.id = tid <;> simpa [hi, ← heq] using h.kinds q hq
  · intro d hd hread
    cases hlink : c.link with
    | none => exact hpres d (by simpa [reservedState, hlink] using hd) hread
    | some r =>
      simp only [reservedState, hlink] at hd
      obtain ⟨q, hq, heq⟩ := List.mem_map.mp hd
      by_cases hi : q.id = tid
      · have hqb := hsame q hq hi
        rw [hqb] at heq
        simpa [← heq, hbi, hv] using htailg
      · have hqd : q = d := by simpa [hi] using heq
        exact hpres d (hqd ▸ hq) hread
  · intro d hd hh
    cases hlink : c.link with
    | none => exact h.holding d (by simpa [reservedState, hlink] using hd) hh
    | some r =>
      simp only [reservedState, hlink] at hd
      obtain ⟨q, hq, heq⟩ := List.mem_map.mp hd
      by_cases hi : q.id = tid
      · have hqb := hsame q hq hi
        rw [hqb] at heq
        exact ⟨r, by simp [← heq, hbi, hv, hlink]⟩
      · have hqd : q = d := by simpa [hi] using heq
        exact h.holding d (hqd ▸ hq) hh
  · intro p hp'
    rcases List.mem_cons.mp hp' with heq | hm
    · subst p
      refine ⟨{ c with status := .setAside, count := 0, link := none }, ?_, rfl⟩
      change (s.mem.updateCell a _).find? a = _
      rw [find_update s.mem a a _ (by intro d _; rfl)]
      simp [hf, hca]
    · obtain ⟨d, hd, hds⟩ := h.reserved p hm
      have hne : p.2 ≠ a := fun he => haddress (List.mem_map.mpr ⟨p, hm, he⟩)
      refine ⟨d, ?_, hds⟩
      change (s.mem.updateCell a _).find? p.2 = _
      rw [find_update_other s.mem a p.2 _ (by intro d _; rfl) hne, hd]
  · intro d hd hds
    obtain ⟨q, hq, heq⟩ := List.mem_map.mp hd
    by_cases hi : q.addr = a
    · exact ⟨bid, by simp [reservedState, ← heq, hi]⟩
    · have hqd : q = d := by simpa [hi] using heq
      obtain ⟨b', hb'⟩ := h.tracked d (hqd ▸ hq) hds
      exact ⟨b', List.mem_cons_of_mem _ hb'⟩
  · intro d hd hds
    obtain ⟨q, hq, heq⟩ := List.mem_map.mp hd
    by_cases hi : q.addr = a
    · simp [← heq, hi]
    · have hqd : q = d := by simpa [hi] using heq
      exact h.detached d (hqd ▸ hq) hds

end Trial.Proofs
