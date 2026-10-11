import Full.Proofs.Preservation

namespace Full.Proofs.PreservationOwnership
open Counted

theorem source_slots (hi : Inspect.invariant initial s = true) :
    s.slots.all (Inspect.readable s) = true := by
  simp only [Inspect.invariant, Bool.and_eq_true] at hi
  have hp := hi.1.1.1.1.1.1.1
  simp only [Inspect.protection, Bool.and_eq_true] at hp
  exact hp.1.2

theorem chooseIf_invariant (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok c)
    (hs : s.tasks = .chooseIf yes no ctx :: rest) :
    Inspect.invariant initial c.state = true := by
  have hslots := source_slots hi
  have ht' := ht
  simp only [Counted.transition, hs, pure, Except.pure] at ht
  split at ht
  next v slots hsl =>
    split at ht
    next b hv =>
      cases ht
      apply Preservation.unchanged_heap_invariant hr hi ht' rfl rfl rfl rfl
      · simp only [hsl, List.all_cons, Bool.and_eq_true] at hslots
        simpa [Inspect.readable] using hslots.2
      · intro a
        simp [Inspect.owners, hsl, hv, Inspect.link]
      · intro a hf
        simp only [hs, List.any_cons, Bool.false_or] at hf
        simp [List.any_append, hf]
    next => cases ht
  next => cases ht

theorem chooseMatch_invariant (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok c)
    (hs : s.tasks = .chooseMatch empty head tail body ctx :: rest) :
    Inspect.invariant initial c.state = true := by
  have hslots := source_slots hi
  have ht' := ht
  simp only [Counted.transition, hs, pure, Except.pure] at ht
  split at ht
  next v slots hsl =>
    split at ht
    next l hv =>
      cases ht
      cases l <;>
        apply Preservation.unchanged_heap_invariant hr hi ht' rfl rfl rfl rfl
      · simp only [hsl, List.all_cons, Bool.and_eq_true] at hslots
        simpa [Inspect.readable] using hslots.2
      · intro a
        simp [Inspect.owners, hsl, hv, Inspect.link]
      · intro a hf
        simp only [hs, List.any_cons, Bool.false_or] at hf
        simp [List.any_append, hf]
      · simpa [Inspect.readable] using hslots
      · intro a; rfl
      · intro a hf
        simp only [hs, List.any_cons, Bool.false_or] at hf
        simp [List.any_append, hf]
    next => cases ht
  next => cases ht

theorem scalar_invariant (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok c)
    (hs : s.tasks = .primitive op ctx :: rest) (hop : op ≠ .cons) :
    Inspect.invariant initial c.state = true := by
  have hslots := source_slots hi
  have ht' := ht
  simp only [Counted.transition, hs, bind, pure, Except.bind, Except.pure] at ht
  split at ht
  next b a slots hsl =>
    simp only [hsl, List.all_cons, Bool.and_eq_true] at hslots
    obtain ⟨hb, ha, htail⟩ := hslots
    cases hp : Plain.primitive op a.value b.value with
    | error err => simp [hp] at ht
    | ok value =>
      simp only [hp] at ht
      simp only [show (op == Op.cons) = false from beq_eq_false_iff_ne.mpr hop,
        Bool.false_eq_true, ↓reduceIte] at ht
      split at ht
      next x hx =>
        split at ht
        next y hy =>
          have hav : a.value = .num x := by
            have h : (.num x : Value) = a.value := by
              simpa [Inspect.readable, hx, Trial.readBack, pure, Except.pure] using ha
            exact h.symm
          have hbv : b.value = .num y := by
            have h : (.num y : Value) = b.value := by
              simpa [Inspect.readable, hy, Trial.readBack, pure, Except.pure] using hb
            exact h.symm
          cases op <;> simp_all [Plain.primitive, pure, Except.pure]
          all_goals cases ht
          all_goals apply Preservation.unchanged_heap_invariant hr hi ht' rfl rfl rfl rfl
          all_goals first
            | solve | simpa [Inspect.readable, Trial.readBack, pure, Except.pure, ← hp] using htail
            | solve | intro addr; simp [Inspect.owners, hsl, hx, hy, Inspect.link]
            | solve | intro addr hf; simpa [hs] using hf
        next => cases ht
      next => cases ht
  next => cases ht

