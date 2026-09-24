//! Benchmark 1: add one to every number in a singly linked list of 1,000,000, 100 times over.
extern crate rust_same;

struct Cell {
    val: i64,
    next: List,
}
type List = Option<Box<Cell>>;

/// Build [1..n] from the back, one cell at a time.
fn build(n: i64) -> List {
    let mut acc = None;
    for i in (1..=n).rev() {
        acc = Some(Box::new(Cell { val: i, next: acc }));
    }
    acc
}

/// One walk of the list, changing each value in place.
fn add_one(list: &mut List) {
    let mut cur = list;
    while let Some(cell) = cur {
        cell.val += 1;
        cur = &mut cell.next;
    }
}

/// Free the list in a loop, not by recursion.
fn free(mut list: List) {
    while let Some(mut cell) = list {
        list = cell.next.take();
    }
}

fn main() {
    let mut list = build(1_000_000);
    for _ in 0..100 {
        add_one(&mut list);
    }
    let (mut sum, mut last) = (0i64, 0i64);
    let mut cur = &list;
    while let Some(cell) = cur {
        sum += cell.val;
        last = cell.val;
        cur = &cell.next;
    }
    let first = list.as_ref().map_or(0, |c| c.val);
    println!("sum {sum}");
    println!("first {first}");
    println!("last {last}");
    free(list);
}
