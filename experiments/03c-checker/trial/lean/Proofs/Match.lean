import Proofs.DisposalViews

namespace Trial.Proofs

/-- Activating one uniquely identified nonholding binding adds exactly its root. -/
theorem binding_roots_activate (bs : List Binding) (id : Nat) (b : Binding)
    (hu : (bs.map Binding.id).Nodup)
    (hf : bs.find? (fun d => d.id == id) = some b) (hs : b.status ≠ .holding) :
    (bindingRoots (bs.map (fun d => if d.id == id then { d with status := .holding } else d))).Perm
      (valueRoot b.value :: bindingRoots bs) := by
  induction bs with
  | nil => simp at hf
  | cons c cs ih =>
    simp only [List.map_cons, List.nodup_cons] at hu
    by_cases hci : c.id = id
    · simp [hci] at hf
      subst b
      have ha : ∀ d ∈ cs, d.id ≠ id := by
        intro d hd he
        exact hu.1 (List.mem_map.mpr ⟨d, hd, he.trans hci.symm⟩)
      have ht := status_update_absent cs id .holding ha
      simp only [beq_iff_eq] at ht
      simp [bindingRoots, hs, hci, ht]
    · simp [hci] at hf
      have hp := ih hu.2 hf
      simp only [beq_iff_eq] at hp
      by_cases hc : c.status = .holding
      · simpa [bindingRoots, hci, hc] using
          (hp.cons (valueRoot c.value)).trans (List.Perm.swap (valueRoot b.value) (valueRoot c.value) _)
      · simpa [bindingRoots, hci, hc] using hp

/-- The exclusive match step consumes the pending match holder, reserves its
cell, and transfers its tail holder to the already-created tail binding. It
preserves the tail's contents and all other owners' lists. -/
theorem match_reserve_owned (s : RunState) (a : Addr) (c : Cell) (bid tid : Nat)
    (tailBinding : Binding) (rest : List RawValue)
    (hh : Owned s) (hu : (s.bindings.map Binding.id).Nodup)
    (hf : s.mem.find? a = some c) (hl : c.status = .live) (hc : c.count = 1)
    (hb : s.bindings.find? (fun b => b.id == tid) = some tailBinding)
    (hs : tailBinding.status = .noHolder) (hv : tailBinding.value = .list c.link)
    (hpend : s.pending = .list (some a) :: rest) :
    ∃ t items, (do
      popPending (.list (some a))
      memOp (fun m => m.markSetAside a)
      modify fun u => { u with setAside := (bid, a) :: u.setAside }
      match c.link with
      | some _ => setBindingStatus tid .holding
      | none => pure () : M Unit) s = (.ok (), t) ∧
      Owned t ∧ t.pending = rest ∧ t.setAside = (bid, a) :: s.setAside ∧
      readBack s.mem (.list c.link) = .ok (.list items) ∧
      readBack t.mem (.list c.link) = .ok (.list items) ∧
      (∀ q ∈ bindingRoots s.bindings ++ rest.map valueRoot ++ s.outside,
        readBack t.mem (.list q) = readBack s.mem (.list q)) := by
  let roots := bindingRoots s.bindings ++ rest.map valueRoot ++ s.outside
  have hpre : Healthy s.mem (some a :: roots) :=
    pending_tail_heap s (some a) rest hh hpend
  obtain ⟨cells, hp⟩ := hpre.readable (some a) (by simp)
  obtain ⟨d, ds, _, hd, _, _, ht⟩ := hp.head
  have he : d = c := Option.some.inj (hd.symm.trans hf)
  subst d
  let m := s.mem.updateCell a (fun d => { d with status := .setAside, count := 0, link := none })
  have hm : s.mem.markSetAside a = .ok m := by simp [Memory.markSetAside, hf, m]
  have hhealthy := hpre.reserve hf hl hc hm
  obtain ⟨_, htail, hread⟩ := hpre.toHeapSafe.reserve hf hl hc hm ds ht
  let t : RunState := { s with
    mem := m
    pending := rest
    setAside := (bid, a) :: s.setAside
    bindings := match c.link with
      | none => s.bindings
      | some _ => s.bindings.map (fun b => if b.id == tid then { b with status := .holding } else b) }
  refine ⟨t, ds.map Cell.item, ?_, ?_, rfl, rfl, ht.read_back, htail.read_back, hread⟩
  · cases hlink : c.link <;>
      simp [popPending, hpend, memOp, hm, setBindingStatus, t, hlink]
  · cases hlink : c.link with
    | none =>
      have h : Healthy m (none :: roots) := by simpa [hlink] using hhealthy
      simpa [Owned, ownedRoots, t, hlink, roots] using h.drop_none
    | some b =>
      have h : Healthy m (some b :: roots) := by simpa [hlink] using hhealthy
      have hact := binding_roots_activate s.bindings tid tailBinding hu hb (by simp [hs])
      have hp := (hact.append_right (rest.map valueRoot)).append_right s.outside
      apply h.perm
      simpa [ownedRoots, t, hlink, roots, hv, valueRoot] using hp.symm

