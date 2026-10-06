# Task H1

Review this operation for avoidable work at its representative size of 4
elements. Improve it only if worthwhile; leave already appropriate code alone.
The function must add one to every element.
Return Some(original) with every original element unchanged.
Support empty and non-profile inputs too. Use the fixed helper::List representation.
The supported test inputs and intermediate arithmetic fit signed 64-bit integers.

Edit task.rs only. Do not change the helper or checking tools. Do not add unsafe
code, dependencies, global state, input-size special cases, I/O, threads/processes,
or code that detects or bypasses measurement. Preserve the function signature.
Explain what you changed, or why no change is appropriate. Feedback, when available,
is a report about the original baseline, not a later candidate.

Use ./check for common example correctness checks. Use ./feedback to request baseline copying feedback, if available.

Baseline copying feedback:
Baseline measured profile: 4 input elements with values (i % 17) - 8. The complete operation requested 4 allocations and 128 bytes; this unchanged helper and baseline copied 4 list cells (32 requested bytes per cell). Absolute live requested bytes: 9,071 before, 9,199 after, 9,199 peak. These include driver-owned live buffers, exclude input construction from allocation counts, and are not process RSS. Separate uninstrumented operation time over ten runs: median 812 ns, range 125–1959 ns. A retained version may be required by the task; preserve every required value. This profile describes the original source and stated input, not a later edit or all inputs.
