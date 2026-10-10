import Full.Proofs.PreservationConsHeap

namespace Full.Proofs.PreservationCons
open Counted Trial Trial.Proofs

/-- Reassemble the exact executable invariant after building one cell. Old
zero-count live cells retain their pending-free obligation; reserved cells
retain their unique matching reservation, rather than a positivity premise. -/
theorem build_invariant (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok c)
    (hs : s.tasks = .primitive .cons ctx :: rest)
    (hbindings : c.state.bindings = s.bindings)
    (hslots : c.state.slots = ⟨.list (some addr),value⟩ :: slots)
    (hedges : c.state.edges = (addr,tail) :: s.edges.filter (fun q => q.1 != addr))
    (htasks : c.state.tasks = rest)
    (hread : ∀ v w, readBack s.mem v = .ok w → readBack c.state.mem v = .ok w)
    (hnewread : readBack c.state.mem (.list (some addr)) = .ok value)
    (htail : readBack s.mem (.list link) = .ok tail)
    (hslotmem : ∀ v ∈ slots, v ∈ s.slots)
    (hu : (c.state.mem.cells.map Cell.addr).Nodup)
    (hfresh : FreshBound c.state.mem)
    (hpaths : LivePaths c.state.mem)
    (hcell : ∀ d ∈ c.state.mem.cells,
      d = (⟨addr,item,link,1,.live⟩ : Cell) ∨ d ∈ s.mem.cells ∧ d.addr ≠ addr)
    (howners : ∀ a, ((Inspect.owners c.state).filter (fun r => r == some a)).length =
      ((Inspect.owners s).filter (fun r => r == some a)).length + if addr == a then 1 else 0)
    (hzero : ((Inspect.owners s).filter (fun r => r == some addr)).length = 0)
    (hreservations : ∀ a, a ≠ addr →
      (c.state.reservations.filter (fun r => r.addr == a)).length =
      (s.reservations.filter (fun r => r.addr == a)).length) :
    Inspect.invariant initial c.state = true := by
  have hobs := Preservation.transition_observer hr ht
  have huses := Preservation.transition_live hr ht
  have hids := Preservation.transition_identity_checks hr ht
  have ho := Preservation.transition_outside ht
  have hallocated := (ReservedReadiness.transition_resources
    (ReservedReadiness.reachable_invariant hr).1
    (ReservedReadiness.reachable_invariant hr).2.1 ht).1
  have hreadable : ∀ v, Inspect.readable s v = true → Inspect.readable c.state v = true := by
    intro v hv
    simp [Inspect.readable, hread _ _ (readable_readback hv)]
  simp only [Inspect.invariant,Bool.and_eq_true,beq_iff_eq,List.all_eq_true] at hi ⊢
  obtain ⟨⟨⟨⟨⟨⟨⟨hprot,_⟩,_⟩,_⟩,_⟩,hcells⟩,_⟩,hrecord⟩ := hi
  refine ⟨⟨⟨⟨⟨⟨⟨?_,hobs⟩,?_⟩,hids.1⟩,List.all_eq_true.mp hids.2⟩,?_⟩,?_⟩,
    Preservation.transition_record hrecord ht⟩
  · simp only [Inspect.protection,Bool.and_eq_true,beq_iff_eq,List.all_eq_true] at hprot ⊢
    obtain ⟨⟨⟨⟨hout,houtside⟩,hbs⟩,hss⟩,hes⟩ := hprot
    refine ⟨⟨⟨⟨by simpa [ho] using hout,?_⟩,?_⟩,?_⟩,?_⟩
    · intro a ha
      have hx := houtside a ha
      cases hinit : readBack initial.toMemory (.list a) <;>
        cases hsrc : readBack s.mem (.list a) <;> simp [hinit,hsrc] at hx
      rename_i x y
      simpa [hinit,hread _ _ hsrc] using hx
    · intro b hb
      have hx := hbs b (hbindings ▸ hb)
      refine ⟨⟨hx.1.1,Preservation.live_check huses b hb⟩,?_⟩
      simp only [Bool.or_eq_true] at hx ⊢
      exact hx.2.imp_right (hreadable _)
    · intro v hv
      rw [hslots] at hv
      rcases List.mem_cons.mp hv with rfl | hv
      · simp [Inspect.readable,hnewread]
      · exact hreadable v (hss v (hslotmem v hv))
    · intro d hd
      rcases hcell d hd with rfl | ⟨hd,hn⟩
      · simp [hedges,Inspect.readable,hread _ _ htail]
      · have hx := hes d hd
        rw [hedges,edge_lookup_other _ addr d.addr tail hn]
        cases hstatus : d.status with
        | setAside => simp
        | live =>
          cases he : s.edges.find? (fun q => q.1 == d.addr) with
          | none => simp [hstatus,he] at hx
          | some edge =>
            exact (by simpa [hstatus,he] using
              hreadable ⟨.list d.link,edge.2⟩ (by simpa [hstatus,he] using hx))
  · rw [PreservationRelease.nodup_eraseDups _ hu]
    simp
  · intro d hd
    refine ⟨⟨by simpa using hfresh d hd,?_⟩,?_⟩
    · rw [howners]
      rcases hcell d hd with rfl | ⟨hd,hn⟩
      · simp [hzero]
      · simpa [Ne.symm hn] using (hcells d hd).1.2
    · rcases hcell d hd with rfl | ⟨hdold,hn⟩
      · obtain ⟨cs,hp⟩ := hpaths _ hd rfl
        simp [hp.read _ hp.length_le,Except.isOk,Except.toBool]
      · have hx := (hcells d hdold).2
        cases hstatus : d.status with
        | setAside => simpa [hstatus,hreservations _ hn] using hx
        | live =>
          obtain ⟨cs,hp⟩ := hpaths d hd hstatus
          simp only [hstatus,reduceCtorEq,↓reduceIte,Bool.and_eq_true,Bool.or_eq_true] at hx ⊢
          refine ⟨by rw [hp.read _ hp.length_le]; rfl,?_⟩
          simpa [hs,htasks] using hx.2
  · intro r hrmem
    obtain ⟨d,hf,hl⟩ := hallocated r hrmem
    have ha : d.addr = r.addr := by simpa using List.find?_some hf
    exact List.any_eq_true.mpr ⟨d,List.mem_of_find?_eq_some hf,by simp [ha,hl]⟩

