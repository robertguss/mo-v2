import Full.Proofs.Initial
import Full.Statements

namespace Full.Proofs.BindingIdentity
open Counted

theorem status_ids (bs : List Binding) (bid : Nat) (status : Trial.BStatus) :
    (bs.map (fun b => if b.record.id == bid then
      { b with record := { b.record with status := status } } else b)).map
        (fun b => b.record.id) = bs.map (fun b => b.record.id) := by
  simp only [List.map_map]
  congr 1
  funext b
  dsimp only [Function.comp_def]
  split <;> rfl

theorem parameter_ids (pairs : List ((String × Kind) × Slot))
    (next invocation : Nat) (name : String) :
    (pairs.zipIdx.map (fun (((x,_),v),i) =>
      makeBinding (next+i) x v invocation s!"{name}/parameter/{x}")).map
        (fun b => b.record.id) = (List.range pairs.length).map (next+·) := by
  have h : pairs.zipIdx.map Prod.snd = List.range pairs.length := by
    simp [List.range_eq_range']
  simpa only [List.map_map, Function.comp_def, makeBinding] using
    congrArg (List.map (next+·)) h

theorem begin_ids (hb : Counted.begin p initial = .ok first) :
    first.bindings.map (fun b => b.record.id) = List.range first.nextBinding := by
  obtain ⟨_,hi,hn⟩ := Initial.begin_scope_ids p initial first hb
  simpa [hn] using hi

set_option maxHeartbeats 1000000 in
/-- Binding identities are never reused, deleted or reordered. New names and
parameters consume exactly the next consecutive identities, even in recursion. -/
theorem transition_ids
    (hs : s.bindings.map (fun b => b.record.id) = List.range s.nextBinding)
    (ht : Counted.transition p s = .ok c) :
    c.state.bindings.map (fun b => b.record.id) = List.range c.state.nextBinding := by
  cases he : s.tasks with
  | nil => simp [Counted.transition, he] at ht
  | cons task rest =>
    cases task
    all_goals simp only [Counted.transition, he, bind, pure, Except.bind, Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals try simp only [List.map_append, List.map_cons, List.map_nil, status_ids, parameter_ids]
    all_goals simp_all [List.range_succ, List.range_add, makeBinding]

theorem advance_ids
    (hs : s.bindings.map (fun b => b.record.id) = List.range s.nextBinding)
    (ht : Counted.advance p n s = .ok t) :
    t.bindings.map (fun b => b.record.id) = List.range t.nextBinding := by
  induction n generalizing s with
  | zero => cases ht; exact hs
  | succ n ih =>
    cases ha : s.answer with
    | some v => simp [Counted.advance, ha] at ht; subst t; exact hs
    | none =>
      cases hc : Counted.transition p s with
      | error why => simp [Counted.advance, Counted.step, ha, hc] at ht
      | ok c =>
        simp [Counted.advance, Counted.step, ha, hc] at ht
        exact ih (s := commit c) (transition_ids hs hc) ht

theorem reachable_ids (hr : Statements.Reachable p initial s) :
    s.bindings.map (fun b => b.record.id) = List.range s.nextBinding := by
  obtain ⟨first,n,hb,hn⟩ := hr
  exact advance_ids (begin_ids hb) hn

theorem reachable_unique (hr : Statements.Reachable p initial s) :
    (s.bindings.map (fun b => b.record.id)).Nodup := by
  rw [reachable_ids hr]
  exact List.nodup_range

theorem reachable_bound (hr : Statements.Reachable p initial s)
    (hb : b ∈ s.bindings) : b.record.id < s.nextBinding := by
  apply List.mem_range.mp
  rw [← reachable_ids hr]
  exact List.mem_map.mpr ⟨b,hb,rfl⟩

theorem reachable_lookup (hr : Statements.Reachable p initial s)
    (hi : bid < s.nextBinding) :
    ∃ b, s.bindings.find? (fun b => b.record.id == bid) = some b ∧ b.record.id = bid := by
  have hm : bid ∈ s.bindings.map (fun b => b.record.id) := by
    rw [reachable_ids hr]
    exact List.mem_range.mpr hi
  obtain ⟨b,hb,he⟩ := List.mem_map.mp hm
  exact ⟨b,by simpa [he] using
    Initial.find_key_self s.bindings (fun b => b.record.id) (reachable_unique hr) b hb,he⟩

/-- Status is mutable, but these fields remain available to saved environments
even after an ownership transfer makes the raw value inaccessible. -/
def data (b : Binding) : Nat × String × Raw × Value :=
  (b.record.id,b.record.name,b.record.value,b.value)

theorem status_data (bs : List Binding) (bid : Nat) (status : Trial.BStatus) :
    (bs.map (fun b => if b.record.id == bid then
      { b with record := { b.record with status := status } } else b)).map data = bs.map data := by
  simp only [List.map_map]
  congr 1
  funext b
  dsimp only [Function.comp_def]
  split <;> rfl

set_option maxHeartbeats 1000000 in
theorem transition_data (ht : Counted.transition p s = .ok c) :
    (s.bindings.map data).IsPrefix (c.state.bindings.map data) := by
  cases he : s.tasks with
  | nil => simp [Counted.transition, he] at ht
  | cons task rest =>
    cases task
    all_goals simp only [Counted.transition, he, bind, pure, Except.bind, Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals try simp only [List.map_append, status_data]
    all_goals first
      | exact List.prefix_refl _
      | exact ⟨_,rfl⟩

theorem transition_lookup (ht : Counted.transition p s = .ok c)
    (hb : (s.bindings.find? (fun b => b.record.id == bid)).map data = some v) :
    (c.state.bindings.find? (fun b => b.record.id == bid)).map data = some v := by
  have hs : (s.bindings.map data).find? (fun d => d.1 == bid) = some v := by
    simpa only [List.find?_map, Function.comp_def, data] using hb
  have hc := (transition_data ht).find?_eq_some hs
  simpa only [List.find?_map, Function.comp_def, data] using hc

end Full.Proofs.BindingIdentity
