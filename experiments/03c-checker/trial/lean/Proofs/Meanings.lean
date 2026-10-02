import Proofs.Cleanup

namespace Trial.Proofs

/-- Equality of the list-root read-back suffices for any raw value; scalar
read-backs are independent of memory. -/
theorem read_back_root (m m' : Memory) (v : RawValue)
    (h : readBack m (.list (valueRoot v)) = readBack m' (.list (valueRoot v))) :
    readBack m v = readBack m' v := by
  cases v with
  | num n => rfl
  | bool b => rfl
  | list r => exact h

/-- Holding meanings survive any memory operation which preserves the roots
owned by those bindings. -/
theorem HoldingMeanings.roots {m m' : Memory} {bs : List Binding}
    {raw : Nat → RawValue} {meaning : Nat → PlainValue}
    (h : HoldingMeanings m bs raw meaning)
    (hr : ∀ r ∈ bindingRoots bs, readBack m' (.list r) = readBack m (.list r)) :
    HoldingMeanings m' bs raw meaning := by
  intro b hb hs
  obtain ⟨hv, hm⟩ := h b hb hs
  refine ⟨hv, ?_⟩
  have hroot : valueRoot b.value ∈ bindingRoots bs :=
    List.mem_filterMap.mpr ⟨b, hb, by simp [hs]⟩
  exact (read_back_root m' m b.value (hr _ hroot)).trans hm

/-- A binding which gives up or moves its holder is no longer subject to the
holding-name promise; every still-holding binding keeps its recorded meaning. -/
theorem HoldingMeanings.drop {m : Memory} {bs : List Binding}
    {raw : Nat → RawValue} {meaning : Nat → PlainValue}
    (h : HoldingMeanings m bs raw meaning) (id : Nat) (st : BStatus) (hn : st ≠ .holding) :
    HoldingMeanings m
      (bs.map (fun b => if b.id == id then { b with status := st } else b)) raw meaning := by
  intro b hb hs
  obtain ⟨d, hd, he⟩ := List.mem_map.mp hb
  subst b
  split at hs
  · exact False.elim (hn hs)
  · rename_i hne
    simpa [hne] using h d hd hs

/-- Extending the proof's per-id interpretation at a fresh id leaves meanings
for all older holding bindings unchanged. -/
theorem HoldingMeanings.fresh {m : Memory} {bs : List Binding}
    {raw : Nat → RawValue} {meaning : Nat → PlainValue}
    (h : HoldingMeanings m bs raw meaning) (next : Nat) (v : RawValue) (w : PlainValue)
    (hb : ∀ b ∈ bs, b.id < next) :
    HoldingMeanings m bs (fun id => if id = next then v else raw id)
      (fun id => if id = next then w else meaning id) := by
  intro b hmem hs
  have hn := Nat.ne_of_lt (hb b hmem)
  simpa [hn] using h b hmem hs

/-- A newly bound holder has the read-back which its producer supplied. -/
theorem HoldingMeanings.append {m : Memory} {bs : List Binding}
    {raw : Nat → RawValue} {meaning : Nat → PlainValue}
    (h : HoldingMeanings m bs raw meaning) (b : Binding)
    (hb : b.status = .holding → b.value = raw b.id ∧ readBack m b.value = .ok (meaning b.id)) :
    HoldingMeanings m (bs ++ [b]) raw meaning := by
  intro d hd hs
  rcases List.mem_append.mp hd with hm | he
  · exact h d hm hs
  · have he' : d = b := by simpa using he
    subst d
    exact hb hs

/-- The actual approved binding release preserves the meanings of every name
which still holds afterwards. This is the current-state part, not yet the
assertion about all intermediate snapshots. -/
theorem give_up_binding_meanings (s : RunState) (id : Nat) (b : Binding) (r : Option Addr)
    (hh : Owned s) (hu : (s.bindings.map Binding.id).Nodup)
    (hf : s.bindings.find? (fun d => d.id == id) = some b)
    (hs : b.status = .holding) (hv : b.value = .list r)
    (raw : Nat → RawValue) (meaning : Nat → PlainValue)
    (hmean : HoldingMeanings s.mem s.bindings raw meaning) :
    HoldingMeanings (giveUpBinding Variant.approved id s).2.mem
      (giveUpBinding Variant.approved id s).2.bindings raw meaning := by
  obtain ⟨t, he, _, hb, _, _, hr⟩ := give_up_binding_owned s id b r hh hu hf hs hv
  rw [he]
  have hdrop : HoldingMeanings s.mem t.bindings raw meaning := by
    rw [hb]
    exact hmean.drop id .givenUp (by decide)
  apply hdrop.roots
  intro q hq
  exact hr q (List.mem_append_left _ (List.mem_append_left _ hq))

end Trial.Proofs
