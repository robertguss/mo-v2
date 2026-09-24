// When the `mimalloc` feature is on, compile the mimalloc source that Koka 3.2.9 ships,
// exactly as Experiment 3's same-container Rust does, so every timed program uses the
// same allocator.
const KOKA_MIMALLOC: &str = "/opt/homebrew/Cellar/koka/3.2.9/share/koka/v3.2.9/kklib/mimalloc";

fn main() {
    println!("cargo:rerun-if-changed=build.rs");
    if std::env::var_os("CARGO_FEATURE_MIMALLOC").is_none() {
        return;
    }
    cc::Build::new()
        .file(format!("{KOKA_MIMALLOC}/src/static.c"))
        .include(format!("{KOKA_MIMALLOC}/include"))
        .define("NDEBUG", None)
        .opt_level(3)
        .warnings(false)
        .compile("mimalloc");
}
