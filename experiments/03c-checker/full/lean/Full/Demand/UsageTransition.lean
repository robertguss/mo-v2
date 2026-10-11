import Full.Demand.Usage
import Full.Proofs.LiveBindings

namespace Full.Demand
open Counted Full.Proofs

@[simp] theorem future_nil (id : Nat) : futureOccurrences id [] = 0 := rfl

@[simp] theorem future_cons (id : Nat) (t : Task) (ts : List Task) :
    futureOccurrences id (t::ts) = taskOccurrences id t + futureOccurrences id ts := by
  simp [futureOccurrences]

@[simp] theorem future_append (id : Nat) (a b : List Task) :
    futureOccurrences id (a ++ b) = futureOccurrences id a + futureOccurrences id b := by
  simp [futureOccurrences]

@[simp] theorem future_dead (id : Nat) (bs : List Binding) (env : Env) (ts : List Task) :
    futureOccurrences id (dead bs env ts) = 0 :=
  (futureUses_zero id _).mp (ReleaseQueue.dead_unused bs env ts id)

theorem parameter_occurrences {id : Nat} (pairs : List ((String × Kind) × Slot))
    (next invocation : Nat) (name : String) (e : Expr) (hb : id < next) :
    occurrences e (Trial.toFEnv
      ((pairs.zipIdx.map (fun (((x,_),v),i) =>
        makeBinding (next+i) x v invocation s!"{name}/parameter/{x}")).reverse.map
          (fun b => (b.record.name,b.record.id)))) id = 0 :=
  (uses_zero _ _ _).mp (LiveBindings.parameters_unused pairs next invocation name e hb)

theorem arguments_occurrences (id : Nat) (args : List (Expr × Nat)) (ctx : Context) :
    futureOccurrences id (args.flatMap (fun (a,i) => [.eval a (child ctx i), .capture])) =
      (args.map (fun a => occurrences a.1 (Trial.toFEnv ctx.env) id)).sum := by
  induction args with
  | nil => simp
  | cons a args ih =>
    rcases a with ⟨e,i⟩
    simp only [List.flatMap_cons, List.map_cons, List.sum_cons, future_append,
      future_cons, future_nil, taskOccurrences, Nat.add_zero, Nat.zero_add]
    rw [ih]
    rfl

theorem call_occurrences (id : Nat) (args : List Expr) (ctx : Context) :
    futureOccurrences id (args.zipIdx.flatMap (fun (a,i) => [.eval a (child ctx i), .capture])) =
      (args.attach.map (fun a => occurrences a.val (Trial.toFEnv ctx.env) id)).sum := by
  rw [arguments_occurrences]
  have hm := congrArg (List.map (fun a => occurrences a (Trial.toFEnv ctx.env) id))
    (List.zipIdx_map_fst 0 args)
  simp only [List.map_map, Function.comp_def] at hm
  simpa [occurrences] using congrArg List.sum hm

@[simp] theorem freeReserved_occurrences (id : Nat) (rs : List Reservation) :
    futureOccurrences id (rs.map (fun r => .freeReserved r.addr)) = 0 := by
  induction rs <;> simp_all [taskOccurrences]

set_option maxHeartbeats 4000000 in
/-- Universal bookkeeping fact: no successful step can increase the maximum
remaining occurrences of an already-created binding. This is not the demand
theorem: newly introduced bindings still require the checker's affine bound. -/
theorem transition_old_occurrences {id : Nat} (hb : id < s.nextBinding)
    (ht : Counted.transition p s = .ok c) :
    futureOccurrences id c.state.tasks ≤ futureOccurrences id s.tasks := by
  have hshadow := fun e env x => occurrences_fresh_shadow e env x
    s.nextBinding id (by omega : s.nextBinding ≠ id)
  have hpair := fun e env head tail => occurrences_fresh_pair e env head tail
    s.nextBinding (s.nextBinding+1) id (by omega) (by omega)
  have hparameters := fun pairs invocation name e =>
    parameter_occurrences pairs s.nextBinding invocation name e hb
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    cases task
    all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals simp only [he, future_append, future_cons, future_nil, future_dead,
      freeReserved_occurrences]
    all_goals try simp only [call_occurrences]
    all_goals simp only [taskOccurrences, child, Nat.zero_add, Nat.add_zero]
    all_goals try simp only [hparameters, Nat.zero_add]
    all_goals try simp only [Trial.toFEnv, List.map_cons, makeBinding, hshadow, hpair]
    all_goals try simp only [occurrences]
    all_goals omega

end Full.Demand
