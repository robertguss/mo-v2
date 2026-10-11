import Full.Proofs.TrialExpressionMatchDecompose
import Full.Proofs.ForwardBindingsEnvironment

namespace Full.Proofs.TrialExecution
open Counted Statements TrialCompatibilitySimulation TrialRelease TrialSimulationRelease

theorem match_decompose_unique (p : Program) (initial : Trial.Start) (s : State)
    (ctx : Context) (head tail : String) (body : Trial.Expr) (bid addr : Nat)
    (rest : List Task) (v : Slot) (older : List Slot) (cell : Trial.Cell)
    (log : List Trial.LogEvent) (env : Trial.Env) (u : Trial.RunState)
    (hr : Reachable p initial s)
    (ht : s.tasks = .decompose head tail (embed body) bid ctx :: rest)
    (hv : s.slots = v::older) (hraw : v.raw = .list (some addr))
    (ha : s.answer = none) (he : Enclosing ctx s) (hb : bid ∈ ctx.branches)
    (hcell : s.mem.find? addr = some cell) (hcount : cell.count = 1)
    (hu : matchDecomposePrefix head tail body ctx.env bid addr (logged s log) =
      (.ok env,u)) :
    let inner := {ctx with env := (tail,s.nextBinding+1)::(head,s.nextBinding)::ctx.env}
    ∃ ticks t, advance p ticks s = .ok t ∧ Reachable p initial t ∧
      t.tasks = .eval (embed body) (child inner 2) ::
        .branchResult bid inner {ctx with branches := ctx.branches.tail} :: rest ∧
      t.slots = older ∧ t.answer = none ∧ env = inner.env ∧
      eraseLog u = observe t ∧ Enclosing inner t := by
  cases hlink : cell.link with
  | none =>
    obtain ⟨t,ht⟩ := match_decompose_unique_nil p initial s ctx head tail body bid addr
      rest v older cell log env u hr ht hv hraw ha he hb hcell hcount hlink hu
    exact ⟨2,t,ht⟩
  | some a =>
    obtain ⟨ph,pt,c,mem,hvalue,hfind,hl,hn,hop,hstep,hrd,hed⟩ :=
      match_decompose_progress p initial s ctx head tail body bid addr rest v older
        hr ht hv hraw ha he hb
    rw [hcell] at hfind
    cases Option.some.inj hfind
    have hm : s.mem.markSetAside addr = .ok mem := by simpa [hcount] using hop
    let inner : Context := {ctx with env := (tail,s.nextBinding+1)::(head,s.nextBinding)::ctx.env}
    let change := matchDecomposeChange s ctx head tail body bid addr rest older ph pt cell mem
    let d := commit change
    let next := .branchStart inner :: .eval (embed body) (child inner 2) ::
      .branchResult bid inner {ctx with branches := ctx.branches.tail} :: rest
    let used := Trial.usesBinding body (Trial.toFEnv inner.env) (s.nextBinding+1)
    have hold : (s.bindings.map (·.record)).map
        (fun b => if b.id = s.nextBinding+1 then {b with status := .holding} else b) =
        s.bindings.map (·.record) := by
      rw [List.map_map]
      apply List.map_congr_left
      intro b hb
      have hbound := BindingIdentity.reachable_bound hr hb
      simp [show b.record.id ≠ s.nextBinding+1 by omega]
    have hfirst : (do
        let c ← Trial.getLiveCell addr
        let hid ← Trial.newBinding head (.num c.item) .noHolder
        let tid ← Trial.newBinding tail (.list c.link) .noHolder
        Trial.popPending (.list (some addr))
        Trial.memOp (fun m => m.markSetAside addr)
        modify fun s => {s with setAside := (bid,addr)::s.setAside}
        Trial.setBindingStatus tid .holding
        Trial.enter ((tail,tid)::(head,hid)::ctx.env)
        Trial.snapshot .matchStep4Done : Trial.M Unit) (logged s log) =
        (.ok (), logged d log) := by
      have hs := match_decompose_snapshot change .matchStep4Done
        (by simp [change, matchDecomposeChange, hcount]) log
      simpa [Trial.getLiveCell, Trial.getCell, Trial.newBinding, Trial.popPending,
        Trial.memOp, Trial.enter, Trial.setBindingStatus, logged, observe, pending,
        hv, hraw, hcell, hl, hm, hcount, hlink, d, change, matchDecomposeChange,
        makeBinding, hold, Nat.add_assoc, -List.map_map] using hs
    have hprefix : matchDecomposePrefix head tail body ctx.env bid addr (logged s log) =
        (do
          if !used then Trial.giveUpBinding .approved (s.nextBinding+1) else pure ()
          Trial.enter inner.env
          Trial.snapshot .branchStarts
          pure inner.env) (logged d log) := by
      simp [matchDecomposePrefix, Trial.getLiveCell, Trial.getCell, Trial.newBinding,
        Trial.shouldSetAside, Trial.Variant.approved, hcell, hcount, hlink, hl,
        Trial.popPending, Trial.memOp, Trial.enter, Trial.setBindingStatus, hm,
        logged, observe, pending, hv, hraw, inner, used] at hfirst ⊢
      rw [hfirst]
    have hd : d.tasks = (if !used then [.giveBinding (s.nextBinding+1)] else []) ++ next := by
      simp [d, change, matchDecomposeChange, hcount, hlink, inner, next, used, commit]
    have hda : d.answer = none := by
      simpa [d, change, matchDecomposeChange, hcount, commit] using ha
    have hens : Enclosing inner d := by simpa [Enclosing, inner] using hed
    rw [hprefix] at hu
    have hready : ∃ k q finalLog, advance p k d = .ok q ∧ Reachable p initial q ∧
        q.tasks = next ∧ q.slots = older ∧ q.answer = none ∧ Enclosing inner q ∧
        (do Trial.enter inner.env; Trial.snapshot .branchStarts; pure inner.env)
          (logged q finalLog) = (.ok env,u) := by
      cases hc : used with
      | true =>
        refine ⟨0,d,log,rfl,hrd,?_,?_,hda,hens,?_⟩
        · simpa [hc] using hd
        · simp [d, change, matchDecomposeChange, hcount, commit]
        · simpa [hc] using hu
      | false =>
        have htd : d.tasks = .giveBinding (s.nextBinding+1) :: next := by simpa [hc] using hd
        obtain ⟨b,a',hfind,hhold,hval⟩ := ReleaseQueue.reachable_binding
          (s := d) (bid := s.nextBinding+1) hrd (by simp [htd])
        have hsuccess : (Trial.giveUpBinding .approved (s.nextBinding+1) >>=
            fun _ => do Trial.enter inner.env; Trial.snapshot .branchStarts; pure inner.env)
            (logged d log) = (.ok env,u) := by simpa [hc] using hu
        obtain ⟨result,z,hz,hlast⟩ := trial_bind_success _ _ _ _ _ hsuccess
        cases result
        have path := binding_cascade_of_success p initial d (s.nextBinding+1) b a' next z
          hrd htd hda hfind hhold hval hz
        obtain ⟨k,q,finalLog,hx,hqt,hqs,hqa,htrial,hbs,hrs⟩ :=
          cascade_binding p d (s.nextBinding+1) b a' next htd hda hfind hhold hval path log
        have hw : logged q finalLog = z := congrArg Prod.snd (htrial.symm.trans hz)
        refine ⟨k,q,finalLog,hx,reachable_advance p initial d q k hrd hx,hqt,?_,hqa,?_,?_⟩
        · rw [hqs]; simp [d, change, matchDecomposeChange, hcount, commit]
        · simpa [Enclosing, hrs] using hens
        · simpa [hw] using hlast
    obtain ⟨k,q,finalLog,hk,hrq,hqt,hqs,hqa,hqe,huq⟩ := hready
    obtain ⟨t,hstart,hrt,htt,hst,hat,hentered,hmem,hsnaps,hent⟩ :=
      control_branch_start p initial q inner _ hrq hqt hqa hqe
    have htcommit : t = commit ⟨{q with tasks := next.tail, entered := inner.env},
        ⟨"BranchStart",some .branchStarts⟩,none⟩ := by
      simpa [advance, step, transition, hqt, hqa, next] using hstart.symm
    have hlast : (do Trial.enter inner.env; Trial.snapshot .branchStarts; pure inner.env)
        (logged q finalLog) = (.ok inner.env, logged t finalLog) := by
      rw [htcommit]
      have hs := match_decompose_snapshot
        ⟨{q with tasks := next.tail, entered := inner.env},⟨"BranchStart",some .branchStarts⟩,none⟩
        .branchStarts rfl finalLog
      simpa [Trial.enter, logged, observe, pending, Trial.snapshot] using
        congrArg (fun x => (x.1.map (fun _ => inner.env),x.2)) hs
    rw [hlast] at huq
    have henv : env = inner.env := (Except.ok.inj (congrArg Prod.fst huq)).symm
    have hus : u = logged t finalLog := (congrArg Prod.snd huq).symm
    refine ⟨1+k+1,t,?_,hrt,htt,?_,hat,henv,?_,hent⟩
    · change advance p (1+k+1) s = .ok t
      have hs : advance p 1 s = .ok d := hstep
      rw [advance_add, advance_add, hs]
      simp only [bind, Except.bind, hk, hstart]
    · rw [hst,hqs]
    · rw [hus]; rfl

end Full.Proofs.TrialExecution

#print axioms Full.Proofs.TrialExecution.match_decompose_unique
