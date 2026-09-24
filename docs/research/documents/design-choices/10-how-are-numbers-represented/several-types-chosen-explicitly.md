# Several types, chosen explicitly

More than one number type, and the programmer picks: fixed-size where speed matters, unlimited where correctness on large values matters. Costs a decision at each use, and mixing the types needs conversion rules that fit D25.

* Languages: Swift and Rust (fixed sizes plus library big integers), OCaml, Haskell (Int and Integer).
