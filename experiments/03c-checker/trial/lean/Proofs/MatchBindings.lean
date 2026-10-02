import Proofs.MatchNil

namespace Trial.Proofs

/-- Match creates its head and tail records before deciding ownership. A
nonholding record extends meanings but contributes no holder to the heap. -/
theorem new_nonholder_state {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (name : String) (r : RawValue) (v : PlainValue)
    (hr : readBack s.mem r = .ok v) :
    StateInvariant start (boundMeanings g s.nextBinding r v) enc
      { s with bindings := s.bindings ++ [{ id := s.nextBinding, name := name, value := r, status := .noHolder }]
               nextBinding := s.nextBinding + 1 } := by
  have hold (b : Binding) (hb : b ∈ s.bindings) : b.id ≠ s.nextBinding := Nat.ne_of_lt (h.bound b hb)
  refine {
    owned := by simpa [Owned, ownedRoots, bindingRoots] using h.owned
    ids := by simp [h.ids, List.range_succ]
    raw := ?_
    kinds := ?_
    readable := ?_
    holding := ?_
    pending := h.pending
    reserved := h.reserved
    tracked := h.tracked
    detached := h.detached
    addresses := h.addresses
    labels := h.labels
    ordered := h.ordered
    branches := h.branches
    branchBound := h.branchBound
    outside := h.outside
    outsideValues := h.outsideValues
    history := ?_
    historyBound := fun sn hsn b hb => Nat.lt_succ_of_lt (h.historyBound sn hsn b hb)
    outsideHistory := h.outsideHistory }
  · intro b hb
    rcases List.mem_append.mp hb with hb | hb
    · simpa [boundMeanings, hold b hb] using h.raw b hb
    · have he := List.mem_singleton.mp hb
      subst b
      simp [boundMeanings]
  · intro b hb
    rcases List.mem_append.mp hb with hb | hb
    · simpa [boundMeanings, hold b hb] using h.kinds b hb
    · have he := List.mem_singleton.mp hb
      subst b
      simpa [boundMeanings] using read_back_kind s.mem r v hr
  · intro b hb hread
    rcases List.mem_append.mp hb with hb | hb
    · simpa [boundMeanings, hold b hb] using h.readable b hb hread
    · have he := List.mem_singleton.mp hb
      subst b
      simpa [boundMeanings] using hr
  · intro b hb hs
    rcases List.mem_append.mp hb with hb | hb
    · exact h.holding b hb hs
    · have he := List.mem_singleton.mp hb
      subst b
      contradiction
  · intro sn hsn b hb hs
    have hn : b.id ≠ s.nextBinding := Nat.ne_of_lt (h.historyBound sn hsn b hb)
    simpa [boundMeanings, hn] using h.history sn hsn b hb hs

def matchBindings (s : RunState) (headName tailName : String) (item : Int) (link : Option Addr) : RunState :=
  { s with
    bindings := s.bindings ++
      [{ id := s.nextBinding, name := headName, value := .num item, status := .noHolder },
       { id := s.nextBinding + 1, name := tailName, value := .list link, status := .noHolder }]
    nextBinding := s.nextBinding + 2 }

def matchMeanings (g : Meanings) (id : Nat) (item : Int) (link : Option Addr) (items : List Int) : Meanings :=
  boundMeanings (boundMeanings g id (.num item) (.num item)) (id + 1) (.list link) (.list items)

theorem match_bindings_run (s : RunState) (headName tailName : String) (item : Int) (link : Option Addr) :
    (do
      let hid ← newBinding headName (.num item) .noHolder
      let tid ← newBinding tailName (.list link) .noHolder
      pure (hid, tid) : M (Nat × Nat)) s =
      (.ok (s.nextBinding, s.nextBinding + 1), matchBindings s headName tailName item link) := by
  simp [newBinding, matchBindings, List.append_assoc]

theorem match_bindings_state {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (headName tailName : String) (item : Int) (link : Option Addr)
    (items : List Int) (hr : readBack s.mem (.list link) = .ok (.list items)) :
    StateInvariant start (matchMeanings g s.nextBinding item link items) enc
      (matchBindings s headName tailName item link) := by
  have hh := new_nonholder_state h headName (.num item) (.num item) rfl
  have ht := new_nonholder_state hh tailName (.list link) (.list items) hr
  simpa [matchBindings, matchMeanings, List.append_assoc] using ht

/-- Both new identifiers are genuinely fresh. Reusing either spelling only
shadows its old binding; old recorded meanings remain immutable. -/
theorem match_meanings_extend (g : Meanings) (id : Nat) (item : Int) (link : Option Addr) (items : List Int) :
    ExtendsMeanings g (matchMeanings g id item link items) id :=
  (bound_meanings_extend g id (.num item) (.num item)).trans
    (bound_meanings_extend _ (id + 1) (.list link) (.list items)) (Nat.le_succ _)

theorem EnvMeaning.match_bindings {env : Env} {plain : List (String × PlainValue)} {g : Meanings}
    (h : EnvMeaning env plain g) (headName tailName : String) (id : Nat) (item : Int)
    (link : Option Addr) (items : List Int) (hi : ∀ p ∈ env, p.2 < id) :
    EnvMeaning ((tailName, id + 1) :: (headName, id) :: env)
      ((tailName, .list items) :: (headName, .num item) :: plain)
      (matchMeanings g id item link items) := by
  apply (h.bind headName id (.num item) (.num item) hi).bind tailName (id + 1) (.list link) (.list items)
  intro p hp
  rcases List.mem_cons.mp hp with he | hm
  · subst p; exact Nat.lt_succ_self _
  · exact Nat.lt_succ_of_lt (hi p hm)

/-- Replacing the two match placeholders does not alter uses of old ids. -/
theorem match_old_uses (e : Expr) (env : Env) (headName tailName : String) (fresh id : Nat)
    (hi : id < fresh) :
    usesBinding e (toFEnv ((tailName, fresh + 1) :: (headName, fresh) :: env)) id =
      usesBinding e ((tailName, none) :: (headName, none) :: toFEnv env) id := by
  change usesBinding e ((tailName, some (fresh + 1)) :: (headName, some fresh) :: toFEnv env) id = _
  rw [uses_fresh_shadow e _ tailName (fresh + 1) id (Nat.ne_of_gt (Nat.lt_succ_of_lt hi))]
  apply uses_binding_congr
  apply lookup_cons_same
  intro x
  by_cases hx : headName = x <;> simp [lookupF, hx, Nat.ne_of_gt hi]

end Trial.Proofs
