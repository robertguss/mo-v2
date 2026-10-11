import Full.Demand.LocalIds

namespace Full.Demand.Framing
open Counted Full.Proofs

/-- Operand shape relative to a saved caller continuation. At the delimiter,
exactly one local result remains; older slots and frames are outside this work.
No instruction here can manufacture a Finish or consume the delimiter. -/
inductive Shape (saved : List Task) (frames : List Nat) : List Task → Nat → List Nat → Prop
  | boundary : Shape saved frames saved 1 frames
  | start : Shape saved frames ts n fs → Shape saved frames (.start::ts) n fs
  | capture : Shape saved frames ts n fs → Shape saved frames (.capture::ts) n fs
  | eval : Shape saved frames ts (n+1) fs → Shape saved frames (.eval e ctx::ts) n fs
  | primitive : Shape saved frames ts (n+1) fs → Shape saved frames (.primitive op ctx::ts) (n+2) fs
  | bind : Shape saved frames ts (n+1) fs → Shape saved frames (.bind x body ctx::ts) (n+1) fs
  | chooseIf : Shape saved frames ts (n+1) fs → Shape saved frames (.chooseIf yes no ctx::ts) (n+1) fs
  | chooseMatch : Shape saved frames ts (n+1) fs → Shape saved frames (.chooseMatch nil h t body ctx::ts) (n+1) fs
  | decompose : Shape saved frames ts (n+1) fs → Shape saved frames (.decompose h t body bid ctx::ts) (n+1) fs
  | matchComplete : Shape saved frames ts n fs → Shape saved frames (.matchComplete ctx::ts) n fs
  | branchStart : Shape saved frames ts n fs → Shape saved frames (.branchStart ctx::ts) n fs
  | branchResult : Shape saved frames ts (n+1) fs → Shape saved frames (.branchResult bid inner outer::ts) (n+1) fs
  | handoffMatch : Shape saved frames ts (n+1) fs → Shape saved frames (.handoffMatch ctx::ts) (n+1) fs
  | handoff : Shape saved frames ts n fs → Shape saved frames (.handoff::ts) n fs
  | enter : Shape saved frames ts (n+1) fs → Shape saved frames (.enter name arity ctx::ts) (n+arity) fs
  | returning : Shape saved frames ts (n+1) fs → Shape saved frames (.returning f ctx::ts) (n+1) (f.id::fs)
  | giveBinding : Shape saved frames ts n fs → Shape saved frames (.giveBinding bid::ts) n fs
  | givePending : Shape saved frames ts n fs → Shape saved frames (.givePending::ts) (n+1) fs
  | free : Shape saved frames ts n fs → Shape saved frames (.free addr::ts) n fs
  | freeReserved : Shape saved frames ts n fs → Shape saved frames (.freeReserved addr::ts) n fs

theorem dead_prefix (bs : List Binding) (env : Env) (future : List Task)
    (hs : Shape saved frames ts n fs) : Shape saved frames (dead bs env future ++ ts) n fs := by
  obtain ⟨ids,he⟩ := SimulationInitial.dead_is_prefix bs env future
  rw [he]
  clear he
  induction ids with
  | nil => exact hs
  | cons id ids ih => exact .giveBinding ih

theorem reserved_prefix (rs : List Reservation) (hs : Shape saved frames ts n fs) :
    Shape saved frames (rs.map (fun r => .freeReserved r.addr) ++ ts) n fs := by
  induction rs with
  | nil => exact hs
  | cons r rs ih => exact .freeReserved ih

theorem arguments (args : List (Expr × Nat)) (ctx : Context)
    (hs : Shape saved frames ts (n+args.length) fs) :
    Shape saved frames (args.flatMap (fun (a,i) => [.eval a (child ctx i),.capture]) ++ ts) n fs := by
  induction args generalizing n with
  | nil => exact hs
  | cons a args ih =>
    apply Shape.eval
    apply Shape.capture
    apply ih
    simpa [Nat.add_assoc,Nat.add_comm,Nat.add_left_comm] using hs

set_option maxHeartbeats 3000000 in
/-- Actual transitions above the delimiter preserve the older operand suffix.
The number of local operands, rather than the total slot count, justifies every
pop, including variable-arity calls and release-cascade temporary operands. -/
theorem transition (hs : Shape saved frames s.tasks n (s.frames.map Frame.id))
    (hn : s.slots.length = n+slots.length) (hd : s.slots.drop n = slots)
    (hne : s.tasks ≠ saved) (ht : Counted.transition p s = .ok c) :
    ∃ n', Shape saved frames c.state.tasks n' (c.state.frames.map Frame.id) ∧
      c.state.slots.length = n'+slots.length ∧ c.state.slots.drop n' = slots := by
  generalize he : s.tasks = tasks at hs
  generalize hf : s.frames.map Frame.id = fs at hs
  cases hs
  case boundary => exact False.elim (hne he)
  all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
  all_goals repeat' first | split at ht | cases ht | contradiction
  all_goals simp_all only [List.length_cons,List.map_cons,List.length_drop,
    List.length_reverse,List.length_take,List.cons.injEq]
  all_goals refine ⟨_,(by
    try simp only [List.append_assoc,List.cons_append,List.nil_append]
    repeat' first
      | assumption
      | apply dead_prefix
      | apply reserved_prefix
      | apply arguments
      | constructor
      | solve | simp only [List.length_zipIdx]; exact Shape.enter (by assumption)),?_,?_⟩
  all_goals try omega
  all_goals simp_all [List.drop_drop,Nat.add_comm,Nat.add_left_comm,Nat.add_assoc]

theorem Shape.prefix (h : Shape saved frames ts n fs) : ∃ work, ts = work ++ saved := by
  induction h
  case boundary => exact ⟨[],rfl⟩
  all_goals obtain ⟨work,rfl⟩ := (by assumption : ∃ work, _ = work ++ saved)
  all_goals exact ⟨_::work,rfl⟩

theorem Shape.at_boundary (h : Shape saved frames ts n fs) (he : ts = saved) :
    n = 1 ∧ fs = frames := by
  cases h
  case boundary => exact ⟨rfl,rfl⟩
  all_goals have hp := Shape.prefix (by assumption)
  all_goals obtain ⟨work,hw⟩ := hp
  all_goals rw [hw] at he
  all_goals have hl := congrArg List.length he
  all_goals simp only [List.length_cons,List.length_append] at hl
  all_goals omega

theorem Shape.operands (h : Shape saved frames (task::ts) n fs)
    (hne : task::ts ≠ saved) : Residual.operands task ≤ n := by
  cases h
  case boundary => contradiction
  all_goals simp [Residual.operands]
  all_goals omega

theorem enter (ht : Counted.transition p s = .ok c)
    (hs : s.tasks = .enter name arity ctx::rest) (hf : c.state.frames.head? = some f) :
    Shape (.returning f ctx::rest) (c.state.frames.map Frame.id)
      c.state.tasks 0 (c.state.frames.map Frame.id) := by
  simp only [Counted.transition,hs,bind,pure,Except.bind,Except.pure] at ht
  repeat' first | split at ht | cases ht | contradiction
  simp only [List.head?_cons,Option.some.injEq] at hf
  subst f
  exact dead_prefix _ _ _ (.eval .boundary)

end Full.Demand.Framing
