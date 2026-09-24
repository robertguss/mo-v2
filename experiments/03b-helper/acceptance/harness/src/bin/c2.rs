//! Claim C2, written by the lead: a value with one holder is updated without copying,
//! a shared value copies only what it must, and memory is freed when the last holder
//! lets go. Counts allocation events during each operation, after the input is built,
//! and checks the values afterwards (so a helper that does nothing cannot pass).
//! Also runs claim B's copying gate at full size. Output, one line per check:
//!   CHECK <name> <measure> <n> rule <rule> ok|FAIL [values-wrong]
//!   COPYPATH <name> <measure> <n> rule <rule> ok|FAIL [values-wrong]   (claim B's gate, not C2)
//!   DONE
//! <measure> is `allocations` (allocation events) or `live-change` (blocks allocated minus
//! blocks freed).
use harness::counting::{events, live};
use harness::{build_from_back, List, Tree, MODULUS};
use std::io::Write;

fn say(line: String) {
    println!("{line}");
    std::io::stdout().flush().ok();
}

enum Rule {
    Exactly(i64),
    AtLeast(i64),
    AtMost(i64),
}

fn report(tag: &str, name: &str, measure: &str, n: i64, rule: Rule, values_ok: bool) {
    let (text, ok) = match rule {
        Rule::Exactly(r) => (format!("exactly-{r}"), n == r),
        Rule::AtLeast(r) => (format!("at-least-{r}"), n >= r),
        Rule::AtMost(r) => (format!("at-most-{r}"), n <= r),
    };
    let verdict = if !values_ok { "FAIL values-wrong" } else if ok { "ok" } else { "FAIL" };
    say(format!("{tag} {name} {measure} {n} rule {text} {verdict}"));
}

/// Allocation events while running `f`.
fn allocations<T>(f: impl FnOnce() -> T) -> (i64, T) {
    let before = events();
    let out = f();
    ((events() - before) as i64, out)
}

const N: i64 = 10_000;
/// A red-black tree of 10,000 keys is at most 2 * log2(10,001) < 27 levels deep, so an
/// insertion that copies only its path allocates at most 27 copied nodes plus 1 new node.
const SHARED_TREE_INSERT_MAX: i64 = 28;

fn tree_of(keys: impl Iterator<Item = i64>) -> Tree {
    let mut t = Tree::new();
    for k in keys {
        t = t.insert(k);
    }
    t
}

