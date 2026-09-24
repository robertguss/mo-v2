// Benchmark 4: replace a list of 1,000,000 amounts with its running totals, 100 times over.
module b4

// Build the amounts from the back: amount i is (i * 37) mod 1000, for i = 1 to n.
fun build(i : int, acc : list<int>) : div list<int>
  if i <= 0 then acc else build(i - 1, Cons((i * 37) % 1000, acc))

// One walk of the list, carrying the running total; each cell is reused.
fun running(xs : list<int>, total : int) : list<int>
  match xs
    Cons(x, xx) ->
      val t = (total + x) % 1000000007
      Cons(t, running(xx, t))
    Nil -> Nil

fun rounds(n : int, xs : list<int>) : div list<int>
  if n <= 0 then xs else rounds(n - 1, running(xs, 0))

fun sum-mod(xs : list<int>, acc : int) : int
  match xs
    Cons(x, xx) -> sum-mod(xx, (acc + x) % 1000000007)
    Nil -> acc

fun last-of(xs : list<int>, prev : int) : int
  match xs
    Cons(x, xx) -> last-of(xx, x)
    Nil -> prev

pub fun main()
  val xs = rounds(100, build(1000000, Nil))
  println("first " ++ xs.head(0).show)
  println("last " ++ last-of(xs, 0).show)
  println("sum-mod " ++ sum-mod(xs, 0).show)
