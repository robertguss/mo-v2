//! Control helper for claim C2, written by the lead: correct values, but every update
//! builds new cells or new tree nodes, even when the value has only one holder.
//! It must pass claim C1 (values are right) and fail claim C2 (it allocates).
use std::rc::Rc;

struct Cell {
    value: i64,
    next: Option<Rc<Cell>>,
}

#[derive(Clone)]
pub struct List(Option<Rc<Cell>>);

impl List {
    pub fn new() -> List {
        List(None)
    }

    pub fn push_front(mut self, value: i64) -> List {
        let next = self.0.take();
        List(Some(Rc::new(Cell { value, next })))
    }

    pub fn pop_front(mut self) -> Option<(i64, List)> {
        let cell = self.0.take()?;
        Some((cell.value, List(cell.next.clone())))
    }

    fn rebuild(values: Vec<i64>) -> List {
        let mut out = List::new();
        for v in values.into_iter().rev() {
            out = out.push_front(v);
        }
        out
    }

    pub fn add_one(self) -> List {
        List::rebuild(self.iter().map(|v| v + 1).collect())
    }

    pub fn reverse(self) -> List {
        let mut out = List::new();
        for v in self.iter() {
            out = out.push_front(v);
        }
        out
    }

    pub fn running_totals(self, modulus: i64) -> List {
        let mut total = 0;
        let values: Vec<i64> = self
            .iter()
            .map(|v| {
                total = (total + v) % modulus;
                total
            })
            .collect();
        List::rebuild(values)
    }

    pub fn first(&self) -> Option<i64> {
        self.0.as_ref().map(|c| c.value)
    }

    pub fn iter(&self) -> impl Iterator<Item = i64> + '_ {
        let mut cur = self.0.as_deref();
        std::iter::from_fn(move || {
            let c = cur?;
            cur = c.next.as_deref();
            Some(c.value)
        })
    }
}

impl Drop for List {
    fn drop(&mut self) {
        let mut cur = self.0.take();
        while let Some(rc) = cur {
            match Rc::try_unwrap(rc) {
                Ok(mut cell) => cur = cell.next.take(),
                Err(_) => break,
            }
        }
    }
}

#[derive(Clone, Copy, PartialEq)]
enum Color {
    Red,
    Black,
}

struct Node {
    color: Color,
    left: Option<Rc<Node>>,
    key: i64,
    right: Option<Rc<Node>>,
}

type Link = Option<Rc<Node>>;

fn node(color: Color, left: Link, key: i64, right: Link) -> Link {
    Some(Rc::new(Node { color, left, key, right }))
}

fn red(t: &Link) -> Option<&Node> {
    t.as_deref().filter(|n| n.color == Color::Red)
}

// Okasaki's balance, building new nodes every time (path copying).
fn balance(color: Color, left: Link, key: i64, right: Link) -> Link {
    use Color::{Black, Red};
    if color == Black {
        if let Some(l) = red(&left) {
            if let Some(ll) = red(&l.left) {
                return node(Red, node(Black, ll.left.clone(), ll.key, ll.right.clone()), l.key,
                            node(Black, l.right.clone(), key, right));
            }
            if let Some(lr) = red(&l.right) {
                return node(Red, node(Black, l.left.clone(), l.key, lr.left.clone()), lr.key,
                            node(Black, lr.right.clone(), key, right));
            }
        }
        if let Some(r) = red(&right) {
            if let Some(rl) = red(&r.left) {
                return node(Red, node(Black, left, key, rl.left.clone()), rl.key,
                            node(Black, rl.right.clone(), r.key, r.right.clone()));
            }
            if let Some(rr) = red(&r.right) {
                return node(Red, node(Black, left, key, r.left.clone()), r.key,
                            node(Black, rr.left.clone(), rr.key, rr.right.clone()));
            }
        }
    }
    node(color, left, key, right)
}

fn ins(t: &Link, key: i64) -> Link {
    match t {
        None => node(Color::Red, None, key, None),
        Some(n) => {
            if key < n.key {
                balance(n.color, ins(&n.left, key), n.key, n.right.clone())
            } else if key > n.key {
                balance(n.color, n.left.clone(), n.key, ins(&n.right, key))
            } else {
                t.clone()
            }
        }
    }
}

#[derive(Clone)]
pub struct Tree(Link);

impl Tree {
    pub fn new() -> Tree {
        Tree(None)
    }

    pub fn insert(self, key: i64) -> Tree {
        let t = ins(&self.0, key);
        match t {
            Some(n) if n.color == Color::Red => Tree(node(Color::Black, n.left.clone(), n.key, n.right.clone())),
            other => Tree(other),
        }
    }

    pub fn iter(&self) -> impl Iterator<Item = i64> + '_ {
        fn walk(t: &Link, out: &mut Vec<i64>) {
            if let Some(n) = t {
                walk(&n.left, out);
                out.push(n.key);
                walk(&n.right, out);
            }
        }
        let mut out = Vec::new();
        walk(&self.0, &mut out);
        out.into_iter()
    }
}
