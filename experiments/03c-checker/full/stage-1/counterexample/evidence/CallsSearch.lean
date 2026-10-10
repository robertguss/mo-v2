import Full.Inspect

open Full
namespace CallSearch

structure GenState where
  seed : Nat
  next : Nat := 0
  functions : List Function := []

def choose (n : Nat) : StateM GenState Nat := do
  let s ← get
  let t := (1664525*s.seed + 1013904223) % 4294967296
  set {s with seed := t}
  pure ((t / 65536) % n)

def extend (x : String) (k : Kind) (env : List (String × Kind)) :=
  (x,k) :: env.filter (fun p => p.1 != x)

def kind (n : Nat) : Kind := match n % 3 with
  | 0 => .number | 1 => .list | _ => .bool

def atom (k : Kind) (env : List (String × Kind)) : StateM GenState Expr := do
  let vs := env.filter (fun p => p.2 == k)
  let i ← choose (vs.length + 2)
  match vs[i]? with
  | some (x,_) => pure (.var x)
  | none => match k with
    | .number => pure (.num (Int.ofNat (← choose 9) - 4))
    | .list => pure .nil
    | .bool => pure (.bool ((← choose 2) == 0))

def gen : Nat → Kind → List (String × Kind) → StateM GenState Expr
  | 0,k,env => atom k env
  | d+1,k,env => do
    match ← choose 10 with
    | 0 | 1 => atom k env
    | 2 =>
      let x := ["x","y","z","h","t"][← choose 5]!
      let a := kind (← choose 3)
      pure (.letE x (← gen d a env) (← gen d k (extend x a env)))
    | 3 => pure (.ifE (← gen d .bool env) (← gen d k env) (← gen d k env))
    | 4 | 5 => pure (.matchE (← gen d .list env) (← gen d k env) "h" "t"
        (← gen d k (extend "t" .list (extend "h" .number env))))
    | 6 | 7 =>
      let id := (← get).next
      modify fun s => {s with next := id+1}
      let arity ← choose 4
      let params := ((["x","y","z"].take arity).zipIdx).map fun (x,i) => (x,kind (i+id))
      let args ← params.mapM fun (_,k) => gen d k env
      let body ← gen d k params
      let name := s!"f{id}"
      modify fun s => {s with functions := s.functions ++ [⟨name,params,k,body,false⟩]}
      pure (.call name args)
    | _ => match k with
      | .number => pure (.bin .sub (← gen d .number env) (← gen d .number env))
      | .bool => pure (.bin .lt (← gen d .number env) (← gen d .number env))
      | .list => pure (.bin .cons (← gen d .number env) (← gen d .list env))

def initial (outside : Bool) : Trial.Start :=
  ⟨[⟨0,7,some 1,if outside then 3 else 2⟩,⟨1,9,none,2⟩],
    [("x",.list (some 0)),("y",.list (some 0)),("z",.list (some 1))],
    if outside then [some 0] else []⟩

def main : IO Unit := do
  for i in [:4000] do
    let (e,g) := (gen (if i < 2000 then 3 else 5) (kind i)
      [("x",.list),("y",.list),("z",.list)]).run {seed := i+314}
    let p : Program := ⟨g.functions,e⟩
    let start := initial (i % 2 == 0)
    match Counted.begin p start with
    | .error why => throw (IO.userError s!"begin {i}: {why}\n{reprStr p}")
    | .ok first =>
      match Inspect.trace p start 10000 first with
      | .error why => throw (IO.userError s!"trace {i}: {why}\n{reprStr p}")
      | .ok () => pure ()
      match Counted.advance p 10000 first with
      | .error why => throw (IO.userError s!"advance {i}: {why}\n{reprStr p}")
      | .ok s => unless s.answer.isSome do throw (IO.userError s!"unfinished {i}")
    if i % 100 == 0 then IO.println s!"checked {i}"
  IO.println "PASS 4000 generated typed multi-function programs, invariants, control/rank and final graphs"

end CallSearch
def main := CallSearch.main
