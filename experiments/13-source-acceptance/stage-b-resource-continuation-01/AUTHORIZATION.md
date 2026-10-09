# A separately authorized larger environment, not a changed scientific freeze

Robert instructed: “I think you should create a new thread/orb and make it the
largest size available and then continue in that orb.” The source acceptance
thread created this `a1.3xlarge` orb and handed off the exact acceptance branch at
[`7037f90`](https://github.com/robertguss/mo-v2/commit/7037f90dbac3b9d7cc5e1f41b52942228d07251e).

Source: https://ampcode.com/threads/T-01a11697-f670-71bc-bd5d-f6f57958fa55
Continuation: https://ampcode.com/threads/T-01a120a8-5f89-72d7-a894-b48b82ed155c

The measured workload cgroup limit here is **45,097,156,608 bytes (42 GiB)**,
versus 14,763,950,080 bytes (13.75 GiB) in the second OOM attempt. The filesystem
has 68,297,543,680 total bytes (about 64 GiB); machine-readable pre-run evidence
records actual free disk, available RAM, cgroup hierarchy and CPU information.
No local cgroup limit, swap setting or kernel control is changed. The old
`stage-b-collector-01/FREEZE.md` correctly says no limit was raised for its
earlier run; it remains byte-identical. This document records the subsequent
owner-authorized provisioning change, not a retroactive edit of that run.

The runtime and both release binaries were transferred without rebuilding.
Archive members and destinations were inspected before extraction; no different
installed file was overwritten. All archive and executable SHA256s match the
handoff. The 645,068,800-byte failure tar exceeded the transfer tool's 100-MiB
limit; ten hash-checked byte parts reassembled to the exact original tar.
`tar --compare` passed for both restores. This transport check is not a new
scientific result. Private corpus/evidence was not transferred or rerun.

Run the unchanged pinned CPython 3.14.7 (JIT disabled), approved collector binary
and frozen `stage-b-collector-01/run_resources.py` into the new external
`/home/user/rob1333-stage-b-large-orb-01/million` directory. Non-tail sum comes
first at one million elements and an inclusive 900 seconds. Discard follows
only if sum passes, at one million elements and 600 seconds. All full
observations, every-record checks, source checking, evidence writes, cleanup,
process exit, eight-MiB child stack and four-GiB provisioning floor stay as
frozen. No candidate, decoder, verifier, predicates or evaluator controls change.

Stop on the first material failure, retain it, and do not repair/retry silently.
No separate Python memory sampler will run alongside this attempt. Resource
reports and cgroup/kernel records remain available; this avoids repeating the
old sampler's allocation but does not make the environment observer-free.
No build, packaging or other heavy validation runs concurrently with the timed
workload. Both orbs stay unarchived. PR #9 remains open/draft; moving orbs does
not justify acceptance, merge or deployment.
