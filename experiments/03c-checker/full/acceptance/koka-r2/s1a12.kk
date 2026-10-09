// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fbip fun mo-positive(xs : list<int>) : list<int>
  match xs { Nil -> Nil; Cons(h,t) -> (if (0 < h) then Cons(h, mo-positive(t)) else mo-positive(t)) }

fun example0() {
  val xs = [-2, 5, 1]
  println("U-positive=" ++ (mo-positive(xs)).show)
}
fun example1() {
  val xs = []
  println("boundary-10-nil=" ++ (mo-positive(xs)).show)
}
fun example2() {
  val xs = [-2]
  println("boundary-10-single=" ++ (mo-positive(xs)).show)
}
fun main() {
  example0()
  example1()
  example2()
}
