// Claim D: ten realistic functions, each marked with the relaxed in-place demand (fbip).
module functions

import types

// Walks the invoice with a running total; each line cell is freed as it is read.
pub fbip fun invoice-total(lines : list<item>) : int
  total-from(lines, 0)

// Accumulator loop for invoice-total.
pub fbip fun total-from(lines : list<item>, acc : int) : int
  match lines
    Cons(Item(q, p), rest) -> total-from(rest, acc + q * p)
    Nil -> acc

// Rebuilds each product and list cell in place with the new price.
pub fbip fun apply-price-change(products : list<product>, percent : int) : list<product>
  match products
    Cons(Product(name, price), rest) ->
      Cons(Product(name, (price * (100 + percent)) / 100), apply-price-change(rest, percent))
    Nil -> Nil

// Walks to the matching item and rebuilds its record in place; comparing skus needs string equality, which is not fip.
pub fbip fun update-stock(items : list<stock>, sku : string, sold : int) : list<stock>
  match items
    Cons(Stock(s, c), rest) ->
      if s == sku then Cons(Stock(s, c - sold), rest)
      else Cons(Stock(s, c), update-stock(rest, sku, sold))
    Nil -> Nil

// The first cell is reused as the new last cell, which is then appended.
pub fbip fun rotate-queue(queue : list<int>) : list<int>
  match queue
    Cons(x, rest) -> append-cell(rest, Cons(x, Nil))
    Nil -> Nil

// Walks to the end of the list, reusing each cell, and hangs the given cell there.
pub fbip fun append-cell(xs : list<int>, last : list<int>) : list<int>
  match xs
    Cons(y, rest) -> Cons(y, append-cell(rest, last))
    Nil -> last

// Plain unbalanced insertion; the new key needs a new node, so this cannot avoid allocating.
pub fbip fun tree-insert(t : tree, k : int) : tree
  match t
    Leaf -> Node(Leaf, k, Leaf)
    Node(l, x, r) ->
      if k < x then Node(tree-insert(l, k), x, r)
      elif k > x then Node(l, x, tree-insert(r, k))
      else Node(l, x, r)

// Removal reusing each node on the path; a removed key's right side has its smallest node rotated up to replace it.
pub fbip fun tree-remove(t : tree, k : int) : tree
  match t
    Leaf -> Leaf
    Node(l, x, r) ->
      if k < x then Node(tree-remove(l, k), x, r)
      elif k > x then Node(l, x, tree-remove(r, k))
      else match lift-min(r)
        Node(_, m, rr) -> Node(l, m, rr)
        Leaf -> l

// Rotates the smallest node up to the root, reusing every node, so the root's left side is empty.
pub fbip fun lift-min(t : tree) : tree
  match t
    Node(l, x, r) ->
      match lift-min(l)
        Node(_, m, lr) -> Node(Leaf, m, Node(lr, x, r))
        Leaf -> Node(Leaf, x, r)
    Leaf -> Leaf

// Natural version using the standard split; splitting makes new strings, so it cannot be in place.
pub fbip fun parse-csv-line(line : string) : list<string>
  line.split(",")

// Classic merge; each output cell reuses the input cell its value came from (div: Koka can't prove it ends).
pub fbip fun merge-sorted(xs : list<int>, ys : list<int>) : div list<int>
  match xs
    Nil -> ys
    Cons(x, xx) ->
      match ys
        Nil -> Cons(x, xx)
        Cons(y, yy) ->
          if x <= y then Cons(x, merge-sorted(xx, Cons(y, yy)))
          else Cons(y, merge-sorted(Cons(x, xx), yy))

// Insertion sort; each input cell is detached and reinserted, so no cell is ever allocated.
pub fbip fun sort-ints(xs : list<int>) : list<int>
  match xs
    Cons(x, rest) -> insert-cell(Cons(x, Nil), sort-ints(rest))
    Nil -> Nil

// Inserts a one-item list into a sorted list, reusing its cell and the cells it passes.
pub fbip fun insert-cell(cell : list<int>, sorted : list<int>) : list<int>
  match cell
    Cons(x, _) ->
      match sorted
        Cons(y, rest) ->
          if x <= y then Cons(x, Cons(y, rest))
          else Cons(y, insert-cell(Cons(x, Nil), rest))
        Nil -> Cons(x, Nil)
    Nil -> sorted

// Rebuilds the customer and address records in place with the new city.
pub fbip fun set-city(c : customer, city : string) : customer
  match c
    Customer(name, Address(street, _)) -> Customer(name, Address(street, city))
