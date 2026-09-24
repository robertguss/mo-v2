//! Claim B's repeated-sharing case (D63), helper version (lead's driver). Benchmark 1,
//! but every round keeps the previous version live while building the new one, reads
//! both, and releases the old one before the next round. Each round must copy.
use harness::{build_from_back, List};

fn main() {
    let mut list: List = build_from_back(1..=1_000_000i64);
    let (mut differ, mut prev_sum) = (0i64, 0i64);
    for round in 1..=100 {
        let prev = list.clone();
        list = list.add_one();
        differ += list.first().unwrap_or(0) - prev.first().unwrap_or(0);
        if round == 100 {
            prev_sum = prev.iter().sum();
        }
        drop(prev);
    }
    let (mut sum, mut last) = (0i64, 0i64);
    for v in list.iter() {
        sum += v;
        last = v;
    }
    println!("sum {sum}");
    println!("first {}", list.first().unwrap_or(0));
    println!("last {last}");
    println!("rounds-differ {differ}");
    println!("prev-sum {prev_sum}");
}
