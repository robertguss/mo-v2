// BROKEN: throws away the rest of the list, so memory is freed rather than reused.
fip fun first-only(xs : list<int>) : list<int>
  match xs
    Cons(x, _) -> Cons(x, Nil)
    Nil -> Nil

fun main()
  println(first-only([1, 2, 3]).show)
