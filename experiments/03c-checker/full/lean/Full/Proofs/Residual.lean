import Full.Proofs.ControlShape

namespace Full.Proofs.Residual
open Counted

/-- Saved work accounts for every operand and active call frame. This is a
structural certificate, not a promise that any future transition succeeds. -/
inductive Shape : List Task → Nat → List Nat → Prop where
  | done : Shape [] 1 []
  | finish : Shape [.finish] 1 []
  | start : Shape ts n fs → Shape (.start :: ts) n fs
  | capture : Shape ts n fs → Shape (.capture :: ts) n fs
  | eval : Shape ts (n+1) fs → Shape (.eval e ctx :: ts) n fs
  | primitive : Shape ts (n+1) fs → Shape (.primitive op ctx :: ts) (n+2) fs
  | bind : Shape ts (n+1) fs → Shape (.bind x body ctx :: ts) (n+1) fs
  | chooseIf : Shape ts (n+1) fs → Shape (.chooseIf yes no ctx :: ts) (n+1) fs
  | chooseMatch : Shape ts (n+1) fs → Shape (.chooseMatch nil h t body ctx :: ts) (n+1) fs
  | decompose : Shape ts (n+1) fs → Shape (.decompose h t body bid ctx :: ts) (n+1) fs
  | matchComplete : Shape ts n fs → Shape (.matchComplete ctx :: ts) n fs
  | branchStart : Shape ts n fs → Shape (.branchStart ctx :: ts) n fs
  | branchResult : Shape ts (n+1) fs → Shape (.branchResult bid inner outer :: ts) (n+1) fs
  | handoffMatch : Shape ts (n+1) fs → Shape (.handoffMatch ctx :: ts) (n+1) fs
  | handoff : Shape ts n fs → Shape (.handoff :: ts) n fs
  | enter : Shape ts (n+1) fs → Shape (.enter name arity ctx :: ts) (n+arity) fs
  | returning : Shape ts (n+1) fs → Shape (.returning f ctx :: ts) (n+1) (f.id :: fs)
  | giveBinding : Shape ts n fs → Shape (.giveBinding bid :: ts) n fs
  | givePending : Shape ts n fs → Shape (.givePending :: ts) (n+1) fs
  | free : Shape ts n fs → Shape (.free addr :: ts) n fs
  | freeReserved : Shape ts n fs → Shape (.freeReserved addr :: ts) n fs

theorem dead_prefix (bs : List Binding) (env : Env) (future : List Task)
    (hs : Shape ts n fs) : Shape (dead bs env future ++ ts) n fs := by
  obtain ⟨ids, he⟩ := SimulationInitial.dead_is_prefix bs env future
  rw [he]
  clear he
  induction ids with
  | nil => exact hs
  | cons id ids ih => exact .giveBinding ih

theorem reserved_prefix (rs : List Reservation) (hs : Shape ts n fs) :
    Shape (rs.map (fun r => .freeReserved r.addr) ++ ts) n fs := by
  induction rs with
  | nil => exact hs
  | cons r rs ih => exact .freeReserved ih

theorem arguments (args : List (Expr × Nat)) (ctx : Context)
    (hs : Shape ts (n+args.length) fs) :
    Shape (args.flatMap (fun (a,i) => [.eval a (child ctx i),.capture]) ++ ts) n fs := by
  induction args generalizing n with
  | nil => simpa using hs
  | cons a args ih =>
    apply Shape.eval
    apply Shape.capture
    apply ih
    simpa [Nat.add_assoc, Nat.add_comm, Nat.add_left_comm] using hs

theorem begin_shape (hb : Counted.begin p initial = .ok first) :
    Shape first.tasks first.slots.length (first.frames.map Frame.id) := by
  obtain ⟨_,_,_,_,_,rfl⟩ := Initial.begin_shape p initial first hb
  exact dead_prefix _ _ _ (.start (.eval .finish))

theorem height_eq (hs : Shape ts n fs) (he : n = m) : Shape ts m fs := he ▸ hs

set_option maxHeartbeats 2000000 in
theorem transition_shape (hs : Shape s.tasks s.slots.length (s.frames.map Frame.id))
    (ht : Counted.transition p s = .ok c) :
    Shape c.state.tasks c.state.slots.length (c.state.frames.map Frame.id) := by
  cases he : s.tasks with
  | nil => simp [Counted.transition, he] at ht
  | cons task rest =>
    rw [he] at hs
    generalize hn : s.slots.length = n at hs
    generalize hf : s.frames.map Frame.id = fs at hs
    cases hs
    all_goals simp only [Counted.transition, he, bind, pure, Except.bind, Except.pure] at ht
    all_goals repeat' first
      | split at ht
      | cases ht
      | contradiction
    all_goals simp_all only [List.length_cons, List.map_cons, List.length_drop,
      List.length_reverse, List.length_take, List.cons.injEq]
    all_goals try simp only [List.append_assoc, List.cons_append, List.nil_append]
    all_goals repeat' first
      | assumption
      | solve | exact Shape.done
      | apply dead_prefix
      | apply reserved_prefix
      | apply arguments
      | constructor
      | solve | refine height_eq (by assumption) ?_; omega
    all_goals simp only [List.length_zipIdx]
    all_goals exact Shape.enter (by assumption)

theorem advance_shape (hs : Shape s.tasks s.slots.length (s.frames.map Frame.id))
    (ht : Counted.advance p n s = .ok t) :
    Shape t.tasks t.slots.length (t.frames.map Frame.id) := by
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
        exact ih (s := commit c) (transition_shape hs hc) ht

