// BROKEN: turns a two-field record into a three-field one, which needs a bigger, new container.
// (Records holding lists are stored in memory, unlike small pairs of numbers.)
type two
  Two(a : list<int>, b : list<int>)
type three
  Three(a : list<int>, b : list<int>, c : list<int>)

fip fun grow(p : two) : three
  match p
    Two(a, b) -> Three(a, b, Nil)

fun main()
  match grow(Two([1], [2]))
    Three(a, b, c) -> println((a ++ b ++ c).show)
