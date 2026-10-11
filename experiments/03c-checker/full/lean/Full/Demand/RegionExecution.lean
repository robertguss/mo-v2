import Full.Demand.RegionWork

namespace Full.Demand.RegionExecution
open Counted Full.Proofs Region

/-- Ownership needed above one fixed Return delimiter. Counts and pointers in
older caller slots/bindings are deliberately outside the local root clauses. -/
structure Resources (root cut : Nat) (region : List Nat)
    (saved : List Task) (frames : List Nat) (slots : List Slot) (s : State) : Prop where
  heap : Heap region s.mem
  bindings : ∀ b ∈ s.bindings, cut ≤ b.record.id → RawIn region b.record.value
  reservations : ∀ r ∈ s.reservations, root ≤ r.invocation → r.addr ∈ region
  cleanup : RegionWork.Clean saved cut region s.tasks
  stack : ∃ n, Framing.Shape saved frames s.tasks n (s.frames.map Frame.id) ∧
    s.slots.length = n+slots.length ∧ s.slots.drop n = slots ∧
    ∀ v ∈ s.slots.take n, RawIn region v.raw

theorem Resources.commit (h : Resources root cut region saved frames slots c.state) :
    Resources root cut region saved frames slots (Counted.commit c) :=
  ⟨h.heap,h.bindings,h.reservations,h.cleanup,h.stack⟩

theorem at_enter (hr : Statements.Reachable p initial s)
    (ht : Counted.transition p s = .ok c) (htask : s.tasks = .enter name arity ctx::rest)
    (hf : c.state.frames.head? = some f) (heap : Heap region c.state.mem)
    (hargs : ∀ v ∈ f.args, RawIn region v.raw) :
    Resources f.id s.nextBinding region (.returning f ctx::rest)
      (c.state.frames.map Frame.id) c.state.slots c.state := by
  have hframing := Framing.enter ht htask hf
  have hres := fun r hm => RegionWork.before_enter_reservations hr htask (r := r) hm
  have hids : ∀ b ∈ s.bindings, b.record.id < s.nextBinding :=
    fun _ hb => BindingIdentity.reachable_bound hr hb
  simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
  repeat' first | split at ht | cases ht | contradiction
  simp only [List.head?_cons,Option.some.injEq] at hf
  subst f
  refine ⟨heap,?_,?_,?_,0,hframing,by simp,by simp,by simp⟩
  · intro b hb hn
    rcases List.mem_append.mp hb with hb | hb
    · have := hids b hb; omega
    · obtain ⟨⟨pair,i⟩,hi,rfl⟩ := List.mem_map.mp hb
      exact hargs pair.2 (List.of_mem_zip (List.fst_mem_of_mem_zipIdx hi)).2
  · intro r hm hn
    have := hres r hm
    dsimp only at hn
    omega
  · apply RegionWork.dead_prefix
    · exact LocalIds.parameter_env _ _ _ _ (root := s.nextInvocation)
        (Nat.le_refl s.nextBinding) (Nat.le_refl s.nextInvocation)
    · exact .cons trivial .boundary

