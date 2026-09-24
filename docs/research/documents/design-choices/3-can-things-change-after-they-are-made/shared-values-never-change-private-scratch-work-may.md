# Shared values never change, private scratch work may

Anything handed to anyone else is frozen; a function may use private working variables inside. Mutable value semantics: changing your copy never affects anyone else's.

* Languages: Swift value types, Hylo, Koka.
