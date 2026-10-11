import Full.Plain

namespace Full.Proofs.PlainTyping
open Full Plain

@[simp] theorem pure_eq (a : α) : (pure a : Except String α) = .ok a := rfl
@[simp] theorem throw_eq (e : String) : (throw e : Except String α) = .error e := rfl
@[simp] theorem bind_error (e : String) (f : α → Except String β) :
    (Except.error e >>= f) = .error e := rfl
@[simp] theorem bind_value (a : α) (f : α → Except String β) :
    (Except.ok a >>= f) = f a := rfl

theorem bind_ok (x : Except String α) (f : α → Except String β) (b : β) :
    (x >>= f) = .ok b ↔ ∃ a, x = .ok a ∧ f a = .ok b := by
  cases x <;> simp

theorem expect_ok (s : String) (a b : Kind) :
    Trial.expectKind s a b = .ok () ↔ b = a := by
  simp [Trial.expectKind]

/-- A value environment realizes every lookup in its static environment.
Extra, inaccessible bindings are harmless. -/
def EnvTyped (ctx : List (String × Kind)) (env : Plain.Env) : Prop :=
  ∀ x k, Trial.lookupKind ctx x = some k →
    ∃ v, Trial.lookupVal env x = some v ∧ v.kind = k

theorem env_cons (h : EnvTyped ctx env) (v : Value) :
    EnvTyped ((x,v.kind)::ctx) ((x,v)::env) := by
  intro y k hk
  simp only [Trial.lookupKind] at hk
  by_cases he : x = y
  · simp [he] at hk; subst k
    exact ⟨v, by simp [Trial.lookupVal, he], rfl⟩
  · simp [he] at hk
    obtain ⟨w, hw, hkind⟩ := h y k hk
    exact ⟨w, by simp [Trial.lookupVal, he, hw], hkind⟩

def rightKind (op : Op) : Kind := if op == .cons then .list else .number
def resultKind : Op → Kind
  | .cons => .list | .add | .sub => .number | _ => .bool

/-- This contract checks bodies once, against signatures, not executions.
In particular it imposes no well-foundedness on the call graph. -/
def FunctionsTyped (p : Program) : Prop :=
  ∀ name f, signature p.functions name = some f →
    check p.functions f.params f.body = .ok f.result ∧
    ∀ args, args.map Trial.PlainValue.kind = f.params.map Prod.snd →
      EnvTyped f.params (((f.params.map Prod.fst).zip args).reverse)

inductive FrameTyped (p : Program) : Kont → Kind → Kind → Prop where
  | left (henv : EnvTyped ctx env) (hb : check p.functions ctx b = .ok (rightKind op)) :
      FrameTyped p (.left op b env) .number (resultKind op)
  | right (ha : a.kind = .number) :
      FrameTyped p (.right op a) (rightKind op) (resultKind op)
  | bind (henv : EnvTyped ctx env) (hb : check p.functions ((x,k)::ctx) b = .ok out) :
      FrameTyped p (.bind x b env) k out
  | choose (henv : EnvTyped ctx env)
      (ht : check p.functions ctx t = .ok out) (he : check p.functions ctx e = .ok out) :
      FrameTyped p (.choose t e env) .bool out
  | split (henv : EnvTyped ctx env)
      (hn : check p.functions ctx n = .ok out)
      (hc : check p.functions ((t,.list)::(h,.number)::ctx) c = .ok out) :
      FrameTyped p (.split n h t c env) .list out
  | arguments (henv : EnvTyped ctx env) (hf : signature p.functions name = some f)
      (hr : rest.mapM (check p.functions ctx) = .ok kinds)
      (hk : done.map Trial.PlainValue.kind ++ k::kinds = f.params.map Prod.snd) :
      FrameTyped p (.arguments name done rest env) k f.result
  | returning : FrameTyped p (.returning name) k k

inductive KontTyped (p : Program) : List Kont → Kind → Kind → Prop where
  | nil : KontTyped p [] k k
  | cons : FrameTyped p frame a b → KontTyped p ks b out →
      KontTyped p (frame::ks) a out

