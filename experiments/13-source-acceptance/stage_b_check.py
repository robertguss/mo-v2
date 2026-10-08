"""Run the whole Stage B acceptance preparation and write its evidence.

    python3 stage_b_check.py evidence/stage-b-01 /tmp/rob1333-stage-b/debug

The second argument is the directory holding the two built stub binaries. Build
them first, with the pinned toolchain, from the repository root:

    export CARGO_TARGET_DIR=/tmp/rob1333-stage-b
    cargo +1.98.1 build --locked \\
        --manifest-path experiments/13-source-acceptance/stage-b-stub/Cargo.toml

Nothing here runs a Mo interpreter, executes one of the ten deferred Stage B
control paths, touches the acceptance-private corpus, or runs either approved
million-cell workload.
"""
from datetime import datetime, timezone
import json
from pathlib import Path
import sys
import time
import traceback

import stage_b_controls
import stage_b_delivery
import stage_b_inventory
import stage_b_link
from closeoutcheck import check_resource
from stage_b_large import (LargeVerifier, OBSERVATION_PERIOD, check_projected_record,
                           observation_count, projected_record, run_large_linked)
from stage_b_workloads import (APPROVED_DEPTH, DiscardedList, NonTailSum, WORKLOADS,
                               linear_fit, state_growth, validate_schedule, validate_states)


# Depths used to validate the closed forms against the frozen reference. Small,
# because the reference is host-recursive and keeps every state.
REFERENCE_DEPTHS = list(range(0, 9))

# Depths used to drive the adapter. Far below the approved million; the largest
# is there to measure how the cost grows, not to approach the workload.
ADAPTER_DEPTHS = [12, 2_000, 5_000, 20_000, 50_000, 100_000, 200_000]


def run_workloads(destination):
    report = dict(reference_depths=REFERENCE_DEPTHS, schedule_comparisons=0, state_comparisons=0)
    for name, workload_class in sorted(WORKLOADS.items()):
        for depth in REFERENCE_DEPTHS:
            workload = workload_class(depth)
            report["schedule_comparisons"] += validate_schedule(workload)
            if workload.states_implemented:
                report["state_comparisons"] += validate_states(workload)
    growth = {name: state_growth(cls, REFERENCE_DEPTHS[:7]) for name, cls in sorted(WORKLOADS.items())}
    report["state_growth"] = growth
    report["state_growth_per_cell"] = {
        name: {key: linear_fit(rows, key) for key in
               ("memory", "bindings", "frames", "pending", "control", "release",
                "transitions", "landmarks")}
        for name, rows in growth.items()}
    # What the approved depth implies, from those slopes. An extrapolation.
    report["approved_depth_projection"] = {}
    for name, workload_class in sorted(WORKLOADS.items()):
        workload = workload_class(APPROVED_DEPTH)
        cost = workload.schedule_cost(OBSERVATION_PERIOD)
        row = dict(transitions=workload.transitions(),
                   answer=workload.expected_answer(),
                   evaluation_cell_counts=workload.expected_cell_counts(),
                   peak_explicit_frames=workload.expected_peak_frames(),
                   observations=observation_count(workload),
                   schedule=cost)
        fits = report["state_growth_per_cell"][name]
        row["peak_full_observation_rows"] = {
            key: None if fits[key] is None else fits[key]["per_cell"] * APPROVED_DEPTH + fits[key]["constant"]
            for key in ("memory", "frames", "control", "release")}
        row["serialized_observation_rows"] = cost["serialized_rows"]
        report["approved_depth_projection"][name] = row
    (destination / "workloads.json").write_text(json.dumps(report, indent=2) + "\n")
    return report


def run_projected_records(destination):
    """The frozen D151 predicate must accept the projected approved records."""
    report = dict(accepted={}, rejected={})
    for name, workload_class in sorted(WORKLOADS.items()):
        workload = workload_class(APPROVED_DEPTH)
        report["accepted"][name] = check_projected_record(workload)
        good = projected_record(workload, elapsed_seconds=599, available_bytes=4 * 1024 ** 3)
        rejections = {}
        for key, wrong in (("depth", APPROVED_DEPTH - 1), ("answer", "999999"),
                           ("elapsed_seconds", 601), ("transitions", 100_000_001),
                           ("stack_bytes", 16 * 1024 ** 2), ("status", "suspended"),
                           ("remaining_owned_cells", 1), ("available_bytes", 1024)):
            bad = dict(good)
            bad[key] = wrong
            try:
                check_resource(bad)
            except AssertionError as error:
                rejections[key] = str(error)
            else:
                raise AssertionError("frozen D151 predicate accepted a wrong record: " + key)
        report["rejected"][name] = rejections
    (destination / "projected-records.json").write_text(json.dumps(report, indent=2) + "\n")
    return report


