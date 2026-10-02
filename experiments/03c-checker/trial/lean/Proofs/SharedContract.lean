import Proofs.ReserveContract

namespace Trial.Proofs

/-- Moving a pending holder to an existing nonholding tail binding changes
ownership but not memory or old meanings. -/
theorem StateInvariant.activate_pending {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (tid : Nat) (b : Binding) (a : Addr) (rest : List RawValue)
    (hf : s.bindings.find? (fun q => q.id == tid) = some b)
    (hs : b.status = .noHolder) (hv : b.value = .list (some a))
    (hp : s.pending = .list (some a) :: rest)
    (hr : readBack s.mem (.list (some a)) = .ok (g tid).2) :
    StateInvariant start g enc { s with
      bindings := s.bindings.map (fun q => if q.id == tid then { q with status := .holding } else q)
      pending := rest } := by
  have hbi : b.id = tid := by simpa using List.find?_some hf
  have hsame : ∀ d ∈ s.bindings, d.id = tid → d = b := by
    intro d hd hi
    have hd' : s.bindings.find? (fun q => q.id == tid) = some d := by
      simpa [hi] using binding_find_self s.bindings h.unique d hd
    exact Option.some.inj (hd'.symm.trans hf)
  refine { h with
    owned := ?_
    ids := by rw [status_update_ids]; exact h.ids
    raw := ?_
    kinds := ?_
    readable := ?_
    holding := ?_
    pending := fun v hv => h.pending v (hp ▸ List.mem_cons_of_mem _ hv) }
  · have hh := pending_tail_heap s (some a) rest h.owned hp
    have hp' := binding_roots_activate s.bindings tid b h.unique hf (by simp [hs])
    apply hh.perm
    simpa [ownedRoots, hv, valueRoot] using
      ((hp'.append_right (rest.map valueRoot)).append_right s.outside).symm
  · intro d hd
    obtain ⟨q, hq, heq⟩ := List.mem_map.mp hd
    by_cases hi : q.id = tid <;> simpa [← heq, hi] using h.raw q hq
  · intro d hd
    obtain ⟨q, hq, heq⟩ := List.mem_map.mp hd
    by_cases hi : q.id = tid <;> simpa [← heq, hi] using h.kinds q hq
  · intro d hd hdread
    obtain ⟨q, hq, heq⟩ := List.mem_map.mp hd
    by_cases hi : q.id = tid
    · have hqb := hsame q hq hi
      rw [hqb] at heq
      simpa [← heq, hbi, hv] using hr
    · have hqd : q = d := by simpa [hi] using heq
      exact h.readable d (hqd ▸ hq) hdread
  · intro d hd hdhold
    obtain ⟨q, hq, heq⟩ := List.mem_map.mp hd
    by_cases hi : q.id = tid
    · have hqb := hsame q hq hi
      rw [hqb] at heq
      exact ⟨a, by simp [← heq, hbi, hv]⟩
    · have hqd : q = d := by simpa [hi] using heq
      exact h.holding d (hqd ▸ hq) hdhold

/-- In a shared match, copying the tail holder into the tail binding has the
full boundary invariant. Every read-back, including the matched list, is unchanged. -/
theorem activate_tail_contract {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (tid : Nat) (b : Binding) (a : Addr) (c : Cell)
    (hf : s.bindings.find? (fun q => q.id == tid) = some b)
    (hs : b.status = .noHolder) (hv : b.value = .list (some a))
    (hc : s.mem.find? a = some c) (hl : c.status = .live)
    (hr : readBack s.mem (.list (some a)) = .ok (g tid).2) :
    ∃ t, (do addHolder a; setBindingStatus tid .holding : M Unit) s = (.ok (), t) ∧
      StateInvariant start g enc t ∧
      t.bindings = s.bindings.map (fun q => if q.id == tid then { q with status := .holding } else q) ∧
      t.pending = s.pending ∧ t.setAside = s.setAside ∧ t.nextBinding = s.nextBinding ∧
      t.nextBranch = s.nextBranch ∧ t.snaps = s.snaps ∧
      (∀ v, readBack t.mem v = readBack s.mem v) := by
  let m := s.mem.updateCell a (fun d => { d with count := c.count + 1 })
  let u := { s with mem := m, pending := .list (some a) :: s.pending }
  let t : RunState := { s with
    mem := m
    bindings := s.bindings.map (fun q => if q.id == tid then { q with status := .holding } else q) }
  have hm : s.mem.setCount a (c.count + 1) = .ok m := by simp [Memory.setCount, hc, m]
  have hread := set_count_read_back s.mem m a _ hm
  have hu : StateInvariant start g enc u := h.copy_holder a c hc hl
  have ht := hu.activate_pending tid b a s.pending hf hs hv rfl ((hread _).trans hr)
  refine ⟨t, ?_, ht, rfl, rfl, rfl, rfl, rfl, rfl, hread⟩
  simp [addHolder, getLiveCell, getCell, memOp, setBindingStatus, hc, hl, hm, t]

end Trial.Proofs
