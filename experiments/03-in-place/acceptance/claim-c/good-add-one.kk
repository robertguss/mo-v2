// CORRECT: adds one to every number, reusing each cell.
fip fun add-one(xs : list<int>) : list<int>
  match xs
    Cons(x, xx) -> Cons(x + 1, add-one(xx))
    Nil -> Nil

fun main()
  println(add-one([1, 2, 3]).show)
