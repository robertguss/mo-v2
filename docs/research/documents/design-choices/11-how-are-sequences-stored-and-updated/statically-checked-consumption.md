# Statically checked consumption

The checker, not the runtime, ensures an updated array had only one holder: after an in-place update the old name may not be used again, and the program is refused if it is. No runtime count, so no fallback copy either. Close to D26's in-place demands, applied to arrays.

* Languages: Futhark (uniqueness types for in-place array updates), Clean, Rust's ownership (by hand rather than by demand).
