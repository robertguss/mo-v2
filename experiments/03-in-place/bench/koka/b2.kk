// Benchmark 2: insert 1,000,000 scrambled keys into a red-black tree (Okasaki).
module b2

type color
  Red
  Black

type tree
  Leaf
  Node(color : color, left : tree, key : int, right : tree)

// Build the key list from the back: key i is (i * 7919) mod 1,000,003.
fun build(i : int, acc : list<int>) : div list<int>
  if i < 0 then acc else build(i - 1, Cons((i * 7919) % 1000003, acc))

// Okasaki's four imbalance cases, each rebuilt from the three nodes it takes apart.
fun balance(t : tree) : tree
  match t
    Node(Black, Node(Red, Node(Red, a, x, b), y, c), z, d) -> Node(Red, Node(Black, a, x, b), y, Node(Black, c, z, d))
    Node(Black, Node(Red, a, x, Node(Red, b, y, c)), z, d) -> Node(Red, Node(Black, a, x, b), y, Node(Black, c, z, d))
    Node(Black, a, x, Node(Red, Node(Red, b, y, c), z, d)) -> Node(Red, Node(Black, a, x, b), y, Node(Black, c, z, d))
    Node(Black, a, x, Node(Red, b, y, Node(Red, c, z, d))) -> Node(Red, Node(Black, a, x, b), y, Node(Black, c, z, d))
    _ -> t

// Go down to the insertion point, add a red node, and rebalance on the way back up.
fun ins(t : tree, k : int) : tree
  match t
    Leaf -> Node(Red, Leaf, k, Leaf)
    Node(c, l, x, r) ->
      if k < x then balance(Node(c, ins(l, k), x, r))
      elif k > x then balance(Node(c, l, x, ins(r, k)))
      else Node(c, l, x, r)

fun blacken(t : tree) : tree
  match t
    Node(Red, l, x, r) -> Node(Black, l, x, r)
    _ -> t

fun insert(t : tree, k : int) : tree
  blacken(ins(t, k))

fun insert-all(keys : list<int>, t : tree) : tree
  match keys
    Cons(k, kk) -> insert-all(kk, insert(t, k))
    Nil -> t

fun count(t : tree) : int
  match t
    Node(_, l, _, r) -> count(l) + 1 + count(r)
    Leaf -> 0

fun sum(t : tree) : int
  match t
    Node(_, l, x, r) -> sum(l) + x + sum(r)
    Leaf -> 0

fun smallest(t : tree, d : int) : int
  match t
    Node(_, l, x, _) -> smallest(l, x)
    Leaf -> d

fun largest(t : tree, d : int) : int
  match t
    Node(_, _, x, r) -> largest(r, x)
    Leaf -> d

pub fun main()
  val t = insert-all(build(999999, Nil), Leaf)
  println("count " ++ count(t).show)
  println("sum " ++ sum(t).show)
  println("smallest " ++ smallest(t, 0).show)
  println("largest " ++ largest(t, 0).show)
