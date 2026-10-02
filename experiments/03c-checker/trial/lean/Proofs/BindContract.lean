import Proofs.IfContract

namespace Trial.Proofs

def resultStatus (r : RawValue) : BStatus :=
  match r with | .list (some _) => .holding | _ => .noHolder

def boundState (s : RunState) (name : String) (r : RawValue) (rest : List RawValue) : RunState :=
  { s with
    bindings := s.bindings ++ [{ id := s.nextBinding, name := name, value := r, status := resultStatus r }]
    pending := rest
    nextBinding := s.nextBinding + 1 }

def boundMeanings (g : Meanings) (id : Nat) (r : RawValue) (v : PlainValue) : Meanings :=
  fun j => if j = id then (r, v) else g j

theorem bound_meanings_extend (g : Meanings) (id : Nat) (r : RawValue) (v : PlainValue) :
    ExtendsMeanings g (boundMeanings g id r v) id := by
  intro j hj
  simp [boundMeanings, Nat.ne_of_lt hj]

theorem read_back_kind (m : Memory) (r : RawValue) (v : PlainValue)
    (hr : readBack m r = .ok v) : r.kind = v.kind := by
  cases r with
  | num n => simp [readBack] at hr; subst v; rfl
  | bool b => simp [readBack] at hr; subst v; rfl
  | list l =>
    cases hh : readList m m.cells.length l with
    | error why => simp [readBack, hh] at hr
    | ok items => simp [readBack, hh] at hr; subst v; rfl

/-- Creating the fresh binding and taking the pending result reaches the
exact state below, for scalar, empty, and nonempty list results alike. -/
theorem bind_result_run (s : RunState) (name : String) (r : RawValue) (rest : List RawValue)
    (hp : s.pending = pendingResult r rest) :
    (do
      let id ← newBinding name r (resultStatus r)
      popPending r
      pure id : M Nat) s = (.ok s.nextBinding, boundState s name r rest) := by
  cases r with
  | num _ | bool _ => simp [newBinding, popPending, resultStatus, boundState, hp, pendingResult]
  | list l => cases l <;> simp [newBinding, popPending, resultStatus, boundState, hp, pendingResult]

/-- A fresh binding extends immutable meanings without changing any previous
snapshot's meaning. Its result holder is transferred, not copied. -/
theorem bind_result_state {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (name : String) (r : RawValue) (v : PlainValue)
    (rest : List RawValue) (hp : s.pending = pendingResult r rest) (hr : readBack s.mem r = .ok v) :
    StateInvariant start (boundMeanings g s.nextBinding r v) enc (boundState s name r rest) := by
  have hold (b : Binding) (hb : b ∈ s.bindings) : b.id ≠ s.nextBinding := Nat.ne_of_lt (h.bound b hb)
  have hrest : ∀ v ∈ rest, v ∈ s.pending := by
    intro v hv
    cases r with
    | num _ | bool _ => simpa [hp, pendingResult] using hv
    | list l => cases l <;> simp [hp, pendingResult, hv]
  refine {
    owned := ?_
    ids := by simp [boundState, h.ids, List.range_succ]
    raw := ?_
    kinds := ?_
    readable := ?_
    holding := ?_
    pending := fun v hv => h.pending v (hrest v hv)
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
  · cases r with
    | num _ | bool _ => simpa [Owned, ownedRoots, bindingRoots, boundState, resultStatus, hp, pendingResult] using h.owned
    | list l => cases l <;>
        simpa [Owned, ownedRoots, bindingRoots, boundState, resultStatus, hp, pendingResult, valueRoot, List.append_assoc] using h.owned
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
    · simpa [boundMeanings, boundState, hold b hb] using h.readable b hb hread
    · have he := List.mem_singleton.mp hb
      subst b
      simpa [boundMeanings, boundState] using hr
  · intro b hb hs
    rcases List.mem_append.mp hb with hb | hb
    · exact h.holding b hb hs
    · have he := List.mem_singleton.mp hb
      subst b
      cases r with
      | num _ | bool _ => simp [resultStatus] at hs
      | list l => cases l with
        | none => simp [resultStatus] at hs
        | some a => exact ⟨a, rfl⟩
  · intro sn hsn b hb hs
    have hn : b.id ≠ s.nextBinding := Nat.ne_of_lt (h.historyBound sn hsn b hb)
    simpa [boundMeanings, hn] using h.history sn hsn b hb hs

theorem EnvMeaning.bind {env : Env} {plain : List (String × PlainValue)} {g : Meanings}
    (h : EnvMeaning env plain g) (name : String) (id : Nat) (r : RawValue) (v : PlainValue)
    (hi : ∀ p ∈ env, p.2 < id) :
    EnvMeaning ((name, id) :: env) ((name, v) :: plain) (boundMeanings g id r v) := by
  have he := h.extend (bound_meanings_extend g id r v) hi
  intro x
  by_cases hx : name = x
  · simp [lookupVal, hx, boundMeanings]
  · simpa [lookupVal, hx] using he x

/-- Older ids see the same shadowing as their future-name placeholder; the
fresh id itself cannot be mentioned by any already-existing future frame. -/
theorem bound_old_live (s : RunState) (env : Env) (body : Expr) (fs : List Frame) (name : String)
    (hl : LiveFor s.bindings ({ text := body, env := (name, none) :: toFEnv env } :: fs))
    (hb : ∀ b ∈ s.bindings, b.id < s.nextBinding) :
    LiveFor s.bindings ({ text := body, env := toFEnv ((name, s.nextBinding) :: env) } :: fs) := by
  intro b hmem hnonempty
  change b.status = .holding ↔
    (usesBinding body ((name, some s.nextBinding) :: toFEnv env) b.id || usedLater fs b.id) = true
  rw [uses_fresh_shadow body (toFEnv env) name s.nextBinding b.id (Nat.ne_of_gt (hb b hmem))]
  exact hl b hmem hnonempty

end Trial.Proofs
