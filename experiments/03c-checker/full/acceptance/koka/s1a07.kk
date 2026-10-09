// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fbip fun mo-merge(xs : list<int>, ys : list<int>) : list<int>
  match xs { Nil -> ys; Cons(a,at) -> match ys { Nil -> Cons(a, at); Cons(b,bt) -> (if (a <= b) then Cons(a, mo-merge(at, Cons(b, bt))) else Cons(b, mo-merge(Cons(a, at), bt))) } }

fun main() {
  {
    val xs = [-3, 4]
    val ys = [-1, 2, 8]
    println("U-merge=" ++ (mo-merge(xs, ys)).show)
  }
  {
    val xs = []
    val ys = []
    println("boundary-5-nil=" ++ (mo-merge(xs, ys)).show)
  }
  {
    val xs = [-2]
    val ys = []
    println("boundary-5-single=" ++ (mo-merge(xs, ys)).show)
  }
}