theorem transfer_heap_invariant (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok c)
    (hm : c.state.mem = s.mem) (he : c.state.edges = s.edges)
    (hres : c.state.reservations = s.reservations)
    (hbindings : ∀ b ∈ c.state.bindings,
      b.record.value.kind = b.value.kind ∧
      ((b.record.status != .holding && (Inspect.link b.record.value).isSome) ||
        Inspect.readable c.state ⟨b.record.value,b.value⟩) = true)
    (hslots : c.state.slots.all (Inspect.readable c.state) = true)
    (howners : ∀ a, ((Inspect.owners c.state).filter (fun r => r == some a)).length =
      ((Inspect.owners s).filter (fun r => r == some a)).length)
    (hfree : ∀ a, s.tasks.any (fun t => match t with | .free b => b == a | _ => false) = true →
      c.state.tasks.any (fun t => match t with | .free b => b == a | _ => false) = true) :
    Inspect.invariant initial c.state = true := by
  have ho := Preservation.transition_outside ht
  have hobs := Preservation.transition_observer hr ht
  have huses := Preservation.transition_live hr ht
  simp only [Inspect.invariant, Bool.and_eq_true, beq_iff_eq, List.all_eq_true] at hi ⊢
  obtain ⟨⟨⟨⟨⟨⟨⟨hprot, _⟩, hunique⟩, _⟩, _⟩, hcells⟩, hreserved⟩, hrecord⟩ := hi
  refine ⟨⟨⟨⟨⟨⟨⟨?_, hobs⟩, ?_⟩, ?_⟩, ?_⟩, ?_⟩, ?_⟩,
    Preservation.transition_record hrecord ht⟩
  · simp only [Inspect.protection, Bool.and_eq_true, beq_iff_eq, List.all_eq_true] at hprot ⊢
    obtain ⟨⟨⟨⟨hout, hread⟩, _⟩, _⟩, hedges⟩ := hprot
    refine ⟨⟨⟨⟨by simpa [ho] using hout, by simpa [hm] using hread⟩, ?_⟩,
      List.all_eq_true.mp hslots⟩,
      by simpa [hm, he, Inspect.readable] using hedges⟩
    intro b hmem
    have hx := hbindings b hmem
    exact ⟨⟨hx.1, Preservation.live_check huses b hmem⟩, hx.2⟩
  · simpa [hm] using hunique
  · exact (Preservation.transition_identity_checks hr ht).1
  · exact (Preservation.transition_identity_checks hr ht).2 |> List.all_eq_true.mp
  · intro d hd
    have hx := hcells d (hm ▸ hd)
    refine ⟨by simpa [hm, howners] using hx.1, ?_⟩
    split
    · rename_i hstatus
      simpa [hstatus, hres] using hx.2
    · rename_i hstatus
      have hh := hx.2
      simp only [hstatus, ↓reduceIte, Bool.and_eq_true] at hh
      rcases hh with ⟨hpath, hqueue⟩
      simp only [Bool.and_eq_true, Bool.or_eq_true] at hqueue ⊢
      refine ⟨by simpa [hm] using hpath, ?_⟩
      rcases hqueue with hn | hf
      · exact Or.inl hn
      · exact Or.inr (hfree d.addr hf)
  · simpa [hm, hres] using hreserved

theorem readable_kind (h : Inspect.readable s v = true) : v.raw.kind = v.value.kind := by
  cases hv : v.raw with
  | num n =>
    have he : (.num n : Value) = v.value := by
      simpa [Inspect.readable, hv, Trial.readBack, pure, Except.pure] using h
    rw [← he]; rfl
  | bool b =>
    have he : (.bool b : Value) = v.value := by
      simpa [Inspect.readable, hv, Trial.readBack, pure, Except.pure] using h
    rw [← he]; rfl
  | list l =>
    cases hl : Trial.readList s.mem s.mem.cells.length l with
    | error err => simp [Inspect.readable, hv, Trial.readBack, hl,
        bind, Except.bind] at h
    | ok xs =>
      have he : (.list xs : Value) = v.value := by
        simpa [Inspect.readable, hv, Trial.readBack, hl,
          bind, pure, Except.bind, Except.pure] using h
      rw [← he]; rfl

