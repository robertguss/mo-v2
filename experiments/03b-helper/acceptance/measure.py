#!/usr/bin/env python3
"""Experiment 3b measurement and scoring. Written by the lead; the builder may not change it.

Screens the builder's helper for forbidden constructs, builds the lead's harness against
the builder's helper and against the lead's two deliberately broken controls, runs the
correctness checks (claims C1 and C2) and the controls, then times every program
(claims A and B) and scores them as ACCEPTANCE.md describes. Correctness and measurement
validity come before any speed verdict (D67). Only a run with the full 10 rounds gets an
acceptance verdict; the outcome stays provisional until the lead's recorded review.

Writes data/timings.csv (as each run finishes), data/summary.json, and the raw output of
every check in data/checks/.

Usage (from experiments/03b-helper):  python3 acceptance/measure.py [--runs N] [--seed S] [--checks-only]
"""
import argparse, csv, json, os, platform, random, re, shutil, statistics, subprocess, tempfile, threading, time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent          # experiments/03b-helper
EXP3 = ROOT.parent / "03-in-place"                      # Experiment 3's baselines, reused unchanged (D64)
ACC = ROOT / "acceptance"
HARNESS = ACC / "harness"
BENCH = ROOT / "bench"
BUILD = ROOT / "build"
DATA = ROOT / "data"

ACCEPTANCE_RUNS = 10
RUN_TIMEOUT = 600          # seconds for one timed run
CHECK_TIMEOUT = 1800       # seconds for one check program
EXPECTED = {
    "b1": ["sum 500100500000", "first 101", "last 1000100"],
    "b2": ["count 1000000", "sum 499999547508", "smallest 0", "largest 1000002"],
    "b3": ["first 1000000", "last 1", "weighted 166667166667000000"],
    "b4": ["first 37", "last 554962791", "sum-mod 491625299"],
    "share-b1": ["sum 500100500000", "first 101", "last 1000100", "rounds-differ 100", "prev-sum 500099500000"],
}
BENCHES = ["b1", "b2", "b3", "b4"]
PROGRAMS = [("helper", b) for b in BENCHES + ["share-b1"]] + [("rust-same", b) for b in BENCHES] + \
           [("koka", b) for b in BENCHES + ["share-b1"]]
KOKA_MIMALLOC_DIR = Path("/opt/homebrew/Cellar/koka/3.2.9/share/koka/v3.2.9/kklib/mimalloc")
HARNESS_CONFIGS = {
    "timed": ["real", "mimalloc"],
    "check-real": ["real", "counting"],
    "check-copies": ["copies", "counting"],
    "check-shares": ["shares", "counting"],
}
C1_FIXED = ["unique-add-one", "unique-reverse", "unique-running-totals", "unique-push-front", "unique-pop-front",
            "empty-list", "unique-tree-insert", "tree-insert-existing", "shared-add-one", "shared-reverse",
            "shared-running-totals", "shared-push-pop", "shared-tree-insert", "shared-tail", "shared-subtree",
            "drop-long-list", "drop-large-tree"]
C1_SHARED = ["shared-add-one", "shared-reverse", "shared-running-totals", "shared-push-pop", "shared-tree-insert",
             "shared-tail", "shared-subtree"]
C1_GENERATED = {"lists": 2000, "trees": 2000}
C2_CHECKS = ["unique-add-one", "unique-reverse", "unique-running-totals", "hold-and-release-list", "unique-pop-front",
             "shared-list-push-front", "reuse-restored-list", "hold-and-release-tree", "reuse-restored-tree",
             "unique-tree-insert-new", "unique-tree-insert-existing", "shared-tree-insert",
             "list-kept-while-held", "list-freed", "tree-kept-while-held", "tree-freed"]
