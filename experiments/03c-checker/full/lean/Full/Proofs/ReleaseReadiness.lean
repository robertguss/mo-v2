import Full.Proofs.Progress

namespace Full.Proofs.ReleaseReadiness
open Counted

def special : Task → Bool
  | .decompose _ _ _ _ _ | .givePending | .free _ => true
  | _ => false

def Clear (ts : List Task) : Prop := ts.all (fun t => !special t) = true

def Nonempty (vs : List Slot) : Prop :=
  ∃ v tail addr, vs = v :: tail ∧ v.raw = .list (some addr)

/-- A pending nonempty operand is installed only at a selected match or a
release boundary. Named cleanup can precede it; ordinary source work cannot. -/
def Ready : List Task → List Slot → Prop
  | [], _ => True
  | .giveBinding _ :: ts, vs | .free _ :: ts, vs => Ready ts vs
  | .givePending :: ts, vs => Nonempty vs ∧ Ready ts vs.tail
  | .decompose _ _ _ _ _ :: ts, vs => Nonempty vs ∧ Clear ts
  | _ :: ts, _ => Clear ts

theorem clear_append : Clear (xs ++ ys) ↔ Clear xs ∧ Clear ys := by
  simp [Clear]

theorem clear_ready (hc : Clear ts) : Ready ts vs := by
  induction ts generalizing vs with
  | nil => trivial
  | cons task ts ih =>
    cases task <;> simp_all [Clear,Ready,special]

theorem dead_ready (bs : List Binding) (env : Env) (future : List Task) :
    Ready (dead bs env future ++ ts) vs ↔ Ready ts vs := by
  obtain ⟨ids,he⟩ := SimulationInitial.dead_is_prefix bs env future
  rw [he]
  clear he
  induction ids with
  | nil => rfl
  | cons id ids ih => simpa [Ready] using ih

theorem arguments_clear (args : List (Expr × Nat)) (ctx : Context) :
    Clear (args.flatMap (fun (e,i) => [.eval e (child ctx i),.capture])) := by
  induction args with
  | nil => rfl
  | cons a args ih => simpa [Clear,special] using ih

theorem reserved_clear (rs : List Reservation) :
    Clear (rs.map (fun r => .freeReserved r.addr)) := by
  simp [Clear,List.all_map,special]

set_option maxHeartbeats 2000000 in
theorem transition_ready (hs : Ready s.tasks s.slots)
    (ht : Counted.transition p s = .ok c) : Ready c.state.tasks c.state.slots := by
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    rw [he] at hs
    cases task
    all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals simp only [Ready] at hs
    all_goals try exact hs
    all_goals try exact clear_ready hs
    all_goals try simp only [dead_ready,List.append_assoc,List.cons_append,List.nil_append]
    all_goals try solve
      | apply clear_ready
        simp_all [clear_append,arguments_clear,reserved_clear,Clear,special]
    all_goals simp_all [Ready,Nonempty,Clear,special,Option.isSome_iff_exists]

theorem begin_ready (hb : Counted.begin p initial = .ok first) :
    Ready first.tasks first.slots := by
  obtain ⟨_,_,_,_,_,rfl⟩ := Initial.begin_shape p initial first hb
  rw [dead_ready]
  simp [Ready,Clear,special]

theorem advance_ready (hs : Ready s.tasks s.slots)
    (ht : Counted.advance p n s = .ok t) : Ready t.tasks t.slots := by
  induction n generalizing s with
  | zero => cases ht; exact hs
  | succ n ih =>
    cases ha : s.answer with
    | some v => simp [Counted.advance,ha] at ht; subst t; exact hs
    | none =>
      cases hc : Counted.transition p s with
      | error why => simp [Counted.advance,Counted.step,ha,hc] at ht
      | ok c =>
        simp [Counted.advance,Counted.step,ha,hc] at ht
        exact ih (s := commit c) (transition_ready hs hc) ht

theorem reachable_ready (hr : Statements.Reachable p initial s) : Ready s.tasks s.slots := by
  obtain ⟨first,n,hb,hn⟩ := hr
  exact advance_ready (begin_ready hb) hn

def NoFree (ts : List Task) : Prop := ∀ a, Task.free a ∉ ts

def FreeReady (s : State) : Prop :=
  match s.tasks with
  | .free a :: rest => NoFree rest ∧
    ∃ c, s.mem.find? a = some c ∧ c.status = .live ∧ c.count = 0
  | ts => NoFree ts

theorem nofree_ready (hn : NoFree s.tasks) : FreeReady s := by
  unfold FreeReady
  cases he : s.tasks with
  | nil => simpa [he] using hn
  | cons task rest =>
    cases task <;> simp_all [NoFree]
    rename_i a
    exact False.elim ((hn a).1 rfl)

theorem dead_nofree (bs : List Binding) (env : Env) (future : List Task) :
    NoFree (dead bs env future) := by
  obtain ⟨ids,he⟩ := SimulationInitial.dead_is_prefix bs env future
  simp [NoFree,he]

theorem free_not_mem_dead (a : Nat) (bs : List Binding) (env : Env) (future : List Task) :
    Task.free a ∉ dead bs env future := dead_nofree bs env future a

theorem args_nofree (args : List (Expr × Nat)) (ctx : Context) :
    NoFree (args.flatMap (fun (e,i) => [.eval e (child ctx i),.capture])) := by
  simp [NoFree]

theorem set_count_find (hf : m.find? a = some c)
    (ht : Trial.Memory.setCount m a n = .ok m') :
    m'.find? a = some { c with count := n } := by
  simp [Trial.Memory.setCount,hf] at ht
  subst m'
  have hid : c.addr = a := by simpa using List.find?_some hf
  rw [Trial.Proofs.find_update _ _ _ _ (by intros; rfl),hf]
  simp [hid]

set_option maxHeartbeats 2000000 in
theorem transition_free_ready (hs : FreeReady s)
    (ht : Counted.transition p s = .ok change) : FreeReady change.state := by
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    cases task
    all_goals simp only [FreeReady,he] at hs
    all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals try solve
      | apply nofree_ready
        simp_all [NoFree,free_not_mem_dead]
    all_goals simp_all only [FreeReady,NoFree,List.mem_cons,not_or]
    all_goals constructor
    all_goals try assumption
    all_goals try simp
    all_goals refine ⟨_,set_count_find (by assumption) (by assumption),?_,?_⟩
    all_goals simp_all

theorem begin_free_ready (hb : Counted.begin p initial = .ok first) : FreeReady first := by
  obtain ⟨_,_,_,_,_,rfl⟩ := Initial.begin_shape p initial first hb
  apply nofree_ready
  simp [NoFree,free_not_mem_dead]

theorem advance_free_ready (hs : FreeReady s)
    (ht : Counted.advance p n s = .ok t) : FreeReady t := by
  induction n generalizing s with
  | zero => cases ht; exact hs
  | succ n ih =>
    cases ha : s.answer with
    | some v => simp [Counted.advance,ha] at ht; subst t; exact hs
    | none =>
      cases hc : Counted.transition p s with
      | error why => simp [Counted.advance,Counted.step,ha,hc] at ht
      | ok change =>
        simp [Counted.advance,Counted.step,ha,hc] at ht
        exact ih (s := commit change) (transition_free_ready hs hc) ht

theorem reachable_free_ready (hr : Statements.Reachable p initial s) : FreeReady s := by
  obtain ⟨first,n,hb,hn⟩ := hr
  exact advance_free_ready (begin_free_ready hb) hn

end Full.Proofs.ReleaseReadiness
