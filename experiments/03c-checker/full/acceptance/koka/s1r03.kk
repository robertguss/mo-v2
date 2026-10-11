// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fbip fun mo-insert-new(n : int, xs : list<int>) : list<int>
  match xs { Nil -> Cons(n, Nil); Cons(h,t) -> (if (n <= h) then Cons(n, Cons(h, t)) else Cons(h, mo-insert-new(n, t))) }

fun main() {
  {
    val xs = [-3, 4, 8]
    println("U-insert-new=" ++ (mo-insert-new(2, xs)).show)
  }
  {
    val xs = []
    println("additional-3=" ++ (mo-insert-new(2, xs)).show)
  }
}
