//! Builder-visible capability and candidate interface; no observer or host controls.
mod abi;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Cell {
    pub item: String,
    pub tail: Option<u64>,
    pub holders: u64,
    pub aside: bool,
}
#[derive(Debug, PartialEq, Eq)]
pub enum Error {
    InjectedAllocationFailure,
    UnknownCell,
    InvalidDetach,
}
#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub enum Resource {
    Number,
    Frame,
}

/// Opaque, non-Clone, non-Send capability. There is no safe public constructor.
/// Only the version-matched acceptance host may construct its private handle.
#[repr(transparent)]
pub struct RuntimeCells(abi::Handle);

impl Drop for RuntimeCells {
    fn drop(&mut self) {
        // SAFETY: host constructs one owning handle, with a valid function table
        // and context, transferred exactly once; no Clone or constructor escapes.
        unsafe { (self.0.functions.drop)(self.0.context) }
    }
}
impl RuntimeCells {
    pub fn allocate<T>(
        &self,
        domain: Resource,
        allocation: impl FnOnce() -> T,
    ) -> Result<T, Error> {
        // SAFETY: all dispatches use the live host context and matching ABI.
        // The gate returns (and releases host borrows) BEFORE invoking the closure.
        unsafe {
            (self.0.functions.gate)(self.0.context, domain)?;
        }
        Ok(allocation())
    }
    pub fn read(&self, id: u64) -> Result<Cell, Error> {
        unsafe { (self.0.functions.read)(self.0.context, id) }
    }
    pub fn create(&self, cell: Cell) -> Result<u64, Error> {
        unsafe { (self.0.functions.create)(self.0.context, cell) }
    }
    pub fn write(&self, id: u64, item: String, tail: Option<u64>) -> Result<(), Error> {
        unsafe { (self.0.functions.write)(self.0.context, id, item, tail) }
    }
    pub fn detach(&self, id: u64) -> Result<Option<u64>, Error> {
        unsafe { (self.0.functions.detach)(self.0.context, id) }
    }
    pub fn metadata(&self, id: u64, holders: u64, aside: bool) -> Result<(), Error> {
        unsafe { (self.0.functions.metadata)(self.0.context, id, holders, aside) }
    }
    pub fn free(&self, id: u64) -> Result<(), Error> {
        unsafe { (self.0.functions.free)(self.0.context, id) }
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Kind {
    Int,
    Bool,
    ListInt,
}
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Value {
    Int(String),
    Bool(bool),
    ListInt(Option<u64>),
}
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Span {
    Text { start: (u64, u64), end: (u64, u64) },
    Bytes { start: u64, end: u64 },
}
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Diagnostic {
    pub class: String,
    pub span: Span,
}
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum CheckFailure {
    Refused(Diagnostic),
    Failed {
        class: String,
        domain: Option<Resource>,
    },
}
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Status {
    Suspended,
    Finished,
    Failed,
}
pub struct Outcome {
    pub status: Status,
    pub committed_steps: u64,
}
pub struct CleanupFailure {
    pub class: String,
}

pub trait Candidate {
    type CheckedProgram;
    type Run;
    fn check_source(
        source: &[u8],
        allocations: &RuntimeCells,
    ) -> Result<Self::CheckedProgram, CheckFailure>;
    fn checked_dump(program: &Self::CheckedProgram) -> Vec<u8>;
    fn source_spans(program: &Self::CheckedProgram) -> Vec<u8>;
    fn begin(
        program: &Self::CheckedProgram,
        inputs: Vec<(String, Value)>,
        cells: RuntimeCells,
    ) -> Self::Run;
    fn advance(
        run: &mut Self::Run,
        budget: u64,
        committed: &mut dyn FnMut(&Self::Run, &[u8]),
    ) -> Outcome;
    fn snapshot(run: &Self::Run) -> Vec<u8>;
    fn public_output(run: &Self::Run) -> Vec<u8>;
    fn destroy(run: &mut Self::Run) -> Result<(), CleanupFailure>;
}
