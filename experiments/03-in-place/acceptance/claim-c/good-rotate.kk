// CORRECT: rotates a small tree to the right, reusing both nodes.
type tree
  Leaf
  Node(left : tree, key : int, right : tree)

fip fun rotate-right(t : tree) : tree
  match t
    Node(Node(a, x, b), y, c) -> Node(a, x, Node(b, y, c))
    t' -> t'

fun keys(t : tree) : list<int>
  match t
    Leaf -> []
    Node(l, k, r) -> keys(l) ++ [k] ++ keys(r)

fun main()
  println(keys(rotate-right(Node(Node(Leaf, 1, Leaf), 2, Leaf))).show)
