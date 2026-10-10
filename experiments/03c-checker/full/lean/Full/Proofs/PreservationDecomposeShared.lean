import Full.Proofs.PreservationCells
import Full.Proofs.PreservationReleaseHeap

namespace Full.Proofs.PreservationDecomposeShared
open Counted Trial Trial.Proofs

theorem fresh_checks {id : Nat} (hi : Inspect.invariant initial s = true)
    (hread : ∀ r, readBack t.mem r = readBack s.mem r)
    (hhead : item = ph) (htail : readBack s.mem (.list link) = .ok (.list pt))
    (hb : t.bindings = s.bindings ++
      [makeBinding id head ⟨.num item,.num ph⟩ invocation headSite,
       makeBinding (id+1) tail ⟨.list link,.list pt⟩ invocation tailSite hold]) :
    ∀ b ∈ t.bindings, b.record.value.kind = b.value.kind ∧
      ((b.record.status != .holding && (Inspect.link b.record.value).isSome) ||
        Inspect.readable t ⟨b.record.value,b.value⟩) = true := by
  intro b hm
  rw [hb] at hm
  simp only [List.mem_append,List.mem_cons,List.not_mem_nil,or_false] at hm
  rcases hm with hm | rfl | rfl
  · simpa [Inspect.readable,hread] using PreservationOwnership.source_bindings hi b hm
  · simp [makeBinding,Inspect.readable,readBack,hhead,RawValue.kind,PlainValue.kind]
  · simp [makeBinding,Inspect.readable,hread,htail,RawValue.kind,PlainValue.kind]

set_option maxHeartbeats 2000000 in
theorem decompose_shared_invariant
    (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok change)
    (hs : s.tasks = .decompose head tail body bid ctx :: rest)
    (hslots : s.slots = v :: slots)
    (hv : v.raw = .list (some addr))
    (hvalue : v.value = .list (ph :: pt))
    (hf : s.mem.find? addr = some cell)
    (hc : cell.count ≠ 1) :
    Inspect.invariant initial change.state = true := by
  cases hused : uses body (Trial.toFEnv
      ((tail,s.nextBinding+1)::(head,s.nextBinding)::ctx.env)) (s.nextBinding+1) with
  | false => exact PreservationCells.decompose_shared_unused_invariant hr hi ht hs hslots hv hvalue hf hc hused
  | true =>
    have ht' := ht
    have hss := PreservationOwnership.source_slots hi
    obtain ⟨hhead,htail⟩ := PreservationCells.decompose_readback hi (by simp [hslots]) hv hvalue hf
    obtain ⟨c,hfc,hl,hpos⟩ := Progress.root_ready hi (Progress.slot_root (by simp [hslots]) hv)
    rw [hf] at hfc
    cases hfc
    have hz : cell.count ≠ 0 := by omega
    simp only [Counted.transition,hs,hslots,hv,hvalue,hf,hl,hused,
      bne_self_eq_false,beq_eq_false_iff_ne.mpr hz,beq_eq_false_iff_ne.mpr hc,
      Bool.false_or,Bool.false_eq_true,↓reduceIte,bind,pure,Except.bind,Except.pure] at ht
    cases hlink : cell.link with
    | none =>
      simp only [hlink,pure,Except.pure] at ht
      cases ht
      apply PreservationOwnership.transfer_heap_invariant hr hi ht' rfl rfl rfl
      · apply fresh_checks hi ?_ hhead ?_ rfl
        · intro r; rfl
        · simpa [hlink] using htail
      · simpa [Inspect.readable,hslots] using hss
      · intro a
        simp [Inspect.owners,List.filter_append,makeBinding,Inspect.link,hlink,hslots]
      · intro a ha
        simp only [hs,List.any_cons,Bool.false_or] at ha
        simp [ha]
    | some tailAddr =>
      simp only [hlink] at ht
      cases htc : s.mem.find? tailAddr with
      | none => simp [htc] at ht
      | some tc =>
        have htlive : tc.status = .live := by
          obtain ⟨hh,hpaths,_⟩ := invariant_heap initial s hi
          have hm := List.mem_of_find?_eq_some hf
          obtain ⟨cs,hp⟩ := hpaths cell hm hl
          obtain ⟨d,ds,_,hd,_,_,ht⟩ := hp.head
          have hid : cell.addr = addr := by simpa using List.find?_some hf
          rw [hid,hf] at hd
          cases hd
          rw [hlink] at ht
          obtain ⟨d,_,_,hd,_,hstatus,_⟩ := ht.head
          rw [htc] at hd
          cases hd
          exact hstatus
        simp only [htc,Memory.setCount,bind,pure,Except.bind,Except.pure] at ht
        cases ht
        have hset : s.mem.setCount tailAddr (tc.count+1) =
            .ok (s.mem.updateCell tailAddr (fun d => { d with count := tc.count+1 })) := by
          simp [Memory.setCount,htc]
        have hread := set_count_read_back _ _ _ _ hset
        have hcount := PreservationRelease.source_count hi htc
        apply PreservationRelease.count_transfer_invariant hr hi ht' rfl htc htlive rfl rfl
        · apply fresh_checks hi hread hhead ?_ rfl
          simpa [hlink] using htail
        · simpa [Inspect.readable,hread,hslots] using hss
        · intro a
          by_cases ha : a = tailAddr
          · subst a
            simp [Inspect.owners,PreservationRelease.count_links,makeBinding,
              Inspect.link,hlink,hcount,List.filter_append,hslots,
              Nat.add_assoc,Nat.add_comm,Nat.add_left_comm]
          · simp [Inspect.owners,PreservationRelease.count_links,makeBinding,
              Inspect.link,hlink,ha,Ne.symm ha,List.filter_append,hslots]
        · intro a ha
          simp only [hs,List.any_cons,Bool.false_or] at ha
          simp [ha]
        · intro hz; omega

end Full.Proofs.PreservationDecomposeShared