fn main() {
    // Unique list updates: no allocation at all.
    let l: List = build_from_back(1..=N);
    let (used, l) = allocations(|| l.add_one());
    report("CHECK", "unique-add-one", "allocations", used, Rule::Exactly(0), l.iter().eq(2..=N + 1));
    let (used, l) = allocations(|| l.reverse());
    report("CHECK", "unique-reverse", "allocations", used, Rule::Exactly(0), l.iter().eq((2..=N + 1).rev()));
    drop(l);

    let l: List = build_from_back((1..=N).map(|i| (i * 37) % 1000));
    let want: Vec<i64> = {
        let mut t = 0;
        (1..=N).map(|i| { t = (t + (i * 37) % 1000) % MODULUS; t }).collect()
    };
    let (used, l) = allocations(|| l.running_totals(MODULUS));
    report("CHECK", "unique-running-totals", "allocations", used, Rule::Exactly(0), l.iter().eq(want.iter().copied()));

    // Adding and removing a holder allocates nothing, for lists and for trees.
    let (used, _) = allocations(|| drop(l.clone()));
    report("CHECK", "hold-and-release-list", "allocations", used, Rule::Exactly(0), l.iter().eq(want.iter().copied()));

    // Taking the front off a unique list allocates nothing.
    let (used, popped) = allocations(|| l.pop_front());
    let ok = matches!(&popped, Some((v, rest)) if *v == want[0] && rest.iter().eq(want[1..].iter().copied()));
    report("CHECK", "unique-pop-front", "allocations", used, Rule::Exactly(0), ok);
    drop(popped);

    // A shared list: pushing onto one holder's front allocates one cell and shares the rest.
    let a: List = build_from_back(1..=N);
    let b = a.clone();
    let (used, b) = allocations(|| b.push_front(0));
    report("CHECK", "shared-list-push-front", "allocations", used, Rule::Exactly(1),
           a.iter().eq(1..=N) && b.iter().eq(0..=N));
    drop(b);

    // Dropping the other holder restores the chance to update in place.
    let (used, a) = allocations(|| a.add_one());
    report("CHECK", "reuse-restored-list", "allocations", used, Rule::Exactly(0), a.iter().eq(2..=N + 1));
    drop(a);

    let t = tree_of((0..1000).map(|i| (i * 7919) % 1009));
    let (used, _) = allocations(|| drop(t.clone()));
    report("CHECK", "hold-and-release-tree", "allocations", used, Rule::Exactly(0), t.iter().count() == 1000);
    let (used, t) = allocations(|| t.insert(5000));
    report("CHECK", "reuse-restored-tree", "allocations", used, Rule::Exactly(1), t.iter().count() == 1001);
    drop(t);

    // Unique tree: each new key allocates exactly one node; existing keys allocate nothing.
    let base: Vec<i64> = (0..N).map(|i| (i * 7919) % 10_007).collect();
    let mut t = tree_of(base.iter().copied());
    let new_keys: Vec<i64> = (0..1000).map(|i| 30_000 + (i * 37) % 1000).collect();
    let mut want: Vec<i64> = base.iter().copied().chain(new_keys.iter().copied()).collect();
    want.sort();
    let (used, t2) = allocations(|| {
        for &k in &new_keys {
            t = t.insert(k);
        }
        t
    });
    report("CHECK", "unique-tree-insert-new", "allocations", used, Rule::Exactly(1000), t2.iter().eq(want.iter().copied()));
    let mut t = t2;
    let (used, t2) = allocations(|| {
        for &k in &new_keys {
            t = t.insert(k);
        }
        t
    });
    report("CHECK", "unique-tree-insert-existing", "allocations", used, Rule::Exactly(0), t2.iter().eq(want.iter().copied()));

    // A shared tree: inserting into one holder copies only the path, and the rest stays shared.
    let u = t2.clone();
    let (used, u) = allocations(|| u.insert(50_000));
    let mut want_u = want.clone();
    want_u.push(50_000);
    report("CHECK", "shared-tree-insert", "allocations", used, Rule::AtMost(SHARED_TREE_INSERT_MAX),
           t2.iter().eq(want.iter().copied()) && u.iter().eq(want_u.iter().copied()));
    drop(u);
    drop(t2);

    // Freeing: a value stays while any holder keeps it, and everything is freed with the last one.
    let before = live();
    let a: List = build_from_back(1..=1_000_000i64);
    let b = a.clone();
    let built = live();
    drop(a);
    report("CHECK", "list-kept-while-held", "live-change", live() - built, Rule::Exactly(0), b.iter().count() == 1_000_000);
    drop(b);
    report("CHECK", "list-freed", "live-change", live() - before, Rule::Exactly(0), true);

    let before = live();
    let t = tree_of((0..100_000).map(|i| (i * 7919) % 100_003));
    let u = t.clone();
    let built = live();
    drop(t);
    report("CHECK", "tree-kept-while-held", "live-change", live() - built, Rule::Exactly(0), u.iter().count() == 100_000);
    drop(u);
    report("CHECK", "tree-freed", "live-change", live() - before, Rule::Exactly(0), true);

    // Claim B's gate, at the timed size: benchmark 1 with the previous version kept each
    // round. Each round a full new copy must exist alongside the kept one, and once the
    // kept one is released nothing may pile up.
    let mut l: List = build_from_back(1..=1_000_000i64);
    let (mut min_growth, mut max_left) = (i64::MAX, 0i64);
    let mut differ = 0;
    for _ in 0..100 {
        let start = live();
        let prev = l.clone();
        l = l.add_one();
        min_growth = min_growth.min(live() - start);
        differ += l.first().unwrap_or(0) - prev.first().unwrap_or(0);
        drop(prev);
        max_left = max_left.max((live() - start).abs());
    }
    let values_ok = differ == 100 && l.iter().eq(101..=1_000_100);
    report("COPYPATH", "share-new-copy-each-round", "live-change", min_growth, Rule::AtLeast(1_000_000), values_ok);
    report("COPYPATH", "share-nothing-piles-up", "live-change", max_left, Rule::Exactly(0), values_ok);
    say("DONE".into());
}
