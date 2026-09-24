#!/usr/bin/env python3
"""DIAGNOSTIC ONLY, not part of the scored experiment (D55).

Times Koka benchmark 4 with Koka's default unlimited-size `int` against the same
program with fixed-size `int64` (b4i64.kk), and against same-container Rust with
mimalloc. Needs `./run.sh` to have been run first, so the scored builds exist.
Writes b4i64-timings.csv and b4i64-summary.json next to this file.

Usage (from experiments/03-in-place):  python3 diagnostics/run_b4i64.py [--runs N] [--seed S]
"""
import argparse, csv, json, platform, random, statistics, subprocess, time
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
EXPECTED = ["first 37", "last 554962791", "sum-mod 491625299"]


def sh(cmd):
    return subprocess.run(cmd, capture_output=True, text=True).stdout.strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--runs", type=int, default=10)
    ap.add_argument("--seed", type=int, default=None)
    args = ap.parse_args()
    out = ROOT / "build" / "diagnostics" / "b4i64"
    out.parent.mkdir(parents=True, exist_ok=True)
    build_cmd = ["koka", "-O2", "-c", f"--builddir={ROOT / 'build' / '.koka-diag'}", "-o", str(out), str(HERE / "b4i64.kk")]
    subprocess.run(build_cmd, check=True, capture_output=True)
    exes = {"koka-int64": out, "koka-int": ROOT / "build" / "koka" / "b4",
            "rust-same-mimalloc": ROOT / "build" / "cargo-rust-same-mimalloc" / "release" / "b4"}
    for name, exe in exes.items():
        if not exe.exists():
            raise SystemExit(f"missing {exe}: run ./run.sh first")
    seed = args.seed if args.seed is not None else random.SystemRandom().randrange(1 << 30)
    rng = random.Random(seed)
    for exe in exes.values():                       # one untimed warm-up each, output checked
        p = subprocess.run([str(exe)], capture_output=True, text=True)
        if p.stdout.strip().splitlines() != EXPECTED:
            raise SystemExit(f"wrong output from {exe} during warm-up")
    rows, order = [], 0
    for rnd in range(1, args.runs + 1):
        names = list(exes); rng.shuffle(names)
        for name in names:
            order += 1
            t0 = time.perf_counter()
            p = subprocess.run([str(exes[name])], capture_output=True, text=True)
            dt = time.perf_counter() - t0
            rows.append({"order": order, "round": rnd, "version": name, "seconds": round(dt, 6),
                         "output_ok": p.returncode == 0 and p.stdout.strip().splitlines() == EXPECTED})
    with open(HERE / "b4i64-timings.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
    med = {n: statistics.median(r["seconds"] for r in rows if r["version"] == n) for n in exes}
    summary = {"note": "diagnostic only, not scored", "seed": seed, "runs": args.runs,
               "machine": {"os": f"macOS {platform.mac_ver()[0]}", "cpu": sh(["sysctl", "-n", "machdep.cpu.brand_string"]),
                           "koka": sh(["koka", "--version"]).splitlines()[0], "rustc": sh(["rustc", "--version"])},
               "build_command": " ".join(build_cmd), "medians_seconds": med,
               "all_outputs_ok": all(r["output_ok"] for r in rows),
               "ratios": {"koka-int / koka-int64": med["koka-int"] / med["koka-int64"],
                          "koka-int64 / rust-same-mimalloc": med["koka-int64"] / med["rust-same-mimalloc"],
                          "koka-int / rust-same-mimalloc": med["koka-int"] / med["rust-same-mimalloc"]}}
    (HERE / "b4i64-summary.json").write_text(json.dumps(summary, indent=2, default=str))
    print(json.dumps(summary["medians_seconds"], indent=1)); print(json.dumps(summary["ratios"], indent=1))
    print("all outputs ok:", summary["all_outputs_ok"], "| seed:", seed)


if __name__ == "__main__":
    main()
