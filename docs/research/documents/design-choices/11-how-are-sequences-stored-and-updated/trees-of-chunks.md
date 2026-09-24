# Trees of chunks

A shallow tree whose leaves are small arrays. Indexing and update cost grow only with the logarithm of the size, and an update shares everything it did not touch, so old versions stay cheap to keep. Persistent vectors and RRB trees are the sequence form; HAMTs are the map form.

* Languages: Clojure (persistent vector), Scala (Vector), Elm and Roc (in parts), the immutable.js and im (Rust) libraries.
