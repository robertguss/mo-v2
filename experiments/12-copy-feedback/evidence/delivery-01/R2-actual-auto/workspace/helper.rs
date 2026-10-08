//! Experiment 3b's in-place helper, written by the builder: a singly linked list and an
//! Okasaki red-black tree in which every list cell and every tree node is its own `Rc`.
//!
//! An operation changes a cell or node in place when it has one holder, and copies that
//! cell or node first when it has more, so no other holder ever sees a change.
//! `Rc::make_mut` does exactly this: with a count of one it hands back the cell itself,
//! otherwise it copies the cell, lets go of the shared original and hands back the copy.
//! Copying a cell or node copies only that one; the copy shares everything below it.
//! Adding a holder (`clone` on a `List` or `Tree`) only raises a count.
//!
//! The algorithms follow Experiment 3's same-container Rust
//! (`experiments/03-in-place/bench/rust-same/src/bin/`) step for step; each function
//! names its counterpart there.

use std::mem;
use std::rc::Rc;

// ------------------------------------------------------------------------------ lists

/// One list cell. Cloning it (done only by `Rc::make_mut`, on a shared cell) copies this
/// cell alone: the copy points at the same rest of the list, which gains a holder.
#[derive(Clone)]
struct ListCell {
    val: i64,
    next: Option<Rc<ListCell>>,
}

/// Free the rest of the list in a loop, not by recursion (Experiment 3's `free`), and stop
/// at the first cell another holder still has.
impl Drop for ListCell {
    fn drop(&mut self) {
        let mut next = self.next.take();
        while let Some(rc) = next {
            // `into_inner` gives the cell back only if this was its last holder, and it is
            // then freed once its own `next` has been taken. Otherwise it only lets go.
            next = match Rc::into_inner(rc) {
                Some(mut cell) => cell.next.take(),
                None => None,
            };
        }
    }
}

/// A list of numbers. `Clone` adds a holder of the same cells; it copies nothing.
#[derive(Clone)]
pub struct List {
    head: Option<Rc<ListCell>>,
}

impl List {
    /// An empty list.
    pub fn new() -> List {
        List { head: None }
    }

    /// Add a value at the front: one new cell, pointing at the old list, which it shares.
    /// The input builders in Experiment 3 add cells this way, one at a time from the back.
    pub fn push_front(self, value: i64) -> List {
        List { head: Some(Rc::new(ListCell { val: value, next: self.head })) }
    }

    /// Take the first value off, giving the value and the rest. With one holder, the first
    /// cell is freed and the rest is handed on (Experiment 3's b2 key loop). If the first
    /// cell is shared, the rest gains a holder instead. Nothing is allocated either way.
    pub fn pop_front(self) -> Option<(i64, List)> {
        let first = self.head?;
        match Rc::try_unwrap(first) {
            Ok(mut cell) => Some((cell.val, List { head: cell.next.take() })),
            Err(shared) => Some((shared.val, List { head: shared.next.clone() })),
        }
    }

    /// One walk of the list, replacing each value with `f` of it, in order (Experiment 3's
    /// b1 `add_one` and b4 `running`). A cell with one holder is changed in place. Once the
    /// walk reaches a shared cell, every later cell is reachable through it, so from there
    /// on each cell is shared too: `make_mut` copies it as the walk reaches it, and the
    /// other holder keeps the old cells unchanged.
    fn map_values(mut self, mut f: impl FnMut(i64) -> i64) -> List {
        let mut cur = &mut self.head;
        while let Some(rc) = cur {
            let cell = Rc::make_mut(rc);
            cell.val = f(cell.val);
            cur = &mut cell.next;
        }
        self
    }

    /// Add one to every value (benchmark 1).
    pub fn add_one(self) -> List {
        self.map_values(|v| v + 1)
    }

