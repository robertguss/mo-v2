import Full.Proofs.TrialExpressionMatch
import Full.Proofs.ProgressHeap

namespace Full.Proofs.TrialExecution
open Counted Statements TrialCompatibilitySimulation TrialRelease TrialSimulationRelease

/-- Literal nonempty-match prefix, beginning at the second live-cell read and
ending before recursive evaluation. No evaluator definition is changed. -/
def matchDecomposePrefix (head tail : String) (body : Trial.Expr)
    (env : Trial.Env) (bid addr : Nat) : Trial.M Trial.Env := do
  let c ← Trial.getLiveCell addr
  let hid ← Trial.newBinding head (.num c.item) .noHolder
  let tid ← Trial.newBinding tail (.list c.link) .noHolder
  let inner := (tail,tid) :: (head,hid) :: env
  let used := Trial.usesBinding body (Trial.toFEnv inner) tid
  if Trial.shouldSetAside .approved c.count then
    Trial.popPending (.list (some addr))
    Trial.memOp (fun m => m.markSetAside addr)
    modify fun s => { s with setAside := (bid,addr) :: s.setAside }
    match c.link with
    | some _ => Trial.setBindingStatus tid .holding
    | none => pure ()
    Trial.enter inner
    Trial.snapshot .matchStep4Done
    match c.link with
    | some _ => if !used then Trial.giveUpBinding .approved tid else pure ()
    | none => pure ()
  else
    match c.link with
    | some rest =>
      if used then
        Trial.addHolder rest
        Trial.setBindingStatus tid .holding
        Trial.enter inner
        Trial.snapshot .newHolder
      else pure ()
    | none => pure ()
    Trial.popPending (.list (some addr))
    Trial.giveUpLink .approved (some addr)
    Trial.enter inner
    Trial.snapshot .matchStep4Done
  Trial.enter inner
  Trial.snapshot .branchStarts
  pure inner

/-- The actual evaluator's nonempty arm factors through the literal prefix.
This equation also fixes the recursive branch environment and branch stack. -/
theorem eval_match_decompose (scrut empty body : Trial.Expr) (head tail : String)
    (env : Trial.Env) (frames : List Trial.Frame) (branches : List Nat) :
    Trial.evalC .approved (.matchE scrut empty head tail body) env frames branches =
      (do
        let r ← Trial.evalC .approved scrut env
          (⟨empty, Trial.toFEnv env⟩ ::
            ⟨body, (tail,none)::(head,none)::Trial.toFEnv env⟩ :: frames) branches
        Trial.enter env
        match r with
        | .list none =>
          let bid ← Trial.freshBranch
          Trial.snapshot .branchChosen
          Trial.giveUpDead .approved env (⟨empty,Trial.toFEnv env⟩::frames)
          Trial.enter env
          Trial.snapshot .branchStarts
          let w ← Trial.evalC .approved empty env frames (bid::branches)
          Trial.finishBranch bid env env w
        | .list (some addr) =>
          let _ ← Trial.getLiveCell addr
          let bid ← Trial.freshBranch
          Trial.snapshot .branchChosen
          Trial.giveUpDead .approved env
            (⟨body,(tail,none)::(head,none)::Trial.toFEnv env⟩::frames)
          let inner ← matchDecomposePrefix head tail body env bid addr
          let w ← Trial.evalC .approved body inner frames (bid::branches)
          Trial.finishBranch bid inner env w
        | _ => throw "stuck: match on a non-list" : Trial.M Raw) := by
  simp only [Trial.evalC]
  apply bind_congr
  intro r
  apply bind_congr
  intro token
  cases r with
  | num n | bool b => rfl
  | list addr =>
    cases addr with
    | none => rfl
    | some addr =>
      simp only [matchDecomposePrefix, bind_assoc]
      apply bind_congr
      intro c0
      apply bind_congr
      intro bid
      apply bind_congr
      intro chosen
      apply bind_congr
      intro cleaned
      apply bind_congr
      intro c
      apply bind_congr
      intro hid
      apply bind_congr
      intro tid
      cases c.link <;>
        split <;> simp [bind_assoc]
      all_goals split <;> simp [bind_assoc]

