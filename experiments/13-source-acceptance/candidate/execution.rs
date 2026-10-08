//! Iterative execution and explicit ownership, using the v16 native contracts.
use crate::frontend::{DeclId, Expr, NodeId, Program, kind_name};
use crate::number;
use mo_acceptance_runtime::{
    Cell, CleanupFailure, Error, Outcome, Resource, RuntimeCells, Status, Value,
};
use serde::{Serialize, Serializer};
use serde_json::{Value as Json, json};
use std::collections::{BTreeSet, VecDeque};
use std::sync::Arc;

#[derive(Clone, Debug)]
enum Val {
    Int(Arc<String>),
    Bool(bool),
    List(Option<u64>),
}
impl Val {
    fn list(&self) -> Option<u64> {
        match self {
            Self::List(l) => *l,
            _ => panic!("checked list"),
        }
    }
    fn int(&self) -> &str {
        match self {
            Self::Int(n) => n,
            _ => panic!("checked integer"),
        }
    }
}

impl Serialize for Val {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        match self {
            Self::Int(n) => ("n", n.as_str()).serialize(serializer),
            Self::Bool(b) => ("b", b).serialize(serializer),
            Self::List(l) => ("l", l).serialize(serializer),
        }
    }
}

#[derive(Clone, Copy, PartialEq, Eq)]
enum Holder {
    Holding,
    Moved,
    GivenUp,
    None,
}
impl Holder {
    fn name(self) -> &'static str {
        match self {
            Self::Holding => "holding",
            Self::Moved => "movedOn",
            Self::GivenUp => "givenUp",
            Self::None => "noHolder",
        }
    }
}

#[derive(Clone)]
struct Binding {
    decl: DeclId,
    value: Val,
    holder: Holder,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Phase {
    Enter,
    Child(usize),
    Capture(usize),
    Primitive,
    Bind,
    Choose,
    Decompose,
    SharedComplete,
    BranchStart,
    BranchResult,
    Reservations,
    Handoff,
    Produced,
}

#[derive(Clone)]
struct Context {
    node: NodeId,
    // Working environment extended by Bind/decomposition for child entry.
    scope: Vec<usize>,
    // Immutable environment at this expression's entry, also used at handoff.
    outer_scope: Vec<usize>,
    operands: Vec<Val>,
    phase: Phase,
    selected: usize,
    branch: Option<u64>,
}

#[derive(Clone, Copy)]
enum ReleasePhase {
    Queued,
    Give,
    Free,
    // Own effect completed; retain through publication and descendant cleanup.
    Waiting,
}
#[derive(Clone)]
struct Release {
    cell: u64,
    phase: ReleasePhase,
    binding: Option<usize>,
}

#[derive(Clone)]
struct State {
    step: u64,
    started: bool,
    finished: bool,
    bindings: Vec<Binding>,
    entered: Vec<usize>,
    contexts: Vec<Context>,
    pending: Vec<u64>,
    aside: Vec<(u64, u64)>,
    release: Vec<Release>,
    cleanup: VecDeque<usize>,
    ready: Option<Val>,
    result: Option<Val>,
    output: Option<Vec<u8>>,
    kind: Option<&'static str>,
    branch_value: Option<Val>,
    next_branch: u64,
    next_landmark: u64,
    events: Vec<Json>,
    births: Vec<Json>,
}

struct Action {
    name: &'static str,
    site: String,
    kind: Option<&'static str>,
}

#[derive(Serialize)]
struct Snapshot<'a> {
    step: u64,
    status: &'static str,
    state: OwnershipView<'a>,
    control: Vec<ControlView<'a>>,
    ready: Option<&'a Val>,
    release: Vec<u64>,
    event_end: usize,
    events: &'a [Json],
    births: &'a [Json],
    failure: Option<FailureView>,
    cleanup_events: &'a [Json],
}
#[derive(Serialize)]
struct OwnershipView<'a> {
    kind: Option<&'static str>,
    bindings: Vec<(usize, &'a str, &'a Val, &'static str)>,
    pending: Vec<(&'static str, u64)>,
    aside: &'a [(u64, u64)],
    branch: Option<&'a Val>,
    frames: [u64; 0],
}
#[derive(Serialize)]
struct ControlView<'a> {
    site: &'a str,
    scope: Vec<(&'a str, usize)>,
    invocation: u64,
    operands: &'a [Val],
}
#[derive(Serialize)]
struct FailureView {
    class: &'static str,
    step: u64,
    domain: Option<&'static str>,
    aborts: [u64; 0],
}

#[derive(Debug)]
struct Fault {
    class: &'static str,
    domain: Option<&'static str>,
}
impl Fault {
    fn denial(domain: &'static str) -> Self {
        Self {
            class: "resource-exhausted",
            domain: Some(domain),
        }
    }
    fn cell(error: Error) -> Self {
        match error {
            Error::InjectedAllocationFailure => Self::denial("cell"),
            Error::UnknownCell => Self {
                class: "unknown-cell",
                domain: None,
            },
            Error::InvalidDetach => Self {
                class: "invalid-detach",
                domain: None,
            },
        }
    }
}

pub(crate) struct Machine {
    program: Arc<Program>,
    cells: Resources,
    state: State,
    failure: Option<Fault>,
    cleanup_events: Vec<Json>,
    destroyed: bool,
}

// Test allocation gates can exercise the SAME scalar/empty-list executor without
// constructing RuntimeCells. There is deliberately no test cell storage: any
// attempt to access native methods with that test variant panics.
enum Resources {
    Native(RuntimeCells),
    #[cfg(test)]
    NoCells {
        attempts: [std::cell::Cell<u64>; 2],
        deny: [Option<u64>; 2],
    },
}

impl Resources {
    fn allocate<T>(&self, domain: Resource, allocation: impl FnOnce() -> T) -> Result<T, Error> {
        match self {
            Self::Native(cells) => cells.allocate(domain, allocation),
            #[cfg(test)]
            Self::NoCells { attempts, deny } => {
                let index = match domain {
                    Resource::Number => 0,
                    Resource::Frame => 1,
                };
                let attempt = attempts[index].get() + 1;
                attempts[index].set(attempt);
                if deny[index] == Some(attempt) {
                    Err(Error::InjectedAllocationFailure)
                } else {
                    Ok(allocation())
                }
            }
        }
    }
}

impl std::ops::Deref for Resources {
    type Target = RuntimeCells;
    fn deref(&self) -> &RuntimeCells {
        match self {
            Self::Native(cells) => cells,
            #[cfg(test)]
            Self::NoCells { .. } => {
                panic!("no native capability or cell store exists in this test")
            }
        }
    }
}

fn read(cells: &Resources, id: u64) -> Result<Cell, Fault> {
    cells
        .allocate(Resource::Number, || cells.read(id))
        .map_err(|_| Fault::denial("number"))?
        .map_err(Fault::cell)
}

fn numeric(cells: &Resources, f: impl FnOnce() -> String) -> Result<Arc<String>, Fault> {
    cells
        .allocate(Resource::Number, || Arc::new(f()))
        .map_err(|_| Fault::denial("number"))
}

impl Machine {
    pub fn begin(program: Arc<Program>, inputs: Vec<(String, Value)>, cells: RuntimeCells) -> Self {
        let state = State::begin(&program, inputs);
        Self {
            program,
            cells: Resources::Native(cells),
            state,
            failure: None,
            cleanup_events: Vec::new(),
            destroyed: false,
        }
    }

    pub fn outcome(&self) -> Outcome {
        Outcome {
            status: self.status(),
            committed_steps: self.state.step,
        }
    }
    fn status(&self) -> Status {
        if self.failure.is_some() {
            Status::Failed
        } else if self.state.finished {
            Status::Finished
        } else {
            Status::Suspended
        }
    }
    fn status_name(&self) -> &'static str {
        match self.status() {
            Status::Failed => "failed",
            Status::Finished => "finished",
            Status::Suspended => "suspended",
        }
    }

    pub fn step(&mut self) -> Option<Vec<u8>> {
        if self.failure.is_some() || self.state.finished || self.destroyed {
            return None;
        }
        let event_start = self.state.events.len();
        let birth_start = self.state.births.len();
        // Allocate the actual next continuation/cleanup storage through Frame.
        // Values share immutable numeric buffers. All Number/cell denial points
        // inside execute precede that action's first native mutation.
        let attempt = self.cells.allocate(Resource::Frame, || {
            let mut next = self.state.clone();
            next.transfer_result();
            next.ready = None;
            next.branch_value = None;
            next.kind = None;
            let action = execute(&self.program, &self.cells, &mut next)?;
            Ok::<_, Fault>((next, action))
        });
        let (mut next, action) = match attempt {
            Err(_) => {
                self.failure = Some(Fault::denial("frame"));
                return None;
            }
            Ok(Err(fault)) => {
                self.failure = Some(fault);
                return None;
            }
            Ok(Ok(result)) => result,
        };
        next.step += 1;
        next.kind = action.kind;
        let landmark = action.kind.map(|_| {
            let index = next.next_landmark;
            next.next_landmark += 1;
            index
        });
        self.state = next;
        Some(serde_json::to_vec(&json!({
            "step":self.state.step, "transition":action.name, "site":action.site,
            "event_end":self.state.events.len(), "landmark":landmark,
            "events_added":&self.state.events[event_start..], "births_added":&self.state.births[birth_start..]
        })).unwrap())
    }

    pub fn snapshot(&self) -> Vec<u8> {
        let s = &self.state;
        let mut visible = s.entered.clone();
        for (id, binding) in s.bindings.iter().enumerate() {
            if binding.holder == Holder::Holding && !visible.contains(&id) {
                visible.push(id);
            }
        }
        let bindings: Vec<_> = visible
            .iter()
            .map(|&id| {
                let b = &s.bindings[id];
                (
                    id,
                    self.program.declarations[b.decl].name.as_str(),
                    &b.value,
                    b.holder.name(),
                )
            })
            .collect();
        let control: Vec<_> = s
            .contexts
            .iter()
            .map(|c| {
                let mut scope: Vec<(&str, usize)> = Vec::new();
                for &id in &c.outer_scope {
                    let name = self.program.declarations[s.bindings[id].decl].name.as_str();
                    if let Some(pair) = scope.iter_mut().find(|(n, _)| *n == name) {
                        pair.1 = id;
                    } else {
                        scope.push((name, id));
                    }
                }
                ControlView {
                    site: &self.program.nodes[c.node].path,
                    scope,
                    invocation: 0,
                    operands: &c.operands,
                }
            })
            .collect();
        let failure = self.failure.as_ref().map(|f| FailureView {
            class: f.class,
            step: s.step,
            domain: f.domain,
            aborts: [],
        });
        serde_json::to_vec(&Snapshot {
            step: s.step,
            status: self.status_name(),
            state: OwnershipView {
                kind: s.kind,
                bindings,
                pending: s.pending.iter().map(|&id| ("l", id)).collect(),
                aside: &s.aside,
                branch: s.branch_value.as_ref(),
                frames: [],
            },
            control,
            ready: s.ready.as_ref(),
            release: s
                .release
                .iter()
                .filter(|r| !matches!(r.phase, ReleasePhase::Queued))
                .map(|r| r.cell)
                .collect(),
            event_end: s.events.len(),
            events: &s.events,
            births: &s.births,
            failure,
            cleanup_events: &self.cleanup_events,
        })
        .unwrap()
    }

    pub fn public_output(&self) -> Vec<u8> {
        // Serialization is read-only observation, never interpreter work.
        let line = if let Some(f) = &self.failure {
            format!(
                "{{\"status\":\"failed\",\"class\":{},\"step\":\"{}\"}}\n",
                serde_json::to_string(f.class).unwrap(),
                self.state.step
            )
        } else if self.state.finished {
            format!(
                "{{\"status\":\"finished\",\"type\":\"{}\",\"value\":{}}}\n",
                kind_name(&self.program.nodes[self.program.main].kind),
                std::str::from_utf8(self.state.output.as_ref().unwrap()).unwrap()
            )
        } else {
            format!(
                "{{\"status\":\"suspended\",\"steps\":\"{}\"}}\n",
                self.state.step
            )
        };
        line.into_bytes()
    }

    pub fn destroy(&mut self) -> Result<(), CleanupFailure> {
        if self.destroyed {
            return Ok(());
        }
        // Each cleanup mutation updates the real ownership ledger immediately,
        // so a denial is retryable without releasing a holder twice. Cleanup
        // continuation allocations use the same Frame boundary as evaluation.
        loop {
            let result = self
                .cells
                .allocate(Resource::Frame, || {
                    destroy_one(&self.cells, &mut self.state, &mut self.cleanup_events)
                })
                .map_err(|_| Fault::denial("frame"))
                .and_then(|r| r);
            match result {
                Ok(true) => continue,
                Ok(false) => break,
                Err(f) => {
                    return Err(CleanupFailure {
                        class: f.class.into(),
                    });
                }
            }
        }
        self.state.contexts.clear();
        self.state.ready = None;
        self.state.release.clear();
        self.state.cleanup.clear();
        self.state.entered.clear();
        self.state.branch_value = None;
        self.destroyed = true;
        Ok(())
    }
}

