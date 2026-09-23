// BROKEN: returns the list together with a changed copy, so the list is used twice.
fip fun with-copy(xs : list<int>) : (list<int>, list<int>)
  (xs, add-one(xs))

fip fun add-one(xs : list<int>) : list<int>
  match xs
    Cons(x, xx) -> Cons(x + 1, add-one(xx))
    Nil -> Nil

fun main()
  println(with-copy([1, 2]).show)