inductive StateTyped (p : Program) (out : Kind) : Plain.State → Prop where
  | eval (henv : EnvTyped ctx env) (he : check p.functions ctx e = .ok k)
      (hk : KontTyped p ks k out) : StateTyped p out ⟨.eval e env,ks⟩
  | value (hv : v.kind = k) (hk : KontTyped p ks k out) :
      StateTyped p out ⟨.value v,ks⟩
  | finished (hv : v.kind = out) : StateTyped p out ⟨.finished v,[]⟩

theorem not_stuck (h : StateTyped p out s) : ∀ why, s.focus ≠ .stuck why := by
  cases h <;> simp

theorem primitive_typed (ha : a.kind = .number) (hb : b.kind = rightKind op) :
    ∃ v, primitive op a b = .ok v ∧ v.kind = resultKind op := by
  cases op <;> cases a <;> cases b <;>
    simp_all [Trial.PlainValue.kind, rightKind, resultKind, primitive]

theorem enter_typed (hp : FunctionsTyped p) (hf : signature p.functions name = some f)
    (ha : args.map Trial.PlainValue.kind = f.params.map Prod.snd)
    (hk : KontTyped p ks f.result out) : StateTyped p out (enter p name args ks) := by
  obtain ⟨hb, he⟩ := hp name f hf
  simp only [enter, hf, ha, beq_self_eq_true, ↓reduceIte]
  exact .eval (he args ha) hb (.cons .returning hk)

theorem dup_none_nodup (ctx : List (String × Kind))
    (h : Trial.dupInput ctx = none) : (ctx.map Prod.fst).Nodup := by
  induction ctx with
  | nil => simp
  | cons a ctx ih =>
    rcases a with ⟨x,k⟩
    simp only [Trial.dupInput] at h
    split at h
    · contradiction
    · rename_i hn
      simp only [List.map_cons, List.nodup_cons]
      refine ⟨?_, ih h⟩
      simpa [List.any_eq_true, List.mem_map] using hn

theorem kind_lookup_mem (ctx : List (String × Kind))
    (h : Trial.lookupKind ctx x = some k) : (x,k) ∈ ctx := by
  induction ctx with
  | nil => simp [Trial.lookupKind] at h
  | cons a ctx ih =>
    rcases a with ⟨y,j⟩
    simp only [Trial.lookupKind] at h
    split at h
    · simp_all
    · exact List.mem_cons_of_mem _ (ih h)

theorem mem_kind_lookup (ctx : List (String × Kind))
    (hn : (ctx.map Prod.fst).Nodup) (hm : (x,k) ∈ ctx) :
    Trial.lookupKind ctx x = some k := by
  induction ctx with
  | nil => simp at hm
  | cons a ctx ih =>
    rcases a with ⟨y,j⟩
    simp only [List.map_cons,List.nodup_cons] at hn
    simp only [List.mem_cons] at hm
    rcases hm with he | hm
    · cases he; simp [Trial.lookupKind]
    · have hne : y ≠ x := by
        intro he; subst y
        exact hn.1 (List.mem_map.mpr ⟨(x,k),hm,rfl⟩)
      simp [Trial.lookupKind,hne,ih hn.2 hm]

theorem lookup_mapped (env : Plain.Env) (x : String) :
    Trial.lookupKind (env.map (fun a => (a.1,a.2.kind))) x =
      (Trial.lookupVal env x).map Trial.PlainValue.kind := by
  induction env with
  | nil => rfl
  | cons a env ih =>
    rcases a with ⟨y,v⟩
    simp only [List.map_cons,Trial.lookupKind,Trial.lookupVal]
    split <;> simp_all

theorem env_of_map (hm : env.map (fun a => (a.1,a.2.kind)) = ctx) :
    EnvTyped ctx env := by
  intro x k hk
  rw [← hm,lookup_mapped] at hk
  cases hv : Trial.lookupVal env x with
  | none => simp [hv] at hk
  | some v => exact ⟨v,rfl,by simpa [hv] using hk⟩

