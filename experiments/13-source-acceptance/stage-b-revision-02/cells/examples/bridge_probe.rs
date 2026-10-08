//! Native observation fixture/stub only. No source parsing or evaluation.
use acceptance_cells::{Cell, Observer, fixture};

fn emit(observer: &Observer, phase: usize) {
    let graph = observer
        .graph()
        .iter()
        .map(|(id, c, ptr)| {
            let tail = c.tail.map(|t| t.to_string()).unwrap_or("null".into());
            format!(
                "[{id},\"{}\",{tail},{},\"{}\",{ptr}]",
                c.item,
                c.holders,
                if c.aside { "aside" } else { "live" }
            )
        })
        .collect::<Vec<_>>()
        .join(",");
    let events = observer
        .events()
        .iter()
        .map(|e| format!("[\"{}\",{},{}]", e.kind, e.lifetime, e.pointer))
        .collect::<Vec<_>>()
        .join(",");
    println!("{{\"phase\":{phase},\"graph\":[{graph}],\"physical\":[{events}]}}");
}

fn main() {
    let bad = std::env::args().any(|a| a == "--corrupt-physical-value");
    let (api, observer) = fixture(vec![(
        41,
        Cell {
            item: if bad { "9" } else { "3" }.into(),
            tail: None,
            holders: 1,
            aside: false,
        },
    )]);
    // Start/name-transfer/finish dumps are supplied by the Python fixture stub.
    // The actual cell allocation survives all three observations, including a
    // zero-work repeated observation; no claimed graph is used here.
    for phase in 0..=3 {
        emit(&observer, phase);
    }
    api.free(41).unwrap();
    emit(&observer, 4);
    // Scripted destroy is repeated without another free.
    emit(&observer, 5);
}