def run_adapter(destination, binaries):
    command = [str(Path(binaries) / "stage_b_large_stub")]
    report = dict(runs=[], controls={}, candidate_executed=False, resource_workload_executed=False)
    for depth in ADAPTER_DEPTHS:
        workload = DiscardedList(depth)
        result = run_large_linked(command, workload, [workload.transitions()],
                                  destination / f"discarded-{depth}")
        report["runs"].append({k: result[k] for k in (
            "depth", "committed_steps", "full_observations", "summary_observations",
            "deepest_photographed", "streamed_commits",
            "evaluation_cell_counts", "cleanup_frees", "teardown_frees", "peak_live_cells",
            "peak_cleanup_chain", "peak_retained_rows", "retained_rows_at_end",
            "peak_rss_kib", "verifier_peak_kib", "elapsed_seconds", "scaled_resource_record")})
    # Suspend, resume with no work, and resume again, at a periodic boundary.
    workload = DiscardedList(5_000)
    total = workload.transitions()
    resumed = run_large_linked(command, workload, [OBSERVATION_PERIOD, 0, total - OBSERVATION_PERIOD],
                               destination / "discarded-resume")
    assert resumed["committed_steps"] == total, "resume reached terminal"
    report["resume_run"] = {k: resumed[k] for k in ("committed_steps", "full_observations",
                                                    "summary_observations", "peak_cleanup_chain",
                                                    "elapsed_seconds")}
    # D159's deepest photograph, taken by pausing there. The frozen collector
    # cannot attach a commit snapshot off the 10,000 grid, and this chain is
    # longest one step before that grid.
    deepest = DiscardedList(5_000)
    photographed = run_large_linked(command, deepest, [deepest.deepest_step()],
                                    destination / "discarded-deepest")
    assert photographed["deepest_photographed"] is True, "deepest photograph missing"
    assert photographed["peak_cleanup_chain"] == deepest.depth, "deepest chain"
    assert photographed["cleanup_frees"] == 1, "the last cell was still allocated at the deepest point"
    report["deepest_photograph"] = {k: photographed[k] for k in (
        "committed_steps", "full_observations", "summary_observations",
        "deepest_photographed", "peak_cleanup_chain", "cleanup_frees")}
    # Destroy part-way through cleanup, with cells still owned by the run.
    cut = run_large_linked(command, workload, [4_000], destination / "discarded-cut")
    assert cut["destroy_calls"] == 2 and cut["cleanup_frees"] > 0, "destroy freed the remainder"
    report["destroy_cut"] = {k: cut[k] for k in ("committed_steps", "cleanup_frees",
                                                 "teardown_frees", "peak_cleanup_chain")}

    def reject(fn, message):
        try:
            fn()
        except (AssertionError, ValueError, KeyError, TypeError) as error:
            assert message in str(error), (message, str(error))
            return str(error)
        raise AssertionError("control accepted: " + message)

    small = DiscardedList(12)
    report["controls"]["compiled-stub/physical-leak"] = reject(
        lambda: run_large_linked(command, small, [small.transitions()],
                                 destination / "broken-physical-leak",
                                 env={"ROB_STAGE_B_CONTROL": "physical-leak"}),
        "reported a cell event the storage never performed")
    # A stream that does not follow the approved schedule must be refused, so
    # a candidate cannot quietly send fewer full observations than D151 asks.
    report["controls"]["wrong-observation-period"] = reject(
        lambda: run_large_linked(command, DiscardedList(5_000),
                                 [DiscardedList(5_000).transitions()],
                                 destination / "broken-period", period=5_000),
        "large full-observation schedule")
    # The approved depth is a target, not an authorization to run it.
    report["controls"]["approved-depth-refused"] = reject(
        lambda: run_large_linked(command, DiscardedList(APPROVED_DEPTH), [1],
                                 destination / "refused-approved-depth"),
        "does not authorize running them")
    report["scaling"] = scaling_model(report["runs"])
    (destination / "adapter.json").write_text(json.dumps(report, indent=2) + "\n")
    return report


# Rates measured on the previous full-photograph schedule, recorded in
# evidence/stage-b-01/adapter.json. D159 changes how many rows are written, not
# these two rates, so the projection multiplies them by the new row counts
# instead of refitting them against summaries that no longer vary the chain.
MEASURED_SECONDS_PER_TRANSITION = 3.7326166089756946e-05
MEASURED_SECONDS_PER_SERIALIZED_ROW = 7.632488642638888e-06


