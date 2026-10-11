// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fbip fun mo-build(n : int) : list<int>
  (if (n <= 0) then Nil else Cons(n, mo-build((n - 1))))

fun main() {
  {
    println("U-build=" ++ (mo-build(3)).show)
  }
  {
    println("additional-4=" ++ (mo-build(0)).show)
  }
  {
    println("additional-5=" ++ (mo-build(1)).show)
  }
  {
    println("additional-6=" ++ (mo-build((-1))).show)
  }
}