theorem at_entry (hr : Statements.Reachable p initial s)
    (hl : s.history.getLast?.map Action.name = some "Enter")
    (hf : s.frames.head? = some f) (hu : Statements.uniqueEntry s f = true) :
    ∃ cut ctx rest, Resources f.id cut (addresses s f) (.returning f ctx::rest)
      (s.frames.map Frame.id) s.slots s := by
  have heap := entry_heap hr hl hf hu
  have hargs : ∀ v ∈ f.args, RawIn (addresses s f) v.raw :=
    fun _ hv => entry_roots hr hl hf hv
  obtain ⟨before,c,hr',ht,ha,rfl⟩ := Events.last_enter hr hl
  obtain ⟨arity,ctx,rest,htask,_⟩ := Entry.source ht ha hf
  exact ⟨before.nextBinding,ctx,rest,(at_enter hr' ht htask hf heap hargs).commit⟩

theorem binding_status {bs : List Binding}
    (hb : ∀ b ∈ bs, cut ≤ b.record.id → RawIn region b.record.value)
    (bid : Nat) (status : Trial.BStatus) :
    ∀ b ∈ bs.map (fun b => if b.record.id == bid then
      { b with record := { b.record with status := status } } else b),
      cut ≤ b.record.id → RawIn region b.record.value := by
  intro b hm hn
  obtain ⟨old,hold,rfl⟩ := List.mem_map.mp hm
  by_cases he : old.record.id = bid
  all_goals simpa [he] using hb old hold (by simpa [he] using hn)

theorem variable_step (hr : Statements.Reachable p initial s)
    (active : root ∈ s.frames.map Frame.id) (hlocal : LocalIds.TasksOK root cut s.tasks)
    (bound : Affinity.Bound cut s) (hs : Resources root cut region saved frames slots s)
    (hne : s.tasks ≠ saved) (htask : s.tasks = .eval (.var name) ctx::rest)
    (ht : Counted.transition p s = .ok c) : Resources root cut region saved frames slots c.state := by
  obtain ⟨n,shape,hlen,hdrop,hroots⟩ := hs.stack
  obtain ⟨n',shape',hlen',hdrop'⟩ := Framing.transition shape hlen hdrop hne ht
  have hclean := ((htask ▸ hs.cleanup).head (htask ▸ hne)).2
  have hmem := LocalIds.variable_memory hr active hlocal bound htask ht
  have hc : LocalIds.ContextOK root cut ctx := hlocal (.eval (.var name) ctx)
    (by rw [htask]; exact List.mem_cons_self)
  have hscope : ctx.invocation = (s.frames.map Frame.id).headD 0 := Scopes.head_scope hr htask
  have hctx := hc (hscope ▸ Scopes.active_head_ge hr active)
  cases he : ctx.env.find? (fun q => q.1 == name) with
  | none => simp [Counted.transition,htask,he] at ht
  | some pair =>
    obtain ⟨spelling,id⟩ := pair
    cases hl : s.bindings.find? (fun b => b.record.id == id) with
    | none => simp [Counted.transition,htask,he,hl] at ht
    | some b =>
      have hid : b.record.id = id := by simpa using List.find?_some hl
      have hcut := hctx _ (List.mem_of_find?_eq_some he)
      have hin := hs.bindings b (List.mem_of_find?_eq_some hl) (hid ▸ hcut)
      simp only [Counted.transition,htask,he,hl,bind,pure,Except.bind,Except.pure] at ht
      repeat' first | split at ht | cases ht | contradiction
      all_goals
        have hn : n' = n+1 := by
          dsimp only at hlen'
          simp only [List.length_cons] at hlen'
          omega
        subst n'
      all_goals refine ⟨?_,?_,hs.reservations,hclean,n+1,shape',hlen',hdrop',?_⟩
      all_goals first
        | exact hmem ▸ hs.heap
        | exact hs.bindings
        | exact binding_status hs.bindings _ _
        | (intro v hv
           simp only [List.take_succ_cons,List.mem_cons] at hv
           rcases hv with rfl | hv
           · exact hin
           · exact hroots v hv)

set_option maxHeartbeats 2000000 in
theorem eval (hr : Statements.Reachable p initial s)
    (active : root ∈ s.frames.map Frame.id) (hlocal : LocalIds.TasksOK root cut s.tasks)
    (bound : Affinity.Bound cut s) (hs : Resources root cut region saved frames slots s)
    (hne : s.tasks ≠ saved) (htask : s.tasks = .eval e ctx::rest)
    (ht : Counted.transition p s = .ok c) : Resources root cut region saved frames slots c.state := by
  cases e with
  | var name => exact variable_step hr active hlocal bound hs hne htask ht
  | num n | bool b | nil =>
    obtain ⟨n,shape,hlen,hdrop,hroots⟩ := hs.stack
    obtain ⟨n',shape',hlen',hdrop'⟩ := Framing.transition shape hlen hdrop hne ht
    have hclean := ((htask ▸ hs.cleanup).head (htask ▸ hne)).2
    simp only [Counted.transition,htask,pure,Except.pure] at ht
    cases ht
    have hn : n' = n+1 := by
      dsimp only at hlen'
      simp only [List.length_cons] at hlen'
      omega
    subst n'
    refine ⟨hs.heap,hs.bindings,hs.reservations,hclean,n+1,shape',hlen',hdrop',?_⟩
    intro v hv
    simp only [List.take_succ_cons,List.mem_cons] at hv
    rcases hv with rfl | hv
    · simp [RawIn,Inspect.link]
    · exact hroots v hv
  | bin op a b | letE x a b | ifE c a b | matchE a b head tail body | call name args =>
    obtain ⟨n,shape,hlen,hdrop,hroots⟩ := hs.stack
    obtain ⟨n',shape',hlen',hdrop'⟩ := Framing.transition shape hlen hdrop hne ht
    have hclean := ((htask ▸ hs.cleanup).head (htask ▸ hne)).2
    simp only [Counted.transition,htask,pure,Except.pure] at ht
    cases ht
    have hn : n' = n := by dsimp only at hlen'; omega
    subst n'
    refine ⟨hs.heap,hs.bindings,hs.reservations,?_,n,shape',hlen',hdrop',hroots⟩
    all_goals try simp only [List.append_assoc,List.cons_append,List.nil_append]
    all_goals repeat' first
      | assumption
      | apply RegionWork.arguments
      | apply RegionWork.Clean.cons
      | trivial

theorem bind_step (hs : Resources root cut region saved frames slots s)
    (hnext : cut ≤ s.nextBinding) (hne : s.tasks ≠ saved)
    (htask : s.tasks = .bind name body ctx::rest) (ht : Counted.transition p s = .ok c) :
    Resources root cut region saved frames slots c.state := by
  obtain ⟨n,shape,hlen,hdrop,hroots⟩ := hs.stack
  have hneed := (htask ▸ shape).operands (htask ▸ hne)
  cases n with
  | zero => simp [Residual.operands] at hneed
  | succ n =>
    obtain ⟨n',shape',hlen',hdrop'⟩ := Framing.transition shape hlen hdrop hne ht
    have hclean := ((htask ▸ hs.cleanup).head (htask ▸ hne)).2
    cases hsl : s.slots with
    | nil => simp [Counted.transition,htask,hsl] at ht
    | cons v vs =>
      have hin := hroots v (by simp [hsl])
      simp only [Counted.transition,htask,hsl,pure,Except.pure] at ht
      cases ht
      have hn : n' = n := by
        dsimp only at hlen'
        simp only [hsl,List.length_cons] at hlen
        omega
      subst n'
      refine ⟨hs.heap,?_,hs.reservations,?_,n,shape',hlen',hdrop',?_⟩
      · intro b hm hcut
        rcases List.mem_append.mp hm with hold | hnew
        · exact hs.bindings b hold hcut
        · obtain rfl := List.mem_singleton.mp hnew
          exact hin
      · apply RegionWork.dead_prefix
        · intro pair hp
          obtain rfl := List.mem_singleton.mp hp
          exact hnext
        · exact .cons trivial (.cons trivial hclean)
      · intro x hx
        exact hroots x (by simp [hsl,hx])

theorem enter_step (hs : Resources root cut region saved frames slots s)
    (hnext : cut ≤ s.nextBinding) (hne : s.tasks ≠ saved)
    (htask : s.tasks = .enter name arity ctx::rest) (ht : Counted.transition p s = .ok c) :
    Resources root cut region saved frames slots c.state := by
  obtain ⟨n,shape,hlen,hdrop,hroots⟩ := hs.stack
  have hneed : arity ≤ n := (htask ▸ shape).operands (htask ▸ hne)
  obtain ⟨n',shape',hlen',hdrop'⟩ := Framing.transition shape hlen hdrop hne ht
  have hclean := ((htask ▸ hs.cleanup).head (htask ▸ hne)).2
  have hargs : ∀ v ∈ (s.slots.take arity).reverse, RawIn region v.raw := by
    intro v hv
    apply hroots
    have hv' : v ∈ (s.slots.take n).take arity := by
      simpa only [List.take_take,Nat.min_eq_left hneed] using List.mem_reverse.mp hv
    exact List.mem_of_mem_take hv'
  simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
  repeat' first | split at ht | cases ht | contradiction
  have hn : arity+n' = n := by
    dsimp only at hlen'
    simp only [List.length_drop] at hlen'
    omega
  refine ⟨hs.heap,?_,hs.reservations,?_,n',shape',hlen',hdrop',?_⟩
  · intro b hm hcut
    rcases List.mem_append.mp hm with hold | hnew
    · exact hs.bindings b hold hcut
    · obtain ⟨⟨pair,i⟩,hi,rfl⟩ := List.mem_map.mp hnew
      exact hargs pair.2 (List.of_mem_zip (List.fst_mem_of_mem_zipIdx hi)).2
  · apply RegionWork.dead_prefix
    · exact LocalIds.parameter_env _ _ _ _ (root := s.nextInvocation) hnext (Nat.le_refl _)
    · exact .cons trivial (.cons trivial hclean)
  · intro v hv
    apply hroots
    exact List.mem_of_mem_drop (by simpa only [List.take_drop,hn] using hv)

set_option maxHeartbeats 2000000 in
theorem decompose_step (hr : Statements.Reachable p initial s)
    (hs : Resources root cut region saved frames slots s)
    (hnext : cut ≤ s.nextBinding) (hne : s.tasks ≠ saved)
    (htask : s.tasks = .decompose head tail body bid ctx::rest)
    (ht : Counted.transition p s = .ok c) : Resources root cut region saved frames slots c.state := by
  obtain ⟨n,shape,hlen,hdrop,hroots⟩ := hs.stack
  have hneed := (htask ▸ shape).operands (htask ▸ hne)
  cases n with
  | zero => simp [Residual.operands] at hneed
  | succ n =>
    obtain ⟨n',shape',hlen',hdrop'⟩ := Framing.transition shape hlen hdrop hne ht
    have hclean := ((htask ▸ hs.cleanup).head (htask ▸ hne)).2
    cases hsl : s.slots with
    | nil => simp [Counted.transition,htask,hsl] at ht
    | cons v vs =>
      have hin := hroots v (by simp [hsl])
      cases hv : v.raw with
      | num q | bool b => simp [Counted.transition,htask,hsl,hv] at ht
      | list link =>
        cases link with
        | none => simp [Counted.transition,htask,hsl,hv] at ht
        | some addr =>
          obtain ⟨cell,hfind,hstatus,hcount⟩ := scrutinee_unique hr hs.heap
            (v := v) (by simp [hsl]) hin hv
          have haddr : cell.addr = addr := by simpa using List.find?_some hfind
          have hregion := hin addr (by simp [hv,Inspect.link])
          have htail : RawIn region (.list cell.link) :=
            hs.heap.closed cell (List.mem_of_find?_eq_some hfind) (haddr ▸ hregion) hstatus
          simp only [Counted.transition,htask,hsl,hv,hfind,hstatus,hcount,
            bind,pure,Except.bind,Except.pure] at ht
          repeat' first | split at ht | cases ht | contradiction
          all_goals
            have hn : n' = n := by
              dsimp only at hlen'
              simp only [hsl,List.length_cons] at hlen
              omega
            subst n'
          all_goals refine ⟨?_,?_,?_,?_,n,shape',hlen',hdrop',?_⟩
          all_goals first
            | exact hs.heap.set_aside (by assumption)
            | (intro b hb hcut
               rcases List.mem_append.mp hb with hold | hnew
               · exact hs.bindings b hold hcut
               · simp only [List.mem_cons,List.not_mem_nil,or_false] at hnew
                 rcases hnew with rfl | rfl
                 · simp [RawIn,Inspect.link,makeBinding]
                 · exact htail)
            | (intro r hr hroot
               rcases List.mem_cons.mp hr with rfl | hold
               · exact hregion
               · exact hs.reservations r hold hroot)
            | (intro x hx; exact hroots x (by simp [hsl,hx]))
            | (simp only [List.cons_append,List.nil_append]
               repeat' first
                 | assumption
                 | apply RegionWork.Clean.cons
                 | trivial
                 | solve | change cut ≤ s.nextBinding+1; omega)

theorem primitive_step (hr : Statements.Reachable p initial s)
    (active : root ∈ s.frames.map Frame.id)
    (hs : Resources root cut region saved frames slots s) (hne : s.tasks ≠ saved)
    (htask : s.tasks = .primitive op ctx::rest)
    (eligible : op = .cons → ∃ r, s.reservations.find? (fun r =>
      r.invocation == ctx.invocation && ctx.branches.contains r.branch) = some r)
    (ht : Counted.transition p s = .ok c) : Resources root cut region saved frames slots c.state := by
  obtain ⟨n,shape,hlen,hdrop,hroots⟩ := hs.stack
  have hneed : 2 ≤ n := (htask ▸ shape).operands (htask ▸ hne)
  obtain ⟨n',shape',hlen',hdrop'⟩ := Framing.transition shape hlen hdrop hne ht
  have hclean := ((htask ▸ hs.cleanup).head (htask ▸ hne)).2
  have hscope : ctx.invocation = (s.frames.map Frame.id).headD 0 := Scopes.head_scope hr htask
  have hroot := hscope ▸ Scopes.active_head_ge hr active
  obtain ⟨k,rfl⟩ := Nat.exists_eq_add_of_le hneed
  cases hsl : s.slots with
  | nil => simp [Counted.transition,htask,hsl] at ht
  | cons b bs =>
    cases hbs : bs with
    | nil => simp [Counted.transition,htask,hsl,hbs] at ht
    | cons a vs =>
      have htail := hroots b (by simp [hsl,hbs,Nat.add_comm])
      have hrest : ∀ v ∈ vs.take k, RawIn region v.raw := by
        intro v hv
        exact hroots v (by simpa [hsl,hbs,Nat.add_comm] using Or.inr (Or.inr hv))
      by_cases hop : op = .cons
      · obtain ⟨r,he⟩ := eligible hop
        have hrinv : r.invocation = ctx.invocation := by
          have htst := List.find?_some he
          simp only [Bool.and_eq_true,beq_iff_eq] at htst
          exact htst.1
        have haddr := hs.reservations r (List.mem_of_find?_eq_some he) (hrinv ▸ hroot)
        subst op
        simp only [Counted.transition,htask,hsl,hbs,he,bind,pure,Except.bind,Except.pure] at ht
        repeat' first | split at ht | cases ht | contradiction
        all_goals
          have hn : n' = k+1 := by
            dsimp only at hlen'
            simp only [List.length_cons] at hlen'
            simp only [hsl,hbs,List.length_cons] at hlen
            omega
          subst n'
          refine ⟨?_,hs.bindings,?_,hclean,k+1,shape',hlen',hdrop',?_⟩
          · apply hs.heap.write (ht := by assumption)
            simpa only [RawIn,Inspect.link,show b.raw = .list _ from by assumption] using htail
          · intro q hq hi
            exact hs.reservations q (List.mem_filter.mp hq).1 hi
          · intro v hv
            rcases List.mem_cons.mp hv with rfl | hv
            · simpa [RawIn,Inspect.link] using haddr
            · exact hrest v hv
      · simp only [Counted.transition,htask,hsl,hbs,bind,pure,Except.bind,Except.pure] at ht
        simp only [beq_iff_eq,hop,↓reduceIte] at ht
        repeat' first | split at ht | cases ht | contradiction
        all_goals
          have hn : n' = k+1 := by
            dsimp only at hlen'
            simp only [List.length_cons] at hlen'
            simp only [hsl,hbs,List.length_cons] at hlen
            omega
          subst n'
          refine ⟨hs.heap,hs.bindings,hs.reservations,hclean,k+1,shape',hlen',hdrop',?_⟩
          intro v hv
          rcases List.mem_cons.mp hv with rfl | hv
          · simp [RawIn,Inspect.link]
          · exact hrest v hv

theorem give_binding_step {id : Nat} (hs : Resources root cut region saved frames slots s)
    (hne : s.tasks ≠ saved) (htask : s.tasks = .giveBinding id::rest)
    (ht : Counted.transition p s = .ok c) : Resources root cut region saved frames slots c.state := by
  obtain ⟨n,shape,hlen,hdrop,hroots⟩ := hs.stack
  obtain ⟨n',shape',hlen',hdrop'⟩ := Framing.transition shape hlen hdrop hne ht
  obtain ⟨hcut,hclean⟩ := (htask ▸ hs.cleanup).head (htask ▸ hne)
  cases hb : s.bindings.find? (fun b => b.record.id == id) with
  | none => simp [Counted.transition,htask,hb] at ht
  | some b =>
    have hid : b.record.id = id := by simpa using List.find?_some hb
    have hin := hs.bindings b (List.mem_of_find?_eq_some hb) (hid ▸ hcut)
    simp only [Counted.transition,htask,hb,bind,pure,Except.bind,Except.pure] at ht
    repeat' first | split at ht | cases ht | contradiction
    all_goals
      have hn : n' = n := by dsimp only at hlen'; omega
      subst n'
      refine ⟨?_,binding_status hs.bindings _ _,hs.reservations,?_,n,shape',hlen',hdrop',hroots⟩
    all_goals first
      | (apply hs.heap.set_count (ht := by assumption)
         have hcount := hs.heap.bounded _ (List.mem_of_find?_eq_some (by assumption))
           (by
             have hid := List.find?_some (show s.mem.find? _ = some _ from by assumption)
             simp only [beq_iff_eq] at hid
             rw [hid]
             exact hin _ (by simp [Inspect.link,show b.record.value = .list _ from by assumption]))
         omega)
      | exact .cons (hin _ (by simp [Inspect.link,show b.record.value = .list _ from by assumption])) hclean
      | exact hclean

theorem give_pending_step (hs : Resources root cut region saved frames slots s)
    (hne : s.tasks ≠ saved) (htask : s.tasks = .givePending::rest)
    (ht : Counted.transition p s = .ok c) : Resources root cut region saved frames slots c.state := by
  obtain ⟨n,shape,hlen,hdrop,hroots⟩ := hs.stack
  have hneed := (htask ▸ shape).operands (htask ▸ hne)
  cases n with
  | zero => simp [Residual.operands] at hneed
  | succ n =>
    obtain ⟨n',shape',hlen',hdrop'⟩ := Framing.transition shape hlen hdrop hne ht
    have hclean := ((htask ▸ hs.cleanup).head (htask ▸ hne)).2
    cases hsl : s.slots with
    | nil => simp [Counted.transition,htask,hsl] at ht
    | cons v vs =>
      have hin := hroots v (by simp [hsl])
      simp only [Counted.transition,htask,hsl,bind,pure,Except.bind,Except.pure] at ht
      repeat' first | split at ht | cases ht | contradiction
      all_goals
        have hn : n' = n := by
          dsimp only at hlen'
          simp only [hsl,List.length_cons] at hlen
          omega
        subst n'
        refine ⟨?_,hs.bindings,hs.reservations,?_,n,shape',hlen',hdrop',?_⟩
      all_goals first
        | (apply hs.heap.set_count (ht := by assumption)
           have hcount := hs.heap.bounded _ (List.mem_of_find?_eq_some (by assumption))
             (by
               have hid := List.find?_some (show s.mem.find? _ = some _ from by assumption)
               simp only [beq_iff_eq] at hid
               rw [hid]
               exact hin _ (by simp [Inspect.link,show v.raw = .list _ from by assumption]))
           omega)
        | exact .cons (hin _ (by simp [Inspect.link,show v.raw = .list _ from by assumption])) hclean
        | exact hclean
        | (intro x hx; exact hroots x (by simp [hsl,hx]))

theorem free_step (hs : Resources root cut region saved frames slots s)
    (hne : s.tasks ≠ saved) (htask : s.tasks = .free addr::rest)
    (ht : Counted.transition p s = .ok c) : Resources root cut region saved frames slots c.state := by
  obtain ⟨n,shape,hlen,hdrop,hroots⟩ := hs.stack
  obtain ⟨n',shape',hlen',hdrop'⟩ := Framing.transition shape hlen hdrop hne ht
  obtain ⟨hin,hclean⟩ := (htask ▸ hs.cleanup).head (htask ▸ hne)
  cases hf : s.mem.find? addr with
  | none => simp [Counted.transition,htask,hf] at ht
  | some cell =>
    have hid : cell.addr = addr := by simpa using List.find?_some hf
    have htail := hs.heap.closed cell (List.mem_of_find?_eq_some hf) (hid ▸ hin)
    simp only [Counted.transition,htask,hf,bind,pure,Except.bind,Except.pure] at ht
    repeat' first | split at ht | cases ht | contradiction
    all_goals
      have hstatus : cell.status = .live := by simp_all
      have hraw : RawIn region (.list cell.link) := htail hstatus
    all_goals first
      | (have hn : n' = n+1 := by
           dsimp only at hlen'
           simp only [List.length_cons] at hlen'
           omega
         subst n'
         refine ⟨hs.heap.release (by assumption),hs.bindings,hs.reservations,
           .cons trivial hclean,n+1,shape',hlen',hdrop',?_⟩
         intro v hv
         rcases List.mem_cons.mp hv with rfl | hv
         · exact hraw
         · exact hroots v hv)
      | (have hn : n' = n := by dsimp only at hlen'; omega
         subst n'
         exact ⟨hs.heap.release (by assumption),hs.bindings,hs.reservations,
           hclean,n,shape',hlen',hdrop',hroots⟩)

theorem choice_step (hr : Statements.Reachable p initial s)
    (active : root ∈ s.frames.map Frame.id) (hlocal : LocalIds.TasksOK root cut s.tasks)
    (hs : Resources root cut region saved frames slots s) (hne : s.tasks ≠ saved)
    (htask : s.tasks = task::rest)
    (hchoice : match task with | .chooseIf .. | .chooseMatch .. => True | _ => False)
    (ht : Counted.transition p s = .ok c) : Resources root cut region saved frames slots c.state := by
  obtain ⟨n,shape,hlen,hdrop,hroots⟩ := hs.stack
  have hneed := (htask ▸ shape).operands (htask ▸ hne)
  obtain ⟨n',shape',hlen',hdrop'⟩ := Framing.transition shape hlen hdrop hne ht
  have hclean := ((htask ▸ hs.cleanup).head (htask ▸ hne)).2
  have hc := hlocal task (by rw [htask]; exact List.mem_cons_self)
  cases task <;> try contradiction
  all_goals rename_i ctx
  all_goals
    have hscope : ctx.invocation = (s.frames.map Frame.id).headD 0 := Scopes.head_scope hr htask
    have hctx : ∀ pair ∈ ctx.env, cut ≤ pair.2 := hc (hscope ▸ Scopes.active_head_ge hr active)
    cases n with
    | zero => simp [Residual.operands] at hneed
    | succ n =>
      cases hsl : s.slots with
      | nil => simp [Counted.transition,htask,hsl] at ht
      | cons v vs =>
        simp only [Counted.transition,htask,hsl,bind,pure,Except.bind,Except.pure] at ht
        repeat' first | split at ht | cases ht | contradiction
        all_goals first
          | (have hn : n' = n := by
               dsimp only at hlen'
               simp only [hsl,List.length_cons] at hlen
               omega
             subst n'
             refine ⟨hs.heap,hs.bindings,hs.reservations,?_,n,shape',hlen',hdrop',?_⟩)
          | (have hn : n' = n+1 := by
               dsimp only at hlen'
               simp only [hsl,List.length_cons] at hlen hlen'
               omega
             subst n'
             refine ⟨hs.heap,hs.bindings,hs.reservations,?_,n+1,shape',hlen',hdrop',
               (by simpa only [hsl] using hroots)⟩)
        all_goals first
          | (intro x hx; exact hroots x (by simp [hsl,hx]))
          | (apply RegionWork.dead_prefix _ _ _ hctx
             simp only [List.cons_append,List.nil_append]
             repeat' first | assumption | apply RegionWork.Clean.cons | trivial)

theorem administrative_step (hr : Statements.Reachable p initial s)
    (active : root ∈ s.frames.map Frame.id)
    (hs : Resources root cut region saved frames slots s) (hne : s.tasks ≠ saved)
    (htask : s.tasks = task::rest)
    (hkind : match task with
      | .start | .capture | .matchComplete .. | .branchStart .. | .branchResult ..
      | .handoffMatch .. | .handoff | .returning .. | .freeReserved .. | .finish => True
      | _ => False)
    (ht : Counted.transition p s = .ok c) : Resources root cut region saved frames slots c.state := by
  obtain ⟨n,shape,hlen,hdrop,hroots⟩ := hs.stack
  obtain ⟨n',shape',hlen',hdrop'⟩ := Framing.transition shape hlen hdrop hne ht
  have hclean := ((htask ▸ hs.cleanup).head (htask ▸ hne)).2
  have hres : ∀ bid inner outer, task = .branchResult bid inner outer →
      ∀ r ∈ s.reservations.filter (fun r => r.invocation == inner.invocation && r.branch == bid),
        r.addr ∈ region := by
    intro bid inner outer he r hm
    have hscope : inner.invocation = (s.frames.map Frame.id).headD 0 :=
      (Scopes.head_scope (t := .branchResult bid inner outer) hr (he ▸ htask)).1
    have hf := List.mem_filter.mp hm
    have hi : r.invocation = inner.invocation := by
      simp only [Bool.and_eq_true,beq_iff_eq] at hf
      exact hf.2.1
    exact hs.reservations r hf.1 (hi ▸ hscope ▸ Scopes.active_head_ge hr active)
  cases task <;> try contradiction
  all_goals simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
  all_goals repeat' first | split at ht | cases ht | contradiction
  all_goals
    have hn : n' = n := by dsimp only at hlen'; omega
    subst n'
    refine ⟨?_,hs.bindings,?_,?_,n,shape',hlen',hdrop',hroots⟩
  all_goals first
    | exact hs.heap
    | exact hs.heap.release (by assumption)
    | exact hs.reservations
    | (intro r hm hi; exact hs.reservations r (List.mem_filter.mp hm).1 hi)
    | exact hclean
    | (simp only [List.append_assoc,List.singleton_append]
       apply RegionWork.reserved_prefix _ (hres _ _ _ rfl)
       exact .cons trivial hclean)

/-- The resource half of simultaneous preservation. Eligibility is deliberately
explicit here; the credit half must derive it from successful source analysis. -/
theorem transition (hr : Statements.Reachable p initial s)
    (active : root ∈ s.frames.map Frame.id) (hlocal : LocalIds.TasksOK root cut s.tasks)
    (bound : Affinity.Bound cut s) (hs : Resources root cut region saved frames slots s)
    (hnext : cut ≤ s.nextBinding) (hne : s.tasks ≠ saved)
    (eligible : ∀ ctx rest, s.tasks = .primitive .cons ctx::rest →
      ∃ r, s.reservations.find? (fun r =>
        r.invocation == ctx.invocation && ctx.branches.contains r.branch) = some r)
    (ht : Counted.transition p s = .ok c) : Resources root cut region saved frames slots c.state := by
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    cases task with
    | eval e ctx => exact eval hr active hlocal bound hs hne he ht
    | primitive op ctx =>
      exact primitive_step hr active hs hne he (fun hop => eligible ctx rest (hop ▸ he)) ht
    | bind name body ctx => exact bind_step hs hnext hne he ht
    | enter name arity ctx => exact enter_step hs hnext hne he ht
    | decompose head tail body bid ctx => exact decompose_step hr hs hnext hne he ht
    | giveBinding id => exact give_binding_step hs hne he ht
    | givePending => exact give_pending_step hs hne he ht
    | free addr => exact free_step hs hne he ht
    | chooseIf yes no ctx | chooseMatch empty head tail body ctx =>
      exact choice_step hr active hlocal hs hne he trivial ht
    | start | capture | matchComplete ctx | branchStart ctx | branchResult bid inner outer
    | handoffMatch ctx | handoff | returning frame ctx | freeReserved addr | finish =>
      exact administrative_step hr active hs hne he trivial ht

end Full.Demand.RegionExecution
