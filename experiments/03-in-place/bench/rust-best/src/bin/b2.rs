//! Benchmark 2 with a BTreeSet: insert 1,000,000 scrambled keys.
extern crate rust_best;

use std::collections::BTreeSet;

fn main() {
    let mut set = BTreeSet::new();
    for i in 0..1_000_000i64 {
        set.insert((i * 7919) % 1_000_003);
    }
    println!("count {}", set.len());
    println!("sum {}", set.iter().sum::<i64>());
    println!("smallest {}", set.first().unwrap());
    println!("largest {}", set.last().unwrap());
}