impl State {
    fn begin(program: &Program, inputs: Vec<(String, Value)>) -> Self {
        let mut state = State {
            step: 0,
            started: false,
            finished: false,
            bindings: Vec::new(),
            entered: Vec::new(),
            contexts: Vec::new(),
            pending: Vec::new(),
            aside: Vec::new(),
            release: Vec::new(),
            cleanup: VecDeque::new(),
            ready: None,
            result: None,
            output: None,
            kind: None,
            branch_value: None,
            next_branch: 0,
            next_landmark: 0,
            events: Vec::new(),
            births: Vec::new(),
        };
        // Host validation has established names/types and installed one holder per
        // nonempty input. Move owned input numerals; no numeric copy is required.
        let mut inputs: Vec<_> = inputs.into_iter().map(Some).collect();
        for input in &program.inputs {
            let decl = input.declaration;
            let position = inputs
                .iter()
                .position(|entry| {
                    entry
                        .as_ref()
                        .is_some_and(|(name, _)| name == &program.declarations[decl].name)
                })
                .expect("host validated inputs");
            let (_, value) = inputs[position].take().unwrap();
            let value = match value {
                Value::Int(n) => Val::Int(Arc::new(n)),
                Value::Bool(b) => Val::Bool(b),
                Value::ListInt(l) => Val::List(l),
            };
            let id = state.bindings.len();
            let holder = if matches!(value, Val::List(Some(_))) {
                Holder::Holding
            } else {
                Holder::None
            };
            state.bindings.push(Binding {
                decl,
                value,
                holder,
            });
            state.entered.push(id);
            state.births.push(json!({"domain":"binding", "id":id, "origin":program.declarations[decl].path, "invocation":0}));
            if holder == Holder::Holding && !program.nodes[program.main].uses.contains(&decl) {
                state.cleanup.push_back(id);
            }
        }
        state
    }
}

fn destroy_one(
    cells: &Resources,
    s: &mut State,
    cleanup_events: &mut Vec<Json>,
) -> Result<bool, Fault> {
    // Queued/Give entries still own a pending/binding holder. Free entries
    // already surrendered theirs and must be drained first; Waiting entries
    // completed their own effect and must never cause another decrement/free.
    if let Some(index) = s
        .release
        .iter()
        .rposition(|r| matches!(r.phase, ReleasePhase::Free))
    {
        let id = s.release[index].cell;
        let cell = read(cells, id)?;
        cells.free(id).map_err(Fault::cell)?;
        s.release.remove(index);
        if let Some(tail) = cell.tail {
            s.pending.insert(0, tail);
        }
        cleanup_events.push(json!(["free", id]));
        return Ok(true);
    }
    s.release.clear();
    if let Some(index) = s.bindings.iter().position(|b| b.holder == Holder::Holding) {
        let id = s.bindings[index].value.list().unwrap();
        let cell = read(cells, id)?;
        cells
            .metadata(id, cell.holders - 1, cell.aside)
            .map_err(Fault::cell)?;
        s.bindings[index].holder = Holder::GivenUp;
        if cell.holders == 1 {
            s.release.push(Release {
                cell: id,
                phase: ReleasePhase::Free,
                binding: None,
            });
        }
        return Ok(true);
    }
    if let Some(&id) = s.pending.first() {
        let cell = read(cells, id)?;
        cells
            .metadata(id, cell.holders - 1, cell.aside)
            .map_err(Fault::cell)?;
        s.pending.remove(0);
        if cell.holders == 1 {
            s.release.push(Release {
                cell: id,
                phase: ReleasePhase::Free,
                binding: None,
            });
        }
        return Ok(true);
    }
    if let Some(&(_, id)) = s.aside.first() {
        cells.free(id).map_err(Fault::cell)?;
        s.aside.remove(0);
        cleanup_events.push(json!(["free", id]));
        return Ok(true);
    }
    Ok(false)
}

