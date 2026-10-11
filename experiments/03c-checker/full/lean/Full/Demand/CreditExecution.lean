import Full.Demand.CreditWork
import Full.Demand.RegionExecution
import Full.Proofs.BranchReservations

namespace Full.Demand.CreditExecution
open Counted Full.Proofs Tickets CreditWork

/-- A closing branch retains its physical reservations in an exact cleanup
prefix. The prefix cannot be skipped by ordinary source evaluation. -/
def Credit (root : Nat) (p : Program) (saved : List Task) (old : List Reservation) (s : State) : Prop :=
  ∃ expired work budgets actual,
    s.tasks = expired.map (fun r => .freeReserved r.addr) ++ work ∧
    Plan root p saved work budgets ∧ StackCovers budgets actual ∧
    Valid root s.nextInvocation s.nextBranch actual ∧
    s.reservations = expired ++ flatten actual ++ old

theorem Credit.commit (h : Credit root p saved old c.state) : Credit root p saved old (commit c) := h

theorem opened (plan : Plan root p saved s.tasks budgets) (cover : StackCovers budgets actual)
    (valid : Valid root s.nextInvocation s.nextBranch actual)
    (store : s.reservations = flatten actual ++ old) : Credit root p saved old s :=
  ⟨[],s.tasks,budgets,actual,rfl,plan,cover,valid,store⟩

set_option maxHeartbeats 2000000 in
theorem numbers (ht : Counted.transition p s = .ok c) :
    s.nextInvocation ≤ c.state.nextInvocation ∧ s.nextBranch ≤ c.state.nextBranch := by
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    cases task
    all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals constructor <;> (dsimp only; omega)

theorem eval_step (checked : expression p.functions env before e = .ok after)
    (plan : Plan root p saved rest (budget ctx after::stack))
    (cover : StackCovers (budget ctx before::stack) actual)
    (valid : Valid root s.nextInvocation s.nextBranch actual)
    (store : s.reservations = flatten actual ++ old)
    (htask : s.tasks = .eval e ctx::rest) (ht : Counted.transition p s = .ok c) :
    Credit root p saved old c.state := by
  have hp := dispatch checked plan htask ht
  have hn := numbers ht
  apply opened hp cover (valid.monotone hn.1 hn.2)
  cases e
  all_goals simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
  all_goals repeat' first | split at ht | cases ht | contradiction
  all_goals exact store

theorem quiet_step (hq : Quiet task) (plan : Plan root p saved rest budgets)
    (cover : StackCovers budgets actual) (valid : Valid root s.nextInvocation s.nextBranch actual)
    (store : s.reservations = flatten actual ++ old)
    (htask : s.tasks = task::rest) (ht : Counted.transition p s = .ok c) :
    Credit root p saved old c.state := by
  cases task <;> try contradiction
  all_goals simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
  all_goals repeat' first | split at ht | cases ht | contradiction
  all_goals refine opened (budgets := budgets) (actual := actual) ?_ cover ?_ ?_
  all_goals first | exact valid | exact store | exact plan | exact .quiet trivial plan

theorem bind_step (checked : expression p.functions env before body = .ok after)
    (plan : Plan root p saved rest (budget ctx after::stack))
    (cover : StackCovers (budget ctx before::stack) actual)
    (valid : Valid root s.nextInvocation s.nextBranch actual)
    (store : s.reservations = flatten actual ++ old)
    (htask : s.tasks = .bind name body ctx::rest) (ht : Counted.transition p s = .ok c) :
    Credit root p saved old c.state := by
  simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
  repeat' first | split at ht | cases ht | contradiction
  all_goals
    refine opened (budgets := budget ctx before::stack) (actual := actual) ?_ cover ?_ ?_
    · apply CreditWork.dead_prefix
      exact .eval checked (.handoff (.refl after) plan)
    · exact valid
    · exact store

theorem choose_if_step
    (hy : expression p.functions env before yes = .ok left)
    (hn : expression p.functions env before no = .ok right)
    (hl : Lower after left) (hr : Lower after right)
    (plan : Plan root p saved rest (budget ctx after::stack))
    (cover : StackCovers (budget ctx before::stack) actual)
    (valid : Valid root s.nextInvocation s.nextBranch actual)
    (store : s.reservations = flatten actual ++ old)
    (htask : s.tasks = .chooseIf yes no ctx::rest) (ht : Counted.transition p s = .ok c) :
    Credit root p saved old c.state := by
  simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
  repeat' first | split at ht | cases ht | contradiction
  all_goals refine opened (budgets := budget ctx before::stack) (actual := actual) ?_ cover ?_ ?_
  all_goals try first | exact valid | exact store
  all_goals apply CreditWork.dead_prefix
  all_goals apply Plan.quiet (task := .branchStart ctx) trivial
  all_goals first
    | exact .eval hy (.handoff hl plan)
    | exact .eval hn (.handoff hr plan)

