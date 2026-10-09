// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fbip fun mo-sort(xs : list<int>) : list<int>
  match xs { Nil -> Nil; Cons(h,t) -> mo-insert-cell(Cons(h, Nil), mo-sort(t)) }

fbip fun mo-insert-cell(node : list<int>, ys : list<int>) : list<int>
  match node { Nil -> ys; Cons(n,nt) -> match ys { Nil -> Cons(n, Nil); Cons(h,t) -> (if (n <= h) then Cons(n, Cons(h, t)) else Cons(h, mo-insert-cell(Cons(n, Nil), t))) } }

fun main() {
  {
    val xs = [-2, 5, 1]
    println("U-sort=" ++ (mo-sort(xs)).show)
  }
  {
    val xs = []
    println("boundary-6-nil=" ++ (mo-sort(xs)).show)
  }
  {
    val xs = [-2]
    println("boundary-6-single=" ++ (mo-sort(xs)).show)
  }
}
