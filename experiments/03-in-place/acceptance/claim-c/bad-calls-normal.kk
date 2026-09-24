// BROKEN: claims to be in place but calls an ordinary function that makes new lists.
// (Both lists come in as arguments, so the only problem is the ordinary call.)
fun plain-append(xs : list<int>, ys : list<int>) : list<int>
  xs ++ ys

fip fun join(xs : list<int>, ys : list<int>) : list<int>
  plain-append(xs, ys)

fun main()
  println(join([1, 2], [0]).show)
