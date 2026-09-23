// Claim D examples. Written by the lead; the builder may not change this file.
// Each line prints "ok" or "FAIL" with the example's name.
module examples
import types
import functions

fun check(name : string, got : string, want : string) : console ()
  if got == want then println("ok   " ++ name)
  else println("FAIL " ++ name ++ ": got " ++ got ++ ", want " ++ want)

fun show-ints(xs : list<int>) : string
  xs.show

fun show-products(ps : list<product>) : string
  ps.map(fn(p) p.name ++ "=" ++ p.price.show).join(",")

fun show-stock(xs : list<stock>) : string
  xs.map(fn(s) s.sku ++ "=" ++ s.count.show).join(",")

fun keys(t : tree) : list<int>
  match t
    Leaf -> []
    Node(l, k, r) -> keys(l) ++ [k] ++ keys(r)

fun sorted-tree(xs : list<int>) : tree
  xs.foldl(Leaf, fn(t, k) plain-insert(t, k))

fun plain-insert(t : tree, k : int) : tree
  match t
    Leaf -> Node(Leaf, k, Leaf)
    Node(l, x, r) ->
      if k < x then Node(plain-insert(l, k), x, r)
      elif k > x then Node(l, x, plain-insert(r, k))
      else t

fun show-strings(xs : list<string>) : string
  xs.map(fn(s) "[" ++ s ++ "]").join(",")

fun show-customer(c : customer) : string
  c.name ++ "|" ++ c.address.street ++ "|" ++ c.address.city

pub fun main()
  // 1 invoice totals
  check("invoice-total empty", invoice-total([]).show, "0")
  check("invoice-total two lines", invoice-total([Item(2, 500), Item(1, 250)]).show, "1250")
  // 2 price change: new price = price * (100 + percent) / 100, rounded down
  check("price-change +10", show-products(apply-price-change([Product("pen", 100), Product("pad", 250)], 10)), "pen=110,pad=275")
  check("price-change -50 rounds down", show-products(apply-price-change([Product("cup", 101)], -50)), "cup=50")
  // 3 stock update: reduce the count of one item; an unknown item changes nothing
  check("update-stock sale", show-stock(update-stock([Stock("a", 5), Stock("b", 3)], "b", 2)), "a=5,b=1")
  check("update-stock unknown", show-stock(update-stock([Stock("a", 5)], "z", 1)), "a=5")
  // 4 queue reordering: move the first item to the back
  check("rotate-queue", show-ints(rotate-queue([1, 2, 3])), "[2,3,1]")
  check("rotate-queue empty", show-ints(rotate-queue([])), "[]")
  // 5 insert into a sorted tree; an existing key changes nothing
  check("tree-insert new", show-ints(keys(tree-insert(sorted-tree([3, 1, 7]), 5))), "[1,3,5,7]")
  check("tree-insert existing", show-ints(keys(tree-insert(sorted-tree([3, 1, 7]), 3))), "[1,3,7]")
  // 6 remove from a sorted tree; a missing key changes nothing
  check("tree-remove middle", show-ints(keys(tree-remove(sorted-tree([3, 1, 7, 5]), 3))), "[1,5,7]")
  check("tree-remove missing", show-ints(keys(tree-remove(sorted-tree([3, 1, 7]), 4))), "[1,3,7]")
  // 7 parse one line of comma-separated values
  check("parse-csv-line", show-strings(parse-csv-line("a,b,,c")), "[a],[b],[],[c]")
  check("parse-csv-line empty", show-strings(parse-csv-line("")), "[]")
  // 8 merge two sorted lists
  check("merge-sorted", show-ints(merge-sorted([1, 4, 6], [2, 3, 7])), "[1,2,3,4,6,7]")
  // 9 sort
  check("sort-ints", show-ints(sort-ints([3, 1, 2])), "[1,2,3]")
  check("sort-ints duplicates", show-ints(sort-ints([2, 1, 2])), "[1,2,2]")
  // 10 update one field in a nested record
  check("set-city", show-customer(set-city(Customer("Ann", Address("1 Main", "Oslo")), "Bergen")), "Ann|1 Main|Bergen")
