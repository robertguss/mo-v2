// CORRECT: reverses a list, reusing each cell it takes apart.
fip fun reverse-acc(xs : list<int>, acc : list<int>) : list<int>
  match xs
    Cons(x, xx) -> reverse-acc(xx, Cons(x, acc))
    Nil -> acc

fun main()
  println(reverse-acc([1, 2, 3], []).show)