theorem env_of_reverse_map (hm : env.map (fun a => (a.1,a.2.kind)) = ctx.reverse)
    (hn : (ctx.map Prod.fst).Nodup) : EnvTyped ctx env := by
  intro x k hk
  have hmem := kind_lookup_mem ctx hk
  have hr : Trial.lookupKind ctx.reverse x = some k :=
    mem_kind_lookup _ (by
      rw [List.map_reverse]
      exact List.pairwise_reverse.mpr (hn.imp (fun h => Ne.symm h)))
      (by simpa using hmem)
  exact env_of_map hm x k hr

theorem zip_kinds (params : List (String × Kind)) (args : List Value)
    (h : args.map Trial.PlainValue.kind = params.map Prod.snd) :
    ((params.map Prod.fst).zip args).map (fun a => (a.1,a.2.kind)) = params := by
  induction params generalizing args with
  | nil =>
    have : args = [] := by simpa using h
    subst args; rfl
  | cons a params ih =>
    rcases a with ⟨x,k⟩
    cases args with
    | nil => simp at h
    | cons v args =>
      simp only [List.map_cons,List.cons.injEq] at h
      simp [h.1,ih args h.2]

private def inspectFunction (fs : List Function) (f : Function) :
    Except String (ForInStep Unit) := do
  if (Trial.dupInput f.params).isSome then throw s!"duplicate parameter: {f.name}"
  Trial.expectKind f.name f.result (← check fs f.params f.body)
  pure (.yield ())

private theorem inspect_contract (f : Function) :
    inspectFunction fs f = .ok r →
      r = .yield () ∧ Trial.dupInput f.params = none ∧
      check fs f.params f.body = .ok f.result := by
  intro h
  unfold inspectFunction at h
  cases hd : Trial.dupInput f.params with
  | some x => simp [hd] at h
  | none =>
    simp only [hd,Option.isSome_none,Bool.false_eq_true,↓reduceIte,bind_ok] at h
    obtain ⟨k,hk,u,hu,hr⟩ := h
    cases u
    have he := (expect_ok _ _ _).mp hu
    subst k
    exact ⟨by simpa using hr.symm,rfl,hk⟩

private theorem inspect_loop (fs xs : List Function)
    (h : (forIn xs () (fun f _ => inspectFunction fs f)) = .ok r) :
    ∀ f ∈ xs, Trial.dupInput f.params = none ∧ check fs f.params f.body = .ok f.result := by
  induction xs with
  | nil => simp
  | cons f xs ih =>
    rw [List.forIn_cons] at h
    simp only [bind_ok] at h
    obtain ⟨r',hf,hrest⟩ := h
    obtain ⟨hr,hd,hb⟩ := inspect_contract f hf
    subst r'
    intro g hg
    rcases List.mem_cons.mp hg with he | hg
    · subst g; exact ⟨hd,hb⟩
    · exact ih hrest g hg

/-- Executable validation supplies the non-recursive body and parameter contracts. -/
theorem validate_contract (hv : validate p inputs = .ok out) :
    FunctionsTyped p ∧ Trial.dupInput inputs = none ∧
      check p.functions inputs p.main = .ok out := by
  unfold validate at hv
  split at hv
  · repeat (first | contradiction | (split at hv) | (simp_all))
  · split at hv
    · repeat (first | contradiction | (split at hv) | (simp_all))
    · rename_i hi
      split at hv
      · simp at hv
      · change ((forIn p.functions () (fun f _ => inspectFunction p.functions f)) >>= fun _ =>
          check p.functions inputs p.main) = .ok out at hv
        obtain ⟨r,hloop,hmain⟩ := bind_ok _ _ _ |>.mp hv
        have hc := inspect_loop p.functions p.functions hloop
        refine ⟨?_,?_,hmain⟩
        · intro name f hf
          obtain ⟨hd,hb⟩ := hc f (List.mem_of_find?_eq_some hf)
          refine ⟨hb,?_⟩
          intro args ha
          apply env_of_reverse_map _ (dup_none_nodup _ hd)
          simp only [List.map_reverse,zip_kinds _ _ ha]
        · cases hd : Trial.dupInput inputs <;> simp_all

