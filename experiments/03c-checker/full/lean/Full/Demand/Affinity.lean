import Full.Demand.Births
import Full.Demand.Scopes
import Full.Proofs.CountedTyping

namespace Full.Demand.Affinity
open Counted Full.Proofs CountedTyping

/-- Typed saved work with syntactic affinity certificates for the target and
its descendants. Older caller continuations are deliberately unconstrained. -/
inductive Work (root : Nat) (p : Program) (bs : List Binding) (out : Kind) :
    List Task → List Kind → List (Nat × Kind) → Prop
  | done : Work root p bs out [] [out] []
  | finish : Work root p bs out [.finish] [out] []
  | start : Work root p bs out ts ks fs → Work root p bs out (.start::ts) ks fs
  | capture : Work root p bs out ts ks fs → Work root p bs out (.capture::ts) ks fs
  | eval (henv : EnvTyped bs ctx.env static)
      (hc : Full.check p.functions static e = .ok k)
      (ha : root ≤ ctx.invocation → Analyzed p.functions static e)
      (rest : Work root p bs out ts (k::ks) fs) :
      Work root p bs out (.eval e ctx::ts) ks fs
  | primitive (rest : Work root p bs out ts (PlainTyping.resultKind op::ks) fs) :
      Work root p bs out (.primitive op ctx::ts)
        (PlainTyping.rightKind op::.number::ks) fs
  | bind (henv : EnvTyped bs ctx.env static)
      (hc : Full.check p.functions ((x,k)::static) body = .ok result)
      (ha : root ≤ ctx.invocation → affine x k body = .ok () ∧
        Analyzed p.functions ((x,k)::static) body)
      (rest : Work root p bs out ts (result::ks) fs) :
      Work root p bs out (.bind x body ctx::ts) (k::ks) fs
  | chooseIf (henv : EnvTyped bs ctx.env static)
      (hy : Full.check p.functions static yes = .ok result)
      (hn : Full.check p.functions static no = .ok result)
      (ha : root ≤ ctx.invocation → Analyzed p.functions static yes ∧ Analyzed p.functions static no)
      (rest : Work root p bs out ts (result::ks) fs) :
      Work root p bs out (.chooseIf yes no ctx::ts) (.bool::ks) fs
  | chooseMatch (henv : EnvTyped bs ctx.env static)
      (hn : Full.check p.functions static nil = .ok result)
      (hc : Full.check p.functions ((t,.list)::(h,.number)::static) body = .ok result)
      (ha : root ≤ ctx.invocation → affine t .list body = .ok () ∧
        Analyzed p.functions static nil ∧ Analyzed p.functions ((t,.list)::(h,.number)::static) body)
      (rest : Work root p bs out ts (result::ks) fs) :
      Work root p bs out (.chooseMatch nil h t body ctx::ts) (.list::ks) fs
  | decompose (henv : EnvTyped bs ctx.env static)
      (hc : Full.check p.functions ((t,.list)::(h,.number)::static) body = .ok result)
      (ha : root ≤ ctx.invocation → affine t .list body = .ok () ∧
        Analyzed p.functions ((t,.list)::(h,.number)::static) body)
      (rest : Work root p bs out ts (result::ks) fs) :
      Work root p bs out (.decompose h t body bid ctx::ts) (.list::ks) fs
  | matchComplete : Work root p bs out ts ks fs → Work root p bs out (.matchComplete ctx::ts) ks fs
  | branchStart : Work root p bs out ts ks fs → Work root p bs out (.branchStart ctx::ts) ks fs
  | branchResult : Work root p bs out ts (k::ks) fs →
      Work root p bs out (.branchResult bid inner outer::ts) (k::ks) fs
  | handoffMatch : Work root p bs out ts (k::ks) fs →
      Work root p bs out (.handoffMatch ctx::ts) (k::ks) fs
  | handoff : Work root p bs out ts ks fs → Work root p bs out (.handoff::ts) ks fs
  | enter (hf : signature p.functions name = some f) (ha : arity = f.params.length)
      (hd : root ≤ ctx.invocation → f.demanded = true)
      (rest : Work root p bs out ts (f.result::ks) fs) :
      Work root p bs out (.enter name arity ctx::ts) ((f.params.map Prod.snd).reverse ++ ks) fs
  | returning (hf : signature p.functions frame.name = some f)
      (rest : Work root p bs out ts (f.result::ks) fs) :
      Work root p bs out (.returning frame ctx::ts) (f.result::ks) ((frame.id,f.result)::fs)
  | giveBinding : Work root p bs out ts ks fs → Work root p bs out (.giveBinding bid::ts) ks fs
  | givePending : Work root p bs out ts ks fs → Work root p bs out (.givePending::ts) (.list::ks) fs
  | free : Work root p bs out ts ks fs → Work root p bs out (.free addr::ts) ks fs
  | freeReserved : Work root p bs out ts ks fs → Work root p bs out (.freeReserved addr::ts) ks fs

