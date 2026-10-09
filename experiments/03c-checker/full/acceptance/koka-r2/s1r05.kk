// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fbip fun mo-bump(xs : list<int>) : list<int>
  match xs { Nil -> Nil; Cons(h,t) -> Cons((h + 1), mo-bump(t)) }

fbip fun mo-append(xs : list<int>, ys : list<int>) : list<int>
  match xs { Nil -> ys; Cons(h,t) -> Cons(h, mo-append(t, ys)) }

fbip fun mo-twice(xs : list<int>) : list<int>
  mo-append(xs, mo-bump(xs))

fun example0() {
  val xs = [1, 2]
  println("U-twice=" ++ (mo-twice(xs)).show)
}
fun example1() {
  val xs = []
  println("additional-7=" ++ (mo-twice(xs)).show)
}
fun main() {
  example0()
  example1()
}
