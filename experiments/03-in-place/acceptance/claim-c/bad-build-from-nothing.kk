// BROKEN: builds a list of n items from a number, so every cell is new.
// (div says the function may not finish, so Koka checks only the in-place rule.)
fip fun count-down(n : int) : div list<int>
  if n <= 0 then Nil else Cons(n, count-down(n - 1))

fun main()
  println(count-down(3).show)
