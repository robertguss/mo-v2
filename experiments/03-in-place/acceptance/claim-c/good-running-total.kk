// CORRECT: turns amounts into running totals, reusing each cell.
fip fun running(xs : list<int>, total : int) : list<int>
  match xs
    Cons(x, xx) ->
      val t = total + x
      Cons(t, running(xx, t))
    Nil -> Nil

fun main()
  println(running([5, 10, 20], 0).show)
