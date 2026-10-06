use helper::List;

pub fn run(input: List) -> (List, Option<List>) {
    let updated = input.clone().reverse();
    (updated, Some(input))
}
