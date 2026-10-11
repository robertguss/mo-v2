// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fbip fun mo-swap(xs : list<int>) : list<int>
  match xs { Nil -> Nil; Cons(h,t) -> match t { Nil -> Cons(h, Nil); Cons(j,u) -> Cons(j, Cons(h, mo-swap(u))) } }

fun main() {
  {
    val xs = [-2, 5, 1]
    println("U-swap=" ++ (mo-swap(xs)).show)
  }
  {
    val xs = []
    println("boundary-3-nil=" ++ (mo-swap(xs)).show)
  }
  {
    val xs = [-2]
    println("boundary-3-single=" ++ (mo-swap(xs)).show)
  }
}
