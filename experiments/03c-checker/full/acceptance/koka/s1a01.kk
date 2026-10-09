// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fbip fun mo-bump(xs : list<int>) : list<int>
  match xs { Nil -> Nil; Cons(h,t) -> Cons((h + 1), mo-bump(t)) }

fun main() {
  {
    val xs = []
    println("C10-bump-empty=" ++ (mo-bump(xs)).show)
  }
  {
    val xs = [-2]
    println("C10-bump-single=" ++ (mo-bump(xs)).show)
  }
  {
    val xs = [-2, 5, 1]
    println("C10-bump-mixed=" ++ (mo-bump(xs)).show)
  }
}
