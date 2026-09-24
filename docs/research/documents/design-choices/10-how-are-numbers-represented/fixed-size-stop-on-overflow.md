# Fixed size, stop on overflow

Numbers have a fixed size. Passing the ceiling is a bug, so under D29 the part that hit it stops. Fast, and the mistake surfaces where it happens. Matches v1's crash on overflow (parking lot, not decided).

* Languages: Swift, Ada, Rust in debug builds.
