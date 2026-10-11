import Full.Proofs.PreservationOwnership

namespace Full.Proofs.PreservationRelease
open Counted Trial Trial.Proofs

/-- Count-only transfers preserve contents, not just the erased heap shape. -/
theorem count_transfer_invariant (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok c)
    (hm : c.state.mem = s.mem.updateCell addr (fun d => { d with count := n }))
    (hf : s.mem.find? addr = some cell) (hl : cell.status = .live)
    (he : c.state.edges = s.edges) (hres : c.state.reservations = s.reservations)
    (hbindings : ∀ b ∈ c.state.bindings,
      b.record.value.kind = b.value.kind ∧
      ((b.record.status != .holding && (Inspect.link b.record.value).isSome) ||
        Inspect.readable c.state ⟨b.record.value,b.value⟩) = true)
    (hslots : c.state.slots.all (Inspect.readable c.state) = true)
    (howners : ∀ a, ((Inspect.owners c.state).filter (fun r => r == some a)).length =
      if a = addr then n else ((Inspect.owners s).filter (fun r => r == some a)).length)
    (hfree : ∀ a, s.tasks.any (fun t => match t with | .free b => b == a | _ => false) = true →
      c.state.tasks.any (fun t => match t with | .free b => b == a | _ => false) = true)
    (hzero : n = 0 → c.state.tasks.any (fun t => match t with
      | .free b => b == addr | _ => false) = true) :
    Inspect.invariant initial c.state = true := by
  have hset : s.mem.setCount addr n = .ok c.state.mem := by
    simp [Memory.setCount, hf, hm]
  have hread := set_count_read_back s.mem c.state.mem addr n hset
  have hpaths := (invariant_heap initial s hi).2.1.set_count addr n hset
  have hca : cell.addr = addr := by simpa using List.find?_some hf
  have hunique := (invariant_heap initial s hi).1.unique
  have ho := Preservation.transition_outside ht
  have hobs := Preservation.transition_observer hr ht
  have huses := Preservation.transition_live hr ht
  simp only [Inspect.invariant, Bool.and_eq_true, beq_iff_eq, List.all_eq_true] at hi ⊢
  obtain ⟨⟨⟨⟨⟨⟨⟨hprot, _⟩, hu⟩, _⟩, _⟩, hcells⟩, hrs⟩, hrecord⟩ := hi
  refine ⟨⟨⟨⟨⟨⟨⟨?_, hobs⟩, ?_⟩, ?_⟩, ?_⟩, ?_⟩, ?_⟩,
    Preservation.transition_record hrecord ht⟩
  · simp only [Inspect.protection, Bool.and_eq_true, beq_iff_eq, List.all_eq_true] at hprot ⊢
    obtain ⟨⟨⟨⟨hout, houtside⟩, _⟩, _⟩, hedges⟩ := hprot
    refine ⟨⟨⟨⟨by simpa [ho] using hout, ?_⟩, ?_⟩,
      List.all_eq_true.mp hslots⟩, ?_⟩
    · simpa only [hread] using houtside
    · intro b hb
      exact ⟨⟨(hbindings b hb).1, Preservation.live_check huses b hb⟩,
        (hbindings b hb).2⟩
    · intro d hd
      rw [hm, update_count_eq_map] at hd
      obtain ⟨e, hem, rfl⟩ := List.mem_map.mp hd
      simpa [he, Inspect.readable, hread] using hedges e hem
  · simpa [hm, update_count_eq_map, List.map_map, Function.comp_def] using hu
  · exact (Preservation.transition_identity_checks hr ht).1
  · exact (Preservation.transition_identity_checks hr ht).2 |> List.all_eq_true.mp
  · intro d hd
    rw [hm, update_count_eq_map] at hd
    obtain ⟨e, hem, rfl⟩ := List.mem_map.mp hd
    have hx := hcells e hem
    dsimp only
    refine ⟨⟨by simpa [hm, Memory.updateCell] using hx.1.1, ?_⟩, ?_⟩
    · rw [howners]
      by_cases ha : e.addr = addr
      · simp [ha]
      · simpa [ha] using hx.1.2
    · cases hstatus : e.status with
      | setAside =>
        have hn : e.addr ≠ addr := by
          intro ha
          have hfound := find_of_mem s.mem hunique e hem
          rw [ha, hf] at hfound
          have ee := Option.some.inj hfound
          rw [ee, hstatus] at hl
          cases hl
        simpa [hstatus, hn, hres] using hx.2
      | live =>
        simp only [hstatus, reduceCtorEq, ↓reduceIte, Bool.and_eq_true,
          Bool.or_eq_true, bne_iff_ne]
        refine ⟨?_, ?_⟩
        · have hm' : ({ e with count := if e.addr == addr then n else e.count } : Cell)
              ∈ c.state.mem.cells := by
            rw [hm, update_count_eq_map]
            exact List.mem_map.mpr ⟨e,hem,rfl⟩
          obtain ⟨cs,hpath⟩ := hpaths _ hm' hstatus
          rw [hpath.read _ hpath.length_le]
          rfl
        · by_cases ha : e.addr = addr
          · by_cases hn : n = 0
            · apply Or.inr
              obtain ⟨t,htm,hq⟩ := List.any_eq_true.mp (hzero hn)
              apply List.any_eq_true.mpr
              refine ⟨t,htm,?_⟩
              cases t <;> simp_all
            · exact Or.inl (by simpa [ha] using hn)
          · have hz := hx.2
            simp only [hstatus, ↓reduceIte, Bool.and_eq_true, Bool.or_eq_true,
              bne_iff_ne, reduceCtorEq] at hz
            rcases hz.2 with hn | hq
            · exact Or.inl (by simpa [ha] using hn)
            · exact Or.inr (hfree e.addr hq)
  · intro r hr'
    obtain ⟨d, hd, ha⟩ := List.any_eq_true.mp (hrs r (hres ▸ hr'))
    apply List.any_eq_true.mpr
    refine ⟨{ d with count := if d.addr == addr then n else d.count }, ?_, ?_⟩
    · rw [hm, update_count_eq_map]
      exact List.mem_map.mpr ⟨d,hd,rfl⟩
    · exact ha

theorem count_links (m : Memory) (addr n : Nat) :
    (((m.updateCell addr (fun d => { d with count := n })).cells.filter
      (fun d => d.status == .live)).map Cell.link) =
    ((m.cells.filter (fun d => d.status == .live)).map Cell.link) := by
  rw [update_count_eq_map]
  simp [List.filter_map, List.map_map, Function.comp_def]

theorem source_count (hi : Inspect.invariant initial s = true)
    (hf : s.mem.find? addr = some cell) :
    cell.count = ((Inspect.owners s).filter (fun r => r == some addr)).length := by
  have hca : cell.addr = addr := by simpa using List.find?_some hf
  simp only [Inspect.invariant, Bool.and_eq_true, List.all_eq_true] at hi
  have hx := hi.1.1.2 cell (List.mem_of_find?_eq_some hf)
  simpa [hca] using hx.1.2

theorem givePending_invariant (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok c)
    (hs : s.tasks = .givePending :: rest) :
    Inspect.invariant initial c.state = true := by
  have ht' := ht
  have hslots := PreservationOwnership.source_slots hi
  have hbindings := PreservationOwnership.source_bindings hi
  simp only [Counted.transition, hs, bind, pure, Except.bind, Except.pure] at ht
  split at ht
  next v slots hsl =>
    split at ht
    next addr hv =>
      split at ht
      next cell hf =>
        split at ht
        next hbad => cases ht
        next hgood =>
          have hg : cell.status = .live ∧ cell.count ≠ 0 := by
            simpa only [Bool.or_eq_true, bne_iff_ne, beq_iff_eq, not_or,
              Decidable.not_not] using hgood
          have hcount := source_count hi hf
          simp only [Memory.setCount, hf, bind, pure, Except.bind, Except.pure] at ht
          cases ht
          have hset : s.mem.setCount addr (cell.count-1) =
              .ok (s.mem.updateCell addr (fun d => { d with count := cell.count-1 })) := by
            simp [Memory.setCount, hf]
          have hread := set_count_read_back _ _ _ _ hset
          apply count_transfer_invariant hr hi ht' rfl hf hg.1 rfl rfl
          · intro b hb
            simpa [Inspect.readable, hread] using hbindings b hb
          · simp only [hsl, List.all_cons, Bool.and_eq_true] at hslots
            simpa [Inspect.readable, hread] using hslots.2
          · intro a
            simp only [Inspect.owners, count_links, hsl, List.map_cons,
              List.filter_append, List.length_append] at hcount ⊢
            by_cases ha : a = addr
            · subst a
              rw [hcount]
              simp [Inspect.link, hv, Nat.add_assoc, Nat.add_comm, Nat.add_left_comm]
            · simp [Inspect.link, hv, Ne.symm ha, ha]
          · intro a hq
            simp only [hs, List.any_cons, Bool.false_or] at hq
            split <;> simp_all only [List.any_cons, Bool.or_eq_true, or_true]
          · intro hz
            have he : cell.count = 1 := by omega
            simp [he]
      next => cases ht
    next => cases ht
  next => cases ht

theorem nodup_eraseDups (xs : List Nat) (hn : xs.Nodup) : xs.eraseDups = xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    obtain ⟨hx,ht⟩ := List.nodup_cons.mp hn
    rw [List.eraseDups_cons]
    have hf : xs.filter (fun y => !y == x) = xs := by
      apply List.filter_eq_self.mpr
      intro y hy
      have hn : y ≠ x := by intro he; exact hx (he ▸ hy)
      simp [hn]
    rw [hf, ih ht]

/-- Reserved cells cannot occur in any successful read, including saved
non-owning values. The smaller post-release fuel still suffices for the path. -/
theorem reserved_readback (m : Memory) (addr : Nat) (cell : Cell)
    (hf : m.find? addr = some cell) (hl : cell.status = .setAside)
    (v : RawValue) (w : PlainValue) (hv : readBack m v = .ok w) :
    readBack { m with
      cells := m.cells.filter (fun d => d.addr != addr)
      record := m.record ++ [.released addr] } v = .ok w := by
  cases v with
  | num n => simpa [readBack] using hv
  | bool b => simpa [readBack] using hv
  | list r =>
    cases hr : readList m m.cells.length r with
    | error err => simp [readBack, hr] at hv
    | ok items =>
      have hw : w = .list items := by simpa [readBack, hr] using hv.symm
      subst w
      obtain ⟨cs,hp,he⟩ := path_of_read hr
      have hp' := hp.release addr (hp.avoids_set_aside addr cell hf hl)
      have hp'' : ListPath { m with
          cells := m.cells.filter (fun d => d.addr != addr)
          record := m.record ++ [.released addr] } r cs := by
        exact hp'.preserve (fun d hd => (hp'.lookup d hd).1)
      simpa [he] using hp''.read_back