    /// Reverse the list (benchmark 3): move cells one at a time from the front of this list
    /// to the front of another, re-pointing each (Experiment 3's b3 `reverse`). A cell with
    /// one holder is moved as it is; a shared cell is copied first and the copy is moved.
    pub fn reverse(self) -> List {
        let mut acc = None;
        let mut list = self.head;
        while let Some(mut rc) = list {
            let cell = Rc::make_mut(&mut rc);
            list = cell.next.take();
            cell.next = acc;
            acc = Some(rc);
        }
        List { head: acc }
    }

    /// Replace each value with the running total so far, total = (total + value) % modulus,
    /// from 0 (benchmark 4).
    pub fn running_totals(self, modulus: i64) -> List {
        let mut total = 0;
        self.map_values(move |v| {
            total = (total + v) % modulus;
            total
        })
    }

    /// The first value, if any.
    pub fn first(&self) -> Option<i64> {
        self.head.as_ref().map(|cell| cell.val)
    }

    /// The values from front to back, without changing anything.
    pub fn iter(&self) -> impl Iterator<Item = i64> + '_ {
        let mut cur = self.head.as_deref();
        std::iter::from_fn(move || {
            let cell = cur?;
            cur = cell.next.as_deref();
            Some(cell.val)
        })
    }
}

// ------------------------------------------------------------------------------ trees

#[derive(Clone, Copy, PartialEq)]
enum Color {
    Red,
    Black,
}
use Color::{Black, Red};

/// One tree node. Cloning it (done only by `Rc::make_mut`, on a shared node) copies this
/// node alone: the copy points at the same two subtrees, which gain a holder each.
#[derive(Clone)]
struct Node {
    color: Color,
    left: Link,
    key: i64,
    right: Link,
}
type Link = Option<Rc<Node>>;

/// A red-black tree of distinct keys. `Clone` adds a holder of the same nodes; it copies
/// nothing.
#[derive(Clone)]
pub struct Tree {
    root: Link,
}

fn is_red(t: &Link) -> bool {
    match t {
        Some(n) => n.color == Red,
        None => false,
    }
}

/// Okasaki's four imbalance cases, as in Experiment 3's b2 `balance`. Each re-points the
/// three nodes involved so that the middle key ends up red at `n`'s position with two black
/// children; no node is allocated. The three nodes are all on the path `ins` just came up,
/// which it has already made single-holder, so each `make_mut` here copies nothing.
fn balance(n: &mut Rc<Node>) {
    if n.color != Black {
        return;
    }
    let left_red = is_red(&n.left);
    let right_red = is_red(&n.right);
    if left_red && is_red(&n.left.as_ref().unwrap().left) {
        // Node(B, Node(R, Node(R, a, x, b), y, c), z, d)
        let top = Rc::make_mut(n);
        let mut y = top.left.take().unwrap();
        let ym = Rc::make_mut(&mut y);
        let mut x = ym.left.take().unwrap();
        Rc::make_mut(&mut x).color = Black;
        top.left = ym.right.take();
        mem::swap(n, &mut y); // n is now y; `y` holds z
        let mut z = y;
        Rc::make_mut(&mut z).color = Black;
        let top = Rc::make_mut(n);
        top.color = Red;
        top.left = Some(x);
        top.right = Some(z);
    } else if left_red && is_red(&n.left.as_ref().unwrap().right) {
        // Node(B, Node(R, a, x, Node(R, b, y, c)), z, d)
        let top = Rc::make_mut(n);
        let mut x = top.left.take().unwrap();
        let xm = Rc::make_mut(&mut x);
        let mut y = xm.right.take().unwrap();
        let ym = Rc::make_mut(&mut y);
        xm.color = Black;
        xm.right = ym.left.take();
        top.left = ym.right.take();
        mem::swap(n, &mut y); // n is now y; `y` holds z
        let mut z = y;
        Rc::make_mut(&mut z).color = Black;
        let top = Rc::make_mut(n);
        top.color = Red;
        top.left = Some(x);
        top.right = Some(z);
    } else if right_red && is_red(&n.right.as_ref().unwrap().left) {
        // Node(B, a, x, Node(R, Node(R, b, y, c), z, d))
        let top = Rc::make_mut(n);
        let mut z = top.right.take().unwrap();
        let zm = Rc::make_mut(&mut z);
        let mut y = zm.left.take().unwrap();
        let ym = Rc::make_mut(&mut y);
        zm.color = Black;
        zm.left = ym.right.take();
        top.right = ym.left.take();
        mem::swap(n, &mut y); // n is now y; `y` holds x
        let mut x = y;
        Rc::make_mut(&mut x).color = Black;
        let top = Rc::make_mut(n);
        top.color = Red;
        top.left = Some(x);
        top.right = Some(z);
    } else if right_red && is_red(&n.right.as_ref().unwrap().right) {
        // Node(B, a, x, Node(R, b, y, Node(R, c, z, d)))
        let top = Rc::make_mut(n);
        let mut y = top.right.take().unwrap();
        let ym = Rc::make_mut(&mut y);
        let mut z = ym.right.take().unwrap();
        Rc::make_mut(&mut z).color = Black;
        top.right = ym.left.take();
        mem::swap(n, &mut y); // n is now y; `y` holds x
        let mut x = y;
        Rc::make_mut(&mut x).color = Black;
        let top = Rc::make_mut(n);
        top.color = Red;
        top.left = Some(x);
        top.right = Some(z);
    }
}

