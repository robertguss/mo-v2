//! Benchmark 4, helper version (lead's driver): replace a list of 1,000,000 amounts with
//! its running totals, 100 times over. Amount i is (i * 37) mod 1000, for i = 1 to 1,000,000.
use harness::{build_from_back, List, MODULUS};

fn main() {
    let mut list: List = build_from_back((1..=1_000_000i64).map(|i| (i * 37) % 1000));
    for _ in 0..100 {
        list = list.running_totals(MODULUS);
    }
    let (mut sum, mut last) = (0i64, 0i64);
    for v in list.iter() {
        sum = (sum + v) % MODULUS;
        last = v;
    }
    println!("first {}", list.first().unwrap_or(0));
    println!("last {last}");
    println!("sum-mod {sum}");
}
