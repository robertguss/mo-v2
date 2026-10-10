import Full.Proofs.Residual
import Full.Proofs.BindingIdentity
import Full.Proofs.PlainTyping

namespace Full.Proofs.CountedTyping
open Counted

/-- A slot has both the runtime kind and the immutable value kind. This does
not assert read-back, ownership, or equality of numeric payloads. -/
def SlotTyped (v : Slot) (k : Kind) : Prop :=
  v.raw.kind = k ∧ v.value.kind = k

/-- Lexical lookup uses immutable binding data, not the mutable holding status.
The static environment may omit names not used by the source checker. -/
def EnvTyped (bs : List Binding) (env : Env) (static : List (String × Kind)) : Prop :=
  ∀ x k, Trial.lookupKind static x = some k →
    ∃ id b, env.find? (fun q => q.1 == x) = some (x,id) ∧
      bs.find? (fun b => b.record.id == id) = some b ∧
      SlotTyped ⟨b.record.value,b.value⟩ k

theorem slot_kind_eq (h : SlotTyped v k) : v.raw.kind = v.value.kind :=
  h.1.trans h.2.symm

theorem env_variable (p : Program) (h : EnvTyped bs env static)
    (hc : check p.functions static (.var x) = .ok k) :
    ∃ id b, env.find? (fun q => q.1 == x) = some (x,id) ∧
      bs.find? (fun b => b.record.id == id) = some b ∧
      SlotTyped ⟨b.record.value,b.value⟩ k := by
  cases hl : Trial.lookupKind static x with
  | none => simp [check, hl] at hc
  | some j =>
    simp [check, hl] at hc
    subst j
    exact h x k hl

/-- Saved lexical checks survive all successful transfers, including moving
and releasing a binding. No heap invariant or future transition is used. -/
theorem transition_env (ht : Counted.transition p s = .ok c)
    (h : EnvTyped s.bindings env static) : EnvTyped c.state.bindings env static := by
  intro x k hk
  obtain ⟨id,b,he,hb,hkind⟩ := h x k hk
  have hd := BindingIdentity.transition_lookup ht
    (by simpa [hb] :
      (s.bindings.find? (fun b => b.record.id == id)).map BindingIdentity.data =
        some (BindingIdentity.data b))
  cases hc : c.state.bindings.find? (fun b => b.record.id == id) with
  | none => simp [hc] at hd
  | some b' =>
    have heq : BindingIdentity.data b' = BindingIdentity.data b := by
      simpa [hc] using hd
    have hr : b'.record.value = b.record.value := congrArg (fun d => d.2.2.1) heq
    have hv : b'.value = b.value := congrArg (fun d => d.2.2.2) heq
    exact ⟨id,b',he,hc,by simpa [SlotTyped,hr,hv] using hkind⟩

/-- Static residual work. The kind stack is in machine order (top first),
whereas call signatures are in source order. Frame kinds record the expected
return kind independently of the operand stack. -/
inductive WorkTyped (p : Program) (bs : List Binding) (out : Kind) :
    List Task → List Kind → List (Nat × Kind) → Prop where
  | done : WorkTyped p bs out [] [out] []
  | finish : WorkTyped p bs out [.finish] [out] []
  | start : WorkTyped p bs out ts ks fs → WorkTyped p bs out (.start::ts) ks fs
  | capture : WorkTyped p bs out ts ks fs → WorkTyped p bs out (.capture::ts) ks fs
  | eval (henv : EnvTyped bs ctx.env static)
      (hc : check p.functions static e = .ok k)
      (rest : WorkTyped p bs out ts (k::ks) fs) :
      WorkTyped p bs out (.eval e ctx::ts) ks fs
  | primitive (rest : WorkTyped p bs out ts (PlainTyping.resultKind op::ks) fs) :
      WorkTyped p bs out (.primitive op ctx::ts)
        (PlainTyping.rightKind op::.number::ks) fs
  | bind (henv : EnvTyped bs ctx.env static)
      (hc : check p.functions ((x,k)::static) body = .ok result)
      (rest : WorkTyped p bs out ts (result::ks) fs) :
      WorkTyped p bs out (.bind x body ctx::ts) (k::ks) fs
  | chooseIf (henv : EnvTyped bs ctx.env static)
      (hy : check p.functions static yes = .ok result)
      (hn : check p.functions static no = .ok result)
      (rest : WorkTyped p bs out ts (result::ks) fs) :
      WorkTyped p bs out (.chooseIf yes no ctx::ts) (.bool::ks) fs
  | chooseMatch (henv : EnvTyped bs ctx.env static)
      (hn : check p.functions static nil = .ok result)
      (hc : check p.functions ((t,.list)::(h,.number)::static) body = .ok result)
      (rest : WorkTyped p bs out ts (result::ks) fs) :
      WorkTyped p bs out (.chooseMatch nil h t body ctx::ts) (.list::ks) fs
  | decompose (henv : EnvTyped bs ctx.env static)
      (hc : check p.functions ((t,.list)::(h,.number)::static) body = .ok result)
      (rest : WorkTyped p bs out ts (result::ks) fs) :
      WorkTyped p bs out (.decompose h t body bid ctx::ts) (.list::ks) fs
  | matchComplete : WorkTyped p bs out ts ks fs →
      WorkTyped p bs out (.matchComplete ctx::ts) ks fs
  | branchStart : WorkTyped p bs out ts ks fs →
      WorkTyped p bs out (.branchStart ctx::ts) ks fs
  | branchResult : WorkTyped p bs out ts (k::ks) fs →
      WorkTyped p bs out (.branchResult bid inner outer::ts) (k::ks) fs
  | handoffMatch : WorkTyped p bs out ts (k::ks) fs →
      WorkTyped p bs out (.handoffMatch ctx::ts) (k::ks) fs
  | handoff : WorkTyped p bs out ts ks fs → WorkTyped p bs out (.handoff::ts) ks fs
  | enter (hf : signature p.functions name = some f)
      (ha : arity = f.params.length)
      (rest : WorkTyped p bs out ts (f.result::ks) fs) :
      WorkTyped p bs out (.enter name arity ctx::ts)
        ((f.params.map Prod.snd).reverse ++ ks) fs
  | returning (hf : signature p.functions frame.name = some f)
      (rest : WorkTyped p bs out ts (f.result::ks) fs) :
      WorkTyped p bs out (.returning frame ctx::ts) (f.result::ks) ((frame.id,f.result)::fs)
  | giveBinding : WorkTyped p bs out ts ks fs →
      WorkTyped p bs out (.giveBinding bid::ts) ks fs
  | givePending : WorkTyped p bs out ts ks fs →
      WorkTyped p bs out (.givePending::ts) (.list::ks) fs
  | free : WorkTyped p bs out ts ks fs → WorkTyped p bs out (.free addr::ts) ks fs
  | freeReserved : WorkTyped p bs out ts ks fs →
      WorkTyped p bs out (.freeReserved addr::ts) ks fs

