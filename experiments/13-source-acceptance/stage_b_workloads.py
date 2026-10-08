"""Closed-form schedules for the two D151 workloads. Nothing here runs them.

The frozen `TransitionReference` predicts a complete trace by walking the whole
program with host recursion. At a million cells it cannot be used: it would hold
every committed state in memory and recurse a million frames deep. So the two
approved workloads get a *rule* instead of a materialised trace: the transition
at step k, and the full state at step k, are computed on demand in constant or
live-set time.

The rules are validated by exact equality against the frozen reference at small
depths. That is the only thing that makes them trustworthy: they are not a
second opinion about Mo, they are a compression of the existing prediction.

D151 approves the two workloads and their observation schedule. It does not
authorize running them. `stage_b_large` refuses any depth above
`VALIDATION_DEPTH_CAP` so an adapter test cannot become an unauthorized run.
"""
from copy import deepcopy

from cases import fixture
from integration import Origins
from syntax import check, parse


# Adapter validation runs far below the approved million-cell workloads. A run
# at or above the approved depth needs separate owner authorization (D151 picks
# the targets; it explicitly does not authorize execution).
VALIDATION_DEPTH_CAP = 200_000
APPROVED_DEPTH = 1_000_000

NON_TAIL_SUM_SOURCE = (
    "input xs: ListInt; "
    "def total(xs: ListInt): Int = match xs do [] -> 0; [h | t] -> h + total(t) end end "
    "main = total(xs)"
)
DISCARDED_LIST_SOURCE = "input xs: ListInt; main = 0"


def million_cells_of_one(depth):
    """D151's fixture: `depth` unique cells each containing 1, no outside root."""
    return fixture([1] * depth)


class Workload:
    """A workload names its source, its fixture rule and its closed-form schedule.

    `state(step)` returns the predicted committed state in the same shape the
    frozen reference produces, so the frozen ownership and protection predicates
    apply unchanged. Memory is materialised only for the cells still live at
    that step, never for the whole history.
    """

    name = None
    source = None
    states_implemented = True

    def __init__(self, depth):
        assert type(depth) is int and depth >= 0, "workload depth"
        self.depth = depth

    # --- fixture -----------------------------------------------------------
    def cell_row(self, index):
        """One installed fixture row, so a large fixture is checked streamingly."""
        assert 0 <= index < self.depth, "fixture index"
        return [index + 1, "1", index + 2 if index + 1 < self.depth else None, 1, "live"]

    def cells(self):
        return [self.cell_row(i) for i in range(self.depth)]

    def births(self):
        """Predicted births, in order. Only workloads with a bounded set qualify."""
        raise NotImplementedError

    def inputs(self):
        return [("xs", ["l", 1 if self.depth else None])]

    def outside(self):
        return []

    def case(self):
        return dict(source=self.source, cells=self.cells(), inputs=self.inputs(), outside=self.outside())

    # --- closed form -------------------------------------------------------
    def transitions(self):
        raise NotImplementedError

    def transition(self, step):
        raise NotImplementedError

    def state(self, step):
        raise NotImplementedError

    def event_end(self, step):
        raise NotImplementedError

    def landmark(self, step):
        raise NotImplementedError

    def site(self, step):
        raise NotImplementedError

    # --- the record D151 and frozen closeoutcheck.check_resource expect ----
    def resource_record(self, *, status, answer, available_bytes, stack_bytes,
                        elapsed_seconds, transitions, evaluation_cell_counts,
                        remaining_owned_cells, peak_explicit_frames):
        return dict(case=self.name, status=status, depth=self.depth, answer=answer,
                    available_bytes=available_bytes, stack_bytes=stack_bytes,
                    elapsed_seconds=elapsed_seconds, transitions=transitions,
                    evaluation_cell_counts=evaluation_cell_counts,
                    remaining_owned_cells=remaining_owned_cells,
                    peak_explicit_frames=peak_explicit_frames)

    def expected_answer(self):
        raise NotImplementedError

    def expected_cell_counts(self):
        """Creates, writes, frees during evaluation; fixture/destroy excluded."""
        return [0, 0, self.depth]

    def expected_peak_frames(self):
        raise NotImplementedError

    def row(self, step):
        """Everything the frozen reference records for one committed action."""
        return dict(step=step, transition=self.transition(step), site=self.site(step),
                    event_end=self.event_end(step), landmark=self.landmark(step),
                    state=self.state(step), control=self.control(step),
                    ready=self.ready(step), release=self.release(step))


