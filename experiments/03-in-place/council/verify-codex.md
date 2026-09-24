# Independent verification of 23 September 2026 work

Reviewed checkout: `629efc7` (initial worktree clean). I read `CLAUDE.md` first. I checked sources, Git history, hashes, raw data, generated C, and fresh executions; the lead's summaries were not treated as proof. Paths below are relative to the repository root.

**Verdict:** the recorded A, C and relaxed-D passes reproduce. B is observational, not a pass. The research text export is complete. There are reporting and documentation errors, a live strict-demand scoring bug, and an allocator configuration difference that the earlier review's fix did not resolve. I found no changed locked file and no deliberately slow Rust baseline. I cannot establish which agent performed every historical write from this repository's aggregate commits.

## Fresh runs and numerical audit

With Robert's explicit permission, I copied Experiment 3 into a temporary directory and ran the unmodified runner there:

```sh
cd /var/folders/f8/ft7ygqg92pj8qh0rwplbw2x80000gn/T/mo-v2-verify-vygbgc6d/03-in-place
./run.sh --seed 251389865
```

Exit status was 0. The machine/tool versions match the recorded summary: Apple M3 Max, macOS 26.6.2, Koka 3.2.9, Rust 1.98.1. There were no build problems. All 320 timed outputs were correct.

| Claim A benchmark | Recorded Koka / Rust medians (seconds) | Recorded ratio | Fresh Koka / Rust medians (seconds) | Fresh ratio |
|---|---|---|---|---|
| b1 | 0.137431500 / 0.163410625 | 0.841 | 0.138311584 / 0.163820209 | 0.844 |
| b2 | 0.217040771 / 0.262494958 | 0.827 | 0.219574916 / 0.267598229 | 0.821 |
| b3 | 0.138198479 / 0.130771750 | 1.057 | 0.138398729 / 0.131740062 | 1.051 |
| b4 | 0.554521917 / 0.304387333 | 1.822 | 0.567933001 / 0.307179688 | 1.849 |

The scored ratios changed by about 0.4%, -0.8%, -0.6%, and 1.5%, respectively. These differences are consistent with ordinary run-to-run variation; all are below 2 without rounding. This is one independent rerun, not an estimate of long-term variance.

| Claim B change | Recorded b1 / b2 / b3 / b4 | Fresh b1 / b2 / b3 / b4 |
|---|---|---|
| keep | 1.035 / 0.974 / 1.041 / 1.014 | 1.029 / 0.991 / 1.050 / 1.012 |
| box | 1.005 / 0.982 / 0.997 / 1.015 | 1.001 / 1.009 / 1.006 / 1.007 |
| helper | 1.003 / 0.987 / 1.000 / 1.011 | 1.002 / 1.003 / 1.001 / 1.000 |

All B outputs were correct and all B warning lists were empty. C again matched all 12 expected diagnostics/acceptances. I also executed all 12 compiled C-fixture programs: each exited 0, including all six deliberately broken demands. D again passed all 18 examples and scored 7 relaxed successes. Separate complete relaxed and strict compiler logs confirm 3 strict successes after following helpers; the runner itself still prints 4 (finding 1).

I independently grouped the recorded CSV into 32 groups of 10 runs and recalculated every median, minimum and maximum. Each agrees with `summary.json` to within 0.51 microseconds, the precision allowed by CSV rounding. Every A-table number, all 12 B-table ratios, the 17%/6% description, and the b3 standard-allocator range agree with the recorded data at their displayed precision. The seed reproduces the exact recorded order, including chronological positions 1–320. Machine metadata is in the JSON, not the CSV itself. Exceptions to the prose's numerical claims are described below.

I separately compiled `diagnostics/b4i64.kk` with `koka -O2 -c`, then measured it, ordinary Koka b4, and same-container mimalloc Rust b4 in 10 randomized interleaved rounds after one warm-up each (seed 230926). All outputs were correct:

