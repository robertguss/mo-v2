// Generated syntax translation of checkpointed public trees; no algorithm rewrite.
fun mo-one(n : int) : list<int>
  Cons(n, Nil)

fbip fun mo-alloc-helper(n : int) : list<int>
  mo-one(n)

fun main() {
  {
    println("U-ordinary-alloc=" ++ (mo-alloc-helper((-9))).show)
  }
}
