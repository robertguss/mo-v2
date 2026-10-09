// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fbip fun mo-totals(xs : list<int>) : list<int>
  mo-totals-acc(xs, 0)

fbip fun mo-totals-acc(xs : list<int>, s : int) : list<int>
  match xs { Nil -> Nil; Cons(h,t) -> Cons((s + h), mo-totals-acc(t, (s + h))) }

fun main() {
  {
    val xs = [-2, 5, 1]
    println("U-totals=" ++ (mo-totals(xs)).show)
  }
  {
    val xs = []
    println("boundary-1-nil=" ++ (mo-totals(xs)).show)
  }
  {
    val xs = [-2]
    println("boundary-1-single=" ++ (mo-totals(xs)).show)
  }
}
