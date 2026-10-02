# Check-in 2: evaluator contracts still unfinished

Candidate [38c4b7a](https://github.com/robertguss/mo-v2/commit/38c4b7accc32cea8a3714eeb93c5917b4431ab8c)
was independently checked by the Lead and a
[fresh Tester](https://ampcode.com/threads/T-01a0fb61-cefb-720f-b823-afd990316243).
Findings were recorded before sharing. Both found **0/4 promises proven**,
four original unfinished bodies and no demonstrated blocker. No exhaustive
counterexample search was performed.

Both runs checked 25 effective locks, 57 allowed proof paths only, a clean
75-job reconstructed build with four original warnings, exact accepted types,
kernel rechecking and byte-identical frozen example output. Every accepted
theorem still depends on `sorryAx`. Checks 9–10 remain withheld until proof
completion. These results permit retention as partial work, not acceptance.

`checkin-2-lead/LEAD.md` records the Lead's original findings;
`checkin-2-tester/REPORT.md` is the original independent Tester report.
Selected raw outputs accompany each. Full Tester evidence was exported with
SHA-256 `fa924100440c9fe84efed2d11f5d8e46f2a0d543035124787a352cf6072618c1`,
verified on transfer. Reports, not implementation code, were transferred.
`checkin-2-builder-report.txt` transcribes the final Builder report returned
by `read_thread`; the original remains in the
[Builder thread](https://ampcode.com/threads/T-01a0fa71-4bff-779d-9439-83059a968a65).

Oracle reviewed the complete incremental diff and the independently recorded
results, without rerunning the commands. No P1/P2 issue found. The evaluator
contract now connects its conditions to all four actual public predicates,
but the universal contract is not proven. Most expression cases are compiled;
the complete nonempty-match composition and final induction remain.

Lead/Oracle continued unchanged scope for 07:06–09:06 UTC. Priority is the
nonempty-match case, then one structural induction and four projections.
Respect the evaluator's second cell read after branch cleanup: cleanup can
change its sharing count. Preserve fresh binding meanings and both liveness
directions, protect the body result during branch finishing, and compose
reservation suffixes rather than equality. These are strategy recommendations,
not new criteria or a forecast of completion. Existing hard stops still apply.

Proof checkpoint and evidence are on separate pushed branches, not merged.
No dependent scientific stage, PR or deployment was started. Linear is the live
status record; this file preserves the check-in's evidence and interpretation.
