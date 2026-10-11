// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fbip fun mo-sum(xs : list<int>) : int
  match xs { Nil -> 0; Cons(h,t) -> (h + mo-sum(t)) }

fun example0() {
  val xs = []
  println("C10-sum-empty=" ++ (mo-sum(xs)).show)
}
fun example1() {
  val xs = [-2]
  println("C10-sum-single=" ++ (mo-sum(xs)).show)
}
fun example2() {
  val xs = [-2, 5, 1]
  println("C10-sum-mixed=" ++ (mo-sum(xs)).show)
}
fun main() {
  example0()
  example1()
  example2()
}
