import Full.Statements
import Full.Proofs.Initial
import Full.Proofs.Control

namespace Full.Proofs.SimulationInitial
open Counted

/-- Ghost lookup recovers each input binding, independently of its holder status. -/
theorem input_lookup (p : Program) (initial : Trial.Start) (first : State)
    (h : Counted.begin p initial = .ok first) (b : Binding) (hb : b ∈ first.bindings) :
    first.bindings.find? (fun c => c.record.id == b.record.id) = some b := by
  apply Initial.find_key_self first.bindings (fun c => c.record.id)
  · rw [(Initial.begin_scope_ids p initial first h).2.1]
    exact List.nodup_range
  · exact hb

theorem mapM_map_ok (xs : List α) (f : α → β) (g : β → Except ε γ)
    (k : α → γ) (h : ∀ x ∈ xs, g (f x) = .ok (k x)) :
    (xs.map f).mapM g = .ok (xs.map k) := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    simp [h x (by simp), ih (fun y hy => h y (by simp [hy]))]

/-- The initialized ghost environment is exactly the reversed immutable inputs. -/
theorem input_environment (p : Program) (initial : Trial.Start) (first : State)
    (h : Counted.begin p initial = .ok first) :
    Control.env first first.entered =
      .ok (first.bindings.reverse.map (fun b => (b.record.name,b.value))) := by
  have hen : first.entered = first.bindings.reverse.map
      (fun b => (b.record.name,b.record.id)) := by
    obtain ⟨_, _, _, _, _, rfl⟩ := Initial.begin_shape p initial first h
    rfl
  rw [hen]
  unfold Control.env
  apply mapM_map_ok
  intro b hb
  simp [input_lookup p initial first h b (by simpa using hb)]

/-- Any finite prefix consisting only of initial binding releases is erased. -/
theorem focus_giveBinding_prefix (s : State) (ids : List Nat)
    (tasks : List Task) (values : List Slot) (n : Nat) :
    Control.focus s (ids.length + n) (ids.map Task.giveBinding ++ tasks) values =
      Control.focus s n tasks values := by
  induction ids with
  | nil => simp
  | cons id ids ih =>
    simpa [Nat.add_assoc, Nat.add_comm, Nat.add_left_comm, Control.focus] using ih

theorem mapM_transfer {xs : List α} {ys : List β} {f : α → Except ε β}
    (h : xs.mapM f = .ok ys) (g : α → Except ε γ) (k : β → γ)
    (hk : ∀ x y, f x = .ok y → g x = .ok (k y)) :
    xs.mapM g = .ok (ys.map k) := by
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
        simp [hk x y hx, ih ht]

theorem input_values (p : Program) (initial : Trial.Start) (first : State)
    (h : Counted.begin p initial = .ok first) :
    (initial.inputs.mapM fun (name,raw) => do
      pure (name, ← Trial.readBack initial.toMemory raw)) =
      .ok (first.bindings.map (fun b => (b.record.name,b.value))) := by
  obtain ⟨_, _, bindings, _, hb, rfl⟩ := Initial.begin_shape p initial first h
  have ht := mapM_transfer hb
    (fun x => do pure (x.1.1, ← Trial.readBack initial.toMemory x.1.2))
    (fun b => (b.record.name,b.value)) (by
      intro x b hx
      simp only [Trial.Proofs.except_bind_eq_ok] at hx
      obtain ⟨v, hr, he⟩ := hx
      cases Except.ok.inj he
      simp [hr, makeBinding])
  change (initial.inputs.zipIdx.mapM (fun x => do
    pure (x.1.1, ← Trial.readBack initial.toMemory x.1.2))) = _ at ht
  have he := List.mapM_map (f := Prod.fst)
    (g := fun x : String × Raw => do pure (x.1, ← Trial.readBack initial.toMemory x.2))
    (l := initial.inputs.zipIdx)
  rw [List.zipIdx_map_fst] at he
  exact he.trans ht

theorem dead_is_prefix (bindings : List Binding) (env : Env) (tasks : List Task) :
    ∃ ids : List Nat, dead bindings env tasks = ids.map Task.giveBinding := by
  unfold dead
  induction env.reverse with
  | nil => exact ⟨[], rfl⟩
  | cons pair xs ih =>
    obtain ⟨ids, hi⟩ := ih
    simp only [List.filterMap_cons, hi]
    cases pair with
    | mk name id =>
      dsimp only
      by_cases hc : (bindings.any (fun b => b.record.id == id && b.record.status == .holding) &&
        !tasks.any (taskUses id)) = true
      · exact ⟨id :: ids, by simp only [hc, ite_true, List.map_cons]⟩
      · exact ⟨ids, by simp [hc]⟩

/-- Exact first conjunct of F2 only: initialized counted control decodes to
the independently initialized plain control. -/
theorem initial_simulation (p : Program) (initial : Trial.Start) (first : State)
    (h : Counted.begin p initial = .ok first) :
    ∃ plain, Statements.plainBegin p initial = .ok plain ∧
      Control.decode first = .ok plain := by
  have hvalues := input_values p initial first h
  have henv := input_environment p initial first h
  have hkinds : initial.inputs.map (fun x => (x.1,x.2.kind)) =
      (first.bindings.map (fun b => (b.record.name,b.value))).map
        (fun x => (x.1,x.2.kind)) := by
    apply Initial.mapM_ok_map hvalues
    intro x y hx
    simp only [Trial.Proofs.except_bind_eq_ok] at hx
    obtain ⟨v, hr, he⟩ := hx
    cases Except.ok.inj he
    -- The read-back kind property follows directly from raw syntax.
    cases x with
    | mk name raw =>
      cases raw with
      | num n | bool n => simp [Trial.readBack] at hr; subst v; rfl
      | list a =>
        simp only [Trial.readBack, Trial.Proofs.except_bind_eq_ok] at hr
        obtain ⟨items, _, hv⟩ := hr
        cases Except.ok.inj hv
        rfl
  have hv : ∃ kind, validate p (initial.inputs.map (fun x => (x.1,x.2.kind))) = .ok kind := by
    unfold Counted.begin at h
    simp only [Trial.Proofs.except_bind_eq_ok] at h
    obtain ⟨v, hv, _⟩ := h
    exact ⟨v, hv⟩
  obtain ⟨kind, hv⟩ := hv
  refine ⟨⟨.eval p.main (first.bindings.reverse.map (fun b => (b.record.name,b.value))), []⟩,
    ?_, ?_⟩
  · unfold Statements.plainBegin
    rw [hvalues]
    change Plain.begin p (first.bindings.map (fun b => (b.record.name,b.value))) = _
    unfold Plain.begin
    rw [← hkinds, hv]
    simp [List.map_reverse]
  · obtain ⟨_, edges, bindings, _, _, hs⟩ := Initial.begin_shape p initial first h
    obtain ⟨ids, hid⟩ := dead_is_prefix bindings
      (bindings.reverse.map (fun b => (b.record.name,b.record.id)))
      [.start,.eval p.main { env := bindings.reverse.map (fun b => (b.record.name,b.record.id)) },.finish]
    subst first
    rw [hid] at henv
    simp only [List.map_reverse] at henv
    simp only [Control.decode, hid, List.length_append, List.length_map, Nat.add_assoc]
    rw [focus_giveBinding_prefix]
    simp [Control.focus, Control.continuations, henv]

end Full.Proofs.SimulationInitial