/-- Edge kinds are necessary for Free, which can install an immutable tail as
a new list operand. This is a kind fact, not heap safety. -/
inductive SlotsTyped : List Slot → List Kind → Prop where
  | nil : SlotsTyped [] []
  | cons : SlotTyped v k → SlotsTyped vs ks → SlotsTyped (v::vs) (k::ks)

def StateTyped (p : Program) (out : Kind) (s : State) : Prop :=
  ∃ ks fs, SlotsTyped s.slots ks ∧
    s.frames.map Frame.id = fs.map Prod.fst ∧
    WorkTyped p s.bindings out s.tasks ks fs ∧
    ∀ edge ∈ s.edges, edge.2.kind = .list

theorem work_shape (h : WorkTyped p bs out ts ks fs) :
    Residual.Shape ts ks.length (fs.map Prod.fst) := by
  induction h <;> try simp only [List.length_cons,List.length_append,List.length_reverse,
    List.length_map,List.map_cons] at *
  all_goals first
    | solve | constructor; assumption
    | solve | exact .done
    | solve | exact .finish
    | rename_i hf ha hr ih
      rw [← ha]
      simpa [Nat.add_comm] using Residual.Shape.enter ih

theorem top_eval (h : WorkTyped p bs out (.eval e ctx::ts) ks fs) :
    ∃ static k, EnvTyped bs ctx.env static ∧ check p.functions static e = .ok k ∧
      WorkTyped p bs out ts (k::ks) fs := by
  cases h with | eval he hc hr => exact ⟨_,_,he,hc,hr⟩

theorem top_enter (h : WorkTyped p bs out (.enter name arity ctx::ts) ks fs) :
    ∃ f tail, signature p.functions name = some f ∧ arity = f.params.length ∧
      ks = (f.params.map Prod.snd).reverse ++ tail ∧
      WorkTyped p bs out ts (f.result::tail) fs := by
  cases h with | enter hf ha hr => exact ⟨_,_,hf,ha,rfl,hr⟩

theorem top_return (h : WorkTyped p bs out (.returning frame ctx::ts) ks fs) :
    ∃ f tail frames, signature p.functions frame.name = some f ∧
      ks = f.result::tail ∧ fs = (frame.id,f.result)::frames ∧
      WorkTyped p bs out ts (f.result::tail) frames := by
  cases h with | returning hf hr => exact ⟨_,_,_,hf,rfl,rfl,hr⟩

theorem transition_work_bindings (ht : Counted.transition p s = .ok c)
    (h : WorkTyped p s.bindings out ts ks fs) :
    WorkTyped p c.state.bindings out ts ks fs := by
  induction h
  all_goals first
    | solve | constructor
    | solve | constructor <;> first | assumption | exact transition_env ht (by assumption)

theorem slots_length (h : SlotsTyped vs ks) : vs.length = ks.length := by
  induction h with
  | nil => rfl
  | cons hv hs ih => simpa using ih

theorem state_shape (h : StateTyped p out s) :
    Residual.Shape s.tasks s.slots.length (s.frames.map Frame.id) := by
  obtain ⟨ks,fs,hslots,hframes,hwork,_⟩ := h
  rw [slots_length hslots,hframes]
  exact work_shape hwork

theorem advance_env (h : EnvTyped s.bindings env static)
    (ht : Counted.advance p n s = .ok t) : EnvTyped t.bindings env static := by
  induction n generalizing s with
  | zero => cases ht; exact h
  | succ n ih =>
    cases ha : s.answer with
    | some v => simp [Counted.advance,ha] at ht; subst t; exact h
    | none =>
      cases hc : Counted.transition p s with
      | error why => simp [Counted.advance,Counted.step,ha,hc] at ht
      | ok c =>
        simp [Counted.advance,Counted.step,ha,hc] at ht
        exact ih (s := commit c) (transition_env hc h) ht

