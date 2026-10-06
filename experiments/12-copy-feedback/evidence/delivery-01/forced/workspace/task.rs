use helper::List;

pub fn run(input: List) -> (List, Option<List>) {
    let previous = input.clone();
    let updated = input.add_one();
    std::hint::black_box(&previous);
    drop(previous);
    (updated, None)
}