| Version | Fresh median seconds | Minimum–maximum |
|---|---|---|
| Koka int64 | 0.340229605 | 0.339703125–0.346551875 |
| Rust same-container mimalloc | 0.305400979 | 0.303682000–0.312863000 |
| Koka int | 0.568700770 | 0.540776459–0.578252416 |

The int64/Rust ratio was **1.114**, rather than the reported historical 1.16; the int/Rust ratio was 1.862. The diagnostic strongly reproduces the number-type effect, but cannot authenticate an earlier run whose raw measurements were not retained.

Fresh data, generated C, diagnostic raw measurements (`build/diagnostic-raw.json`), compiler logs (`build/relaxed.log`, `build/strict.log`), and allocator command lines (`build/allocator-config3.log`) remain in that temporary copy. They are not changes to the reviewed repository.

## Findings

### 1. The executable scorer still falsely accepts invoice-total's strict demand

- **Severity: wrong.**
- **File and line:** `experiments/03-in-place/acceptance/measure.py:217`, `:224`, `:228`; `experiments/03-in-place/data/summary.json:498`.
- **What's wrong:** the scorer checks warnings only on the named function. It reports `invoice-total` as strict-successful even though its required helper fails. Successful strict compilation also causes the full strict diagnostic log to be discarded, hiding that helper warning from the JSON. The manual correction in `RESULT.md:129` is correct, but the machine-readable result and every rerun remain wrong.
- **Evidence:** the fresh runner prints `invoice-total: success True, strict fip True`. A separate strict compilation, replacing `fbip fun` with `fip fun` exactly as the runner does, exits 0 but prints `functions.kk(11,13): warning: fip fun total-from: the matched constructor Cons/16 is not reused`. `invoice-total` calls `total-from` at `bench/claim-d/functions.kk:8`. The actual strict successes are apply-price-change, rotate-queue, and merge-sorted. No relaxed helper has a warning, so the 7 relaxed successes stand.
- **Concrete fix:** after approval of a scoring correction, include each function's reachable local helpers when deciding both demands, retain all demand diagnostics even when compilation succeeds, and regenerate the summary under a new documented lock. Do not silently edit the existing locked scorer or merely hand-edit its JSON output.

### 2. “All four claims pass” assigns a verdict that Claim B does not have

- **Severity: wrong.**
- **File and line:** `experiments/03-in-place/RESULT.md:8`; `HANDOFF.md:40`; `docs/README.md:31`; `docs/research/documents/design-choices/3-can-things-change-after-they-are-made/experiment-3-in-place.md:27`.
- **What's wrong:** the summaries promote B to a passed claim even though the approved rule explicitly gives it no pass or fail, and its own discussion acknowledges that two interventions were optimized away. `RESULT.md:150` additionally attributes an “all four hold → D26 stands” interpretation to the plan that the current plan does not contain.
- **Evidence:** `PLAN.md:29` and `ACCEPTANCE.md:79` make B observational. The JSON stores B observations without a pass field, and the fresh runner prints “Claim B (observational)”. I read the complete current plan; its stop condition requires measured results, not that inference about D26.
- **Concrete fix:** say “A, C and D pass; B's observations are complete but limited” everywhere. Present any inference about D26 as the lead's proposal, without attributing an absent rule to the plan.

### 3. The locked plan contradicts the later accepted demand and reversal rules

- **Severity: wrong.**
- **File and line:** `experiments/03-in-place/PLAN.md:31`, `:45`.
- **What's wrong:** the D row still requires trying strict `fip` with a 7/10 threshold, while D46 and acceptance use relaxed `fbip`. The plan says 100 reversals; acceptance and both implementations do 101. Under the plan's literal strict-demand wording the reported 3/10 would fail.
- **Evidence:** `docs/DECISIONS.md:54`, the Claim D section of acceptance, and fresh strict/relaxed results above. Both `bench/koka/b3.kk` and `bench/rust-same/src/bin/b3.rs` execute 101 rounds, producing the reversed output required by acceptance.
- **Concrete fix:** record an approved correction identifying the obsolete plan statements and aligning them with D46 and the acceptance inputs. Preserve the old lock/history and record a new lock if the plan is edited.