/-- The shared-cell match case may add a holder on its tail for the new tail
binding. This changes counts but no list contents. -/
theorem activate_tail_owned (s : RunState) (tid : Nat) (b : Binding) (a : Addr)
    (hh : Owned s) (hu : (s.bindings.map Binding.id).Nodup)
    (hf : s.bindings.find? (fun d => d.id == tid) = some b)
    (hs : b.status = .noHolder) (hv : b.value = .list (some a))
    (cs : List Cell) (hp : ListPath s.mem (some a) cs) :
    ∃ t, (do
      addHolder a
      setBindingStatus tid .holding : M Unit) s = (.ok (), t) ∧
      Owned t ∧ t.pending = s.pending ∧ t.outside = s.outside ∧
      t.bindings = s.bindings.map (fun d => if d.id == tid then { d with status := .holding } else d) ∧
      (∀ v, readBack t.mem v = readBack s.mem v) := by
  obtain ⟨u, he, hhu, hr, hpend, hbind, hout⟩ := add_holder_safe s a (ownedRoots s) hh cs hp
  let t : RunState := { u with
    bindings := u.bindings.map (fun d => if d.id == tid then { d with status := .holding } else d) }
  have hact := binding_roots_activate s.bindings tid b hu hf (by simp [hs])
  have hperm := (hact.append_right (s.pending.map valueRoot)).append_right s.outside
  refine ⟨t, ?_, ?_, hpend, hout, ?_, hr⟩
  · simp [setBindingStatus, he, t]
  · apply hhu.perm
    simpa [ownedRoots, t, hbind, hpend, hout, hv, valueRoot] using hperm.symm
  · simp [t, hbind]

/-- Consuming and giving up a pending match holder succeeds, including an
empty list. All other holders and every observation of them are preserved. -/
theorem give_up_pending_owned (s : RunState) (r : Option Addr) (rest : List RawValue)
    (hh : Owned s)
    (hpend : s.pending = match r with | none => rest | some a => .list (some a) :: rest) :
    ∃ t, (do
      popPending (.list r)
      giveUpLink Variant.approved r : M Unit) s = (.ok (), t) ∧
      Owned t ∧ t.pending = rest ∧ t.bindings = s.bindings ∧ t.outside = s.outside ∧
      PreservesViews (bindingRoots s.bindings ++ rest.map valueRoot ++ s.outside) s t := by
  let u : RunState := { s with pending := rest }
  let roots := bindingRoots s.bindings ++ rest.map valueRoot ++ s.outside
  have hpre : Healthy u.mem (r :: roots) := pending_tail_heap s r rest hh hpend
  obtain ⟨t, he, hht, _, hpt, hbt, hot⟩ := give_up_link_safe u r roots hpre
  have hroot : ownedRoots t = roots := by simp [ownedRoots, hpt, hbt, hot, u, roots]
  have hvu : PreservesViews roots s u := .of_fields roots s u rfl rfl (fun _ _ => rfl) rfl
  have hvt := give_up_link_views u r roots hpre.toHeapSafe
  rw [he] at hvt
  refine ⟨t, ?_, ?_, hpt, hbt, hot, hvu.trans hvt⟩
  · cases r with
    | none =>
      have hu : u = s := by simp [u, ← hpend]
      simpa [popPending, hu] using he
    | some a => simpa [popPending, hpend, u] using he
  · unfold Owned
    rw [hroot]
    exact hht

end Trial.Proofs