set_option maxHeartbeats 2000000 in
/-- Cons preserves the exact invariant for both fresh allocation and reserved
reuse, using only the actual source reachability and this successful step. -/
theorem cons_invariant (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok c)
    (hs : s.tasks = .primitive .cons ctx :: rest) :
    Inspect.invariant initial c.state = true := by
  have ht' := ht
  obtain ⟨hh,hpaths,hfresh⟩ := invariant_heap initial s hi
  have hslots := PreservationOwnership.source_slots hi
  simp only [Counted.transition,hs,bind,pure,Except.bind,Except.pure] at ht
  split at ht
  next b a slots hsl =>
    simp only [hsl,List.all_cons,Bool.and_eq_true] at hslots
    obtain ⟨hb,ha,hss⟩ := hslots
    cases hp : Plain.primitive .cons a.value b.value with
    | error err => simp [hp] at ht
    | ok value =>
      simp only [hp,beq_self_eq_true,↓reduceIte] at ht
      split at ht
      next item hra =>
        split at ht
        next link hrb =>
          have har : a.value = .num item := by
            have hx := readable_readback ha
            simpa [hra,readBack] using hx.symm
          have hbr := readable_readback hb
          rw [hrb] at hbr
          cases hlread : readList s.mem s.mem.cells.length link with
          | error err => simp [readBack,hlread] at hbr
          | ok items =>
            have hval : b.value = .list items := by
              simpa [readBack,hlread] using hbr.symm
            have hvalue : value = .list (item :: items) := by
              simpa [Plain.primitive,har,hval] using hp.symm
            obtain ⟨cs,hpath,hitems⟩ := path_of_read hlread
            let roots := slots.map (fun v => Inspect.link v.raw) ++ s.outside ++
              (s.bindings.filter (fun b => b.record.status == .holding)).map
                (fun b => Inspect.link b.record.value)
            have hroots : executionRoots s = link :: none :: roots := by
              simp [executionRoots,hsl,hra,hrb,Inspect.link,roots]
            have hnorm : ∀ addr, holders s.mem (executionRoots s) addr =
                holders s.mem (link :: roots) addr :=
              source_holders s b a slots hsl hra hrb
            have hheap : HeapSafe s.mem (link :: roots) := by
              refine ⟨hh.unique,?_,?_⟩
              · intro r hrmem
                apply hh.readable r
                rw [hroots]
                rcases List.mem_cons.mp hrmem with he | he
                · exact List.mem_cons.mpr (Or.inl he)
                · exact List.mem_cons.mpr (Or.inr (List.mem_cons.mpr (Or.inr he)))
              · intro d hd hl
                rw [← hnorm]
                exact hh.counts d hd hl
            have hslotmem : ∀ v ∈ slots, v ∈ s.slots := by
              intro v hv; simp [hsl,hv]
            split at ht
            next r hel =>
              obtain ⟨old,hf,hstatus⟩ := (ReservedReadiness.reachable_invariant hr).1 r
                (List.mem_of_find?_eq_some hel)
              have hz := no_holders_reserved s.mem (executionRoots s) hh hpaths r.addr old hf hstatus
              have hw : s.mem.writeInPlace r.addr item link = .ok
                  { s.mem.updateCell r.addr (fun _ => ⟨r.addr,item,link,1,.live⟩) with
                    record := s.mem.record ++ [.written r.addr] } := by
                simp [Memory.writeInPlace,hf,hstatus]
              simp only [hw] at ht
              cases ht
              have htarget := hheap.write r.addr item hw (by rw [← hnorm]; exact hz)
              apply build_invariant hr hi ht' hs rfl rfl rfl rfl
              · exact write_preserves_readback _ _ _ _ _ hw
              · simpa [hvalue,hitems] using write_in_place_read_back _ _ _ _ _ hw cs hpath
              · exact hbr
              · exact hslotmem
              · exact htarget.unique
              · exact hfresh.update r.addr _ (by intro d hd; exact hd.symm)
              · exact hpaths.write r.addr item link cs hpath hw
              · intro d hd
                obtain ⟨e,he,hde⟩ := List.mem_map.mp hd
                subst d
                split
                · exact Or.inl rfl
                · rename_i hn
                  exact Or.inr ⟨he,by simpa using hn⟩
              · intro addr
                rw [← executionRoots_holders,← executionRoots_holders,hnorm]
                simpa [executionRoots,Inspect.link,roots] using
                  write_holders s.mem _ roots r.addr item link hh.unique hw addr
              · rw [← executionRoots_holders]; exact hz
              · intro addr hn
                rw [reservation_filter_other _ r.addr addr hn]
            next hel =>
              simp only [Memory.create] at ht
              cases ht
              have hz := no_holders_missing s.mem (executionRoots s) hh hpaths s.mem.next hfresh.missing
              have htarget := hheap.create item hfresh.missing (by rw [← hnorm]; exact hz)
              apply build_invariant hr hi ht' hs rfl rfl rfl rfl
              · exact create_preserves_readback s.mem item link
              · simpa [hvalue,hitems,Memory.create] using create_read_back s.mem item link cs hpath hfresh.missing
              · exact hbr
              · exact hslotmem
              · exact htarget.unique
              · intro d hd
                rcases List.mem_append.mp hd with hd | hd
                · exact Nat.lt_trans (hfresh d hd) (Nat.lt_succ_self _)
                · simp only [List.mem_cons,List.not_mem_nil,or_false] at hd
                  subst d; exact Nat.lt_succ_self _
              · exact hpaths.create item link cs hpath hfresh.missing
              · intro d hd
                rcases List.mem_append.mp hd with hd | hd
                · exact Or.inr ⟨hd,Nat.ne_of_lt (hfresh d hd)⟩
                · exact Or.inl (by simpa using hd)
              · intro addr
                rw [← executionRoots_holders,← executionRoots_holders,hnorm]
                simpa [executionRoots,Inspect.link,roots,Memory.create] using
                  create_holders s.mem roots item link addr
              · rw [← executionRoots_holders]; exact hz
              · intro _ _; rfl
        next => cases ht
      next => cases ht
  next => cases ht

end Full.Proofs.PreservationCons