theorem step_preserves (hp : FunctionsTyped p) (hs : StateTyped p out s) :
    StateTyped p out (step p s) := by
  cases hs with
  | finished hv => exact .finished hv
  | eval henv he hk =>
    rename_i ctx env e k ks
    cases e with
    | num n =>
      simp [check] at he
      subst k
      exact .value rfl hk
    | bool b =>
      simp [check] at he
      subst k
      exact .value rfl hk
    | nil =>
      simp [check] at he
      subst k
      exact .value rfl hk
    | var x =>
      simp only [check] at he
      cases hl : Trial.lookupKind ctx x with
      | none => simp [hl] at he
      | some kind =>
        simp [hl] at he
        subst kind
        obtain ⟨v,hv,hkind⟩ := henv x k hl
        simpa [step,hv] using StateTyped.value hkind hk
    | bin op a b =>
      rw [check.eq_def] at he
      simp only [bind_ok] at he
      obtain ⟨ka,ha,hrest⟩ := he
      obtain ⟨u,hu,hrest⟩ := hrest
      cases u
      have hka := (expect_ok _ _ _).mp hu
      subst ka
      obtain ⟨kb,hb,hrest⟩ := hrest
      obtain ⟨u,hu,hresult⟩ := hrest
      cases u
      have hkb := (expect_ok _ _ _).mp hu
      simp only [pure_eq, Except.ok.injEq] at hresult
      subst k
      exact .eval henv ha (.cons (.left henv (by simpa [rightKind,hkb] using hb)) hk)
    | letE x a b =>
      simp only [check, bind_ok] at he
      obtain ⟨ka,ha,hb⟩ := he
      exact .eval henv ha (.cons (.bind henv hb) hk)
    | ifE c t e =>
      simp only [check, bind_ok] at he
      obtain ⟨kc,hc,u,hu,kt,ht,ke,he,u',hu',hresult⟩ := he
      cases u; cases u'
      have hkc := (expect_ok _ _ _).mp hu
      subst kc
      have hke := (expect_ok _ _ _).mp hu'
      subst ke
      simp only [pure_eq, Except.ok.injEq] at hresult
      subst kt
      exact .eval henv hc (.cons (.choose henv ht he) hk)
    | matchE s n h t c =>
      simp only [check, bind_ok] at he
      obtain ⟨kscr,hs,u,hu,hrest⟩ := he
      cases u
      have hkscr := (expect_ok _ _ _).mp hu
      subst kscr
      split at hrest
      · simp at hrest
      · simp only [bind_ok] at hrest
        obtain ⟨kn,hn,kc,hc,u,hu,hresult⟩ := hrest
        cases u
        have hkc := (expect_ok _ _ _).mp hu
        subst kc
        simp only [pure_eq, Except.ok.injEq] at hresult
        subst kn
        exact .eval henv hs (.cons (.split henv hn hc) hk)
    | call name args =>
      simp only [check] at he
      cases hf : signature p.functions name with
      | none => simp [hf] at he
      | some f =>
        simp only [hf, bind_ok] at he
        obtain ⟨kinds,hargs,hrest⟩ := he
        split at hrest
        · rename_i heq
          have heq' : kinds = f.params.map Prod.snd := by simpa using heq
          simp only [pure_eq, Except.ok.injEq] at hrest
          subst k
          cases args with
          | nil =>
            simp only [List.mapM_nil, pure_eq, Except.ok.injEq] at hargs
            exact enter_typed hp hf (hargs.trans heq') hk
          | cons a rest =>
            simp only [List.mapM_cons, bind_ok] at hargs
            obtain ⟨ka,ha,kr,hr,hlist⟩ := hargs
            simp at hlist
            exact .eval henv ha (.cons (.arguments henv hf hr
              (by simpa using hlist.trans heq')) hk)
        · simp at hrest
  | value hv hk =>
    rename_i ks k v
    cases hk with
    | nil => exact .finished hv
    | cons hf hk =>
      cases hf with
      | left henv hb => exact .eval henv hb (.cons (.right hv) hk)
      | right ha =>
        obtain ⟨w,hw,hkind⟩ := primitive_typed ha hv
        simpa [step,hw] using StateTyped.value hkind hk
      | bind henv hb =>
        exact .eval (by simpa [hv] using env_cons henv v) hb hk
      | choose henv ht he =>
        cases v <;> simp [Trial.PlainValue.kind] at hv
        rename_i b
        cases b
        · exact .eval henv he hk
        · exact .eval henv ht hk
      | split henv hn hc =>
        cases v <;> simp [Trial.PlainValue.kind] at hv
        rename_i xs
        cases xs with
        | nil => exact .eval henv hn hk
        | cons x xs => exact .eval (env_cons (env_cons henv (.num x)) (.list xs)) hc hk
      | arguments henv hf hr hargs =>
        rename_i ctx env name f kinds done rest
        cases rest with
        | nil =>
          simp only [List.mapM_nil, pure_eq, Except.ok.injEq] at hr
          subst kinds
          apply enter_typed hp hf _ hk
          simpa [List.map_append,hv] using hargs
        | cons a rest =>
          simp only [List.mapM_cons, bind_ok] at hr
          obtain ⟨ka,ha,kr,hr,hlist⟩ := hr
          simp at hlist
          subst kinds
          exact .eval henv ha (.cons (.arguments henv hf hr
            (by simpa [List.map_append,List.append_assoc,hv] using hargs)) hk)
      | returning => exact .value hv hk

/-- Preservation for any successfully validated program and any typed CEK state,
not just states reachable from main. -/
theorem validated_step_preserves (hv : validate p inputs = .ok mainKind)
    (hs : StateTyped p out s) : StateTyped p out (step p s) :=
  step_preserves (validate_contract hv).1 hs

/-- Progress here means exclusion of a stuck successor. Finished states are
allowed; no termination or recursive execution summary is assumed. -/
theorem progress (hp : FunctionsTyped p) (hs : StateTyped p out s) :
    ∀ why, (step p s).focus ≠ .stuck why :=
  not_stuck (step_preserves hp hs)

theorem advance_preserves (hp : FunctionsTyped p) (hs : StateTyped p out s) (n : Nat) :
    StateTyped p out (advance p n s) := by
  induction n generalizing s with
  | zero => exact hs
  | succ n ih => exact ih (step_preserves hp hs)

/-- Every finite prefix is safe, even for divergent and mutually recursive code. -/
theorem validated_advance_not_stuck (hv : validate p inputs = .ok mainKind)
    (hs : StateTyped p out s) (n : Nat) :
    ∀ why, (advance p n s).focus ≠ .stuck why :=
  not_stuck (advance_preserves (validate_contract hv).1 hs n)

theorem finished_kind (hs : StateTyped p out ⟨.finished v,ks⟩) :
    ks = [] ∧ v.kind = out := by
  cases hs with
  | finished hv => exact ⟨rfl,hv⟩

theorem validated_initial_typed (inputs : Plain.Env)
    (hv : validate p (inputs.map (fun a => (a.1,a.2.kind))) = .ok out) :
    StateTyped p out ⟨.eval p.main inputs.reverse,[]⟩ := by
  obtain ⟨_,hd,hmain⟩ := validate_contract hv
  apply StateTyped.eval _ hmain .nil
  apply env_of_reverse_map _ (dup_none_nodup _ hd)
  exact List.map_reverse

/-- Successful executable begin supplies both the body contract and the typed
initial state. The existential kind is precisely the validator's output. -/
theorem begin_typed (hb : Plain.begin p inputs = .ok s) :
    ∃ out, validate p (inputs.map (fun a => (a.1,a.2.kind))) = .ok out ∧
      FunctionsTyped p ∧ StateTyped p out s := by
  unfold Plain.begin at hb
  obtain ⟨out,hv,hs⟩ := (bind_ok _ _ _).mp hb
  simp only [pure_eq,Except.ok.injEq] at hs
  subst s
  exact ⟨out,hv,(validate_contract hv).1,validated_initial_typed inputs hv⟩

theorem begin_advance_not_stuck (hb : Plain.begin p inputs = .ok s) (n : Nat) :
    ∀ why, (advance p n s).focus ≠ .stuck why := by
  obtain ⟨_,_,hp,hs⟩ := begin_typed hb
  exact not_stuck (advance_preserves hp hs n)

end Full.Proofs.PlainTyping
