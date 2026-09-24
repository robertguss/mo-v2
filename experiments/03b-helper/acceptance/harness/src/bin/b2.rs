//! Benchmark 2, helper version (lead's driver): insert 1,000,000 scrambled keys into a
//! red-black tree. Key i is (i * 7919) mod 1,000,003. As in Experiment 3's same-container
//! Rust b2, the keys are built as a list from the back, then consumed one at a time.
use harness::{build_from_back, List, Tree};

fn main() {
    let mut keys: List = build_from_back((0..1_000_000i64).map(|i| (i * 7919) % 1_000_003));
    let mut tree = Tree::new();
    while let Some((key, rest)) = keys.pop_front() {
        keys = rest;
        tree = tree.insert(key);
    }
    // Experiment 3's same-container Rust reads the tree with two full walks (count, sum)
    // and two edge walks (smallest, largest). Through the helper's operations the closest
    // match is three full walks and one edge walk, so the remaining difference counts
    // against the helper, not for it.
    let count = tree.iter().count();
    let sum: i64 = tree.iter().sum();
    let smallest = tree.iter().next().unwrap_or(0);
    let largest = tree.iter().last().unwrap_or(0);
    println!("count {count}");
    println!("sum {sum}");
    println!("smallest {smallest}");
    println!("largest {largest}");
}