theorem source_bindings (hi : Inspect.invariant initial s = true) :
    ∀ b ∈ s.bindings, b.record.value.kind = b.value.kind ∧
      ((b.record.status != .holding && (Inspect.link b.record.value).isSome) ||
        Inspect.readable s ⟨b.record.value,b.value⟩) = true := by
  simp only [Inspect.invariant, Bool.and_eq_true] at hi
  have hp := hi.1.1.1.1.1.1.1
  simp only [Inspect.protection, Bool.and_eq_true, List.all_eq_true] at hp
  intro b hb
  have hx := hp.1.1.2 b hb
  exact ⟨by simpa using hx.1.1, hx.2⟩

/-- Scalar and empty-list acquisitions are filtered out as noHolder, but
contribute zero to every address count, just like their source slots. -/
theorem binding_owner (v : Slot) (id invocation : Nat) (name origin : String) (a : Nat) :
    ((([makeBinding id name v invocation origin].filter
      (fun b => b.record.status == .holding)).map (fun b => Inspect.link b.record.value)).filter
      (fun r => r == some a)).length =
    (([Inspect.link v.raw]).filter (fun r => r == some a)).length := by
  cases hv : v.raw with
  | num n => simp [makeBinding, hv, Inspect.link]
  | bool b => simp [makeBinding, hv, Inspect.link]
  | list l => cases l <;> simp [makeBinding, hv, Inspect.link]

theorem bind_invariant (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok c)
    (hs : s.tasks = .bind name body ctx :: rest) :
    Inspect.invariant initial c.state = true := by
  have hslots := source_slots hi
  have hbs := source_bindings hi
  have ht' := ht
  simp only [Counted.transition, hs, pure, Except.pure] at ht
  split at ht
  next v slots hsl =>
    cases ht
    simp only [hsl, List.all_cons, Bool.and_eq_true] at hslots
    obtain ⟨hv, htail⟩ := hslots
    apply transfer_heap_invariant hr hi ht' rfl rfl rfl
    · intro b hb
      simp only [List.mem_append, List.mem_singleton] at hb
      rcases hb with hb | rfl
      · simpa [Inspect.readable] using hbs b hb
      · refine ⟨by simpa [makeBinding] using readable_kind hv, ?_⟩
        have hread : Inspect.readable s
            ⟨(makeBinding s.nextBinding name v ctx.invocation s!"{ctx.site}/binding").record.value,
             (makeBinding s.nextBinding name v ctx.invocation s!"{ctx.site}/binding").value⟩ = true := by
          simpa [makeBinding] using hv
        simp [Inspect.readable] at hread ⊢
        exact Or.inr hread
    · simpa [Inspect.readable] using htail
    · intro a
      simp only [Inspect.owners, List.filter_append, List.map_append, List.length_append,
        hsl, List.map_cons]
      have ho := binding_owner v s.nextBinding ctx.invocation name s!"{ctx.site}/binding" a
      by_cases h : Inspect.link v.raw = some a
      all_goals simp [h] at ho ⊢
      all_goals omega
    · intro a hf
      simp only [hs, List.any_cons, Bool.false_or] at hf
      simp [List.any_append, hf]
  next => cases ht

theorem acquired_owners (xs : List α) (slot : α → Slot) (id : α → Nat)
    (name origin : α → String) (invocation a : Nat) :
    (((xs.map (fun q => makeBinding (id q) (name q) (slot q) invocation (origin q))).filter
      (fun b => b.record.status == .holding)).map (fun b => Inspect.link b.record.value) |>.filter
      (fun r => r == some a)).length =
    ((xs.map (fun q => Inspect.link (slot q).raw)).filter (fun r => r == some a)).length := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    change ((([makeBinding (id x) (name x) (slot x) invocation (origin x)] ++
      xs.map (fun q => makeBinding (id q) (name q) (slot q) invocation (origin q))).filter
      (fun b => b.record.status == .holding)).map (fun b => Inspect.link b.record.value) |>.filter
      (fun r => r == some a)).length =
      (([Inspect.link (slot x).raw] ++ xs.map (fun q => Inspect.link (slot q).raw)).filter
        (fun r => r == some a)).length
    simp only [List.filter_append, List.map_append, List.length_append]
    rw [ih, binding_owner]

