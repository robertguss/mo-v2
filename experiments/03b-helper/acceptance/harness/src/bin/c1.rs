//! Claim C1, written by the lead: the helper preserves values in these fixed and
//! generated tests. After every operation, every live value is compared with a simple
//! copying reference model (Rust's Vec and BTreeSet). Output, one line per result:
//!   FIXED <name> ok|FAIL <detail>
//!   GENERATED <kind> sequences <n> failures <k>
//!   FAILURE <kind> seed <s> step <i> <detail> ops <sequence so far>   (every failure)
//!   DONE
//! A crash (for example a stack overflow while dropping a long list) ends the output
//! early; the measuring script then fails C1.
use harness::{build_from_back, List, Tree, MODULUS};
use std::collections::BTreeSet;
use std::io::Write;
use std::panic::{catch_unwind, AssertUnwindSafe};

const SEED_BASE: u64 = 20_260_923;
const SEQUENCES: u64 = 2_000;
const STEPS: usize = 60;

fn say(line: String) {
    println!("{line}");
    std::io::stdout().flush().ok();
}

fn vals(l: &List) -> Vec<i64> {
    l.iter().collect()
}

fn keys(t: &Tree) -> Vec<i64> {
    t.iter().collect()
}

fn list_of(v: &[i64]) -> List {
    build_from_back(v.iter().copied())
}

fn tree_of(v: &[i64]) -> Tree {
    let mut t = Tree::new();
    for &k in v {
        t = t.insert(k);
    }
    t
}

fn running(v: &[i64]) -> Vec<i64> {
    let mut total = 0;
    v.iter().map(|x| { total = (total + x) % MODULUS; total }).collect()
}

fn fixed(name: &str, f: impl FnOnce() -> Result<(), String>) {
    let r = catch_unwind(AssertUnwindSafe(f)).unwrap_or_else(|_| Err("panicked".into()));
    match r {
        Ok(()) => say(format!("FIXED {name} ok")),
        Err(d) => say(format!("FIXED {name} FAIL {d}")),
    }
}

fn expect<T: PartialEq + std::fmt::Debug>(what: &str, got: T, want: T) -> Result<(), String> {
    if got == want { Ok(()) } else { Err(format!("{what}: expected {want:?}, got {got:?}")) }
}

fn fixed_cases() {
    // Unique updates give the expected new value (this also rejects a helper that does nothing).
    fixed("unique-add-one", || expect("list", vals(&list_of(&[1, 2, 3]).add_one()), vec![2, 3, 4]));
    fixed("unique-reverse", || expect("list", vals(&list_of(&[1, 2, 3]).reverse()), vec![3, 2, 1]));
    fixed("unique-running-totals", || expect("list", vals(&list_of(&[1, 2, 3]).running_totals(MODULUS)), vec![1, 3, 6]));
    fixed("unique-push-front", || expect("list", vals(&list_of(&[2, 3]).push_front(1)), vec![1, 2, 3]));
    fixed("unique-pop-front", || {
        let (v, rest) = list_of(&[1, 2, 3]).pop_front().ok_or("pop of a non-empty list gave nothing")?;
        expect("value", v, 1)?;
        expect("rest", vals(&rest), vec![2, 3])
    });
    fixed("empty-list", || {
        expect("pop", List::new().pop_front().is_none(), true)?;
        expect("first", List::new().first(), None)?;
        expect("add-one", vals(&List::new().add_one()), vec![])
    });
    fixed("unique-tree-insert", || expect("tree", keys(&tree_of(&[5, 1, 9]).insert(3)), vec![1, 3, 5, 9]));
    fixed("tree-insert-existing", || expect("tree", keys(&tree_of(&[5, 1, 9]).insert(5)), vec![1, 5, 9]));

    // A shared update changes the chosen version and preserves the other.
    fixed("shared-add-one", || {
        let a = list_of(&[1, 2, 3]);
        let b = a.clone();
        let a = a.add_one();
        expect("updated", vals(&a), vec![2, 3, 4])?;
        expect("other holder", vals(&b), vec![1, 2, 3])
    });
    fixed("shared-reverse", || {
        let a = list_of(&[1, 2, 3]);
        let b = a.clone();
        let a = a.reverse();
        expect("updated", vals(&a), vec![3, 2, 1])?;
        expect("other holder", vals(&b), vec![1, 2, 3])
    });
    fixed("shared-running-totals", || {
        let a = list_of(&[1, 2, 3]);
        let b = a.clone();
        let a = a.running_totals(MODULUS);
        expect("updated", vals(&a), vec![1, 3, 6])?;
        expect("other holder", vals(&b), vec![1, 2, 3])
    });
    fixed("shared-push-pop", || {
        let a = list_of(&[1, 2, 3]);
        let b = a.clone();
        let (_, a) = a.pop_front().ok_or("pop gave nothing")?;
        let a = a.push_front(9);
        expect("updated", vals(&a), vec![9, 2, 3])?;
        expect("other holder", vals(&b), vec![1, 2, 3])
    });
    fixed("shared-tree-insert", || {
        let t = tree_of(&[10, 20, 30]);
        let u = t.clone();
        let t = t.insert(15);
        expect("updated", keys(&t), vec![10, 15, 20, 30])?;
        expect("other holder", keys(&u), vec![10, 20, 30])
    });

    // Two distinct roots share a tail or subtree; updating one preserves the other.
    fixed("shared-tail", || {
        let base = list_of(&[1, 2, 3]);
        let x = base.clone().push_front(10);
        let y = base.push_front(20);
        let x = x.add_one();
        expect("updated", vals(&x), vec![11, 2, 3, 4])?;
        expect("other root", vals(&y), vec![20, 1, 2, 3])?;
        let y = y.reverse();
        expect("other root reversed", vals(&y), vec![3, 2, 1, 20])?;
        expect("first root", vals(&x), vec![11, 2, 3, 4])
    });
    fixed("shared-subtree", || {
        let t = tree_of(&[10, 20, 30, 40, 50]);
        let t1 = t.clone().insert(5);
        let t2 = t.insert(60);
        let t1 = t1.insert(15).insert(25).insert(35);
        expect("updated", keys(&t1), vec![5, 10, 15, 20, 25, 30, 35, 40, 50])?;
        expect("other root", keys(&t2), vec![10, 20, 30, 40, 50, 60])
    });

    // Long structures are freed without running out of stack, whether unique or shared.
    fixed("drop-long-list", || {
        let a = build_from_back(1..=1_000_000i64);
        drop(a);
        let a = build_from_back(1..=1_000_000i64);
        let b = a.clone();
        drop(a);
        expect("kept holder's length", b.iter().count(), 1_000_000)?;
        drop(b);
        Ok(())
    });
    fixed("drop-large-tree", || {
        let t = tree_of(&(0..100_000).map(|i| (i * 7919) % 100_003).collect::<Vec<i64>>());
        let u = t.clone();
        drop(t);
        expect("kept holder's size", u.iter().count(), 100_000)?;
        drop(u);
        Ok(())
    });
}