### 4. The historical int64 timing evidence was not kept with the result

- **Severity: minor.**
- **File and line:** `experiments/03-in-place/RESULT.md:69`.
- **What's wrong:** the 0.340 / 0.295 seconds, 1.16×, and “10 interleaved runs” assertion has source code but no saved timing dataset, run-order seed, or repeatable diagnostic runner in the repository. It cannot be checked against either named data file. This falls short of D38's data-retention requirement and D54's repository record.
- **Evidence:** `git ls-files experiments/03-in-place` lists only `diagnostics/b4i64.kk` for this diagnostic. `data/timings.csv` has exactly the 32 scored benchmark/version groups; none is int64. `run.sh` never invokes the diagnostic. My fresh measurement supports the speedup, but gives 1.114× against the current Rust run.
- **Concrete fix:** retain diagnostic raw rounds, outputs, seed, machine/build commands, and a reproduction command as explicitly unscored evidence. Label the old numbers as an unarchived observation if their original data cannot be recovered; do not manufacture retrospective raw data from these medians.

### 5. Some causal and general conclusions exceed these measurements

- **Severity: wrong.**
- **File and line:** `experiments/03-in-place/RESULT.md:64`, `:73`, `:155`, `:165`; mirrored at the research Experiment 3 note's line 31.
- **What's wrong:** the diagnostic shows that choosing int64 removes much of this benchmark's gap, not that all of the gap is “numbers, not memory”, or that unlimited-size numbers themselves cost 1.8×. The latter number compares two languages, not Koka int against Koka int64. “Arrays … whatever the language” is also broader than the sample, and the tree's best-container implementation is a BTreeSet, not an array benchmark.
- **Evidence:** my same-round Koka int/int64 ratio is 0.568700770 / 0.340229605 = about **1.672**, with a residual int64/Rust ratio of **1.114**. Changing numeric representation can affect generated arithmetic and representation; this experiment does not isolate all remaining costs. The recorded b2 best-container ratio is 0.217040771 / 0.084274500 = **2.575**, while b1 and b3 are about 8.51 and 8.23. `bench/rust-best/src/bin/b2.rs` uses `BTreeSet` and directly generates its keys, unlike the same-container input list.
- **Concrete fix:** say the int64 intervention substantially reduces this particular Koka b4 gap. Compare int/int64 directly when discussing numeric overhead. Report the best-container improvements as about 2.6–8.5× on these benchmarks, distinguish Vec from BTreeSet, and limit the conclusion to the tested implementations and whole-program workloads.

### 6. The allocator release matches, but its build configuration does not

- **Severity: minor.**
- **File and line:** `experiments/03-in-place/bench/rust-same/build.rs:10`; identical issue in `bench/rust-best/build.rs:10`; `acceptance/measure.py:169`; `RESULT.md:18`.
- **What's wrong:** the exact-source/version part of the old review was fixed, but its request for matching and recording relevant allocator configuration was not. The result proves a shared release, not a controlled identical configuration. This does not establish deliberate Rust slowness or overturn the accepted numerical pass rule.
- **Evidence:** a fresh `koka -v3 -O2 -c` build prints `-DKK_MIMALLOC=8` for `kklib/src/all.c`, which sets `MI_MAX_ALIGN_SIZE` to 8. Rust's build scripts compile `mimalloc/src/static.c` directly without that definition; bundled `mimalloc/include/mimalloc/types.h:38–39` defaults it to 16. Koka compiles its runtime at `-O2` with native tuning; Rust's allocator script requests optimization level 3. The scorer checks the source-path string and presence of mimalloc symbols, not these settings. Both do use native version 30503 (3.5.3). Independent `nm` checks of all 32 fresh executables found mimalloc symbols in every Koka/mimalloc Rust build and none in standard-allocator Rust.
- **Concrete fix:** record both sets of native build options and the alignment difference. If making an identical-configuration comparison, approve and run a matched configuration, preserving Rust's allocation-alignment contract; do not simply lower Rust's alignment macro while its wrapper still assumes 16-byte alignment. Otherwise explicitly state this remaining control limitation.

