import Full.Demand.CreditExecution
import Full.Proofs.Simulation

namespace Full.Demand.Soundness
open Counted Full.Proofs

structure Invariant (root cut : Nat) (p : Program) (out : Kind) (region : List Nat)
    (saved : List Task) (frames : List Nat) (slots : List Slot) (old : List Reservation) (s : State) : Prop where
  certified : Affinity.StateCertified root p out s
  bound : Affinity.Bound cut s
  ids : LocalIds.TasksOK root cut s.tasks
  next : cut ≤ s.nextBinding
  resources : RegionExecution.Resources root cut region saved frames slots s
  credit : CreditExecution.Credit root p saved old s

theorem Invariant.commit (h : Invariant root cut p out region saved frames slots old c.state) :
    Invariant root cut p out region saved frames slots old (commit c) :=
  ⟨h.certified,h.bound,h.ids,h.next,h.resources.commit,h.credit.commit⟩

theorem Invariant.transition (h : Invariant root cut p out region saved frames slots old s)
    (hp : PlainTyping.FunctionsTyped p) (table : CertifiedTable p)
    (hr : Statements.Reachable p initial s) (active : root ∈ s.frames.map Frame.id)
    (hne : s.tasks ≠ saved) (older : ∀ r ∈ old, r.invocation < root)
    (ht : Counted.transition p s = .ok c) :
    Invariant root cut p out region saved frames slots old c.state := by
  have hi := LocalIds.transition h.ids h.next ht
  exact ⟨Affinity.transition_certified hp table hr active ht h.certified,
    Affinity.transition_bound hr active table ht h.certified h.bound,hi.1,hi.2,
    RegionExecution.transition hr active h.ids h.bound h.resources h.next hne
      (fun _ _ he => CreditExecution.eligible h.credit hne he) ht,
    CreditExecution.transition hr table h.resources hne older h.credit ht⟩

