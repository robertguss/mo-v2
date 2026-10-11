// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fbip fun mo-append(xs : list<int>, ys : list<int>) : list<int>
  match xs { Nil -> ys; Cons(h,t) -> Cons(h, mo-append(t, ys)) }

fbip fun mo-rotate(xs : list<int>) : list<int>
  match xs { Nil -> Nil; Cons(h,t) -> mo-append(t, Cons(h, Nil)) }

fun example0() {
  val xs = [-2, 5, 1]
  println("U-rotate=" ++ (mo-rotate(xs)).show)
}
fun example1() {
  val xs = []
  println("boundary-4-nil=" ++ (mo-rotate(xs)).show)
}
fun example2() {
  val xs = [-2]
  println("boundary-4-single=" ++ (mo-rotate(xs)).show)
}
fun main() {
  example0()
  example1()
  example2()
}