theorem reachable_shape (hr : Statements.Reachable p initial s) :
    Shape s.tasks s.slots.length (s.frames.map Frame.id) := by
  obtain ⟨first,n,hb,hn⟩ := hr
  exact advance_shape (begin_shape hb) hn

theorem empty_shape (hs : Shape [] n fs) : n = 1 ∧ fs = [] := by
  cases hs
  exact ⟨rfl,rfl⟩

def operands : Task → Nat
  | .primitive _ _ => 2
  | .enter _ arity _ => arity
  | .bind _ _ _ | .chooseIf _ _ _ | .chooseMatch _ _ _ _ _ |
    .decompose _ _ _ _ _ | .branchResult _ _ _ | .handoffMatch _ |
    .returning _ _ | .givePending | .finish => 1
  | _ => 0

theorem shape_operands (hs : Shape (task :: ts) n fs) : operands task ≤ n := by
  cases hs <;> simp [operands] <;> omega

/-- All explicit operand reads are in bounds, independently of heap safety. -/
theorem reachable_operands (hr : Statements.Reachable p initial s)
    (ht : s.tasks = task :: ts) : operands task ≤ s.slots.length := by
  have hs := reachable_shape hr
  rw [ht] at hs
  exact shape_operands hs

theorem shape_return (hs : Shape (.returning frame ctx :: ts) n fs) :
    ∃ rest, fs = frame.id :: rest := by
  cases hs
  exact ⟨_,rfl⟩

/-- The next Return always has the correct active frame; the runtime check is
not assumed to succeed as part of the certificate. -/
theorem reachable_return (hr : Statements.Reachable p initial s)
    (ht : s.tasks = .returning frame ctx :: ts) :
    ∃ active rest, s.frames = active :: rest ∧ active.id = frame.id := by
  have hs := reachable_shape hr
  rw [ht] at hs
  obtain ⟨rest,hf⟩ := shape_return hs
  cases he : s.frames with
  | nil => simp [he] at hf
  | cons active frames =>
    exact ⟨active,frames,rfl,by simpa [he] using congrArg List.head? hf⟩

/-- No extra operand or active frame can survive a reachable Finish, even
before the heap and binding cleanup obligations of F4 have been established. -/
theorem terminal_shape (hr : Statements.Reachable p initial s)
    (ha : s.answer.isSome = true) : s.slots.length = 1 ∧ s.frames = [] := by
  have hs := reachable_shape hr
  rw [(ControlShape.reachable_shape hr).2 ha] at hs
  obtain ⟨hn,hf⟩ := empty_shape hs
  exact ⟨hn,List.map_eq_nil_iff.mp hf⟩

/-- Finish remains in the saved work until the answer is installed. -/
def Waiting : List Task → Prop
  | [] => False
  | .finish :: _ => True
  | _ :: ts => Waiting ts

theorem waiting_append (xs ys : List Task) :
    Waiting (xs ++ ys) ↔ Waiting xs ∨ Waiting ys := by
  induction xs with
  | nil => simp [Waiting]
  | cons x xs ih => cases x <;> simp [Waiting, ih]

theorem waiting_dead (bs : List Binding) (env : Env) (future : List Task) :
    ¬ Waiting (dead bs env future) := by
  obtain ⟨ids,he⟩ := SimulationInitial.dead_is_prefix bs env future
  rw [he]
  clear he
  induction ids with
  | nil => simp [Waiting]
  | cons id ids ih => simpa [Waiting] using ih

theorem waiting_arguments (args : List (Expr × Nat)) (ctx : Context) :
    ¬ Waiting (args.flatMap (fun (a,i) => [.eval a (child ctx i),.capture])) := by
  induction args with
  | nil => simp [Waiting]
  | cons a args ih => simpa [Waiting] using ih

theorem waiting_reserved (rs : List Reservation) :
    ¬ Waiting (rs.map (fun r => .freeReserved r.addr)) := by
  induction rs with
  | nil => simp [Waiting]
  | cons r rs ih => simpa [Waiting] using ih

set_option maxHeartbeats 1000000 in
theorem transition_waiting (hs : Waiting s.tasks)
    (ht : Counted.transition p s = .ok c) (ha : c.state.answer = none) :
    Waiting c.state.tasks := by
  cases he : s.tasks with
  | nil => simp [Counted.transition, he] at ht
  | cons task rest =>
    cases task
    all_goals simp only [Counted.transition, he, bind, pure, Except.bind, Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals simp_all [Waiting, waiting_append, waiting_dead, waiting_arguments, waiting_reserved]

theorem advance_waiting (hs : s.answer = none → Waiting s.tasks)
    (ht : Counted.advance p n s = .ok t) : t.answer = none → Waiting t.tasks := by
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
        apply ih (s := commit c) ?_ ht
        exact transition_waiting (hs ha) hc

theorem reachable_waiting (hr : Statements.Reachable p initial s)
    (ha : s.answer = none) : Waiting s.tasks := by
  obtain ⟨first,n,hb,hn⟩ := hr
  apply advance_waiting ?_ hn ha
  obtain ⟨_,_,_,_,_,rfl⟩ := Initial.begin_shape p initial first hb
  simp [waiting_append, Waiting]

theorem reachable_task (hr : Statements.Reachable p initial s)
    (ha : s.answer = none) : ∃ task rest, s.tasks = task :: rest := by
  have hs := reachable_waiting hr ha
  cases he : s.tasks with
  | nil => simp [he, Waiting] at hs
  | cons task rest => exact ⟨task,rest,rfl⟩

end Full.Proofs.Residual
