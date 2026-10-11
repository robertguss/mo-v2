// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fbip fun mo-reverse(xs : list<int>) : list<int>
  mo-rev-acc(xs, Nil)

fbip fun mo-rev-acc(xs : list<int>, acc : list<int>) : list<int>
  match xs { Nil -> acc; Cons(h,t) -> mo-rev-acc(t, Cons(h, acc)) }

fun main() {
  {
    val xs = [-2, 5, 1]
    println("U-reverse=" ++ (mo-reverse(xs)).show)
  }
  {
    val xs = []
    println("boundary-0-nil=" ++ (mo-reverse(xs)).show)
  }
  {
    val xs = [-2]
    println("boundary-0-single=" ++ (mo-reverse(xs)).show)
  }
}
