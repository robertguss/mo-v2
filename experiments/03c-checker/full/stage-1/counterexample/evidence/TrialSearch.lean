import Full.Inspect

open Trial
deriving instance Inhabited for Trial.Kind
deriving instance Repr for Trial.Expr
namespace Search

def choose (n : Nat) : StateM Nat Nat := do
  let s ← get
  let t := (1664525*s + 1013904223) % 4294967296
  set t
  pure ((t / 65536) % n)

def extend (x : String) (k : Kind) (env : List (String × Kind)) :=
  (x,k) :: env.filter (fun p => p.1 != x)

def atom (k : Kind) (env : List (String × Kind)) : StateM Nat Expr := do
  let vs := env.filter (fun p => p.2 == k)
  let i ← choose (vs.length + 2)
  match vs[i]? with
  | some (x,_) => pure (.var x)
  | none => match k with
    | .number => pure (.num (Int.ofNat (← choose 9) - 4))
    | .list => pure .nil
    | .bool => pure (.eq (.num 0) (.num (Int.ofNat (← choose 2))))

def gen : Nat → Kind → List (String × Kind) → StateM Nat Expr
  | 0,k,env => atom k env
  | d+1,k,env => do
    match ← choose 8 with
    | 0 | 1 => atom k env
    | 2 =>
      let x := ["x","y","z","h","t"][← choose 5]!
      let kind := [Kind.number,Kind.list,Kind.bool][← choose 3]!
      pure (.letE x (← gen d kind env) (← gen d k (extend x kind env)))
    | 3 => pure (.ifE (← gen d .bool env) (← gen d k env) (← gen d k env))
    | 4 | 5 =>
      pure (.matchE (← gen d .list env) (← gen d k env) "h" "t"
        (← gen d k (extend "t" .list (extend "h" .number env))))
    | _ => match k with
      | .number => pure (.add (← gen d .number env) (← gen d .number env))
      | .bool => pure (.lt (← gen d .number env) (← gen d .number env))
      | .list => pure (.cons (← gen d .number env) (← gen d .list env))

def initial : Start :=
  ⟨[⟨0,7,some 1,3⟩,⟨1,9,none,2⟩],
    [("x",.list (some 0)),("y",.list (some 0)),("z",.list (some 1))],[some 0]⟩

def main : IO Unit := do
  for i in [:3000] do
    let k := [Kind.number,Kind.list,Kind.bool][i % 3]!
    let e := (gen (if i < 2000 then 3 else 5) k
      [("x",.list),("y",.list),("z",.list)]).run' (i+1)
    let p : Full.Program := ⟨[],Full.embed e⟩
    let old := runCountedWith .approved e initial
    match Full.Counted.begin p initial with
    | .error why => throw (IO.userError s!"begin {i}: {why}\n{reprStr e}")
    | .ok first =>
      match Full.Inspect.trace p initial 10000 first with
      | .error why => throw (IO.userError s!"trace {i}: {why}\n{reprStr e}")
      | .ok () => pure ()
      match Full.Counted.advance p 10000 first,old.result with
      | .ok s,.answer raw =>
        unless s.answer.map (·.raw) == some raw && s.mem.record == old.record &&
            reprStr s.landmarks == reprStr old.states do
          let mismatch := (s.landmarks.zip old.states).findIdx? (fun (a,b) => reprStr a != reprStr b)
          throw (IO.userError s!"compatibility {i}: index {mismatch}; lengths {s.landmarks.length}/{old.states.length}\n{reprStr e}\nnew {reprStr s.landmarks}\nold {reprStr old.states}")
      | _,_ => throw (IO.userError s!"answer {i}: {reprStr e}")
    if i % 100 == 0 then IO.println s!"checked {i}"
  IO.println "PASS 3000 generated typed programs, invariants, control/rank, and exact Trial correspondence"

end Search
def main := Search.main
