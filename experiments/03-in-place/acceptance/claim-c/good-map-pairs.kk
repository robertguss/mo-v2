// CORRECT: swaps every pair in a list, reusing each cell and each pair.
fip fun swap-all(xs : list<(int, int)>) : list<(int, int)>
  match xs
    Cons((a, b), xx) -> Cons((b, a), swap-all(xx))
    Nil -> Nil

fun main()
  println(swap-all([(1, 2), (3, 4)]).show)