### 7. Supersession is recorded only in the later rows, and the historical orientation note is too narrow

- **Severity: minor.**
- **File and line:** `docs/DECISIONS.md:28`, `:30`, `:31`, `:51`; `docs/research/session-orientation.md:3`, `:5`, `:11`.
- **What's wrong:** D34 correctly supersedes D20's two-language portion, D47 supersedes D43, and D54 supersedes D22/D23. But the original rows themselves remain unmarked, unlike struck-through D8. Readers encountering those rows alone still see active two-language/TheBrain/Lean instructions. Session Orientation's added note calls only the API section historical, while the preserved body still says to read it every session and that TheBrain is the source of truth.
- **Evidence:** direct reading of these lines and the later superseding rows. A repository-wide text search found the remaining fnox/API instructions only in this preserved orientation note and the raw export; no active fnox configuration remains tracked.
- **Concrete fix:** add “superseded by D…” backlinks to the old rows, striking only D20's superseded portion. Expand the permitted top note to mark the entire preserved Session Orientation body historical and direct current sessions to HANDOFF/CLAUDE. Keep the exported note text intact.

### 8. Six secondary-parent child listings disappeared from the navigation

- **Severity: minor.**
- **File and line:** `docs/research/big-picture/2-code-layer/README.md:5`; `4-built-in-verification/README.md:3`; `5-effects-and-authority/README.md:5`; `7-ecosystem/README.md:3` (the latter three relative to `docs/research/big-picture/`).
- **What's wrong:** all six “Also filed under” backlinks are preserved on the children, so the relationships are not lost globally. However, the corresponding parents omit those children from their contents; two parent pages appear to have no children at all. The raw export's child navigation is therefore incomplete in Markdown.
- **Evidence:** a Python comparison of all 103 exported `children` entries against parent-page links finds exactly six omissions: Code layer → Core Semantics; Built-in verification → Verification and Feedback, Human and Agent Workflow; Effects and authority → Core Semantics; Ecosystem → Standard Library and Interop, Toolchain and Agent Interface.
- **Concrete fix:** add those relative links to the four parent contents lists, optionally labeled “also filed here”. No original note text needs changing.

### 9. The historical builder-write assertion cannot be independently established

- **Severity: minor.**
- **File and line:** `experiments/03-in-place/RESULT.md:26–27`.
- **What's wrong:** the unconditional statement that the builder wrote only under `bench/` is stronger than the independently attributable evidence in this repository. There is no separate builder commit or write log. This is an evidence limitation, not a finding that the builder changed forbidden files.
- **Evidence:** `git show --format=fuller --stat 4a405fe` is one aggregate commit containing bench sources, data, the diagnostic, RESULT and HANDOFF. It is attributed to Robert/Claude, without per-write agent attribution. Git and the hashes independently establish that the locked files stayed unchanged; they cannot identify who wrote all other paths. The builder brief also allows running a script that writes outside bench, so “wrote” needs to distinguish authored source changes from generated outputs.
- **Concrete fix:** qualify the historical statement as the builder's reported scope plus independently verified unchanged locks, unless a contemporaneous write/session record can substantiate it. For later experiments, retain a bounded source diff or attributable work record if this assertion is needed.

### 10. Small factual and stale-record slips remain

