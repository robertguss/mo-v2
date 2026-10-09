"""Unadopted ownership lookup proposal derived from the performance freeze.

Uses constant-size per-step birth/event expectations, checks actual call events,
and normalizes branch identities as well as bindings and frames. Retained
bookkeeping is bounded by the input depth, not the number of transitions.
The observation schema and explicit host requests are documented in
OBSERVATIONS.md. Every reached deepest boundary must be photographed.

Only the ownership implementation import changes; other predicates stay frozen.
This runner is for small validation only; it still refuses
the million-element workloads. Their 900/600-second limits are unchanged.
"""
from collections import deque
import gzip
import hashlib
import json
import os
from pathlib import Path
import resource
import selectors
import signal
import subprocess
import time

from cleanupcheck import check_destroy
from closeoutcheck import check_resource
from integration import checked, natural, snapshot_schema, tagged
from fast_json import exact, fields, hash_item, load
from linked import available_bytes, check_clock
from predicates import walk
from ownership import state_ownership
from stage_b_workloads import APPROVED_DEPTH, VALIDATION_DEPTH_CAP
from wirecheck import check_public, public_bytes


# D159/D160: full detail at boundaries, summaries on the periodic grid.
# A deliberate pause at the deepest step obtains its required full observation.
# The revised collector explicitly requests each shape; no candidate guessing.
OBSERVATION_PERIOD = 10_000
TRANSITION_CAP = 100_000_000

# What the verifier is allowed to retain, beyond the live cell set: identity
# rows, counters and one committed state. Anything proportional to the number
# of committed actions would defeat the point, so the bound is enforced on
# every row rather than described in a comment.
RETENTION_SLACK = 64

NATIVE_PHASE = {"frontend": "frontend", "pre-run": "frontend", "fixture": "fixture", "begin": "begin",
                "commit": "execution", "advance": "execution", "destroy": "destroy",
                "destroy-again": "destroy", "drop": "destroy", "teardown": "teardown",
                "invalid-fixture": "frontend"}


class BoundedIdentities:
    """Candidate identity to predicted identity, without a retired-ID set.

    The small-case normalizer keeps every retired cell identity forever and
    resolves each one by a linear scan, so it costs time and memory quadratic
    in the number of cells. A large run cannot afford that. Here a cell
    identity is retired by raising a watermark: a later create must use a
    strictly larger identity, which rules out revival without remembering every
    dead one. This is weaker than the small-case check and is reported as such.
    """

    def __init__(self):
        self.binding, self.frame, self.branch = {}, {0: 0}, {}
        self.predicted = {"binding": set(), "frame": {0}, "branch": set()}
        self.watermark = 0
        self.peak = 0

    def note_cell(self, ident):
        assert type(ident) is int and ident >= 0, "cell identity kind"
        self.watermark = max(self.watermark, ident)

    def new_cell(self, ident):
        assert type(ident) is int and ident > self.watermark, "cell lifetime revived"
        self.watermark = ident

    def register(self, domain, raw, predicted):
        table = getattr(self, domain)
        natural(raw)
        assert raw not in table, "identity rebirth"
        assert predicted not in self.predicted[domain], "aliased normalization"
        table[raw] = predicted
        self.predicted[domain].add(predicted)
        self.peak = max(self.peak, len(self.binding) + len(self.frame) + len(self.branch))

    def ident(self, domain, raw):
        table = getattr(self, domain)
        assert raw in table, "unregistered identity"
        return table[raw]

    def value(self, value):
        if value and value[0] == "l" and value[1] is not None:
            return ["l", value[1]]
        return value


