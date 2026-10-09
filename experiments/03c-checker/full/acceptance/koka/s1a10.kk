// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fbip fun mo-keep-first(xs : list<int>) : list<int>
  match xs { Nil -> Nil; Cons(h,t) -> Cons(h, Nil) }

fun main() {
  {
    val xs = [-2, 5, 1]
    println("U-keep-first=" ++ (mo-keep-first(xs)).show)
  }
  {
    val xs = []
    println("boundary-7-nil=" ++ (mo-keep-first(xs)).show)
  }
  {
    val xs = [-2]
    println("boundary-7-single=" ++ (mo-keep-first(xs)).show)
  }
}
