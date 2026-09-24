//! Benchmark 3, helper version (lead's driver): reverse a list of 1,000,000, 101 times.
use harness::{build_from_back, List};

fn main() {
    let mut list: List = build_from_back(1..=1_000_000i64);
    for _ in 0..101 {
        list = list.reverse();
    }
    let (mut weighted, mut pos, mut last) = (0i64, 1i64, 0i64);
    for v in list.iter() {
        weighted += pos * v;
        pos += 1;
        last = v;
    }
    println!("first {}", list.first().unwrap_or(0));
    println!("last {last}");
    println!("weighted {weighted}");
}
