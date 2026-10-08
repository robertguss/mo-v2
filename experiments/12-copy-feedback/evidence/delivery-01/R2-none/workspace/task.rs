use helper::List;

pub fn run(input: List) -> (List, Option<List>) {
    let updated = input.clone().running_totals(1_000_003);
    (updated, Some(input))
}
