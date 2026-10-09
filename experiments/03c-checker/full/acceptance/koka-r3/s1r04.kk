// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fbip fun mo-build(n : int) : div list<int>
  (if (n <= 0) then Nil else Cons(n, mo-build((n - 1))))

fun example0() {
  println("U-build=" ++ (mo-build(3)).show)
}
fun example1() {
  println("additional-4=" ++ (mo-build(0)).show)
}
fun example2() {
  println("additional-5=" ++ (mo-build(1)).show)
}
fun example3() {
  println("additional-6=" ++ (mo-build((-1))).show)
}
fun main() {
  example0()
  example1()
  example2()
  example3()
}
