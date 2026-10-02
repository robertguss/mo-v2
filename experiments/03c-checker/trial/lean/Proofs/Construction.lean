import Proofs.Variables

namespace Trial.Proofs

/-- Removing the newest pending list exposes precisely the roots that remain;
the empty list contributes only an ignorable empty root. -/
theorem pending_tail_heap (s : RunState) (link : Option Addr) (rest : List RawValue)
    (hh : Owned s)
    (hpend : s.pending = match link with | none => rest | some a => .list (some a) :: rest) :
    Healthy s.mem (link :: (bindingRoots s.bindings ++ rest.map valueRoot ++ s.outside)) := by
  cases link with
  | none => simpa [ownedRoots, hpend] using hh.add_none
  | some a =>
    apply hh.perm
    simp [ownedRoots, hpend, valueRoot, List.append_assoc]

/-- Under the actual reserved-stack and pending-holder preconditions, the
approved cell constructor succeeds, preserves old readable lists, and produces
the requested head and tail with the right ownership. -/
theorem build_cell_safe (s : RunState) (enc : List Nat) (item : Int) (link : Option Addr)
    (rest : List RawValue) (hh : Owned s)
    (hpend : s.pending = match link with | none => rest | some a => .list (some a) :: rest)
    (hreserved : ∀ bid a more, s.setAside = (bid, a) :: more →
      enc.contains bid = true ∧ ∃ c, s.mem.find? a = some c ∧ c.status = .setAside) :
    ∃ a t items, buildCell Variant.approved enc item link s = (.ok (.list (some a)), t) ∧
      Owned t ∧ readBack s.mem (.list link) = .ok (.list items) ∧
      readBack t.mem (.list (some a)) = .ok (.list (item :: items)) ∧
      t.pending = .list (some a) :: rest ∧ t.bindings = s.bindings ∧ t.outside = s.outside ∧
      t.setAside = s.setAside.tail ∧
      (∀ q ∈ ownedRoots s, readBack t.mem (.list q) = readBack s.mem (.list q)) ∧
      t.snaps = (snapshot .newCellBuilt none { t with snaps := s.snaps }).2.snaps := by
  have hpre := pending_tail_heap s link rest hh hpend
  obtain ⟨cs, hpath⟩ := hpre.readable link (by simp)
  cases ha : s.setAside with
  | nil =>
    let m' := (s.mem.create item link).2
    let u : RunState := { s with mem := m', pending := rest }
    let p : RunState := { u with
      log := s.log ++ [.alloc s.mem.next]
      pending := .list (some s.mem.next) :: rest }
    let t := (snapshot .newCellBuilt none p).2
    have hnew : Healthy u.mem (some s.mem.next :: ownedRoots u) := hpre.create item
    have hown := owned_push u s.mem.next hnew
    refine ⟨s.mem.next, t, cs.map Cell.item, ?_, ?_, hpath.read_back, ?_, ?_, ?_, ?_, ?_, ?_⟩
    · cases link <;>
        simp [buildCell, ha, popPending, pushPending, logEvent, snapshot,
          hpend, t, p, u, m', Memory.create]
    · apply hown.same_fields <;> simp [t, p, u, snapshot]
    · simpa [t, p, u, m', snapshot] using create_read_back s.mem item link cs hpath hh.fresh.missing
    · simp [t, p, snapshot]
    · simp [t, p, u, snapshot]
    · simp [t, p, u, snapshot]
    · simp [t, p, u, snapshot, ha]
    · constructor
      · intro q hq
        obtain ⟨ds, hp⟩ := hh.readable q hq
        have hp' := hp.create item link
        simpa [t, p, u, m', snapshot] using hp'.read_back.trans hp.read_back.symm
      · rfl
  | cons entry more =>
    rcases entry with ⟨bid, a⟩
    obtain ⟨henc, c, hf, hs⟩ := hreserved bid a more ha
    simp only [List.contains_iff_mem] at henc
    let m' : Memory := { s.mem.updateCell a (fun _ =>
      { addr := a, item := item, link := link, count := 1, status := .live })
      with record := s.mem.record ++ [.written a] }
    have hw : s.mem.writeInPlace a item link = .ok m' := by
      simp [Memory.writeInPlace, hf, hs, m']
    let u : RunState := { s with mem := m', pending := rest, setAside := more }
    let p : RunState := { u with log := s.log ++ [.reuse a], pending := .list (some a) :: rest }
    let t := (snapshot .newCellBuilt none p).2
    have hnew : Healthy u.mem (some a :: ownedRoots u) := hpre.write a item hw
    have hown := owned_push u a hnew
    refine ⟨a, t, cs.map Cell.item, ?_, ?_, hpath.read_back, ?_, ?_, ?_, ?_, ?_, ?_⟩
    · cases link <;>
        simp [buildCell, ha, henc, Variant.approved, memOp, hw, popPending,
          pushPending, logEvent, snapshot, hpend, t, p, u]
    · apply hown.same_fields <;> simp [t, p, u, snapshot]
    · simpa [t, p, u, snapshot] using write_in_place_read_back s.mem m' a item link hw cs hpath
    · simp [t, p, snapshot]
    · simp [t, p, u, snapshot]
    · simp [t, p, u, snapshot]
    · simp [t, p, u, snapshot]
    · constructor
      · intro q hq
        obtain ⟨ds, hp⟩ := hh.readable q hq
        have hp' := write_in_place_preserves s.mem m' a item link hw q ds hp
        simpa [t, p, u, snapshot] using hp'.read_back.trans hp.read_back.symm
      · rfl

end Trial.Proofs