impl State {
    fn action(&self, program: &Program, name: &'static str, kind: Option<&'static str>) -> Action {
        Action {
            name,
            kind,
            site: self
                .contexts
                .last()
                .map_or("root", |c| program.nodes[c.node].path.as_str())
                .into(),
        }
    }
    fn push_context(&mut self, node: NodeId, scope: Vec<usize>) {
        self.contexts.push(Context {
            node,
            outer_scope: scope.clone(),
            scope,
            operands: Vec::new(),
            phase: Phase::Enter,
            selected: 0,
            branch: None,
        });
    }
    fn produce(&mut self, value: Val) {
        self.ready = Some(value);
        self.contexts.last_mut().unwrap().phase = Phase::Produced;
    }
    fn transfer_result(&mut self) {
        if !self
            .contexts
            .last()
            .is_some_and(|c| c.phase == Phase::Produced)
        {
            return;
        }
        // The result callback retains its actual producing context. Transfer
        // only in the staged next action, without replay or an extra commit.
        let value = self.ready.take().expect("produced result");
        self.contexts.pop();
        if let Some(parent) = self.contexts.last_mut() {
            parent.operands.push(value);
        } else {
            self.result = Some(value);
        }
    }
    fn remove_pending(&mut self, id: u64) {
        let position = self
            .pending
            .iter()
            .position(|&p| p == id)
            .expect("owned pending holder");
        self.pending.remove(position);
    }
    fn gave_up(&mut self, release: &Release, remaining_holders: u64) {
        if let Some(id) = release.binding {
            self.bindings[id].holder = Holder::GivenUp;
        } else {
            self.remove_pending(release.cell);
        }
        if remaining_holders == 0 {
            self.release.last_mut().unwrap().phase = ReleasePhase::Free;
        } else {
            self.release.last_mut().unwrap().phase = ReleasePhase::Waiting;
        }
    }
    fn freed(&mut self, id: u64, tail: Option<u64>) {
        self.events.push(json!(["free", id]));
        self.release.last_mut().unwrap().phase = ReleasePhase::Waiting;
        if let Some(tail) = tail {
            self.pending.insert(0, tail);
            self.release.push(Release {
                cell: tail,
                phase: ReleasePhase::Queued,
                binding: None,
            });
        }
    }
    fn start_release(&mut self) -> Option<Release> {
        // Resume after the preceding callback: completed frames unwind only
        // after their descendants finish, and queued work becomes active here.
        while self
            .release
            .last()
            .is_some_and(|r| matches!(r.phase, ReleasePhase::Waiting))
        {
            self.release.pop();
        }
        if self.release.is_empty() {
            while let Some(id) = self.cleanup.pop_front() {
                if self.bindings[id].holder == Holder::Holding {
                    self.release.push(Release {
                        cell: self.bindings[id].value.list().unwrap(),
                        phase: ReleasePhase::Queued,
                        binding: Some(id),
                    });
                    break;
                }
            }
        }
        let release = self.release.last_mut()?;
        if matches!(release.phase, ReleasePhase::Queued) {
            release.phase = ReleasePhase::Give;
        }
        Some(release.clone())
    }
    fn binding(&mut self, program: &Program, decl: DeclId, value: Val, holding: bool) -> usize {
        let id = self.bindings.len();
        self.bindings.push(Binding {
            decl,
            value,
            holder: if holding {
                Holder::Holding
            } else {
                Holder::None
            },
        });
        self.births.push(json!({"domain":"binding","id":id,"origin":program.declarations[decl].path,"invocation":0}));
        id
    }
    fn decomposed(&mut self, program: &Program, id: u64, cell: Cell, tail_used: bool) -> Action {
        // Logical continuation after the native detach/acquisition has succeeded.
        let index = self.contexts.len() - 1;
        let Expr::Match(head_decl, tail_decl) = program.nodes[self.contexts[index].node].expr
        else {
            unreachable!()
        };
        let unique = cell.holders == 1;
        let head = self.binding(program, head_decl, Val::Int(Arc::new(cell.item)), false);
        let tail = self.binding(
            program,
            tail_decl,
            Val::List(cell.tail),
            cell.tail.is_some() && (unique || tail_used),
        );
        self.contexts[index].scope.extend([head, tail]);
        self.contexts[index].operands.clear();
        self.contexts[index].phase = if unique {
            Phase::BranchStart
        } else {
            Phase::SharedComplete
        };
        // A shared match without an acquired tail enters only at completion,
        // after the separate scrutinee release. Binding births are already due.
        if unique || (cell.tail.is_some() && tail_used) {
            self.entered = self.contexts[index].scope.clone();
        }
        if unique {
            let scope = self.entered.clone();
            self.queue_unused(program, &scope);
        } else {
            self.release.push(Release {
                cell: id,
                phase: ReleasePhase::Queued,
                binding: None,
            });
        }
        self.action(
            program,
            "Match decompose",
            if unique {
                Some("matchStep4Done")
            } else if cell.tail.is_some() && tail_used {
                Some("newHolder")
            } else {
                None
            },
        )
    }
    fn remaining(&self, program: &Program) -> BTreeSet<DeclId> {
        let mut uses = BTreeSet::new();
        for context in &self.contexts {
            let children = &program.nodes[context.node].children;
            let future: &[NodeId] = match context.phase {
                Phase::Enter => children,
                Phase::Child(index) => &children[index..],
                Phase::Capture(index) => &children[index + 1..],
                Phase::Bind => &children[1..],
                Phase::Choose => &children[1..],
                Phase::Decompose | Phase::SharedComplete | Phase::BranchStart => {
                    &children[context.selected..context.selected + 1]
                }
                _ => &[],
            };
            for &child in future {
                uses.extend(program.nodes[child].uses.iter().copied());
            }
        }
        uses
    }
    fn queue_unused(&mut self, program: &Program, scope: &[usize]) {
        let remaining = self.remaining(program);
        for &id in scope {
            let binding = &self.bindings[id];
            if binding.holder == Holder::Holding
                && !remaining.contains(&binding.decl)
                && !self.cleanup.contains(&id)
            {
                self.cleanup.push_back(id);
            }
        }
    }
}

fn release_action(
    program: &Program,
    cells: &Resources,
    s: &mut State,
) -> Result<Option<Action>, Fault> {
    let Some(release) = s.start_release() else {
        return Ok(None);
    };
    let cell = read(cells, release.cell)?;
    match release.phase {
        ReleasePhase::Give => {
            cells
                .metadata(release.cell, cell.holders - 1, cell.aside)
                .map_err(Fault::cell)?;
            s.gave_up(&release, cell.holders - 1);
            Ok(Some(s.action(
                program,
                "Give up holder",
                Some("holderGivenUp"),
            )))
        }
        ReleasePhase::Free => {
            cells.free(release.cell).map_err(Fault::cell)?;
            s.freed(release.cell, cell.tail);
            Ok(Some(s.action(program, "Free cell", Some("cellFreed"))))
        }
        ReleasePhase::Queued | ReleasePhase::Waiting => unreachable!("release has been activated"),
    }
}

