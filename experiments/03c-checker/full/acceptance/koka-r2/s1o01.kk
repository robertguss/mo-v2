// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fun mo-arithmetic(n : int) : int
  ((n + 3) - 7)

fbip fun mo-arith-demand(n : int) : int
  mo-arithmetic(n)

fun example0() {
  println("U-ordinary-arithmetic=" ++ (mo-arith-demand((-2))).show)
}
fun main() {
  example0()
}
