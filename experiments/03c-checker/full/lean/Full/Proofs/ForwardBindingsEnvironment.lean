import Full.Proofs.ForwardValue
import Full.Proofs.SimulationInitial

namespace Full.Proofs.ForwardBindings
open Counted

theorem fresh_absent (hr : Statements.Reachable p initial s) (bid : Nat)
    (hle : s.nextBinding ≤ bid) :
    s.bindings.find? (fun b => b.record.id == bid) = none := by
  apply List.find?_eq_none.mpr
  intro b hb
  have := BindingIdentity.reachable_bound hr hb
  simp only [beq_iff_eq]
  omega

theorem env_success (ht : Counted.transition p s = .ok c)
    (he : Control.env s names = .ok values) : Control.env c.state names = .ok values := by
  unfold Control.env at he ⊢
  induction names generalizing values with
  | nil => simpa using he
  | cons pair names ih =>
    simp only [List.mapM_cons, Trial.Proofs.except_bind_eq_ok] at he ⊢
    obtain ⟨v, hv, vs, hvs, hvalues⟩ := he
    refine ⟨v, ?_, vs, ih hvs, hvalues⟩
    cases hb : s.bindings.find? (fun b => b.record.id == pair.2) with
    | none => simp [hb] at hv
    | some b =>
      have hh := BindingIdentity.transition_lookup ht
        (bid := pair.2) (v := BindingIdentity.data b) (by simp [hb])
      cases hc : c.state.bindings.find? (fun b => b.record.id == pair.2) with
      | none => simp [hc] at hh
      | some d =>
        have hd : BindingIdentity.data d = BindingIdentity.data b := by simpa [hc] using hh
        have hdv : d.value = b.value := congrArg (fun x => x.2.2.2) hd
        simpa [hb, hc, hdv] using hv

theorem continuations_success (ht : Counted.transition p s = .ok c)
    (he : Control.continuations s n tasks values = .ok ks) :
    Control.continuations c.state n tasks values = .ok ks := by
  induction n generalizing tasks values ks with
  | zero => simp [Control.continuations] at he
  | succ n ih =>
    unfold Control.continuations at he ⊢
    split at he <;> simp_all only
    all_goals repeat' first | split at he | contradiction
    all_goals try simp only [Trial.Proofs.except_bind_eq_ok] at he ⊢
    all_goals repeat' first | obtain ⟨x, hx, he⟩ := he | cases he
    all_goals simp_all [env_success ht, ih]

end Full.Proofs.ForwardBindings
