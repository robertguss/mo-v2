//! Benchmark 2: insert 1,000,000 scrambled keys into a red-black tree (Okasaki's insertion),
//! with every node edited in place.
extern crate rust_same;

use std::mem;

#[derive(Clone, Copy, PartialEq)]
enum Color {
    Red,
    Black,
}
use Color::{Black, Red};

struct Node {
    color: Color,
    left: Tree,
    key: i64,
    right: Tree,
}
type Tree = Option<Box<Node>>;

struct Cell {
    val: i64,
    next: List,
}
type List = Option<Box<Cell>>;

/// Build the key list from the back: key i is (i * 7919) mod 1,000,003.
fn build(n: i64) -> List {
    let mut acc = None;
    for i in (0..n).rev() {
        acc = Some(Box::new(Cell { val: (i * 7919) % 1_000_003, next: acc }));
    }
    acc
}

fn is_red(t: &Tree) -> bool {
    matches!(t, Some(n) if n.color == Red)
}

/// Okasaki's four imbalance cases. Each re-points the three nodes involved so that the
/// middle key ends up red at `n`'s position with two black children; no node is allocated.
fn balance(n: &mut Box<Node>) {
    if n.color != Black {
        return;
    }
    let left_red = is_red(&n.left);
    let right_red = is_red(&n.right);
    if left_red && is_red(&n.left.as_ref().unwrap().left) {
        // Node(B, Node(R, Node(R, a, x, b), y, c), z, d)
        let mut y = n.left.take().unwrap();
        let mut x = y.left.take().unwrap();
        x.color = Black;
        n.left = y.right.take();
        mem::swap(n, &mut y); // n is now y; `y` holds z
        let mut z = y;
        z.color = Black;
        n.color = Red;
        n.left = Some(x);
        n.right = Some(z);
    } else if left_red && is_red(&n.left.as_ref().unwrap().right) {
        // Node(B, Node(R, a, x, Node(R, b, y, c)), z, d)
        let mut x = n.left.take().unwrap();
        let mut y = x.right.take().unwrap();
        x.color = Black;
        x.right = y.left.take();
        n.left = y.right.take();
        mem::swap(n, &mut y); // n is now y; `y` holds z
        let mut z = y;
        z.color = Black;
        n.color = Red;
        n.left = Some(x);
        n.right = Some(z);
    } else if right_red && is_red(&n.right.as_ref().unwrap().left) {
        // Node(B, a, x, Node(R, Node(R, b, y, c), z, d))
        let mut z = n.right.take().unwrap();
        let mut y = z.left.take().unwrap();
        z.color = Black;
        z.left = y.right.take();
        n.right = y.left.take();
        mem::swap(n, &mut y); // n is now y; `y` holds x
        let mut x = y;
        x.color = Black;
        n.color = Red;
        n.left = Some(x);
        n.right = Some(z);
    } else if right_red && is_red(&n.right.as_ref().unwrap().right) {
        // Node(B, a, x, Node(R, b, y, Node(R, c, z, d)))
        let mut y = n.right.take().unwrap();
        let mut z = y.right.take().unwrap();
        z.color = Black;
        n.right = y.left.take();
        mem::swap(n, &mut y); // n is now y; `y` holds x
        let mut x = y;
        x.color = Black;
        n.color = Red;
        n.left = Some(x);
        n.right = Some(z);
    }
}

/// Go down to the insertion point, add a red node, and rebalance on the way back up.
fn ins(t: &mut Tree, k: i64) {
    match t {
        None => *t = Some(Box::new(Node { color: Red, left: None, key: k, right: None })),
        Some(n) => {
            if k < n.key {
                ins(&mut n.left, k);
                balance(n);
            } else if k > n.key {
                ins(&mut n.right, k);
                balance(n);
            }
        }
    }
}

fn insert(t: &mut Tree, k: i64) {
    ins(t, k);
    if let Some(n) = t {
        n.color = Black;
    }
}

fn count(t: &Tree) -> i64 {
    match t {
        Some(n) => count(&n.left) + 1 + count(&n.right),
        None => 0,
    }
}

fn sum(t: &Tree) -> i64 {
    match t {
        Some(n) => sum(&n.left) + n.key + sum(&n.right),
        None => 0,
    }
}

fn smallest(mut t: &Tree, mut d: i64) -> i64 {
    while let Some(n) = t {
        d = n.key;
        t = &n.left;
    }
    d
}

fn largest(mut t: &Tree, mut d: i64) -> i64 {
    while let Some(n) = t {
        d = n.key;
        t = &n.right;
    }
    d
}

fn main() {
    let mut keys = build(1_000_000);
    let mut tree: Tree = None;
    // Consume the key list, freeing each cell as its key is inserted.
    while let Some(cell) = keys {
        let Cell { val, next } = *cell;
        keys = next;
        insert(&mut tree, val);
    }
    println!("count {}", count(&tree));
    println!("sum {}", sum(&tree));
    println!("smallest {}", smallest(&tree, 0));
    println!("largest {}", largest(&tree, 0));
    // The tree is balanced (depth about 40), so its ordinary recursive drop frees it.
    drop(tree);
}