theorem begin_binding_kinds (hb : Counted.begin p initial = .ok first)
    (hm : b ∈ first.bindings) :
    SlotTyped ⟨b.record.value,b.value⟩ b.record.value.kind := by
  have hk := (Initial.begin_binding_readable p initial first hb b hm).2.1
  exact ⟨rfl,hk.symm⟩

theorem begin_functions (hb : Counted.begin p initial = .ok first) :
    ∃ out, validate p (initial.inputs.map (fun a => (a.1,a.2.kind))) = .ok out ∧
      PlainTyping.FunctionsTyped p ∧
      check p.functions (initial.inputs.map (fun a => (a.1,a.2.kind))) p.main = .ok out := by
  unfold Counted.begin at hb
  obtain ⟨out,hv,_⟩ := PlainTyping.bind_ok _ _ _ |>.mp hb
  exact ⟨out,hv,(PlainTyping.validate_contract hv).1,
    (PlainTyping.validate_contract hv).2.2⟩

theorem advance_lookup_kind (ht : Counted.advance p n s = .ok t)
    (hb : s.bindings.find? (fun b => b.record.id == bid) = some b)
    (hk : SlotTyped ⟨b.record.value,b.value⟩ k) :
    ∃ b', t.bindings.find? (fun b => b.record.id == bid) = some b' ∧
      SlotTyped ⟨b'.record.value,b'.value⟩ k := by
  induction n generalizing s b with
  | zero => cases ht; exact ⟨b,hb,hk⟩
  | succ n ih =>
    cases ha : s.answer with
    | some v => simp [Counted.advance,ha] at ht; subst t; exact ⟨b,hb,hk⟩
    | none =>
      cases hc : Counted.transition p s with
      | error why => simp [Counted.advance,Counted.step,ha,hc] at ht
      | ok c =>
        simp [Counted.advance,Counted.step,ha,hc] at ht
        have hd := BindingIdentity.transition_lookup hc
          (by simp [hb] :
            (s.bindings.find? (fun b => b.record.id == bid)).map BindingIdentity.data =
              some (BindingIdentity.data b))
        cases hl : c.state.bindings.find? (fun b => b.record.id == bid) with
        | none => simp [hl] at hd
        | some b' =>
          have heq : BindingIdentity.data b' = BindingIdentity.data b := by
            simpa [hl] using hd
          have hr : b'.record.value = b.record.value := congrArg (fun d => d.2.2.1) heq
          have hv : b'.value = b.value := congrArg (fun d => d.2.2.2) heq
          exact ih (s := commit c) ht hl (by simpa [SlotTyped,hr,hv] using hk)

/-- Every initial binding retains both kinds throughout actual finite counted
execution, even after its holding status changes. -/
theorem reachable_initial_binding_kind
    (hb : Counted.begin p initial = .ok first)
    (ht : Counted.advance p n first = .ok s)
    (hl : first.bindings.find? (fun b => b.record.id == bid) = some b) :
    ∃ b', s.bindings.find? (fun b => b.record.id == bid) = some b' ∧
      SlotTyped ⟨b'.record.value,b'.value⟩ b.record.value.kind :=
  advance_lookup_kind ht hl (begin_binding_kinds hb (List.mem_of_find?_eq_some hl))

theorem binding_list_env (bs visible : List Binding)
    (hunique : (bs.map (fun b => b.record.id)).Nodup)
    (hkind : ∀ b ∈ visible, SlotTyped ⟨b.record.value,b.value⟩ b.record.value.kind)
    (hsub : ∀ b ∈ visible, b ∈ bs) :
    EnvTyped bs (visible.map (fun b => (b.record.name,b.record.id)))
      (visible.map (fun b => (b.record.name,b.record.value.kind))) := by
  induction visible with
  | nil => intro x k hk; simp [Trial.lookupKind] at hk
  | cons b visible ih =>
    intro x k hk
    by_cases he : b.record.name = x
    · simp [Trial.lookupKind, he] at hk
      subst k
      exact ⟨b.record.id,b,by simp [he],
        Initial.find_key_self bs (fun b => b.record.id) hunique b (hsub b (by simp)),
        hkind b (by simp)⟩
    · simp [Trial.lookupKind, he] at hk
      obtain ⟨bid,q,hq,hb,hk⟩ := ih
        (by intro b hb; exact hkind b (by simp [hb]))
        (by intro b hb; exact hsub b (by simp [hb])) x k hk
      exact ⟨bid,q,by simpa [he] using hq,hb,hk⟩

theorem env_reverse_static (h : EnvTyped bs env static.reverse)
    (hn : (static.map Prod.fst).Nodup) : EnvTyped bs env static := by
  intro x k hk
  apply h x k
  apply PlainTyping.mem_kind_lookup
  · rw [List.map_reverse]
    exact List.pairwise_reverse.mpr (hn.imp (fun h => Ne.symm h))
  · exact List.mem_reverse.mpr (PlainTyping.kind_lookup_mem _ hk)