/-- Proposed data for the genuine decompose transfer. The memory operation is
not assumed successful: `match_decompose_progress` obtains it from F1. -/
def matchDecomposeChange (s : State) (ctx : Context) (head tail : String)
    (body : Trial.Expr) (bid addr : Nat) (rest : List Task)
    (older : List Slot) (ph : Int) (pt : List Int) (cell : Trial.Cell)
    (mem : Trial.Memory) : Change :=
  let hid := s.nextBinding
  let tid := hid + 1
  let inner := { ctx with env := (tail,tid)::(head,hid)::ctx.env }
  let used := Trial.usesBinding body (Trial.toFEnv inner.env) tid
  let next := [.branchStart inner, .eval (embed body) (child inner 2),
    .branchResult bid inner { ctx with branches := ctx.branches.tail }] ++ rest
  let bindings := s.bindings ++ [
    makeBinding hid head ⟨.num cell.item,.num ph⟩ ctx.invocation s!"{ctx.site}/head",
    makeBinding tid tail ⟨.list cell.link,.list pt⟩ ctx.invocation s!"{ctx.site}/tail"
      (cell.count == 1 || used)]
  if cell.count == 1 then
    ⟨{ s with
      mem, bindings, slots := older, nextBinding := tid+1,
      entered := inner.env, reservations := ⟨ctx.invocation,bid,addr⟩::s.reservations,
      edges := s.edges.filter (fun q => q.1 != addr),
      tasks := (if cell.link.isSome && !used then [.giveBinding tid] else []) ++ next },
      ⟨"Decompose",some .matchStep4Done⟩,none⟩
  else
    ⟨{ s with
      mem, bindings, nextBinding := tid+1,
      entered := if used && cell.link.isSome then inner.env else s.entered,
      tasks := [.givePending,.matchComplete inner] ++ next },
      ⟨"Decompose",if used && cell.link.isSome then some .newHolder else none⟩,none⟩

/-- Actual reachable progress classifies both ownership cases, including the
ghost decomposition derived from readback. No positive transition is a premise. -/
theorem match_decompose_progress (p : Program) (initial : Trial.Start) (s : State)
    (ctx : Context) (head tail : String) (body : Trial.Expr) (bid addr : Nat)
    (rest : List Task) (v : Slot) (older : List Slot)
    (hr : Reachable p initial s)
    (ht : s.tasks = .decompose head tail (embed body) bid ctx :: rest)
    (hv : s.slots = v::older) (hraw : v.raw = .list (some addr))
    (ha : s.answer = none) (he : Enclosing ctx s) (hb : bid ∈ ctx.branches) :
    ∃ ph pt cell mem,
      v.value = .list (ph::pt) ∧ s.mem.find? addr = some cell ∧
      cell.status = .live ∧ cell.count ≠ 0 ∧
      (if cell.count == 1 then s.mem.markSetAside addr else
        if Trial.usesBinding body
            (Trial.toFEnv ((tail,s.nextBinding+1)::(head,s.nextBinding)::ctx.env))
            (s.nextBinding+1) then
          match cell.link with
          | none => .ok s.mem
          | some a => do
            let some c := s.mem.find? a | throw "missing tail cell"
            s.mem.setCount a (c.count+1)
        else .ok s.mem) = .ok mem ∧
      let change := matchDecomposeChange s ctx head tail body bid addr rest older ph pt cell mem
      advance p 1 s = .ok (commit change) ∧
      Reachable p initial (commit change) ∧ Enclosing ctx (commit change) := by
  obtain ⟨ph,pt,hvalue⟩ := Full.Proofs.Progress.nonempty_value
    (Full.Proofs.f1.2 p initial s hr).1 (by simp [hv]) hraw
  obtain ⟨actual,hstep,_⟩ := (Full.Proofs.f1.2 p initial s hr).2.2 ha
  cases hc : transition p s with
  | error why => simp [step, ha, hc] at hstep
  | ok change =>
    cases hf : s.mem.find? addr with
    | none => simp [transition, ht, hv, hraw, hvalue, hf] at hc
    | some cell =>
      have hl : cell.status = .live := by
        cases hstatus : cell.status <;>
          simp_all [transition]
      have hn : cell.count ≠ 0 := by
        intro hz
        simp [transition, ht, hv, hraw, hvalue, hf, hz] at hc
      let op : Except String Trial.Memory :=
        if cell.count == 1 then s.mem.markSetAside addr else
          if Trial.usesBinding body
              (Trial.toFEnv ((tail,s.nextBinding+1)::(head,s.nextBinding)::ctx.env))
              (s.nextBinding+1) then
            match cell.link with
            | none => .ok s.mem
            | some a => do
              let some c := s.mem.find? a | throw "missing tail cell"
              s.mem.setCount a (c.count+1)
          else .ok s.mem
      have hnorm : transition p s = (do
          let mem ← op
          pure (matchDecomposeChange s ctx head tail body bid addr rest older ph pt cell mem)) := by
        simp only [transition, ht, hv, hraw, hvalue, hf]
        simp [hl, hn, uses_embed, op, matchDecomposeChange, hv]
        split
        · rfl
        · split
          · cases cell.link with
            | none => rfl
            | some a =>
              simp only
              cases hfind : s.mem.find? a <;> simp
          · rfl
      cases hm : op with
      | error why => rw [hnorm, hm] at hc; cases hc
      | ok mem =>
        have hchange : change = matchDecomposeChange s ctx head tail body bid addr rest older ph pt cell mem := by
          rw [hnorm, hm] at hc
          exact (Except.ok.inj hc).symm
        subst change
        have hex : advance p 1 s = .ok (commit
            (matchDecomposeChange s ctx head tail body bid addr rest older ph pt cell mem)) := by
          simp [advance, step, ha, hc]
        refine ⟨ph,pt,cell,mem,hvalue,rfl,hl,hn,hm,hex,
          reachable_advance p initial s _ 1 hr hex, ?_⟩
        intro r hmem
        simp only [matchDecomposeChange] at hmem
        split at hmem
        · simp only [commit, List.mem_cons] at hmem
          rcases hmem with rfl | hmem
          · exact ⟨rfl,hb⟩
          · exact he r hmem
        · exact he r hmem

