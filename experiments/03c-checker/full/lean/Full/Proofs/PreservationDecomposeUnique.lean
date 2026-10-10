import Full.Proofs.PreservationCells
import Full.Proofs.PreservationReleaseHeap
import Full.Proofs.ReservedReadiness
import Proofs.Reserve

namespace Full.Proofs.PreservationDecomposeUnique
open Counted Trial Trial.Proofs

theorem reserve_readable {s : State} (m : Memory) (addr : Nat) (v : Slot)
    (hv : readBack m v.raw = .ok v.value)
    (hn : Inspect.link v.raw ≠ some addr)
    (hlinks : ∀ d ∈ m.cells, d.status = .live → d.link ≠ some addr) :
    Inspect.readable { s with mem := (m.updateCell addr
      (fun d => { d with status := .setAside, count := 0, link := none })) } v = true := by
  cases hraw : v.raw with
  | num n | bool b => simpa [Inspect.readable,hraw,readBack] using hv
  | list r =>
    rw [hraw] at hv
    cases hr : readList m m.cells.length r with
    | error e => simp [readBack,hr] at hv
    | ok items =>
      have heq : v.value = .list items := by simpa [readBack,hr] using hv.symm
      obtain ⟨cs,hp,he⟩ := path_of_read hr
      have hp' := hp.update_other addr
        (fun d => { d with status := .setAside, count := 0, link := none })
        (by intro d _; rfl) (hp.avoids addr (by simpa [Inspect.link,hraw] using hn) hlinks)
      simp [Inspect.readable,hraw,heq,hp'.read_back,he]

theorem decompose_unique_invariant
    (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok change)
    (hs : s.tasks = .decompose head tail body bid ctx :: rest)
    (hslots : s.slots = v :: slots)
    (hv : v.raw = .list (some addr))
    (hvalue : v.value = .list (ph :: pt))
    (hf : s.mem.find? addr = some cell)
    (hc : cell.count = 1) :
    Inspect.invariant initial change.state = true := by
  have ht' := ht
  obtain ⟨hh,hpaths,hfresh⟩ := invariant_heap initial s hi
  obtain ⟨c,hfc,hl,_⟩ := Progress.root_ready hi (Progress.slot_root (by simp [hslots]) hv)
  rw [hf] at hfc
  cases hfc
  have hca : cell.addr = addr := by simpa using List.find?_some hf
  obtain ⟨hhead,htail⟩ := PreservationCells.decompose_readback hi (by simp [hslots]) hv hvalue hf
  let roots := slots.map (fun v => Inspect.link v.raw) ++ s.outside ++
    (s.bindings.filter (fun b => b.record.status == .holding)).map
      (fun b => Inspect.link b.record.value)
  have hroot : executionRoots s = some addr :: roots := by
    simp [executionRoots,hslots,hv,Inspect.link,roots]
  rw [hroot] at hh
  have hown : holders s.mem (some addr :: roots) addr = 1 := by
    simpa [hca,hc] using (hh.counts cell (List.mem_of_find?_eq_some hf) hl).symm
  obtain ⟨hnroot,hnlink⟩ := sole_holder s.mem roots addr hown
  have hm : s.mem.markSetAside addr = .ok (s.mem.updateCell addr
      (fun d => { d with status := .setAside, count := 0, link := none })) := by
    simp [Memory.markSetAside,hf]
  obtain ⟨cs,hpath,hitems⟩ := path_of_read_back _ _ _ htail
  obtain ⟨hh',htailpath,hreads⟩ := hh.reserve hf hl hc hm cs hpath
  have hpaths' := hpaths.reserve hh hf hl hc hm
  have hreserved := (ReservedReadiness.reachable_invariant hr).1
  have hrne : ∀ r ∈ s.reservations, r.addr ≠ addr := by
    exact fun r hr => ReservedReadiness.live_distinct hreserved hr hf hl
  have hread : ∀ w, Inspect.readable s w = true → Inspect.link w.raw ≠ some addr →
      Inspect.readable { s with mem := (s.mem.updateCell addr
        (fun d => { d with status := .setAside, count := 0, link := none })) } w = true := by
    intro w hw hn
    apply reserve_readable _ _ _ _ hn hnlink
    cases hb : readBack s.mem w.raw with
    | error e => simp [Inspect.readable,hb] at hw
    | ok value =>
      have he : value = w.value := by simpa [Inspect.readable,hb] using hw
      simpa [he] using hb
  simp only [Counted.transition,hs,hslots,hv,hvalue,hf,hl,hc,hm,
    bne_self_eq_false,beq_self_eq_true,Bool.false_or,Bool.true_or,
    Bool.false_eq_true,↓reduceIte,bind,pure,Except.bind,Except.pure] at ht
  cases ht
  have hobs := Preservation.transition_observer hr ht'
  have huses := Preservation.transition_live hr ht'
  have hids := Preservation.transition_identity_checks hr ht'
  have howners : ∀ a, ((Inspect.owners
      { s with
        mem := (s.mem.updateCell addr (fun d => { d with status := .setAside, count := 0, link := none }))
        slots := slots
        bindings := s.bindings ++
          [makeBinding s.nextBinding head ⟨.num cell.item,.num ph⟩ ctx.invocation s!"{ctx.site}/head",
           makeBinding (s.nextBinding+1) tail ⟨.list cell.link,.list pt⟩ ctx.invocation s!"{ctx.site}/tail" true] }).filter
        (fun r => r == some a)).length = holders
          (s.mem.updateCell addr (fun d => { d with status := .setAside, count := 0, link := none }))
          (cell.link :: roots) a := by
    intro a
    rw [← executionRoots_holders]
    cases cell.link <;>
      simp [executionRoots,roots,makeBinding,Inspect.link,holders,List.filter_append,
        List.map_append,List.filter_map,List.filter_cons,Function.comp_def,
        Nat.add_assoc,Nat.add_comm,Nat.add_left_comm]
    split <;> simp_all [List.length_append,List.length_map,
      Nat.add_assoc,Nat.add_comm,Nat.add_left_comm]
  simp only [Inspect.owners] at howners
  simp only [Inspect.invariant,Bool.and_eq_true,beq_iff_eq,List.all_eq_true] at hi ⊢
  obtain ⟨⟨⟨⟨⟨⟨⟨hprot,_⟩,_⟩,_⟩,_⟩,hcells⟩,hrs⟩,hrecord⟩ := hi
  refine ⟨⟨⟨⟨⟨⟨⟨?_,hobs⟩,?_⟩,hids.1⟩,List.all_eq_true.mp hids.2⟩,?_⟩,?_⟩,
    Preservation.transition_record hrecord ht'⟩
  · simp only [Inspect.protection,Bool.and_eq_true,beq_iff_eq,List.all_eq_true] at hprot ⊢
    obtain ⟨⟨⟨⟨hout,houtside⟩,hbs⟩,hss⟩,hedges⟩ := hprot
    refine ⟨⟨⟨⟨hout,?_⟩,?_⟩,?_⟩,?_⟩
    · intro a ha
      have he := hreads a (by simp [roots,hout,ha])
      simpa [he] using houtside a ha
    · intro b hb
      refine ⟨⟨?_,by simpa only [Bool.or_eq_true,Bool.and_eq_true,beq_iff_eq] using Preservation.live_check huses b hb⟩,?_⟩
      all_goals simp only [List.mem_append,List.mem_cons,List.not_mem_nil,or_false] at hb
      · rcases hb with hb | rfl | rfl
        · exact (hbs b hb).1.1
        · rfl
        · rfl
      · rcases hb with hb | rfl | rfl
        · have hx := (hbs b hb).2
          simp only [Bool.or_eq_true] at hx ⊢
          rcases hx with hn | hw
          · exact Or.inl hn
          · by_cases hh : b.record.status = .holding
            · exact Or.inr (by simpa [Inspect.readable] using (hread _ hw
                (fun he => hnroot (by
                  simp only [roots,List.mem_append]
                  exact Or.inr (List.mem_map.mpr ⟨b,List.mem_filter.mpr ⟨hb,by simp [hh]⟩,he⟩)))))
            · by_cases he : (Inspect.link b.record.value).isSome = true
              · exact Or.inl (by simp [hh,he])
              · exact Or.inr (by simpa [Inspect.readable] using (hread _ hw
                  (by intro hx; simp [hx] at he)))
        · simp [makeBinding,Inspect.readable,readBack,hhead]
        · have hb : Inspect.readable { s with mem := (s.mem.updateCell addr
              (fun d => { d with status := .setAside, count := 0, link := none })) }
              ⟨.list cell.link,.list pt⟩ = true := by
            simp [Inspect.readable,htailpath.read_back,hitems]
          simp only [Bool.or_eq_true]
          exact Or.inr (by simpa [makeBinding,Inspect.readable] using hb)
    · intro w hw
      apply (show Inspect.readable _ w = true from by
        simpa [Inspect.readable] using (hread w (hss w (by simp [hslots,hw]))
          (fun he => hnroot (by
            simp only [roots,List.mem_append]
            exact Or.inl (Or.inl (List.mem_map.mpr ⟨w,hw,he⟩))))))
    · intro d hd
      obtain ⟨e,he,rfl⟩ := List.mem_map.mp hd
      by_cases ha : e.addr = addr
      · simp [Memory.updateCell,ha]
      · have hx := hedges e he
        have hefind : (s.edges.filter (fun q => q.1 != addr)).find? (fun q => q.1 == e.addr) =
            s.edges.find? (fun q => q.1 == e.addr) := by
          rw [List.find?_filter]
          congr 1
          funext q
          by_cases hq : q.1 = e.addr <;> simp [hq,ha]
        cases hstatus : e.status with
        | setAside => simp [Memory.updateCell,ha,hstatus]
        | live =>
          cases hedge : s.edges.find? (fun q => q.1 == e.addr) with
          | none => simp [hstatus,hedge] at hx
          | some edge =>
            simpa [Memory.updateCell,ha,hstatus,hefind,hedge,Inspect.readable] using
              hread ⟨.list e.link,edge.2⟩ (by simpa [hstatus,hedge] using hx)
                (by simpa [Inspect.link] using hnlink e he hstatus)
  · rw [PreservationRelease.nodup_eraseDups _ hh'.unique]
    simp [Memory.updateCell]
  · intro d hd
    obtain ⟨e,he,rfl⟩ := List.mem_map.mp hd
    have hx := hcells e he
    by_cases ha : e.addr = addr
    · have heq : e = cell := by
        have hfind := find_of_mem s.mem hh.unique e he
        rw [ha,hf] at hfind
        exact (Option.some.inj hfind).symm
      subst e
      have hzero : holders (s.mem.updateCell addr
          (fun d => { d with status := .setAside, count := 0, link := none })) (cell.link :: roots) addr = 0 := by
        have hhld := reserve_holders s.mem _ roots addr cell hh.unique hf hl hm addr
        have hn : holders s.mem roots addr = 0 := by simpa [holders_cons] using hown
        exact hhld.trans hn
      have hfilter : s.reservations.filter (fun r => r.addr == addr) = [] := by
        apply List.filter_eq_nil_iff.mpr
        intro r hr
        simp [hrne r hr]
      simp only [hca,beq_self_eq_true,↓reduceIte,Inspect.owners,howners,hzero,
        List.filter_cons,hfilter,List.length_cons,List.length_nil,Option.isNone_none,
        and_true,Bool.and_true,Bool.true_and]
      simpa [hca,Memory.updateCell] using hx.1.1
    · dsimp only
      simp only [beq_eq_false_iff_ne.mpr ha,Bool.false_eq_true,↓reduceIte]
      refine ⟨⟨hx.1.1,?_⟩,?_⟩
      · cases hstatus : e.status with
        | live => simpa only [Inspect.owners,howners] using hh'.counts e (List.mem_map.mpr ⟨e,he,by simp [ha]⟩) hstatus
        | setAside =>
          simp only [Inspect.owners,howners]
          rw [reserve_holders s.mem _ roots addr cell hh.unique hf hl hm]
          have hcount := hx.1.2
          rw [← executionRoots_holders,hroot,holders_cons] at hcount
          simpa [Ne.symm ha] using hcount
      · cases hstatus : e.status with
        | setAside => simpa [hstatus,ha,Ne.symm ha,List.filter_cons] using hx.2
        | live =>
          simp only [hstatus,reduceCtorEq,↓reduceIte,Bool.and_eq_true,Bool.or_eq_true] at hx ⊢
          obtain ⟨ds,hp⟩ := hpaths' e (List.mem_map.mpr ⟨e,he,by simp [Memory.updateCell,ha]⟩) hstatus
          refine ⟨by rw [hp.read _ hp.length_le]; rfl,?_⟩
          rcases hx.2.2 with hn | hq
          · exact Or.inl hn
          · apply Or.inr
            simp only [hs,List.any_cons,Bool.false_or] at hq
            simp [List.any_append,hq]
  · intro r hrmem
    simp only [List.mem_cons] at hrmem
    rcases hrmem with rfl | hrmem
    · apply List.any_eq_true.mpr
      refine ⟨{ cell with status := .setAside, count := 0, link := none },?_,?_⟩
      · exact List.mem_map.mpr ⟨cell,List.mem_of_find?_eq_some hf,by simp [hca]⟩
      · simp [hca]
    · obtain ⟨d,hd,hdr⟩ := List.any_eq_true.mp (hrs r hrmem)
      apply List.any_eq_true.mpr
      refine ⟨d,List.mem_map.mpr ⟨d,hd,?_⟩,hdr⟩
      have hda : d.addr = r.addr := by
        simp only [Bool.and_eq_true,beq_iff_eq] at hdr
        exact hdr.1
      simp [Memory.updateCell,hda,hrne r hrmem]

end Full.Proofs.PreservationDecomposeUnique