theorem Work.typed (h : Work root p bs out ts ks fs) : WorkTyped p bs out ts ks fs := by
  induction h
  all_goals constructor <;> assumption

def StateCertified (root : Nat) (p : Program) (out : Kind) (s : State) : Prop :=
  ∃ ks fs, SlotsTyped s.slots ks ∧ s.frames.map Frame.id = fs.map Prod.fst ∧
    Work root p s.bindings out s.tasks ks fs ∧ ∀ edge ∈ s.edges, edge.2.kind = .list

theorem StateCertified.typed (h : StateCertified root p out s) : StateTyped p out s := by
  obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := h
  exact ⟨ks,fs,hslots,hframes,hwork.typed,hedges⟩

theorem transition_bindings (ht : Counted.transition p s = .ok c)
    (h : Work root p s.bindings out ts ks fs) : Work root p c.state.bindings out ts ks fs := by
  induction h
  all_goals constructor <;> first | assumption | exact transition_env ht (by assumption)

theorem dead_prefix (h : Work root p bs out ts ks fs) (bindings : List Binding)
    (env : Env) (future : List Task) : Work root p bs out (dead bindings env future ++ ts) ks fs := by
  obtain ⟨ids,hi⟩ := SimulationInitial.dead_is_prefix bindings env future
  rw [hi]
  clear hi
  induction ids with
  | nil => exact h
  | cons id ids ih => exact .giveBinding ih

theorem reserved_prefix (rs : List Reservation) (h : Work root p bs out ts ks fs) :
    Work root p bs out (rs.map (fun r => .freeReserved r.addr) ++ ts) ks fs := by
  induction rs with
  | nil => exact h
  | cons r rs ih => exact .freeReserved ih

theorem arguments (args : List Expr) (index : Nat) (ctx : Context)
    (he : EnvTyped bs ctx.env static)
    (ha : args.mapM (Full.check p.functions static) = .ok kinds)
    (hc : root ≤ ctx.invocation → ∀ e ∈ args, Analyzed p.functions static e)
    (hr : Work root p bs out ts (kinds.reverse ++ ks) fs) :
    Work root p bs out
      ((args.zipIdx index).flatMap (fun (a,i) => [.eval a (child ctx i),.capture]) ++ ts) ks fs := by
  induction args generalizing index kinds ks with
  | nil =>
    simp only [List.mapM_nil,PlainTyping.pure_eq,Except.ok.injEq] at ha
    subst kinds
    exact hr
  | cons a args ih =>
    simp only [List.mapM_cons,PlainTyping.bind_ok] at ha
    obtain ⟨k,hk,rest,hrest,hkinds⟩ := ha
    simp only [PlainTyping.pure_eq,Except.ok.injEq] at hkinds
    subst kinds
    apply Work.eval (ctx := child ctx index) he hk (fun hroot => hc hroot a (by simp))
    apply Work.capture
    apply ih (index+1) hrest (fun hroot e hm => hc hroot e (by simp [hm]))
    simpa only [List.reverse_cons,List.append_assoc,List.singleton_append] using hr