# The always-copies control must fail these on allocations alone, with its values right.
C2_COPYING = ["unique-add-one", "unique-reverse", "unique-running-totals", "unique-tree-insert-new"]
COPYPATH = ["share-new-copy-each-round", "share-nothing-piles-up"]
# A preliminary screen only. The lead's recorded source review decides (ACCEPTANCE.md).
FORBIDDEN_RUST = [r"\bunsafe\b", r"\bRefCell\b", r"\bUnsafeCell\b", r"\bOnceCell\b", r"\bLazyCell\b",
                  r"\bcell::", r"\bCell\s*<", r"\bWeak\b", r"\bArc\b", r"(?<!')\bstatic\b", r"\bMutex\b", r"\bRwLock\b",
                  r"\bAtomic", r"\bsync::", r"global_allocator", r"\bthread_local\b", r"\bptr::",
                  r"\*\s*(mut|const)\b", r"\btransmute\b", r"\balloc::", r"\b(env|fs|process|time|thread)::",
                  r"\bextern\b", r"\bmacro_rules\b", r"#\s*!?\s*\[\s*path\b",
                  r"\bcfg\s*\(\s*(not\s*\(\s*)?(feature|debug_assertions|target)"]
FORBIDDEN_KOKA = [r"\bvar\b", r"\bref\s*\(", r"\bvector\b", r"unsafe"]


def sh(cmd, cwd=None, timeout=None):
    try:
        p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout, p.stderr
    except subprocess.TimeoutExpired as e:
        out = e.stdout.decode() if isinstance(e.stdout, bytes) else (e.stdout or "")
        return "timeout", out, f"timed out after {timeout} s"


def strip_rust_comments(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)


def screen_helper_source():
    """Preliminary screen of the builder's helper: its crate description and every Rust file."""
    problems = []
    crate = BENCH / "helper"
    manifest = crate / "Cargo.toml"
    if not manifest.exists():
        return [f"missing {manifest.relative_to(ROOT)}"]
    m = manifest.read_text()
    if not re.search(r'^name\s*=\s*"helper"', m, re.M) or not re.search(r'^version\s*=\s*"0\.1\.0"', m, re.M):
        problems.append("bench/helper/Cargo.toml must declare name \"helper\" and version \"0.1.0\"")
    if re.search(r"^\s*\[(dev-|build-)?dependencies|^\s*\[target|^\s*build\s*=", m, re.M):
        problems.append("bench/helper/Cargo.toml may not declare dependencies or a build script")
    if (crate / "build.rs").exists():
        problems.append("bench/helper may not have a build script")
    sources = [s for s in sorted(crate.rglob("*.rs")) if "target" not in s.relative_to(crate).parts]
    if not sources:
        problems.append("bench/helper has no Rust source")
    uses_rc = False
    for src in sources:
        text = strip_rust_comments(src.read_text())
        uses_rc = uses_rc or re.search(r"\bRc\b", text) is not None
        for pat in FORBIDDEN_RUST:
            if re.search(pat, text):
                problems.append(f"{src.relative_to(ROOT)} matches forbidden pattern {pat}")
    if sources and not uses_rc:
        problems.append("bench/helper does not use Rc")
    return problems


def cargo_build(manifest, target, features):
    cmd = ["cargo", "build", "--release", "--locked", "--manifest-path", str(manifest), "--target-dir", str(target)]
    if features:
        cmd += ["--no-default-features", "--features", ",".join(features)]
    code, out, err = sh(cmd)
    return code == 0, (out + err)[-4000:]


def uses_mimalloc(exe):
    _, out, _ = sh(["nm", str(exe)])
    return re.search(r"\s_{0,2}mi_\w+", out) is not None


def koka_build(src, out):
    out.parent.mkdir(parents=True, exist_ok=True)
    code, o, e = sh(["koka", "-O2", "-c", f"--builddir={BUILD / '.koka'}", f"-i{src.parent}", "-o", str(out), str(src)])
    log = o + e
    return code == 0 and out.exists(), [l for l in log.splitlines() if "warning" in l], log[-2000:]


