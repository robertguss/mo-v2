// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fbip fun mo-remove(n : int, xs : list<int>) : list<int>
  match xs { Nil -> Nil; Cons(h,t) -> (if (n == h) then t else Cons(h, mo-remove(n, t))) }

fun example0() {
  val xs = [-2, 5, 1]
  println("U-remove=" ++ (mo-remove(5, xs)).show)
}
fun example1() {
  val xs = []
  println("boundary-8-nil=" ++ (mo-remove(5, xs)).show)
}
fun example2() {
  val xs = [-2]
  println("boundary-8-single=" ++ (mo-remove(5, xs)).show)
}
fun example3() {
  val xs = []
  println("boundary-9-nil=" ++ (mo-remove((-2), xs)).show)
}
fun example4() {
  val xs = [-2]
  println("boundary-9-single=" ++ (mo-remove((-2), xs)).show)
}
fun main() {
  example0()
  example1()
  example2()
  example3()
  example4()
}