class LargeVerifier:
    """Streaming checker for one large workload run. Retains no row history."""

    def __init__(self, workload, budgets, *, period=OBSERVATION_PERIOD):
        self.workload = workload
        self.budgets = list(budgets)
        self.period = period
        self.case = workload.case()
        self.ids = BoundedIdentities()
        self.step = 0
        self.event_end = 0
        self.cursor = [0, 0, 0, 0]
        self.clock = 0
        self.live = {}
        self.attempts = {}
        self.denials = []
        self.cell_counts = {"create": 0, "write": 0, "free": 0}
        self.cleanup_frees = 0
        self.teardown_frees = 0
        self.pending_native = deque()
        self.pending_logical = deque()
        self.peak_frames = 0
        self.peak_live = 0
        self.peak_release = 0
        self.full_observations = 0
        self.summary_observations = 0
        self.deepest_photographed = False
        self.last_observation_step = 0
        self.streamed_commits = 0
        self.peak_retained = 0
        self.births_registered = 0
        self.birth_digest = hashlib.sha256()
        self.event_digest = hashlib.sha256()
        self.advance_index = 0
        self.advance_start = 0
        self.destroyed = 0
        self.ended = False
        self.seen_check = self.seen_fixture = self.seen_begin = False
        self.last_state = None
        self.last_pointers = None
        self.last_cleanup = 0
        self.status = None
        self.installed = 0

    # --- retention ---------------------------------------------------------
    def retained(self):
        """Rows this verifier is holding on to right now."""
        state = self.last_state or {}
        return (len(self.case["cells"]) + len(self.live)
                + 2 * (len(self.ids.binding) + len(self.ids.frame) + len(self.ids.branch))
                + len(self.last_pointers or {}) + len(state.get("memory", []))
                + len(state.get("bindings", [])) + len(state.get("frames", [])))

    def check_retention(self):
        # Sum retains three bindings, one frame and one branch per level,
        # plus inverse identity sets, the fixture and full-boundary state.
        # This bounds verifier bookkeeping, not the candidate's resource limit.
        limit = 16 * self.workload.depth + RETENTION_SLACK
        self.peak_retained = max(getattr(self, "peak_retained", 0), self.retained())
        assert self.peak_retained <= limit, "verifier retention grew beyond the live set"

    # --- schedule ----------------------------------------------------------
    def commit_observation(self, step):
        """What a committed step must carry.

        `summary` is every periodic step. `none` carries metadata/events only.
        Start, pause, failure, finish and cleanup are phase boundaries and are
        full photographs whether or not the step is on the grid. The deepest
        step is always requested as a pause boundary, including grid collisions.
        """
        if step % self.period == 0:
            return "summary"
        return "none"

    # --- physical accounting ----------------------------------------------
    def apply_native(self, rows, phase):
        for kind, ident, pointer, tagged_phase in rows:
            assert tagged_phase == phase, "native event phase"
            natural(ident)
            assert type(pointer) is int and pointer > 0, "native pointer"
            if kind == "fixture":
                assert ident not in self.live, "fixture identity reused"
                self.ids.note_cell(ident)
                self.live[ident] = pointer
                self.installed += 1
            elif kind == "create":
                self.ids.new_cell(ident)
                assert ident not in self.live, "physical identity recycled"
                assert pointer not in self.live.values(), "physical alias"
                self.live[ident] = pointer
                self.cell_counts["create"] += 1
            elif kind == "write":
                assert self.live.get(ident) == pointer, "physical continuity"
                self.cell_counts["write"] += 1
            else:
                assert kind == "free", "physical event kind"
                assert self.live.get(ident) == pointer, "physical continuity"
                del self.live[ident]
                if phase == "execution":
                    self.cell_counts["free"] += 1
                elif phase == "destroy":
                    self.cleanup_frees += 1
                else:
                    self.teardown_frees += 1
            if phase == "execution":
                self.pending_native.append([kind, ident])
        self.peak_live = max(self.peak_live, len(self.live))

    def match_events(self):
        """The candidate's reported cell events must be the ones that happened.

        Both streams are consumed in order and dropped, so claiming a free that
        the storage never performed is rejected at the step it is claimed, not
        inferred later from a state that happens to disagree.
        """
        while self.pending_native and self.pending_logical:
            native = self.pending_native.popleft()
            logical = self.pending_logical.popleft()
            assert native == logical, "logical/native cell event disagreement"

    def check_graph(self, graph):
        """The observed graph must be exactly the incrementally derived live set."""
        assert len(graph) == len(self.live), "observed/derived live cell count"
        memory = []
        for cell in graph:
            assert type(cell) is list and len(cell) == 6, "native cell row"
            ident, item, tail, holders, status, pointer = cell
            natural(ident)
            tagged(["n", item])
            if tail is not None:
                natural(tail)
            natural(holders)
            assert status in ("live", "aside") and type(pointer) is int and pointer > 0, "native cell status/pointer"
            assert self.live.get(ident) == pointer, "physical graph/event continuity"
            memory.append([ident, item, tail, holders, status])
        return memory

    # --- full observation ---------------------------------------------------
    def check_full(self, snapshot, memory, *, terminal_expected=None):
        predicted = self.workload.row(self.step) if self.step else self.initial_row()
        assert snapshot["step"] == self.step, "snapshot committed step"
        assert snapshot["failure"] is None, "unexpected large failure"
        assert not snapshot["cleanup_events"], "cleanup before destroy"
        for key, count, digest in (("births", self.births_registered, self.birth_digest),
                                   ("events", self.event_end, self.event_digest)):
            assert len(snapshot[key]) == count, key + " prefix length"
            observed = hashlib.sha256()
            for item in snapshot[key]:
                self.hash_item(observed, item)
            assert observed.digest() == digest.digest(), key + " prefix rewritten"
        state = dict(snapshot["state"], memory=memory, outside=list(self.case["outside"]))
        state["bindings"] = [[self.ids.ident("binding", i), n, self.ids.value(v), s]
                             for i, n, v, s in snapshot["state"]["bindings"]]
        state["frames"] = [self.ids.ident("frame", f) for f in snapshot["state"]["frames"]]
        state["aside"] = [[self.ids.ident("branch", b), c] for b, c in snapshot["state"]["aside"]]
        control = []
        for row in snapshot["control"]:
            control.append(dict(row, invocation=self.ids.ident("frame", row["invocation"]),
                                scope=[[name, self.ids.ident("binding", i)] for name, i in row["scope"]]))
        exact(state, predicted["state"], "large full committed state")
        exact(control, predicted["control"], "large control stack")
        exact(snapshot["ready"], predicted["ready"], "large ready value")
        exact(snapshot["release"], predicted["release"], "large cleanup chain")
        assert snapshot["event_end"] == predicted["event_end"] == self.event_end, "large event prefix"
        # Frozen ownership and outside-value protection, unchanged.
        state_ownership(state)
        for root in self.case["outside"]:
            walk(state["memory"], root)
        self.peak_frames = max(self.peak_frames, len(state["frames"]))
        self.peak_release = max(self.peak_release, len(snapshot["release"]))
        self.full_observations += 1
        if self.step == self.workload.deepest_step():
            self.deepest_photographed = True
        if terminal_expected is not None:
            assert snapshot["status"] == terminal_expected, "large terminal classification"
        self.last_state = state
        self.last_observation_step = self.step
        return state

    def check_summary(self, snapshot, row):
        """D159/D160 between-boundary record. The chain body is not kept."""
        summary_schema(snapshot)
        assert snapshot["step"] == self.step, "summary committed step"
        assert snapshot["depth"] == self.workload.frames(self.step), "summary depth"
        assert snapshot["live_cells"] == self.workload.live_cells(self.step) == len(self.live), \
            "summary live cells"
        counts = [snapshot["counts"]["create"], snapshot["counts"]["write"], snapshot["counts"]["free"]]
        assert counts == self.workload.cell_counts_at(self.step), "summary cell counts"
        assert counts == [self.cell_counts["create"], self.cell_counts["write"], self.cell_counts["free"]], \
            "summary counts disagree with the cell operations"
        exact(snapshot["changed_cells"], self.workload.changed_cells(self.last_observation_step, self.step),
              "summary changed cells")
        assert snapshot["cleanup_chain_length"] == self.workload.chain_length(self.step), "summary chain length"
        assert row["graph"] is None, "summary must not serialize a full graph"
        self.summary_observations += 1
        self.peak_release = max(self.peak_release, snapshot["cleanup_chain_length"])
        self.peak_frames = max(self.peak_frames, snapshot["depth"])
        self.last_observation_step = self.step

    def initial_row(self):
        case = self.case
        bindings = [[i, n, v, "holding" if v[0] == "l" and v[1] is not None else "noHolder"]
                    for i, (n, v) in enumerate(case["inputs"])]
        return dict(step=0, event_end=0, control=[], ready=None, release=[],
                    state=dict(kind=None, memory=[list(c) for c in case["cells"]],
                               outside=list(case["outside"]), bindings=bindings,
                               pending=[], aside=[], branch=None, frames=[]))

    @staticmethod
    def hash_item(digest, item):
        hash_item(digest, item)

    def register_births(self, rows):
        predicted = self.workload.births_at(self.step)
        assert type(rows) is list and len(rows) == len(predicted), "birth coverage"
        for row, want in zip(rows, predicted):
            fields(row, "domain id origin invocation")
            assert row["domain"] == want["domain"] and row["origin"] == want["origin"], "birth origin/domain/order"
            assert self.ids.ident("frame", row["invocation"]) == want["invocation"], "birth owning invocation"
            self.ids.register(want["domain"], row["id"], want["id"])
            self.hash_item(self.birth_digest, row)
            self.births_registered += 1

    def normalize_event(self, event):
        assert type(event) is list and event, "event shape"
        if event[0] in ("create", "write", "free"):
            assert len(event) == 2, "cell event fields"
            natural(event[1])
            return event
        if event[0] == "enter":
            assert len(event) == 5, "enter fields"
            return ["enter", self.ids.ident("frame", event[1]),
                    self.ids.ident("frame", event[2]), event[3], event[4]]
        assert event[0] == "return" and len(event) == 3, "return fields"
        tagged(event[2])
        return ["return", self.ids.ident("frame", event[1]), event[2]]

    # --- the row loop -------------------------------------------------------
    def row(self, row):
        assert not self.ended, "evidence after process completion"
        phase = row["phase"]
        if phase == "check":
            assert not self.seen_check, "repeated frontend check"
            checked(self.case["source"], row["checked"], row["spans"], "B")
            self.seen_check = True
            return dict(status="install")
        fields(row, "phase elapsed_ns step raw graph outside from to events mutations resources creates")
        natural(row["step"])
        natural(row["elapsed_ns"])
        assert row["elapsed_ns"] >= self.clock, "phase clock went backwards"
        self.clock = row["elapsed_ns"]
        exact(row["outside"], self.case["outside"], "host external roots")
        exact(row["from"], self.cursor, "native cursor continuity")
        for i, key in enumerate(("events", "mutations", "resources", "creates")):
            natural(row["to"][i])
            assert row["to"][i] == self.cursor[i] + len(row[key]), "native cursor length"
        self.cursor = list(row["to"])
        self.check_retention()
        native_phase = NATIVE_PHASE[phase]
        self.apply_native(row["events"], native_phase)
        for event in row["mutations"]:
            assert len(event) == 4 and event[3] == native_phase, "native mutation phase"
        for domain, ordinal, allowed, tagged_phase in row["resources"] + [["cell", *a] for a in row["creates"]]:
            assert domain in ("number", "frame", "cell") and type(allowed) is bool, "resource domain"
            assert tagged_phase == native_phase, "resource phase"
            self.attempts[domain] = self.attempts.get(domain, 0) + 1
            assert ordinal == self.attempts[domain], "resource ordinal continuity"
            if not allowed:
                self.denials.append([domain, ordinal])
        assert not self.denials, "large run requested no allocation denial"
        return getattr(self, "phase_" + phase.replace("-", "_"))(row)

    def phase_frontend(self, row):
        assert self.seen_check and row["graph"] == [] and row["step"] == 0, "frontend managed effects"

    def phase_fixture(self, row):
        assert self.seen_check and not self.seen_fixture and row["step"] == 0, "fixture phase order"
        graph = row["graph"]
        assert len(graph) == self.workload.depth, "installed fixture size"
        assert self.installed == self.workload.depth, "fixture construction count"
        for index, cell in enumerate(sorted(graph, key=lambda c: c[0])):
            assert cell[:5] == self.workload.cell_row(index), "installed actual fixture"
        self.check_graph(graph)
        self.seen_fixture = True

    def phase_begin(self, row):
        assert self.seen_fixture and not self.seen_begin and row["step"] == 0, "begin phase order"
        snapshot = load(row["raw"]["snapshot"])
        snapshot_schema(snapshot)
        self.register_births(snapshot["births"])
        memory = self.check_graph(row["graph"])
        self.check_full(snapshot, memory, terminal_expected="suspended")
        check_public(row["raw"]["public"].encode(), public_bytes(dict(status="suspended", steps="0")))
        self.last_pointers = dict(self.live)
        self.seen_begin = True

    def phase_commit(self, row):
        assert self.seen_begin and not self.destroyed, "callback outside execution"
        meta = load(row["raw"]["metadata"])
        fields(meta, "step transition site event_end landmark events_added births_added")
        natural(meta["step"])
        natural(meta["event_end"])
        assert meta["step"] == self.step + 1, "callback step continuity"
        self.step = meta["step"]
        assert self.step <= TRANSITION_CAP, "committed transition cap"
        assert self.step <= self.workload.transitions(), "committed actions beyond the predicted schedule"
        for key in ("transition", "site", "landmark"):
            assert meta[key] == getattr(self.workload, key)(self.step), "large " + key
        self.register_births(meta["births_added"])
        self.event_end += len(meta["events_added"])
        assert meta["event_end"] == self.event_end == self.workload.event_end(self.step), "large event prefix"
        exact([self.normalize_event(e) for e in meta["events_added"]],
              self.workload.events_at(self.step), "large call/cell events")
        for event in meta["events_added"]:
            self.hash_item(self.event_digest, event)
            if event[0] in ("create", "write", "free"):
                self.pending_logical.append(list(event))
        self.match_events()
        assert not self.pending_logical, "reported a cell event the storage never performed"
        self.streamed_commits += 1
        kind = self.commit_observation(self.step)
        snapshot_raw = row["raw"]["snapshot"]
        if kind == "none":
            assert row["graph"] is None and snapshot_raw is None, "large full-observation schedule"
            return
        assert snapshot_raw is not None, "large full-observation schedule"
        snapshot = load(snapshot_raw)
        if kind == "summary":
            assert snapshot.get("observation") == "summary", "large full-observation schedule"
            self.check_summary(snapshot, row)
            return
        assert row["graph"] is not None, "large full-observation schedule"
        snapshot_schema(snapshot)
        assert snapshot["step"] == self.step, "snapshot committed step"
        memory = self.check_graph(row["graph"])
        self.check_full(snapshot, memory)

    def phase_advance(self, row):
        assert self.advance_index < len(self.budgets), "extra advance"
        budget = self.budgets[self.advance_index]
        assert self.step - self.advance_start <= budget, "advance overshot budget"
        snapshot = load(row["raw"]["snapshot"])
        snapshot_schema(snapshot)
        assert snapshot["step"] == self.step, "snapshot committed step"
        memory = self.check_graph(row["graph"])
        terminal = self.step == self.workload.transitions()
        state = self.check_full(snapshot, memory,
                                terminal_expected="finished" if terminal else "suspended")
        if snapshot["status"] == "suspended":
            assert self.step - self.advance_start == budget, "advance undershot budget"
            expected = dict(status="suspended", steps=str(self.step))
        else:
            value = snapshot["ready"]
            assert value == ["n", self.workload.expected_answer()], "large independent answer"
            expected = dict(status="finished", type="Int", value=value[1])
        check_public(row["raw"]["public"].encode(), public_bytes(expected))
        self.advance_index += 1
        self.advance_start = self.step
        self.status = snapshot["status"]
        self.last_pointers = dict(self.live)
        self.last_state = state

    def _destroy(self, row, index):
        assert self.advance_index == len(self.budgets), "missing budget calls"
        snapshot = load(row["raw"]["snapshot"])
        snapshot_schema(snapshot)
        before = self.last_state
        before_pointers = dict(self.last_pointers)
        memory = self.check_graph(row["graph"])
        after = dict(snapshot["state"], memory=memory, outside=list(self.case["outside"]))
        after["bindings"] = [[self.ids.ident("binding", i), n, self.ids.value(v), s]
                             for i, n, v, s in snapshot["state"]["bindings"]]
        after["frames"] = [self.ids.ident("frame", f) for f in snapshot["state"]["frames"]]
        assert snapshot["control"] == [] and snapshot["ready"] is None and snapshot["release"] == [], \
            "destroy execution temporaries"
        assert snapshot["event_end"] == self.event_end, "destroy altered committed event prefix"
        events = [[kind, ident] for kind, ident in snapshot["cleanup_events"]]
        new_events = events[self.last_cleanup:]
        check_destroy(before, after, new_events, before_pointers, dict(self.live))
        self.last_cleanup = len(events)
        self.last_state = after
        self.last_pointers = dict(self.live)
        self.destroyed = index + 1
        state_ownership(after)

    def phase_destroy(self, row):
        assert self.destroyed == 0, "destroy ordering"
        self._destroy(row, 0)

    def phase_destroy_again(self, row):
        assert self.destroyed == 1, "repeated destroy ordering"
        self._destroy(row, 1)

    def phase_drop(self, row):
        assert self.destroyed == 2, "missing repeated destroy"
        assert not row["events"] and not row["mutations"], "Drop cell effects"
        self.check_graph(row["graph"])

    def phase_teardown(self, row):
        assert self.destroyed == 2, "missing repeated destroy"
        assert row["graph"] == [] and not self.live, "host teardown leak"
        self.ended = True

    def phase_pre_run(self, row):
        raise AssertionError("large workload source was refused before the run")

    def phase_invalid_fixture(self, row):
        raise AssertionError("large workload fixture was rejected")

    # --- the D151 record ----------------------------------------------------
    def resource_record(self, *, elapsed_seconds, available, stack_bytes):
        return self.workload.resource_record(
            status="finished" if self.status == "finished" else "suspended",
            answer=self.workload.expected_answer(),
            available_bytes=available, stack_bytes=stack_bytes,
            elapsed_seconds=elapsed_seconds, transitions=self.step,
            evaluation_cell_counts=[self.cell_counts["create"], self.cell_counts["write"],
                                    self.cell_counts["free"]],
            remaining_owned_cells=len(self.live),
            peak_explicit_frames=self.peak_frames)

    def finish(self):
        assert self.ended, "incomplete process evidence"
        if self.step >= self.workload.deepest_step():
            assert self.deepest_photographed, "missing deepest full observation"
        assert not self.live, "cells remained after host teardown"
        assert not self.pending_native and not self.pending_logical, "unmatched cell events"
        return dict(committed_steps=self.step, advances=self.advance_index,
                    destroy_calls=self.destroyed, full_observations=self.full_observations,
                    summary_observations=self.summary_observations,
                    deepest_photographed=self.deepest_photographed,
                    streamed_commits=self.streamed_commits,
                    evaluation_cell_counts=[self.cell_counts["create"], self.cell_counts["write"],
                                            self.cell_counts["free"]],
                    cleanup_frees=self.cleanup_frees, teardown_frees=self.teardown_frees,
                    peak_live_cells=self.peak_live, peak_explicit_frames=self.peak_frames,
                    peak_cleanup_chain=self.peak_release,
                    peak_identity_rows=self.ids.peak, peak_retained_rows=self.peak_retained,
                    retained_rows_at_end=self.retained(), resource_attempts=self.attempts)