def scaling_model(runs):
    """Project both approved workloads with the measured rates and the D159 rows.

    The new runs are recorded so the summary schedule can be seen to execute.
    They are not refit: a summary no longer carries the cleanup chain, so a
    chain-versus-time fit would have nothing to identify.
    """
    projected = {}
    for name, workload_class in sorted(WORKLOADS.items()):
        workload = workload_class(APPROVED_DEPTH)
        cost = workload.schedule_cost(OBSERVATION_PERIOD)
        rows = cost["serialized_rows"]
        from_steps = MEASURED_SECONDS_PER_TRANSITION * workload.transitions()
        from_rows = MEASURED_SECONDS_PER_SERIALIZED_ROW * rows
        projected[name] = dict(
            transitions=workload.transitions(),
            schedule=cost,
            serialized_observation_rows=rows,
            seconds_from_transitions=from_steps,
            seconds_from_observation_rows=from_rows,
            seconds_total=from_steps + from_rows,
            fits_in_600_seconds=from_steps + from_rows <= 600,
            watchdog_seconds=600)
    return dict(measured=[dict(depth=r["depth"], steps=r["committed_steps"],
                               summaries=r["summary_observations"],
                               seconds=r["elapsed_seconds"])
                          for r in runs if r["depth"] >= 20_000],
                seconds_per_transition=MEASURED_SECONDS_PER_TRANSITION,
                seconds_per_serialized_row=MEASURED_SECONDS_PER_SERIALIZED_ROW,
                rate_source="evidence/stage-b-01/adapter.json",
                projection=projected,
                note="Rates from the previous full-photograph runs of this harness. "
                     "Row counts are the D159/D160 schedule. Not a measurement of a candidate.")


def write_effort(destination, started, check_seconds):
    """D152's ledger row: elapsed contributor time, one contributor, no concurrency."""
    stopped = datetime.now(timezone.utc)
    row = dict(
        row="ROB-1333 Stage B acceptance preparation",
        convention="elapsed contributor seconds from explicit start to stop, including tool, "
                   "build and test waits, excluding timestamped owner-wait and stopped periods",
        contributors=1,
        concurrent=False,
        started=None if started is None else started.isoformat(),
        stopped=stopped.isoformat(),
        elapsed_seconds=None if started is None else round((stopped - started).total_seconds(), 3),
        check_run_seconds=round(check_seconds, 3),
        owner_wait_seconds=0,
        note="Earlier preparation and Stage A effort are recorded in their own files and are "
             "not reconstructed here.")
    (destination / "effort.json").write_text(json.dumps(row, indent=2) + "\n")
    return row


def run(destination, binaries, started=None):
    destination = Path(destination)
    destination.mkdir(parents=True, exist_ok=False)
    began = time.monotonic()
    report = dict(passed=False, candidate_executed=False, resource_workload_executed=False,
                  private_corpus_used=False, builder_dispatched=False, stage_b_controls_executed=0)
    try:
        report["inventory"] = stage_b_inventory.run(destination / "inventory")
        report["workloads"] = run_workloads(destination)
        report["projected_records"] = run_projected_records(destination)
        report["adapter"] = run_adapter(destination, binaries)
        report["link"] = stage_b_link.run(destination / "link",
                                          [str(Path(binaries) / "stage_b_call_stub")])
        report["controls"] = stage_b_controls.run(destination / "controls")
        report["delivery"] = stage_b_delivery.run(destination / "delivery")
        for key in ("inventory", "link", "controls", "delivery"):
            assert report[key] is True, key + " did not pass"
        report["passed"] = True
    except Exception:
        report["error"] = traceback.format_exc()
    report["effort"] = write_effort(destination, started, time.monotonic() - began)
    summary = {k: v for k, v in report.items() if k not in ("workloads", "adapter", "projected_records")}
    summary["workload_schedule_comparisons"] = report.get("workloads", {}).get("schedule_comparisons")
    summary["workload_state_comparisons"] = report.get("workloads", {}).get("state_comparisons")
    summary["adapter_runs"] = len(report.get("adapter", {}).get("runs", []))
    (destination / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps(summary, indent=2))
    return report["passed"]


if __name__ == "__main__":
    # Optional third argument: the ISO start of this contributor session, for
    # the D152 ledger. Without it the ledger records the check run only.
    begin = datetime.fromisoformat(sys.argv[3]) if len(sys.argv) > 3 else None
    sys.exit(not run(Path(sys.argv[1]), sys.argv[2], begin))
