import Full.Proofs.PreservationReleaseHeap

namespace Full.Proofs.PreservationRelease
open Counted Trial Trial.Proofs

def bindingCount (bs : List Counted.Binding) (a : Nat) : Nat :=
  (((bs.filter (fun b => b.record.status == .holding)).map
    (fun b => Inspect.link b.record.value)).filter (fun r => r == some a)).length

theorem status_owner_count (bs : List Counted.Binding) (b : Counted.Binding)
    (hb : b ∈ bs) (hu : (bs.map (fun b => b.record.id)).Nodup)
    (hh : b.record.status = .holding) (status : BStatus) (hstatus : status ≠ .holding)
    (a : Nat) :
    bindingCount bs a = bindingCount (bs.map (fun q => if q.record.id == b.record.id then
      { q with record := { q.record with status := status } } else q)) a +
      if Inspect.link b.record.value == some a then 1 else 0 := by
  induction bs with
  | nil => simp at hb
  | cons x xs ih =>
    obtain ⟨hn,hu⟩ := List.nodup_cons.mp hu
    rcases List.mem_cons.mp hb with rfl | hb
    · have hmap : xs.map (fun q => if q.record.id == b.record.id then
          { q with record := { q.record with status := status } } else q) = xs := by
        calc
          _ = xs.map id := List.map_congr_left (by
            intro q hq
            have hne : q.record.id ≠ b.record.id := by
              intro he
              exact hn (List.mem_map.mpr ⟨q,hq,he⟩)
            simp [hne])
          _ = xs := List.map_id xs
      simp only [List.map_cons,beq_self_eq_true,↓reduceIte,hmap]
      cases he : Inspect.link b.record.value == some a <;>
        simp [bindingCount,hh,hstatus,hmap,he]
    · have hne : x.record.id ≠ b.record.id := by
        intro he
        exact hn (List.mem_map.mpr ⟨b,hb,he.symm⟩)
      have hx := ih hb hu
      cases hhx : x.record.status == .holding <;>
        cases he : Inspect.link x.record.value == some a <;>
        simp [bindingCount,hne,hhx,he] at hx ⊢ <;> omega

/-- A flag change preserves the stored value and ghost value. Non-owning
nonempty records need not be reread; all other records still must be. -/
theorem status_binding_checks {id : Nat} (hi : Inspect.invariant initial s = true)
    (hm : ∀ v, readBack t.mem v = readBack s.mem v)
    (hb : t.bindings = s.bindings.map (fun q => if q.record.id == id then
      { q with record := { q.record with status := status } } else q))
    (hstatus : status ≠ .holding) :
    ∀ b ∈ t.bindings, b.record.value.kind = b.value.kind ∧
      ((b.record.status != .holding && (Inspect.link b.record.value).isSome) ||
        Inspect.readable t ⟨b.record.value,b.value⟩) = true := by
  intro b hbmem
  rw [hb] at hbmem
  obtain ⟨q,hq,rfl⟩ := List.mem_map.mp hbmem
  have hx := PreservationOwnership.source_bindings hi q hq
  split
  · refine ⟨hx.1,?_⟩
    cases hv : q.record.value with
    | num n | bool b => simpa [Inspect.link,hstatus,hv,Inspect.readable,hm] using hx.2
    | list l =>
      cases l with
      | none => simpa [Inspect.link,hstatus,hv,Inspect.readable,hm] using hx.2
      | some a => simp [Inspect.link,hstatus,hv]
  · simpa [Inspect.readable,hm] using hx