# D162 amends D151's clock for the recursive sum only. The discard stays at
# 600 seconds. The per-step record is unchanged. The frozen predicate in
# closeoutcheck.check_resource still requires 600 seconds for both workloads;
# that file is not edited. This map is the package's envelope.
ENVELOPE_SECONDS = {"discarded-list": 600, "non-tail-sum": 900}


def projected_record(workload, *, elapsed_seconds, available_bytes, stack_bytes=8 * 1024 ** 2):
    """The record the adapter would emit, built from the closed form alone.

    At the approved depth this can be handed to `check_amended_envelope`
    without running anything. The frozen `closeoutcheck.check_resource` still
    encodes D151's 600-second clock for both workloads and is not this
    envelope.
    """
    return workload.resource_record(
        status="finished", answer=workload.expected_answer(),
        available_bytes=available_bytes, stack_bytes=stack_bytes,
        elapsed_seconds=elapsed_seconds, transitions=workload.transitions(),
        evaluation_cell_counts=workload.expected_cell_counts(),
        remaining_owned_cells=0, peak_explicit_frames=workload.expected_peak_frames())


def observation_count(workload, period=OBSERVATION_PERIOD):
    """D159/D160 observations for one completing run, and the rows they contain."""
    cost = workload.schedule_cost(period)
    return dict(summaries=cost["summary_observations"], begin=1, deepest=1, finish=1,
                cleanup_boundaries=4, serialized_rows=cost["serialized_rows"],
                deepest_step=cost["deepest_step"])


