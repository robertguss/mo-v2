import Full.Demand.Credits

namespace Full.Demand
open Full.Proofs.PlainTyping

/-- Only syntactic certificates, never a callee's semantic no-Create conclusion. -/
def CertifiedFunction (fs : List Function) (f : Function) : Prop :=
  (∀ param ∈ f.params, affine param.1 param.2 f.body = .ok ()) ∧
  ∃ credits, expression fs f.params [] f.body = .ok credits

def CertifiedTable (p : Program) : Prop :=
  ∀ f ∈ p.functions, f.demanded = true → CertifiedFunction p.functions f

private def inspectParameter (body : Expr) (param : String × Kind) :
    Except String (ForInStep PUnit) := do
  affine param.1 param.2 body
  pure (.yield PUnit.unit)

private theorem parameter_result (h : inspectParameter body param = .ok r) :
    r = .yield PUnit.unit ∧ affine param.1 param.2 body = .ok () := by
  simp only [inspectParameter, bind_ok] at h
  obtain ⟨u,hu,hr⟩ := h
  cases u
  exact ⟨by simpa using hr.symm, hu⟩

private theorem parameters_result (params : List (String × Kind))
    (h : forIn params PUnit.unit (fun param _ => inspectParameter body param) = .ok r) :
    ∀ param ∈ params, affine param.1 param.2 body = .ok () := by
  induction params with
  | nil => simp
  | cons param params ih =>
    rw [List.forIn_cons] at h
    simp only [bind_ok] at h
    obtain ⟨step,hs,ht⟩ := h
    obtain ⟨rfl,ha⟩ := parameter_result hs
    intro p hp
    rcases List.mem_cons.mp hp with rfl | hp
    · exact ha
    · exact ih ht p hp

private def inspectFunction (fs : List Function) (f : Function) :
    Except String (ForInStep PUnit) :=
  if f.demanded then do
    forIn f.params PUnit.unit (fun param _ => inspectParameter f.body param)
    let _ ← expression fs f.params [] f.body
    pure (.yield PUnit.unit)
  else pure (.yield PUnit.unit)

private theorem function_result (h : inspectFunction fs f = .ok r) :
    r = .yield PUnit.unit ∧ (f.demanded = true → CertifiedFunction fs f) := by
  unfold inspectFunction at h
  cases hd : f.demanded with
  | false => simp [hd] at h ⊢; exact h.symm
  | true =>
    simp only [hd, ↓reduceIte, bind_ok] at h
    obtain ⟨u,hu,credits,hc,hr⟩ := h
    exact ⟨by simpa using hr.symm, fun _ => ⟨parameters_result _ hu, credits, hc⟩⟩

private theorem functions_result (fs xs : List Function)
    (h : forIn xs PUnit.unit (fun f _ => inspectFunction fs f) = .ok r) :
    ∀ f ∈ xs, f.demanded = true → CertifiedFunction fs f := by
  induction xs with
  | nil => simp
  | cons f xs ih =>
    rw [List.forIn_cons] at h
    simp only [bind_ok] at h
    obtain ⟨step,hs,ht⟩ := h
    obtain ⟨rfl,hf⟩ := function_result hs
    intro g hg
    rcases List.mem_cons.mp hg with rfl | hg
    · exact hf
    · exact ih ht g hg

theorem accepts_certificates (h : accepts p name = true) : CertifiedTable p := by
  cases hc : check p name with
  | error why => simp [accepts, hc, Except.isOk, Except.toBool] at h
  | ok u =>
    unfold check at hc
    simp only [bind_ok] at hc
    obtain ⟨kind,hv,hc⟩ := hc
    split at hc
    · split at hc
      · simp at hc
      · change ((forIn p.functions PUnit.unit (fun f _ => inspectFunction p.functions f)) >>=
          fun _ => pure ()) = .ok u at hc
        obtain ⟨r,hr,_⟩ := (bind_ok _ _ _).mp hc
        exact functions_result p.functions p.functions hr
    · simp at hc