def build_all(helper_ok):
    builds, problems = {}, []
    for name, feats in HARNESS_CONFIGS.items():
        if "real" in feats and not helper_ok:
            continue
        ok, log = cargo_build(HARNESS / "Cargo.toml", BUILD / f"cargo-{name}", feats)
        if not ok:
            problems.append(f"harness build '{name}' failed")
        builds[("harness", name)] = {"ok": ok, "dir": BUILD / f"cargo-{name}" / "release", "log": log}
    ok, log = cargo_build(EXP3 / "bench" / "rust-same" / "Cargo.toml", BUILD / "cargo-rust-same", ["mimalloc"])
    if not ok:
        problems.append("Experiment 3's same-container Rust failed to build")
    builds[("rust-same", "all")] = {"ok": ok, "dir": BUILD / "cargo-rust-same" / "release", "log": log}
    for b in BENCHES:
        ok, warns, log = koka_build(EXP3 / "bench" / "koka" / f"{b}.kk", BUILD / "koka" / b)
        builds[("koka", b)] = {"ok": ok, "exe": BUILD / "koka" / b, "warnings": warns, "log": log}
        if not ok:
            problems.append(f"Experiment 3's Koka {b} failed to build")
    src = BENCH / "koka-share" / "b1-share.kk"
    if not src.exists():
        problems.append(f"missing {src.relative_to(ROOT)}")
    else:
        text = re.sub(r"//[^\n]*", "", src.read_text())
        bad = [p for p in FORBIDDEN_KOKA if re.search(p, text)]
        if bad:
            problems.append(f"{src.relative_to(ROOT)} uses forbidden {bad}")
        ok, warns, log = koka_build(src, BUILD / "koka" / "share-b1")
        builds[("koka", "share-b1")] = {"ok": ok and not bad, "exe": BUILD / "koka" / "share-b1", "warnings": warns, "log": log}
        if not ok:
            problems.append("Koka share-b1 failed to build")
    return builds, problems


def run_check(builds, config, program):
    info = builds.get(("harness", config))
    if not info or not info["ok"]:
        return None
    code, out, err = sh([str(info["dir"] / program)], timeout=CHECK_TIMEOUT)
    (DATA / "checks").mkdir(parents=True, exist_ok=True)
    (DATA / "checks" / f"{config}-{program}.txt").write_text(
        out + f"\n--- exit {code} ---\n" + ("--- stderr ---\n" + err if err.strip() else ""))
    return code, out.splitlines()


def parse_c1(result):
    if result is None:
        return {"ran": False, "complete": False, "passed": False, "reason": "not built"}
    code, lines = result
    fixed, generated, failures = {}, {}, []
    for l in lines:
        parts = l.split(" ", 3)
        if parts[0] == "FIXED" and len(parts) >= 3:
            fixed[parts[1]] = {"ok": parts[2] == "ok", "detail": parts[3] if len(parts) > 3 else ""}
        elif parts[0] == "GENERATED":
            m = re.match(r"GENERATED (\w+) sequences (\d+) failures (\d+)", l)
            if m:
                generated[m.group(1)] = {"sequences": int(m.group(2)), "failures": int(m.group(3))}
        elif parts[0] == "FAILURE":
            failures.append(l)
    complete = (code == 0 and bool(lines) and lines[-1] == "DONE" and all(n in fixed for n in C1_FIXED)
                and all(generated.get(k, {}).get("sequences") == n for k, n in C1_GENERATED.items()))
    passed = complete and all(fixed[n]["ok"] for n in C1_FIXED) and all(generated[k]["failures"] == 0 for k in C1_GENERATED)
    # A caught panic is not a value mismatch; controls must be caught by wrong values (Codex, re-check).
    mismatches = {k: 0 for k in C1_GENERATED}
    panics = sum(1 for v in fixed.values() if v["detail"] == "panicked")
    for l in failures:
        m = re.match(r"FAILURE (\w+) seed \d+ step \d+ (.*?) ops ", l + " ops ")
        if m and m.group(2) == "panicked":
            panics += 1
        elif m and m.group(1) in mismatches:
            mismatches[m.group(1)] += 1
    return {"ran": True, "exit": code, "complete": complete, "passed": passed, "fixed": fixed,
            "generated": generated, "failure_count": len(failures), "failures_first_3": failures[:3],
            "panics": panics, "value_mismatches": mismatches}


