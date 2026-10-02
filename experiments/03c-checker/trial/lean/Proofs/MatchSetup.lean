import Proofs.SharedSetup

namespace Trial.Proofs

/-- The setup choice depends on the selected cell's count, before the fresh
bindings are introduced. Both setup contracts therefore apply to the actual
nonempty evaluator branch, rather than to a separate model of that branch. -/
def matchCellSetup (bid a : Nat) (c : Cell) (headName tailName : String)
    (cb : Expr) (env : Env) : M Env :=
  if shouldSetAside .approved c.count then
    exclusiveSetup bid a c headName tailName cb env
  else sharedSetup a c headName tailName cb env

theorem eval_match_setup (scrut nb cb : Expr) (headName tailName : String)
    (env : Env) (fs : List Frame) (enc : List Nat) :
    evalC .approved (.matchE scrut nb headName tailName cb) env fs enc =
      (do
        let r ← evalC .approved scrut env
          ({ text := nb, env := toFEnv env } ::
           { text := cb, env := (tailName, none) :: (headName, none) :: toFEnv env } :: fs) enc
        enter env
        match r with
        | .list none => do
          let bid ← freshBranch
          snapshot .branchChosen
          giveUpDead .approved env ({ text := nb, env := toFEnv env } :: fs)
          enter env
          snapshot .branchStarts
          let w ← evalC .approved nb env fs (bid :: enc)
          finishBranch bid env env w
        | .list (some a) => do
          let _ ← getLiveCell a
          let bid ← freshBranch
          snapshot .branchChosen
          giveUpDead .approved env
            ({ text := cb, env := (tailName, none) :: (headName, none) :: toFEnv env } :: fs)
          let c ← getLiveCell a
          let env' ← matchCellSetup bid a c headName tailName cb env
          let w ← evalC .approved cb env' fs (bid :: enc)
          finishBranch bid env' env w
        | _ => throw "stuck: match on a non-list" : M RawValue) := by
  simp only [evalC]
  apply bind_congr
  intro r
  apply bind_congr
  intro _
  cases r with
  | num _ | bool _ => rfl
  | list l =>
    cases l with
    | none => rfl
    | some a =>
      apply bind_congr
      intro _
      apply bind_congr
      intro bid
      apply bind_congr
      intro _
      apply bind_congr
      intro _
      apply bind_congr
      intro c
      by_cases hc : shouldSetAside .approved c.count = true
      · simp only [matchCellSetup, hc, ite_true, exclusiveSetup, reserveAction, bind_assoc]
        apply bind_congr
        intro hid
        apply bind_congr
        intro tid
        cases c.link <;>
          cases usesBinding cb (toFEnv ((tailName, tid) :: (headName, hid) :: env)) tid <;>
          simp
      · have hc' : shouldSetAside .approved c.count = false := by
          cases he : shouldSetAside .approved c.count <;> simp_all
        simp only [matchCellSetup, hc', Bool.false_eq_true, ite_false, sharedSetup, bind_assoc]
        apply bind_congr
        intro hid
        apply bind_congr
        intro tid
        cases c.link <;>
          cases usesBinding cb (toFEnv ((tailName, tid) :: (headName, hid) :: env)) tid <;>
          simp [bind_assoc]

theorem match_cell_setup_contract {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (bid : Nat) (h : StateInvariant start g (bid :: enc) s) (a : Addr) (c : Cell)
    (headName tailName : String) (cb : Expr) (env : Env) (fs : List Frame)
    (rest : List RawValue) (items : List Int)
    (hc : s.mem.find? a = some c) (hcl : c.status = .live)
    (hp : s.pending = .list (some a) :: rest)
    (hr : readBack s.mem (.list c.link) = .ok (.list items))
    (ho : (s.setAside.map Prod.fst).Sublist enc) (hf : FramesBound s fs)
    (hl : LiveFor s.bindings ({ text := cb, env := (tailName, none) :: (headName, none) :: toFEnv env } :: fs)) :
    ∃ t, matchCellSetup bid a c headName tailName cb env s =
        (.ok ((tailName, s.nextBinding + 1) :: (headName, s.nextBinding) :: env), t) ∧
      StateInvariant start (matchMeanings g s.nextBinding c.item c.link items) (bid :: enc) t ∧
      LiveFor t.bindings ({ text := cb, env := toFEnv ((tailName, s.nextBinding + 1) :: (headName, s.nextBinding) :: env) } :: fs) ∧
      t.nextBinding = s.nextBinding + 2 ∧ t.nextBranch = s.nextBranch ∧
      t.pending = rest ∧
      t.setAside = (if shouldSetAside .approved c.count then (bid, a) :: s.setAside else s.setAside) ∧
      s.snaps.IsPrefix t.snaps ∧ (∀ v ∈ rest, readBack t.mem v = readBack s.mem v) := by
  by_cases hc1 : shouldSetAside .approved c.count = true
  · have hcount : c.count = 1 := by simpa [shouldSetAside, Variant.approved] using hc1
    simpa [matchCellSetup, hc1] using
      exclusive_setup_contract bid h a c headName tailName cb env fs rest items hc hcl hcount hp hr ho hf hl
  · have hc0 : shouldSetAside .approved c.count = false := by
      cases he : shouldSetAside .approved c.count <;> simp_all
    simpa [matchCellSetup, hc0] using
      shared_setup_contract h a c headName tailName cb env fs rest items hc hp hr hf hl

end Trial.Proofs
