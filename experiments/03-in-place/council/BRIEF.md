# Review brief: Experiment 3 setup

You are an independent reviewer. Another AI (the lead) designed this experiment,
and you are checking its work before anything runs. Work only in
`experiments/03-in-place` of this repo.

## The one question

**Could this experiment give a misleading answer?** Look for anything in its
setup that could make a claim pass when the idea behind it is actually weak, or
fail when the idea is actually sound.

## What the experiment tests

It tests one idea, in the Koka language. Programs are pure, meaning no value is
ever changed in place. The compiler counts who holds each value and updates it
in place when there is only one holder. A function can also demand in-place
updating, and a checker then proves or rejects that demand. The four claims are
in `ACCEPTANCE.md`:

- **A:** speed within 2× of Rust that uses the same container and the same
  allocator.
- **B:** how fragile the in-place trick is. This one is observational.
- **C:** whether the in-place demand is detected on 12 test functions.
- **D:** whether the demand works on 10 realistic functions (7 are needed to
  pass).

## Read

`PLAN.md`, `ACCEPTANCE.md`, `LOCK.md`, `run.sh`, `acceptance/measure.py`,
everything in `acceptance/claim-c/` and `acceptance/claim-d/`, and
`briefs/builder.md`. The builder hasn't started, so `bench/` doesn't exist yet.

You may run `koka` or `python3` to check a point, but don't change or create any
file except your verdict.

## Things worth checking

This list isn't exhaustive:

- Are the expected benchmark outputs correct?
- Is the comparison with Rust fair? Is there any way the builder, who writes
  both sides, could tilt it?
- Do the claim C tests really test what each one says? Could a test be
  mislabelled as correct or broken?
- Does `measure.py` score each claim the way `ACCEPTANCE.md` says? Look for bugs
  and for loopholes.
- Could the builder game any of the scores without breaking the brief's rules?
- Is there anything the experiment would get wrong because of this machine (an
  Apple M3 Max running macOS)?

## Write

One file, `council/verdict-codex.md`. For each finding, give:

- **Severity:** _misleading_ (could flip or distort a claim's result) or _minor_
  (worth fixing, but can't change a result).
- **Which claim,** or "setup".
- **What's wrong,** in plain English, with the file and line.
- **A concrete fix.**

Include only findings you can back with a specific reason. If you find nothing
that could mislead, say so plainly.
