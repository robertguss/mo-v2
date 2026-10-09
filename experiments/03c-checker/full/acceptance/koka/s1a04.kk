// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fbip fun mo-append(xs : list<int>, ys : list<int>) : list<int>
  match xs { Nil -> ys; Cons(h,t) -> Cons(h, mo-append(t, ys)) }

fun main() {
  {
    val xs = [-2, 5]
    val ys = [1, 7]
    println("U-append=" ++ (mo-append(xs, ys)).show)
  }
  {
    val xs = []
    val ys = []
    println("boundary-2-nil=" ++ (mo-append(xs, ys)).show)
  }
  {
    val xs = [-2]
    val ys = []
    println("boundary-2-single=" ++ (mo-append(xs, ys)).show)
  }
}
