import Proofs.Initialization

namespace Trial.Proofs

theorem cell_find_self (cs : List Cell) (hu : (cs.map Cell.addr).Nodup)
    (c : Cell) (hc : c ∈ cs) : cs.find? (fun d => d.addr == c.addr) = some c := by
  induction cs with
  | nil => simp at hc
  | cons d ds ih =>
    have hn := List.nodup_cons.mp hu
    rcases List.mem_cons.mp hc with he | hm
    · subst c; simp
    · have hne : d.addr ≠ c.addr := by
        intro he
        exact hn.1 (List.mem_map.mpr ⟨c, hm, he.symm⟩)
      simp [hne, ih hn.2 hm]

/-- Copying a variable's holder changes its count, adds the result holder,
and preserves every part of the evaluator boundary invariant. -/
theorem StateInvariant.copy_holder {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (a : Addr) (c : Cell)
    (hf : s.mem.find? a = some c) (hl : c.status = .live) :
    StateInvariant start g enc { s with
      mem := s.mem.updateCell a (fun d => { d with count := c.count + 1 })
      pending := .list (some a) :: s.pending } := by
  let m := s.mem.updateCell a (fun d => { d with count := c.count + 1 })
  have hm : s.mem.setCount a (c.count + 1) = .ok m := by simp [Memory.setCount, hf, m]
  have hr := set_count_read_back s.mem m a _ hm
  have hne : ∀ d ∈ s.mem.cells, d.status = .setAside → d.addr ≠ a := by
    intro d hd hs he
    have hd' : s.mem.find? a = some d := by
      simpa [Memory.find?, he] using cell_find_self s.mem.cells h.owned.unique d hd
    have heq := Option.some.inj (hf.symm.trans hd')
    subst d
    simp [hl] at hs
  have hres : ∀ d, d.status = .setAside → (d ∈ m.cells ↔ d ∈ s.mem.cells) := by
    intro d hs
    constructor
    · intro hd
      obtain ⟨q, hq, he⟩ := List.mem_map.mp hd
      by_cases hqa : q.addr = a
      · have hqs : q.status = .setAside := by simpa [hqa, ← he] using hs
        exact False.elim (hne q hq hqs hqa)
      · have he' : q = d := by simpa [hqa] using he
        exact he' ▸ hq
    · intro hd
      exact List.mem_map.mpr ⟨d, hd, by simp [hne d hd hs]⟩
  refine { h with
    owned := owned_push { s with mem := m } a (h.owned.add_count hf hl hm)
    readable := fun b hb hp => (hr b.value).trans (h.readable b hb hp)
    pending := ?_
    reserved := ?_
    tracked := fun d hd hs => h.tracked d ((hres d hs).mp hd) hs
    detached := fun d hd hs => h.detached d ((hres d hs).mp hd) hs
    outsideValues := fun r hr' => (hr (.list r)).trans (h.outsideValues r hr') }
  · intro v hv
    rcases List.mem_cons.mp hv with he | ht
    · subst v; exact ⟨a, rfl⟩
    · exact h.pending v ht
  · intro p hp
    obtain ⟨d, hd, hs⟩ := h.reserved p hp
    have ha : d.addr = p.2 := by simpa using List.find?_some hd
    refine ⟨d, ?_, hs⟩
    change m.find? p.2 = some d
    rw [find_update_other s.mem a p.2 _ (by intro _ _; rfl)
      (by simpa [ha] using hne d (List.mem_of_find?_eq_some hd) hs)]
    exact hd

/-- Last use moves the holder from its binding to the one pending result.
Dead bindings retain raw identity, but need no readable-list obligation. -/
theorem StateInvariant.move_holder {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (id : Nat) (b : Binding) (a : Addr)
    (hf : s.bindings.find? (fun d => d.id == id) = some b)
    (hs : b.status = .holding) (hv : b.value = .list (some a)) :
    StateInvariant start g enc { s with
      bindings := s.bindings.map (fun d => if d.id == id then { d with status := .movedOn } else d)
      pending := .list (some a) :: s.pending } := by
  refine { h with
    owned := owned_move s id b a h.owned h.unique hf hs hv
    ids := by rw [status_update_ids]; exact h.ids
    raw := ?_
    kinds := ?_
    readable := ?_
    holding := ?_
    pending := ?_ }
  · intro d hd
    obtain ⟨q, hq, rfl⟩ := List.mem_map.mp hd
    by_cases he : q.id = id <;> simpa [he] using h.raw q hq
  · intro d hd
    obtain ⟨q, hq, rfl⟩ := List.mem_map.mp hd
    by_cases he : q.id = id <;> simpa [he] using h.kinds q hq
  · intro d hd hdread
    obtain ⟨q, hq, rfl⟩ := List.mem_map.mp hd
    by_cases he : q.id = id
    · have hn : valueRoot q.value = none := by simpa [he] using hdread
      simpa [he] using h.readable q hq (Or.inr hn)
    · simpa [he] using h.readable q hq (by simpa [he] using hdread)
  · intro d hd hdhold
    obtain ⟨q, hq, rfl⟩ := List.mem_map.mp hd
    by_cases he : q.id = id
    · simp [he] at hdhold
    · simpa [he] using h.holding q hq (by simpa [he] using hdhold)
  · intro v hv'
    rcases List.mem_cons.mp hv' with he | ht
    · subst v; exact ⟨a, rfl⟩
    · exact h.pending v ht

/-- Variable lookup, including copy and last-use move, satisfies the entire
induction contract rather than only the local memory-ownership obligation. -/
theorem variable_contract (x : String) : EvalContract (.var x) := by
  intro start g env plain fs enc k s h hl hf henv ht
  cases he : env.find? (fun p => p.1 == x) with
  | none =>
    have hm : lookupVal plain x = none := by simpa [he] using henv x
    simp [check, lookup_kind, hm] at ht
  | some p =>
    rcases p with ⟨y, id⟩
    have hy : y = x := by simpa using List.find?_some he
    subst y
    have hm : lookupVal plain x = some (g id).2 := by simpa [he] using henv x
    have hk : (g id).2.kind = k := by simpa [check, lookup_kind, hm] using ht
    have hi : id ∈ s.bindings.map Binding.id := by
      rw [h.ids]
      exact List.mem_range.mpr (hf.env (x, id) (List.mem_of_find?_eq_some he))
    obtain ⟨b, hbfind⟩ := find_binding_id s.bindings id hi
    have hb : b ∈ s.bindings := List.mem_of_find?_eq_some hbfind
    have hbid : b.id = id := by simpa using List.find?_some hbfind
    have hmeaning : eval plain (.var x) = .ok (g id).2 := by simp [eval, hm]
    have hu (j : Nat) : usesBinding (.var x) (toFEnv env) j = (id == j) := by
      simp [usesBinding, lookup_frame_env, he]
    by_cases hv : ∃ a, b.value = .list (some a)
    · obtain ⟨a, ha⟩ := hv
      have hbhold : b.status = .holding := (hl b hb ⟨a, ha⟩).mpr (by
        simp [used_later_cons, hu, hbid])
      have hread : readBack s.mem b.value = .ok (g id).2 := by
        simpa [hbid] using h.readable b hb (Or.inl hbhold)
      by_cases hlater : usedLater fs id = true
      · have hroot : some a ∈ ownedRoots s := by
          simpa [ha, valueRoot] using holding_root_mem s b hb hbhold
        obtain ⟨cs, hp⟩ := h.owned.readable (some a) hroot
        obtain ⟨c, ds, _, hc, _, hcLive, _⟩ := hp.head
        let m := s.mem.updateCell a (fun d => { d with count := c.count + 1 })
        let u : RunState := { s with
          mem := m
          pending := .list (some a) :: s.pending
          scope := env.reverse.map Prod.snd }
        let t := (snapshot .newHolder none u).2
        have hcRun : addHolder a s = (.ok (), { s with mem := m }) := by
          simp [addHolder, getLiveCell, getCell, memOp, Memory.setCount, hc, hcLive, m]
        have hvAll := set_count_read_back s.mem m a (c.count + 1)
          (by simp [Memory.setCount, hc, m])
        have htInv : StateInvariant start g enc t :=
          ((h.copy_holder a c hc hcLive).scope (env.reverse.map Prod.snd)).snapshot .newHolder none
        refine ⟨t, g, b.value, (g id).2, {
          run := by simp [evalC, he, getBinding, hbfind, hbhold, ha, hlater, hcRun,
            pushPending, enter, snapshot, t, u]
          meaning := hmeaning
          kind := hk
          read := (hvAll b.value).trans hread
          state := htInv
          live := ?_
          frames := hf.tail
          bindingsGrow := Nat.le_refl _
          branchesGrow := Nat.le_refl _
          meanings := fun _ _ => rfl
          pending := by
            change t.pending = match b.value with | .list (some _) => b.value :: s.pending | _ => s.pending
            simp [t, u, snapshot, ha]
          saved := fun v _ => hvAll v
          reservations := ⟨[], by simp [t, u, snapshot]⟩
          snapshots := snapshot_prefix u .newHolder none }⟩
        apply hl.congr
        intro j
        by_cases hj : id = j
        · subst j; simp [used_later_cons, hu, hlater]
        · simp [used_later_cons, hu, hj]
      · let u : RunState := { s with
          bindings := s.bindings.map (fun d => if d.id == id then { d with status := .movedOn } else d)
          pending := .list (some a) :: s.pending
          scope := env.reverse.map Prod.snd }
        let t := (snapshot .holderMoved none u).2
        have htInv : StateInvariant start g enc t :=
          ((h.move_holder id b a hbfind hbhold ha).scope (env.reverse.map Prod.snd)).snapshot .holderMoved none
        refine ⟨t, g, b.value, (g id).2, {
          run := by simp [evalC, he, getBinding, hbfind, hbhold, ha, hlater,
            setBindingStatus, pushPending, enter, snapshot, t, u]
          meaning := hmeaning
          kind := hk
          read := hread
          state := htInv
          live := ?_
          frames := hf.tail
          bindingsGrow := Nat.le_refl _
          branchesGrow := Nat.le_refl _
          meanings := fun _ _ => rfl
          pending := by
            change t.pending = match b.value with | .list (some _) => b.value :: s.pending | _ => s.pending
            simp [t, u, snapshot, ha]
          saved := fun _ _ => rfl
          reservations := ⟨[], by simp [t, u, snapshot]⟩
          snapshots := snapshot_prefix u .holderMoved none }⟩
        intro d hd hdnonempty
        obtain ⟨q, hq, rfl⟩ := List.mem_map.mp hd
        by_cases hj : q.id = id
        · simp [hj, hlater]
        · have hqn : ∃ a, q.value = .list (some a) := by simpa [hj] using hdnonempty
          simpa [hj, used_later_cons, hu, Ne.symm hj] using hl q hq hqn
    · have hn : ∀ a, b.value ≠ .list (some a) := by simpa using hv
      have hnone : valueRoot b.value = none := by
        cases ha : b.value with
        | num _ | bool _ => rfl
        | list r => cases r with
          | none => rfl
          | some a => exact False.elim (hn a ha)
      have hread : readBack s.mem b.value = .ok (g id).2 := by
        simpa [hbid] using h.readable b hb (Or.inr hnone)
      refine ⟨s, g, b.value, (g id).2, {
        run := variable_no_holder s env fs enc x id b he hbfind hn
        meaning := hmeaning
        kind := hk
        read := hread
        state := h
        live := ?_
        frames := hf.tail
        bindingsGrow := Nat.le_refl _
        branchesGrow := Nat.le_refl _
        meanings := fun _ _ => rfl
        pending := ?_
        saved := fun _ _ => rfl
        reservations := ⟨[], by simp⟩
        snapshots := ⟨[], by simp⟩ }⟩
      · intro d hd hdnonempty
        have hdi : id ≠ d.id := by
          intro hdi
          have hdf : s.bindings.find? (fun q => q.id == id) = some d := by
            simpa [hdi] using binding_find_self s.bindings h.unique d hd
          have hbd := Option.some.inj (hbfind.symm.trans hdf)
          subst d
          exact hv hdnonempty
        simpa [used_later_cons, hu, hdi] using hl d hd hdnonempty
      · change s.pending = match b.value with | .list (some _) => b.value :: s.pending | _ => s.pending
        cases ha : b.value with
        | num _ | bool _ => rfl
        | list r => cases r with
          | none => rfl
          | some a => exact False.elim (hn a ha)

end Trial.Proofs
