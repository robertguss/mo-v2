// Benchmark 3: reverse a list of 1,000,000 numbers, 101 times.
module b3-helper

import helper

// Build [1..n] from the back, one cell at a time.
fun build(i : int, acc : list<int>) : div list<int>
  if i <= 0 then acc else build(i - 1, Cons(i, acc))

// Move cells one at a time from the front of xs to the front of acc; each cell is reused.
fun reverse-acc(xs : list<int>, acc : list<int>) : list<int>
  match xs
    Cons(x, xx) -> reverse-acc(xx, Cons(x, acc))
    Nil -> acc

fun rounds(n : int, xs : list<int>) : div list<int>
  if n <= 0 then xs else rounds(n - 1, reverse-acc(pass-along(xs), Nil))

fun weighted(xs : list<int>, pos : int, acc : int) : int
  match xs
    Cons(x, xx) -> weighted(xx, pos + 1, acc + pos * x)
    Nil -> acc

fun last-of(xs : list<int>, prev : int) : int
  match xs
    Cons(x, xx) -> last-of(xx, x)
    Nil -> prev

pub fun main()
  val xs = rounds(101, build(1000000, Nil))
  println("first " ++ xs.head(0).show)
  println("last " ++ last-of(xs, 0).show)
  println("weighted " ++ weighted(xs, 1, 0).show)
