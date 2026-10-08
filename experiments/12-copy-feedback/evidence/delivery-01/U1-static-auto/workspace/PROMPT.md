# Task U1

Review this operation for avoidable work at its representative size of 100,000
elements. Improve it only if worthwhile; leave already appropriate code alone.
The function must add one to every element.
Return None as the second tuple element.
Support empty and non-profile inputs too. Use the fixed helper::List representation.
The supported test inputs and intermediate arithmetic fit signed 64-bit integers.

Edit task.rs only. Do not change the helper or checking tools. Do not add unsafe
code, dependencies, global state, input-size special cases, I/O, threads/processes,
or code that detects or bypasses measurement. Preserve the function signature.
Explain what you changed, or why no change is appropriate. Feedback, when available,
is a report about the original baseline, not a later candidate.

Use ./check for common example correctness checks. Use ./feedback to request baseline copying feedback, if available.

Baseline copying feedback:
Baseline possible-copy note: add_one can copy list cells when another holder of the input remains live during the operation. This is a static possibility, not a measured copy count. A retained version may be required by the task; preserve every required value. This note describes the original source only.