def parse_c2(result):
    if result is None:
        return {"ran": False, "complete": False, "passed": False, "reason": "not built"}
    code, lines = result
    checks, copypath = {}, {}
    for l in lines:
        m = re.match(r"(CHECK|COPYPATH) (\S+) (allocations|live-change) (-?\d+) rule (\S+) (ok|FAIL)(?: (.*))?$", l)
        if m:
            row = {"measure": m.group(3), "value": int(m.group(4)), "rule": m.group(5), "ok": m.group(6) == "ok",
                   "values_wrong": m.group(7) == "values-wrong"}
            (checks if m.group(1) == "CHECK" else copypath)[m.group(2)] = row
    complete = (code == 0 and bool(lines) and lines[-1] == "DONE" and all(n in checks for n in C2_CHECKS)
                and all(n in copypath for n in COPYPATH))
    passed = complete and all(checks[n]["ok"] for n in C2_CHECKS)
    copying_ok = complete and all(copypath[n]["ok"] for n in COPYPATH)
    return {"ran": True, "exit": code, "complete": complete, "passed": passed, "checks": checks,
            "copypath": copypath, "copypath_ok": copying_ok}


def controls_verdict(c1_shares, c1_copies, c2_copies):
    """Each control must finish and fail in the specific way it was built to (Codex, 3b review)."""
    shares_caught = (c1_shares["complete"] and c1_shares["panics"] == 0
                     and all(not c1_shares["fixed"][n]["ok"] for n in C1_SHARED)
                     and all(c1_shares["value_mismatches"][k] > 0 for k in C1_GENERATED))
    copies_accepted = c1_copies["passed"]
    copies_caught = (c2_copies["complete"] and not any(r["values_wrong"] for r in c2_copies["checks"].values())
                     and all(not c2_copies["checks"][n]["ok"] for n in C2_COPYING))
    return {
        "C1 catches a helper that changes shared values (shared-mutation): finished without panics, wrong values in every shared case and in generated sequences of both kinds": shares_caught,
        "C1 accepts a correct helper that always copies (always-copies): finished and passed": copies_accepted,
        "C2 catches a helper that always copies (always-copies): finished, values right, allocations over the limit on every unique update": copies_caught,
    }


def run_once(exe, expected):
    """One run, bounded by RUN_TIMEOUT. Returns the time, output check, exit status, the
    tail of stderr, and peak memory in bytes (macOS reports ru_maxrss in bytes)."""
    with tempfile.TemporaryFile() as fo, tempfile.TemporaryFile() as fe:
        t0 = time.perf_counter()
        p = subprocess.Popen([str(exe)], stdout=fo, stderr=fe)
        timed_out = threading.Event()
        timer = threading.Timer(RUN_TIMEOUT, lambda: (timed_out.set(), p.kill()))
        timer.start()
        _, status, usage = os.wait4(p.pid, 0)
        dt = time.perf_counter() - t0
        timer.cancel()
        p.returncode = os.waitstatus_to_exitcode(status)
        fo.seek(0); fe.seek(0)
        out = fo.read().decode(errors="replace")
        err = fe.read().decode(errors="replace")
    ok = p.returncode == 0 and not timed_out.is_set() and out.strip().splitlines() == expected
    return {"seconds": dt, "output_ok": ok, "exit_code": p.returncode, "timed_out": timed_out.is_set(),
            "peak_bytes": usage.ru_maxrss, "output": out.strip().replace("\n", " | ")[:200], "stderr_tail": err[-300:]}


def time_interleaved(jobs, runs, seed, writer, handle):
    """As Experiment 3 (D51, D56): one checked, untimed warm-up of every program (round 0),
    then `runs` rounds, each running every program once in a fresh random order from a
    recorded seed. Each run is written to the CSV as soon as it finishes."""
    rows, order = {key: [] for key, _, _ in jobs}, 0

    def one(rnd, key, exe, expected):
        nonlocal order
        order += 1
        r = run_once(exe, expected)
        r.update({"round": rnd, "order": order, "program": key[0], "benchmark": key[1]})
        rows[key].append(r)
        writer.writerow({k: r[k] for k in writer.fieldnames})
        handle.flush()

    for key, exe, expected in jobs:
        one(0, key, exe, expected)
    rng = random.Random(seed)
    for rnd in range(1, runs + 1):
        batch = list(jobs)
        rng.shuffle(batch)
        for key, exe, expected in batch:
            one(rnd, key, exe, expected)
    return rows