struct Rng(u64);
impl Rng {
    fn new(seed: u64) -> Rng {
        Rng(seed.wrapping_mul(0x9E37_79B9_7F4A_7C15) | 1)
    }
    fn next(&mut self) -> u64 {
        let mut x = self.0;
        x ^= x << 13;
        x ^= x >> 7;
        x ^= x << 17;
        self.0 = x;
        x
    }
    fn below(&mut self, n: u64) -> u64 {
        self.next() % n
    }
}

fn pick(rng: &mut Rng, live: &[usize]) -> usize {
    live[rng.below(live.len() as u64) as usize]
}

/// Generated sequences over lists: new, hold, drop, add-one, reverse, running totals,
/// push-front (consuming, or keeping the original so two roots share a tail), pop-front.
fn list_sequence(seed: u64) -> Result<(), (usize, String, Vec<String>)> {
    let mut rng = Rng::new(seed);
    let mut slots: Vec<Option<(List, Vec<i64>)>> = Vec::new();
    let mut ops: Vec<String> = Vec::new();
    for step in 0..STEPS {
        let live: Vec<usize> = (0..slots.len()).filter(|&i| slots[i].is_some()).collect();
        let choice = if live.is_empty() { 0 } else if live.len() >= 8 { 2 } else { rng.below(9) };
        let r = catch_unwind(AssertUnwindSafe(|| -> Result<(), String> {
            match choice {
                0 => {
                    let n = rng.below(12) as usize;
                    let v: Vec<i64> = (0..n).map(|_| rng.below(100) as i64).collect();
                    ops.push(format!("new{v:?}"));
                    slots.push(Some((list_of(&v), v)));
                }
                1 => {
                    let i = pick(&mut rng, &live);
                    ops.push(format!("hold({i})"));
                    let (l, m) = slots[i].as_ref().unwrap();
                    let copy = (l.clone(), m.clone());
                    slots.push(Some(copy));
                }
                2 => {
                    let i = pick(&mut rng, &live);
                    ops.push(format!("drop({i})"));
                    slots[i] = None;
                }
                3 | 4 | 5 => {
                    let i = pick(&mut rng, &live);
                    let (l, m) = slots[i].take().unwrap();
                    let (l, m) = match choice {
                        3 => { ops.push(format!("add-one({i})")); (l.add_one(), m.iter().map(|x| x + 1).collect()) }
                        4 => { ops.push(format!("reverse({i})")); (l.reverse(), m.iter().rev().copied().collect()) }
                        _ => { ops.push(format!("running-totals({i})")); (l.running_totals(MODULUS), running(&m)) }
                    };
                    slots[i] = Some((l, m));
                }
                6 | 7 => {
                    let i = pick(&mut rng, &live);
                    let v = rng.below(100) as i64;
                    if choice == 6 {
                        ops.push(format!("push-front({i},{v})"));
                        let (l, mut m) = slots[i].take().unwrap();
                        m.insert(0, v);
                        slots[i] = Some((l.push_front(v), m));
                    } else {
                        ops.push(format!("push-front-keep({i},{v})"));
                        let (l, m) = slots[i].as_ref().unwrap();
                        let mut m2 = m.clone();
                        m2.insert(0, v);
                        let l2 = l.clone().push_front(v);
                        slots.push(Some((l2, m2)));
                    }
                }
                _ => {
                    let i = pick(&mut rng, &live);
                    ops.push(format!("pop-front({i})"));
                    let (l, m) = slots[i].take().unwrap();
                    match (l.pop_front(), m.first()) {
                        (Some((v, rest)), Some(&want)) => {
                            if v != want {
                                return Err(format!("pop-front({i}) gave {v}, expected {want}"));
                            }
                            slots[i] = Some((rest, m[1..].to_vec()));
                        }
                        (None, None) => slots[i] = Some((List::new(), vec![])),
                        (got, want) => return Err(format!("pop-front({i}) gave {:?}, expected {:?}", got.map(|g| g.0), want)),
                    }
                }
            }
            for (j, s) in slots.iter().enumerate() {
                if let Some((l, m)) = s {
                    let got = vals(l);
                    if &got != m || l.first() != m.first().copied() {
                        return Err(format!("slot {j}: expected {m:?}, got {got:?} (first {:?})", l.first()));
                    }
                }
            }
            Ok(())
        }));
        match r {
            Ok(Ok(())) => {}
            Ok(Err(d)) => return Err((step, d, ops)),
            Err(_) => return Err((step, "panicked".into(), ops)),
        }
    }
    Ok(())
}

