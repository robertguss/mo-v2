# Experiment 7: native preparation deadlines and retained lifetime

ROB-1328. Robert approved “merge it and continue” after the recommendation to
combine actual code loading with independent deadlines and late-result fencing.
Same-author verification continues; no independent acceptance claim. Prior
experiments and locks remain unchanged. Stop after verification, controls, report
and branch push; no automatic merge, deployment or next experiment.

## Boundary

Extend experiment 6's Rust host and C shared-library ABI, preserving FIFO jobs,
admission-version pinning, duplicate/conflict handling and persistent TCP clients.
Preparation is a native synchronous function returning a fixed readiness value
42. It cannot mutate authoritative host state. The host queue representation does
not migrate in this experiment. This isolates stalled native preparation and
lifetime before combining representation changes. No new dependencies or Mo v1.

ABI 2 additionally requires mo_prepare(callback,context). Versions 1,3,5 return
x+1, 3*x+7, 3*x+7 respectively from each mo_step; jobs take two steps. Candidate
v2 is held in a native callback until released. Candidate v4 sleeps natively for
800ms after signaling entry, without callbacks during that sleep. Candidate v6
returns wrong readiness. Artifacts are compiled separately after host startup.
Trusted constructors/destructors are short. No arbitrary native-code preemption,
malicious library safety, resource reclamation for permanently hung code, or
bounded dlopen/dlclose guarantee. The bounded claim applies to native preparation
outside loader critical sections, not arbitrary loader constructors.

## Update protocol

`update PATH normal|hold` starts an asynchronous attempt; response started with
monotonic attempt ID (max 32). Only one pending authority token. Loader and native
preparation run outside state lock. Existing jobs/admission continue. Every
attempt expires 200ms after command admission. Independent watchdog polls at
1ms; refusal must be observable no later than 950ms from start (200ms plus prior
experiment's 750ms host tolerance). Success must commit strictly before 200ms.
Refusal does not wait for preparation to return. No result after deadline may
activate even if watchdog has not yet run.

Before native preparation, reject ABI/symbol/version conflicts. Pending candidate
ownership is kept in the module registry and by its updater thread. `retire V`
refuses while active or referenced by jobs/native preparation. `release ID`
releases a held preparation, even after timeout. It does not activate anything.
At return, verify token, base active version, deadline and readiness before
activation. A stale return may only mark itself returned/discarded and dispose of
its own candidate. It cannot change newer work, active version, pending token or
terminal outcome. Drop candidate owner outside state lock. Loader/image inventory
operations share a separate mutex because dyld enumeration is not thread-safe
against concurrent loading. No claim about stuck loader operations.

Snapshot adds pending ID, attempt rows (ID, base, status, started/deadline/finished
microseconds, entered, returned, discarded, released) and monotonic now_us.
Terminal outcomes immutable. Existing hold_work/step_work/release_work and job
commands remain. Shutdown refuses while work or updater threads remain active.
Finished updater threads are joined on shutdown. Eight loaded modules/256 jobs.

## Required observations, three fresh-build trials

1. Start v1 and five persistent clients. Compile new artifacts afterward. Start
   held v2 preparation and observe native entry plus real loaded image. Submit
   and finish old jobs while preparation is held. Stop polling for 300ms, then
   require timeout with entered=true/returned=false, without a release. Verify
   timeout timestamp budget and that v2 is still mapped and retirement blocked.
2. Before releasing v2, activate v3 within its own deadline and complete new jobs.
   Then release v2. Its late readiness must be discarded, active v3 and completed
   work unchanged, v2 destructor observed and image absent only after return.
3. Run v4's native 800ms blocking call, with service work during it. Require
   autonomous 200ms timeout and v5 activation before v4 returns. Late v4 return
   cannot roll back v5. Observe actual eventual image removal and destructor.
4. Refuse readiness-corrupt v6; keep v5 authoritative. Old v1/v3 retire only after
   all references finish. All acknowledged payloads/FIFO/results must match their
   admission versions. Four clients each submit 20 further jobs under v5.
5. Retain raw traces, timings, source/tool fingerprints and all failures. Five
   actual host source controls must compile and fail observably: disabled watchdog,
   stale candidate publication, premature candidate unload, wrong readiness
   accepted, and preparation executed while holding the service mutex.

Polling and socket limits bound the harness; observed latencies are measurements,
not a production SLA. This is not exhaustive Rust schedule or native-code proof.
