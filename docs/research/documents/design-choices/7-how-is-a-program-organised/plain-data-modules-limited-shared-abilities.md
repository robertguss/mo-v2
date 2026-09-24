# Plain data, modules, limited shared abilities

**Label:** Chosen (D31)

Robert's choice (D31). Records and choice types with every-case-covered checking; functions in modules; no classes, objects or inheritance; a small, deliberately limited system of shared abilities (how limited is a later question). Robert: he hates OOP and inheritance and much prefers composability.

Why:
* Choice types are the best tool for if-it-compiles-it-runs confidence.
* Inheritance adds tangled relationships agents and checkers handle badly.
* Limited abilities avoid Elm's duplication without Haskell's complexity.
* Describe-the-result is not ruled out for the spec language.

* Similar languages: Roc (abilities), Go (interfaces).