def summarize(rows):
    timed = [r for r in rows if r["round"] > 0]
    secs = [r["seconds"] for r in timed]
    return {"median": statistics.median(secs) if secs else None, "fastest": min(secs, default=None),
            "slowest": max(secs, default=None), "runs": len(secs),
            "median_peak_bytes": statistics.median(r["peak_bytes"] for r in timed) if timed else None,
            "all_outputs_ok": bool(rows) and all(r["output_ok"] for r in rows)}   # the warm-up counts too (D56)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--runs", type=int, default=ACCEPTANCE_RUNS)
    ap.add_argument("--seed", type=int, default=None, help="random order seed; recorded in the summary")
    ap.add_argument("--checks-only", action="store_true", help="build and run claims C1 and C2 and the controls only")
    args = ap.parse_args()
    DATA.mkdir(exist_ok=True)
    if BUILD.exists():
        shutil.rmtree(BUILD)
    acceptance_run = args.runs == ACCEPTANCE_RUNS and not args.checks_only
    summary = {"machine": {"os": f"macOS {platform.mac_ver()[0]}",
                           "cpu": sh(["sysctl", "-n", "machdep.cpu.brand_string"])[1].strip(),
                           "koka": sh(["koka", "--version"])[1].splitlines()[0],
                           "rustc": sh(["rustc", "--version"])[1].strip()},
               "runs_per_program": args.runs, "acceptance_run": acceptance_run}

    helper_problems = screen_helper_source()
    builds, problems = build_all(not helper_problems)
    summary["helper_screen_problems"] = helper_problems
    summary["build_problems"] = problems

    # Claims C1 and C2, and the controls that show the checks can tell right from wrong.
    c1 = {cfg: parse_c1(run_check(builds, cfg, "c1")) for cfg in ["check-real", "check-copies", "check-shares"]}
    c2 = {cfg: parse_c2(run_check(builds, cfg, "c2")) for cfg in ["check-real", "check-copies"]}
    controls = controls_verdict(c1["check-shares"], c1["check-copies"], c2["check-copies"])
    summary["claim_c1"] = c1["check-real"]
    summary["claim_c2"] = c2["check-real"]
    summary["controls"] = controls
    summary["control_runs"] = {"c1": {k: v for k, v in c1.items() if k != "check-real"},
                               "c2": {"check-copies": c2["check-copies"]}}
    correctness_ok = (not helper_problems) and all(controls.values()) and c1["check-real"]["passed"] and c2["check-real"]["passed"]

    if not args.checks_only:
        # Timed programs: the builder's helper through the lead's drivers, and Experiment 3's
        # same-container Rust and pure Koka, rebuilt and re-run today, interleaved.
        jobs = []
        for who, b in PROGRAMS:
            if who == "helper":
                info = builds.get(("harness", "timed"))
                exe = info["dir"] / b if info and info["ok"] else None
            elif who == "rust-same":
                info = builds.get(("rust-same", "all"))
                exe = info["dir"] / b if info and info["ok"] else None
            else:
                info = builds.get(("koka", b))
                exe = info["exe"] if info and info["ok"] else None
            if exe:
                jobs.append(((who, b), exe, EXPECTED[b]))
        missing = [f"{w} {b}" for w, b in PROGRAMS if (w, b) not in {k for k, _, _ in jobs}]
        alloc_ok = all(uses_mimalloc(exe) for (who, _), exe, _ in jobs if who in ("helper", "rust-same"))
        summary["machine"]["mimalloc"] = {"source": str(KOKA_MIMALLOC_DIR), "present_in_timed_rust": alloc_ok}
        seed = args.seed if args.seed is not None else random.SystemRandom().randrange(1 << 30)
        summary["timing"] = {"order": "interleaved, random per round", "seed": seed, "warm_up_runs": 1,
                             "timeout_seconds_per_run": RUN_TIMEOUT, "missing_programs": missing}
        fields = ["order", "round", "program", "benchmark", "seconds", "peak_bytes", "exit_code", "timed_out",
                  "output_ok", "output", "stderr_tail"]
        with open(DATA / "timings.csv", "w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=fields)
            w.writeheader()
            all_rows = time_interleaved(jobs, args.runs, seed, w, f) if jobs else {}
        t = {key: summarize(rows) for key, rows in all_rows.items()}
        summary["programs"] = {f"{k[0]} {k[1]}": v for k, v in t.items()}
        all_programs_ok = all(v["all_outputs_ok"] for v in t.values())

        # Measurement validity for the whole experiment: every specified program built, ran and
        # gave the right output; every timed Rust program contains mimalloc.
        validity_failures = [w for w, bad in [
            ("the helper failed the preliminary source screen", bool(helper_problems)),
            ("a control did not behave as expected, so the checks cannot be trusted", not all(controls.values())),
            ("claim C1 failed", not c1["check-real"]["passed"]),
            ("claim C2 failed", not c2["check-real"]["passed"]),
            ("claim B's copying gate failed", not c2["check-real"].get("copypath_ok", False)),
            (f"a specified program is missing: {', '.join(missing)}", bool(missing)),
            ("a timed program gave wrong output, crashed or timed out", not all_programs_ok),
            ("a timed Rust program does not contain mimalloc", not alloc_ok)] if bad]
        valid = not validity_failures

        # Claim A (D67): helper within 2x of same-container Rust with mimalloc, on each benchmark,
        # exact medians. Koka ratios are extra data.
        rows_a = []
        for b in BENCHES:
            h, base, k = t.get(("helper", b)), t.get(("rust-same", b)), t.get(("koka", b))
            both_ok = bool(h and base and h["all_outputs_ok"] and base["all_outputs_ok"])
            rows_a.append({"benchmark": b, "helper": h, "rust_same": base, "koka": k,
                           "ratio_to_rust_same": round(h["median"] / base["median"], 3) if both_ok else None,
                           "ratio_to_koka": round(h["median"] / k["median"], 3) if (both_ok and k and k["all_outputs_ok"]) else None,
                           "within_2x": both_ok and h["median"] <= 2.0 * base["median"]})
        if not acceptance_run:
            verdict = f"NO VERDICT (exploratory run of {args.runs} rounds; acceptance needs {ACCEPTANCE_RUNS})"
        elif not valid:
            verdict = "NO VERDICT"
        else:
            verdict = "PASS" if all(r["within_2x"] for r in rows_a) else "FAIL"
        summary["claim_a"] = {"benchmarks": rows_a, "verdict": verdict, "validity_failures": validity_failures}

        # Claim B (D63): observational. Peak memory is reported, not judged.
        def sharing(who):
            plain, share = t.get((who, "b1")), t.get((who, "share-b1"))
            if not (plain and share and plain["all_outputs_ok"] and share["all_outputs_ok"]):
                return {"valid_output": False}
            return {"valid_output": True, "plain": plain, "share": share,
                    "raw_time_ratio": round(share["median"] / plain["median"], 3),
                    "raw_peak_memory_ratio": round(share["median_peak_bytes"] / plain["median_peak_bytes"], 3)}
        hb, kb = sharing("helper"), sharing("koka")
        hb["copying_gate"] = c2["check-real"].get("copypath", {})
        hb["copying_gate_ok"] = c2["check-real"].get("copypath_ok", False)
        # Interpreted only when every gate holds. Koka's gate needs the lead's recorded check,
        # so Koka's ratios and the cross-language ratio stay unvalidated in the script's output.
        hb["validated"] = bool(hb["valid_output"] and hb["copying_gate_ok"] and correctness_ok)
        kb["retention_in_compiled_program"] = "PENDING: the lead reads Koka's compiled C and records the finding in RESULT.md"
        kb["validated"] = False
        summary["claim_b"] = {"helper": hb, "koka": kb,
                              "raw_helper_share_vs_koka_share": round(hb["share"]["median"] / kb["share"]["median"], 3)
                              if hb["valid_output"] and kb["valid_output"] else None,
                              "note": "raw ratios are measurements only; a ratio is interpreted only once its gates hold"}

        # What the outcome means for 3c (D66). Provisional until the lead's recorded review.
        if not acceptance_run:
            outcome = "none (exploratory run)"
        elif not valid:
            outcome = "1 (provisional): correctness or measurement validity failed; repair or redesign 3b before drawing conclusions"
        elif verdict == "PASS":
            outcome = "2 (provisional): a valid helper meets the speed budget; supports going on to 3c with it as a candidate foundation"
        else:
            outcome = "3 (provisional): a valid helper misses the speed budget; diagnose the cause and bring Robert a next-step proposal"
        summary["d66_outcome"] = outcome
        summary["pending_lead_review"] = ["source review of the measured helper (ACCEPTANCE.md, 'The lead's recorded review')",
                                          "step-for-step algorithm correspondence with Experiment 3's same-container Rust",
                                          "Koka sharing program holds the kept version across the update (compiled C)"]

    (DATA / "summary.json").write_text(json.dumps(summary, indent=2, default=str))

    print("Experiment 3b results" + ("" if acceptance_run or args.checks_only else f"  [EXPLORATORY: {args.runs} rounds, no acceptance verdict]"))
    if helper_problems:
        print("Helper source screen problems:", *helper_problems, sep="\n  ")
    if problems:
        print("Build problems:", *problems, sep="\n  ")
    print("Controls (the checks must tell right from wrong):")
    for name, ok in controls.items():
        print(f"  {'ok  ' if ok else 'FAIL'} {name}")
    r = c1["check-real"]
    print(f"Claim C1 (values preserved in these tests): {'PASS' if r['passed'] else 'FAIL'}")
    for n, v in r.get("fixed", {}).items():
        if not v["ok"]:
            print(f"  {n}: {v['detail']}")
    for kind, g in r.get("generated", {}).items():
        print(f"  generated {kind}: {g['sequences']} sequences, {g['failures']} failures")
    for l in r.get("failures_first_3", []):
        print(f"  {l[:300]}")
    r = c2["check-real"]
    print(f"Claim C2 (no copying with one holder; shared values copy only what they must; memory freed): {'PASS' if r['passed'] else 'FAIL'}")
    for n, v in r.get("checks", {}).items():
        print(f"  {n}: {v['measure']} {v['value']}, rule {v['rule']}, {'ok' if v['ok'] else 'FAIL'}{' (values wrong)' if v['values_wrong'] else ''}")
    if "claim_a" in summary:
        a = summary["claim_a"]
        print(f"Claim A (helper within 2x of same-container Rust, each benchmark): {a['verdict']}")
        for why in a["validity_failures"]:
            print(f"  not valid: {why}")
        for row in a["benchmarks"]:
            hm = row["helper"]["median"] if row["helper"] else None
            bm = row["rust_same"]["median"] if row["rust_same"] else None
            print(f"  {row['benchmark']}: helper {hm}, rust-same {bm}, ratio {row['ratio_to_rust_same']}, vs koka {row['ratio_to_koka']}")
        b = summary["claim_b"]
        print("Claim B (observational):")
        for n, v in b["helper"]["copying_gate"].items():
            print(f"  helper gate {n}: {v['measure']} {v['value']}, rule {v['rule']}, {'ok' if v['ok'] else 'FAIL'}")
        for who in ["helper", "koka"]:
            x = b[who]
            if not x["valid_output"]:
                print(f"  {who}: sharing programs did not both give the right output; nothing to interpret")
            elif x["validated"]:
                print(f"  {who}: sharing costs {x['raw_time_ratio']}x time; peak memory {x['raw_peak_memory_ratio']}x (reported, not judged)")
            else:
                why = "Koka retention check pending" if who == "koka" else "a gate failed"
                print(f"  {who}: raw ratios {x['raw_time_ratio']}x time, {x['raw_peak_memory_ratio']}x peak memory; NOT INTERPRETED ({why})")
        print(f"  raw helper sharing vs koka sharing: {b['raw_helper_share_vs_koka_share']} (not interpreted until Koka's retention check is recorded)")
        print(f"  Koka retention: {b['koka']['retention_in_compiled_program']}")
        print(f"Outcome under D66: {summary['d66_outcome']}")
        if acceptance_run:
            print("  Final only after the lead's recorded review:", *summary["pending_lead_review"], sep="\n    ")
    print(f"Wrote {DATA / 'summary.json'}" + ("" if args.checks_only else f" and {DATA / 'timings.csv'}"))


if __name__ == "__main__":
    main()
