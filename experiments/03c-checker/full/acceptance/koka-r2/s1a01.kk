// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fbip fun mo-bump(xs : list<int>) : list<int>
  match xs { Nil -> Nil; Cons(h,t) -> Cons((h + 1), mo-bump(t)) }

fun example0() {
  val xs = []
  println("C10-bump-empty=" ++ (mo-bump(xs)).show)
}
fun example1() {
  val xs = [-2]
  println("C10-bump-single=" ++ (mo-bump(xs)).show)
}
fun example2() {
  val xs = [-2, 5, 1]
  println("C10-bump-mixed=" ++ (mo-bump(xs)).show)
}
fun main() {
  example0()
  example1()
  example2()
}