fn execute(program: &Program, cells: &Resources, s: &mut State) -> Result<Action, Fault> {
    // V17: selection commits first. Prepare the identity before the next
    // action's outer-holder cleanup, so its first commit publishes the birth.
    // This is staged state; a denied action publishes neither identity nor row.
    if let Some(context) = s.contexts.last_mut()
        && context.branch.is_none()
        && matches!(context.phase, Phase::Decompose | Phase::BranchStart)
        && matches!(program.nodes[context.node].expr, Expr::Match(..))
    {
        let branch = s.next_branch;
        s.next_branch += 1;
        context.branch = Some(branch);
        s.births.push(json!({"domain":"branch","id":branch,"origin":program.nodes[context.node].path,"invocation":0}));
    }
    if let Some(action) = release_action(program, cells, s)? {
        return Ok(action);
    }
    if !s.started {
        s.started = true;
        return Ok(Action {
            name: "Start",
            site: "root".into(),
            kind: Some("start"),
        });
    }
    if s.contexts.is_empty() {
        if let Some(value) = &s.result {
            let output = match value {
                Val::Int(n) => serde_json::to_vec(n.as_str()).unwrap(),
                Val::Bool(b) => serde_json::to_vec(b).unwrap(),
                Val::List(root) => {
                    let mut items = Vec::new();
                    let mut at = *root;
                    while let Some(id) = at {
                        let cell = read(cells, id)?;
                        items.push(cell.item);
                        at = cell.tail;
                    }
                    serde_json::to_vec(&items).unwrap()
                }
            };
            s.output = Some(output);
            s.ready = Some(value.clone());
            s.finished = true;
            return Ok(Action {
                name: "Finish",
                site: "root".into(),
                kind: Some("end"),
            });
        }
        s.push_context(program.main, s.entered.clone());
    }
    loop {
        let index = s.contexts.len() - 1;
        let id = s.contexts[index].node;
        let node = &program.nodes[id];
        let phase = s.contexts[index].phase;
        match phase {
            Phase::Enter => match &node.expr {
                Expr::Int(value) => {
                    let value = Val::Int(numeric(cells, || value.to_string())?);
                    let action = s.action(program, "Leaf", None);
                    s.produce(value);
                    return Ok(action);
                }
                Expr::Bool(value) => {
                    let action = s.action(program, "Leaf", None);
                    s.produce(Val::Bool(*value));
                    return Ok(action);
                }
                Expr::Nil => {
                    let action = s.action(program, "Leaf", None);
                    s.produce(Val::List(None));
                    return Ok(action);
                }
                Expr::Var { binding, .. } => {
                    let bind = *s.contexts[index]
                        .scope
                        .iter()
                        .rev()
                        .find(|&&id| s.bindings[id].decl == *binding)
                        .unwrap();
                    let value = s.bindings[bind].value.clone();
                    let mut kind = None;
                    if let Val::List(Some(cell_id)) = value {
                        let used_again = s.remaining(program).contains(binding);
                        if used_again {
                            let cell = read(cells, cell_id)?;
                            cells
                                .metadata(cell_id, cell.holders + 1, cell.aside)
                                .map_err(Fault::cell)?;
                            kind = Some("newHolder");
                        } else {
                            s.bindings[bind].holder = Holder::Moved;
                            kind = Some("holderMoved");
                        }
                        s.pending.insert(0, cell_id);
                        s.entered = s.contexts[index].scope.clone();
                    }
                    let action = s.action(program, "Leaf", kind);
                    s.produce(value);
                    return Ok(action);
                }
                Expr::Call => unreachable!("Stage A refuses calls"),
                _ => {
                    s.contexts[index].phase = Phase::Child(0);
                    return Ok(s.action(program, "Dispatch compound", None));
                }
            },
            Phase::Child(child) => {
                let next = match node.expr {
                    Expr::Let(_) => {
                        if child == 0 {
                            Phase::Bind
                        } else {
                            Phase::Handoff
                        }
                    }
                    Expr::If | Expr::Match(..) => {
                        if child == 0 {
                            Phase::Choose
                        } else if matches!(node.expr, Expr::Match(..)) {
                            Phase::BranchResult
                        } else {
                            Phase::Handoff
                        }
                    }
                    _ => Phase::Capture(child),
                };
                let scope = s.contexts[index].scope.clone();
                s.contexts[index].phase = next;
                s.push_context(node.children[child], scope);
            }
            Phase::Capture(child) => {
                s.contexts[index].phase = if child == 0 {
                    Phase::Child(1)
                } else {
                    Phase::Primitive
                };
                return Ok(s.action(program, "Operand capture", None));
            }
            Phase::Primitive => {
                let left = s.contexts[index].operands[0].clone();
                let right = s.contexts[index].operands[1].clone();
                let mut kind = None;
                let value = match node.expr {
                    Expr::Add | Expr::Sub => Val::Int(numeric(cells, || {
                        number::arithmetic(left.int(), right.int(), matches!(node.expr, Expr::Sub))
                    })?),
                    Expr::Eq => Val::Bool(number::compare(left.int(), right.int()).is_eq()),
                    Expr::Lt => Val::Bool(number::compare(left.int(), right.int()).is_lt()),
                    Expr::Le => Val::Bool(number::compare(left.int(), right.int()).is_le()),
                    Expr::Cons => {
                        let item = cells
                            .allocate(Resource::Number, || left.int().to_string())
                            .map_err(|_| Fault::denial("number"))?;
                        let tail = right.list();
                        let branches: BTreeSet<_> =
                            s.contexts.iter().filter_map(|c| c.branch).collect();
                        let eligible = s
                            .aside
                            .iter()
                            .position(|(branch, _)| branches.contains(branch));
                        let cell = if let Some(position) = eligible {
                            let (_, cell) = s.aside[position];
                            cells.write(cell, item, tail).map_err(Fault::cell)?;
                            cells.metadata(cell, 1, false).map_err(Fault::cell)?;
                            s.aside.remove(position);
                            s.events.push(json!(["write", cell]));
                            cell
                        } else {
                            let cell = cells
                                .create(Cell {
                                    item,
                                    tail,
                                    holders: 1,
                                    aside: false,
                                })
                                .map_err(Fault::cell)?;
                            s.events.push(json!(["create", cell]));
                            s.births.push(json!({"domain":"cell","id":cell,"origin":node.path,"invocation":0}));
                            cell
                        };
                        if let Some(tail) = tail {
                            s.remove_pending(tail);
                        }
                        s.pending.insert(0, cell);
                        s.entered = s.contexts[index].scope.clone();
                        kind = Some("newCellBuilt");
                        Val::List(Some(cell))
                    }
                    _ => unreachable!(),
                };
                s.contexts[index].operands.clear();
                let action = s.action(program, "Primitive result", kind);
                s.produce(value);
                return Ok(action);
            }
            Phase::Bind => {
                let Expr::Let(decl) = node.expr else {
                    unreachable!()
                };
                let value = s.contexts[index].operands[0].clone();
                let holding = matches!(value, Val::List(Some(_)));
                if let Val::List(Some(cell)) = value {
                    s.remove_pending(cell);
                }
                let binding = s.binding(program, decl, value, holding);
                s.contexts[index].scope.push(binding);
                s.contexts[index].operands.clear();
                s.contexts[index].phase = Phase::Child(1);
                s.entered = s.contexts[index].scope.clone();
                let scope = s.entered.clone();
                s.queue_unused(program, &scope);
                return Ok(s.action(
                    program,
                    "Bind",
                    if holding { Some("nameBound") } else { None },
                ));
            }
            Phase::Choose => {
                let value = s.contexts[index].operands[0].clone();
                let selected = match value {
                    Val::Bool(true) => 1,
                    Val::Bool(false) => 2,
                    Val::List(None) => 1,
                    Val::List(Some(_)) => 2,
                    _ => unreachable!(),
                };
                s.contexts[index].selected = selected;
                s.contexts[index].phase = if matches!(value, Val::List(Some(_))) {
                    Phase::Decompose
                } else {
                    Phase::BranchStart
                };
                s.entered = s.contexts[index].scope.clone();
                let scope = s.entered.clone();
                s.queue_unused(program, &scope);
                return Ok(s.action(program, "Choose branch", Some("branchChosen")));
            }
            Phase::Decompose => {
                let Expr::Match(_, tail_decl) = node.expr else {
                    unreachable!()
                };
                let id = s.contexts[index].operands[0].list().unwrap();
                let cell = read(cells, id)?;
                let branch = s.contexts[index].branch.unwrap();
                let unique = cell.holders == 1;
                let tail_used = program.nodes[node.children[2]].uses.contains(&tail_decl);
                // Perform every fallible allocation/read before detaching or
                // updating any count. Native metadata/detach do not allocate.
                let tail_cell = if !unique && tail_used {
                    cell.tail.map(|tail| read(cells, tail)).transpose()?
                } else {
                    None
                };
                if unique {
                    cells.detach(id).map_err(Fault::cell)?;
                    s.aside.insert(0, (branch, id));
                    s.remove_pending(id);
                } else if let (Some(tail), Some(meta)) = (cell.tail, tail_cell) {
                    cells
                        .metadata(tail, meta.holders + 1, meta.aside)
                        .map_err(Fault::cell)?;
                }
                return Ok(s.decomposed(program, id, cell, tail_used));
            }
            Phase::SharedComplete => {
                s.contexts[index].phase = Phase::BranchStart;
                s.entered = s.contexts[index].scope.clone();
                return Ok(s.action(program, "Match complete", Some("matchStep4Done")));
            }
            Phase::BranchStart => {
                s.contexts[index].operands.clear();
                s.contexts[index].phase = Phase::Child(s.contexts[index].selected);
                s.entered = s.contexts[index].scope.clone();
                return Ok(s.action(program, "Branch start", Some("branchStarts")));
            }
            Phase::BranchResult => {
                s.branch_value = s.contexts[index].operands.last().cloned();
                s.contexts[index].phase = Phase::Reservations;
                s.entered = s.contexts[index].scope.clone();
                return Ok(s.action(
                    program,
                    "Branch result/cleanup",
                    Some("branchValueWorkedOut"),
                ));
            }
            Phase::Reservations => {
                let branch = s.contexts[index].branch.unwrap();
                if let Some(position) = s.aside.iter().position(|&(owner, _)| owner == branch) {
                    let (_, id) = s.aside[position];
                    cells.free(id).map_err(Fault::cell)?;
                    s.aside.remove(position);
                    s.events.push(json!(["free", id]));
                    return Ok(s.action(program, "Free cell", Some("cellFreed")));
                }
                s.contexts[index].phase = Phase::Handoff;
            }
            Phase::Handoff => {
                let value = s.contexts[index].operands.last().unwrap().clone();
                let is_match = matches!(node.expr, Expr::Match(..));
                let action = s.action(
                    program,
                    "Handoff",
                    if is_match {
                        Some("branchValueHandedOn")
                    } else {
                        None
                    },
                );
                if is_match {
                    s.branch_value = Some(value.clone());
                    s.entered = s.contexts[index].outer_scope.clone();
                }
                s.contexts[index].operands.clear();
                s.produce(value);
                return Ok(action);
            }
            Phase::Produced => unreachable!("result transferred before the next action"),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{Run, StageA, frontend};
    use mo_acceptance_runtime::Candidate;

    fn program(source: &str) -> Arc<Program> {
        Arc::new(
            frontend::check(source.as_bytes(), &mut |digits, negative| {
                Ok(number::literal(digits, negative))
            })
            .unwrap(),
        )
    }
    fn run(source: &str, inputs: Vec<(String, Value)>, deny: [Option<u64>; 2]) -> Run {
        let program = program(source);
        let state = State::begin(&program, inputs);
        Run(Machine {
            program,
            state,
            cells: Resources::NoCells {
                attempts: std::array::from_fn(|_| std::cell::Cell::new(0)),
                deny,
            },
            failure: None,
            cleanup_events: vec![],
            destroyed: false,
        })
    }
    fn snapshot(run: &Run) -> Json {
        serde_json::from_slice(&StageA::snapshot(run)).unwrap()
    }
    fn attempts(run: &Run) -> [u64; 2] {
        let Resources::NoCells { attempts, .. } = &run.0.cells else {
            unreachable!()
        };
        [attempts[0].get(), attempts[1].get()]
    }
    fn collect(run: &mut Run, budget: u64) -> Vec<(Json, Json)> {
        let mut records = Vec::new();
        StageA::advance(run, budget, &mut |run, record| {
            let record: Json = serde_json::from_slice(record).unwrap();
            let state = snapshot(run);
            assert_eq!(record["step"], state["step"]);
            records.push((record, state));
        });
        records
    }

    #[test]
    fn result_boundaries_keep_current_context_until_next_action() {
        let mut run = run("main = 17 - 4", vec![], [None, None]);
        // Each row is one real callback, not an extra transfer transition.
        let expected = [
            ("Start", "root", json!([]), Json::Null),
            (
                "Dispatch compound",
                "main",
                json!([["main", []]]),
                Json::Null,
            ),
            (
                "Leaf",
                "main/0",
                json!([["main", []], ["main/0", []]]),
                json!(["n", "17"]),
            ),
            (
                "Operand capture",
                "main",
                json!([["main", [["n", "17"]]]]),
                Json::Null,
            ),
            (
                "Leaf",
                "main/1",
                json!([["main", [["n", "17"]]], ["main/1", []]]),
                json!(["n", "4"]),
            ),
            (
                "Operand capture",
                "main",
                json!([["main", [["n", "17"], ["n", "4"]]]]),
                Json::Null,
            ),
            (
                "Primitive result",
                "main",
                json!([["main", []]]),
                json!(["n", "13"]),
            ),
            ("Finish", "root", json!([]), json!(["n", "13"])),
        ];
        for (name, site, control, ready) in expected {
            let records = collect(&mut run, 1);
            assert_eq!(records.len(), 1);
            let (record, state) = &records[0];
            assert_eq!(record["transition"], name);
            assert_eq!(record["site"], site);
            let actual: Vec<_> = state["control"]
                .as_array()
                .unwrap()
                .iter()
                .map(|c| json!([c["site"], c["operands"]]))
                .collect();
            assert_eq!(json!(actual), control, "{name} at {site}");
            assert_eq!(state["ready"], ready);
            let saved = StageA::snapshot(&run);
            let gates = attempts(&run);
            assert!(collect(&mut run, 0).is_empty());
            assert_eq!(StageA::snapshot(&run), saved);
            assert_eq!(attempts(&run), gates);
        }
        assert_eq!(run.0.outcome().status, Status::Finished);
        assert_eq!(run.0.outcome().committed_steps, 8);
        assert_eq!(attempts(&run), [3, 8]);
    }

    #[test]
    fn nested_result_boundaries_retain_scope_and_consumed_operands() {
        let source = "main = (let x = 17 - 11 in if false then 9 else x end) - (match [] do [] -> 4; [h|t] -> h end)";
        let mut run = run(source, vec![], [None, None]);
        let mut boundaries = Vec::new();
        while run.0.outcome().status == Status::Suspended {
            let records = collect(&mut run, 1);
            let (record, state) = &records[0];
            let action = record["transition"].as_str().unwrap();
            if matches!(action, "Leaf" | "Primitive result" | "Handoff") {
                let control = state["control"].as_array().unwrap();
                let current = control
                    .last()
                    .expect("result boundary retains its expression");
                assert_eq!(current["site"], record["site"]);
                assert_eq!(current["operands"], json!([]));
                boundaries.push(json!([action, record["site"], state["ready"]]));
                if record["site"] == "main/0/1" {
                    // If handoff restores the ownership view, but its own
                    // lexical control and the waiting let remain suspended.
                    assert_eq!(control.len(), 3);
                    assert_eq!(current["scope"], json!([["x", 0]]));
                    assert_eq!(control[1]["operands"], json!([]));
                }
                if record["site"] == "main/1" {
                    assert_eq!(control[0]["operands"], json!([["n", "6"]]));
                    assert_eq!(state["state"]["branch"], json!(["n", "4"]));
                }
            }
        }
        assert_eq!(
            boundaries,
            vec![
                json!(["Leaf", "main/0/0/0", ["n", "17"]]),
                json!(["Leaf", "main/0/0/1", ["n", "11"]]),
                json!(["Primitive result", "main/0/0", ["n", "6"]]),
                json!(["Leaf", "main/0/1/0", ["b", false]]),
                json!(["Leaf", "main/0/1/2", ["n", "6"]]),
                json!(["Handoff", "main/0/1", ["n", "6"]]),
                json!(["Handoff", "main/0", ["n", "6"]]),
                json!(["Leaf", "main/1/0", ["l", null]]),
                json!(["Leaf", "main/1/1", ["n", "4"]]),
                json!(["Handoff", "main/1", ["n", "4"]]),
                json!(["Primitive result", "main", ["n", "2"]]),
            ]
        );
        assert_eq!(
            serde_json::from_slice::<Json>(&StageA::public_output(&run)).unwrap()["value"],
            "2"
        );
        assert_eq!(attempts(&run)[0], 5);
    }

    #[test]
    fn entered_bindings_follow_action_specific_nested_handoffs() {
        for (source, expected, final_names) in [
            (
                "main = let a = 3 in if true then (let b = 8 in b - a) else 0 end",
                json!([
                    ["main/1/1", ["a", "b"], [["a", 0]]],
                    ["main/1", ["a", "b"], [["a", 0]]],
                    ["main", ["a", "b"], []]
                ]),
                json!(["a", "b"]),
            ),
            (
                "main = let a = 3 in match [] do [] -> if true then (let b = 8 in b - a) else 0 end; [h|t] -> h end",
                json!([
                    ["main/1/1/1", ["a", "b"], [["a", 0]]],
                    ["main/1/1", ["a", "b"], [["a", 0]]],
                    ["main/1", ["a"], [["a", 0]]],
                    ["main", ["a"], []]
                ]),
                json!(["a"]),
            ),
        ] {
            let mut whole = run(source, vec![], [None, None]);
            let uninterrupted = collect(&mut whole, 128);
            let mut split = run(source, vec![], [None, None]);
            let mut resumed = Vec::new();
            let mut handoffs = Vec::new();
            while split.0.outcome().status == Status::Suspended {
                let records = collect(&mut split, 1);
                let (record, state) = &records[0];
                if record["transition"] == "Handoff" {
                    let names: Vec<_> = state["state"]["bindings"]
                        .as_array()
                        .unwrap()
                        .iter()
                        .map(|b| b[1].clone())
                        .collect();
                    let current = state["control"].as_array().unwrap().last().unwrap();
                    handoffs.push(json!([record["site"], names, current["scope"]]));
                    assert_eq!(current["site"], record["site"]);
                    assert_eq!(current["operands"], json!([]));
                    assert_eq!(state["ready"], json!(["n", "5"]));
                }
                resumed.extend(records);
                let saved = StageA::snapshot(&split);
                assert!(collect(&mut split, 0).is_empty());
                assert_eq!(saved, StageA::snapshot(&split));
            }
            assert_eq!(json!(handoffs), expected);
            assert_eq!(resumed, uninterrupted);
            assert_eq!(attempts(&split), attempts(&whole));
            let final_state = snapshot(&split);
            let names: Vec<_> = final_state["state"]["bindings"]
                .as_array()
                .unwrap()
                .iter()
                .map(|b| b[1].clone())
                .collect();
            assert_eq!(json!(names), final_names);
            assert_eq!(
                serde_json::from_slice::<Json>(&StageA::public_output(&split)).unwrap()["value"],
                "5"
            );
        }
    }

    #[test]
    fn moved_local_remains_entered_at_let_handoff_and_finish_denial() {
        // Last-use transfers need no native call. Finish's read is denied at
        // the Number gate before native access; no cell storage is constructed.
        let mut run = run(
            "input xs: ListInt; main = let xs = xs in xs",
            vec![("xs".into(), Value::ListInt(Some(43)))],
            [Some(1), None],
        );
        let records = collect(&mut run, 6);
        assert_eq!(records.last().unwrap().0["transition"], "Handoff");
        let before = snapshot(&run);
        assert_eq!(
            before["state"]["bindings"],
            json!([
                [0, "xs", ["l", 43], "movedOn"],
                [1, "xs", ["l", 43], "movedOn"]
            ])
        );
        assert_eq!(before["control"][0]["scope"], json!([["xs", 0]]));
        assert_eq!(before["state"]["pending"], json!([["l", 43]]));
        assert!(collect(&mut run, 1).is_empty());
        let after = snapshot(&run);
        for field in [
            "step", "state", "control", "ready", "release", "events", "births",
        ] {
            assert_eq!(before[field], after[field], "{field}");
        }
        assert_eq!(after["failure"]["domain"], "number");
    }

    fn decomposition_case(unique: bool, tail: Option<u64>, tail_used: bool) -> Run {
        // Exercise only post-native logical bookkeeping with a read descriptor.
        // No store, read, detach or acquisition is constructed or emulated.
        let source = if tail_used {
            "input outer: Int; main = match [] do [] -> []; [head|tail] -> tail end"
        } else {
            "input outer: Int; main = match [] do [] -> []; [head|tail] -> [] end"
        };
        let mut run = run(
            source,
            vec![("outer".into(), Value::Int("9".into()))],
            [None, None],
        );
        let program = Arc::clone(&run.0.program);
        let state = &mut run.0.state;
        state.started = true;
        state.push_context(program.main, state.entered.clone());
        state.contexts[0].phase = Phase::Decompose;
        state.contexts[0].selected = 2;
        state.contexts[0].branch = Some(0);
        state.contexts[0].operands.push(Val::List(Some(71)));
        if !unique {
            state.pending.push(71);
        }
        let action = state.decomposed(
            &program,
            71,
            Cell {
                item: "23".into(),
                tail,
                holders: if unique { 1 } else { 3 },
                aside: false,
            },
            tail_used,
        );
        assert_eq!(action.name, "Match decompose");
        run
    }

    #[test]
    fn decomposition_enters_scope_only_for_unique_or_acquired_tail() {
        for (unique, tail, used, entered, holding) in [
            (false, Some(89), false, vec![0], false),
            (false, None, true, vec![0], false),
            (false, None, false, vec![0], false),
            (false, Some(89), true, vec![0, 1, 2], true),
            (true, Some(89), false, vec![0, 1, 2], true),
            (true, Some(89), true, vec![0, 1, 2], true),
            (true, None, true, vec![0, 1, 2], false),
            (true, None, false, vec![0, 1, 2], false),
        ] {
            let run = decomposition_case(unique, tail, used);
            let state = &run.0.state;
            assert_eq!(
                state.entered, entered,
                "unique={unique}, tail={tail:?}, used={used}"
            );
            assert_eq!(state.contexts[0].scope, vec![0, 1, 2]);
            assert_eq!(state.contexts[0].outer_scope, vec![0]);
            assert!(state.contexts[0].operands.is_empty());
            assert_eq!(state.bindings.len(), 3);
            assert_eq!(state.births.len(), 3);
            assert_eq!(state.births[1]["id"], 1);
            assert_eq!(state.births[2]["id"], 2);
            assert_eq!(state.bindings[2].holder == Holder::Holding, holding);
            let view = snapshot(&run);
            let ids: Vec<_> = view["state"]["bindings"]
                .as_array()
                .unwrap()
                .iter()
                .map(|b| b[0].as_u64().unwrap() as usize)
                .collect();
            assert_eq!(ids, entered);
            assert_eq!(view["release"], json!([]));
            assert_eq!(view["events"], json!([]));
        }
    }

    #[test]
    fn shared_completion_enters_scope_after_release_and_survives_denial() {
        for (tail, used, prior) in [
            (Some(89), false, vec![0]),
            (None, true, vec![0]),
            (Some(89), true, vec![0, 1, 2]),
        ] {
            let mut run = decomposition_case(false, tail, used);
            // Begin at the clarified post-decomposition entered state, so this
            // test independently detects a missing Match complete switch.
            run.0.state.entered = prior.clone();
            let release = run.0.state.start_release().unwrap();
            run.0.state.gave_up(&release, 2);
            assert_eq!(run.0.state.entered, prior);
            assert_eq!(snapshot(&run)["release"], json!([71]));
            assert!(run.0.state.pending.is_empty());
            let before = snapshot(&run);
            assert!(collect(&mut run, 0).is_empty());
            assert_eq!(snapshot(&run), before);
            let saved = run.0.state.clone();
            if let Resources::NoCells { deny, .. } = &mut run.0.cells {
                deny[1] = Some(1);
            }
            assert!(collect(&mut run, 1).is_empty());
            let denied = snapshot(&run);
            for field in [
                "step", "state", "control", "ready", "release", "events", "births",
            ] {
                assert_eq!(denied[field], before[field], "{field}");
            }
            assert_eq!(denied["failure"]["domain"], "frame");

            // A separate continuation from the same pre-denial checkpoint.
            let mut resumed = decomposition_case(false, tail, used);
            resumed.0.state = saved;
            let records = collect(&mut resumed, 1);
            assert_eq!(records.len(), 1);
            assert_eq!(records[0].0["transition"], "Match complete");
            assert_eq!(resumed.0.state.entered, vec![0, 1, 2]);
            assert_eq!(records[0].1["release"], json!([]));
            assert_eq!(records[0].1["births"], before["births"]);
            assert_eq!(records[0].1["events"], before["events"]);
            assert_eq!(records[0].1["control"][0]["scope"], json!([["outer", 0]]));
            assert_eq!(collect(&mut resumed, 1)[0].0["transition"], "Branch start");
            assert_eq!(resumed.0.state.entered, vec![0, 1, 2]);
            assert_eq!(attempts(&resumed), [0, 2]);
        }
    }

    #[test]
    fn match_handoff_restores_outer_entered_bindings() {
        // Logical Handoff continuation only, not native Match decomposition.
        let mut run = run(
            "input a: Int; main = match [] do [] -> a; [h|t] -> h end",
            vec![("a".into(), Value::Int("3".into()))],
            [None, None],
        );
        let program = Arc::clone(&run.0.program);
        let state = &mut run.0.state;
        state.started = true;
        state.push_context(program.main, state.entered.clone());
        let Expr::Match(head_decl, tail_decl) = program.nodes[program.main].expr else {
            unreachable!()
        };
        let head = state.binding(&program, head_decl, Val::Int(Arc::new("8".into())), false);
        let tail = state.binding(&program, tail_decl, Val::List(None), false);
        state.contexts[0].scope.extend([head, tail]);
        state.contexts[0].phase = Phase::Handoff;
        state.contexts[0]
            .operands
            .push(Val::Int(Arc::new("8".into())));
        state.entered = state.contexts[0].scope.clone();
        assert_eq!(
            snapshot(&run)["state"]["bindings"]
                .as_array()
                .unwrap()
                .len(),
            3
        );
        let records = collect(&mut run, 1);
        assert_eq!(records[0].0["transition"], "Handoff");
        assert_eq!(
            records[0].1["state"]["bindings"],
            json!([[0, "a", ["n", "3"], "noHolder"]])
        );
        assert_eq!(records[0].1["state"]["branch"], json!(["n", "8"]));
        assert_eq!(records[0].1["ready"], json!(["n", "8"]));
        assert_eq!(records[0].1["control"][0]["scope"], json!([["a", 0]]));
    }

    #[test]
    fn lexical_entry_scopes_survive_shadowing_and_resume() {
        let source = "input x: Int; input z: Int; main = let y = x - z in let x = y + 2 in let y = x - 5 in (x - y) + z";
        let inputs = vec![
            ("x".into(), Value::Int("17".into())),
            ("z".into(), Value::Int("4".into())),
        ];
        let mut whole = run(source, inputs.clone(), [None, None]);
        let expected_run = collect(&mut whole, 128);
        let mut split = run(source, inputs, [None, None]);
        let mut actual_run = Vec::new();
        while split.0.outcome().status == Status::Suspended {
            let records = collect(&mut split, 1);
            let (record, state) = &records[0];
            for context in state["control"].as_array().unwrap() {
                let site = context["site"].as_str().unwrap();
                let expected = if site.starts_with("main/1/1/1") {
                    json!([["x", 3], ["z", 1], ["y", 4]])
                } else if site.starts_with("main/1/1") {
                    json!([["x", 3], ["z", 1], ["y", 2]])
                } else if site.starts_with("main/1") {
                    json!([["x", 0], ["z", 1], ["y", 2]])
                } else {
                    json!([["x", 0], ["z", 1]])
                };
                assert_eq!(
                    context["scope"], expected,
                    "{} at {site}",
                    record["transition"]
                );
            }
            if record["transition"] == "Bind" {
                let expected = match record["site"].as_str().unwrap() {
                    "main" => json!([[0, "x"], [1, "z"], [2, "y"]]),
                    "main/1" => json!([[0, "x"], [1, "z"], [2, "y"], [3, "x"]]),
                    "main/1/1" => json!([[0, "x"], [1, "z"], [2, "y"], [3, "x"], [4, "y"]]),
                    _ => unreachable!(),
                };
                let entered: Vec<_> = state["state"]["bindings"]
                    .as_array()
                    .unwrap()
                    .iter()
                    .map(|b| json!([b[0], b[1]]))
                    .collect();
                assert_eq!(json!(entered), expected);
            }
            actual_run.extend(records);
            let saved = StageA::snapshot(&split);
            assert!(collect(&mut split, 0).is_empty());
            assert_eq!(saved, StageA::snapshot(&split));
        }
        assert_eq!(actual_run, expected_run);
        assert_eq!(attempts(&split), attempts(&whole));
        assert_eq!(
            serde_json::from_slice::<Json>(&StageA::public_output(&split)).unwrap()["value"],
            "9"
        );
    }

    #[test]
    fn match_scope_projection_and_child_entry_keep_separate_environments() {
        // Pure logical projection/child-entry test, not native decomposition.
        // Construct no native cells and invoke no native methods.
        let mut run = run(
            "input h: Int; input tail: ListInt; main = match tail do [] -> h; [h|tail] -> let h = h + 2 in h end",
            vec![
                ("h".into(), Value::Int("9".into())),
                ("tail".into(), Value::ListInt(None)),
            ],
            [None, None],
        );
        let program = Arc::clone(&run.0.program);
        let state = &mut run.0.state;
        state.started = true;
        state.push_context(program.main, state.entered.clone());
        let Expr::Match(head_decl, tail_decl) = program.nodes[program.main].expr else {
            unreachable!()
        };
        let head = state.binding(&program, head_decl, Val::Int(Arc::new("23".into())), false);
        let tail = state.binding(&program, tail_decl, Val::List(None), false);
        state.contexts[0].scope.extend([head, tail]);
        state.contexts[0].phase = Phase::Child(2);
        state.entered = state.contexts[0].scope.clone();
        let before = snapshot(&run);
        assert_eq!(
            before["control"][0]["scope"],
            json!([["h", 0], ["tail", 1]])
        );
        let entered: Vec<_> = before["state"]["bindings"]
            .as_array()
            .unwrap()
            .iter()
            .map(|b| json!([b[0], b[1]]))
            .collect();
        assert_eq!(
            json!(entered),
            json!([[0, "h"], [1, "tail"], [2, "h"], [3, "tail"]])
        );
        let records = collect(&mut run, 1);
        assert_eq!(records[0].0["transition"], "Dispatch compound");
        assert_eq!(records[0].0["site"], "main/2");
        let after = &records[0].1;
        assert_eq!(after["control"][0]["scope"], json!([["h", 0], ["tail", 1]]));
        assert_eq!(after["control"][1]["scope"], json!([["h", 2], ["tail", 3]]));
        assert_eq!(after["state"]["bindings"], before["state"]["bindings"]);
    }

    #[test]
    fn exact_budget_zero_and_terminal_boundary() {
        let mut run = run("main = 17 - 4", vec![], [None, None]);
        let initial = StageA::snapshot(&run);
        assert!(collect(&mut run, 0).is_empty());
        assert_eq!(initial, StageA::snapshot(&run));
        assert_eq!(attempts(&run), [0, 0]);
        let prefix = collect(&mut run, 7);
        assert_eq!(prefix.len(), 7);
        assert_eq!(run.0.outcome().status, Status::Suspended);
        assert_eq!(snapshot(&run)["ready"], json!(["n", "13"]));
        assert_eq!(
            StageA::public_output(&run),
            b"{\"status\":\"suspended\",\"steps\":\"7\"}\n"
        );
        assert_eq!(collect(&mut run, 1).len(), 1);
        assert_eq!(run.0.outcome().status, Status::Finished);
        assert_eq!(
            StageA::public_output(&run),
            b"{\"status\":\"finished\",\"type\":\"Int\",\"value\":\"13\"}\n"
        );
        let terminal = StageA::snapshot(&run);
        let final_attempts = attempts(&run);
        assert!(collect(&mut run, 99).is_empty());
        assert_eq!(terminal, StageA::snapshot(&run));
        assert_eq!(attempts(&run), final_attempts);
    }

    #[test]
    fn segmented_resume_matches_single_execution_without_replay() {
        let source =
            "input x: Int; main = let x = x - 2 in if x <= 3 then 8 else (let y = 4 in x - y) end";
        let mut whole = run(
            source,
            vec![("x".into(), Value::Int("12".into()))],
            [None, None],
        );
        let mut split = run(
            source,
            vec![("x".into(), Value::Int("12".into()))],
            [None, None],
        );
        let expected = collect(&mut whole, 256);
        let mut actual = Vec::new();
        for budget in [1, 2, 0, 5, 3, 1, 4, 256] {
            actual.extend(collect(&mut split, budget));
        }
        assert_eq!(actual, expected);
        assert_eq!(
            StageA::public_output(&split),
            b"{\"status\":\"finished\",\"type\":\"Int\",\"value\":\"6\"}\n"
        );
        assert_eq!(attempts(&split), attempts(&whole));
        let numbers = attempts(&split)[0];
        StageA::snapshot(&split);
        StageA::public_output(&split);
        assert_eq!(attempts(&split)[0], numbers);
    }

    #[test]
    fn scalar_program_results_are_source_driven() {
        for (source, kind, value) in [
            ("main = 23 - 8 - 6", "Int", json!("9")),
            ("main = 23 - (8 - 6)", "Int", json!("21")),
            ("main = if false then 41 else - 9 end", "Int", json!("-9")),
            ("main = 4 < -2", "Bool", json!(false)),
            ("main = -5 + 2 == -3", "Bool", json!(true)),
            (
                "main = 999999999999999999999999999999 + 9",
                "Int",
                json!("1000000000000000000000000000008"),
            ),
            ("main = []", "ListInt", json!([])),
        ] {
            let mut run = run(source, vec![], [None, None]);
            collect(&mut run, 256);
            let output: Json = serde_json::from_slice(&StageA::public_output(&run)).unwrap();
            assert_eq!(
                output,
                json!({"status":"finished","type":kind,"value":value}),
                "{source}"
            );
        }
    }

    #[test]
    fn empty_match_observes_branch_result_and_handoff() {
        let mut run = run(
            "main = match [] do [] -> 37; [h|t] -> h end",
            vec![],
            [None, None],
        );
        let records = collect(&mut run, 128);
        let names: Vec<_> = records
            .iter()
            .map(|(r, _)| r["transition"].as_str().unwrap())
            .collect();
        assert_eq!(
            names,
            [
                "Start",
                "Dispatch compound",
                "Leaf",
                "Choose branch",
                "Branch start",
                "Leaf",
                "Branch result/cleanup",
                "Handoff",
                "Finish"
            ]
        );
        assert_eq!(records[3].0["births_added"], json!([]));
        assert_eq!(records[3].1["births"], json!([]));
        let branch_birth = json!([{"domain":"branch","id":0,"origin":"main","invocation":0}]);
        assert_eq!(records[4].0["births_added"], branch_birth);
        assert_eq!(records[4].1["births"], branch_birth);
        assert!(
            records[5..]
                .iter()
                .all(|(r, _)| r["births_added"] == json!([]))
        );
        let results: Vec<_> = records
            .iter()
            .filter(|(_, s)| !s["state"]["branch"].is_null())
            .collect();
        assert_eq!(results.len(), 2);
        assert_eq!(results[0].1["state"]["branch"], json!(["n", "37"]));
        assert_eq!(results[1].1["state"]["branch"], json!(["n", "37"]));
        assert_eq!(
            snapshot(&run)["births"],
            json!([{"domain":"branch","id":0,"origin":"main","invocation":0}])
        );
        assert_eq!(snapshot(&run)["events"], json!([]));
    }

    #[test]
    fn match_births_follow_scrutinee_execution_order_across_resume() {
        let mut run = run(
            "main = match (match [] do [] -> []; [h|t] -> t end) do [] -> if true then 8 else 9 end; [h|t] -> h end",
            vec![],
            [None, None],
        );
        let mut seen = Vec::new();
        while run.0.outcome().status == Status::Suspended {
            let records = collect(&mut run, 1);
            let (record, state) = &records[0];
            let births: Vec<_> = state["births"]
                .as_array()
                .unwrap()
                .iter()
                .map(|b| b["origin"].clone())
                .collect();
            let added: Vec<_> = record["births_added"]
                .as_array()
                .unwrap()
                .iter()
                .map(|b| b["origin"].clone())
                .collect();
            if record["transition"] == "Choose branch" || record["transition"] == "Branch start" {
                seen.push(json!([record["transition"], record["site"], births, added]));
            } else {
                assert!(added.is_empty());
            }
            let saved = StageA::snapshot(&run);
            assert!(collect(&mut run, 0).is_empty());
            assert_eq!(saved, StageA::snapshot(&run));
        }
        assert_eq!(
            seen,
            vec![
                json!(["Choose branch", "main/0", [], []]),
                json!(["Branch start", "main/0", ["main/0"], ["main/0"]]),
                json!(["Choose branch", "main", ["main/0"], []]),
                json!(["Branch start", "main", ["main/0", "main"], ["main"]]),
                json!(["Choose branch", "main/1", ["main/0", "main"], []]),
                json!(["Branch start", "main/1", ["main/0", "main"], []]),
            ]
        );
        let state = snapshot(&run);
        assert_ne!(state["births"][0]["id"], state["births"][1]["id"]);
        assert!(
            state["births"]
                .as_array()
                .unwrap()
                .iter()
                .all(|b| b["domain"] == "branch" && b["invocation"] == 0)
        );
        assert_eq!(
            serde_json::from_slice::<Json>(&StageA::public_output(&run)).unwrap()["value"],
            "8"
        );
    }

    #[test]
    fn match_birth_preparation_precedes_cleanup_and_rolls_back_on_denial() {
        // Opaque holder identities only: the Number gate denies BEFORE any
        // native read. No native cells are constructed, read or emulated.
        for (source, inputs, cleanup) in [
            (
                "input xs: ListInt; main = match [] do [] -> []; [h|t] -> xs end",
                vec![("xs".into(), Value::ListInt(Some(41)))],
                true,
            ),
            (
                "input xs: ListInt; main = match xs do [] -> 0; [h|t] -> h end",
                vec![("xs".into(), Value::ListInt(Some(73)))],
                false,
            ),
            (
                "input xs: ListInt; input ys: ListInt; main = match xs do [] -> ys; [h|t] -> t end",
                vec![
                    ("xs".into(), Value::ListInt(Some(73))),
                    ("ys".into(), Value::ListInt(Some(41))),
                ],
                true,
            ),
        ] {
            let mut run = run(source, inputs, [Some(1), None]);
            let prefix = collect(&mut run, 4);
            assert_eq!(prefix.last().unwrap().0["transition"], "Choose branch");
            let before = snapshot(&run);
            assert!(
                before["births"]
                    .as_array()
                    .unwrap()
                    .iter()
                    .all(|b| b["domain"] != "branch")
            );
            assert_eq!(!run.0.state.cleanup.is_empty(), cleanup);
            // Inspect the real executor's uncommitted logical preparation at a
            // denied read, separately from Machine's committed-state rollback.
            let gates = Resources::NoCells {
                attempts: std::array::from_fn(|_| std::cell::Cell::new(0)),
                deny: [Some(1), None],
            };
            let mut staged = run.0.state.clone();
            let fault = execute(&run.0.program, &gates, &mut staged).err().unwrap();
            assert_eq!(fault.domain, Some("number"));
            assert_eq!(staged.births.len(), run.0.state.births.len() + 1);
            assert_eq!(staged.births.last().unwrap()["origin"], "main");
            assert_eq!(staged.births.last().unwrap()["domain"], "branch");
            assert!(staged.contexts.last().unwrap().branch.is_some());
            assert!(collect(&mut run, 1).is_empty());
            let after = snapshot(&run);
            for field in [
                "step", "state", "control", "ready", "release", "events", "births",
            ] {
                assert_eq!(before[field], after[field], "{field}");
            }
            assert_eq!(after["failure"]["domain"], "number");
            assert_eq!(run.0.state.next_branch, 0);
        }
        for denied_frame in [5, 6] {
            let mut run = run(
                "main = match [] do [] -> 12; [h|t] -> h end",
                vec![],
                [None, Some(denied_frame)],
            );
            collect(&mut run, denied_frame - 1);
            let before = snapshot(&run);
            assert_eq!(
                before["births"].as_array().unwrap().len(),
                usize::from(denied_frame == 6)
            );
            assert!(collect(&mut run, 1).is_empty());
            assert_eq!(before["births"], snapshot(&run)["births"]);
            assert_eq!(snapshot(&run)["failure"]["domain"], "frame");
        }
    }

    #[test]
    fn number_denial_preserves_committed_prefix_and_is_terminal() {
        let mut run = run("main = 17 - 4", vec![], [Some(3), None]);
        assert_eq!(collect(&mut run, 6).len(), 6);
        let before = snapshot(&run);
        assert!(collect(&mut run, 1).is_empty());
        assert_eq!(run.0.outcome().status, Status::Failed);
        let after = snapshot(&run);
        for field in [
            "step",
            "state",
            "control",
            "ready",
            "release",
            "event_end",
            "events",
            "births",
            "cleanup_events",
        ] {
            assert_eq!(before[field], after[field], "{field}");
        }
        assert_eq!(
            after["failure"],
            json!({"class":"resource-exhausted","step":6,"domain":"number","aborts":[]})
        );
        assert_eq!(
            StageA::public_output(&run),
            b"{\"status\":\"failed\",\"class\":\"resource-exhausted\",\"step\":\"6\"}\n"
        );
        let counts = attempts(&run);
        assert!(collect(&mut run, 100).is_empty());
        assert_eq!(attempts(&run), counts);
        StageA::destroy(&mut run).unwrap_or_else(|e| panic!("{}", e.class));
        let destroyed = StageA::snapshot(&run);
        StageA::destroy(&mut run).unwrap_or_else(|e| panic!("{}", e.class));
        assert_eq!(destroyed, StageA::snapshot(&run));
    }

    #[test]
    fn frame_denial_before_first_action_preserves_zero_state() {
        let mut run = run("main = true", vec![], [None, Some(1)]);
        let before = snapshot(&run);
        assert!(collect(&mut run, 1).is_empty());
        let after = snapshot(&run);
        assert_eq!(after["step"], 0);
        for field in ["state", "control", "ready", "events", "births"] {
            assert_eq!(before[field], after[field]);
        }
        assert_eq!(after["failure"]["domain"], "frame");
        assert_eq!(attempts(&run), [0, 1]);
    }

    #[test]
    fn snapshots_omit_host_owned_fields_and_do_not_consume_gates() {
        let mut run = run(
            "input n: Int; main = let n = n + 2 in n",
            vec![("n".into(), Value::Int("41".into()))],
            [None, None],
        );
        collect(&mut run, 3);
        let counts = attempts(&run);
        let state = snapshot(&run);
        let keys: BTreeSet<_> = state["state"]
            .as_object()
            .unwrap()
            .keys()
            .map(String::as_str)
            .collect();
        assert_eq!(
            keys,
            BTreeSet::from(["kind", "bindings", "pending", "aside", "branch", "frames"])
        );
        assert_eq!(state["state"]["bindings"][0][2], json!(["n", "41"]));
        for _ in 0..3 {
            StageA::snapshot(&run);
            StageA::public_output(&run);
        }
        assert_eq!(counts, attempts(&run));
    }

    #[test]
    fn ownership_liveness_uses_declarations_and_chosen_branch() {
        // These are logical holder identities only. No native cells are built,
        // supplied, read, or emulated by this ownership-analysis unit test.
        let program =
            program("input x: ListInt; input y: ListInt; main = if true then x else y end");
        let mut state = State::begin(
            &program,
            vec![
                ("y".into(), Value::ListInt(Some(19))),
                ("x".into(), Value::ListInt(Some(71))),
            ],
        );
        assert!(state.cleanup.is_empty());
        assert_eq!(state.bindings[0].value.list(), Some(71));
        assert_eq!(state.bindings[1].value.list(), Some(19));
        state.push_context(program.main, state.entered.clone());
        state.contexts[0].phase = Phase::Choose;
        assert_eq!(
            state.remaining(&program),
            BTreeSet::from([program.inputs[0].declaration, program.inputs[1].declaration])
        );
        state.contexts[0].selected = 1;
        state.contexts[0].phase = Phase::BranchStart;
        state.queue_unused(&program, &state.entered.clone());
        assert_eq!(state.cleanup, VecDeque::from([1]));
        assert_eq!(state.bindings[1].holder.name(), "holding");
        assert!(state.release.is_empty());
        assert!(state.events.is_empty());
    }

    #[test]
    fn every_small_scalar_allocation_denial_preserves_its_prefix() {
        let source = "main = let a = 17 - 6 in if a < 0 then 4 else a + 9 end";
        let mut baseline = run(source, vec![], [None, None]);
        let initial = snapshot(&baseline);
        let records = collect(&mut baseline, 128);
        let total_attempts = attempts(&baseline);
        assert_eq!(
            serde_json::from_slice::<Json>(&StageA::public_output(&baseline)).unwrap()["value"],
            "20"
        );
        for domain in 0..2 {
            for ordinal in 1..=total_attempts[domain] {
                let mut denial = [None, None];
                denial[domain] = Some(ordinal);
                let mut failed = run(source, vec![], denial);
                let committed = collect(&mut failed, 128);
                assert_eq!(failed.0.status(), Status::Failed);
                assert_eq!(committed, &records[..committed.len()]);
                let reference = committed.last().map_or(&initial, |(_, state)| state);
                let actual = snapshot(&failed);
                for field in [
                    "step",
                    "state",
                    "control",
                    "ready",
                    "release",
                    "event_end",
                    "events",
                    "births",
                ] {
                    assert_eq!(
                        actual[field], reference[field],
                        "domain {domain}, ordinal {ordinal}, field {field}"
                    );
                }
            }
        }
    }

    #[test]
    fn release_bookkeeping_retains_parent_until_descendant_cleanup() {
        let program = program("input xs: ListInt; main = 0");
        let mut state = State::begin(&program, vec![("xs".into(), Value::ListInt(Some(9)))]);
        state.pending = vec![33];
        let parent = state.start_release().unwrap();
        assert_eq!(parent.cell, 9);
        assert_eq!(parent.binding, Some(0));
        state.gave_up(&parent, 0);
        assert_eq!(state.bindings[0].holder.name(), "givenUp");
        assert!(matches!(state.release[0].phase, ReleasePhase::Free));
        assert!(state.events.is_empty());
        assert_eq!(state.pending, [33]);
        assert!(matches!(
            state.start_release().unwrap().phase,
            ReleasePhase::Free
        ));
        state.freed(9, Some(15));
        assert_eq!(
            state.release.iter().map(|r| r.cell).collect::<Vec<_>>(),
            [9, 15]
        );
        assert!(matches!(state.release[0].phase, ReleasePhase::Waiting));
        assert!(matches!(state.release[1].phase, ReleasePhase::Queued));
        assert_eq!(state.pending, [15, 33]);
        let child = state.start_release().unwrap();
        assert!(matches!(child.phase, ReleasePhase::Give));
        state.gave_up(&child, 0);
        assert_eq!(state.pending, [33]);
        assert_eq!(state.events, vec![json!(["free", 9])]);
        state.freed(15, None);
        assert_eq!(
            state.release.iter().map(|r| r.cell).collect::<Vec<_>>(),
            [9, 15]
        );
        assert_eq!(state.events, vec![json!(["free", 9]), json!(["free", 15])]);
        assert!(state.start_release().is_none());
        assert!(state.release.is_empty());
        assert_eq!(state.pending, [33]);
    }

    #[test]
    fn shared_holder_release_consumes_only_one_pending_holder() {
        let program = program("main = 0");
        let mut state = State::begin(&program, vec![]);
        state.pending = vec![9, 42, 9];
        let release = Release {
            cell: 9,
            phase: ReleasePhase::Give,
            binding: None,
        };
        state.release.push(release.clone());
        state.gave_up(&release, 2);
        assert_eq!(state.pending, [42, 9]);
        assert_eq!(
            state.release.iter().map(|r| r.cell).collect::<Vec<_>>(),
            [9]
        );
        assert!(state.events.is_empty());
        assert!(state.start_release().is_none());
        assert!(state.release.is_empty());
        assert_eq!(state.pending, [42, 9]);
    }

    #[test]
    fn free_callback_protects_but_does_not_activate_its_tail() {
        // Logical ledger helpers only, with no native cell storage or calls.
        let mut run = run("main = 0", vec![], [None, None]);
        let release = Release {
            cell: 57,
            phase: ReleasePhase::Give,
            binding: None,
        };
        run.0.state.pending = vec![57, 81];
        run.0.state.release.push(release.clone());
        run.0.state.gave_up(&release, 0);
        assert_eq!(snapshot(&run)["release"], json!([57]));
        run.0.state.freed(57, Some(26));
        assert_eq!(snapshot(&run)["release"], json!([57]));
        assert_eq!(run.0.state.pending, [26, 81]);
        assert_eq!(run.0.state.events, vec![json!(["free", 57])]);
        let child = run.0.state.start_release().unwrap();
        run.0.state.gave_up(&child, 2);
        assert_eq!(snapshot(&run)["release"], json!([57, 26]));
        assert_eq!(run.0.state.pending, [81]);
        assert!(run.0.state.start_release().is_none());
        assert_eq!(snapshot(&run)["release"], json!([]));
        assert_eq!(run.0.state.events, vec![json!(["free", 57])]);
    }

    #[test]
    fn queued_release_activation_is_not_published_when_denied() {
        for deny in [[Some(1), None], [None, Some(1)]] {
            // Deny before any native call; these IDs have no native storage.
            let mut run = run("main = 5", vec![], deny);
            run.0.state.pending.push(71);
            run.0.state.release.push(Release {
                cell: 71,
                phase: ReleasePhase::Queued,
                binding: None,
            });
            let before = snapshot(&run);
            assert_eq!(before["release"], json!([]));
            assert!(collect(&mut run, 1).is_empty());
            let after = snapshot(&run);
            assert_eq!(run.0.outcome().status, Status::Failed);
            for field in [
                "step", "state", "control", "ready", "release", "events", "births",
            ] {
                assert_eq!(before[field], after[field], "{field}");
            }
            assert!(matches!(run.0.state.release[0].phase, ReleasePhase::Queued));
        }
    }

    #[test]
    fn completed_release_unwinds_on_resume_not_in_its_callback() {
        for deny in [Some(1), None] {
            // A logical completed-release continuation, not a native fixture.
            let mut run = run("main = 5", vec![], [deny, None]);
            run.0.state.started = true;
            run.0.state.step = 7;
            run.0.state.release.push(Release {
                cell: 68,
                phase: ReleasePhase::Waiting,
                binding: None,
            });
            let before = snapshot(&run);
            assert_eq!(before["release"], json!([68]));
            assert!(collect(&mut run, 0).is_empty());
            assert_eq!(before, snapshot(&run));
            let next = collect(&mut run, 1);
            if deny.is_some() {
                assert!(next.is_empty());
                let after = snapshot(&run);
                for field in [
                    "step", "state", "control", "ready", "release", "events", "births",
                ] {
                    assert_eq!(before[field], after[field], "{field}");
                }
            } else {
                assert_eq!(next.len(), 1);
                assert_eq!(next[0].0["transition"], "Leaf");
                assert_eq!(next[0].0["step"], 8);
                assert_eq!(next[0].1["release"], json!([]));
                assert_eq!(next[0].1["ready"], json!(["n", "5"]));
            }
            // Destruction discards completed release bookkeeping, even after
            // a denial preserved it. No native read/free may be attempted.
            StageA::destroy(&mut run).unwrap_or_else(|e| panic!("{}", e.class));
            assert_eq!(snapshot(&run)["release"], json!([]));
            assert_eq!(snapshot(&run)["cleanup_events"], json!([]));
            let destroyed = StageA::snapshot(&run);
            StageA::destroy(&mut run).unwrap_or_else(|e| panic!("{}", e.class));
            assert_eq!(destroyed, StageA::snapshot(&run));
        }
    }
}
