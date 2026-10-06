# Experiment 6: genuine native loading and retirement

ROB-1327. Authorized 6 October 2026; Robert subsequently waived separate
check authorship. Implementation and verification are by the same Codex agent.
Prior experiments, specifications and locks are unchanged.

## Boundary and question

Can a running Rust FIFO service load separately compiled new machine code,
activate it without reconnecting clients, preserve accepted work under its
original version, and genuinely unload the old library only after all use ends?

Experimental choice: macOS dlopen/dlsym/dlclose, a small C shared library, fixed
primitive C ABI, host-owned queue and state. Reuse experiment 5's TCP commands,
deduplication, mutex/condition-variable worker and accepted-socket fix. No queue
representation migration in this experiment: experiment 5 already tests that
separate concern. Activation is an atomic admission-version switch, not a pause
waiting for old work. No compiler infrastructure or v1 imports.

Compared with an interpreter or subprocess this directly exercises in-process
native lifetime, with no runtime dependency. It does not choose Mo's eventual
backend or prove arbitrary libraries safe. Trusted modules must have no escaped
pointers, background threads, TLS, callbacks retained after return, or persistent
module-owned state. Metadata validation detects interface mismatches, not hostile
code: dlopen may execute constructors before metadata is checked. Paths are
immutable, uniquely versioned local artifacts under test control. Unloading must
be observed rather than inferred from dlclose success.

## Fixed obligations and runnable scenarios

- Start v1 before v2 exists; compile v2 while the same server PID and TCP clients
  remain alive. Host contains neither version's arithmetic. v1 step is x+1;
  v2 step is 3*x+7. Every job calls its pinned library twice: payload 10 yields
  v1 result 12 and v2 result 118; a mixed-version result must fail checks.
- Pin at admission, including queued jobs. One worker preserves FIFO completion.
  IDs/payloads 1..1,000,000, capacity eight, 256 accepted jobs, eight loaded
  modules. Duplicate ID/payload returns original sequence without more work;
  conflicting payload refuses. No acknowledged work disappears or duplicates.
- A synchronous host callback holds the worker inside the module's first call.
  While held, activate v2, admit new work, reject retiring v1, then release.
  Hold the next queued old job as well to test references beyond the active job.
- Loading nonexistent/malformed, wrong-ABI and missing-symbol artifacts refuses
  without changing the active version or accepted work. Same/older version
  refuses. ABI is fixed integer 1; required symbols mo_abi, mo_version, mo_step.
- Explicit retire VERSION refuses active versions and any module with queued or
  executing references. After old jobs finish, retirement calls dlclose once.
  Verify the library's destructor marker AND absence from dyld image inventory
  while service and existing connections remain alive. Old code cannot be
  reacquired for new jobs. Module function pointers are private to an owning
  handle; references never survive that owner.
- Three fresh-process trials, each with held old work, late compilation, refusal
  cases, two old jobs and 80 new jobs from four persistent producer connections.
  Verify actual acknowledgments, full FIFO ledger, both intermediate and final
  results, pinned versions, and post-retirement v2 service. Five-second bounded
  polling and two-second socket timeouts are harness tolerances, not an SLA.
- Actual disposable source controls: bypass retirement reference guard; remove
  dlclose; reacquire active version for a job's second call; lose queued work
  on activation; bypass ABI check. Each must build and fail a relevant observable
  assertion. A crash is reported as such, never silently counted as success.

Protocol: line commands submit ID PAYLOAD, update PATH, retire VERSION,
hold_work, step_work, release_work, snapshot, shutdown. step_work permits one
callback to return while leaving the hold armed for the next job. JSON responses; LISTEN address
announced on startup. Update accepts an absolute path without spaces. Snapshot
contains active version, queued and executing rows, accepted and completed rows,
loaded versions, held state and actual dyld images. Completion rows contain
seq,id,payload,version,first,result. Admission assigns consecutive seq numbers.

Stop after clean builds, three trials, controls and a report with retained raw
traces/source fingerprints, then push a reviewable branch. Fix implementation
bugs with original failure evidence retained. Do not retune checks to outcomes.
No merge, deployment, next experiment, arbitrary native-code preemption, universal
schedule proof, crash recovery, external side-effect guarantee or timing SLA.

Apple documents loader reference counting and cases that prevent unloading:
https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/dlclose.3.html
