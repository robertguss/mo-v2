# Rules, Waivers, and Approval

Strict by default: Mo's rules apply everywhere unless a waiver is declared. Flexibility exists but is never the default.

Waiver: A declared, justified departure from one of Mo's default rules (for example, allowing recursion). Agents may propose waivers; only humans grant them.

Exception: Not a Mo term. Mo has no thrown exceptions, and a departure from a rule is a waiver. Named this way because agents trained on other languages would misread "exception."

Guarantee level: How strongly a property is checked. Three levels: proven, bounded, trusted. A waiver moves code down a level instead of removing the guarantee.

Proven: The compiler proves the property statically, before the program runs. The default.

Bounded: The compiler can't prove the property, so the author declares a limit that is checked at runtime (for example, a maximum recursion depth).

Trusted: No check at all, only a written justification. Rare and conspicuous.

Approval: A human's sign-off on a waiver.

Pinned approval: An approval tied to a hash of the code it covers. If the code changes, the approval becomes invalid and returns to a human.

Waiver list: The compiler-generated list of every waiver in a project: the rule waived, where, and why. Part of what humans review.

Approval fatigue: When approval requests are so frequent that humans stop reading them. Mo's defaults must be good enough that waivers stay rare.
