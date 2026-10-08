use helper::List;
pub fn run(input: List) -> (List, Option<List>) {
    // Broken repair: copying happens before a participant-chosen inner interval.
    let updated = input.clone().add_one();
    let inner_start = std::time::Instant::now();
    std::hint::black_box(inner_start);
    drop(input);
    (updated, None)
}
