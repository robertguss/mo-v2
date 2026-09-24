// Claim B's repeated-sharing case (D63), Koka version, from Experiment 3's b1.kk.
// Benchmark 1, but every round keeps the previous list while add-one builds the new one,
// then reads the first value of both, so the old cells are still held during the update
// and add-one must copy them rather than reuse them. In the last round it also sums the
// kept list. After those reads the kept list is no longer used, so it is released before
// the next round.
module b1-share

// Build [1..n] from the back, one cell at a time.
fun build(i : int, acc : list<int>) : div list<int>
  if i <= 0 then acc else build(i - 1, Cons(i, acc))

// One walk of the list; a cell is reused for the new value only if nothing else holds it.
fun add-one(xs : list<int>) : list<int>
  match xs
    Cons(x, xx) -> Cons(x + 1, add-one(xx))
    Nil -> Nil

fun sum-of(xs : list<int>, acc : int) : int
  match xs
    Cons(x, xx) -> sum-of(xx, acc + x)
    Nil -> acc

fun last-of(xs : list<int>, prev : int) : int
  match xs
    Cons(x, xx) -> last-of(xx, x)
    Nil -> prev

// One round per step, n rounds left. `kept` is the previous version; it is read after
// add-one has built `ys`, so it stays held across the update.
fun rounds(n : int, kept : list<int>, differ : int, prev-sum : int) : div (list<int>, int, int)
  if n <= 0 then (kept, differ, prev-sum) else
    val ys = add-one(kept)
    val d = differ + (ys.head(0) - kept.head(0))
    val s = if n == 1 then sum-of(kept, 0) else prev-sum
    rounds(n - 1, ys, d, s)

pub fun main()
  val (xs, differ, prev-sum) = rounds(100, build(1000000, Nil), 0, 0)
  println("sum " ++ sum-of(xs, 0).show)
  println("first " ++ xs.head(0).show)
  println("last " ++ last-of(xs, 0).show)
  println("rounds-differ " ++ differ.show)
  println("prev-sum " ++ prev-sum.show)
