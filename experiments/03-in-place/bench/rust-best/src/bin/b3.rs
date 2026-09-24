//! Benchmark 3 with a Vec: reverse 1,000,000 numbers, 101 times.
extern crate rust_best;

fn main() {
    let mut v: Vec<i64> = (1..=1_000_000).collect();
    for _ in 0..101 {
        v.reverse();
    }
    let weighted: i64 = v.iter().enumerate().map(|(i, x)| (i as i64 + 1) * x).sum();
    println!("first {}", v[0]);
    println!("last {}", v[v.len() - 1]);
    println!("weighted {weighted}");
}
