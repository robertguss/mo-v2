# Confined mutation

A mutable array exists only inside a region that nothing outside can observe; the region hands back an ordinary value at the end. Pure from the outside, so it fits D26. Useful for building a large value quickly.

* Languages: Haskell (ST and runST), Clojure (transients on persistent collections), Koka (local state effects).
