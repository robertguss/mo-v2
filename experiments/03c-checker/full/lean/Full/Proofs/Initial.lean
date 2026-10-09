import Full.Inspect
import Proofs.Initialization
import Proofs.Healthy

namespace Full.Proofs.Initial
open Counted

/-- Successful monadic input construction preserves the element relation. -/
theorem mapM_ok_mem {xs : List α} {ys : List β} {f : α → Except ε β}
    (h : xs.mapM f = .ok ys) : ∀ y ∈ ys, ∃ x ∈ xs, f x = .ok y := by
  induction xs generalizing ys with
  | nil => simp at h; subst ys; simp
  | cons x xs ih =>
    rw [List.mapM_cons] at h
    cases hx : f x with
    | error e => simp [hx] at h
    | ok y =>
      cases ht : xs.mapM f with
      | error e => simp [hx, ht] at h
      | ok zs =>
        have he : y :: zs = ys := by simpa [hx, ht] using h
        subst ys
        intro z hz
        rcases List.mem_cons.mp hz with rfl | hz
        · exact ⟨x, by simp, hx⟩
        · obtain ⟨a, ha, hf⟩ := ih ht z hz
          exact ⟨a, by simp [ha], hf⟩

theorem mapM_ok_map {xs : List α} {ys : List β} {f : α → Except ε β}
    (h : xs.mapM f = .ok ys) (g : α → γ) (k : β → γ)
    (hk : ∀ x y, f x = .ok y → g x = k y) : xs.map g = ys.map k := by
  induction xs generalizing ys with
  | nil => simp at h; subst ys; rfl
  | cons x xs ih =>
    rw [List.mapM_cons] at h
    cases hx : f x with
    | error e => simp [hx] at h
    | ok y =>
      cases ht : xs.mapM f with
      | error e => simp [hx, ht] at h
      | ok zs =>
        have he : y :: zs = ys := by simpa [hx, ht] using h
        subst ys
        simp only [List.map_cons]
        rw [hk x y hx, ih ht]

/-- The complete initialized state, retaining the actual read-back computations. -/
theorem begin_shape (p : Program) (initial : Trial.Start) (first : State)
    (h : Counted.begin p initial = .ok first) :
    Trial.validStart (.num 0) initial = .ok () ∧
    ∃ edges bindings,
      (initial.cells.mapM fun c => do
        pure (c.addr, ← Trial.readBack initial.toMemory (.list c.link))) = .ok edges ∧
      (initial.inputs.zipIdx.mapM fun ((name,raw),id) => do
        let value ← Trial.readBack initial.toMemory raw
        pure (makeBinding id name ⟨raw,value⟩ 0 s!"main/input/{name}")) = .ok bindings ∧
      first = {
        mem := initial.toMemory, outside := initial.outside, edges, bindings,
        nextBinding := bindings.length,
        entered := bindings.reverse.map (fun b => (b.record.name,b.record.id)),
        tasks := dead bindings (bindings.reverse.map (fun b => (b.record.name,b.record.id)))
          [.start,.eval p.main { env := bindings.reverse.map (fun b => (b.record.name,b.record.id)) },.finish] ++
          [.start,.eval p.main { env := bindings.reverse.map (fun b => (b.record.name,b.record.id)) },.finish] } := by
  unfold Counted.begin at h
  simp only [Trial.Proofs.except_bind_eq_ok] at h
  obtain ⟨_, _, _, hv, edges, he, bindings, hb, hs⟩ := h
  exact ⟨hv, edges, bindings, he, hb, (Except.ok.inj hs).symm⟩

theorem begin_valid_start (p : Program) (initial : Trial.Start) (first : State)
    (h : Counted.begin p initial = .ok first) :
    Trial.validStart (.num 0) initial = .ok () := (begin_shape p initial first h).1

theorem begin_memory (p : Program) (initial : Trial.Start) (first : State)
    (h : Counted.begin p initial = .ok first) :
    first.mem = initial.toMemory ∧ first.outside = initial.outside ∧
    first.slots = [] ∧ first.reservations = [] ∧ first.events = [] := by
  obtain ⟨_, _, _, _, _, rfl⟩ := begin_shape p initial first h
  exact ⟨rfl, rfl, rfl, rfl, rfl⟩