theorem begin_input_kinds (hb : Counted.begin p initial = .ok first) :
    first.bindings.map (fun b => (b.record.name,b.record.value.kind)) =
      initial.inputs.map (fun a => (a.1,a.2.kind)) := by
  obtain ⟨_,_,bs,_,hbs,rfl⟩ := Initial.begin_shape p initial first hb
  have hm := Initial.mapM_ok_map hbs
    (fun a => (a.1.1,a.1.2.kind)) (fun b => (b.record.name,b.record.value.kind)) (by
      intro a b h
      simp only [Trial.Proofs.except_bind_eq_ok] at h
      obtain ⟨v,hr,hb⟩ := h
      cases Except.ok.inj hb
      rfl)
  rw [← hm]
  simpa only [List.map_map, Function.comp_def] using
    congrArg (List.map (fun a : String × Raw => (a.1,a.2.kind))) (List.zipIdx_map_fst 0 initial.inputs)

theorem begin_env (hb : Counted.begin p initial = .ok first) :
    EnvTyped first.bindings (first.bindings.reverse.map (fun b => (b.record.name,b.record.id)))
      (initial.inputs.map (fun a => (a.1,a.2.kind))) := by
  obtain ⟨out,hv,_,_⟩ := begin_functions hb
  apply env_reverse_static
  · have he := binding_list_env first.bindings first.bindings.reverse
      (by rw [BindingIdentity.begin_ids hb]; exact List.nodup_range)
      (by intro b hm; exact begin_binding_kinds hb (List.mem_reverse.mp hm))
      (by intro b hm; exact List.mem_reverse.mp hm)
    simpa only [List.map_reverse, begin_input_kinds hb] using he
  · exact PlainTyping.dup_none_nodup _ (PlainTyping.validate_contract hv).2.1

theorem work_dead_prefix (h : WorkTyped p bs out ts ks fs) (bindings : List Binding)
    (env : Env) (future : List Task) :
    WorkTyped p bs out (dead bindings env future ++ ts) ks fs := by
  obtain ⟨ids,hi⟩ := SimulationInitial.dead_is_prefix bindings env future
  rw [hi]
  clear hi
  induction ids with
  | nil => exact h
  | cons bid ids ih => exact .giveBinding ih

theorem begin_typed (hb : Counted.begin p initial = .ok first) :
    ∃ out, PlainTyping.FunctionsTyped p ∧ StateTyped p out first := by
  obtain ⟨out,hv,hfunctions,hmain⟩ := begin_functions hb
  have he := begin_env hb
  obtain ⟨_,edges,bs,hedges,hbs,rfl⟩ := Initial.begin_shape p initial first hb
  refine ⟨out,hfunctions,[],[],.nil,rfl,?_,?_⟩
  · exact work_dead_prefix (.start (.eval he hmain .finish)) _ _ _
  · intro edge hm
    obtain ⟨cell,hcell,hr⟩ := Initial.mapM_ok_mem hedges edge hm
    simp only [Trial.Proofs.except_bind_eq_ok] at hr
    obtain ⟨v,hread,he⟩ := hr
    cases Except.ok.inj he
    simp only [Trial.readBack, Trial.Proofs.except_bind_eq_ok] at hread
    obtain ⟨items,_,he⟩ := hread
    cases Except.ok.inj he
    rfl

theorem env_cons (id : Nat) (he : EnvTyped bs env static)
    (hb : bs.find? (fun b => b.record.id == id) = some b)
    (hk : SlotTyped ⟨b.record.value,b.value⟩ k) :
    EnvTyped bs ((x,id)::env) ((x,k)::static) := by
  intro y j hj
  by_cases hxy : x = y
  · simp [Trial.lookupKind,hxy] at hj
    subst j
    exact ⟨id,b,by simp [hxy],hb,hk⟩
  · simp [Trial.lookupKind,hxy] at hj
    obtain ⟨bid,q,hq,hb,hk⟩ := he y j hj
    exact ⟨bid,q,by simpa [hxy] using hq,hb,hk⟩

theorem fresh_lookup (bs : List Binding) (b : Binding)
    (hs : bs.map (fun b => b.record.id) = List.range next)
    (hi : next ≤ b.record.id) :
    (bs ++ b::more).find? (fun q => q.record.id == b.record.id) = some b := by
  have hn : bs.find? (fun q => q.record.id == b.record.id) = none := by
    apply List.find?_eq_none.mpr
    intro q hq
    have hlt : q.record.id < next := List.mem_range.mp
      (hs ▸ List.mem_map.mpr ⟨q,hq,rfl⟩)
    simp only [beq_iff_eq]
    omega
  simp [List.find?_append,hn]

theorem slots_take (h : SlotsTyped vs ks) (n : Nat) :
    SlotsTyped (vs.take n) (ks.take n) := by
  induction h generalizing n with
  | nil => simp; exact .nil
  | cons hv hs ih =>
    cases n with
    | zero => exact .nil
    | succ n => exact .cons hv (ih n)

theorem slots_drop (h : SlotsTyped vs ks) (n : Nat) :
    SlotsTyped (vs.drop n) (ks.drop n) := by
  induction h generalizing n with
  | nil => simp; exact .nil
  | cons hv hs ih =>
    cases n with
    | zero => exact .cons hv hs
    | succ n => exact ih n