- **Severity: minor.**
- **File and line:** `experiments/03-in-place/RESULT.md:36`, `:95`; `ACCEPTANCE.md:172`; `HANDOFF.md:5–6`.
- **What's wrong:** the result says Koka's final list summary makes three walks; it actually makes two full walks and a constant-time head lookup. “The other 99” reuse rounds is true for b1/b4 but b3 has 100 after its initial copy. Acceptance still says approval fingerprints are “to be recorded”, although its opening and LOCK say they exist. HANDOFF's update description still says the session “set up” Experiment 3 even though its next-step section records completion.
- **Evidence:** source and generated main functions for b1/b3/b4; the 101-round b3 source; all 18 matching fingerprints in LOCK. These are documentation errors, not benchmark failures.
- **Concrete fix:** say two full summary traversals, qualify the reuse-round count by benchmark, replace the stale fingerprint placeholder with the lock reference through an approved lock update, and describe the handoff as covering completion and migration.

### 11. Warm-up output failures are silently ignored

- **Severity: minor.**
- **File and line:** `experiments/03-in-place/acceptance/measure.py:92–93`.
- **What's wrong:** the warm-up invokes the output checker but discards its result. A version can produce incorrect output in that run and still receive fully valid timings, despite acceptance saying every output is checked and an incorrect version's time does not count. This is an enforcement gap, not an observed wrong output from these deterministic benchmark programs.
- **Evidence:** an in-memory probe of the actual `time_interleaved` and `summarize` functions supplied a false output check for the warm-up and a true check for the timed run. The summary still returned `all_outputs_ok: True`.
- **Concrete fix:** retain and require warm-up output validity, or explicitly approve an acceptance rule that validates only timed outputs; record failed warm-ups in the evidence.

## Integrity and the seven previous findings

All **18/18 SHA-256 fingerprints match**. `git log -- experiments/03-in-place/LOCK.md` identifies the current replacement lock in `dddcd3f`. The locked files' last-change commits are either `ff946cf` or `dddcd3f`. Both history inspection and `git diff dddcd3f..HEAD --` restricted to all locked paths show no later changes. There is no lock-integrity finding.

| Previous review finding | Independent disposition |
|---|---|
| 1. Rounded 2× threshold | Fixed. The actual scoring expression rejects an in-memory 2.0004/1.0 boundary probe. |
| 2. Failed strict compile counted as success | Fixed as originally described. An in-memory probe of the current scoring body with strict exit 1 reports all strict results unavailable. The distinct helper bug in finding 1 above remains. |
| 3. Allocator equality | Exact native source/release and Rust allocator selection fixed. Configuration matching/recording remains incomplete (finding 6). |
| 4. Unconstrained algorithms | The approved table now fixes the algorithms; current sources follow its input-building, update, insertion, reversal and cleanup procedures. Final output traversals are not identical, as discussed below. |
| 5. Extra holder may die early | Fixed. Outputs observe the designated contents, and generated C retains the values through the work. |
| 6. Ordinary-call fixture has a second violation | Fixed. `join` receives both lists; the warning is specifically its non-fip `plain-append` call. Fresh C results match each specified violation. |
| 7. Uninterrupted timing blocks | Fixed. Warm-ups precede randomized interleaved rounds; the recorded seed exactly reconstructs the CSV chronology. |

The scorer implements the actual A threshold, C's 12 expected outcomes, and D's relaxed 7/10 rule correctly for the supplied files. It does not fully implement the strict result requirement because it ignores helper warnings. Algorithm correspondence and kept lifetimes remain manual checks, as acceptance explicitly requires. The timed-output checks are complete; the warm-up enforcement gap is described in finding 11.

The same-container sources implement the same prescribed main algorithms: backward list construction, 100 update/prefix rounds, 101 cell-by-cell reversals, and bottom-up Okasaki insertion with the same key comparisons and four ordered rebalance cases. Rust rewires nodes without replacement allocations and frees lists iteratively. I found no fake outputs, benchmark-size shortcuts, added busywork, or deliberately poor baseline. Release builds use LTO and one codegen unit. The complete programs are not literally step-for-step identical: Koka computes list summaries in two traversals while Rust combines them, and their representations, runtime operations and native compilation differ. The results should be read as whole-program implementation comparisons under the specified algorithm, not identical machine instructions differing only in reuse.

