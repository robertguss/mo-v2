# Koka 3.2.9 slice-1 comparison

Executed only after the prediction checkpoint at 2026-10-09T19:21:39Z.
All five prediction-file hashes still match. No expectation was edited after
observing Koka. No Mo counted/plain evaluator or historical corpus was executed.

Final selection: `koka-r2/` for every category except S1A07/S1R04, which use
`koka-r3/`. All 19 selected compilations and executables exit 0. All 53 concrete
answer lines (including empty/singleton controls) equal the independently
recorded answers. This is not a comparison of physical memory-event traces:
Koka's static pairing/reuse policy is not Mo's dynamic newest-eligible rule.

## Exact evidence and reproduction

Each directory contains the exact `.kk` source, compiler stdout/stderr, and
where compilation succeeded, executable stdout/stderr. `results.json` retains
the exact commands, UTC execution times, exit statuses, case IDs and answer
comparison result. The compiler version output is in each `version.txt`.

Commands executed from this acceptance directory:

```
python3 -B compare_koka.py
python3 -B compare_koka.py --output koka-r2
python3 -B compare_koka.py --output koka-r3 --only S1A07 S1R04 --div merge build
```

The first invocation used the original translator snapshot saved as
`koka/generator.py`; the second used `koka-r2/generator.py`; the current
`compare_koka.py` includes the third invocation's effect-annotation option.
To reproduce final evidence without overwriting it:

```
python3 -B compare_koka.py --output koka-reproduction --div merge build
```

The translator directly prints the checkpoint's typed trees into Koka syntax,
prefixing function names with `mo-`. It writes a separate file per category,
using that main's exact transitive function closure and demand annotations.
Ordinary helpers remain ordinary. Initial lists are constructed outside the
demanded calls. It performs no source algorithm rewrite, reference evaluation,
manual copy insertion, unsafe cast, termination bypass or result substitution.
Koka executables are separately run; output values are parsed and compared with
the prior JSON answers. Build directories/executables are temporary and removed;
they are not evidence files or delivery artifacts. Source and raw output remain.

## Per-category verdicts and classified differences

"No demand warning" means no `warning: fbip` diagnostic, not an absence of all
compiler diagnostics. Koka warns rather than refusing compilation; the future
Mo checker must actually refuse each R example.

| Category | Koka demand result | Classification and relation to Mo prediction |
|---|---|---|
| S1A01 increment | No demand warning | Agreement; all 3 answers match. |
| S1A02 reverse | No demand warning | Agreement; wrapper and revAcc both annotated; 3 answers. |
| S1A03 running totals | No demand warning | Agreement; wrapper and totalsAcc both annotated; 3 answers. |
| S1A04 append | No demand warning | Agreement; 3 answers. |
| S1A05 swap | No demand warning | Agreement; 3 answers including odd-length list. |
| S1A06 rotate | No demand warning | Agreement; live singleton construction before helper retained; 3 answers. |
| S1A07 merge | No demand warning after `div` annotation | **Termination/representation:** total annotation failed effect checking. Only signature gained `div`; body unchanged. 3 answers match. Mo allows unrestricted recursion; this is not a memory refusal or evidence of divergence. |
| S1A08 insertion sort | No demand warning | Agreement; singleton reconstruction and insertCell retained; 3 answers. Unused `nt` pattern warning is not a demand warning. |
| S1A09 total | No demand warning | Agreement; 3 scalar answers. Koka is permitted to free under relaxed demand. |
| S1A10 keep first | No demand warning | Agreement; 3 answers. Unused `t` pattern warning is representation/style, not a demand failure. |
| S1A11 remove first match | No demand warning | Agreement; 5 answers, including both singleton match branches. |
| S1A12 keep positives | No demand warning | Agreement; 3 answers. |
| S1R01 duplicate | `function allocates unlimited but was declared as allocating nothing` | **Memory:** agrees with Mo's one new cell per input element; 3 answers match. "Unlimited" is Koka's static classification, not measured finite-run count. |
| S1R02 prepend | `function allocates at most 1 but was declared as allocating nothing` | **Memory:** agrees with Mo's one Create; 2 answers. |
| S1R03 insert new | Same `at most 1` warning | **Memory:** agrees with one Create; 2 answers. |
| S1R04 build | `function allocates unlimited but was declared as allocating nothing`, after `div` annotation | **Termination + memory:** original total annotation failed effect checking; `div` exposes the memory warning. Four answers match. No algorithm or Mo verdict change. |
| S1R05 same list twice | `variable xs is used multiple times (causing sharing and preventing reuse)` | **Memory:** agrees with the actual copying witness; 2 answers match. Does not imply read-only C5 allocates. |
| S1R06 ordinary allocating helper | `calling a non-fip function: mo-one` | **Library/annotation boundary:** Koka's reason is missing helper demand annotation, not a measured Create. Mo's separate source derivation establishes one Create. One answer matches. |
| S1O01 ordinary arithmetic helper | `calling a non-fip function: mo-arithmetic` | **Library/annotation usefulness limit:** the Mo derivation has zero list-cell operations. Koka conservatively warns even though answer -6 matches. No mandatory Mo verdict exists for this category. |

Diagnostic excerpts above are exact text after the function prefix; full locations
and all messages are preserved in the `.compile.stdout` files. C compiler
stderr on first runtime-library compilation in r2/r3 also includes a GCC
`-Wstringop-overflow` warning from Koka's bundled mimalloc. It is retained,
classified as a library/compiler warning, not suppressed and not counted as an
example `fbip` refusal. Executables still compiled and returned the stated
answers; no memory-safety claim about that native library follows.

## Failed attempts remain evidence, not verdicts

`koka/`: all 19 attempts failed at a generated nested bare block in main
(`unexpected "{"`). This was an acceptance harness syntax bug, classified
**representation**, before any demand check. The correction made each example
a named ordinary top-level wrapper and called those wrappers from main. No
tested function body changed. All initial sources, compiler output, generator
and command results remain. These 19 failures are NOT 19 demand refusals.

`koka-r2/S1A07` and `S1R04`: `effects do not match`, total vs `<div|_e>`.
The r3 follow-up adds the honest possible-divergence effect to those two Koka
signatures. It does not claim the finite witnesses diverge, assert termination,
use an unsafe `undiv` function, or change the Mo programs. The separately
retained successful comparison completes their memory-demand observation.

No memory-verdict disagreement with a mandated Mo category was found in this
comparison. This supports, but does not establish, the correctness of the Mo
predictions, universal guarantees, dynamic event timing, or proposed checker.
