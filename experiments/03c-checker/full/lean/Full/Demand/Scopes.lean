import Full.Demand.Events
import Full.Proofs.Residual

namespace Full.Demand.Scopes
open Counted

/-- Saved source work belongs to the current invocation; Return restores the
parent. This is control metadata, not a no-allocation assumption. -/
def task (frames : List Nat) : Task → Prop
  | .eval _ ctx | .primitive _ ctx | .bind _ _ ctx | .chooseIf _ _ ctx |
    .chooseMatch _ _ _ _ ctx | .decompose _ _ _ _ ctx | .matchComplete ctx |
    .branchStart ctx | .handoffMatch ctx | .enter _ _ ctx =>
      ctx.invocation = frames.headD 0
  | .branchResult _ inner outer =>
      inner.invocation = frames.headD 0 ∧ outer.invocation = frames.headD 0
  | .returning f ctx => frames.head? = some f.id ∧ ctx.invocation = frames.tail.headD 0
  | _ => True

def after (t : Task) (frames : List Nat) : List Nat :=
  match t with | .returning _ _ => frames.tail | _ => frames

inductive Work : List Task → List Nat → Prop
  | nil : Work [] fs
  | cons (head : task fs t) (tail : Work ts (after t fs)) : Work (t::ts) fs

theorem dead_prefix (bs : List Binding) (env : Env) (future : List Task)
    (hs : Work ts fs) : Work (dead bs env future ++ ts) fs := by
  obtain ⟨ids,he⟩ := Full.Proofs.SimulationInitial.dead_is_prefix bs env future
  rw [he]
  clear he
  induction ids with
  | nil => exact hs
  | cons id ids ih => exact .cons trivial ih

theorem reserved_prefix (rs : List Reservation) (hs : Work ts fs) :
    Work (rs.map (fun r => .freeReserved r.addr) ++ ts) fs := by
  induction rs with
  | nil => exact hs
  | cons r rs ih => exact .cons trivial ih

theorem arguments (args : List (Expr × Nat)) (ctx : Context)
    (hc : ctx.invocation = fs.headD 0) (hs : Work ts fs) :
    Work (args.flatMap (fun (a,i) => [.eval a (child ctx i),.capture]) ++ ts) fs := by
  induction args with
  | nil => exact hs
  | cons a args ih => exact .cons hc (.cons trivial ih)

theorem begin_work (hb : Counted.begin p initial = .ok first) :
    Work first.tasks (first.frames.map Frame.id) := by
  obtain ⟨_,_,_,_,_,rfl⟩ := Full.Proofs.Initial.begin_shape p initial first hb
  exact dead_prefix _ _ _ (.cons trivial (.cons rfl (.cons trivial .nil)))

set_option maxHeartbeats 2000000 in
theorem transition_work (hs : Work s.tasks (s.frames.map Frame.id))
    (ht : Counted.transition p s = .ok c) :
    Work c.state.tasks (c.state.frames.map Frame.id) := by
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons t rest =>
    rw [he] at hs
    cases hs with
    | cons hhead hrest =>
      cases t
      all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
      all_goals repeat' first | split at ht | cases ht | contradiction
      all_goals simp only [task,after] at hhead hrest
      all_goals try simp only [List.append_assoc,List.cons_append,List.nil_append,List.map_cons]
      all_goals repeat' first
        | assumption
        | apply dead_prefix
        | apply reserved_prefix
        | apply arguments
        | apply Work.cons
        | exact Work.nil
        | solve | simp_all [task,after,child]

theorem advance_work (hs : Work s.tasks (s.frames.map Frame.id))
    (ht : Counted.advance p n s = .ok t) : Work t.tasks (t.frames.map Frame.id) := by
  induction n generalizing s with
  | zero => cases ht; exact hs
  | succ n ih =>
    cases ha : s.answer with
    | some v => simp [Counted.advance,ha,pure,Except.pure] at ht; subst t; exact hs
    | none =>
      cases hc : Counted.transition p s with
      | error why => simp [Counted.advance,Counted.step,ha,hc,Functor.map,Except.map] at ht
      | ok c =>
        simp [Counted.advance,Counted.step,ha,hc,Functor.map,Except.map] at ht
        exact ih (s := commit c) (transition_work hs hc) ht

theorem reachable_work (hr : Statements.Reachable p initial s) :
    Work s.tasks (s.frames.map Frame.id) := by
  obtain ⟨first,n,hb,ha⟩ := hr
  exact advance_work (begin_work hb) ha

def contexts : Task → List Context
  | .eval _ ctx | .primitive _ ctx | .bind _ _ ctx | .chooseIf _ _ ctx |
    .chooseMatch _ _ _ _ ctx | .decompose _ _ _ _ ctx | .matchComplete ctx |
    .branchStart ctx | .handoffMatch ctx | .enter _ _ ctx | .returning _ ctx => [ctx]
  | .branchResult _ inner outer => [inner,outer]
  | _ => []

theorem headD_bound (ids : List Nat) (hn : 0 < next)
    (hb : ∀ id ∈ ids, id < next) : ids.headD 0 < next := by
  cases ids with
  | nil => exact hn
  | cons id ids => exact hb id (by simp)

theorem task_bound (h : task fs t) (hn : 0 < next) (hb : ∀ id ∈ fs, id < next) :
    ∀ ctx ∈ contexts t, ctx.invocation < next := by
  have hh := headD_bound fs hn hb
  have ht := headD_bound fs.tail hn (fun id hm => hb id (List.mem_of_mem_tail hm))
  cases t <;> simp_all [task,contexts]
  all_goals omega

theorem Work.contexts_bound (hs : Work ts fs) (hn : 0 < next)
    (hb : ∀ id ∈ fs, id < next) :
    ∀ t ∈ ts, ∀ ctx ∈ contexts t, ctx.invocation < next := by
  induction hs with
  | nil => simp
  | @cons fs task ts hh ht ih =>
    intro t hm
    rcases List.mem_cons.mp hm with rfl | hm
    · exact task_bound hh hn hb
    · apply ih _ t hm
      intro id hid
      cases task <;> simp only [after] at hid
      all_goals first
        | exact hb id hid
        | exact hb id (List.mem_of_mem_tail hid)

/-- Saved caller work cannot refer to an invocation ID that a future Enter
has yet to allocate. This separates caller continuations from the target. -/
theorem reachable_contexts_bound (hr : Statements.Reachable p initial s)
    (hm : t ∈ s.tasks) (hc : ctx ∈ contexts t) : ctx.invocation < s.nextInvocation := by
  have hi := Events.reachable_invariant hr
  exact (reachable_work hr).contexts_bound (Events.next_positive hi)
    (Events.frame_bound hi) t hm ctx hc

theorem head_scope (hr : Statements.Reachable p initial s) (ht : s.tasks = t::ts) :
    task (s.frames.map Frame.id) t := by
  have hw := reachable_work hr
  rw [ht] at hw
  cases hw with | cons hh _ => exact hh

theorem active_head_ge {id : Nat} (hr : Statements.Reachable p initial s)
    (hm : id ∈ s.frames.map Frame.id) : id ≤ (s.frames.map Frame.id).headD 0 := by
  have hi := Events.reachable_invariant hr
  cases hf : s.frames with
  | nil => simp [hf] at hm
  | cons f fs =>
    simp only [Events.Invariant,hf,List.map_cons] at hi
    exact Events.head_ge hi (by simpa [hf] using hm)

end Full.Demand.Scopes
