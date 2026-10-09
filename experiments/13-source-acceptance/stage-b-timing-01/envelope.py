"""Timing-01 resource predicate; no fabricated elapsed observations.

Non-time checks are copied exactly from closeoutcheck.check_resource: physical
counts, cleanup, provisioning, transition cap and explicit frames are unchanged.
Source/path inspection remains a separate obligation of the supplied verifier.
"""
import math

ENVELOPE_SECONDS = {"non-tail-sum": 1800, "discarded-list": 600}


def check_amended_envelope(row):
    assert row["case"] in ENVELOPE_SECONDS, "resource case"
    assert all(type(row[k]) is int and row[k] >= 0 for k in ("depth", "available_bytes", "stack_bytes", "transitions", "remaining_owned_cells", "peak_explicit_frames")), "resource integer fields"
    assert all(type(n) is int for n in row["evaluation_cell_counts"]), "resource count kinds"
    assert row["status"] == "finished" and row["depth"] == 1000000, "resource completion/depth"
    assert row["answer"] == ("1000000" if row["case"] == "non-tail-sum" else "0"), "resource answer"
    assert row["available_bytes"] >= 4 * 1024 ** 3 and row["stack_bytes"] == 8 * 1024 ** 2, "resource provisioning"
    elapsed = row["elapsed_seconds"]
    assert type(elapsed) in (int, float), "resource elapsed kind"
    assert (type(elapsed) is int or math.isfinite(elapsed)) and 0 <= elapsed <= ENVELOPE_SECONDS[row["case"]], "resource envelope"
    assert row["transitions"] <= 100000000, "resource envelope"
    assert row["evaluation_cell_counts"] == [0, 0, 1000000], "resource physical counts"
    assert row["remaining_owned_cells"] == 0, "resource cleanup"
    if row["case"] == "non-tail-sum": assert row["peak_explicit_frames"] >= 1000000, "resource frame evidence"
    return row
