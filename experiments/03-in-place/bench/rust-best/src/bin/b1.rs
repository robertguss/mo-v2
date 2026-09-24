//! Benchmark 1 with a Vec: add one to every number of 1,000,000, 100 times over.
extern crate rust_best;

fn main() {
    let mut v: Vec<i64> = (1..=1_000_000).collect();
    for _ in 0..100 {
        for x in v.iter_mut() {
            *x += 1;
        }
    }
    println!("sum {}", v.iter().sum::<i64>());
    println!("first {}", v[0]);
    println!("last {}", v[v.len() - 1]);
}
