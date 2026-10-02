import Proofs.Final

namespace Trial.Proofs

/-- The binding records created for inputs, in input order. This is proof data,
not an evaluator; the following theorem relates it to the actual stateful loop. -/
def inputBindings : Nat → List (String × RawValue) → List Binding
  | _, [] => []
  | next, (name, value) :: rest =>
    { id := next, name := name, value := value,
      status := match value with | .list (some _) => .holding | _ => .noHolder } ::
      inputBindings (next + 1) rest

/-- The actual input-binding loop succeeds, assigns consecutive fresh ids,
and places nearer bindings first in the evaluator environment. It does not
change memory, pending holders, the reserved stack, or snapshots. -/
theorem input_binding_loop (inputs : List (String × RawValue)) (s : RunState) (env : Env) :
    (forIn inputs env (fun p env => do
      let status := match p.2 with | .list (some _) => .holding | _ => .noHolder
      let id ← newBinding p.1 p.2 status
      pure (ForInStep.yield ((p.1, id) :: env))) : M Env) s =
      (.ok ((inputBindings s.nextBinding inputs).map (fun b => (b.name, b.id)) |>.reverse |>.append env),
        { s with
          bindings := s.bindings ++ inputBindings s.nextBinding inputs
          nextBinding := s.nextBinding + inputs.length }) := by
  induction inputs generalizing s env with
  | nil => simp [inputBindings]
  | cons p ps ih =>
    rcases p with ⟨name, value⟩
    let b : Binding := {
      id := s.nextBinding
      name := name
      value := value
      status := match value with | .list (some _) => .holding | _ => .noHolder }
    let u : RunState := { s with
      bindings := s.bindings ++ [b]
      nextBinding := s.nextBinding + 1 }
    simpa [List.forIn_cons, newBinding, inputBindings, u, b,
      List.append_assoc, Nat.add_assoc, Nat.add_comm, Nat.add_left_comm] using
      ih u ((name, s.nextBinding) :: env)

/-- The ghost input records use precisely the consecutive fresh ids. -/
theorem input_binding_ids (inputs : List (String × RawValue)) (next : Nat) :
    (inputBindings next inputs).map Binding.id = List.range' next inputs.length := by
  induction inputs generalizing next with
  | nil => simp [inputBindings]
  | cons p ps ih =>
    rcases p with ⟨name, value⟩
    simp [inputBindings, List.range'_succ, ih]

/-- Input bindings hold exactly the nonempty input roots. Empty input lists
are readable but own no cell. -/
theorem input_binding_roots (inputs : List (String × RawValue)) (next : Nat) :
    bindingRoots (inputBindings next inputs) =
      (inputs.filterMap (fun p => match p.2 with | .list r => some r | _ => none)).filter Option.isSome := by
  induction inputs generalizing next with
  | nil => rfl
  | cons p ps ih =>
    rcases p with ⟨name, value⟩
    cases value with
    | num n | bool n => simpa [inputBindings, bindingRoots] using ih (next + 1)
    | list r => cases r <;> simpa [inputBindings, bindingRoots, valueRoot] using ih (next + 1)

/-- After creating the input bindings, validated starting ownership agrees
with the evaluator's holder list, including empty input and outside lists. -/
theorem valid_input_bindings_healthy (e : Expr) (s : Start) (h : validStart e s = .ok ()) :
    Healthy s.toMemory (bindingRoots (inputBindings 0 s.inputs) ++ s.outside) := by
  have hh := valid_start_healthy e s h
  let rs := s.inputs.filterMap (fun p => match p.2 with | .list r => some r | _ => none)
  have hstart : startRoots s = rs ++ s.outside := by
    unfold startRoots
    apply congrArg (fun f : (String × RawValue) → Option (Option Addr) =>
      s.inputs.filterMap f ++ s.outside)
    funext p
    cases p.2 <;> rfl
  have hfilter : ∀ a, (rs.filter Option.isSome).filter (fun r => r == some a) =
      rs.filter (fun r => r == some a) := by
    intro a
    rw [List.filter_filter]
    apply List.filter_congr
    intro r _
    cases r <;> simp
  refine ⟨⟨hh.unique, ?_, ?_⟩, hh.closed, hh.positive, hh.fresh⟩
  · intro r hr
    apply hh.readable r
    rw [hstart]
    rw [input_binding_roots] at hr
    rcases List.mem_append.mp hr with hi | ho
    · exact List.mem_append_left _ (List.mem_filter.mp hi).1
    · exact List.mem_append_right _ ho
  · intro c hc hl
    have hn := hh.counts c hc hl
    rw [hstart] at hn
    simpa [holders, input_binding_roots, List.filter_append, rs, hfilter] using hn

end Trial.Proofs