/// Generated sequences over trees: new, hold, drop, insert (consuming, or keeping the
/// original so two roots share subtrees). Keys 0 to 39, so repeats happen.
fn tree_sequence(seed: u64) -> Result<(), (usize, String, Vec<String>)> {
    let mut rng = Rng::new(seed ^ 0xABCD_EF01);
    let mut slots: Vec<Option<(Tree, BTreeSet<i64>)>> = Vec::new();
    let mut ops: Vec<String> = Vec::new();
    for step in 0..STEPS {
        let live: Vec<usize> = (0..slots.len()).filter(|&i| slots[i].is_some()).collect();
        let choice = if live.is_empty() { 0 } else if live.len() >= 8 { 2 } else { rng.below(6) };
        let r = catch_unwind(AssertUnwindSafe(|| -> Result<(), String> {
            match choice {
                0 => { ops.push("new".into()); slots.push(Some((Tree::new(), BTreeSet::new()))); }
                1 => {
                    let i = pick(&mut rng, &live);
                    ops.push(format!("hold({i})"));
                    let (t, m) = slots[i].as_ref().unwrap();
                    let copy = (t.clone(), m.clone());
                    slots.push(Some(copy));
                }
                2 => { let i = pick(&mut rng, &live); ops.push(format!("drop({i})")); slots[i] = None; }
                3 | 4 => {
                    let i = pick(&mut rng, &live);
                    let k = rng.below(40) as i64;
                    ops.push(format!("insert({i},{k})"));
                    let (t, mut m) = slots[i].take().unwrap();
                    m.insert(k);
                    slots[i] = Some((t.insert(k), m));
                }
                _ => {
                    let i = pick(&mut rng, &live);
                    let k = rng.below(40) as i64;
                    ops.push(format!("insert-keep({i},{k})"));
                    let (t, m) = slots[i].as_ref().unwrap();
                    let mut m2 = m.clone();
                    m2.insert(k);
                    let t2 = t.clone().insert(k);
                    slots.push(Some((t2, m2)));
                }
            }
            for (j, s) in slots.iter().enumerate() {
                if let Some((t, m)) = s {
                    let got = keys(t);
                    let want: Vec<i64> = m.iter().copied().collect();
                    if got != want {
                        return Err(format!("slot {j}: expected {want:?}, got {got:?}"));
                    }
                }
            }
            Ok(())
        }));
        match r {
            Ok(Ok(())) => {}
            Ok(Err(d)) => return Err((step, d, ops)),
            Err(_) => return Err((step, "panicked".into(), ops)),
        }
    }
    Ok(())
}

fn generated(kind: &str, run: fn(u64) -> Result<(), (usize, String, Vec<String>)>) {
    let mut failures = 0u64;
    for n in 0..SEQUENCES {
        let seed = SEED_BASE + n;
        if let Err((step, detail, ops)) = run(seed) {
            failures += 1;
            say(format!("FAILURE {kind} seed {seed} step {step} {detail} ops {}", ops.join(" ")));
        }
    }
    say(format!("GENERATED {kind} sequences {SEQUENCES} failures {failures}"));
}

fn main() {
    // Silence the default panic message; panics are reported as failures above.
    std::panic::set_hook(Box::new(|_| {}));
    fixed_cases();
    generated("lists", list_sequence);
    generated("trees", tree_sequence);
    say("DONE".into());
}
