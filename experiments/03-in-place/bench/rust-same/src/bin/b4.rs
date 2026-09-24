//! Benchmark 4: replace a singly linked list of 1,000,000 amounts with its running totals, 100 times over.
extern crate rust_same;

const MODULUS: i64 = 1_000_000_007;

struct Cell {
    val: i64,
    next: List,
}
type List = Option<Box<Cell>>;

/// Build the amounts from the back: amount i is (i * 37) mod 1000, for i = 1 to n.
fn build(n: i64) -> List {
    let mut acc = None;
    for i in (1..=n).rev() {
        acc = Some(Box::new(Cell { val: (i * 37) % 1000, next: acc }));
    }
    acc
}

/// One walk of the list, carrying the running total and changing each value in place.
fn running(list: &mut List) {
    let mut total = 0;
    let mut cur = list;
    while let Some(cell) = cur {
        total = (total + cell.val) % MODULUS;
        cell.val = total;
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
        running(&mut list);
    }
    let (mut sum, mut last) = (0i64, 0i64);
    let mut cur = &list;
    while let Some(cell) = cur {
        sum = (sum + cell.val) % MODULUS;
        last = cell.val;
        cur = &cell.next;
    }
    let first = list.as_ref().map_or(0, |c| c.val);
    println!("first {first}");
    println!("last {last}");
    println!("sum-mod {sum}");
    free(list);
}
