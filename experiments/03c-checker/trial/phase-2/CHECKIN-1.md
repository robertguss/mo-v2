# Check-in 1: unfinished, continuing

The first two-hour interval produced a retained proof checkpoint, not a proof
of any of the four promises. The Lead and fresh Tester recorded findings
separately before sharing them. Both found the same result: **0/4 proven**,
four original unfinished bodies, and no demonstrated blocker. No promise was
weakened, no prediction changed, and no dependent scientific stage started.

- [Candidate commit](https://github.com/robertguss/mo-v2/commit/8c57ccbd4f41dea91f2cda903d9377362f37270a)
- [Builder thread](https://ampcode.com/threads/T-01a0fa71-4bff-779d-9439-83059a968a65)
- [Tester thread](https://ampcode.com/threads/T-01a0fae6-c94d-727a-bb87-11152865679f)
- Original Builder report: `checkin-1-builder-report.txt`, transcribed from
  the final report returned by `read_thread`; the thread remains the original.
- Independent Lead findings: `CHECKIN-1-LEAD.md`, raw output in `checkin-1-lead/`.
- Original Tester findings: `checkin-1-tester/REPORT.md`, selected raw evidence
  alongside it. Full exported archive is retained in the Tester thread and was
  transferred solely as evidence, not code. Its SHA-256 was verified as
  `733bfc9042d82c407294afc76a297894dabf7912f3908e0abc8479f13c33d0fb`.

Both runs verified all 25 effective locks, allowed paths only, the fresh
baseline-plus-proofs reconstruction, 48-job build with four original unfinished
warnings, exact theorem types, kernel rechecking, and byte-identical frozen
example output. Every accepted theorem still depends on `sorryAx`, so none is
proven. No counterexample was found in these checks; that is not an exhaustive
search. Broken-copy checks 9–10 remain for after completed proof.

Oracle read the complete candidate diff and reviewed these independently
recorded results. It found no P1/P2 issue and no materially misleading claim
in the Lead report. It did not rerun the acceptance commands; its review is
additional, not a third execution. The supporting lemmas address genuine
memory operations but their conditions are not yet established for every run.

Lead/Oracle continued the existing scope for interval 2, 04:49–06:49 UTC.
The recommended priority is one whole-evaluator induction connecting typing,
binding meanings and both directions of liveness, pending-holder order,
reservation-stack suffixes, and recorded observations. In particular, proving
that needed bindings survive does not prove that every dead holding is gone;
and outer reserved cells may be consumed, so they need not stay unchanged.
These are proof-strategy recommendations, not new acceptance criteria.

The next report still counts completed exact promises, not helper lemmas.
Proof and evidence branches are pushed separately; neither checkpoint nor
operational amendments are merged. Linear remains the live status record.