theorem input_binding_projection (initial : Trial.Start) (bindings : List Binding)
    (h : (initial.inputs.zipIdx.mapM fun ((name,raw),id) => do
      let value ← Trial.readBack initial.toMemory raw
      pure (makeBinding id name ⟨raw,value⟩ 0 s!"main/input/{name}")) = .ok bindings) :
    bindings.map (fun b => (b.record.name,b.record.id)) =
      initial.inputs.zipIdx.map (fun ((name,_),id) => (name,id)) ∧
    bindings.map (fun b => b.record.id) = List.range initial.inputs.length := by
  have hp (x : (String × Raw) × Nat) (b : Binding)
      (hx : (do
        let value ← Trial.readBack initial.toMemory x.1.2
        pure (makeBinding x.2 x.1.1 ⟨x.1.2,value⟩ 0 s!"main/input/{x.1.1}")) = .ok b) :
      b.record.name = x.1.1 ∧ b.record.id = x.2 := by
    simp only [Trial.Proofs.except_bind_eq_ok] at hx
    obtain ⟨v, _, hb⟩ := hx
    cases Except.ok.inj hb
    exact ⟨rfl, rfl⟩
  constructor
  · symm
    exact mapM_ok_map h (fun x => (x.1.1,x.2))
      (fun b => (b.record.name,b.record.id)) (fun x b hx => by
        obtain ⟨hn, hi⟩ := hp x b hx
        simp [hn, hi])
  · have hi := mapM_ok_map h Prod.snd (fun b => b.record.id)
      (fun x b hx => (hp x b hx).2.symm)
    rw [← hi]
    simp [List.range_eq_range']

theorem begin_scope_ids (p : Program) (initial : Trial.Start) (first : State)
    (h : Counted.begin p initial = .ok first) :
    first.entered = Inspect.initialScope initial ∧
    first.bindings.map (fun b => b.record.id) = List.range initial.inputs.length ∧
    first.nextBinding = initial.inputs.length := by
  obtain ⟨_, edges, bindings, _, hb, rfl⟩ := begin_shape p initial first h
  obtain ⟨hn, hi⟩ := input_binding_projection initial bindings hb
  refine ⟨?_, hi, ?_⟩
  · simpa [Inspect.initialScope, List.map_reverse] using congrArg List.reverse hn
  · have hl := congrArg List.length hi
    simpa using hl

theorem begin_binding_readable (p : Program) (initial : Trial.Start) (first : State)
    (h : Counted.begin p initial = .ok first) :
    ∀ b ∈ first.bindings,
      Trial.readBack first.mem b.record.value = .ok b.value ∧
      b.record.value.kind = b.value.kind ∧
      (Inspect.link b.record.value).isSome = (b.record.status == .holding) := by
  obtain ⟨hv, edges, bindings, _, hb, rfl⟩ := begin_shape p initial first h
  intro b hm
  obtain ⟨⟨⟨name,raw⟩,id⟩, hx, hr⟩ := mapM_ok_mem hb b hm
  simp only [Trial.Proofs.except_bind_eq_ok] at hr
  obtain ⟨v, hr, he⟩ := hr
  cases Except.ok.inj he
  have hm' : (name,raw) ∈ initial.inputs := List.fst_mem_of_mem_zipIdx hx
  obtain ⟨w, hw, hk⟩ := Trial.Proofs.valid_start_input (.num 0) initial hv (name,raw) hm'
  have hwv : w = v := Except.ok.inj (hw.symm.trans hr)
  subst w
  refine ⟨hr, hk.symm, ?_⟩
  cases raw with
  | num n | bool n => rfl
  | list a => cases a <;> rfl

theorem begin_heap (p : Program) (initial : Trial.Start) (first : State)
    (h : Counted.begin p initial = .ok first) :
    Trial.Proofs.Healthy first.mem (Trial.Proofs.startRoots initial) := by
  rw [(begin_memory p initial first h).1]
  exact Trial.Proofs.valid_start_healthy (.num 0) initial (begin_valid_start p initial first h)

theorem filterMap_of_mem (xs : List α) (f : α → Option β) (g : α → β)
    (h : ∀ x ∈ xs, f x = some (g x)) : xs.filterMap f = xs.map g := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    simp [h x (by simp), ih (fun y hy => h y (by simp [hy]))]

theorem begin_observer (p : Program) (initial : Trial.Start) (first : State)
    (h : Counted.begin p initial = .ok first) : Inspect.observer first = true := by
  have hids := (begin_scope_ids p initial first h).2.1
  obtain ⟨_, edges, bindings, _, _, rfl⟩ := begin_shape p initial first h
  let env := bindings.reverse.map (fun b => (b.record.name,b.record.id))
  have hen : ∀ b ∈ bindings, env.any (fun pair => pair.2 == b.record.id) = true := by
    intro b hb
    apply List.any_eq_true.mpr
    exact ⟨(b.record.name,b.record.id), List.mem_map.mpr ⟨b, by simpa using hb, rfl⟩, by simp⟩
  have hf : (bindings.filterMap fun b =>
      if env.any (fun pair => pair.2 == b.record.id) || b.record.status == .holding
      then some b.record else none) = bindings.map (fun b => b.record) := by
    apply filterMap_of_mem
    intro b hb
    simp [hen b hb]
  have hs : (bindings.map (fun b => b.record)).Pairwise (fun a b => decide (a.id ≤ b.id) = true) := by
    have hp : (bindings.map (fun b => b.record.id)).Pairwise (· ≤ ·) := by
      rw [hids]
      exact List.pairwise_le_range
    simpa [List.pairwise_map] using hp
  have hall : env.all (fun (name,id) =>
      bindings.any (fun b => b.record.id == id && b.record.name == name)) = true := by
    apply List.all_eq_true.mpr
    intro pair hm
    obtain ⟨b, hb, rfl⟩ := List.mem_map.mp hm
    apply List.any_eq_true.mpr
    exact ⟨b, by simpa using hb, by simp⟩
  simp only [Inspect.observer, Counted.visible]
  change (env.all (fun (name,id) => bindings.any (fun b =>
    b.record.id == id && b.record.name == name)) &&
    decide ((bindings.filterMap fun b =>
      if env.any (fun pair => pair.2 == b.record.id) || b.record.status == .holding
      then some b.record else none) =
      (bindings.filterMap fun b =>
      if env.any (fun pair => pair.2 == b.record.id) || b.record.status == .holding
      then some b.record else none).mergeSort (fun a b => a.id ≤ b.id))) = true
  rw [hall, hf, List.mergeSort_of_pairwise hs]
  simp

theorem eraseDups_of_nodup [BEq α] [LawfulBEq α] (xs : List α)
    (h : xs.Nodup) : xs.eraseDups = xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    obtain ⟨hx, ht⟩ := List.nodup_cons.mp h
    have hf : xs.filter (fun y => !y == x) = xs := by
      apply List.filter_eq_self.mpr
      intro y hy
      have hn : y ≠ x := fun he => hx (he ▸ hy)
      simp [hn]
    rw [List.eraseDups_cons, hf, ih ht]

theorem begin_identity_checks (p : Program) (initial : Trial.Start) (first : State)
    (h : Counted.begin p initial = .ok first) :
    (first.mem.cells.map (fun c => c.addr)).eraseDups.length = first.mem.cells.length ∧
    (first.bindings.map (fun b => b.record.id)).eraseDups.length = first.bindings.length ∧
    first.bindings.all (fun b => b.record.id < first.nextBinding) = true ∧
    Inspect.cellEffects first.events = first.mem.record := by
  have hv := begin_valid_start p initial first h
  obtain ⟨hm, _, _, _, he⟩ := begin_memory p initial first h
  obtain ⟨_, hi, hn⟩ := begin_scope_ids p initial first h
  refine ⟨?_, ?_, ?_, ?_⟩
  · have hu := Trial.Proofs.valid_start_unique (.num 0) initial hv
    rw [hm, eraseDups_of_nodup _ hu, List.length_map]
  · rw [hi, eraseDups_of_nodup _ List.nodup_range]
    have hl := congrArg List.length hi
    simpa using hl.symm
  · apply List.all_eq_true.mpr
    intro b hb
    have hib : b.record.id ∈ List.range initial.inputs.length := by
      rw [← hi]
      exact List.mem_map.mpr ⟨b, hb, rfl⟩
    simpa [hn] using List.mem_range.mp hib
  · simp [he, hm, Inspect.cellEffects, Trial.Start.toMemory]

/-- All input obligations in protection, including the holding/task-use clause. -/
theorem begin_binding_protection (p : Program) (initial : Trial.Start) (first : State)
    (h : Counted.begin p initial = .ok first) :
    first.bindings.all (fun b =>
      b.record.value.kind == b.value.kind &&
      (!(first.tasks.any (taskUses b.record.id)) ||
        (Inspect.link b.record.value).isNone || b.record.status == .holding) &&
      ((b.record.status != .holding && (Inspect.link b.record.value).isSome) ||
        Inspect.readable first ⟨b.record.value,b.value⟩)) = true := by
  apply List.all_eq_true.mpr
  intro b hb
  obtain ⟨hr, hk, hs⟩ := begin_binding_readable p initial first h b hb
  have hread : Inspect.readable first ⟨b.record.value,b.value⟩ = true := by
    simp [Inspect.readable, hr]
  have hhold : ((Inspect.link b.record.value).isNone || b.record.status == .holding) = true := by
    rw [← hs]
    cases Inspect.link b.record.value <;> rfl
  simp only [hk, beq_self_eq_true, Bool.true_and, hread, Bool.or_true, Bool.and_true]
  cases ht : first.tasks.any (taskUses b.record.id) <;> simp_all

theorem begin_outside_protection (p : Program) (initial : Trial.Start) (first : State)
    (h : Counted.begin p initial = .ok first) :
    (first.outside == initial.outside) = true ∧
    initial.outside.all (fun a =>
      match Trial.readBack initial.toMemory (.list a), Trial.readBack first.mem (.list a) with
      | .ok x,.ok y => x == y | _,_ => false) = true := by
  obtain ⟨hm, ho, _, _, _⟩ := begin_memory p initial first h
  refine ⟨by simp [ho], ?_⟩
  rw [hm]
  apply List.all_eq_true.mpr
  intro a ha
  obtain ⟨cs, hp⟩ := (begin_heap p initial first h).readable a
    (List.mem_append_right _ ha)
  rw [hm] at hp
  simp [hp.read_back]

theorem find_key_self (xs : List α) (key : α → Nat) (hu : (xs.map key).Nodup)
    (x : α) (hx : x ∈ xs) : xs.find? (fun y => key y == key x) = some x := by
  induction xs with
  | nil => simp at hx
  | cons y ys ih =>
    obtain ⟨hn, ht⟩ := List.nodup_cons.mp hu
    rcases List.mem_cons.mp hx with rfl | hx
    · simp
    · have hne : key y ≠ key x := fun he =>
        hn (List.mem_map.mpr ⟨x, hx, he.symm⟩)
      simp [hne, ih ht hx]

theorem begin_edge_protection (p : Program) (initial : Trial.Start) (first : State)
    (h : Counted.begin p initial = .ok first) :
    first.mem.cells.all (fun c => c.status != .live ||
      match first.edges.find? (fun e => e.1 == c.addr) with
      | some (_,v) => Inspect.readable first ⟨.list c.link,v⟩ | none => false) = true := by
  obtain ⟨hv, edges, bindings, he, _, rfl⟩ := begin_shape p initial first h
  have hkeys : edges.map Prod.fst = initial.cells.map Trial.StartCell.addr := by
    symm
    apply mapM_ok_map he
    intro c e hr
    simp only [Trial.Proofs.except_bind_eq_ok] at hr
    obtain ⟨v, _, hr⟩ := hr
    cases Except.ok.inj hr
    rfl
  have hu := Trial.Proofs.valid_start_unique (.num 0) initial hv
  apply List.all_eq_true.mpr
  intro c hc
  obtain ⟨d, hd, hdc⟩ := List.mem_map.mp hc
  have haddr : d.addr = c.addr := congrArg Trial.Cell.addr hdc
  have hm : c.addr ∈ edges.map Prod.fst := by
    rw [hkeys]
    exact List.mem_map.mpr ⟨d, hd, haddr⟩
  cases hf : edges.find? (fun e => e.1 == c.addr) with
  | none =>
    have hn := List.find?_eq_none.mp hf
    obtain ⟨e, hem, hea⟩ := List.mem_map.mp hm
    have hh := hn e hem
    simp [hea] at hh
  | some e =>
    have hem := List.mem_of_find?_eq_some hf
    have hea : e.1 = c.addr := by simpa using List.find?_some hf
    obtain ⟨a, ha, hr⟩ := mapM_ok_mem he e hem
    simp only [Trial.Proofs.except_bind_eq_ok] at hr
    obtain ⟨v, hr, hev⟩ := hr
    have hev' := Except.ok.inj hev
    subst e
    let ac : Trial.Cell := ⟨a.addr,a.item,a.link,a.count,.live⟩
    have hac : ac ∈ initial.toMemory.cells := List.mem_map.mpr ⟨a, ha, rfl⟩
    have hfc := find_key_self initial.toMemory.cells Trial.Cell.addr hu c hc
    have hfa := find_key_self initial.toMemory.cells Trial.Cell.addr hu ac hac
    have hacaddr : ac.addr = c.addr := hea
    rw [hacaddr] at hfa
    have heq : ac = c := Option.some.inj (hfa.symm.trans hfc)
    have hlink : a.link = c.link := congrArg Trial.Cell.link heq
    simp [Inspect.readable, ← hlink, hr]

theorem begin_protection (p : Program) (initial : Trial.Start) (first : State)
    (h : Counted.begin p initial = .ok first) : Inspect.protection initial first = true := by
  obtain ⟨ho, hr⟩ := begin_outside_protection p initial first h
  have hb := begin_binding_protection p initial first h
  have he := begin_edge_protection p initial first h
  have hs := (begin_memory p initial first h).2.2.1
  unfold Inspect.protection
  simp only [Bool.and_eq_true]
  refine ⟨⟨⟨⟨ho, ?_⟩, hb⟩, by simp [hs]⟩, ?_⟩
  · apply List.all_eq_true.mpr
    intro a ha
    have hh := List.all_eq_true.mp hr a ha
    cases h₁ : Trial.readBack initial.toMemory (.list a) <;>
      cases h₂ : Trial.readBack first.mem (.list a) <;>
      simp only [h₁, h₂] at hh <;> exact hh
  · apply List.all_eq_true.mpr
    intro c hc
    have hh := List.all_eq_true.mp he c hc
    cases hf : first.edges.find? (fun e => e.1 == c.addr) with
    | none => simpa only [hf] using hh
    | some e => cases e; simpa only [hf] using hh

theorem input_records_zip (xs : List (String × Raw)) (next : Nat) :
    (xs.zipIdx next).map (fun ((name,raw),id) =>
      (makeBinding id name ⟨raw,.num 0⟩ 0 s!"main/input/{name}").record) =
    Trial.Proofs.inputBindings next xs := by
  induction xs generalizing next with
  | nil => rfl
  | cons x xs ih =>
    rcases x with ⟨name,raw⟩
    simp only [List.zipIdx_cons, List.map_cons, Trial.Proofs.inputBindings]
    rw [ih]
    cases raw with
    | num n | bool n => rfl
    | list a => cases a <;> rfl

theorem begin_records (p : Program) (initial : Trial.Start) (first : State)
    (h : Counted.begin p initial = .ok first) :
    first.bindings.map (fun b => b.record) = Trial.Proofs.inputBindings 0 initial.inputs := by
  obtain ⟨_, _, bindings, _, hb, rfl⟩ := begin_shape p initial first h
  rw [← input_records_zip initial.inputs 0]
  symm
  apply mapM_ok_map hb
  intro x b hx
  rcases x with ⟨⟨name,raw⟩,id⟩
  simp only [Trial.Proofs.except_bind_eq_ok] at hx
  obtain ⟨v, _, he⟩ := hx
  cases Except.ok.inj he
  rfl

theorem full_binding_roots (bs : List Binding) :
    (bs.filter (fun b => b.record.status == .holding)).map (fun b => Inspect.link b.record.value) =
      Trial.Proofs.bindingRoots (bs.map (fun b => b.record)) := by
  induction bs with
  | nil => rfl
  | cons b bs ih =>
    simp only [Trial.Proofs.bindingRoots] at ih
    simp only [List.filter_cons, List.map_cons, Trial.Proofs.bindingRoots, List.filterMap_cons]
    cases b.record.status == .holding <;> simp [ih]
    rfl

theorem begin_owner_counts (p : Program) (initial : Trial.Start) (first : State)
    (h : Counted.begin p initial = .ok first) :
    ∀ c ∈ first.mem.cells,
      c.count = ((Inspect.owners first).filter (fun a => a == some c.addr)).length := by
  obtain ⟨hm, ho, hs, _, _⟩ := begin_memory p initial first h
  have hr := begin_records p initial first h
  have hh := Trial.Proofs.valid_input_bindings_healthy (.num 0) initial
    (begin_valid_start p initial first h)
  intro c hc
  have hl : c.status = .live := by
    rw [hm] at hc
    obtain ⟨d, _, rfl⟩ := List.mem_map.mp hc
    rfl
  rw [hm] at hc
  have hcount := hh.counts c hc hl
  rw [← hr, ← full_binding_roots first.bindings, ← hm, ← ho] at hcount
  simpa [Trial.holders, Inspect.owners, hs, List.filter_append, List.filter_map,
    List.filter_filter, Function.comp_def, Bool.and_comm, Nat.add_comm, Nat.add_left_comm,
    Nat.add_assoc] using hcount

theorem begin_cell_checks (p : Program) (initial : Trial.Start) (first : State)
    (h : Counted.begin p initial = .ok first) :
    first.mem.cells.all (fun c => c.addr < first.mem.next &&
      c.count == ((Inspect.owners first).filter (fun a => a == some c.addr)).length &&
      (if c.status == .setAside then
        c.count == 0 && c.link.isNone && (first.reservations.filter (fun r => r.addr == c.addr)).length == 1
      else
        (Trial.readList first.mem first.mem.cells.length (some c.addr)).isOk &&
        (c.count != 0 || first.tasks.any (fun t => match t with | .free a => a == c.addr | _ => false)))) = true := by
  have hh := begin_heap p initial first h
  apply List.all_eq_true.mpr
  intro c hc
  have hl : c.status = .live := by
    rw [(begin_memory p initial first h).1] at hc
    obtain ⟨d, _, rfl⟩ := List.mem_map.mp hc
    rfl
  have hf := hh.fresh c hc
  have hn := hh.positive c hc hl
  have hz : c.count ≠ 0 := by omega
  have hcount := begin_owner_counts p initial first h c hc
  obtain ⟨cs, hp⟩ := hh.closed c hc hl
  have hread := hp.read first.mem.cells.length hp.length_le
  have hne : (c.count != 0) = true := by simp [hz]
  rw [hne]
  simp [hl, hf, hcount, hread, Except.isOk]
  rfl

/-- Concrete initialized-state obligation of F1, with the frozen full observer,
edge representation and ghost bindings (not the Trial observer). -/
theorem initialized_invariant (p : Program) (initial : Trial.Start) (first : State)
    (h : Counted.begin p initial = .ok first) : Inspect.invariant initial first = true := by
  have hp := begin_protection p initial first h
  have ho := begin_observer p initial first h
  obtain ⟨ha, hb, hi, he⟩ := begin_identity_checks p initial first h
  have hr := (begin_memory p initial first h).2.2.2.1
  unfold Inspect.invariant
  rw [hp, ho, ha, hb, hi, hr, he]
  simp only [beq_self_eq_true, Bool.true_and, Bool.and_true, List.all_nil]
  have hh := begin_heap p initial first h
  apply List.all_eq_true.mpr
  intro c hc
  have hl : c.status = .live := by
    rw [(begin_memory p initial first h).1] at hc
    obtain ⟨d, _, rfl⟩ := List.mem_map.mp hc
    rfl
  have hf := hh.fresh c hc
  have hn := hh.positive c hc hl
  have hz : c.count ≠ 0 := by omega
  have hcount := begin_owner_counts p initial first h c hc
  obtain ⟨cs, hpath⟩ := hh.closed c hc hl
  have hread := hpath.read first.mem.cells.length hpath.length_le
  have hne : (c.count != 0) = true := by simp [hz]
  rw [hne]
  simp [hl, hf, hcount, hread, Except.isOk]
  rfl

end Full.Proofs.Initial
