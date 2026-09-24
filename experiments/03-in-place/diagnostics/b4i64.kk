// DIAGNOSTIC ONLY (not part of the scored experiment): benchmark 4 with fixed-size int64 numbers.
module b4i64
import std/num/int64

fun build(i : int64, acc : list<int64>) : div list<int64>
  if i <= 0.int64 then acc else build(i - 1.int64, Cons((i * 37.int64) % 1000.int64, acc))

fun running(xs : list<int64>, total : int64) : list<int64>
  match xs
    Cons(x, xx) ->
      val t = (total + x) % 1000000007.int64
      Cons(t, running(xx, t))
    Nil -> Nil

fun rounds(n : int, xs : list<int64>) : div list<int64>
  if n <= 0 then xs else rounds(n - 1, running(xs, 0.int64))

fun sum-mod(xs : list<int64>, acc : int64) : int64
  match xs
    Cons(x, xx) -> sum-mod(xx, (acc + x) % 1000000007.int64)
    Nil -> acc

fun last-of(xs : list<int64>, prev : int64) : int64
  match xs
    Cons(x, xx) -> last-of(xx, x)
    Nil -> prev

pub fun main()
  val xs = rounds(100, build(1000000.int64, Nil))
  println("first " ++ xs.head(0.int64).show)
  println("last " ++ last-of(xs, 0.int64).show)
  println("sum-mod " ++ sum-mod(xs, 0.int64).show)
