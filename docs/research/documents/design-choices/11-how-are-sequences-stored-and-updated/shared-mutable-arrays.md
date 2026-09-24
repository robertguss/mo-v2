# Shared mutable arrays

**Label:** Conflicts with D26

An ordinary mutable array that any holder can change and every other holder sees changed, whether or not it sits behind an effect or capability. Fastest and simplest, but one holder observing another's update is exactly what D26 rules out.

* Languages: OCaml, Java, Go, Python, and C.