set_option maxHeartbeats 1000000 in
theorem transition_eval (ht : Counted.transition p s = .ok c)
    (htask : s.tasks = .eval e ctx::rest) (hs : StateCertified root p out s) :
    StateCertified root p out c.state := by
  obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
  rw [htask] at hwork
  cases hwork with
  | eval henv he hc hr =>
    rename_i static k
    have hr' := transition_bindings ht hr
    cases e with
    | num n | bool b | nil =>
      simp only [Full.check,PlainTyping.pure_eq,Except.ok.injEq] at he
      subst k
      simp only [Counted.transition,htask,pure,Except.pure] at ht
      cases ht
      exact ⟨_,fs,.cons ⟨rfl,rfl⟩ hslots,hframes,hr',hedges⟩
    | var x =>
      obtain ⟨id,b,hfind,hbinding,hkind⟩ := env_variable p henv he
      simp only [Counted.transition,htask,hfind,hbinding,bind,pure,Except.bind,Except.pure] at ht
      repeat' first | split at ht | cases ht | contradiction
      all_goals exact ⟨_,fs,.cons hkind hslots,hframes,hr',hedges⟩
    | bin op a b =>
      rw [Full.check.eq_def] at he
      simp only [PlainTyping.bind_ok] at he
      obtain ⟨ka,ha,u,hu,kb,hb,u',hu',hresult⟩ := he
      cases u; cases u'
      have hka := (PlainTyping.expect_ok _ _ _).mp hu
      have hkb := (PlainTyping.expect_ok _ _ _).mp hu'
      subst ka
      simp only [PlainTyping.pure_eq,Except.ok.injEq] at hresult
      subst k
      simp only [Counted.transition,htask,pure,Except.pure] at ht
      cases ht
      refine ⟨_,fs,hslots,hframes,?_,hedges⟩
      exact .eval henv ha (fun h => (analyzed_bin (hc h)).1)
        (.capture (.eval henv (by simpa [PlainTyping.rightKind,hkb] using hb)
          (fun h => (analyzed_bin (hc h)).2) (.capture (.primitive hr'))))
    | letE x a b =>
      simp only [Full.check,PlainTyping.bind_ok] at he
      obtain ⟨ka,ha,hb⟩ := he
      simp only [Counted.transition,htask,pure,Except.pure] at ht
      cases ht
      exact ⟨_,fs,hslots,hframes,
        .eval henv ha (fun h => (analyzed_let (hc h) ha).2.1)
          (.bind henv hb (fun h => ⟨(analyzed_let (hc h) ha).1,
            (analyzed_let (hc h) ha).2.2⟩) hr'),hedges⟩
    | ifE cond yes no =>
      simp only [Full.check,PlainTyping.bind_ok] at he
      obtain ⟨kc,hcond,u,hu,kt,hty,ke,hen,u',hu',hresult⟩ := he
      cases u; cases u'
      have hkc := (PlainTyping.expect_ok _ _ _).mp hu
      have hke := (PlainTyping.expect_ok _ _ _).mp hu'
      subst kc; subst ke
      simp only [PlainTyping.pure_eq,Except.ok.injEq] at hresult
      subst kt
      simp only [Counted.transition,htask,pure,Except.pure] at ht
      cases ht
      exact ⟨_,fs,hslots,hframes,
        .eval henv hcond (fun h => (analyzed_if (hc h)).1)
          (.chooseIf henv hty hen (fun h => (analyzed_if (hc h)).2) hr'),hedges⟩
    | matchE scr empty head tail body =>
      simp only [Full.check,PlainTyping.bind_ok] at he
      obtain ⟨kscr,hsc,u,hu,hrest⟩ := he
      cases u
      have hkscr := (PlainTyping.expect_ok _ _ _).mp hu
      subst kscr
      split at hrest
      · simp at hrest
      · simp only [PlainTyping.bind_ok] at hrest
        obtain ⟨kn,hn,kc,hcell,u,hu,hresult⟩ := hrest
        cases u
        have hkc := (PlainTyping.expect_ok _ _ _).mp hu
        subst kc
        simp only [PlainTyping.pure_eq,Except.ok.injEq] at hresult
        subst kn
        simp only [Counted.transition,htask,pure,Except.pure] at ht
        cases ht
        exact ⟨_,fs,hslots,hframes,
          .eval henv hsc (fun h => (analyzed_match (hc h)).2.1)
            (.chooseMatch henv hn hcell (fun h => ⟨(analyzed_match (hc h)).1,
              (analyzed_match (hc h)).2.2⟩) hr'),hedges⟩
    | call name args =>
      simp only [Full.check] at he
      cases hf : signature p.functions name with
      | none => simp [hf] at he
      | some f =>
        simp only [hf,PlainTyping.bind_ok] at he
        obtain ⟨kinds,hargs,hrest⟩ := he
        split at hrest
        · rename_i heq
          have hkinds : kinds = f.params.map Prod.snd := by simpa using heq
          simp only [PlainTyping.pure_eq,Except.ok.injEq] at hrest
          subst k
          have hlen := congrArg List.length (Initial.mapM_ok_map hargs
            (fun _ => ()) (fun _ => ()) (by intros; rfl))
          simp only [List.length_map,hkinds] at hlen
          simp only [Counted.transition,htask,pure,Except.pure] at ht
          cases ht
          refine ⟨_,fs,hslots,hframes,?_,hedges⟩
          dsimp only
          rw [List.append_assoc]
          apply arguments args 0 ctx henv hargs (fun h => (analyzed_call (hc h) hf).2)
          rw [hkinds]
          exact .enter hf hlen (fun h => (analyzed_call (hc h) hf).1) hr'
        · simp at hrest

theorem transition_bind (ht : Counted.transition p s = .ok c)
    (htask : s.tasks = .bind x body ctx::rest) (hs : StateCertified root p out s)
    (hids : s.bindings.map (fun b => b.record.id) = List.range s.nextBinding) :
    StateCertified root p out c.state := by
  obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
  have hw := transition_bindings ht hwork
  rw [htask] at hw
  cases hw with
  | bind he hc ha hr =>
    generalize hsl : s.slots = slots at hslots
    cases hslots with
    | cons hv htail =>
      simp only [Counted.transition,htask,hsl,bind,pure,Except.bind,Except.pure] at ht
      cases ht
      refine ⟨_,fs,htail,hframes,?_,hedges⟩
      apply dead_prefix
      apply Work.eval _ hc _ (.handoff hr)
      · apply fresh_env he hids (by simp [makeBinding])
        simpa only [makeBinding] using hv
      · exact fun h => (ha h).2

set_option maxHeartbeats 1000000 in
theorem transition_decompose (ht : Counted.transition p s = .ok c)
    (htask : s.tasks = .decompose head tail body bid ctx::rest)
    (hs : StateCertified root p out s)
    (hids : s.bindings.map (fun b => b.record.id) = List.range s.nextBinding) :
    StateCertified root p out c.state := by
  obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
  have hw := transition_bindings ht hwork
  have hnewids := BindingIdentity.transition_ids hids ht
  have huniq : (c.state.bindings.map (fun b => b.record.id)).Nodup := by
    rw [hnewids]; exact List.nodup_range
  have hedge := transition_edges ht hedges
  rw [htask] at hw
  cases hw with
  | decompose he hc ha hr =>
    generalize hsl : s.slots = slots at hslots
    cases hslots with
    | cons hv htail =>
      simp only [Counted.transition,htask,hsl,bind,pure,Except.bind,Except.pure] at ht
      repeat' first | split at ht | cases ht | contradiction
      all_goals
        have he' := env_two he huniq
          (show SlotTyped _ .number from ⟨rfl,rfl⟩) (show SlotTyped _ .list from ⟨rfl,rfl⟩)
      all_goals first
        | exact ⟨_,fs,.cons hv htail,hframes,
            .givePending (.matchComplete (.branchStart (.eval he' hc (fun h => (ha h).2)
              (.branchResult hr)))),hedge⟩
        | exact ⟨_,fs,htail,hframes,
            .giveBinding (.branchStart (.eval he' hc (fun h => (ha h).2) (.branchResult hr))),hedge⟩
        | exact ⟨_,fs,htail,hframes,
            .branchStart (.eval he' hc (fun h => (ha h).2) (.branchResult hr)),hedge⟩

theorem transition_enter (hp : PlainTyping.FunctionsTyped p)
    (ht : Counted.transition p s = .ok c)
    (htask : s.tasks = .enter name arity ctx::rest) (hs : StateCertified root p out s)
    (hids : s.bindings.map (fun b => b.record.id) = List.range s.nextBinding)
    (cert : ∀ f, signature p.functions name = some f → CertifiedFunction p.functions f) :
    StateCertified root p out c.state := by
  obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
  have hw := transition_bindings ht hwork
  have hnewids := BindingIdentity.transition_ids hids ht
  have huniq : (c.state.bindings.map (fun b => b.record.id)).Nodup := by
    rw [hnewids]; exact List.nodup_range
  rw [htask] at hw
  cases hw with
  | enter hf ha hd hr =>
    rename_i f ks
    subst arity
    obtain ⟨hargs,hrest⟩ := enter_slots hslots
    simp only [List.length_map] at hargs hrest
    obtain ⟨hbody,henv⟩ := hp name f hf
    obtain ⟨credits,hcert⟩ := (cert f hf).2
    have he := henv (((s.slots.take f.params.length).reverse).map Slot.value)
      (by simpa only [List.map_map,Function.comp_def] using slots_value_kinds hargs)
    simp only [Counted.transition,htask,hf,bind,pure,Except.bind,Except.pure] at ht
    repeat' first | split at ht | cases ht | contradiction
    refine ⟨_,(s.nextInvocation,f.result)::fs,hrest,by simp [hframes],?_,hedges⟩
    apply dead_prefix
    apply Work.eval _ hbody (fun _ => ⟨[],credits,hcert⟩) (.returning hf hr)
    apply env_from_values
    · simpa only [List.map_reverse,parameter_values,parameter_zip_values] using he
    · exact huniq
    · intro b hb
      exact List.mem_append_right _ (List.mem_reverse.mp hb)
    · intro b hb
      obtain ⟨⟨⟨⟨x,k⟩,v⟩,i⟩,hm,rfl⟩ := List.mem_map.mp (List.mem_reverse.mp hb)
      apply slots_member_kind hargs
      apply (List.of_mem_zip (a := (x,k)) (l₁ := f.params) ?_).2
      have hm' : ((x,k),v) ∈ (f.params.zip (s.slots.take f.params.length).reverse).zipIdx.map Prod.fst :=
        List.mem_map.mpr ⟨(((x,k),v),i),hm,rfl⟩
      simpa only [List.zipIdx_map_fst] using hm'

set_option maxHeartbeats 1000000 in
theorem transition_primitive (ht : Counted.transition p s = .ok c)
    (htask : s.tasks = .primitive op ctx::rest) (hs : StateCertified root p out s) :
    StateCertified root p out c.state := by
  obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
  rw [htask] at hwork
  cases hwork with
  | primitive hr =>
    generalize hsl : s.slots = slots at hslots
    cases hslots with
    | cons hb htail =>
      cases htail with
      | cons ha htail =>
        cases op
        all_goals simp only [Counted.transition,htask,hsl,bind,pure,Except.bind,Except.pure,
          beq_self_eq_true,↓reduceIte] at ht
        all_goals repeat' first | split at ht | cases ht | contradiction
        all_goals have hv := primitive_kind (by assumption)
        all_goals refine ⟨_,fs,.cons ⟨?_,hv⟩ htail,hframes,hr,?_⟩
        all_goals first
          | rfl
          | exact hedges
          | intro edge hm
            simp only [List.mem_cons,List.mem_filter] at hm
            rcases hm with he | he
            · subst edge; exact hb.2
            · exact hedges edge he.1

theorem transition_free (ht : Counted.transition p s = .ok c)
    (htask : s.tasks = .free addr::rest) (hs : StateCertified root p out s) :
    StateCertified root p out c.state := by
  obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
  rw [htask] at hwork
  cases hwork with
  | free hr =>
    simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
    repeat' first | split at ht | cases ht | contradiction
    all_goals have hk := hedges _ (List.mem_of_find?_eq_some (by assumption))
    all_goals first
      | exact ⟨.list::ks,fs,.cons ⟨rfl,hk⟩ hslots,hframes,.givePending hr,
          by intro e hm; exact hedges e (List.mem_filter.mp hm).1⟩
      | exact ⟨ks,fs,hslots,hframes,hr,
          by intro e hm; exact hedges e (List.mem_filter.mp hm).1⟩

set_option maxHeartbeats 2000000 in
/-- While the target frame is active, every newly entered callee is justified
by its own syntactic certificate. No recursive semantic summary is assumed. -/
theorem transition_certified (hp : PlainTyping.FunctionsTyped p) (table : CertifiedTable p)
    (hr : Statements.Reachable p initial s) (active : root ∈ s.frames.map Frame.id)
    (ht : Counted.transition p s = .ok c) (hs : StateCertified root p out s) :
    StateCertified root p out c.state := by
  have hids := BindingIdentity.reachable_ids hr
  cases htask : s.tasks with
  | nil => simp [Counted.transition,htask] at ht
  | cons task rest =>
    cases task with
    | eval e ctx => exact transition_eval ht htask hs
    | primitive op ctx => exact transition_primitive ht htask hs
    | bind x body ctx => exact transition_bind ht htask hs hids
    | decompose head tail body bid ctx => exact transition_decompose ht htask hs hids
    | free addr => exact transition_free ht htask hs
    | enter name arity ctx =>
      apply transition_enter hp ht htask hs hids
      intro f hf
      obtain ⟨ks,fs,_,_,hw,_⟩ := hs
      rw [htask] at hw
      cases hw with
      | enter hf' ha hd hw =>
        cases Option.some.inj (hf'.symm.trans hf)
        have hctx : ctx.invocation = (s.frames.map Frame.id).headD 0 := Scopes.head_scope hr htask
        exact table _ (List.mem_of_find?_eq_some hf) (hd (hctx ▸ Scopes.active_head_ge hr active))
    | start | capture | matchComplete ctx | branchStart ctx | handoff | handoffMatch ctx | freeReserved addr =>
      obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
      have hw := transition_bindings ht hwork
      rw [htask] at hw
      cases hw
      all_goals rename_i hrest
      all_goals simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
      all_goals repeat' first | split at ht | cases ht | contradiction
      all_goals exact ⟨_,_,hslots,hframes,hrest,hedges⟩
    | giveBinding id =>
      obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
      have hw := transition_bindings ht hwork
      rw [htask] at hw
      cases hw with
      | giveBinding hrest =>
        simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
        repeat' first | split at ht | cases ht | contradiction
        all_goals first
          | exact ⟨_,_,hslots,hframes,hrest,hedges⟩
          | exact ⟨_,_,hslots,hframes,.free hrest,hedges⟩
    | givePending =>
      obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
      have hw := transition_bindings ht hwork
      rw [htask] at hw
      cases hw with
      | givePending hrest =>
        generalize hsl : s.slots = slots at hslots
        cases hslots with
        | cons hv htail =>
          simp only [Counted.transition,htask,hsl,bind,pure,Except.bind,Except.pure] at ht
          repeat' first | split at ht | cases ht | contradiction
          all_goals first
            | exact ⟨_,_,htail,hframes,hrest,hedges⟩
            | exact ⟨_,_,htail,hframes,.free hrest,hedges⟩
    | branchResult bid inner outer =>
      obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
      rw [htask] at hwork
      cases hwork with
      | branchResult hrest =>
        simp only [Counted.transition,htask,pure,Except.pure] at ht
        repeat' first | split at ht | cases ht | contradiction
        refine ⟨_,_,hslots,hframes,?_,hedges⟩
        rw [List.append_assoc]
        exact reserved_prefix _ (.handoffMatch hrest)
    | returning frame ctx =>
      obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
      rw [htask] at hwork
      cases hwork with
      | returning hf hrest =>
        simp only [Counted.transition,htask,pure,Except.pure] at ht
        repeat' first | split at ht | cases ht | contradiction
        refine ⟨_,_,hslots,?_,hrest,hedges⟩
        have hf' := congrArg List.tail hframes
        simp_all only [List.map_cons,List.tail_cons,List.cons.injEq]
    | finish =>
      obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
      rw [htask] at hwork
      cases hwork
      simp only [Counted.transition,htask,pure,Except.pure] at ht
      repeat' first | split at ht | cases ht | contradiction
      exact ⟨_,_,hslots,hframes,.done,hedges⟩
    | chooseIf yes no ctx =>
      obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
      rw [htask] at hwork
      cases hwork with
      | chooseIf he hy hn ha hrest =>
        generalize hsl : s.slots = slots at hslots
        cases hslots with
        | cons hv htail =>
          simp only [Counted.transition,htask,hsl,pure,Except.pure] at ht
          repeat' first | split at ht | cases ht | contradiction
          all_goals refine ⟨_,_,htail,hframes,?_,hedges⟩
          all_goals apply dead_prefix
          all_goals first
            | exact .branchStart (.eval he hy (fun h => (ha h).1) (.handoff hrest))
            | exact .branchStart (.eval he hn (fun h => (ha h).2) (.handoff hrest))
    | chooseMatch empty head tail body ctx =>
      obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
      rw [htask] at hwork
      cases hwork with
      | chooseMatch he hn hc ha hrest =>
        generalize hsl : s.slots = slots at hslots
        cases hslots with
        | cons hv htail =>
          simp only [Counted.transition,htask,hsl,pure,Except.pure] at ht
          repeat' first | split at ht | cases ht | contradiction
          all_goals first
            | refine ⟨_,_,htail,hframes,?_,hedges⟩
            | refine ⟨_,_,.cons hv htail,hframes,?_,hedges⟩
          all_goals apply dead_prefix
          all_goals first
            | exact .branchStart (.eval he hn (fun h => (ha h).2.1) (.branchResult hrest))
            | exact .decompose he hc (fun h => ⟨(ha h).1,(ha h).2.2⟩) hrest

theorem Work.of_older (h : WorkTyped p bs out ts ks fs)
    (older : ∀ t ∈ ts, ∀ ctx ∈ Scopes.contexts t, ctx.invocation < root) :
    Work root p bs out ts ks fs := by
  induction h
  all_goals simp_all [Scopes.contexts]
  all_goals constructor <;> first
    | assumption
    | solve_by_elim (maxDepth := 4) [And.left, And.right]
    | (intro h; omega)

theorem before_entry_certified (hr : Statements.Reachable p initial s)
    (hs : StateTyped p out s) : StateCertified s.nextInvocation p out s := by
  obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
  exact ⟨ks,fs,hslots,hframes,Work.of_older hwork
    (fun _ hm _ hc => Scopes.reachable_contexts_bound hr hm hc),hedges⟩

/-- Affinity bound for the invocation's binding-ID suffix, including moved
and released records. The cutoff is the pre-Enter nextBinding counter. -/
def Bound (cut : Nat) (s : State) : Prop :=
  ∀ b ∈ s.bindings, cut ≤ b.record.id → b.record.value.kind = .list →
    futureOccurrences b.record.id s.tasks ≤ 1

theorem transition_old_bound (hr : Statements.Reachable p initial s)
    (ht : Counted.transition p s = .ok c) (hs : Bound cut s)
    (hm : b ∈ c.state.bindings) (hcut : cut ≤ b.record.id)
    (hk : b.record.value.kind = .list) (hold : b.record.id < s.nextBinding) :
    futureOccurrences b.record.id c.state.tasks ≤ 1 := by
  obtain ⟨old,hl,hid⟩ := BindingIdentity.reachable_lookup hr hold
  have hi := BindingIdentity.transition_ids (BindingIdentity.reachable_ids hr) ht
  have hu : (c.state.bindings.map (fun b => b.record.id)).Nodup := by
    rw [hi]; exact List.nodup_range
  have hb := Initial.find_key_self c.state.bindings (fun b => b.record.id) hu b hm
  have hd := BindingIdentity.transition_lookup ht
    (by simp [hl] : (s.bindings.find? (fun q => q.record.id == b.record.id)).map
      BindingIdentity.data = some (BindingIdentity.data old))
  rw [hb] at hd
  have hv : b.record.value = old.record.value := congrArg (fun d => d.2.2.1) (Option.some.inj hd)
  have ho := hs old (List.mem_of_find?_eq_some hl) (hid ▸ hcut) (hv ▸ hk)
  exact Nat.le_trans (transition_old_occurrences hold ht) (by simpa [hid] using ho)

set_option maxHeartbeats 2000000 in
theorem transition_new_bound (hr : Statements.Reachable p initial s)
    (active : root ∈ s.frames.map Frame.id) (table : CertifiedTable p)
    (ht : Counted.transition p s = .ok c) (hs : StateCertified root p out s)
    (hm : b ∈ c.state.bindings) (hnew : s.nextBinding ≤ b.record.id)
    (hk : b.record.value.kind = .list) : futureOccurrences b.record.id c.state.tasks ≤ 1 := by
  have hids := BindingIdentity.transition_ids (BindingIdentity.reachable_ids hr) ht
  have hlt : b.record.id < c.state.nextBinding := by
    apply List.mem_range.mp
    rw [← hids]
    exact List.mem_map.mpr ⟨b,hm,rfl⟩
  cases htask : s.tasks with
  | nil => simp [Counted.transition,htask] at ht
  | cons task rest =>
    have hscope := Scopes.head_scope hr htask
    have hge := Scopes.active_head_ge hr active
    cases task with
    | bind name body ctx =>
      have hctx : root ≤ ctx.invocation := by simpa only [Scopes.task] using hscope ▸ hge
      obtain ⟨ks,fs,hslots,_,hw,_⟩ := hs
      rw [htask] at hw
      cases hw with
      | bind he hc ha hrest =>
        generalize hsl : s.slots = slots at hslots
        cases hslots with
        | cons hv htail =>
          have hbirth := transition_bind_new_bound hr ht htask
          simp only [Counted.transition,htask,hsl,pure,Except.pure] at ht
          cases ht
          simp only [List.mem_append,List.mem_singleton] at hm
          rcases hm with hm | rfl
          · have := BindingIdentity.reachable_bound hr hm; omega
          · apply hbirth
            have heq := hv.1.symm.trans hk
            simpa only [heq] using (ha hctx).1
    | decompose head tail body bid ctx =>
      have hctx : root ≤ ctx.invocation := by simpa only [Scopes.task] using hscope ▸ hge
      obtain ⟨ks,fs,_,_,hw,_⟩ := hs
      rw [htask] at hw
      cases hw with
      | decompose he hc ha hrest =>
        have hbirth := transition_tail_new_bound hr ht htask (ha hctx).1
        simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
        repeat' first | split at ht | cases ht | contradiction
        all_goals simp only [List.mem_append,List.mem_cons,List.not_mem_nil,or_false] at hm
        all_goals rcases hm with hm | rfl | rfl
        all_goals first
          | exact hbirth
          | (have := BindingIdentity.reachable_bound hr hm; omega)
          | contradiction
    | enter name arity ctx =>
      have hctx : root ≤ ctx.invocation := by simpa only [Scopes.task] using hscope ▸ hge
      obtain ⟨ks,fs,_,_,hw,_⟩ := hs
      rw [htask] at hw
      cases hw with
      | enter hf ha hd hrest =>
        exact transition_parameters_new_bound hr ht htask hf
          (table _ (List.mem_of_find?_eq_some hf) (hd hctx)).1 hm hnew hk
    | eval e ctx =>
      cases e
      all_goals simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
      all_goals repeat' first | split at ht | cases ht | contradiction
      all_goals dsimp only at hlt
      all_goals omega
    | primitive op ctx =>
      cases op
      all_goals simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
      all_goals repeat' first | split at ht | cases ht | contradiction
      all_goals dsimp only at hlt
      all_goals omega
    | _ =>
      all_goals simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
      all_goals repeat' first | split at ht | cases ht | contradiction
      all_goals dsimp only at hlt
      all_goals omega

/-- Every list binding introduced by the invocation or its descendants stays
affine throughout their actual small-step execution. -/
theorem transition_bound (hr : Statements.Reachable p initial s)
    (active : root ∈ s.frames.map Frame.id) (table : CertifiedTable p)
    (ht : Counted.transition p s = .ok c) (hc : StateCertified root p out s)
    (hb : Bound cut s) : Bound cut c.state := by
  intro b hm hcut hk
  by_cases hold : b.record.id < s.nextBinding
  · exact transition_old_bound hr ht hb hm hcut hk hold
  · exact transition_new_bound hr active table ht hc hm (by omega) hk

end Full.Demand.Affinity
