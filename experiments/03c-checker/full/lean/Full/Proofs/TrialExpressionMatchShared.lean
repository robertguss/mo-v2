import Full.Proofs.TrialExpressionMatchDecompose

namespace Full.Proofs.TrialExecution
open Counted Statements TrialCompatibilitySimulation TrialRelease TrialSimulationRelease

/-- The shared arm up to (but not including) taking the scrutinee holder.
The optional acquisition retains its actual new-holder observation. -/
def matchSharedSetup (head tail : String) (body : Trial.Expr) (env : Trial.Env)
    (addr : Nat) : Trial.M Trial.Env := do
  let c ← Trial.getLiveCell addr
  let hid ← Trial.newBinding head (.num c.item) .noHolder
  let tid ← Trial.newBinding tail (.list c.link) .noHolder
  let inner := (tail,tid)::(head,hid)::env
  match c.link with
  | some a =>
    if Trial.usesBinding body (Trial.toFEnv inner) tid then
      Trial.addHolder a
      Trial.setBindingStatus tid .holding
      Trial.enter inner
      Trial.snapshot .newHolder
    else pure ()
  | none => pure ()
  pure inner

theorem matchShared_factor (s : State) (log : List Trial.LogEvent)
    (head tail : String) (body : Trial.Expr) (env : Trial.Env) (bid addr : Nat)
    (cell : Trial.Cell) (hf : s.mem.find? addr = some cell)
    (hl : cell.status = .live) (hn : cell.count ≠ 1) :
    matchDecomposePrefix head tail body env bid addr (logged s log) =
      (do
        let inner ← matchSharedSetup head tail body env addr
        Trial.popPending (.list (some addr))
        Trial.giveUpLink .approved (some addr)
        Trial.enter inner
        Trial.snapshot .matchStep4Done
        Trial.enter inner
        Trial.snapshot .branchStarts
        pure inner) (logged s log) := by
  simp only [matchDecomposePrefix, matchSharedSetup, bind_assoc]
  simp [Trial.getLiveCell, Trial.getCell,
    logged, observe, hf, hl, Trial.shouldSetAside, Trial.Variant.approved, hn,
    Trial.newBinding, bind_assoc]
  cases cell.link <;> simp
  split <;> simp
  split <;> simp [Trial.setBindingStatus, Trial.enter, Trial.snapshot]

/-- Updating the fresh tail cannot change the status of any older binding. -/
theorem matchShared_old_status (hr : Reachable p initial s) :
    (s.bindings.map (·.record)).map
      (fun b => if b.id == s.nextBinding+1 then {b with status := .holding} else b) =
      s.bindings.map (·.record) := by
  rw [List.map_map]
  apply List.map_congr_left
  intro b hb
  have hn := BindingIdentity.reachable_bound hr hb
  have hne : b.record.id ≠ s.nextBinding+1 := by omega
  simp [hne]

theorem matchShared_setup_exact (p : Program) (initial : Trial.Start) (s : State)
    (ctx : Context) (head tail : String) (body : Trial.Expr) (bid addr : Nat)
    (rest : List Task) (older : List Slot) (ph : Int) (pt : List Int)
    (cell : Trial.Cell) (mem : Trial.Memory) (log : List Trial.LogEvent)
    (env : Trial.Env) (u : Trial.RunState)
    (hr : Reachable p initial s) (hf : s.mem.find? addr = some cell)
    (hl : cell.status = .live) (hn : cell.count ≠ 1)
    (hop : (if Trial.usesBinding body
        (Trial.toFEnv ((tail,s.nextBinding+1)::(head,s.nextBinding)::ctx.env))
        (s.nextBinding+1) then match cell.link with
        | none => (Except.ok s.mem : Except String Trial.Memory)
        | some a => do
          let some c := s.mem.find? a | throw "missing tail cell"
          s.mem.setCount a (c.count+1)
      else .ok s.mem) = .ok mem)
    (hu : matchSharedSetup head tail body ctx.env addr (logged s log) = (.ok env,u)) :
    env = (tail,s.nextBinding+1)::(head,s.nextBinding)::ctx.env ∧
      u = logged (commit (matchDecomposeChange s ctx head tail body bid addr rest
        older ph pt cell mem)) log := by
  have hold := matchShared_old_status hr
  cases hc : cell.link with
  | none =>
    have hm : mem = s.mem := by simpa [hc] using hop.symm
    subst mem
    simp [matchSharedSetup, Trial.getLiveCell, Trial.getCell, Trial.newBinding,
      hf, hl, hc, logged, observe] at hu
    simpa [logged, observe, commit, matchDecomposeChange, hn, hc, makeBinding, pending]
      using And.intro (Except.ok.inj (congrArg Prod.fst hu)).symm
        (congrArg Prod.snd hu).symm
  | some a =>
    cases used : Trial.usesBinding body
        (Trial.toFEnv ((tail,s.nextBinding+1)::(head,s.nextBinding)::ctx.env))
        (s.nextBinding+1) with
    | false =>
      have hm : mem = s.mem := by simpa [used] using hop.symm
      subst mem
      simp [matchSharedSetup, Trial.getLiveCell, Trial.getCell, Trial.newBinding,
        hf, hl, hc, used, logged, observe] at hu
      simpa [logged, observe, commit, matchDecomposeChange, hn, hc, used, makeBinding, pending]
        using And.intro (Except.ok.inj (congrArg Prod.fst hu)).symm
          (congrArg Prod.snd hu).symm
    | true =>
      cases ht : s.mem.find? a with
      | none => simp [used, hc, ht] at hop
      | some c =>
        have hm : s.mem.setCount a (c.count+1) = .ok mem := by
          simpa [used, hc, ht] using hop
        have hcl : c.status = .live := by
          cases hs : c.status
          · rfl
          · simp [matchSharedSetup, Trial.getLiveCell, Trial.getCell, Trial.newBinding,
              Trial.addHolder, logged, observe, hf, hl, hc, used, ht, hs] at hu
            have impossible := congrArg Prod.fst hu
            contradiction
        simp only [List.map_map, beq_iff_eq] at hold
        have hex : matchSharedSetup head tail body ctx.env addr (logged s log) =
            (.ok ((tail,s.nextBinding+1)::(head,s.nextBinding)::ctx.env),
              logged (commit (matchDecomposeChange s ctx head tail body bid addr rest
                older ph pt cell mem)) log) := by
          simp [matchSharedSetup, Trial.getLiveCell, Trial.getCell, Trial.newBinding,
            Trial.addHolder, Trial.memOp, Trial.setBindingStatus, Trial.enter,
            hf, hl, hc, ht, hcl, used, hm, logged, observe, hold,
            commit, matchDecomposeChange, hn, makeBinding, pending, Trial.snapshot,
            ← visible_projection]
        rw [hex] at hu
        exact ⟨(Except.ok.inj (congrArg Prod.fst hu)).symm,
          (congrArg Prod.snd hu).symm⟩

