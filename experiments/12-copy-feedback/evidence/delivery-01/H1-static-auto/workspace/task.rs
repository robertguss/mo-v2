use helper::List;

pub fn run(input: List) -> (List, Option<List>) {
    let updated = input.clone().add_one();
    (updated, Some(input))
}