def summary_schema(snapshot):
    """The between-boundary record. It has no state, no chain and no event prefix."""
    fields(snapshot, "observation step depth live_cells counts changed_cells cleanup_chain_length")
    assert snapshot["observation"] == "summary", "summary observation kind"
    natural(snapshot["step"])
    natural(snapshot["depth"])
    natural(snapshot["live_cells"])
    natural(snapshot["cleanup_chain_length"])
    fields(snapshot["counts"], "create write free")
    for key in ("create", "write", "free"):
        natural(snapshot["counts"][key])
    for ident in snapshot["changed_cells"]:
        natural(ident)


def run_large_linked(command, workload, budgets, destination, *, env=None, timeout=600,
                     keep_rows=False, period=OBSERVATION_PERIOD, fixture_stub=False):
    """Stream one large run under a single inclusive watchdog.

    The clock covers process launch, the frontend exchange, fixture installation,
    every observation, both destroys, host teardown, process exit and the final
    checks, exactly as `linked.run_linked` does for small cases. Rows are
    verified as they arrive and then dropped; only `keep_rows` writes them out,
    and then compressed, because a large run's rows do not fit comfortably on
    disk uncompressed.
    """
    assert workload.depth < APPROVED_DEPTH, (
        "D151 fixes the million-cell workloads and does not authorize running them")
    assert workload.depth <= VALIDATION_DEPTH_CAP, "adapter validation depth cap"
    verifier = LargeVerifier(workload, budgets, period=period)
    destination = Path(destination)
    destination.mkdir(parents=True, exist_ok=False)
    # Validation runs only. The approved recursive sum's envelope is 900 seconds
    # and the discard's is 600 (D162); this function refuses both approved depths.
    assert 0 < timeout <= 600, "validation watchdog range"
    case = workload.case()
    source = case["source"].encode() if isinstance(case["source"], str) else case["source"]
    memory = available_bytes()
    previous_handler = signal.getsignal(signal.SIGALRM)
    assert signal.getitimer(signal.ITIMER_REAL) == (0.0, 0.0), "watchdog already owned"

    def expired(*_):
        raise TimeoutError("inclusive watchdog")

    def stack_limit():
        _, hard = resource.getrlimit(resource.RLIMIT_STACK)
        resource.setrlimit(resource.RLIMIT_STACK, (8 * 1024 ** 2, hard))

    proc = None
    phase_count = 0
    start = time.monotonic_ns()
    boundary = start
    phase = "launch"
    report = dict(passed=False, candidate_executed=False, fixture_stub=fixture_stub, large=True,
                  workload=workload.name, depth=workload.depth, available_bytes=memory,
                  stack_bytes=8 * 1024 ** 2, observation_period=period)
    rows_file = gzip.open(destination / "rows.jsonl.gz", "wb") if keep_rows else None
    signal.signal(signal.SIGALRM, expired)
    signal.setitimer(signal.ITIMER_REAL, timeout)
    try:
        with (destination / "stderr.txt").open("wb") as errors:
            proc = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=errors,
                                    env=dict(os.environ, **(env or {})), preexec_fn=stack_limit)
            report["candidate_executed"] = not fixture_stub
            payload = dict(source=list(source), cells=case["cells"], inputs=case["inputs"],
                           outside=case["outside"], budgets=budgets, large=True, deny=None)
            proc.stdin.write(json.dumps(payload).encode() + b"\n")
            proc.stdin.flush()
            pending = b""
            selector = selectors.DefaultSelector()
            selector.register(proc.stdout, selectors.EVENT_READ)
            try:
                while True:
                    if not selector.select(timeout):
                        raise TimeoutError("inclusive watchdog")
                    block = os.read(proc.stdout.fileno(), 1 << 20)
                    if not block:
                        break
                    pending += block
                    while b"\n" in pending:
                        line, pending = pending.split(b"\n", 1)
                        if rows_file is not None:
                            rows_file.write(line + b"\n")
                        record = load(line)
                        now = time.monotonic_ns()
                        # Validate each contiguous clock segment immediately;
                        # do not retain one dictionary per committed action.
                        check_clock(boundary, now, [dict(phase=phase, start_ns=boundary, end_ns=now)],
                                    int(timeout * 1_000_000_000))
                        assert now - start <= int(timeout * 1_000_000_000), "inclusive watchdog"
                        phase_count += 1
                        boundary = now
                        phase = record["phase"]
                        answer = verifier.row(record)
                        del record
                        if answer is not None:
                            proc.stdin.write(json.dumps(answer).encode() + b"\n")
                            proc.stdin.flush()
                assert not pending, "partial driver record"
                _, status, usage = os.wait4(proc.pid, 0)
                proc.returncode = os.waitstatus_to_exitcode(status)
                report.update(exit_code=proc.returncode, peak_rss_kib=usage.ru_maxrss)
                assert proc.returncode == 0, "linked process abnormal termination"
                report.update(verifier.finish())
            finally:
                selector.close()
        stop = time.monotonic_ns()
        check_clock(boundary, stop, [dict(phase=phase, start_ns=boundary, end_ns=stop)],
                    int(timeout * 1_000_000_000))
        assert stop - start <= int(timeout * 1_000_000_000), "inclusive watchdog"
        phase_count += 1
        elapsed_seconds = (stop - start) / 1_000_000_000
        record = verifier.resource_record(elapsed_seconds=elapsed_seconds, available=memory,
                                          stack_bytes=8 * 1024 ** 2)
        report.update(passed=True, elapsed_ns=stop - start, elapsed_seconds=elapsed_seconds,
                      phase_count=phase_count, scaled_resource_record=record,
                      verifier_peak_kib=resource.getrusage(resource.RUSAGE_SELF).ru_maxrss)
    except BaseException as error:
        report.update(error=f"{type(error).__name__}: {error}",
                      elapsed_ns=time.monotonic_ns() - start, phase_count=phase_count)
        raise
    finally:
        signal.setitimer(signal.ITIMER_REAL, 0)
        signal.signal(signal.SIGALRM, previous_handler)
        if rows_file is not None:
            rows_file.close()
        if proc is not None:
            if proc.returncode is None:
                proc.kill()
                proc.wait()
            if proc.stdin:
                proc.stdin.close()
            if proc.stdout:
                proc.stdout.close()
        (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    return report


def check_amended_envelope(row):
    """Accept a finished approved-depth record under D162's clock.

    A recursive-sum record may take up to 900 seconds. A discard record may
    take up to 600. Every other field is still the frozen D151 predicate.
    That frozen predicate rejects a clock over 600, so a sum record inside the
    new limit and over 600 is shown to it with the clock set to the older
    limit, and only after the new limit has already been enforced here.
    """
    assert row["case"] in ENVELOPE_SECONDS, "resource case"
    limit = ENVELOPE_SECONDS[row["case"]]
    elapsed = row["elapsed_seconds"]
    assert type(elapsed) in (int, float) and 0 <= elapsed <= limit, "resource envelope"
    frozen = dict(row)
    if elapsed > 600:
        frozen["elapsed_seconds"] = 600
    check_resource(frozen)
    return row


def check_projected_record(workload):
    """The amended envelope must accept the projected approved-depth record."""
    assert workload.depth == APPROVED_DEPTH, "projection is for the approved depth"
    record = projected_record(workload, elapsed_seconds=0, available_bytes=4 * 1024 ** 3)
    check_amended_envelope(record)
    return record
