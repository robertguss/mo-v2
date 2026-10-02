import Proofs.Environment

namespace Trial.Proofs

/-- The actual state after input records have been created, before dead-input
cleanup. Liveness is intentionally not asserted until that cleanup completes. -/
def inputState (s : Start) : RunState :=
  { mem := s.toMemory, log := [], bindings := inputBindings 0 s.inputs, scope := [], pending := [],
    outside := s.outside, setAside := [], nextBranch := 0, nextBinding := s.inputs.length, snaps := [] }

def inputEnv (s : Start) : Env :=
  ((inputBindings 0 s.inputs).map (fun b => (b.name, b.id))).reverse

/-- Initial proof meanings. The arbitrary value outside allocated binding ids
is never used: input_meanings_spec proves exact read-back on every existing id. -/
def inputMeanings (s : Start) : Meanings := fun id =>
  match (inputBindings 0 s.inputs).find? (fun b => b.id == id) with
  | none => (.num 0, .num 0)
  | some b => (b.value, match readBack s.toMemory b.value with | .ok v => v | .error _ => .num 0)

theorem input_ids_range (s : Start) :
    (inputBindings 0 s.inputs).map Binding.id = List.range s.inputs.length := by
  simp [input_binding_ids, List.range'_eq_map_range]

theorem input_meanings_spec (e : Expr) (s : Start) (h : validStart e s = .ok ())
    (b : Binding) (hb : b ∈ inputBindings 0 s.inputs) :
    b.value = (inputMeanings s b.id).1 ∧
      readBack s.toMemory b.value = .ok (inputMeanings s b.id).2 ∧
      b.value.kind = (inputMeanings s b.id).2.kind := by
  have hu : ((inputBindings 0 s.inputs).map Binding.id).Nodup := by
    rw [input_ids_range]; exact List.nodup_range
  have hf := binding_find_self _ hu b hb
  obtain ⟨v, hr, hk⟩ := valid_start_input e s h (b.name, b.value) (input_binding_source s.inputs 0 b hb)
  simp [inputMeanings, hf, hr, hk]

theorem input_binding_status (inputs : List (String × RawValue)) (next : Nat)
    (b : Binding) (hb : b ∈ inputBindings next inputs) :
    b.status = match b.value with | .list (some _) => .holding | _ => .noHolder := by
  induction inputs generalizing next with
  | nil => simp [inputBindings] at hb
  | cons p ps ih =>
    rcases p with ⟨name, value⟩
    rcases List.mem_cons.mp hb with he | hm
    · subst b; rfl
    · exact ih (next + 1) hm

theorem initialized_state (e : Expr) (s : Start) (hv : validStart e s = .ok ()) :
    StateInvariant s (inputMeanings s) [] (inputState s) := by
  have hlive : ∀ c ∈ s.toMemory.cells, c.status = .live := by
    intro c hc
    obtain ⟨d, _, he⟩ := List.mem_map.mp hc
    subst c
    rfl
  refine {
    owned := by simpa [Owned, ownedRoots, inputState] using valid_input_bindings_healthy e s hv
    ids := input_ids_range s
    raw := fun b hb => (input_meanings_spec e s hv b hb).1
    kinds := fun b hb => (input_meanings_spec e s hv b hb).2.2
    readable := fun b hb _ => (input_meanings_spec e s hv b hb).2.1
    holding := ?_
    pending := by simp [inputState]
    reserved := by simp [ReservedAllocated, inputState]
    tracked := ?_
    detached := ?_
    addresses := by simp [inputState]
    labels := by simp [inputState]
    ordered := by simp [inputState]
    branches := by simp
    branchBound := by simp
    outside := rfl
    outsideValues := fun _ _ => rfl
    history := by simp [inputState]
    historyBound := by simp [inputState]
    outsideHistory := by simp [inputState] }
  · intro b hb hs
    have ht := input_binding_status s.inputs 0 b hb
    rw [hs] at ht
    cases hvalue : b.value with
    | num n | bool n => simp [hvalue] at ht
    | list r =>
      cases r with
      | none => simp [hvalue] at ht
      | some a => exact ⟨a, rfl⟩
  · intro c hc hs
    simp [hlive c hc] at hs
  · intro c hc hs
    simp [hlive c hc] at hs

/-- The locked counted input loop reaches exactly inputState and inputEnv. -/
theorem input_loop_initial (s : Start) :
    (forIn s.inputs ([] : Env) (fun p env => do
      let status := match p.2 with | .list (some _) => .holding | _ => .noHolder
      let id ← newBinding p.1 p.2 status
      pure (ForInStep.yield ((p.1, id) :: env))) : M Env)
      { mem := s.toMemory, log := [], bindings := [], scope := [], pending := [],
        outside := s.outside, setAside := [], nextBranch := 0, nextBinding := 0, snaps := [] } =
      (.ok (inputEnv s), inputState s) := by
  have hm (v : RawValue) :
      input_binding_status.match_1 (fun _ => BStatus) v (fun _ => .holding) (fun _ => .noHolder) =
      inputBindings.match_1 (fun _ => BStatus) v (fun _ => .holding) (fun _ => .noHolder) := by
    cases v with
    | num _ | bool _ => rfl
    | list r => cases r <;> rfl
  simpa [hm, inputState, inputEnv] using
    input_binding_loop s.inputs
      { mem := s.toMemory, log := [], bindings := [], scope := [], pending := [],
        outside := s.outside, setAside := [], nextBranch := 0, nextBinding := 0, snaps := [] } []

/-- The reversed counted environment agrees with the original plain inputs
by lookup. No false equality of the two environment lists is needed. -/
theorem initialized_environment (e : Expr) (s : Start) (hv : validStart e s = .ok ())
    (plain : List (String × PlainValue)) (hp : startPlain s = .ok plain) :
    EnvMeaning (inputEnv s) plain (inputMeanings s) := by
  have hr := read_inputs_meanings s.inputs 0 s.toMemory (inputMeanings s)
    (fun b hb => (input_meanings_spec e s hv b hb).2.1)
  have hp' : plain = (inputBindings 0 s.inputs).map (fun b => (b.name, (inputMeanings s b.id).2)) :=
    Except.ok.inj (hp.symm.trans hr)
  let env := (inputBindings 0 s.inputs).map (fun b => (b.name, b.id))
  have hu : (env.map Prod.fst).Nodup := by
    simpa [env, List.map_map, Function.comp_def, input_binding_names] using valid_input_names e s hv
  intro x
  change lookupVal plain x = (env.reverse.find? (fun p => p.1 == x)).map (fun p => (inputMeanings s p.2).2)
  rw [find_reverse_names env hu x, hp']
  simpa [env, List.map_map, Function.comp_def] using lookup_meaning_env env (inputMeanings s) x

theorem initialized_frame (e : Expr) (s : Start) (hv : validStart e s = .ok ()) :
    FramesBound (inputState s) [{ text := e, env := toFEnv (inputEnv s) }] := by
  intro f hf x id hi
  have hf' := List.mem_singleton.mp hf
  subst f
  obtain ⟨p, hp, he⟩ := List.mem_map.mp hi
  have hid : p.2 = id := by simpa using congrArg Prod.snd he
  have hp' : p ∈ (inputBindings 0 s.inputs).map (fun b => (b.name, b.id)) := by
    simpa [inputEnv] using hp
  obtain ⟨b, hb, he⟩ := List.mem_map.mp hp'
  subst p
  rw [← hid]
  exact (initialized_state e s hv).bound b hb

end Trial.Proofs
