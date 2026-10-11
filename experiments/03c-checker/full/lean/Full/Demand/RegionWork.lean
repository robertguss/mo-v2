import Full.Demand.Region
import Full.Proofs.ReservationAccounted
import Full.Proofs.ReservedReadiness

namespace Full.Demand.RegionWork
open Counted Full.Proofs Region

def TaskOK (cut : Nat) (region : List Nat) : Task → Prop
  | .giveBinding id => cut ≤ id
  | .free a | .freeReserved a => a ∈ region
  | _ => True

/-- Only cleanup above the target's Return delimiter is local. Cleanup saved
in an older caller continuation is intentionally not constrained. -/
inductive Clean (saved : List Task) (cut : Nat) (region : List Nat) : List Task → Prop
  | boundary : Clean saved cut region saved
  | cons : TaskOK cut region task → Clean saved cut region ts → Clean saved cut region (task::ts)

theorem Clean.head (h : Clean saved cut region (task::ts)) (hne : task::ts ≠ saved) :
    TaskOK cut region task ∧ Clean saved cut region ts := by
  cases h
  case boundary => contradiction
  case cons hh ht => exact ⟨hh,ht⟩

theorem dead_prefix (bs : List Binding) (env : Env) (future : List Task)
    (hc : ∀ pair ∈ env, cut ≤ pair.2) (hs : Clean saved cut region ts) :
    Clean saved cut region (dead bs env future ++ ts) := by
  obtain ⟨ids,he,hi⟩ := EnvironmentIdentity.dead_ids_sublist bs env future
  have hb : ∀ id ∈ ids, cut ≤ id := by
    intro id hm
    obtain ⟨pair,hp,rfl⟩ := List.mem_map.mp (hi.subset hm)
    exact hc pair (List.mem_reverse.mp hp)
  rw [he]
  clear he hi
  induction ids with
  | nil => exact hs
  | cons id ids ih => exact .cons (hb id (by simp)) (ih (fun i hm => hb i (by simp [hm])))

theorem reserved_prefix (rs : List Reservation) (hr : ∀ r ∈ rs, r.addr ∈ region)
    (hs : Clean saved cut region ts) :
    Clean saved cut region (rs.map (fun r => .freeReserved r.addr) ++ ts) := by
  induction rs with
  | nil => exact hs
  | cons r rs ih => exact .cons (hr r (by simp)) (ih (fun q hm => hr q (by simp [hm])))

theorem arguments (args : List (Expr × Nat)) (ctx : Context) (hs : Clean saved cut region ts) :
    Clean saved cut region (args.flatMap (fun (e,i) => [.eval e (child ctx i),.capture]) ++ ts) := by
  induction args with
  | nil => exact hs
  | cons a args ih => exact .cons trivial (.cons trivial ih)

theorem ids_mem (hm : .freeReserved a ∈ ts) : a ∈ ReservedReadiness.ids ts := by
  induction ts with
  | nil => simp at hm
  | cons t ts ih =>
    cases t <;> simp_all [ReservedReadiness.ids]
    exact hm.imp (fun h => h) ih

/-- Existing reservations at Enter all belong to older invocations. This is
derived from reachable cleanup work and context freshness, not a provenance
assumption added to Conditional. -/
theorem before_enter_reservations (hr : Statements.Reachable p initial s)
    (htask : s.tasks = .enter name arity ctx::rest) (hm : r ∈ s.reservations) :
    r.invocation < s.nextInvocation := by
  have hp := (ReservedReadiness.reachable_invariant hr).2.2.1
  rw [htask] at hp
  change ReservedReadiness.ids rest = [] at hp
  obtain ⟨t,ht,hc⟩ := ReservationAccounted.reachable_accounted hr r hm
  cases t
  all_goals simp only [ReservationAccounted.Cleans] at hc
  all_goals try contradiction
  · rename_i bid inner outer
    obtain ⟨hi,_⟩ := hc
    have hb := Scopes.reachable_contexts_bound (ctx := inner) hr ht (by simp [Scopes.contexts])
    omega
  · rw [htask] at ht
    rcases List.mem_cons.mp ht with he | ht
    · cases he
    have hb := ids_mem ht
    rw [hp] at hb
    contradiction

end Full.Demand.RegionWork
