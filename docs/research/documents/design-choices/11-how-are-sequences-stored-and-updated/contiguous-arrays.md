# Contiguous arrays

Elements side by side in one block. Fast to index and to walk; growing or changing one element means copying the block unless the update can happen in place. What Rust's Vec is.

* Languages: Rust (Vec), Swift (Array), Lean (Array), Koka (vector; its published map allocates a new vector, so in-place behaviour needs checking), Go slices.