theorem slots_append (ha : SlotsTyped as aks) (hb : SlotsTyped bs bks) :
    SlotsTyped (as ++ bs) (aks ++ bks) := by
  induction ha with
  | nil => exact hb
  | cons hv hs ih => exact .cons hv ih

theorem slots_reverse (h : SlotsTyped vs ks) : SlotsTyped vs.reverse ks.reverse := by
  induction h with
  | nil => exact .nil
  | cons hv hs ih =>
    simpa using slots_append ih (.cons hv .nil)

theorem slots_raw_kinds (h : SlotsTyped vs ks) : vs.map (fun v => v.raw.kind) = ks := by
  induction h with
  | nil => rfl
  | cons hv hs ih => simp [hv.1,ih]

theorem slots_value_kinds (h : SlotsTyped vs ks) : vs.map (fun v => v.value.kind) = ks := by
  induction h with
  | nil => rfl
  | cons hv hs ih => simp [hv.2,ih]

theorem commit_typed (h : StateTyped p out c.state) : StateTyped p out (commit c) := by
  exact h

theorem cons_tail_kind (h : Plain.primitive .cons a b = .ok v) : b.kind = .list := by
  cases a <;> cases b <;> simp_all [Plain.primitive,Trial.PlainValue.kind]

set_option maxHeartbeats 1000000 in
theorem transition_edges (ht : Counted.transition p s = .ok c)
    (hs : ∀ edge ∈ s.edges, edge.2.kind = .list) :
    ∀ edge ∈ c.state.edges, edge.2.kind = .list := by
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    cases task
    all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals try exact hs
    all_goals intro edge hm
    all_goals simp only [List.mem_filter,List.mem_cons] at hm
    all_goals first
      | exact hs edge hm.1
      | rcases hm with h | h
        · subst edge
          simp_all only [beq_iff_eq]
          apply cons_tail_kind
          assumption
        · exact hs edge h.1

theorem advance_edges (hs : ∀ edge ∈ s.edges, edge.2.kind = .list)
    (ht : Counted.advance p n s = .ok t) :
    ∀ edge ∈ t.edges, edge.2.kind = .list := by
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
        exact ih (s := commit c) (transition_edges hc hs) ht

theorem reachable_edges (hr : Statements.Reachable p initial s) :
    ∀ edge ∈ s.edges, edge.2.kind = .list := by
  obtain ⟨first,n,hb,hn⟩ := hr
  obtain ⟨out,_,ks,fs,_,_,_,he⟩ := begin_typed hb
  exact advance_edges he hn

theorem enter_slots (h : SlotsTyped vs (params.reverse ++ ks)) :
    SlotsTyped ((vs.take params.length).reverse) params ∧
      SlotsTyped (vs.drop params.length) ks := by
  constructor
  · have ht := slots_reverse (slots_take h params.length)
    simpa using ht
  · simpa using slots_drop h params.length

theorem fresh_env (he : EnvTyped (bs ++ b::more) env static)
    (hs : bs.map (fun b => b.record.id) = List.range next)
    (hi : next ≤ b.record.id) (hk : SlotTyped ⟨b.record.value,b.value⟩ k) :
    EnvTyped (bs ++ b::more) ((x,b.record.id)::env) ((x,k)::static) :=
  env_cons b.record.id he (fresh_lookup bs b hs hi) hk

theorem edge_slot (edges : List (Nat × Value))
    (hs : ∀ edge ∈ edges, edge.2.kind = .list)
    (he : edges.find? (fun q => q.1 == addr) = some (addr,tail)) :
    SlotTyped ⟨.list link,tail⟩ .list :=
  ⟨rfl,hs _ (List.mem_of_find?_eq_some he)⟩

theorem transition_free_typed (ht : Counted.transition p s = .ok c)
    (htask : s.tasks = .free addr::rest) (hs : StateTyped p out s) :
    StateTyped p out c.state := by
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

theorem transition_bind_typed (ht : Counted.transition p s = .ok c)
    (htask : s.tasks = .bind x body ctx::rest) (hs : StateTyped p out s)
    (hids : s.bindings.map (fun b => b.record.id) = List.range s.nextBinding) :
    StateTyped p out c.state := by
  obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
  have hw := transition_work_bindings ht hwork
  rw [htask] at hw
  cases hw with
  | bind he hc hr =>
    generalize hsl : s.slots = slots at hslots
    cases hslots with
    | cons hv htail =>
      simp only [Counted.transition,htask,hsl,bind,pure,Except.bind,Except.pure] at ht
      cases ht
      refine ⟨_,fs,htail,hframes,?_,hedges⟩
      apply work_dead_prefix
      apply WorkTyped.eval _ hc (.handoff hr)
      apply fresh_env he hids (by simp [makeBinding])
      simpa only [makeBinding] using hv

theorem primitive_kind (ht : Plain.primitive op a b = .ok v) :
    v.kind = PlainTyping.resultKind op := by
  cases op <;> cases a <;> cases b <;>
    simp_all [Plain.primitive,Trial.PlainValue.kind,PlainTyping.resultKind]
  all_goals cases ht; rfl

