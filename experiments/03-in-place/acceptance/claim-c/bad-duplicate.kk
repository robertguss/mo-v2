// BROKEN: writes every item twice, so it must make new cells.
fip fun duplicate(xs : list<int>) : list<int>
  match xs
    Cons(x, xx) -> Cons(x, Cons(x, duplicate(xx)))
    Nil -> Nil

fun main()
  println(duplicate([1, 2, 3]).show)
