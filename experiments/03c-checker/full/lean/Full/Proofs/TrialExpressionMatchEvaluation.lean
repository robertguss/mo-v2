import Full.Proofs.TrialExpressionMatchUnique
import Full.Proofs.TrialExpressionMatchShared
import Full.Proofs.TrialExpressionMatchFinish

namespace Full.Proofs.TrialExecution
open Counted Statements TrialCompatibilitySimulation TrialRelease TrialSimulationRelease

/-- The choose step retains the complete logged Trial observation. -/
theorem match_choose_exact (p : Program) (initial : Trial.Start) (s : State)
    (ctx : Context) (empty body : Trial.Expr) (head tail : String)
    (rest : List Task) (v : Slot) (older : List Slot) (addr : Option Nat)
    (q decision : Trial.RunState)
    (hr : Reachable p initial s)
    (ht : s.tasks = .chooseMatch (embed empty) head tail (embed body) ctx :: rest)
    (hv : s.slots = v :: older) (hraw : v.raw = .list addr)
    (ha : s.answer = none) (he : Enclosing ctx s) (hq : eraseLog q = observe s)
    (hd : Trial.snapshot .branchChosen none
      { q with scope := ctx.env.reverse.map Prod.snd, nextBranch := s.nextBranch + 1 } = (.ok (), decision)) :
    let inner := { ctx with branches := s.nextBranch :: ctx.branches }
    let next := (match addr with
      | none => [.branchStart inner, .eval (embed empty) (child inner 1),
          .branchResult s.nextBranch inner ctx]
      | some _ => [.decompose head tail (embed body) s.nextBranch inner]) ++ rest
    ∃ t, advance p 1 s = .ok t ∧ Reachable p initial t ∧
      t.tasks = dead t.bindings ctx.env next ++ next ∧
      t.slots = (if addr.isNone then older else s.slots) ∧ t.answer = none ∧
      logged t q.log = decision ∧ Enclosing inner t := by
  dsimp only
  let inner := { ctx with branches := s.nextBranch :: ctx.branches }
  let next := (match addr with
      | none => [.branchStart inner, .eval (embed empty) (child inner 1),
          .branchResult s.nextBranch inner ctx]
      | some _ => [.decompose head tail (embed body) s.nextBranch inner]) ++ rest
  let change : Change := ⟨{ s with
    nextBranch := s.nextBranch + 1,
    slots := if addr.isNone then older else s.slots,
    tasks := dead s.bindings ctx.env next ++ next, entered := ctx.env },
    ⟨"Choose",some .branchChosen⟩,none⟩
  have hx : advance p 1 s = .ok (commit change) := by
    cases addr <;> simp [advance, step, transition, ht, hv, hraw, ha, change, next, inner]
  refine ⟨commit change, hx, reachable_advance p initial s _ 1 hr hx,
    rfl, rfl, ha, ?_, ?_⟩
  · have hd' : decision = (Trial.snapshot .branchChosen none
        { q with scope := ctx.env.reverse.map Prod.snd, nextBranch := s.nextBranch + 1 }).2 :=
      (congrArg Prod.snd hd).symm
    rw [hd', ← logged_of_exact s q hq]
    cases addr <;>
      simp [logged, observe, change, commit, pending, Trial.snapshot, hv, hraw]
    all_goals simpa [observe, change, hv] using (visible_projection change.state).symm
  · intro r hm
    obtain ⟨hi,hb⟩ := he r hm
    exact ⟨hi,List.mem_cons_of_mem _ hb⟩

/-- Exact logged observation of the branch-start step. -/
theorem match_start_exact (p : Program) (initial : Trial.Start) (s : State)
    (ctx : Context) (rest : List Task) (q started : Trial.RunState)
    (hr : Reachable p initial s) (ht : s.tasks = .branchStart ctx :: rest)
    (ha : s.answer = none) (he : Enclosing ctx s) (hq : eraseLog q = observe s)
    (hu : (do Trial.enter ctx.env; Trial.snapshot .branchStarts : Trial.M Unit)
      q = (.ok (), started)) :
    ∃ t, advance p 1 s = .ok t ∧ Reachable p initial t ∧
      t.tasks = rest ∧ t.slots = s.slots ∧ t.answer = none ∧
      logged t q.log = started ∧ Enclosing ctx t := by
  let change : Change := ⟨{ s with tasks := rest, entered := ctx.env },
    ⟨"BranchStart",some .branchStarts⟩,none⟩
  have hx : advance p 1 s = .ok (commit change) := by
    simp [advance, step, transition, ht, ha, change]
  refine ⟨commit change,hx,reachable_advance p initial s _ 1 hr hx,rfl,rfl,ha,?_,he⟩
  have hs : started = (Trial.snapshot .branchStarts none
      {q with scope := ctx.env.reverse.map Prod.snd}).2 := by
    simpa [Trial.enter] using (congrArg Prod.snd hu).symm
  rw [hs, ← logged_of_exact s q hq]
  simp [logged, observe, Trial.snapshot, change, commit, pending]
  simpa [observe, change] using (visible_projection change.state).symm

/-- Evaluate a branch and perform its complete disposal and handoff. -/
theorem match_body_finish (body : Trial.Expr) (ih : Evaluation body)
    (p : Program) (initial : Trial.Start) (s : State) (inner outer : Context)
    (site bid : Nat) (rest : List Task) (frames : List Trial.Frame)
    (q : Trial.RunState) (raw : Raw) (u : Trial.RunState)
    (hr : Reachable p initial s)
    (ht : s.tasks = .eval (embed body) (child inner site) ::
      .branchResult bid inner outer :: rest)
    (ha : s.answer = none) (hf : Future rest frames) (he : Enclosing inner s)
    (hi : inner.invocation = outer.invocation)
    (hb : inner.branches = bid :: outer.branches) (hq : eraseLog q = observe s)
    (hu : (do
      let w ← Trial.evalC .approved body inner.env frames inner.branches
      Trial.finishBranch bid inner.env outer.env w) q = (.ok raw,u)) :
    ∃ ticks t v, advance p ticks s = .ok t ∧ Reachable p initial t ∧
      t.tasks = rest ∧ t.slots = v :: s.slots ∧ v.raw = raw ∧
      t.answer = none ∧ eraseLog u = observe t ∧ Enclosing outer t := by
  obtain ⟨w,z,hw,hfinish⟩ := trial_bind_success _ _ _ _ _ hu
  obtain ⟨n,a,v,hxa,hra,hta,hsa,hva,haa,hoa,hena⟩ :=
    ih p initial s (child inner site) (.branchResult bid inner outer :: rest)
      frames q.log w z hr ht ha (future_silent _ (fun _ => rfl) hf)
      (by simpa [Enclosing,child] using he)
      (by simpa [child,logged_of_exact s q hq] using hw)
  obtain ⟨m,t,hxt,hrt,htt,hst,hat,hot,hent,hraw⟩ :=
    match_finishBranch p initial a bid inner outer rest v s.slots z.log raw u
      hra hta hsa haa hi hb (by simpa [Enclosing,child] using hena)
      (by rw [hva,logged_of_exact a z hoa]; exact hfinish)
  refine ⟨n+m,t,v,?_,hrt,htt,hst.trans hsa,hraw.symm,hat,hot,hent⟩
  rw [advance_add,hxa]; exact hxt

/-- Complete match evaluation, from only the three recursive evaluation IHs. -/
theorem evaluation_match {scrut empty body : Trial.Expr} {head tail : String}
    (hscrut : Evaluation scrut) (hempty : Evaluation empty) (hbody : Evaluation body) :
    Evaluation (.matchE scrut empty head tail body) := by
  intro p initial s ctx rest frames log raw u hr htasks hs hf hen hu
  rw [eval_match_decompose] at hu
  obtain ⟨cv,q,hq,hk⟩ := trial_bind_success _ _ _ _ _ hu
  obtain ⟨token,entered,henter,hk⟩ := trial_bind_success _ _ _ _ _ hk
  cases token
  have hentered : entered = {q with scope := ctx.env.reverse.map Prod.snd} :=
    (congrArg Prod.snd henter).symm
  subst entered
  cases cv with
  | num n | bool b => cases congrArg Prod.fst hk
  | list addr =>
    obtain ⟨n,a,v,hxa,hra,hta,hsa,hva,haa,hoa,hena⟩ :=
      match_operand scrut empty body head tail hscrut p initial s ctx rest frames
        log (.list addr) q hr htasks hs hf hen hq
    have hnext : q.nextBranch = a.nextBranch := by
      exact congrArg Trial.RunState.nextBranch (logged_of_exact a q hoa).symm
    let inner : Context := {ctx with branches := a.nextBranch :: ctx.branches}
    cases addr with
    | none =>
      obtain ⟨bid,fresh,hfresh,hk⟩ := trial_bind_success _ _ _ _ _ hk
      have hbid : bid = a.nextBranch := by
        simpa [Trial.freshBranch,hnext] using Except.ok.inj (congrArg Prod.fst hfresh).symm
      have hfresh' : fresh = {q with
          scope := ctx.env.reverse.map Prod.snd, nextBranch := a.nextBranch+1} := by
        simpa [Trial.freshBranch,hnext] using (congrArg Prod.snd hfresh).symm
      subst bid
      subst fresh
      obtain ⟨token,decision,hd,hk⟩ := trial_bind_success _ _ _ _ _ hk
      cases token
      obtain ⟨token,clean,hclean,hk⟩ := trial_bind_success _ _ _ _ _ hk
      cases token
      obtain ⟨token,entered,henter,hk⟩ := trial_bind_success _ _ _ _ _ hk
      cases token
      obtain ⟨token,started,hstart,hbranch⟩ := trial_bind_success _ _ _ _ _ hk
      cases token
      let next := [.branchStart inner,.eval (embed empty) (child inner 1),
        .branchResult a.nextBranch inner ctx] ++ rest
      obtain ⟨d,hxd,hrd,htd,hsd,had,hod,hend⟩ :=
        match_choose_exact p initial a ctx empty body head tail rest v s.slots none q decision
          hra hta hsa hva haa hena hoa hd
      have hfn : Future next (⟨empty,Trial.toFEnv ctx.env⟩::frames) :=
        future_silent _ (fun _ => rfl)
          (future_eval _ _ (future_silent _ (fun _ => rfl) hf))
      obtain ⟨m,z,hxz,hrz,htz,hsz,haz,hoz,henz⟩ :=
        TrialCleanup.cleanup_bridge p initial d inner next ctx.env _ q.log clean
          hrd htd had hfn hend (by rw [hod]; exact hclean)
      obtain ⟨w,hxw,hrw,htw,hsw,haw,how,henw⟩ :=
        match_start_exact p initial z inner _ clean started hrz htz haz henz hoz
          (by
            simpa only [inner, bind, ExceptT.bind, ExceptT.mk, StateT.bind,
              ExceptT.bindCont, henter] using hstart)
      obtain ⟨k,t,result,hxt,hrt,htt,hst,hraw,hat,hot,hent⟩ :=
        match_body_finish empty hempty p initial w inner ctx 1 a.nextBranch rest frames
          started raw u hrw htw haw hf henw rfl rfl
          (by rw [← how]; rfl) (by simpa [inner] using hbranch)
      refine ⟨n+1+m+1+k,t,result,?_,hrt,htt,?_,hraw,hat,hot,hent⟩
      · rw [advance_add,advance_add,advance_add,advance_add,hxa]
        simp only [bind,Except.bind,hxd,hxz,hxw,hxt]
      · rw [hst,hsw,hsz,hsd]; rfl
    | some addr =>
      obtain ⟨cell0,read,hread,hk⟩ := trial_bind_success _ _ _ _ _ hk
      have hread' : read = {q with scope := ctx.env.reverse.map Prod.snd} := by
        cases hc : q.mem.find? addr with
        | none => simp [Trial.getLiveCell,Trial.getCell,hc] at hread; cases hread
        | some c =>
          cases hstatus : c.status <;>
            simp [Trial.getLiveCell,Trial.getCell,hc,hstatus] at hread
          · simpa using (congrArg Prod.snd hread).symm
          · cases congrArg Prod.fst hread
      subst read
      obtain ⟨bid,fresh,hfresh,hk⟩ := trial_bind_success _ _ _ _ _ hk
      have hbid : bid = a.nextBranch := by
        simpa [Trial.freshBranch,hnext] using Except.ok.inj (congrArg Prod.fst hfresh).symm
      have hfresh' : fresh = {q with
          scope := ctx.env.reverse.map Prod.snd, nextBranch := a.nextBranch+1} := by
        simpa [Trial.freshBranch,hnext] using (congrArg Prod.snd hfresh).symm
      subst bid
      subst fresh
      obtain ⟨token,decision,hd,hk⟩ := trial_bind_success _ _ _ _ _ hk
      cases token
      obtain ⟨token,clean,hclean,hk⟩ := trial_bind_success _ _ _ _ _ hk
      cases token
      obtain ⟨env,started,hprefix,hbranch⟩ := trial_bind_success _ _ _ _ _ hk
      let next := .decompose head tail (embed body) a.nextBranch inner :: rest
      obtain ⟨d,hxd,hrd,htd,hsd,had,hod,hend⟩ :=
        match_choose_exact p initial a ctx empty body head tail rest v s.slots (some addr)
          q decision hra hta hsa hva haa hena hoa hd
      have hfn : Future next
          (⟨body,(tail,none)::(head,none)::Trial.toFEnv ctx.env⟩::frames) :=
        future_decompose inner body head tail a.nextBranch hf
      obtain ⟨m,z,hxz,hrz,htz,hsz,haz,hoz,henz⟩ :=
        TrialCleanup.cleanup_bridge p initial d inner next ctx.env _ q.log clean
          hrd htd had hfn hend (by rw [hod]; exact hclean)
      have hsv : z.slots = v :: s.slots := hsz.trans (hsd.trans hsa)
      have hp : matchDecomposePrefix head tail body inner.env a.nextBranch addr
          (logged z clean.log) = (.ok env,started) := by
        rw [logged_of_exact z clean hoz]; exact hprefix
      obtain ⟨ph,pt,cell,mem,hvalue,hfind,hl,hn,hop,hstep,hrstep,hestep⟩ :=
        match_decompose_progress p initial z inner head tail body a.nextBranch addr
          rest v s.slots hrz htz hsv hva haz henz (by simp [inner])
      have hdecomp := if hc : cell.count = 1 then
          match_decompose_unique p initial z inner head tail body a.nextBranch addr rest
            v s.slots cell clean.log env started hrz htz hsv hva haz henz
            (by simp [inner]) hfind hc hp
        else
          match_decompose_shared p initial z inner head tail body a.nextBranch addr rest
            v s.slots cell clean.log env started hrz htz hsv hva haz henz
            (by simp [inner]) hfind hc hp
      obtain ⟨j,w,hxw,hrw,htw,hsw,haw,henv,how,henw⟩ := hdecomp
      let branch : Context := {inner with env :=
        (tail,z.nextBinding+1)::(head,z.nextBinding)::inner.env}
      obtain ⟨k,t,result,hxt,hrt,htt,hst,hraw,hat,hot,hent⟩ :=
        match_body_finish body hbody p initial w branch ctx 2 a.nextBranch rest frames
          started raw u hrw (by simpa [branch,inner] using htw) haw hf henw rfl rfl how
          (by simpa [branch,inner,henv] using hbranch)
      refine ⟨n+1+m+j+k,t,result,?_,hrt,htt,?_,hraw,hat,hot,hent⟩
      · rw [advance_add,advance_add,advance_add,advance_add,hxa]
        simp only [bind,Except.bind,hxd,hxz,hxw,hxt]
      · rw [hst,hsw]

end Full.Proofs.TrialExecution

#print axioms Full.Proofs.TrialExecution.evaluation_match