set_option maxHeartbeats 1000000 in
theorem transition_primitive_typed (ht : Counted.transition p s = .ok c)
    (htask : s.tasks = .primitive op ctx::rest) (hs : StateTyped p out s) :
    StateTyped p out c.state := by
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
          beq_self_eq_true, Bool.true_eq_false,↓reduceIte] at ht
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

theorem env_two (he : EnvTyped (bs ++ [a,b]) env static)
    (hu : ((bs ++ [a,b]).map (fun b => b.record.id)).Nodup)
    (ha : SlotTyped ⟨a.record.value,a.value⟩ k)
    (hb : SlotTyped ⟨b.record.value,b.value⟩ j) :
    EnvTyped (bs ++ [a,b]) ((b.record.name,b.record.id)::(a.record.name,a.record.id)::env)
      ((b.record.name,j)::(a.record.name,k)::static) :=
  env_cons b.record.id (env_cons a.record.id he
    (Initial.find_key_self _ _ hu a (by simp)) ha)
    (Initial.find_key_self _ _ hu b (by simp)) hb

set_option maxHeartbeats 1000000 in
theorem transition_decompose_typed (ht : Counted.transition p s = .ok c)
    (htask : s.tasks = .decompose head tail body bid ctx::rest)
    (hs : StateTyped p out s)
    (hids : s.bindings.map (fun b => b.record.id) = List.range s.nextBinding) :
    StateTyped p out c.state := by
  obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
  have hw := transition_work_bindings ht hwork
  have hnewids := BindingIdentity.transition_ids hids ht
  have huniq : (c.state.bindings.map (fun b => b.record.id)).Nodup := by
    rw [hnewids]; exact List.nodup_range
  have hedge := transition_edges ht hedges
  rw [htask] at hw
  cases hw with
  | decompose he hc hr =>
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
            .givePending (.matchComplete (.branchStart (.eval he' hc (.branchResult hr)))),hedge⟩
        | exact ⟨_,fs,htail,hframes,
            .giveBinding (.branchStart (.eval he' hc (.branchResult hr))),hedge⟩
        | exact ⟨_,fs,htail,hframes,.branchStart (.eval he' hc (.branchResult hr)),hedge⟩

theorem slots_member_kind (hs : SlotsTyped vs ks) (hm : v ∈ vs) :
    v.raw.kind = v.value.kind := by
  induction hs with
  | nil => simp at hm
  | cons hv hs ih =>
    rcases List.mem_cons.mp hm with rfl | hm
    · exact slot_kind_eq hv
    · exact ih hm

theorem value_lookup_binding (visible : List Binding)
    (hv : Trial.lookupVal (visible.map (fun b => (b.record.name,b.value))) x = some v) :
    ∃ b ∈ visible, (visible.map (fun b => (b.record.name,b.record.id))).find?
      (fun q => q.1 == x) = some (x,b.record.id) ∧ b.value = v := by
  induction visible with
  | nil => simp [Trial.lookupVal] at hv
  | cons b visible ih =>
    by_cases he : b.record.name = x
    · simp [Trial.lookupVal,he] at hv
      exact ⟨b,by simp,by simp [he],hv⟩
    · simp [Trial.lookupVal,he] at hv
      obtain ⟨q,hq,hl,hv⟩ := ih hv
      exact ⟨q,by simp [hq],by simpa [he] using hl,hv⟩

/-- The checked callee environment already resolves parameter shadowing.
Lifting those exact lookups avoids imposing another name-order convention. -/
theorem env_from_values {visible : List Binding} (he : PlainTyping.EnvTyped static
    (visible.map (fun b => (b.record.name,b.value))))
    (hu : (bs.map (fun b => b.record.id)).Nodup)
    (hsub : ∀ b ∈ visible, b ∈ bs)
    (hk : ∀ b ∈ visible, b.record.value.kind = b.value.kind) :
    EnvTyped bs (visible.map (fun b => (b.record.name,b.record.id))) static := by
  intro x k hl
  obtain ⟨v,hv,hkind⟩ := he x k hl
  obtain ⟨b,hb,hfind,hvalue⟩ := value_lookup_binding visible hv
  have hbkind : b.value.kind = k := hvalue ▸ hkind
  exact ⟨b.record.id,b,hfind,Initial.find_key_self bs _ hu b (hsub b hb),
    (hk b hb).trans hbkind,hbkind⟩

theorem parameter_values (pairs : List ((String × Kind) × Slot))
    (next invocation : Nat) (name : String) :
    (pairs.zipIdx.map (fun (((x,_),v),i) =>
      makeBinding (next+i) x v invocation s!"{name}/parameter/{x}")).map
        (fun b => (b.record.name,b.value)) = pairs.map (fun q => (q.1.1,q.2.value)) := by
  have h := List.zipIdx_map_fst 0 pairs
  simpa only [List.map_map,Function.comp_def,makeBinding] using
    congrArg (List.map (fun q : (String × Kind) × Slot => (q.1.1,q.2.value))) h

theorem parameter_zip_values (params : List (String × Kind)) (args : List Slot) :
    (params.zip args).map (fun q => (q.1.1,q.2.value)) =
      (params.map Prod.fst).zip (args.map Slot.value) := by
  induction params generalizing args with
  | nil => simp
  | cons p params ih => cases args <;> simp [ih]

theorem transition_enter_typed (hp : PlainTyping.FunctionsTyped p)
    (ht : Counted.transition p s = .ok c)
    (htask : s.tasks = .enter name arity ctx::rest) (hs : StateTyped p out s)
    (hids : s.bindings.map (fun b => b.record.id) = List.range s.nextBinding) :
    StateTyped p out c.state := by
  obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
  have hw := transition_work_bindings ht hwork
  have hnewids := BindingIdentity.transition_ids hids ht
  have huniq : (c.state.bindings.map (fun b => b.record.id)).Nodup := by
    rw [hnewids]; exact List.nodup_range
  rw [htask] at hw
  cases hw with
  | enter hf ha hr =>
    rename_i f ks
    subst arity
    obtain ⟨hargs,hrest⟩ := enter_slots hslots
    simp only [List.length_map] at hargs hrest
    obtain ⟨hbody,henv⟩ := hp name f hf
    have he := henv (((s.slots.take f.params.length).reverse).map Slot.value)
      (by simpa only [List.map_map,Function.comp_def] using slots_value_kinds hargs)
    simp only [Counted.transition,htask,hf,bind,pure,Except.bind,Except.pure] at ht
    repeat' first | split at ht | cases ht | contradiction
    refine ⟨_,(s.nextInvocation,f.result)::fs,hrest,by simp [hframes],?_,hedges⟩
    apply work_dead_prefix
    apply WorkTyped.eval _ hbody (.returning hf hr)
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

theorem work_arguments (args : List Expr) (index : Nat) (ctx : Context)
    (he : EnvTyped bs ctx.env static)
    (ha : args.mapM (check p.functions static) = .ok kinds)
    (hr : WorkTyped p bs out ts (kinds.reverse ++ ks) fs) :
    WorkTyped p bs out
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
    apply WorkTyped.eval (ctx := child ctx index) he hk
    apply WorkTyped.capture
    apply ih (index+1) hrest
    simpa only [List.reverse_cons,List.append_assoc,List.singleton_append] using hr

set_option maxHeartbeats 1000000 in
theorem transition_eval_typed (ht : Counted.transition p s = .ok c)
    (htask : s.tasks = .eval e ctx::rest) (hs : StateTyped p out s) :
    StateTyped p out c.state := by
  obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
  rw [htask] at hwork
  cases hwork with
  | eval henv he hr =>
    rename_i static k
    have hr' := transition_work_bindings ht hr
    cases e with
    | num n | bool b | nil =>
      simp only [check,PlainTyping.pure_eq,Except.ok.injEq] at he
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
      rw [check.eq_def] at he
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
      exact .eval henv ha (.capture (.eval henv
        (by simpa [PlainTyping.rightKind,hkb] using hb) (.capture (.primitive hr'))))
    | letE x a b =>
      simp only [check,PlainTyping.bind_ok] at he
      obtain ⟨ka,ha,hb⟩ := he
      simp only [Counted.transition,htask,pure,Except.pure] at ht
      cases ht
      exact ⟨_,fs,hslots,hframes,.eval henv ha (.bind henv hb hr'),hedges⟩
    | ifE cond yes no =>
      simp only [check,PlainTyping.bind_ok] at he
      obtain ⟨kc,hc,u,hu,kt,hty,ke,hen,u',hu',hresult⟩ := he
      cases u; cases u'
      have hkc := (PlainTyping.expect_ok _ _ _).mp hu
      have hke := (PlainTyping.expect_ok _ _ _).mp hu'
      subst kc; subst ke
      simp only [PlainTyping.pure_eq,Except.ok.injEq] at hresult
      subst kt
      simp only [Counted.transition,htask,pure,Except.pure] at ht
      cases ht
      exact ⟨_,fs,hslots,hframes,.eval henv hc (.chooseIf henv hty hen hr'),hedges⟩
    | matchE scr nil head tail body =>
      simp only [check,PlainTyping.bind_ok] at he
      obtain ⟨kscr,hsc,u,hu,hrest⟩ := he
      cases u
      have hkscr := (PlainTyping.expect_ok _ _ _).mp hu
      subst kscr
      split at hrest
      · simp at hrest
      · simp only [PlainTyping.bind_ok] at hrest
        obtain ⟨kn,hn,kc,hc,u,hu,hresult⟩ := hrest
        cases u
        have hkc := (PlainTyping.expect_ok _ _ _).mp hu
        subst kc
        simp only [PlainTyping.pure_eq,Except.ok.injEq] at hresult
        subst kn
        simp only [Counted.transition,htask,pure,Except.pure] at ht
        cases ht
        exact ⟨_,fs,hslots,hframes,.eval henv hsc (.chooseMatch henv hn hc hr'),hedges⟩
    | call name args =>
      simp only [check] at he
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
          apply work_arguments args 0 ctx henv hargs
          rw [hkinds]
          exact .enter hf hlen hr'
        · simp at hrest

theorem work_reserved_prefix (rs : List Reservation) (hr : WorkTyped p bs out ts ks fs) :
    WorkTyped p bs out (rs.map (fun r => .freeReserved r.addr) ++ ts) ks fs := by
  induction rs with
  | nil => exact hr
  | cons r rs ih => exact .freeReserved ih

set_option maxHeartbeats 2000000 in
theorem transition_typed (hp : PlainTyping.FunctionsTyped p)
    (ht : Counted.transition p s = .ok c) (hs : StateTyped p out s)
    (hids : s.bindings.map (fun b => b.record.id) = List.range s.nextBinding) :
    StateTyped p out c.state := by
  cases htask : s.tasks with
  | nil => simp [Counted.transition,htask] at ht
  | cons task rest =>
    cases task with
    | eval e ctx => exact transition_eval_typed ht htask hs
    | primitive op ctx => exact transition_primitive_typed ht htask hs
    | bind x body ctx => exact transition_bind_typed ht htask hs hids
    | decompose head tail body bid ctx => exact transition_decompose_typed ht htask hs hids
    | enter name arity ctx => exact transition_enter_typed hp ht htask hs hids
    | free addr => exact transition_free_typed ht htask hs
    | start | capture | matchComplete ctx | branchStart ctx | handoff | handoffMatch ctx | freeReserved addr =>
      obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
      have hw := transition_work_bindings ht hwork
      rw [htask] at hw
      cases hw
      all_goals rename_i hr
      all_goals simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
      all_goals repeat' first | split at ht | cases ht | contradiction
      all_goals exact ⟨_,_,hslots,hframes,hr,hedges⟩
    | giveBinding id =>
      obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
      have hw := transition_work_bindings ht hwork
      rw [htask] at hw
      cases hw with
      | giveBinding hr =>
        simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
        repeat' first | split at ht | cases ht | contradiction
        all_goals first
          | exact ⟨_,_,hslots,hframes,hr,hedges⟩
          | exact ⟨_,_,hslots,hframes,.free hr,hedges⟩
    | givePending =>
      obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
      have hw := transition_work_bindings ht hwork
      rw [htask] at hw
      cases hw with
      | givePending hr =>
        generalize hsl : s.slots = slots at hslots
        cases hslots with
        | cons hv htail =>
          simp only [Counted.transition,htask,hsl,bind,pure,Except.bind,Except.pure] at ht
          repeat' first | split at ht | cases ht | contradiction
          all_goals first
            | exact ⟨_,_,htail,hframes,hr,hedges⟩
            | exact ⟨_,_,htail,hframes,.free hr,hedges⟩
    | branchResult bid inner outer =>
      obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
      rw [htask] at hwork
      cases hwork with
      | branchResult hr =>
        simp only [Counted.transition,htask,pure,Except.pure] at ht
        repeat' first | split at ht | cases ht | contradiction
        refine ⟨_,_,hslots,hframes,?_,hedges⟩
        rw [List.append_assoc]
        exact work_reserved_prefix _ (.handoffMatch hr)
    | returning frame ctx =>
      obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
      rw [htask] at hwork
      cases hwork with
      | returning hf hr =>
        simp only [Counted.transition,htask,pure,Except.pure] at ht
        repeat' first | split at ht | cases ht | contradiction
        refine ⟨_,_,hslots,?_,hr,hedges⟩
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
      | chooseIf he hy hn hr =>
        generalize hsl : s.slots = slots at hslots
        cases hslots with
        | cons hv htail =>
          simp only [Counted.transition,htask,hsl,pure,Except.pure] at ht
          repeat' first | split at ht | cases ht | contradiction
          all_goals refine ⟨_,_,htail,hframes,?_,hedges⟩
          all_goals apply work_dead_prefix
          all_goals first
            | exact .branchStart (.eval he hy (.handoff hr))
            | exact .branchStart (.eval he hn (.handoff hr))
    | chooseMatch nil head tail body ctx =>
      obtain ⟨ks,fs,hslots,hframes,hwork,hedges⟩ := hs
      rw [htask] at hwork
      cases hwork with
      | chooseMatch he hn hc hr =>
        generalize hsl : s.slots = slots at hslots
        cases hslots with
        | cons hv htail =>
          simp only [Counted.transition,htask,hsl,pure,Except.pure] at ht
          repeat' first | split at ht | cases ht | contradiction
          all_goals first
            | refine ⟨_,_,htail,hframes,?_,hedges⟩
            | refine ⟨_,_,.cons hv htail,hframes,?_,hedges⟩
          all_goals apply work_dead_prefix
          all_goals first
            | exact .branchStart (.eval he hn (.branchResult hr))
            | exact .decompose he hc hr

theorem advance_typed (hp : PlainTyping.FunctionsTyped p) (hs : StateTyped p out s)
    (hids : s.bindings.map (fun b => b.record.id) = List.range s.nextBinding)
    (ht : Counted.advance p n s = .ok t) : StateTyped p out t := by
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
        exact ih (s := commit c) (commit_typed (transition_typed hp hc hs hids))
          (BindingIdentity.transition_ids hids hc) ht

/-- Every finite successful execution prefix retains the source checker's
operand, lexical-environment, call-signature and return-kind certificates. -/
theorem reachable_typed (hr : Statements.Reachable p initial s) :
    ∃ out, PlainTyping.FunctionsTyped p ∧ StateTyped p out s := by
  obtain ⟨first,n,hb,hn⟩ := hr
  obtain ⟨out,hp,hs⟩ := begin_typed hb
  exact ⟨out,hp,advance_typed hp hs (BindingIdentity.begin_ids hb) hn⟩

end Full.Proofs.CountedTyping
