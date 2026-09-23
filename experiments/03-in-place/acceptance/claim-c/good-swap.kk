// CORRECT: swaps the two halves of a record, reusing the record.
// (Records holding lists are stored in memory, unlike small pairs of numbers.)
type two
  Two(a : list<int>, b : list<int>)

fip fun swap(p : two) : two
  match p
    Two(a, b) -> Two(b, a)

fun main()
  match swap(Two([1], [2]))
    Two(a, b) -> println((a ++ b).show)