/-- Every conjunct is initialized at the same actual predecessor and the same
pre-Enter binding cutoff. Independent existential cutoffs are not combined. -/
theorem at_entry (hr : Statements.Reachable p initial s)
    (hl : s.history.getLast?.map Action.name = some "Enter")
    (hf : s.frames.head? = some f) (ha : accepts p f.name = true)
    (hu : Statements.uniqueEntry s f = true) :
    ∃ cut out ctx rest old, PlainTyping.FunctionsTyped p ∧
      (∀ r ∈ old, r.invocation < f.id) ∧
      Invariant f.id cut p out (Region.addresses s f) (.returning f ctx::rest)
        (s.frames.map Frame.id) s.slots old s := by
  have heap := Region.entry_heap hr hl hf hu
  have args : ∀ v ∈ f.args, Region.RawIn (Region.addresses s f) v.raw :=
    fun _ hv => Region.entry_roots hr hl hf hv
  obtain ⟨before,c,hr',ht,hname,rfl⟩ := Events.last_enter hr hl
  obtain ⟨arity,ctx,rest,htask,hid⟩ := Entry.source ht hname hf
  obtain ⟨out,hp,hs⟩ := CountedTyping.reachable_typed hr'
  obtain ⟨decl,hdecl,hd⟩ := accepts_target ha
  have table := accepts_certificates ha
  have hdeclcert := table decl (List.mem_of_find?_eq_some hdecl) hd
  have hc := Affinity.transition_enter hp ht htask (Affinity.before_entry_certified hr' hs)
    (BindingIdentity.reachable_ids hr') (fun g hg => by
      cases Option.some.inj (hg.symm.trans hdecl)
      exact hdeclcert)
  have hi := LocalIds.transition (LocalIds.before_entry hr') (Nat.le_refl before.nextBinding) ht
  refine ⟨before.nextBinding,out,ctx,rest,before.reservations,hp,?_,?_⟩
  · intro r hm
    simpa only [hid] using RegionWork.before_enter_reservations hr' htask hm
  · refine ⟨?_,?_,?_,hi.2,?_,?_⟩
    · simpa only [Affinity.StateCertified,commit,hid] using hc
    · intro b hm hnew hk
      exact transition_parameters_new_bound hr' ht htask hdecl hdeclcert.1 hm hnew hk
    · simpa only [commit,hid] using hi.1
    · exact (RegionExecution.at_enter hr' ht htask hf heap args).commit
    · exact (CreditExecution.at_enter ha htask ht hf).commit

set_option maxHeartbeats 2000000 in
theorem creates_preserved (eligible : ∀ ctx rest, s.tasks = .primitive .cons ctx::rest →
      ∃ r, s.reservations.find? (fun r =>
        r.invocation == ctx.invocation && ctx.branches.contains r.branch) = some r)
    (ht : Counted.transition p s = .ok c) : Statements.creates root c.state.events = Statements.creates root s.events := by
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    cases task
    case primitive op ctx =>
      by_cases hop : op = .cons
      · subst op
        obtain ⟨r,hfind⟩ := eligible ctx rest he
        simp only [Counted.transition,he,hfind,bind,pure,Except.bind,Except.pure] at ht
        repeat' first | split at ht | cases ht | contradiction
        all_goals simp [Statements.creates,List.foldl_append]
      · simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
        simp only [beq_iff_eq,hop,↓reduceIte] at ht
        repeat' first | split at ht | cases ht | contradiction
        all_goals rfl
    all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals simp [Statements.creates,List.foldl_append]

theorem return_closed (hr : Statements.Reachable p initial s)
    (htask : s.tasks = .returning f ctx::rest) (ht : Counted.transition p s = .ok c) :
    f.id < c.state.nextInvocation ∧ f.id ∉ c.state.frames.map Frame.id ∧
    Statements.creates f.id c.state.events = Statements.creates f.id s.events := by
  have hi := Events.reachable_invariant hr
  have hb := Events.frame_bound hi
  have hn := Events.frames_nodup hi
  simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
  repeat' first | split at ht | cases ht | contradiction
  all_goals refine ⟨hb _ (by simp_all [bne_iff_ne]),?_,?_⟩
  all_goals first
    | solve | simp_all [bne_iff_ne]
    | simp [Statements.creates,List.foldl_append]

theorem finite_prefix (hp : PlainTyping.FunctionsTyped p) (table : CertifiedTable p)
    (older : ∀ r ∈ old, r.invocation < f.id)
    (hr : Statements.Reachable p initial s) (fresh : f.id < s.nextInvocation)
    (inv : Invariant f.id cut p out region (.returning f ctx::rest) frames slots old s)
    (zero : Statements.creates f.id s.events = 0)
    (ht : Counted.advance p n s = .ok t) : Statements.creates f.id t.events = 0 := by
  induction n generalizing s with
  | zero => cases ht; exact zero
  | succ n ih =>
    by_cases active : f.id ∈ s.frames.map Frame.id
    · cases ha : s.answer with
      | some v => simp [Counted.advance,ha] at ht; subst t; exact zero
      | none =>
        cases hc : Counted.transition p s with
        | error why => simp [Counted.advance,Counted.step,ha,hc] at ht
        | ok c =>
          simp [Counted.advance,Counted.step,ha,hc] at ht
          have step : Counted.step p s = .ok (commit c) := by simp [Counted.step,ha,hc]
          have hr' := Simulation.reachable_step hr step
          by_cases hend : s.tasks = .returning f ctx::rest
          · obtain ⟨hf,hn,hcount⟩ := return_closed hr hend hc
            have hclosed := (Events.advance_closed (Events.reachable_invariant hr') hf hn ht).2.2
            rw [Events.creates_eq,hclosed]
            exact hcount.trans zero
          · have hi := inv.transition hp table hr active hend older hc
            have hz := creates_preserved (root := f.id) (fun _ _ he => CreditExecution.eligible inv.credit hend he) hc
            exact ih hr' (Nat.lt_of_lt_of_le fresh (CreditExecution.numbers hc).1) hi.commit (hz.trans zero) ht
    · have hclosed := (Events.advance_closed (Events.reachable_invariant hr) fresh active ht).2.2
      rw [Events.creates_eq,hclosed]
      exact zero

/-- Exact frozen slice-1 target, for the Bool checker that actually executes.
Finite prefixes may stop inside descendants or extend beyond target Return. -/
theorem conditional : Statements.Conditional Full.Demand.accepts := by
  intro p initial s f n t hr hf hl _ ha hu ht
  obtain ⟨cut,out,ctx,rest,old,hp,older,inv⟩ := at_entry hr hl hf ha hu
  have active : f.id ∈ s.frames.map Frame.id := by
    cases hframes : s.frames with
    | nil => simp [hframes] at hf
    | cons top tail =>
      simp only [hframes,List.head?_cons,Option.some.injEq] at hf
      simp [hframes,hf]
  have fresh := Events.frame_bound (Events.reachable_invariant hr) _ active
  have zero : Statements.creates f.id s.events = 0 := by
    rw [Events.creates_eq,Events.entry_zero hr hl hf]
  exact finite_prefix hp (accepts_certificates ha) older hr fresh inv zero ht

end Full.Demand.Soundness
