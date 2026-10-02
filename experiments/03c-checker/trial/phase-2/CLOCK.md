# Phase-2 proof clock

Lead-owned evidence, not a Builder file or a substitute for Linear status.
Times below are UTC. The Lead in the [owning thread](https://ampcode.com/threads/T-01a0f9e2-cd4f-7408-a467-ecdb636cdeb7)
keeps this clock. Restarts do not reset an interval.

## Before interval 1

Setup, coordination and waiting are not proof work. Linear's rate limit delayed
dispatch until 2026-10-02T02:11:14Z. The original Grok47 readiness thread
verified locks but then repeatedly errored; no proof interval, edits or pushes
occurred. Its ownership was revoked. Lead and Oracle selected a high-mode
replacement under Robert's AFK delegation, preserving scientific criteria.

The [replacement Builder](https://ampcode.com/threads/T-01a0fa71-4bff-779d-9439-83059a968a65)
reported readiness by 2026-10-02T02:30:48Z: 25/25 locks match, pinned Lean
4.34.0 build succeeds with four expected unfinished-proof warnings, and each
accepted theorem depends on `sorryAx`. No promise is proven at this point.

## Interval 1

- Authorized start: 2026-10-02T02:35:00Z.
- Deadline: 2026-10-02T04:35:00Z (two elapsed hours).
- Builder branch: `rob-1136-trial-proofs-high`.
- Starting plan: [ad9302c](https://github.com/robertguss/mo-v2/commit/ad9302cd4aacaf08ca0d82a01c3aaadca92c9201).
- Acceptance baseline: [787e042](https://github.com/robertguss/mo-v2/commit/787e0427244837fd0f44b76c4a648d07938c3bcc).
- Builder reports stopping at 04:35 UTC, two elapsed authorized hours.
  Final report was available by 04:35:38 UTC; no active-CPU time measured.
- Checkpoint: [8c57ccb](https://github.com/robertguss/mo-v2/commit/8c57ccbd4f41dea91f2cda903d9377362f37270a).
- Lead and fresh Tester recorded separate partial checks before sharing. Both
  found 0/4 promises proven, four unfinished bodies, no demonstrated blocker.
  Oracle found no blocking issue and recommended continued evaluator proof.
- Waiting before start: setup/coordination, not proof time; no earlier interval.
- At stop: retain the original report and separately mark Lead-checked claims.
  Continuation is automatic through the Lead unless a hard stop applies.

## Interval 2

- Authorized start: 2026-10-02T04:49:00Z.
- Deadline: 2026-10-02T06:49:00Z.
- Same Builder, branch, baseline, proof-only ownership and hard stops.
- Expected starting tip: the interval-1 checkpoint above.
- Gap between authorized intervals: 14 minutes for reporting, independent
  verification and Oracle review, not proof work.
- Builder reports stopping at 06:49 UTC; final report available by 06:49:47.
  Two elapsed authorized hours; 0/4 proven, no demonstrated blocker.
- Checkpoint: [38c4b7a](https://github.com/robertguss/mo-v2/commit/38c4b7accc32cea8a3714eeb93c5917b4431ab8c).
- Independent Lead/Tester partial checks agreed; Oracle found no P1/P2.

## Interval 3

- Authorized start: 2026-10-02T07:06:00Z.
- Deadline: 2026-10-02T09:06:00Z.
- Same Builder, branch, amended baseline and safeguards.
- Expected starting tip: the interval-2 checkpoint above.
- Gap between authorized intervals: 17 minutes for reporting and review.
- Priority: complete nonempty-match composition, then structural induction.
  Actual stop and results pending original report.

An interval measures elapsed authorized work, not measured active CPU or model
time. Reports must distinguish waiting between intervals from that duration.