class DiscardedList(Workload):
    """`main = 0` with a `depth`-cell input: every cell is released unused.

    Entry cleanup gives up the input holder and frees the head, which releases
    the next cell, and so on. Two committed actions per cell, then the ordinary
    three-action evaluation of the literal 0.
    """

    name = "discarded-list"
    source = DISCARDED_LIST_SOURCE

    def transitions(self):
        return 3 + 2 * self.depth

    def transition(self, step):
        if step <= 2 * self.depth:
            return "Give up holder" if step % 2 else "Free cell"
        return ("Start", "Leaf", "Finish")[step - 2 * self.depth - 1]

    def site(self, step):
        return "main" if step == 2 * self.depth + 2 else "root"

    def event_end(self, step):
        return min(step // 2, self.depth)

    def landmark(self, step):
        if step <= 2 * self.depth:
            return step - 1
        return {1: 2 * self.depth, 2: None, 3: 2 * self.depth + 1}[step - 2 * self.depth]

    def _binding(self, step):
        if not self.depth:
            return [[0, "xs", ["l", None], "noHolder"]]
        return [[0, "xs", ["l", 1], "holding" if step == 0 else "givenUp"]]

    def memory(self, step):
        """Cells still allocated after `step`. Linear in the live set only."""
        if step == 0:
            return self.cells()
        if step > 2 * self.depth:
            return []
        freed = step // 2
        rows = [[i + 1, "1", i + 2 if i + 1 < self.depth else None, 1, "live"]
                for i in range(freed, self.depth)]
        if step % 2 and rows:
            rows[0] = [rows[0][0], "1", rows[0][2], 0, "live"]
        return rows

    def state(self, step):
        kind = None
        if step and step <= 2 * self.depth:
            kind = "holderGivenUp" if step % 2 else "cellFreed"
        elif step == 2 * self.depth + 1:
            kind = "start"
        elif step == 2 * self.depth + 3:
            kind = "end"
        pending = []
        if step and step <= 2 * self.depth and step % 2 == 0 and step // 2 < self.depth:
            pending = [["l", step // 2 + 1]]
        return dict(kind=kind, memory=self.memory(step), bindings=self._binding(step),
                    pending=pending, outside=[], aside=[], branch=None, frames=[])

    def control(self, step):
        if step == 2 * self.depth + 2:
            return [dict(site="main", scope=[["xs", 0]], invocation=0, operands=[])]
        return []

    def ready(self, step):
        return ["n", "0"] if step >= 2 * self.depth + 2 else None

    def release(self, step):
        """The cleanup chain still being released, oldest first.

        This grows with the number of cells released so far, so a committed
        state near the end of the approved workload carries a chain of up to
        one million identities. That is a property of the approved contract,
        not of this rule; see STAGE_B_PREPARATION.md, open choice 1.
        """
        if step == 0 or step > 2 * self.depth:
            return []
        return list(range(1, (step + 1) // 2 + 1))

    def births(self):
        """One input binding, whatever the depth. No frame or cell is born."""
        return [dict(domain="binding", id=0, origin="input/0", invocation=0)]

    def expected_answer(self):
        return "0"

    def expected_peak_frames(self):
        return 0


class NonTailSum(Workload):
    """`total(xs)` summing `depth` cells of 1 without a tail call.

    A four-action prologue, one twelve-action descent per cell, an eight-action
    base case, one six-action ascent per cell, and a two-action epilogue.

    The committed state here grows with the depth: at the bottom of the
    recursion the control stack, the frame list and the binding list all have
    one row per level. `state_shape` reports those sizes without building the
    state, because the serialization of a committed state that large is one of
    the choices still open for owner approval.
    """

    name = "non-tail-sum"
    source = NON_TAIL_SUM_SOURCE
    states_implemented = False

    PROLOGUE = [("Start", "root"), ("Dispatch compound", "main"), ("Leaf", "main/0"),
                ("Operand capture", "main")]
    DESCENT = [("Enter", None), ("Dispatch compound", "function/0/body"), ("Leaf", "function/0/body/0"),
               ("Choose branch", "function/0/body"), ("Match decompose", "function/0/body"),
               ("Branch start", "function/0/body"), ("Dispatch compound", "function/0/body/2"),
               ("Leaf", "function/0/body/2/0"), ("Operand capture", "function/0/body/2"),
               ("Dispatch compound", "function/0/body/2/1"), ("Leaf", "function/0/body/2/1/0"),
               ("Operand capture", "function/0/body/2/1")]
    BASE = [("Enter", None), ("Dispatch compound", "function/0/body"), ("Leaf", "function/0/body/0"),
            ("Choose branch", "function/0/body"), ("Branch start", "function/0/body"),
            ("Leaf", "function/0/body/1"), ("Branch result/cleanup", "function/0/body"),
            ("Handoff", "function/0/body")]
    ASCENT = [("Return", "function/0/body/2/1"), ("Operand capture", "function/0/body/2"),
              ("Primitive result", "function/0/body/2"), ("Branch result/cleanup", "function/0/body"),
              ("Free cell", "function/0/body"), ("Handoff", "function/0/body")]
    EPILOGUE = [("Return", "main"), ("Finish", "root")]

    # Positions inside each block that carry a historical landmark. The two
    # conditional ones depend on whether the list being read is still nonempty.
    DESCENT_LANDMARKS = (1, 3, 4, 5, 6)
    DESCENT_TAIL_LANDMARK = 11
    BASE_LANDMARKS = (1, 4, 5, 7, 8)
    ASCENT_LANDMARKS = (1, 4, 5, 6)

    def transitions(self):
        return 14 + 18 * self.depth

    def transitions_detail(self):
        return dict(prologue=4, descent=12 * self.depth, base=8,
                    ascent=6 * self.depth, epilogue=2, total=self.transitions())

    def locate(self, step):
        """(block, level, offset) with a one-based offset inside the block."""
        assert 1 <= step <= self.transitions(), ("step out of range", step)
        if step <= 4:
            return "prologue", 0, step
        after = step - 4
        if after <= 12 * self.depth:
            return "descent", (after - 1) // 12 + 1, (after - 1) % 12 + 1
        after -= 12 * self.depth
        if after <= 8:
            return "base", self.depth + 1, after
        after -= 8
        if after <= 6 * self.depth:
            # The innermost call returns first, so ascent k unwinds level n-k+1.
            return "ascent", self.depth - (after - 1) // 6, (after - 1) % 6 + 1
        return "epilogue", 0, after - 6 * self.depth

    def transition(self, step):
        block, _, offset = self.locate(step)
        return getattr(self, block.upper())[offset - 1][0]

    def site(self, step):
        block, level, offset = self.locate(step)
        site = getattr(self, block.upper())[offset - 1][1]
        if site is None:  # the Enter of a descent or base block
            return "main" if level == 1 else "function/0/body/2/1"
        return site

    def event_end(self, step):
        """Enter, Free cell and Return are the only recorded call/cell events."""
        block, level, offset = self.locate(step)
        if block == "prologue":
            return 0
        if block == "descent":
            return level - 1 + (1 if offset >= 1 else 0)
        if block == "base":
            return self.depth + 1
        if block == "ascent":
            done = self.depth - level  # completed ascent blocks
            seen = self.depth + 1 + 2 * done
            if offset >= 1:
                seen += 1  # this block's Return
            if offset >= 5:
                seen += 1  # this block's Free cell
            return seen
        return 3 * self.depth + 1 + (1 if offset >= 1 else 0)

    def has_landmark(self, step):
        block, level, offset = self.locate(step)
        if block == "prologue":
            return offset == 1 or (offset == 3 and self.depth > 0)
        if block == "descent":
            return offset in self.DESCENT_LANDMARKS or (
                offset == self.DESCENT_TAIL_LANDMARK and level < self.depth)
        if block == "base":
            return offset in self.BASE_LANDMARKS
        if block == "ascent":
            return offset in self.ASCENT_LANDMARKS
        return True

    # How many control rows a committed state carries, by block and offset.
    # Each level adds three, so one observation near the bottom of the
    # recursion carries about three rows per cell already descended.
    CONTROL_ROWS = {
        "prologue": [0, 1, 2, 1],
        "descent": [1, 2, 3, 2, 2, 2, 3, 4, 3, 4, 5, 4],
        "base": [1, 2, 3, 2, 2, 3, 2, 2],
        "ascent": [4, 3, 3, 2, 2, 2],
        "epilogue": [1, 0],
    }

    def frames(self, step):
        block, level, _ = self.locate(step)
        return 0 if block in ("prologue", "epilogue") else level

    def control_rows(self, step):
        block, level, offset = self.locate(step)
        rows = self.CONTROL_ROWS[block][offset - 1]
        return rows if block in ("prologue", "epilogue") else rows + 3 * (level - 1)

    def live_cells(self, step):
        block, level, offset = self.locate(step)
        if block in ("prologue", "descent", "base"):
            return self.depth
        if block == "ascent":
            return level - (1 if offset >= 5 else 0)
        return 0

    def observation_rows(self, period):
        """Total control, frame and memory rows D151's schedule asks for."""
        total = dict(control=0, frames=0, memory=0, observations=0)
        for step in range(period, self.transitions() + 1, period):
            total["control"] += self.control_rows(step)
            total["frames"] += self.frames(step)
            total["memory"] += self.live_cells(step)
            total["observations"] += 1
        return total

    def _prologue_landmarks(self, before_offset):
        offsets = [1] + ([3] if self.depth else [])
        return sum(1 for o in offsets if o < before_offset)

    def _descent_landmarks(self, level, before_offset):
        offsets = set(self.DESCENT_LANDMARKS)
        if level < self.depth:
            offsets.add(self.DESCENT_TAIL_LANDMARK)
        return sum(1 for o in offsets if o < before_offset)

    def _descent_total(self):
        return len(self.DESCENT_LANDMARKS) * self.depth + max(self.depth - 1, 0)

    def landmark(self, step):
        if not self.has_landmark(step):
            return None
        block, level, offset = self.locate(step)
        prologue = 1 + (1 if self.depth else 0)
        if block == "prologue":
            return self._prologue_landmarks(offset)
        before = prologue
        if block == "descent":
            done = level - 1
            before += len(self.DESCENT_LANDMARKS) * done + min(done, max(self.depth - 1, 0))
            return before + self._descent_landmarks(level, offset)
        before += self._descent_total()
        if block == "base":
            return before + sum(1 for o in self.BASE_LANDMARKS if o < offset)
        before += len(self.BASE_LANDMARKS)
        if block == "ascent":
            before += len(self.ASCENT_LANDMARKS) * (self.depth - level)
            return before + sum(1 for o in self.ASCENT_LANDMARKS if o < offset)
        return before + len(self.ASCENT_LANDMARKS) * self.depth + offset - 1

    def expected_answer(self):
        return str(self.depth)

    def expected_peak_frames(self):
        return self.depth + 1


WORKLOADS = {DiscardedList.name: DiscardedList, NonTailSum.name: NonTailSum}


def reference_trace(workload):
    """The frozen reference's own trace for this workload at a small depth."""
    assert workload.depth <= 8, "reference trace is only usable at small depths"
    program = parse(workload.source)
    check(program, "B")
    case = workload.case()
    reference = Origins(program, case["cells"], case["inputs"], case["outside"], landmark_limit=100000)
    outcome = reference.observe(program["main"])
    return reference, outcome


def validate_schedule(workload):
    """Exact equality of the closed form against the frozen reference.

    Returns the per-step comparison count. Raises on the first disagreement so a
    counterexample is preserved rather than averaged away.
    """
    reference, outcome = reference_trace(workload)
    trace = reference.trace
    assert len(trace) == workload.transitions(), (
        "closed-form transition count", workload.name, workload.depth, len(trace), workload.transitions())
    assert outcome["status"] == "finished", "workload must finish at validation depth"
    assert outcome["outcome"]["value"] == ["n", workload.expected_answer()], "closed-form answer"
    counts = [sum(e[0] == k for e in outcome["outcome"]["record"]) for k in ("create", "write", "free")]
    assert counts == workload.expected_cell_counts(), ("closed-form cell counts", counts)
    peak = max((len(t["state"]["frames"]) for t in trace), default=0)
    assert peak == workload.expected_peak_frames(), ("closed-form peak frames", peak)
    compared = 0
    for predicted in trace:
        step = predicted["step"]
        if hasattr(workload, "control_rows"):
            assert workload.control_rows(step) == len(predicted["control"]), (
                "closed-form control rows", workload.name, workload.depth, step)
            assert workload.frames(step) == len(predicted["state"]["frames"]), (
                "closed-form frame rows", workload.name, workload.depth, step)
            assert workload.live_cells(step) == len(predicted["state"]["memory"]), (
                "closed-form live cells", workload.name, workload.depth, step)
        for key in ("transition", "site", "event_end", "landmark"):
            assert getattr(workload, key)(step) == predicted[key], (
                "closed-form " + key, workload.name, workload.depth, step,
                getattr(workload, key)(step), predicted[key])
        compared += 1
    return compared


def state_growth(workload_class, depths):
    """Peak committed-state row counts per depth, measured on the reference.

    This is how large one approved full observation becomes. It is a
    measurement at small depths, not a claim about the approved workload; the
    million-cell figures in the report are an extrapolation of these slopes.
    """
    rows = []
    for depth in depths:
        reference, _ = reference_trace(workload_class(depth))
        trace = reference.trace
        rows.append(dict(depth=depth,
                         memory=max(len(t["state"]["memory"]) for t in trace),
                         bindings=max(len(t["state"]["bindings"]) for t in trace),
                         frames=max(len(t["state"]["frames"]) for t in trace),
                         pending=max(len(t["state"]["pending"]) for t in trace),
                         control=max(len(t["control"]) for t in trace),
                         release=max(len(t["release"]) for t in trace),
                         transitions=len(trace),
                         landmarks=sum(1 for t in trace if t["landmark"] is not None)))
    return rows


def linear_fit(rows, key):
    """Slope and intercept of a row count against depth, or None if not linear."""
    first, last = rows[0], rows[-1]
    span = last["depth"] - first["depth"]
    if span == 0:
        return None
    slope, remainder = divmod(last[key] - first[key], span)
    if remainder:
        return None
    intercept = first[key] - slope * first["depth"]
    if any(row[key] != slope * row["depth"] + intercept for row in rows):
        return None
    return dict(per_cell=slope, constant=intercept)


def validate_states(workload):
    """Full-state equality for the workloads whose state rule is implemented."""
    assert workload.states_implemented, ("no state rule", workload.name)
    reference, _ = reference_trace(workload)
    compared = 0
    for predicted in reference.trace:
        step = predicted["step"]
        actual = workload.row(step)
        for key in ("transition", "site", "event_end", "landmark", "state", "control", "ready", "release"):
            assert actual[key] == predicted[key], ("closed-form " + key, workload.name, workload.depth, step,
                                                   actual[key], predicted[key])
        compared += 1
    return compared


def initial_state(workload):
    """Step 0, matching the frozen `Verifier.initial` shape."""
    case = workload.case()
    bindings = [[i, n, v, "holding" if v[0] == "l" and v[1] is not None else "noHolder"]
                for i, (n, v) in enumerate(case["inputs"])]
    return dict(step=0, event_end=0, control=[], ready=None, release=[],
                state=dict(kind=None, memory=deepcopy(case["cells"]), outside=case["outside"],
                           bindings=bindings, pending=[], aside=[], branch=None, frames=[]))
