// BROKEN: claims to be in place but calls an ordinary function that makes new lists.
fun plain-append(xs : list<int>, ys : list<int>) : list<int>
  xs ++ ys

fip fun add-marker(xs : list<int>) : list<int>
  plain-append(xs, [0])

fun main()
  println(add-marker([1, 2]).show)
