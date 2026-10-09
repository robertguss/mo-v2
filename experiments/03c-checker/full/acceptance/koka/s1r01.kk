// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fbip fun mo-duplicate(xs : list<int>) : list<int>
  match xs { Nil -> Nil; Cons(h,t) -> Cons(h, Cons(h, mo-duplicate(t))) }

fun main() {
  {
    val xs = [-2, 5, 1]
    println("U-duplicate=" ++ (mo-duplicate(xs)).show)
  }
  {
    val xs = []
    println("additional-0=" ++ (mo-duplicate(xs)).show)
  }
  {
    val xs = [-2]
    println("additional-1=" ++ (mo-duplicate(xs)).show)
  }
}