For the four keep variants, generated `b1_dash_keep.c`, `b3_dash_keep.c`, and `b4_dash_keep.c` duplicate `original` before calling `rounds` and consume it only in the final sum/weighted sum. `b2_dash_keep.c` duplicates `snapshot` before the second insertion batch, then counts/sums it after observing the final tree. The unshared branch reuses cells; the shared branch duplicates child holders and allocates replacement cells. The helper and box variants' generated rounds/insertion loops contain neither the identity-helper call nor wrapper-record construction. All 12 generated variant C files in the fresh build are byte-identical to the corresponding reviewed `build/.koka` files. These specific generated-code claims are correct.

## Research migration, decisions, and leftovers

The migration audit used `brain-export.json`, not a claimed thought count. It found **98 unique thoughts → 98 uniquely title-matched Markdown files**. All **97 nonempty note bodies appear in full, byte-for-byte after ignoring only exterior whitespace**. All **11 labels**, **6 secondary-parent backlinks**, **10 Earlier research type memberships**, and **20 named-link endpoints representing 10 edges** are preserved, including direction for “depends on” and “tests”. The type node referenced by those memberships is not one of the 98 exported thoughts; its name survives as `Type: Earlier research`.

All **124 relative Markdown links resolve**; there are no relative fragment links requiring anchor resolution. The only narrative additions found are the root README text, the Session Orientation top note, and the Experiment 3 result section. Generated titles, labels, relationship metadata and contents navigation account for the rest. **No thought, note text, label, or named relationship was lost or altered.** Finding 8 is the loss of six parent-to-child navigation entries, not missing child files or lost backlink relationships. Export completeness relative to the original live TheBrain database cannot be established beyond the supplied JSON, and I did not access its API.

I read every decision D24–D54 and compared the requested current documents. D24–D33 form a consistent design outline, with unresolved details explicitly deferred. D34–D35 supersede the two-language direction while retaining the syntax family. D36–D42 define the experiment, thresholds, observational/detection limits and conditional follow-ons consistently. D43 is superseded by D47; D44–D53 refine the experiment without conflicting with the final acceptance rules. D54 supersedes D22/D23. Apart from the old-row markers and stale plan statements listed above, I found no further decision contradiction in HANDOFF, docs/README, CLAUDE, PLAN or ACCEPTANCE. This verifies internal records, not the unrecorded conversations in which Robert approved them.

The current CLAUDE and research root README correctly make the repository authoritative. Remaining TheBrain/fnox/API mentions are historical export material or the old decision/orientation wording covered in finding 7. `git ls-files --others --exclude-standard` was empty before this verdict. Ignored paths were generated builds, Cargo targets, Lake outputs, and `.DS_Store`; none needs to be committed as product source. All existing experiment sources, both Cargo lockfiles, recorded scored data, and the raw research export are tracked. The missing diagnostic raw data in finding 4 is the material evidence-retention gap.

## Checked and found correct

- All 18 locks match, with no post-lock change in Git history.
- A, C and relaxed D reproduce; all 320 timed outputs and 18 examples pass.
- The recorded timing tables and summary statistics agree with the CSV.
- The prescribed core algorithms correspond, and the Rust baseline has no deliberate slowness found.
- All four kept lifetimes are real; helper/box wrappers disappear in generated C.
- The lead's manual strict count of 3 is correct, and the int64 speedup reproduces.
- All 98 research thoughts, full note bodies, labels, secondary-parent backlinks and named links are preserved; every relative link resolves.
- No source file or existing evidence file in the reviewed repository was changed. This verdict is the only repository file created.
