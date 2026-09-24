//! Control helper for claim C1, written by the lead: every holder shares one mutable
//! store (safe Rust, defined behaviour), so updating through one holder changes what
//! every other holder sees. This breaks D26's promise on purpose; claim C1 must catch it.
use std::cell::RefCell;
use std::collections::BTreeSet;
use std::rc::Rc;

/// The list is stored back to front, so the front is the last element of the vector.
#[derive(Clone)]
pub struct List(Rc<RefCell<Vec<i64>>>);

impl List {
    pub fn new() -> List {
        List(Rc::new(RefCell::new(Vec::new())))
    }

    pub fn push_front(self, value: i64) -> List {
        self.0.borrow_mut().push(value);
        self
    }

    pub fn pop_front(self) -> Option<(i64, List)> {
        let front = self.0.borrow_mut().pop();
        front.map(|v| (v, self))
    }

    pub fn add_one(self) -> List {
        for v in self.0.borrow_mut().iter_mut() {
            *v += 1;
        }
        self
    }

    pub fn reverse(self) -> List {
        self.0.borrow_mut().reverse();
        self
    }

    pub fn running_totals(self, modulus: i64) -> List {
        {
            let mut store = self.0.borrow_mut();
            let mut total = 0;
            for v in store.iter_mut().rev() {
                total = (total + *v) % modulus;
                *v = total;
            }
        }
        self
    }

    pub fn first(&self) -> Option<i64> {
        self.0.borrow().last().copied()
    }

    pub fn iter(&self) -> impl Iterator<Item = i64> + '_ {
        let values: Vec<i64> = self.0.borrow().iter().rev().copied().collect();
        values.into_iter()
    }
}

#[derive(Clone)]
pub struct Tree(Rc<RefCell<BTreeSet<i64>>>);

impl Tree {
    pub fn new() -> Tree {
        Tree(Rc::new(RefCell::new(BTreeSet::new())))
    }

    pub fn insert(self, key: i64) -> Tree {
        self.0.borrow_mut().insert(key);
        self
    }

    pub fn iter(&self) -> impl Iterator<Item = i64> + '_ {
        let values: Vec<i64> = self.0.borrow().iter().copied().collect();
        values.into_iter()
    }
}
