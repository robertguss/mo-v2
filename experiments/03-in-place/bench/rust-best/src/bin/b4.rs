//! Benchmark 4 with a Vec: replace 1,000,000 amounts with their running totals, 100 times over.
extern crate rust_best;

const MODULUS: i64 = 1_000_000_007;

fn main() {
    let mut v: Vec<i64> = (1..=1_000_000i64).map(|i| (i * 37) % 1000).collect();
    for _ in 0..100 {
        let mut total = 0;
        for x in v.iter_mut() {
            total = (total + *x) % MODULUS;
            *x = total;
        }
    }
    let sum = v.iter().fold(0, |acc, x| (acc + x) % MODULUS);
    println!("first {}", v[0]);
    println!("last {}", v[v.len() - 1]);
    println!("sum-mod {sum}");
}
