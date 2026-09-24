// Benchmark 1: add one to every number in a list of 1,000,000, 100 times over.
module b1-box

// Build [1..n] from the back, one cell at a time.
fun build(i : int, acc : list<int>) : div list<int>
  if i <= 0 then acc else build(i - 1, Cons(i, acc))

// One walk of the list; each cell is reused for the new value.
fun add-one(xs : list<int>) : list<int>
  match xs
    Cons(x, xx) -> Cons(x + 1, add-one(xx))
    Nil -> Nil

// Claim B: each round the value is stored in a record and taken back out.
struct holder(value : list<int>)

fun rounds(n : int, xs : list<int>) : div list<int>
  if n <= 0 then xs else
    val h = Holder(xs)
    rounds(n - 1, add-one(h.value))

fun sum-of(xs : list<int>, acc : int) : int
  match xs
    Cons(x, xx) -> sum-of(xx, acc + x)
    Nil -> acc

fun last-of(xs : list<int>, prev : int) : int
  match xs
    Cons(x, xx) -> last-of(xx, x)
    Nil -> prev

pub fun main()
  val xs = rounds(100, build(1000000, Nil))
  println("sum " ++ sum-of(xs, 0).show)
  println("first " ++ xs.head(0).show)
  println("last " ++ last-of(xs, 0).show)