/-- Full shared-cell transfer for arbitrary tail and usedness. The successful
literal prefix supplies raw release success; F1 supplies its ghost certificate
at reachable boundaries. All observation fields, including the ordered
new-holder, holder-given-up, step-four and branch-start snapshots, are exact.
Only the textual log is erased. No transition-success premise is required. -/
theorem match_decompose_shared (p : Program) (initial : Trial.Start) (s : State)
    (ctx : Context) (head tail : String) (body : Trial.Expr) (bid addr : Nat)
    (rest : List Task) (v : Slot) (older : List Slot) (cell : Trial.Cell)
    (log : List Trial.LogEvent) (env : Trial.Env) (u : Trial.RunState)
    (hr : Reachable p initial s)
    (ht : s.tasks = .decompose head tail (embed body) bid ctx :: rest)
    (hv : s.slots = v::older) (hraw : v.raw = .list (some addr))
    (ha : s.answer = none) (he : Enclosing ctx s) (hb : bid ∈ ctx.branches)
    (hcell : s.mem.find? addr = some cell) (hcount : cell.count ≠ 1)
    (hu : matchDecomposePrefix head tail body ctx.env bid addr (logged s log) =
      (.ok env,u)) :
    let inner := {ctx with env := (tail,s.nextBinding+1)::(head,s.nextBinding)::ctx.env}
    ∃ ticks t, advance p ticks s = .ok t ∧ Reachable p initial t ∧
      t.tasks = .eval (embed body) (child inner 2) ::
        .branchResult bid inner {ctx with branches := ctx.branches.tail} :: rest ∧
      t.slots = older ∧ t.answer = none ∧ env = inner.env ∧
      eraseLog u = observe t ∧ Enclosing inner t := by
  obtain ⟨ph,pt,c,mem,hvalue,hfind,hl,hn,hop,hstep,hrd,hed⟩ :=
    match_decompose_progress p initial s ctx head tail body bid addr rest v older
      hr ht hv hraw ha he hb
  rw [hcell] at hfind
  cases Option.some.inj hfind
  simp only [show (cell.count == 1) = false from by simp [hcount], Bool.false_eq_true,
    ite_false] at hop
  let inner : Context := {ctx with env := (tail,s.nextBinding+1)::(head,s.nextBinding)::ctx.env}
  let change := matchDecomposeChange s ctx head tail body bid addr rest older ph pt cell mem
  let d := commit change
  let next := .eval (embed body) (child inner 2) ::
    .branchResult bid inner {ctx with branches := ctx.branches.tail} :: rest
  have hd : d.tasks = .givePending :: .matchComplete inner :: .branchStart inner :: next := by
    simp [d, change, matchDecomposeChange, hcount, inner, next, commit]
  have hds : d.slots = v::older := by
    simpa [d, change, matchDecomposeChange, hcount, commit] using hv
  have hda : d.answer = none := by
    simpa [d, change, matchDecomposeChange, hcount, commit] using ha
  have hens : Enclosing inner d := by simpa [Enclosing, inner] using hed
  rw [matchShared_factor s log head tail body ctx.env bid addr cell hcell hl hcount] at hu
  obtain ⟨setupEnv,w,hsetup,hrelease⟩ := trial_bind_success _ _ _ _ _ hu
  obtain ⟨henv,hw⟩ := matchShared_setup_exact p initial s ctx head tail body bid addr
    rest older ph pt cell mem log setupEnv w hr hcell hl hcount hop hsetup
  change setupEnv = inner.env at henv
  change w = logged d log at hw
  rw [henv,hw] at hrelease
  obtain ⟨token,z,hpop,htail⟩ := trial_bind_success _ _ _ _ _ hrelease
  cases token
  have hpopExact : Trial.popPending (.list (some addr)) (logged d log) =
      (.ok (), input d older log) := by
    simp [Trial.popPending, input, logged, observe, pending, hds, hraw]
  have hz : z = input d older log := (congrArg Prod.snd (hpop.symm.trans hpopExact))
  rw [hz] at htail
  obtain ⟨token,z',hgive,hlast⟩ := trial_bind_success _ _ _ _ _ htail
  cases token
  have hrawgive : Trial.giveUp .approved d.mem.cells.length addr (input d older log) =
      (.ok (),z') := by
    simpa [Trial.giveUpLink, input, logged, observe] using hgive
  have path := cascade_of_success_f1 Full.Proofs.f1 p initial
    (.matchComplete inner :: .branchStart inner :: next) older d.mem.cells.length d addr
    log z' hrd v hd hds hraw hda hrawgive
  obtain ⟨k,q,finalLog,hq,hqt,hqs,hqa,htrial,_,_,_,hreservations⟩ :=
    cascade_pending p (.matchComplete inner :: .branchStart inner :: next) older
      d.mem.cells.length d addr path v hd hds hraw hda log
  have hqreach := reachable_advance p initial d q k hrd hq
  have hqenc : Enclosing inner q := by
    intro r hm
    exact hens r (by simpa [hreservations] using hm)
  have hz' : z' = logged q finalLog := (congrArg Prod.snd (hrawgive.symm.trans htrial))
  rw [hz'] at hlast
  let complete : Change := ⟨{q with tasks := .branchStart inner :: next, entered := inner.env},
    ⟨"MatchComplete",some .matchStep4Done⟩,none⟩
  let b := commit complete
  have hx : advance p 1 q = .ok b := by
    simp [advance, step, transition, hqt, hqa, b, complete]
  have hcomplete : (do Trial.enter inner.env; Trial.snapshot .matchStep4Done : Trial.M Unit)
      (logged q finalLog) = (.ok (),logged b finalLog) := by
    simpa [Trial.enter, logged, observe, pending, b, complete, Trial.snapshot] using
      match_decompose_snapshot complete .matchStep4Done rfl finalLog
  have hbenc : Enclosing inner b := hqenc
  have hbreach := reachable_advance p initial q b 1 hqreach hx
  let start : Change := ⟨{b with tasks := next, entered := inner.env},
    ⟨"BranchStart",some .branchStarts⟩,none⟩
  let t := commit start
  have hbt : b.tasks = .branchStart inner :: next := rfl
  have hba : b.answer = none := hqa
  have hy : advance p 1 b = .ok t := by
    simp [advance, step, transition, hbt, hba, t, start]
  have hstart : (do Trial.enter inner.env; Trial.snapshot .branchStarts; pure inner.env)
      (logged b finalLog) = (.ok inner.env, logged t finalLog) := by
    simpa [Trial.enter, logged, observe, pending, t, start, Trial.snapshot] using
      congrArg (fun x => (x.1.map (fun _ => inner.env),x.2))
        (match_decompose_snapshot start .branchStarts rfl finalLog)
  have hlast' : (do
      Trial.enter inner.env
      Trial.snapshot .matchStep4Done
      Trial.enter inner.env
      Trial.snapshot .branchStarts
      pure inner.env) (logged q finalLog) = (.ok inner.env,logged t finalLog) := by
    rw [← bind_assoc]
    rw [Trial.Proofs.m_bind_apply, hcomplete]
    exact hstart
  rw [hlast'] at hlast
  have huFinal : u = logged t finalLog := (congrArg Prod.snd hlast).symm
  refine ⟨1+k+1+1,t,?_,reachable_advance p initial b t 1 hbreach hy,
    rfl,?_,hqa,(Except.ok.inj (congrArg Prod.fst hlast)).symm,?_,hbenc⟩
  · rw [advance_add, advance_add, advance_add, hstep]
    change (advance p k d >>= advance p 1 >>= advance p 1) = .ok t
    rw [hq]
    change (advance p 1 q >>= advance p 1) = .ok t
    rw [hx]
    exact hy
  · exact hqs
  · rw [huFinal]
    rfl

end Full.Proofs.TrialExecution

#print axioms Full.Proofs.TrialExecution.match_decompose_shared
