// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fbip fun mo-prepend(n : int, xs : list<int>) : list<int>
  Cons(n, xs)

fun main() {
  {
    val xs = [1, 2]
    println("U-prepend=" ++ (mo-prepend((-7), xs)).show)
  }
  {
    val xs = []
    println("additional-2=" ++ (mo-prepend((-7), xs)).show)
  }
}