/-- Transfer the reversed argument prefix to fresh parameter identities.
No uniqueness of parameter names is needed: accounting is by slots and IDs. -/
theorem enter_invariant (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok c)
    (hs : s.tasks = .enter name arity ctx :: rest) :
    Inspect.invariant initial c.state = true := by
  have hslots := source_slots hi
  have hbs := source_bindings hi
  have ht' := ht
  simp only [Counted.transition, hs, bind, pure, Except.bind, Except.pure] at ht
  split at ht
  next f hf =>
    split at ht
    next hbad => cases ht
    next hgood =>
      have hlen : ((s.slots.take arity).reverse).length = f.params.length := by
        simp only [Bool.or_eq_true, bne_iff_ne, not_or, Decidable.not_not] at hgood
        have hk := congrArg List.length hgood.2
        simpa using hk
      have hmap : (f.params.zip (s.slots.take arity).reverse).zipIdx.map
          (fun q => q.1.2) = (s.slots.take arity).reverse := by
        have hm := List.zipIdx_map_fst 0 (f.params.zip (s.slots.take arity).reverse)
        have he := congrArg (List.map Prod.snd) hm
        simp only [List.map_map, Function.comp_def] at he
        rw [he]
        exact List.map_snd_zip (by omega)
      cases ht
      apply transfer_heap_invariant hr hi ht' rfl rfl rfl
      · intro b hb
        simp only [List.mem_append] at hb
        rcases hb with hb | hb
        · simpa [Inspect.readable] using hbs b hb
        · obtain ⟨q,hq,rfl⟩ := List.mem_map.mp hb
          have hv : Inspect.readable s q.1.2 = true := by
            apply List.all_eq_true.mp hslots
            have hm : q.1.2 ∈ (s.slots.take arity).reverse := by
              rw [← hmap]
              exact List.mem_map.mpr ⟨q,hq,rfl⟩
            exact List.mem_of_mem_take (List.mem_reverse.mp hm)
          refine ⟨by simpa [makeBinding] using readable_kind hv, ?_⟩
          simp only [makeBinding, Inspect.readable] at hv ⊢
          simp only [Bool.or_eq_true]
          exact Or.inr hv
      · apply List.all_eq_true.mpr
        intro v hv
        simpa [Inspect.readable] using List.all_eq_true.mp hslots v (List.mem_of_mem_drop hv)
      · intro a
        have ho := acquired_owners
          (f.params.zip (s.slots.take arity).reverse).zipIdx
          (fun q => q.1.2) (fun q => s.nextBinding+q.2)
          (fun q => q.1.1.1) (fun q => s!"{name}/parameter/{q.1.1.1}") s.nextInvocation a
        have hlinks : ((f.params.zip (s.slots.take arity).reverse).zipIdx.map
          (fun q => Inspect.link q.1.2.raw)) =
            ((s.slots.take arity).reverse.map (fun v => Inspect.link v.raw)) := by
          simpa only [List.map_map, Function.comp_def] using
            congrArg (List.map (fun v => Inspect.link v.raw)) hmap
        rw [hlinks] at ho
        simp only [Inspect.owners, List.filter_append, List.map_append, List.length_append]
        rw [ho]
        have hsplit : s.slots = s.slots.take arity ++ s.slots.drop arity :=
          (List.take_append_drop arity s.slots).symm
        conv => rhs; rw [hsplit]
        simp [List.map_reverse, List.filter_reverse,
          Nat.add_assoc, Nat.add_comm, Nat.add_left_comm]
        have hc := congrArg (fun xs : List (Option Nat) =>
          (xs.filter (fun r => r == some a)).length)
          (List.take_append_drop arity (s.slots.map (fun v => Inspect.link v.raw)))
        simp only [List.filter_append, List.length_append] at hc
        omega
      · intro a hf
        simp only [hs, List.any_cons, Bool.false_or] at hf
        simp [List.any_append, hf]
  next => cases ht

end Full.Proofs.PreservationOwnership
