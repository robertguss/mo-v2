fn main() {
    if let Err(error) = mo_acceptance_driver::serve::<mo_stage_a::StageA>() {
        eprintln!("{error}");
        std::process::exit(1);
    }
}