theorem freeReserved_invariant (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok c)
    (hs : s.tasks = .freeReserved addr :: rest) :
    Inspect.invariant initial c.state = true := by
  have ht' := ht
  have hh := (invariant_heap initial s hi).1
  simp only [Counted.transition, hs, bind, pure, Except.bind, Except.pure] at ht
  split at ht
  next cell hf =>
    split at ht
    next hbad => cases ht
    next hgood =>
      have hg : cell.status = .setAside ∧ cell.count = 0 := by
        simpa only [Bool.or_eq_true, bne_iff_ne, not_or, Decidable.not_not] using hgood
      have hca : cell.addr = addr := by simpa using List.find?_some hf
      simp only [Memory.release, hf, bind, pure, Except.bind, Except.pure] at ht
      cases ht
      have hn : ∀ d ∈ s.mem.cells, d.addr = addr → d = cell := by
        intro d hd ha
        have hfd := find_of_mem s.mem hh.unique d hd
        rw [ha,hf] at hfd
        exact (Option.some.inj hfd).symm
      have hlinks : (s.mem.cells.filter (fun d => d.addr != addr) |>.filter
          (fun d => d.status == .live)).map Cell.link =
          (s.mem.cells.filter (fun d => d.status == .live)).map Cell.link := by
        congr 1
        rw [List.filter_filter]
        apply List.filter_congr
        intro d hd
        by_cases ha : d.addr = addr
        · have he := hn d hd ha
          simp [he, hca, hg.1]
        · simp [ha]
      have howners : Inspect.owners
          { s with
            mem := { s.mem with
              cells := s.mem.cells.filter (fun d => d.addr != addr)
              record := s.mem.record ++ [.released addr] }
            reservations := s.reservations.filter (fun r => r.addr != addr)
            tasks := rest, events := s.events ++ [.free addr] } = Inspect.owners s := by
        simp only [Inspect.owners, hlinks]
      have hread := reserved_readback s.mem addr cell hf hg.1
      have hreadable : ∀ v, Inspect.readable s v = true →
          Inspect.readable
            { s with mem := { s.mem with
                cells := s.mem.cells.filter (fun d => d.addr != addr)
                record := s.mem.record ++ [.released addr] } } v = true := by
        intro v hv
        cases hv' : readBack s.mem v.raw with
        | error err => simp [Inspect.readable,hv'] at hv
        | ok value =>
          simpa [Inspect.readable, hread _ _ hv'] using
            (show (value == v.value) = true from by simpa [Inspect.readable,hv'] using hv)
      have hobs := Preservation.transition_observer hr ht'
      have huses := Preservation.transition_live hr ht'
      have hids := Preservation.transition_identity_checks hr ht'
      simp only [Inspect.invariant, Bool.and_eq_true, beq_iff_eq, List.all_eq_true] at hi ⊢
      obtain ⟨⟨⟨⟨⟨⟨⟨hprot,_⟩,_⟩,_⟩,_⟩,hcells⟩,hrs⟩,hrecord⟩ := hi
      refine ⟨⟨⟨⟨⟨⟨⟨?_,hobs⟩,?_⟩,hids.1⟩,List.all_eq_true.mp hids.2⟩,?_⟩,?_⟩,
        Preservation.transition_record hrecord ht'⟩
      · simp only [Inspect.protection, Bool.and_eq_true, beq_iff_eq, List.all_eq_true] at hprot ⊢
        obtain ⟨⟨⟨⟨hout,houtside⟩,hbs⟩,hslots⟩,hedges⟩ := hprot
        refine ⟨⟨⟨⟨hout,?_⟩,?_⟩,?_⟩,?_⟩
        · intro a ha
          have hx := houtside a ha
          cases hinit : readBack initial.toMemory (.list a) <;>
            cases hsrc : readBack s.mem (.list a) <;>
            simp [hinit,hsrc] at hx
          rename_i x y
          simpa [hinit,hread _ _ hsrc] using hx
        · intro b hb
          have hx := hbs b hb
          refine ⟨⟨hx.1.1,Preservation.live_check huses b hb⟩,?_⟩
          have hx' := hx.2
          simp only [Bool.or_eq_true] at hx' ⊢
          rcases hx' with hn | hv
          · exact Or.inl hn
          · exact Or.inr (by simpa [Inspect.readable] using hreadable _ hv)
        · intro v hv; simpa [Inspect.readable] using hreadable v (hslots v hv)
        · intro d hd
          have hx := hedges d (List.mem_filter.mp hd).1
          cases hstatus : d.status with
          | setAside => simp [hstatus]
          | live =>
            cases he : s.edges.find? (fun e => e.1 == d.addr) with
            | none => simp [hstatus,he] at hx
            | some edge =>
              simpa [hstatus,he,Inspect.readable] using hreadable ⟨.list d.link,edge.2⟩
                (by simpa [hstatus,he] using hx)
      · have hu : ((s.mem.cells.filter (fun d => d.addr != addr)).map Cell.addr).Nodup :=
          List.Nodup.sublist (List.Sublist.map Cell.addr List.filter_sublist) hh.unique
        rw [nodup_eraseDups _ hu]
        simp
      · intro d hd
        obtain ⟨hd,hnaddr⟩ := List.mem_filter.mp hd
        have hda : d.addr ≠ addr := by simpa using hnaddr
        have hx := hcells d hd
        refine ⟨⟨hx.1.1,by simpa only [howners] using hx.1.2⟩,?_⟩
        cases hstatus : d.status with
        | setAside =>
          have hfilter : (s.reservations.filter (fun r => r.addr != addr) |>.filter
              (fun r => r.addr == d.addr)) = s.reservations.filter (fun r => r.addr == d.addr) := by
            rw [List.filter_filter]
            apply List.filter_congr
            intro r _
            by_cases ha : r.addr = d.addr <;> simp [ha,hda]
          simpa [hstatus,hfilter] using hx.2
        | live =>
          simp only [hstatus,reduceCtorEq,↓reduceIte,Bool.and_eq_true,Bool.or_eq_true] at hx ⊢
          refine ⟨?_,?_⟩
          · cases hp : readList s.mem s.mem.cells.length (some d.addr) with
            | error err => simp [hp,Except.isOk,Except.toBool] at hx
            | ok items =>
              have hback : readBack s.mem (.list (some d.addr)) = .ok (.list items) := by
                simp [readBack,hp]
              have hout := hread _ _ hback
              obtain ⟨cs,hpath,_⟩ := path_of_read_back _ _ _ hout
              rw [hpath.read _ hpath.length_le]
              rfl
          · simpa [hs] using hx.2.2
      · intro r hrmem
        obtain ⟨hrmem,hrne⟩ := List.mem_filter.mp hrmem
        obtain ⟨d,hd,hdr⟩ := List.any_eq_true.mp (hrs r hrmem)
        apply List.any_eq_true.mpr
        refine ⟨d, List.mem_filter.mpr ⟨hd,?_⟩,hdr⟩
        have ha : d.addr = r.addr := by
          simp only [Bool.and_eq_true,beq_iff_eq] at hdr
          exact hdr.1
        simpa [ha] using hrne
  next => cases ht

theorem zero_readable (hi : Inspect.invariant initial s = true)
    (hf : s.mem.find? addr = some cell) (hl : cell.status = .live) (hz : cell.count = 0)
    (v : Slot) (hv : Inspect.readable s v = true)
    (hn : Inspect.link v.raw ≠ some addr) :
    Inspect.readable { s with mem := { s.mem with
      cells := s.mem.cells.filter (fun d => d.addr != addr)
      record := s.mem.record ++ [.released addr] } } v = true := by
  have hh := (invariant_heap initial s hi).1
  have hca : cell.addr = addr := by simpa using List.find?_some hf
  have hcount : holders s.mem (executionRoots s) addr = 0 := by
    rw [← hca, ← hh.counts cell (List.mem_of_find?_eq_some hf) hl, hz]
  have hnlink := (holders_zero s.mem (executionRoots s) addr).mp hcount |>.2
  cases hraw : v.raw with
  | num n | bool b => simpa [Inspect.readable, hraw, readBack] using hv
  | list r =>
    cases hr : readList s.mem s.mem.cells.length r with
    | error err => simp [Inspect.readable,hraw,readBack,hr] at hv
    | ok items =>
      obtain ⟨cs,hpath,he⟩ := path_of_read hr
      have hn' : r ≠ some addr := by simpa [Inspect.link,hraw] using hn
      have hp := hpath.release addr (hpath.avoids addr hn' hnlink)
      have hp' : ListPath { s.mem with
          cells := s.mem.cells.filter (fun d => d.addr != addr)
          record := s.mem.record ++ [.released addr] } r cs :=
        hp.preserve (fun d hd => (hp.lookup d hd).1)
      simpa [Inspect.readable,hraw,hp'.read_back,he] using
        (show (.list items == v.value) = true from by
          simpa [Inspect.readable,hraw,readBack,hr] using hv)

theorem free_invariant (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok c)
    (hs : s.tasks = .free addr :: rest) :
    Inspect.invariant initial c.state = true := by
  have ht' := ht
  obtain ⟨hh,hpaths,hfresh⟩ := invariant_heap initial s hi
  simp only [Counted.transition, hs, bind, pure, Except.bind, Except.pure] at ht
  split at ht
  next cell hf =>
    split at ht
    next hbad => cases ht
    next hgood =>
      have hg : cell.status = .live ∧ cell.count = 0 := by
        simpa only [Bool.or_eq_true,bne_iff_ne,not_or,Decidable.not_not] using hgood
      split at ht
      next a tail he =>
        have hea : a = addr := by simpa using List.find?_some he
        subst a
        have hca : cell.addr = addr := by simpa using List.find?_some hf
        obtain ⟨change,hchange,hheap,hpaths',hfresh',hroots,htail⟩ :=
          free_preserves_heap p s addr cell tail rest hs hf hg.1 hg.2 he hh hpaths hfresh
        have hc : c = change := Except.ok.inj (ht'.symm.trans hchange)
        have hshape := free_transition p s addr cell tail rest hs hf hg.1 hg.2 he
        rw [hshape] at ht'
        cases ht'
        simp only [hshape,Except.ok.injEq] at hchange
        subst change
        have hcount : holders s.mem (executionRoots s) addr = 0 := by
          rw [← hca, ← hh.counts cell (List.mem_of_find?_eq_some hf) hg.1,hg.2]
        obtain ⟨hnroot,hnlink⟩ := (holders_zero s.mem (executionRoots s) addr).mp hcount
        have hread := zero_readable hi hf hg.1 hg.2
        have hobs := Preservation.transition_observer hr hshape
        have huses := Preservation.transition_live hr hshape
        have hids := Preservation.transition_identity_checks hr hshape
        have htailread : Inspect.readable s ⟨.list cell.link,tail⟩ = true := by
          obtain ⟨value,hvalue,hread⟩ := invariant_live_edge initial s hi cell
            (List.mem_of_find?_eq_some hf) hg.1
          rw [hca,he] at hvalue
          cases hvalue
          exact hread
        have howners : ∀ a, ((Inspect.owners
            { s with
              mem := { s.mem with
                cells := s.mem.cells.filter (fun d => d.addr != addr)
                record := s.mem.record ++ [.released addr] }
              edges := s.edges.filter (fun e => e.1 != addr)
              slots := if cell.link.isSome then ⟨.list cell.link,tail⟩ :: s.slots else s.slots
              releaseChain := if cell.link.isSome then s.releaseChain else []
              tasks := if cell.link.isSome then .givePending :: rest else rest
              events := s.events ++ [.free addr] }).filter (fun r => r == some a)).length =
            ((Inspect.owners s).filter (fun r => r == some a)).length := by
          intro a
          have hrel : s.mem.release addr = .ok { s.mem with
              cells := s.mem.cells.filter (fun d => d.addr != addr)
              record := s.mem.record ++ [.released addr] } := by simp [Memory.release,hf]
          have hx := release_holders s.mem _ addr cell hh.unique hf hg.1 hrel (executionRoots s) a
          rw [executionRoots_holders] at hx
          rw [← executionRoots_holders]
          cases hlink : cell.link with
          | none => simpa [executionRoots,hlink,holders,Inspect.link] using hx
          | some b => simpa [executionRoots,hlink,holders,Inspect.link] using hx
        simp only [Inspect.invariant,Bool.and_eq_true,beq_iff_eq,List.all_eq_true] at hi ⊢
        obtain ⟨⟨⟨⟨⟨⟨⟨hprot,_⟩,_⟩,_⟩,_⟩,hcells⟩,hrs⟩,hrecord⟩ := hi
        refine ⟨⟨⟨⟨⟨⟨⟨?_,hobs⟩,?_⟩,hids.1⟩,List.all_eq_true.mp hids.2⟩,?_⟩,?_⟩,
          Preservation.transition_record hrecord hshape⟩
        · simp only [Inspect.protection,Bool.and_eq_true,beq_iff_eq,List.all_eq_true] at hprot ⊢
          obtain ⟨⟨⟨⟨hout,houtside⟩,hbs⟩,hslots⟩,hedges⟩ := hprot
          refine ⟨⟨⟨⟨hout,?_⟩,?_⟩,?_⟩,?_⟩
          · intro a ha
            have hx := houtside a ha
            have heq := hroots a (by
              simp only [executionRoots,List.mem_append]
              exact Or.inl (Or.inr (hout ▸ ha)))
            simpa [heq] using hx
          · intro b hb
            have hx := hbs b hb
            refine ⟨⟨hx.1.1,Preservation.live_check huses b hb⟩,?_⟩
            have hx' := hx.2
            simp only [Bool.or_eq_true] at hx' ⊢
            by_cases hn : (b.record.status != .holding && (Inspect.link b.record.value).isSome) = true
            · exact Or.inl hn
            · apply Or.inr
              have hv := hx'.resolve_left hn
              have hne : Inspect.link b.record.value ≠ some addr := by
                intro heq
                cases hstatus : b.record.status with
                | holding =>
                  apply hnroot
                  simp only [executionRoots,List.mem_append]
                  apply Or.inr
                  exact List.mem_map.mpr ⟨b,List.mem_filter.mpr ⟨hb,by simp [hstatus]⟩,heq⟩
                | noHolder | movedOn | givenUp =>
                  have hn' : (b.record.status != .holding && (Inspect.link b.record.value).isSome) = true := by
                    simp [hstatus,heq]
                  exact hn hn'
              simpa [Inspect.readable] using hread _ hv hne
          · intro v hv
            cases hlink : cell.link with
            | none =>
              simp only [hlink,Option.isSome_none,Bool.false_eq_true,↓reduceIte] at hv
              simpa [Inspect.readable] using hread v (hslots v hv)
                (fun heq => hnroot (List.mem_append.mpr (Or.inl
                  (List.mem_append.mpr (Or.inl (List.mem_map.mpr ⟨v,hv,heq⟩))))))
            | some a =>
              simp only [hlink,Option.isSome_some,↓reduceIte,List.mem_cons] at hv
              rcases hv with rfl | hv
              · simpa [Inspect.readable,hlink] using hread _ htailread
                  (by simpa [Inspect.link] using hnlink cell (List.mem_of_find?_eq_some hf) hg.1)
              · simpa [Inspect.readable] using hread v (hslots v hv)
                  (fun heq => hnroot (List.mem_append.mpr (Or.inl
                    (List.mem_append.mpr (Or.inl (List.mem_map.mpr ⟨v,hv,heq⟩))))))
          · intro d hd
            obtain ⟨hd,hne⟩ := List.mem_filter.mp hd
            have hda : d.addr ≠ addr := by simpa using hne
            have hx := hedges d hd
            have hefind : (s.edges.filter (fun e => e.1 != addr)).find? (fun e => e.1 == d.addr) =
                s.edges.find? (fun e => e.1 == d.addr) := by
              simp only [List.find?_filter]
              congr 1
              funext e
              by_cases ha : e.1 = d.addr <;> simp [ha,hda]
            cases hstatus : d.status with
            | setAside => simp [hstatus]
            | live =>
              cases he' : s.edges.find? (fun e => e.1 == d.addr) with
              | none => simp [hstatus,he'] at hx
              | some edge =>
                simpa [hstatus,hefind,he',Inspect.readable] using hread ⟨.list d.link,edge.2⟩
                  (by simpa [hstatus,he'] using hx)
                  (by simpa [Inspect.link] using hnlink d hd hstatus)
        · rw [nodup_eraseDups _ hheap.unique]
          simp
        · intro d hd
          obtain ⟨hd,hne⟩ := List.mem_filter.mp hd
          have hda : d.addr ≠ addr := by simpa using hne
          have hx := hcells d hd
          refine ⟨⟨hx.1.1,by simpa only [howners] using hx.1.2⟩,?_⟩
          cases hstatus : d.status with
          | setAside => simpa [hstatus] using hx.2
          | live =>
            simp only [hstatus,reduceCtorEq,↓reduceIte,Bool.and_eq_true,Bool.or_eq_true] at hx ⊢
            obtain ⟨cs,hpath⟩ := hpaths' d (List.mem_filter.mpr ⟨hd,hne⟩) hstatus
            refine ⟨by rw [hpath.read _ hpath.length_le]; rfl,?_⟩
            rcases hx.2.2 with hn | hq
            · exact Or.inl hn
            · apply Or.inr
              simp only [hs,List.any_cons,show (addr == d.addr) = false from
                beq_eq_false_iff_ne.mpr (Ne.symm hda),Bool.false_or] at hq
              cases cell.link <;> simpa using hq
        · intro r hrmem
          obtain ⟨d,hd,hdr⟩ := List.any_eq_true.mp (hrs r hrmem)
          have hds : d.status = .setAside := by
            have hx := hdr
            simp only [Bool.and_eq_true,beq_iff_eq] at hx
            exact hx.2
          have hne : d.addr ≠ addr := by
            intro ha
            have hfd := find_of_mem s.mem hh.unique d hd
            rw [ha,hf] at hfd
            have heq := (Option.some.inj hfd).symm
            rw [heq,hg.1] at hds
            cases hds
          exact List.any_eq_true.mpr ⟨d,List.mem_filter.mpr ⟨hd,by simp [hne]⟩,hdr⟩
      next => cases ht
  next => cases ht

end Full.Proofs.PreservationRelease
