// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fbip fun mo-append(xs : list<int>, ys : list<int>) : list<int>
  match xs { Nil -> ys; Cons(h,t) -> Cons(h, mo-append(t, ys)) }

fun example0() {
  val xs = [-2, 5]
  val ys = [1, 7]
  println("U-append=" ++ (mo-append(xs, ys)).show)
}
fun example1() {
  val xs = []
  val ys = []
  println("boundary-2-nil=" ++ (mo-append(xs, ys)).show)
}
fun example2() {
  val xs = [-2]
  val ys = []
  println("boundary-2-single=" ++ (mo-append(xs, ys)).show)
}
fun main() {
  example0()
  example1()
  example2()
}