theorem accepts_target (h : accepts p name = true) :
    ∃ f, signature p.functions name = some f ∧ f.demanded = true := by
  cases hc : check p name with
  | error why => simp [accepts,hc,Except.isOk,Except.toBool] at h
  | ok u =>
    unfold check at hc
    simp only [bind_ok] at hc
    obtain ⟨kind,hv,hc⟩ := hc
    split at hc
    · rename_i f hf
      split at hc
      · simp at hc
      · exact ⟨f,hf,by simp_all⟩
    · simp at hc

theorem affine_list_bound (h : affine name .list body = .ok ()) :
    occurrences body [(name,some 0)] 0 ≤ 1 := by
  simp [affine] at h
  omega

/-- Source analysis exists for some credit stack. This projection retains
affinity and demanded-call checks, but makes no claim about runtime credits. -/
def Analyzed (fs : List Function) (static : List (String × Kind)) (e : Expr) : Prop :=
  ∃ before after, expression fs static before e = .ok after

theorem analyzed_bin (h : Analyzed fs static (.bin op a b)) :
    Analyzed fs static a ∧ Analyzed fs static b := by
  obtain ⟨before,after,h⟩ := h
  simp only [expression,bind_ok] at h
  obtain ⟨middle,ha,last,hb,_⟩ := h
  exact ⟨⟨before,middle,ha⟩,⟨middle,last,hb⟩⟩

theorem analyzed_let (h : Analyzed fs static (.letE x a b))
    (hk : Full.check fs static a = .ok k) :
    affine x k b = .ok () ∧ Analyzed fs static a ∧ Analyzed fs ((x,k)::static) b := by
  obtain ⟨before,after,h⟩ := h
  simp only [expression,hk,bind_value,bind_ok] at h
  obtain ⟨u,hu,middle,ha,hb⟩ := h
  cases u
  exact ⟨hu,⟨before,middle,ha⟩,⟨middle,after,hb⟩⟩

theorem analyzed_if (h : Analyzed fs static (.ifE c a b)) :
    Analyzed fs static c ∧ Analyzed fs static a ∧ Analyzed fs static b := by
  obtain ⟨before,after,h⟩ := h
  simp only [expression,bind_ok] at h
  obtain ⟨middle,hc,left,ha,right,hb,_⟩ := h
  exact ⟨⟨before,middle,hc⟩,⟨middle,left,ha⟩,⟨middle,right,hb⟩⟩

theorem analyzed_match (h : Analyzed fs static (.matchE s n head tail c)) :
    affine tail .list c = .ok () ∧ Analyzed fs static s ∧ Analyzed fs static n ∧
      Analyzed fs ((tail,.list)::(head,.number)::static) c := by
  obtain ⟨before,after,h⟩ := h
  simp only [expression,bind_ok] at h
  obtain ⟨u,hu,middle,hs,left,hn,right,hc,_⟩ := h
  cases u
  exact ⟨hu,⟨before,middle,hs⟩,⟨0::middle,left,hn⟩,⟨1::middle,right,hc⟩⟩

theorem fold_analyzed (xs : List α) (get : α → Expr)
    (h : xs.foldlM (fun credits x => expression fs static credits (get x)) before = .ok after) :
    ∀ x ∈ xs, Analyzed fs static (get x) := by
  induction xs generalizing before with
  | nil => simp
  | cons x xs ih =>
    simp only [List.foldlM_cons,bind_ok] at h
    obtain ⟨middle,hx,ht⟩ := h
    intro y hy
    rcases List.mem_cons.mp hy with rfl | hy
    · exact ⟨before,middle,hx⟩
    · exact ih ht y hy

theorem analyzed_call (h : Analyzed fs static (.call name args))
    (hf : signature fs name = some f) :
    f.demanded = true ∧ ∀ arg ∈ args, Analyzed fs static arg := by
  obtain ⟨before,after,h⟩ := h
  simp only [expression,hf] at h
  split at h
  · simp at h
  · constructor
    · simp_all
    · intro arg hm
      exact fold_analyzed args.attach Subtype.val h ⟨arg,hm⟩ (by simp)

end Full.Demand