theorem giveBinding_invariant {id : Nat} (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok c)
    (hs : s.tasks = .giveBinding id :: rest) :
    Inspect.invariant initial c.state = true := by
  have ht' := ht
  have hslots := PreservationOwnership.source_slots hi
  have hu := BindingIdentity.reachable_unique hr
  simp only [Counted.transition,hs,bind,pure,Except.bind,Except.pure] at ht
  split at ht
  next b hb =>
    split at ht
    next hbad => cases ht
    next hgood =>
      have hh : b.record.status = .holding := by simpa using hgood
      have hid : b.record.id = id := by simpa using List.find?_some hb
      have hbm := List.mem_of_find?_eq_some hb
      split at ht
      next addr hv =>
        split at ht
        next cell hf =>
          split at ht
          next hbad => cases ht
          next hgood =>
            have hg : cell.status = .live ∧ cell.count ≠ 0 := by
              simpa only [Bool.or_eq_true,bne_iff_ne,beq_iff_eq,not_or,Decidable.not_not] using hgood
            have hcount := source_count hi hf
            simp only [Memory.setCount,hf,pure,Except.pure] at ht
            cases ht
            have hset : s.mem.setCount addr (cell.count-1) =
                .ok (s.mem.updateCell addr (fun d => { d with count := cell.count-1 })) := by
              simp [Memory.setCount,hf]
            have hread := set_count_read_back _ _ _ _ hset
            have hown := status_owner_count s.bindings b hbm hu hh .givenUp (by decide) addr
            apply count_transfer_invariant hr hi ht' rfl hf hg.1 rfl rfl
            · exact status_binding_checks hi hread rfl (by decide)
            · simpa [Inspect.readable,hread] using hslots
            · intro a
              have hown := status_owner_count s.bindings b hbm hu hh .givenUp (by decide) a
              rw [hid] at hown
              change bindingCount s.bindings a = _ at hown
              simp only [Inspect.owners,count_links,List.filter_append,List.length_append]
              by_cases ha : a = addr
              · subst a
                simp [Inspect.link,hv] at hown
                have hc : cell.count = (s.outside.filter (fun r => r == some addr)).length +
                    bindingCount s.bindings addr +
                    ((s.slots.map (fun v => Inspect.link v.raw)).filter (fun r => r == some addr)).length +
                    (((s.mem.cells.filter (fun d => d.status == .live)).map Cell.link).filter
                      (fun r => r == some addr)).length := by
                  simpa [Inspect.owners,bindingCount,List.filter_append,List.length_append,
                    Nat.add_assoc] using hcount
                simp only [ite_true]
                change _ = cell.count - 1
                rw [hc, hown]
                simp [bindingCount,Nat.add_assoc,Nat.add_comm,Nat.add_left_comm]
              · have he : (Inspect.link b.record.value == some a) = false := by
                  simp [Inspect.link,hv,Ne.symm ha]
                simp only [he,Bool.false_eq_true,↓reduceIte,Nat.add_zero] at hown
                simp only [ha,↓reduceIte]
                unfold bindingCount at hown
                rw [hown]
            · intro a hq
              simp only [hs,List.any_cons,Bool.false_or] at hq
              split <;> simp_all only [List.any_cons,Bool.or_eq_true,or_true]
            · intro hz
              have he : cell.count = 1 := by omega
              simp [he]
        next => cases ht
      next => cases ht
  next => cases ht

