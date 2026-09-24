//! Benchmark 1, helper version (lead's driver): add one to every number in a list of
//! 1,000,000, 100 times over. Same steps as Experiment 3's same-container Rust b1.
use harness::{build_from_back, List};

fn main() {
    let mut list: List = build_from_back(1..=1_000_000i64);
    for _ in 0..100 {
        list = list.add_one();
    }
    let (mut sum, mut last) = (0i64, 0i64);
    for v in list.iter() {
        sum += v;
        last = v;
    }
    println!("sum {sum}");
    println!("first {}", list.first().unwrap_or(0));
    println!("last {last}");
}