/// Is `k` in the subtree under `n`? One walk down, changing nothing.
fn contains(mut n: &Node, k: i64) -> bool {
    loop {
        let next = if k < n.key {
            &n.left
        } else if k > n.key {
            &n.right
        } else {
            return true;
        };
        match next {
            Some(child) => n = child,
            None => return false,
        }
    }
}

/// Go down to the insertion point, add a red node, and rebalance on the way back up
/// (Experiment 3's b2 `ins`). Each node on the way down goes through `make_mut`: with one
/// holder it is changed in place; if shared, it is copied first, so only the path is copied
/// and the rest of the tree stays shared.
///
/// An insert of a key that is already there changes nothing, so it must copy nothing. The
/// first time the walk meets a shared node it therefore checks, once, whether the key is
/// already below; if it is, it stops there. `absent` records that this check has been done
/// and found nothing. With one holder all the way down, as in benchmark 2, the check never
/// runs.
fn ins(t: &mut Link, k: i64, mut absent: bool) {
    match t {
        None => *t = Some(Rc::new(Node { color: Red, left: None, key: k, right: None })),
        Some(n) => {
            if !absent && Rc::strong_count(n) > 1 {
                if contains(n, k) {
                    return;
                }
                absent = true;
            }
            let node = Rc::make_mut(n);
            if k < node.key {
                ins(&mut node.left, k, absent);
                balance(n);
            } else if k > node.key {
                ins(&mut node.right, k, absent);
                balance(n);
            }
        }
    }
}

/// Push `t` and its chain of left children, so the smallest key is on top of the stack.
fn push_left<'a>(stack: &mut Vec<&'a Node>, mut t: &'a Link) {
    while let Some(n) = t {
        stack.push(n);
        t = &n.left;
    }
}

impl Tree {
    /// An empty tree.
    pub fn new() -> Tree {
        Tree { root: None }
    }

    /// Insert a key; an existing key changes nothing (Experiment 3's b2 `insert`). Then make
    /// the root black. The root is red only straight after a change, when `ins` has already
    /// made it single-holder, so this never copies.
    pub fn insert(self, key: i64) -> Tree {
        let mut root = self.root;
        ins(&mut root, key, false);
        if let Some(n) = &mut root {
            if n.color == Red {
                Rc::make_mut(n).color = Black;
            }
        }
        Tree { root }
    }

    /// The keys in ascending order, without changing anything.
    pub fn iter(&self) -> impl Iterator<Item = i64> + '_ {
        let mut stack = Vec::new();
        push_left(&mut stack, &self.root);
        std::iter::from_fn(move || {
            let n = stack.pop()?;
            push_left(&mut stack, &n.right);
            Some(n.key)
        })
    }
}