/-- Snapshot comparison retains every observation field, not just landmarks. -/
theorem match_decompose_snapshot (change : Change) (kind : Trial.StepKind)
    (hk : change.action.landmark = some kind) (log : List Trial.LogEvent) :
    Trial.snapshot kind change.branchValue (logged change.state log) =
      (.ok (), logged (commit change) log) := by
  have hs := commit_snapshot change kind hk
  simp [Trial.snapshot, logged, observe, commit, hk] at hs ⊢
  rw [hs.symm]
  rfl

/-- A complete exact prefix theorem for a unique cell with empty tail. It stops
at the real body task, preserves older slots, and makes no progress assumption. -/
theorem match_decompose_unique_nil (p : Program) (initial : Trial.Start) (s : State)
    (ctx : Context) (head tail : String) (body : Trial.Expr) (bid addr : Nat)
    (rest : List Task) (v : Slot) (older : List Slot) (cell : Trial.Cell)
    (log : List Trial.LogEvent) (env : Trial.Env) (u : Trial.RunState)
    (hr : Reachable p initial s)
    (ht : s.tasks = .decompose head tail (embed body) bid ctx :: rest)
    (hv : s.slots = v::older) (hraw : v.raw = .list (some addr))
    (ha : s.answer = none) (he : Enclosing ctx s) (hb : bid ∈ ctx.branches)
    (hcell : s.mem.find? addr = some cell) (hcount : cell.count = 1)
    (hlink : cell.link = none)
    (hu : matchDecomposePrefix head tail body ctx.env bid addr (logged s log) =
      (.ok env,u)) :
    let inner := {ctx with env := (tail,s.nextBinding+1)::(head,s.nextBinding)::ctx.env}
    ∃ t, advance p 2 s = .ok t ∧ Reachable p initial t ∧
      t.tasks = .eval (embed body) (child inner 2) ::
        .branchResult bid inner {ctx with branches := ctx.branches.tail} :: rest ∧
      t.slots = older ∧ t.answer = none ∧ env = inner.env ∧
      eraseLog u = observe t ∧ Enclosing inner t := by
  obtain ⟨ph,pt,c,mem,hvalue,hfind,hl,hn,hop,hstep,hrd,hed⟩ :=
    match_decompose_progress p initial s ctx head tail body bid addr rest v older
      hr ht hv hraw ha he hb
  rw [hcell] at hfind
  cases Option.some.inj hfind
  have hm : s.mem.markSetAside addr = .ok mem := by
    simpa [hcount] using hop
  let inner : Context := {ctx with env := (tail,s.nextBinding+1)::(head,s.nextBinding)::ctx.env}
  let change := matchDecomposeChange s ctx head tail body bid addr rest older ph pt cell mem
  let d := commit change
  let next := .eval (embed body) (child inner 2) ::
    .branchResult bid inner {ctx with branches := ctx.branches.tail} :: rest
  have hd : d.tasks = .branchStart inner :: next := by
    simp [d, change, matchDecomposeChange, hcount, hlink, inner, next, commit]
  have hda : d.answer = none := by
    simpa [d, change, matchDecomposeChange, hcount, commit] using ha
  have hens : Enclosing inner d := by simpa [Enclosing, inner] using hed
  obtain ⟨t,hstart,hrt,htt,hst,hat,hentered,hmem,hsnaps,hent⟩ :=
    control_branch_start p initial d inner next hrd hd hda hens
  have hfirst : (do
      let c ← Trial.getLiveCell addr
      let hid ← Trial.newBinding head (.num c.item) .noHolder
      let tid ← Trial.newBinding tail (.list c.link) .noHolder
      Trial.popPending (.list (some addr))
      Trial.memOp (fun m => m.markSetAside addr)
      modify fun s => {s with setAside := (bid,addr)::s.setAside}
      Trial.enter ((tail,tid)::(head,hid)::ctx.env)
      Trial.snapshot .matchStep4Done : Trial.M Unit) (logged s log) =
      (.ok (), logged d log) := by
    have hs := match_decompose_snapshot change .matchStep4Done
      (by simp [change, matchDecomposeChange, hcount]) log
    simpa [Trial.getLiveCell, Trial.getCell, Trial.newBinding, Trial.popPending,
      Trial.memOp, Trial.enter, logged, observe, pending, hv, hraw, hcell, hl,
      hm, hcount, hlink, d, change, matchDecomposeChange, makeBinding] using hs
  have hprefix : matchDecomposePrefix head tail body ctx.env bid addr (logged s log) =
      (do Trial.enter inner.env; Trial.snapshot .branchStarts; pure inner.env)
        (logged d log) := by
    simp [matchDecomposePrefix, Trial.getLiveCell, Trial.getCell, Trial.newBinding,
      Trial.shouldSetAside, Trial.Variant.approved, hcell, hcount, hlink, hl,
      Trial.popPending, Trial.memOp, Trial.enter, hm, logged, observe, pending,
      hv, hraw, inner] at hfirst ⊢
    rw [hfirst]
  have htcommit : t = commit ⟨{d with tasks := next, entered := inner.env},
      ⟨"BranchStart",some .branchStarts⟩,none⟩ := by
    simpa [advance, step, transition, hd, hda] using hstart.symm
  have hlast : (do Trial.enter inner.env; Trial.snapshot .branchStarts; pure inner.env)
      (logged d log) = (.ok inner.env, logged t log) := by
    rw [htcommit]
    have hs := match_decompose_snapshot
      ⟨{d with tasks := next, entered := inner.env},⟨"BranchStart",some .branchStarts⟩,none⟩
      .branchStarts rfl log
    simpa [Trial.enter, logged, observe, pending, Trial.snapshot] using
      congrArg (fun x => (x.1.map (fun _ => inner.env),x.2)) hs
  rw [hprefix, hlast] at hu
  have henv : env = inner.env := (Except.ok.inj (congrArg Prod.fst hu)).symm
  have hus : u = logged t log := (congrArg Prod.snd hu).symm
  refine ⟨t, ?_,hrt,htt,?_,hat,henv,?_,hent⟩
  · rw [show 2 = 1+1 from rfl, advance_add, hstep]
    exact hstart
  · rw [hst]
    simp [d, change, matchDecomposeChange, hcount, commit]
  · rw [hus]
    rfl

end Full.Proofs.TrialExecution

#print axioms Full.Proofs.TrialExecution.eval_match_decompose
#print axioms Full.Proofs.TrialExecution.match_decompose_progress
#print axioms Full.Proofs.TrialExecution.match_decompose_snapshot
#print axioms Full.Proofs.TrialExecution.match_decompose_unique_nil
