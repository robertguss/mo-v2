# Experiment 7 staged revision: owner-approved deadline boundary

Robert approved on 6 October 2026: load candidate first, then start the 200ms
preparation deadline. D120, separate staging from native preparation. ROB-1328.
Same-author verification; no independent acceptance claim. Original failed
experiment, spec, checks and evidence at 78b3be7 remain byte-for-byte unchanged.

Reuse the original experiment's trusted synchronous C ABI, host-owned FIFO,
admission-version pinning, timeout authority tokens and real loader lifetime.
Each update starts in `staging`, with requested_us recorded but started_us and
deadline_us null. Load and validate required symbols, ABI and increasing unique
version outside authoritative-state lock. If invalid, refuse without starting a
preparation clock. Once loaded/validated and registered under the state lock,
record started_us and deadline=that Instant+200ms, change status to pending, then
call native preparation outside the lock. Watchdog only expires armed deadlines.
At native return, check token, base version, deadline and readiness before commit.
Loading elapsed time = started_us-requested_us (or finished-requested on rejected
staging). No whole-update 200ms claim or OS-loader bound is made.

`state` reports coherent service/attempt state without waiting for the loader or
listing images; `snapshot` additionally serializes with loader image inventory.
This observation split allows testing service while dlopen is busy. Existing
submit, hold, release, retire and shutdown semantics otherwise unchanged. Only
one authoritative pending/staging attempt at a time; a timed-out native worker
may coexist with the next attempt. Candidate ownership persists through return.

Three fresh builds/processes with five persistent TCP clients; every version
compiled after server start except v1. No automatic retries in acceptance.
Preserve all original 96-job scenarios per trial, adding deterministic slow
staging: v2 constructor sleeps 400ms before preparation, while four extra v1 jobs
must complete with status staging and started/deadline still null. Require
measured staging >=400ms, then held preparation timeout in [200ms,950ms] from
preparation start, despite staging already exceeding 200ms. Exact final count:
100 jobs/trial, 300 total. Continue original newer-v3-before-held-return and
newer-v5-before-800ms-native-sleep-return scenarios, wrong readiness rejection,
retirement/image-removal checks, FIFO/version/result ledger and five source
controls. Add rejected missing-file, ABI and symbol staging cases; they must not
arm preparation or change active version/work. Successful activation strictly
before its preparation deadline; timeout terminal outcomes immutable.

Six actual source controls: original watchdog, stale-publication, premature
unload, wrong readiness and native-under-state-lock defects, plus arming the
clock at request admission (must fail the deterministic slow-staging scenario).
Retain all attempts and fingerprints; no threshold retuning. Stop after report
and branch push, or a real specification blocker. No merge/deployment/next phase.

The 400ms constructor is a bounded test fault, not proof that constructors can be
preempted or bounded in general. An arbitrary stuck loader still prevents other
loads/image snapshots, but ordinary state/work must not wait on its mutex.
Forever-hung native preparation loses authority but retains code/thread resources.
No crash recovery, external-effect guarantee, arbitrary library safety, queue
representation migration, whole-process availability SLA or universal proof.
