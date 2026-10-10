import Full.Proofs.PreservationOwnership
import Full.Proofs.ProgressHeap

namespace Full.Proofs.PreservationCells
open Counted Trial Trial.Proofs

/-- The scalar head used by decomposition is the actual heap head, not merely
an independently well-typed ghost. The tail has the same exact readback. -/
theorem decompose_readback (hi : Inspect.invariant initial s = true)
    (hm : v ∈ s.slots) (hv : v.raw = .list (some addr))
    (hvalue : v.value = .list (ph :: pt))
    (hf : s.mem.find? addr = some cell) :
    cell.item = ph ∧ Trial.readBack s.mem (.list cell.link) = .ok (.list pt) := by
  have hread := Progress.slot_readable hi hm
  obtain ⟨c,hfc,hl,_⟩ := Progress.root_ready hi (Progress.slot_root hm hv)
  rw [hf] at hfc
  cases hfc
  obtain ⟨hh,hpaths,_⟩ := invariant_heap initial s hi
  obtain ⟨cs,hpath⟩ := hpaths cell (List.mem_of_find?_eq_some hf) hl
  obtain ⟨d,ds,hcs,hfd,ha,_,htail⟩ := hpath.head
  have haddr : cell.addr = addr := by simpa using List.find?_some hf
  rw [haddr,hf] at hfd
  cases hfd
  have hfull := hpath.read_back
  have htailread := htail.read_back
  have heq : cell.item :: ds.map Cell.item = ph :: pt := by
    rw [hcs] at hfull
    simpa [Inspect.readable,hv,hvalue,← haddr,hfull,beq_iff_eq] using hread
  have hh' := List.cons.inj heq
  exact ⟨hh'.1, by simpa [hh'.2] using htailread⟩

/-- Shared decomposition with no tail acquisition retains the operand until
GivePending. Both new identities are nevertheless checked at this boundary. -/
theorem decompose_shared_unused_invariant
    (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok change)
    (hs : s.tasks = .decompose head tail body bid ctx :: rest)
    (hslots : s.slots = v :: slots)
    (hv : v.raw = .list (some addr))
    (hvalue : v.value = .list (ph :: pt))
    (hf : s.mem.find? addr = some cell)
    (hshared : cell.count ≠ 1)
    (hused : uses body (Trial.toFEnv
      ((tail,s.nextBinding+1)::(head,s.nextBinding)::ctx.env)) (s.nextBinding+1) = false) :
    Inspect.invariant initial change.state = true := by
  have ht' := ht
  have hbs := PreservationOwnership.source_bindings hi
  have hss := PreservationOwnership.source_slots hi
  obtain ⟨hhead,htail⟩ := decompose_readback hi (by simp [hslots]) hv hvalue hf
  obtain ⟨c,hfc,hl,hpos⟩ := Progress.root_ready hi
    (Progress.slot_root (by simp [hslots]) hv)
  rw [hf] at hfc
  cases hfc
  have hz : cell.count ≠ 0 := by omega
  simp only [Counted.transition,hs,hslots,hv,hvalue,hf,hl,hused,
    bne_self_eq_false,beq_eq_false_iff_ne.mpr hz,
    beq_eq_false_iff_ne.mpr hshared,Bool.false_or,Bool.false_and,
    Bool.false_eq_true,↓reduceIte,bind,pure,Except.bind,Except.pure] at ht
  cases ht
  apply PreservationOwnership.transfer_heap_invariant hr hi ht' rfl rfl rfl
  · intro b hb
    simp only [List.mem_append,List.mem_cons,List.not_mem_nil,or_false] at hb
    rcases hb with hb | rfl | rfl
    · simpa [Inspect.readable] using hbs b hb
    · simp [makeBinding,Inspect.readable,Trial.readBack,hhead,RawValue.kind,PlainValue.kind]
    · cases hlink : cell.link with
      | none =>
        have he : pt = [] := by
          simpa [hlink,Trial.readBack,Trial.readList] using htail.symm
        simp [makeBinding,Inspect.readable,Trial.readBack,Trial.readList,he,
          RawValue.kind,PlainValue.kind]
      | some a => simp [makeBinding,Inspect.link,RawValue.kind,PlainValue.kind]
  · simpa [Inspect.readable,hslots] using hss
  · intro a
    cases cell.link <;>
      simp [Inspect.owners,List.filter_append,makeBinding,Inspect.link,hslots]
  · intro a ha
    simp only [hs,List.any_cons,Bool.false_or] at ha
    simp [ha]

end Full.Proofs.PreservationCells
