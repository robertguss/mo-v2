# Experiment 8: real native code and queue-state migration together

Authorized by Robert's “sounds good. do it”, 6 October 2026 (D122, combined
native/state experiment). Same-author verification. Prior experiments immutable.
Reuse experiment 7's staged boundary: dlopen/validation unbounded and outside
state lock; 200ms deadline starts when loaded candidate begins migration.
Timeout observation tolerance remains 750ms beyond deadline, not a production SLA.

## State and ownership

Use a fixed C ABI 3, trusted synchronous modules, opaque queue handles. Queue
storage and push/pop/export/free functions live in the native module. V1 uses
an eight-row contiguous array; v2 and subsequent candidates use allocated linked
nodes. Row = four u64 values: sequence, ID, payload, admission code version.
The host has no compiled-in alternate queue storage. A NativeQueue owns a module
reference until native queue_free returns. Native live-allocation accounting must
be zero on module unload (destructor writes version:live_queue_count).

Rust keeps the accepted/completed ledger and code ownership for each queued job.
This is an ownership map, not a second queue/payload store. Pop removes the matching
owner by sequence; the in-flight job pins that module across two native calls.
Migrated queued jobs retain their admission version. New admissions after commit
pin new code. V1 step x+1, later step 3*x+7, so payload 10 finishes as 12 or 118.
Capacity eight queued+flight, 256 accepted, 32 attempts, eight loaded modules.

## Protocol and migration

Keep experiment 7 commands plus snapshot/state schema and native layout reporting.
`update PATH normal|hold` stages first. Once loaded, snapshot actual queued rows,
freeze admissions/dequeues using attempt ID, arm deadline, and call candidate
mo_migrate outside state lock with a private copied row buffer. In-flight old work
may finish during this pause. Candidate migration builds a real new representation.
Retain the old live queue unchanged until validation succeeds. Validate candidate
export equals original rows in full, original authoritative queue still equals
source, candidate layout supported, token/base/freeze ownership and deadline valid.
Commit candidate queue and active version together under one lock. Dispose old
queue outside that lock using its own pinned old module.

Native callback hold and 800ms native sleep test stalled migration. Independent
watchdog makes timeout terminal, clears only that attempt's freeze, and resumes
old queue without waiting for native return. Late return must not change active
code, live queue, newer attempt/freeze or terminal outcome. It frees only its own
candidate, then closes its module after all references end. No native preemption.
Duplicate/conflicting submissions retain original handling even during a freeze;
new submissions return busy without acknowledging until admission resumes.

## Required scenarios: three fresh builds/processes, five persistent clients

- Start v1, hold its first executing job, queue more old jobs. Compile v2 afterward.
  Normal migration must change actual array storage to linked storage with nonempty
  rows, activate while the old job remains in native execution, and keep all old
  queued job code versions pinned. Admit a new v2 job; verify retirement of v1
  blocked, then release old work and validate all FIFO/two-step results. Retire v1
  only after its queue destructor and job references finish; image absent and
  native live-state count zero at unload.
- Keep a held v2 job and a nonempty queue. Corrupt candidate v3 modifies a real
  payload during migration. It must be rejected, leaving rows/version/owners usable.
  Test empty-queue corruption as well after work drains.
- Hold a v4 migration over nonempty rows. While frozen, duplicate stays duplicate
  and new work is busy. After 300ms client silence require autonomous timeout
  [200ms,950ms], unchanged old state and library still mapped. Admit old-version
  work after refusal. Before releasing v4, activate v5 on this nonempty queue;
  release v4 and require late discard, unchanged newer state and real disposal.
- Repeat with v6's 800ms native sleep over nonempty rows and normal v7 activation
  before native return. Then release job hold and compare exact acknowledged and
  completed ledger; retire old code. Submit 80 jobs from four concurrent persistent
  producers under v7. Exactly-once FIFO and admission code behavior for every job.
- Reject incompatible ABI/missing-symbol staging without arming a clock. Verify
  snapshots of actual native rows and layout, plus OS image inventory and native
  state destruction before module unload. All new artifacts compiled after startup.

Six actual source controls must compile and fail the relevant behavior: accept
corrupt candidate, publish stale migration, fail to resume old queue on timeout,
force premature native-module unload, rebind queued jobs to new code, and leak
native queue state at disposal. Native storage code is inspected/compiled with
warnings as errors; controls are real source changes in disposable copies.
Retain all traces, source hashes, failures and repaired attempts, no check retuning.
Stop after tests, report and branch push; no merge/deployment or next milestone.

## Limits

Trusted native ABI only; no escaping pointers, retained callbacks, TLS, background
native threads, malicious code, crash recovery or external effects. Snapshot export
and push/pop/free are bounded small trusted operations. Stuck constructors can
block other loader work; forever-stuck migration retains its thread and module.
No arbitrary code preemption, full schedule proof, production SLA, transactional
external state or permanent choice of Mo representation/ABI/backend.