theorem handoff_step (bound : Lower after before)
    (plan : Plan root p saved rest (budget ctx after::stack))
    (cover : StackCovers (budget ctx before::stack) actual)
    (valid : Valid root s.nextInvocation s.nextBranch actual)
    (store : s.reservations = flatten actual ++ old)
    (htask : s.tasks = .handoff::rest) (ht : Counted.transition p s = .ok c) :
    Credit root p saved old c.state := by
  cases cover with
  | cons hc htail =>
    rename_i a actual
    simp only [Counted.transition,htask,pure,Except.pure] at ht
    cases ht
    refine opened (actual := a::actual) plan ?_ ?_ ?_
    · exact .cons ⟨hc.1,hc.2.1,bound.trans hc.2.2⟩ htail
    · exact valid
    · exact store

theorem primitive_step (hr : Statements.Reachable p initial s)
    (checked : (if op == .cons then spend before else .ok before) = .ok after)
    (plan : Plan root p saved rest (budget ctx after::stack))
    (cover : StackCovers (budget ctx before::stack) actual)
    (valid : Valid root s.nextInvocation s.nextBranch actual)
    (store : s.reservations = flatten actual ++ old)
    (htask : s.tasks = .primitive op ctx::rest) (ht : Counted.transition p s = .ok c) :
    Credit root p saved old c.state := by
  by_cases hop : op = .cons
  · subst op
    simp only [beq_self_eq_true,↓reduceIte] at checked
    cases cover with
    | cons hc htail =>
      rename_i a actual
      obtain ⟨inv,scopes⟩ := a
      obtain ⟨hi,hbs,lower⟩ := hc
      dsimp only [budget] at hi hbs lower
      subst inv
      obtain ⟨r,scopes',hconsume,lower'⟩ := consume_lower (inv := ctx.invocation) lower checked
      have hshape := (consume_shape hconsume).1
      have hfind : s.reservations.find? (fun q =>
          q.invocation == ctx.invocation && ctx.branches.contains q.branch) = some r := by
        rw [store]
        simpa only [flatten,List.flatMap_cons,List.append_assoc,hbs] using
          consume_find (suffix := flatten actual ++ old) hconsume
      have hfilter : s.reservations.filter (fun q => q.addr != r.addr) =
          flatten (⟨ctx.invocation,scopes'⟩::actual) ++ old := by
        rw [store]
        simp only [flatten,List.flatMap_cons,List.append_assoc]
        apply consume_filter hconsume
        simpa only [ReservedReadiness.Unique,store,flatten,List.flatMap_cons,List.append_assoc] using
          (ReservedReadiness.reachable_invariant hr).2.1
      have valid' := valid.replace (a' := ⟨ctx.invocation,scopes'⟩) rfl hshape
      have cover' : StackCovers (budget ctx after::stack) (⟨ctx.invocation,scopes'⟩::actual) :=
        .cons ⟨rfl,hbs.trans hshape.symm,lower'⟩ htail
      simp only [Counted.transition,htask,hfind,bind,pure,Except.bind,Except.pure] at ht
      repeat' first | split at ht | cases ht | contradiction
      all_goals
        refine opened (actual := ⟨ctx.invocation,scopes'⟩::actual) plan cover' ?_ ?_
        · exact valid'
        · exact hfilter
  · simp only [beq_iff_eq,hop,↓reduceIte,Except.ok.injEq] at checked
    subst after
    simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
    simp only [beq_iff_eq,hop,↓reduceIte] at ht
    repeat' first | split at ht | cases ht | contradiction
    all_goals
      refine opened (actual := actual) plan cover ?_ ?_
      · exact valid
      · exact store

theorem choose_match_step
    (hn : expression p.functions emptyEnv (0::before) empty = .ok left)
    (hc : expression p.functions cellEnv (1::before) body = .ok right)
    (hl : Lower after left.tail) (hr : Lower after right.tail)
    (plan : Plan root p saved rest (budget ctx after::stack))
    (cover : StackCovers (budget ctx before::stack) actual)
    (valid : Valid root s.nextInvocation s.nextBranch actual)
    (store : s.reservations = flatten actual ++ old)
    (htask : s.tasks = .chooseMatch empty head tail body ctx::rest)
    (ht : Counted.transition p s = .ok c) : Credit root p saved old c.state := by
  cases cover with
  | cons hcover htail =>
    rename_i a actual
    obtain ⟨inv,scopes⟩ := a
    obtain ⟨hi,hbs,lower⟩ := hcover
    dsimp only [budget] at hi hbs lower
    subst inv
    let inner : Context := { ctx with branches := s.nextBranch::ctx.branches }
    let next : List Activation := ⟨ctx.invocation,⟨s.nextBranch,none⟩::scopes⟩::actual
    have cover' : StackCovers (budget inner (0::before)::stack) next :=
      .cons ⟨rfl,by simp [budget,inner,hbs],.cons (Nat.le_refl 0) lower⟩ htail
    have valid' := valid.push_scope
    have store' : s.reservations = flatten next ++ old := by
      simpa only [next,flatten,List.flatMap_cons,reservations,List.filterMap_cons,Option.map_none] using store
    simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
    repeat' first | split at ht | cases ht | contradiction
    all_goals refine opened (budgets := budget inner (0::before)::stack) (actual := next) ?_ cover' ?_ ?_
    all_goals try first | exact valid' | exact store'
    all_goals apply CreditWork.dead_prefix
    all_goals first
      | (apply Plan.quiet (task := .branchStart inner) trivial
         exact .eval hn (.branchResult ⟨rfl,rfl⟩ hl plan))
      | exact .decompose rfl hc hr plan

theorem pending_no_reservation (hr : Statements.Reachable p initial s)
    (htask : s.tasks = .decompose head tail body bid ctx::rest)
    (hm : r ∈ s.reservations) : r.branch ≠ bid := by
  intro he
  have hb := (BranchReservations.reachable_invariant hr bid).1
  simp only [htask,BranchReservations.pending,List.count_cons,beq_self_eq_true,↓reduceIte] at hb
  have hm' : r ∈ s.reservations.filter (fun r => r.branch == bid) := by simp [hm,he]
  cases hf : s.reservations.filter (fun r => r.branch == bid) with
  | nil => simp [hf] at hm'
  | cons q qs => simp only [hf,List.length_cons] at hb; omega

theorem decompose_step (hr : Statements.Reachable p initial s)
    (resources : RegionExecution.Resources root cut region saved frames slots s)
    (hne : s.tasks ≠ saved) (hbranches : ctx.branches = bid::outer)
    (checked : expression p.functions env (1::before) body = .ok after)
    (bound : Lower joined after.tail)
    (plan : Plan root p saved rest (⟨ctx.invocation,outer,joined⟩::stack))
    (cover : StackCovers (budget ctx (0::before)::stack) actual)
    (valid : Valid root s.nextInvocation s.nextBranch actual)
    (store : s.reservations = flatten actual ++ old)
    (htask : s.tasks = .decompose head tail body bid ctx::rest)
    (ht : Counted.transition p s = .ok c) : Credit root p saved old c.state := by
  cases cover with
  | cons hc htail =>
    rename_i a actual
    obtain ⟨inv,scopes⟩ := a
    obtain ⟨hi,hbs,lower⟩ := hc
    dsimp only [budget] at hi hbs lower
    subst inv
    rw [hbranches] at hbs
    cases scopes with
    | nil => simp at hbs
    | cons scope scopes =>
      obtain ⟨j,address⟩ := scope
      simp only [List.map_cons,List.cons.injEq] at hbs
      obtain ⟨rfl,hbs⟩ := hbs
      have hempty : address = none := by
        cases address with
        | none => rfl
        | some addr =>
          have hm : (⟨ctx.invocation,bid,addr⟩ : Reservation) ∈ s.reservations := by
            simp [store,flatten,reservations]
          exact False.elim (pending_no_reservation hr htask hm rfl)
      subst address
      have lowerTail : Lower before (counts scopes) := lower.tail
      obtain ⟨n,shape,_,_,hroots⟩ := resources.stack
      have hneed := (htask ▸ shape).operands (htask ▸ hne)
      cases n with
      | zero => simp [Residual.operands] at hneed
      | succ n =>
        cases hslots : s.slots with
        | nil => simp [Counted.transition,htask,hslots] at ht
        | cons v vs =>
          have hin := hroots v (by simp [hslots])
          cases hv : v.raw with
          | num q | bool b => simp [Counted.transition,htask,hslots,hv] at ht
          | list link =>
            cases link with
            | none => simp [Counted.transition,htask,hslots,hv] at ht
            | some addr =>
              obtain ⟨cell,hfind,hstatus,hcount⟩ := Region.scrutinee_unique hr resources.heap
                (v := v) (by simp [hslots]) hin hv
              let next : List Activation := ⟨ctx.invocation,⟨bid,some addr⟩::scopes⟩::actual
              have valid' : Valid root s.nextInvocation s.nextBranch next := valid.replace rfl rfl
              have cover' : StackCovers (budget ctx (1::before)::stack) next :=
                .cons ⟨rfl,by simp [budget,hbranches,hbs],.cons (Nat.le_refl 1) lowerTail⟩ htail
              have store' : (⟨ctx.invocation,bid,addr⟩ : Reservation)::s.reservations = flatten next ++ old := by
                simpa only [store,next,flatten,reservations,List.flatMap_cons,List.filterMap_cons,
                  Option.map_some,Option.map_none,List.cons_append]
              simp only [Counted.transition,htask,hslots,hv,hfind,hstatus,hcount,
                bind,pure,Except.bind,Except.pure] at ht
              repeat' first | split at ht | cases ht | contradiction
              all_goals refine opened (budgets := budget ctx (1::before)::stack) (actual := next) ?_ cover' ?_ ?_
              all_goals try first | exact valid' | exact store'
              all_goals simp only [List.cons_append,List.nil_append]
              all_goals try apply Plan.quiet (task := .giveBinding (s.nextBinding+1)) trivial
              all_goals apply Plan.quiet (task := .branchStart _) trivial
              all_goals apply Plan.eval checked
              all_goals apply Plan.branchResult _ bound
              all_goals first
                | (constructor; rfl; simp [hbranches])
                | simpa only [budget,hbranches,List.tail_cons] using plan

theorem branch_result_step (older : ∀ r ∈ old, r.invocation < root)
    (scope : inner.invocation = outer.invocation ∧ inner.branches = bid::outer.branches)
    (bound : Lower after before.tail)
    (plan : Plan root p saved rest (budget outer after::stack))
    (cover : StackCovers (budget inner before::stack) actual)
    (valid : Valid root s.nextInvocation s.nextBranch actual)
    (store : s.reservations = flatten actual ++ old)
    (htask : s.tasks = .branchResult bid inner outer::rest)
    (ht : Counted.transition p s = .ok c) : Credit root p saved old c.state := by
  cases cover with
  | cons hc htail =>
    rename_i a actual
    obtain ⟨inv,scopes⟩ := a
    obtain ⟨hi,hbs,lower⟩ := hc
    dsimp only [budget] at hi hbs lower
    subst inv
    rw [scope.2] at hbs
    cases scopes with
    | nil => simp at hbs
    | cons top scopes =>
      obtain ⟨j,addr⟩ := top
      simp only [List.map_cons,List.cons.injEq] at hbs
      obtain ⟨rfl,hbs⟩ := hbs
      let expired := reservations inner.invocation [⟨bid,addr⟩]
      let next : List Activation := ⟨inner.invocation,scopes⟩::actual
      have hfilter : s.reservations.filter (fun r => r.invocation == inner.invocation && r.branch == bid) = expired := by
        rw [store]
        exact branch_filter valid older
      have cover' : StackCovers (budget outer after::stack) next :=
        .cons ⟨scope.1.symm,hbs,bound.trans lower.tail⟩ htail
      have store' : s.reservations = expired ++ flatten next ++ old := by
        rw [store]
        cases addr <;> simp [expired,next,flatten,reservations]
      simp only [Counted.transition,htask,hfilter,bind,pure,Except.bind,Except.pure] at ht
      repeat' first | split at ht | cases ht | contradiction
      refine ⟨expired,.handoffMatch outer::rest,budget outer after::stack,next,?_,
        .quiet trivial plan,cover',valid.pop_scope,store'⟩
      simp only [List.append_assoc,List.singleton_append]

theorem enter_step (table : CertifiedTable p)
    (found : signature p.functions name = some f) (demanded : f.demanded = true)
    (plan : Plan root p saved rest (budget ctx credits::stack))
    (cover : StackCovers (budget ctx credits::stack) actual)
    (valid : Valid root s.nextInvocation s.nextBranch actual)
    (store : s.reservations = flatten actual ++ old)
    (htask : s.tasks = .enter name arity ctx::rest) (ht : Counted.transition p s = .ok c) :
    Credit root p saved old c.state := by
  obtain ⟨out,hbody⟩ := (table f (List.mem_of_find?_eq_some found) demanded).2
  have hlen := expression_length _ _ _ _ _ hbody
  simp only [List.length_nil,List.length_eq_zero_iff] at hlen
  subst out
  have hroot : root ≤ s.nextInvocation := by
    cases cover with
    | cons hc htail =>
      have hv := valid.2 _ List.mem_cons_self
      omega
  have valid' := valid.push_call hroot
  simp only [Counted.transition,htask,found,bind,pure,Except.bind,Except.pure] at ht
  repeat' first | split at ht | cases ht | contradiction
  refine opened (budgets := ⟨s.nextInvocation,[],[]⟩::budget ctx credits::stack)
    (actual := ⟨s.nextInvocation,[]⟩::actual) ?_ (.cons ⟨rfl,rfl,.nil⟩ cover) ?_ ?_
  · apply CreditWork.dead_prefix
    exact .eval hbody (.returning plan)
  · exact valid'
  · simpa [flatten,reservations] using store

theorem returning_step
    (plan : Plan root p saved rest (budget ctx credits::stack))
    (cover : StackCovers (⟨frame.id,[],[]⟩::budget ctx credits::stack) actual)
    (valid : Valid root s.nextInvocation s.nextBranch actual)
    (store : s.reservations = flatten actual ++ old)
    (htask : s.tasks = .returning frame ctx::rest) (ht : Counted.transition p s = .ok c) :
    Credit root p saved old c.state := by
  cases cover with
  | cons hc htail =>
    rename_i a actual
    have hempty : a.scopes = [] := List.map_eq_nil_iff.mp hc.2.1.symm
    have store' : s.reservations = flatten actual ++ old := by simpa [flatten,hempty,reservations] using store
    have valid' := valid.tail
    simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
    repeat' first | split at ht | cases ht | contradiction
    refine opened (actual := actual) plan htail ?_ ?_
    · exact valid'
    · exact store'

theorem expired_step (hr : Statements.Reachable p initial s)
    (plan : Plan root p saved work budgets) (cover : StackCovers budgets actual)
    (valid : Valid root s.nextInvocation s.nextBranch actual)
    (store : s.reservations = (r::expired) ++ flatten actual ++ old)
    (htask : s.tasks = (r::expired).map (fun q => .freeReserved q.addr) ++ work)
    (ht : Counted.transition p s = .ok c) : Credit root p saved old c.state := by
  have unique := (ReservedReadiness.reachable_invariant hr).2.1
  have hfilter : s.reservations.filter (fun q => q.addr != r.addr) = expired ++ flatten actual ++ old := by
    rw [store]
    simp only [List.cons_append,List.filter_cons,bne_self_eq_false]
    apply List.filter_eq_self.mpr
    intro q hq
    have hu : ¬r.addr ∈ (expired ++ flatten actual ++ old).map Reservation.addr := by
      simp only [ReservedReadiness.Unique,store,List.cons_append,List.map_cons,List.nodup_cons] at unique
      exact unique.1
    have hne : q.addr ≠ r.addr := fun he => hu (List.mem_map.mpr ⟨q,hq,he⟩)
    simpa using hne
  simp only [Counted.transition,htask,List.map_cons,List.cons_append,bind,pure,Except.bind,Except.pure] at ht
  repeat' first | split at ht | cases ht | contradiction
  exact ⟨expired,work,budgets,actual,rfl,plan,cover,valid,hfilter⟩

theorem transition_open (hr : Statements.Reachable p initial s) (table : CertifiedTable p)
    (resources : RegionExecution.Resources root cut region saved frames slots s)
    (hne : s.tasks ≠ saved) (older : ∀ r ∈ old, r.invocation < root)
    (plan : Plan root p saved s.tasks budgets) (cover : StackCovers budgets actual)
    (valid : Valid root s.nextInvocation s.nextBranch actual)
    (store : s.reservations = flatten actual ++ old)
    (ht : Counted.transition p s = .ok c) : Credit root p saved old c.state := by
  generalize he : s.tasks = tasks at plan
  cases plan
  case boundary => exact False.elim (hne he)
  all_goals first
    | exact eval_step (by assumption) (by assumption) cover valid store he ht
    | exact quiet_step (by assumption) (by assumption) cover valid store he ht
    | exact bind_step (by assumption) (by assumption) cover valid store he ht
    | exact choose_if_step (by assumption) (by assumption) (by assumption) (by assumption)
        (by assumption) cover valid store he ht
    | exact handoff_step (by assumption) (by assumption) cover valid store he ht
    | exact primitive_step hr (by assumption) (by assumption) cover valid store he ht
    | exact choose_match_step (by assumption) (by assumption) (by assumption) (by assumption)
        (by assumption) cover valid store he ht
    | exact decompose_step hr resources hne (by assumption) (by assumption) (by assumption)
        (by assumption) cover valid store he ht
    | exact branch_result_step older (by assumption) (by assumption) (by assumption) cover valid store he ht
    | exact enter_step table (by assumption) (by assumption) (by assumption) cover valid store he ht
    | exact returning_step (by assumption) cover valid store he ht

theorem transition (hr : Statements.Reachable p initial s) (table : CertifiedTable p)
    (resources : RegionExecution.Resources root cut region saved frames slots s)
    (hne : s.tasks ≠ saved) (older : ∀ r ∈ old, r.invocation < root)
    (credit : Credit root p saved old s) (ht : Counted.transition p s = .ok c) :
    Credit root p saved old c.state := by
  obtain ⟨expired,work,budgets,actual,htasks,plan,cover,valid,store⟩ := credit
  cases expired with
  | nil =>
    simp only [List.map_nil,List.nil_append] at htasks store
    rw [← htasks] at plan
    exact transition_open hr table resources hne older plan cover valid store ht
  | cons r rs => exact expired_step hr plan cover valid store htasks ht

/-- Successful Cons analysis entails actual machine eligibility. No caller
reservation, recursive semantic summary, or hypothesis about a later state is
used to establish this premise of regional preservation. -/
theorem eligible (credit : Credit root p saved old s) (hne : s.tasks ≠ saved)
    (htask : s.tasks = .primitive .cons ctx::rest) :
    ∃ r, s.reservations.find? (fun r =>
      r.invocation == ctx.invocation && ctx.branches.contains r.branch) = some r := by
  obtain ⟨expired,work,budgets,actual,htasks,plan,cover,valid,store⟩ := credit
  cases expired with
  | cons r rs => simp [htask] at htasks
  | nil =>
    simp only [List.map_nil,List.nil_append] at htasks store
    rw [← htasks,htask] at plan
    cases plan with
    | boundary => exact False.elim (hne htask)
    | quiet hq _ => contradiction
    | primitive checked restPlan =>
      simp only [beq_self_eq_true,↓reduceIte] at checked
      cases cover with
      | cons hc htail =>
        rename_i a actual
        obtain ⟨inv,scopes⟩ := a
        obtain ⟨hi,hbs,lower⟩ := hc
        dsimp only [budget] at hi hbs lower
        subst inv
        obtain ⟨r,ss',hconsume,_⟩ := consume_lower (inv := ctx.invocation) lower checked
        refine ⟨r,?_⟩
        rw [store]
        simpa only [flatten,List.flatMap_cons,List.append_assoc,hbs] using
          consume_find (suffix := flatten actual ++ old) hconsume

theorem at_enter (ha : accepts p name = true)
    (htask : s.tasks = .enter name arity ctx::rest) (ht : Counted.transition p s = .ok c)
    (hf : c.state.frames.head? = some f) :
    Credit f.id p (.returning f ctx::rest) s.reservations c.state := by
  obtain ⟨decl,hdecl,hd⟩ := accepts_target ha
  obtain ⟨out,hbody⟩ := ((accepts_certificates ha) decl (List.mem_of_find?_eq_some hdecl) hd).2
  have hlen := expression_length _ _ _ _ _ hbody
  simp only [List.length_nil,List.length_eq_zero_iff] at hlen
  subst out
  simp only [Counted.transition,htask,hdecl,bind,pure,Except.bind,Except.pure] at ht
  repeat' first | split at ht | cases ht | contradiction
  simp only [List.head?_cons,Option.some.injEq] at hf
  subst f
  refine opened (budgets := [⟨s.nextInvocation,[],[]⟩]) (actual := [⟨s.nextInvocation,[]⟩]) ?_ ?_ ?_ ?_
  · apply CreditWork.dead_prefix
    exact .eval hbody .boundary
  · exact .cons ⟨rfl,rfl,.nil⟩ .nil
  · simp [Valid]
  · simp [flatten,reservations]

end Full.Demand.CreditExecution
