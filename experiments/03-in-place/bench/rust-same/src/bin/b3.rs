//! Benchmark 3: reverse a singly linked list of 1,000,000 numbers, 101 times.
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

/// Move cells one at a time from the front of `list` to the front of `acc`, re-pointing each cell.
fn reverse(mut list: List) -> List {
    let mut acc = None;
    while let Some(mut cell) = list {
        list = cell.next.take();
        cell.next = acc;
        acc = Some(cell);
    }
    acc
}

/// Free the list in a loop, not by recursion.
fn free(mut list: List) {
    while let Some(mut cell) = list {
        list = cell.next.take();
    }
}

fn main() {
    let mut list = build(1_000_000);
    for _ in 0..101 {
        list = reverse(list);
    }
    let (mut weighted, mut pos, mut last) = (0i64, 1i64, 0i64);
    let mut cur = &list;
    while let Some(cell) = cur {
        weighted += pos * cell.val;
        pos += 1;
        last = cell.val;
        cur = &cell.next;
    }
    let first = list.as_ref().map_or(0, |c| c.val);
    println!("first {first}");
    println!("last {last}");
    println!("weighted {weighted}");
    free(list);
}