theorem var_invariant (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok c)
    (hs : s.tasks = .eval (.var name) ctx :: rest) :
    Inspect.invariant initial c.state = true := by
  have ht' := ht
  have hslots := PreservationOwnership.source_slots hi
  have hbs := PreservationOwnership.source_bindings hi
  have hu := BindingIdentity.reachable_unique hr
  simp only [Counted.transition,hs,bind,pure,Except.bind,Except.pure] at ht
  split at ht
  next x id he =>
    split at ht
    next b hb =>
      have hbm := List.mem_of_find?_eq_some hb
      have hid : b.record.id = id := by simpa using List.find?_some hb
      have hx := hbs b hbm
      cases hv : b.record.value with
      | list l =>
        cases l with
        | some addr =>
          simp only [hv] at ht
          split at ht
          next hbad => cases ht
          next hgood =>
            have hh : b.record.status = .holding := by simpa using hgood
            have hvread : Inspect.readable s ⟨b.record.value,b.value⟩ = true := by
              simpa [hh] using hx.2
            split at ht
            next hlater =>
              split at ht
              next cell hf =>
                split at ht
                next hbad => cases ht
                next hgood =>
                  have hl : cell.status = .live := by simpa using hgood
                  have hcount := source_count hi hf
                  simp only [Memory.setCount,hf,bind,pure,Except.bind,Except.pure] at ht
                  cases ht
                  have hset : s.mem.setCount addr (cell.count+1) =
                      .ok (s.mem.updateCell addr (fun d => { d with count := cell.count+1 })) := by
                    simp [Memory.setCount,hf]
                  have hread := set_count_read_back _ _ _ _ hset
                  apply count_transfer_invariant hr hi ht' rfl hf hl rfl rfl
                  · intro q hq
                    simpa [hlater,Inspect.readable,hread] using hbs q hq
                  · simpa [Inspect.readable,hread,hv] using
                      (show (⟨b.record.value,b.value⟩ :: s.slots).all (Inspect.readable s) = true from by
                        simp [hvread,hslots])
                  · intro a
                    simp only [Inspect.owners,hlater,↓reduceIte,count_links,List.map_cons,
                      List.filter_append,List.length_append]
                    by_cases ha : a = addr
                    · subst a
                      simp only [ite_true]
                      rw [hcount]
                      simp [Inspect.owners,Inspect.link,hv,Nat.add_assoc,Nat.add_comm,Nat.add_left_comm]
                    · simp [Inspect.link,hv,ha,Ne.symm ha]
                  · intro a hq
                    simpa [hs] using hq
                  · intro hz; omega
              next => cases ht
            next hlater =>
              cases ht
              apply PreservationOwnership.transfer_heap_invariant hr hi ht' rfl rfl rfl
              · exact status_binding_checks hi (fun _ => rfl) rfl (by decide)
              · simpa [Inspect.readable,hv] using
                  (show (⟨b.record.value,b.value⟩ :: s.slots).all (Inspect.readable s) = true from by
                    simp [hvread,hslots])
              · intro a
                have hown := status_owner_count s.bindings b hbm hu hh .movedOn (by decide) a
                rw [hid] at hown
                simp only [Inspect.owners,List.map_cons,List.filter_append,List.length_append]
                unfold bindingCount at hown
                rw [hv] at hown
                cases ha : some addr == some a <;>
                  simp [Inspect.link,ha] at hown ⊢
                all_goals simp [hown,Nat.add_assoc,Nat.add_comm,Nat.add_left_comm]
              · intro a hq; simpa [hs] using hq
        | none =>
          simp only [hv] at ht
          cases ht
          apply PreservationOwnership.transfer_heap_invariant hr hi ht' rfl rfl rfl
          · intro q hq; simpa [Inspect.readable] using hbs q hq
          · have hvread : Inspect.readable s ⟨b.record.value,b.value⟩ = true := by
              simpa [Inspect.link,hv] using hx.2
            simpa [Inspect.readable,hv] using
              (show (⟨b.record.value,b.value⟩ :: s.slots).all (Inspect.readable s) = true from by
                simp [hvread,hslots])
          · intro a; simp [Inspect.owners,Inspect.link,hv]
          · intro a hq; simpa [hs] using hq
      | num n | bool v =>
        simp only [hv] at ht
        cases ht
        apply PreservationOwnership.transfer_heap_invariant hr hi ht' rfl rfl rfl
        · intro q hq; simpa [Inspect.readable] using hbs q hq
        · have hvread : Inspect.readable s ⟨b.record.value,b.value⟩ = true := by
            simpa [Inspect.link,hv] using hx.2
          simpa [Inspect.readable,hv] using
            (show (⟨b.record.value,b.value⟩ :: s.slots).all (Inspect.readable s) = true from by
              simp [hvread,hslots])
        · intro a; simp [Inspect.owners,Inspect.link,hv]
        · intro a hq; simpa [hs] using hq
    next => cases ht
  next => cases ht

end Full.Proofs.PreservationRelease
