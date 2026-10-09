//! Acceptance-owned physical storage preparation, NOT a Mo interpreter.
//! Runtime capability cannot inspect provenance, pointers, event logs or faults.
//! The observer capability stays with acceptance. No evaluator/arithmetic here.
use std::cell::RefCell;
use std::collections::BTreeMap;
use std::rc::Rc;

pub use mo_acceptance_runtime::{Cell, Error, Resource, RuntimeCells};
#[path = "../runtime/abi.rs"]
mod abi;
mod host;
mod linkage;
pub use host::{Cursor, Delta, FixtureError, Phase, ResourceAttempt};

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Event {
    pub kind: &'static str,
    pub lifetime: u64,
    pub pointer: usize,
    pub phase: Phase,
}

#[derive(Default)]
struct Store {
    cells: BTreeMap<u64, Box<Cell>>,
    events: Vec<Event>,
    mutations: Vec<Event>,
    next: u64,
    attempts: u64,
    fail_at: Option<u64>,
    create_log: Vec<(u64, bool, Phase)>,
    resource_attempts: BTreeMap<Resource, u64>,
    resource_failures: BTreeMap<Resource, u64>,
    resource_log: Vec<ResourceAttempt>,
    phase: Phase,
    reads: u64,
    fixture_installed: bool,
}

struct Backend(Rc<RefCell<Store>>);
pub struct Observer(Rc<RefCell<Store>>);

impl Store {
    fn record(&mut self, kind: &'static str, lifetime: u64, pointer: usize) {
        let event = Event {
            kind,
            lifetime,
            pointer,
            phase: self.phase,
        };
        self.mutations.push(event.clone());
        if matches!(kind, "fixture" | "create" | "write" | "free") {
            self.events.push(event);
        }
    }
}

/// Host-only fixture construction. Caller validates the graph before this call.
/// All fixtures and source-created cells use identical boxed storage.
pub fn fixture(rows: Vec<(u64, Cell)>) -> (RuntimeCells, Observer) {
    let mut store = Store::default();
    store.fixture_installed = !rows.is_empty();
    store.phase = Phase::Fixture;
    for (id, cell) in rows {
        assert!(!store.cells.contains_key(&id), "duplicate fixture cell");
        store.next = store.next.max(id.checked_add(1).expect("fixture ID range"));
        let cell = Box::new(cell);
        store.record("fixture", id, &*cell as *const Cell as usize);
        store.cells.insert(id, cell);
    }
    store.phase = Phase::Frontend;
    let shared = Rc::new(RefCell::new(store));
    (
        linkage::capability(Backend(shared.clone())),
        Observer(shared),
    )
}

impl Backend {
    /// Acceptance-controlled pre-allocation gate for the candidate's numeric
    /// backend/frame store. Source inspection must establish complete routing;
    /// this hook alone cannot detect a candidate that bypasses it.
    pub fn allocate<T>(
        &self,
        domain: Resource,
        allocation: impl FnOnce() -> T,
    ) -> Result<T, Error> {
        let mut store = self.0.borrow_mut();
        let attempt = store.resource_attempts.entry(domain).or_default();
        *attempt = attempt.checked_add(1).expect("resource attempt range");
        let ordinal = *attempt;
        let allowed = store.resource_failures.get(&domain) != Some(&ordinal);
        let phase = store.phase;
        store.resource_log.push(ResourceAttempt {
            domain,
            ordinal,
            allowed,
            phase,
        });
        drop(store);
        if allowed {
            Ok(allocation())
        } else {
            Err(Error::InjectedAllocationFailure)
        }
    }

    pub fn read(&self, id: u64) -> Result<Cell, Error> {
        let mut store = self.0.borrow_mut();
        store.reads = store.reads.checked_add(1).expect("read counter range");
        store
            .cells
            .get(&id)
            .map(|c| (**c).clone())
            .ok_or(Error::UnknownCell)
    }
    pub fn create(&self, cell: Cell) -> Result<u64, Error> {
        let mut store = self.0.borrow_mut();
        store.attempts = store.attempts.checked_add(1).expect("cell attempt range");
        let ordinal = store.attempts;
        let allowed = store.fail_at != Some(ordinal);
        let phase = store.phase;
        store.create_log.push((ordinal, allowed, phase));
        if !allowed {
            return Err(Error::InjectedAllocationFailure);
        }
        let id = store.next;
        store.next = id.checked_add(1).expect("lifetime ID range");
        let cell = Box::new(cell);
        store.record("create", id, &*cell as *const Cell as usize);
        store.cells.insert(id, cell);
        Ok(id)
    }
    /// Rebuilding a reserved cell preserves its actual Box allocation.
    pub fn write(&self, id: u64, item: String, tail: Option<u64>) -> Result<(), Error> {
        let mut store = self.0.borrow_mut();
        let cell = store.cells.get_mut(&id).ok_or(Error::UnknownCell)?;
        cell.item = item;
        cell.tail = tail;
        let pointer = &**cell as *const Cell as usize;
        store.record("write", id, pointer);
        Ok(())
    }
    /// Unique match decomposition is not a counted Rebuild/Write operation.
    pub fn detach(&self, id: u64) -> Result<Option<u64>, Error> {
        let mut store = self.0.borrow_mut();
        let cell = store.cells.get_mut(&id).ok_or(Error::UnknownCell)?;
        if cell.holders != 1 || cell.aside {
            return Err(Error::InvalidDetach);
        }
        let tail = cell.tail.take();
        cell.holders = 0;
        cell.aside = true;
        let pointer = &**cell as *const Cell as usize;
        store.record("detach", id, pointer);
        Ok(tail)
    }
    /// Bookkeeping changes are not the trial's item/link Write operation.
    pub fn metadata(&self, id: u64, holders: u64, aside: bool) -> Result<(), Error> {
        let mut store = self.0.borrow_mut();
        let cell = store.cells.get_mut(&id).ok_or(Error::UnknownCell)?;
        cell.holders = holders;
        cell.aside = aside;
        let pointer = &**cell as *const Cell as usize;
        store.record("metadata", id, pointer);
        Ok(())
    }
    pub fn free(&self, id: u64) -> Result<(), Error> {
        let mut store = self.0.borrow_mut();
        let cell = store.cells.remove(&id).ok_or(Error::UnknownCell)?;
        store.record("free", id, &*cell as *const Cell as usize);
        drop(cell);
        Ok(())
    }
}

impl Observer {
    pub fn events(&self) -> Vec<Event> {
        self.0.borrow().events.clone()
    }
    pub fn mutations(&self) -> Vec<Event> {
        self.0.borrow().mutations.clone()
    }
    pub fn graph(&self) -> Vec<(u64, Cell, usize)> {
        self.0
            .borrow()
            .cells
            .iter()
            .map(|(&id, c)| (id, (**c).clone(), &**c as *const Cell as usize))
            .collect()
    }
    /// One-based source-create attempt, excludes fixture construction.
    pub fn fail_create(&self, attempt: u64) {
        assert!(attempt > 0, "one-based cell attempt");
        self.0.borrow_mut().fail_at = Some(attempt);
    }

    pub fn fail_resource(&self, domain: Resource, attempt: u64) {
        assert!(attempt > 0, "one-based resource attempt");
        self.0
            .borrow_mut()
            .resource_failures
            .insert(domain, attempt);
    }

    pub fn resource_log(&self) -> Vec<(Resource, u64, bool)> {
        self.0
            .borrow()
            .resource_log
            .iter()
            .map(|r| (r.domain, r.ordinal, r.allowed))
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    fn cell(n: &str) -> Cell {
        Cell {
            item: n.into(),
            tail: None,
            holders: 1,
            aside: false,
        }
    }
    #[test]
    fn actual_rebuild_preserves_live_object_and_records_real_contents() {
        let (api, observer) = fixture(vec![(7, cell("3"))]);
        let pointer = observer.graph()[0].2;
        api.metadata(7, 0, true).unwrap();
        api.write(7, "4".into(), None).unwrap();
        api.metadata(7, 1, false).unwrap();
        assert_eq!(observer.graph(), vec![(7, cell("4"), pointer)]);
        assert_eq!(
            observer.events().iter().map(|e| e.kind).collect::<Vec<_>>(),
            vec!["fixture", "write"]
        );
        assert!(observer.events().iter().all(|e| e.pointer == pointer));
    }
    #[test]
    fn retired_lifetime_never_reused_even_if_allocator_recycles_address() {
        let (api, observer) = fixture(vec![]);
        let first = api.create(cell("3")).unwrap();
        api.free(first).unwrap();
        let next = api.create(cell("7")).unwrap();
        assert_ne!(first, next);
        assert_eq!(api.read(first), Err(Error::UnknownCell));
        assert_eq!(
            observer.events().iter().map(|e| e.kind).collect::<Vec<_>>(),
            vec!["create", "free", "create"]
        );
    }
    #[test]
    fn denied_creation_leaves_graph_and_primitive_prefix_unchanged() {
        let (api, observer) = fixture(vec![(4, cell("9"))]);
        let graph = observer.graph();
        let events = observer.events();
        observer.fail_create(1);
        assert_eq!(api.create(cell("7")), Err(Error::InjectedAllocationFailure));
        assert_eq!(observer.graph(), graph);
        assert_eq!(observer.events(), events);
        assert_eq!(api.create(cell("8")), Ok(5));
    }
    #[test]
    fn freeing_run_owned_cell_does_not_free_outside_cell() {
        let (api, observer) = fixture(vec![(1, cell("11")), (2, cell("-7"))]);
        let outside_pointer = observer.graph()[1].2;
        api.free(1).unwrap();
        assert_eq!(observer.graph(), vec![(2, cell("-7"), outside_pointer)]);
        assert_eq!(api.free(1), Err(Error::UnknownCell));
    }
    #[test]
    fn actual_detachment_is_visible_without_counting_a_rebuild() {
        let mut head = cell("3");
        head.tail = Some(2);
        let (api, observer) = fixture(vec![(1, head), (2, cell("7"))]);
        let pointer = observer.graph()[0].2;
        assert_eq!(api.detach(1), Ok(Some(2)));
        assert_eq!(
            api.read(1).unwrap(),
            Cell {
                item: "3".into(),
                tail: None,
                holders: 0,
                aside: true
            }
        );
        assert_eq!(observer.graph()[0].2, pointer);
        assert_eq!(observer.events().len(), 2);
        assert_eq!(observer.mutations().last().unwrap().kind, "detach");
        assert_eq!(api.detach(1), Err(Error::InvalidDetach));
        api.metadata(2, 2, false).unwrap();
        assert_eq!(api.detach(2), Err(Error::InvalidDetach));
    }

    #[test]
    #[should_panic(expected = "live allocation changed")]
    fn compiled_replacement_control_fails_pointer_continuity() {
        let (api, observer) = fixture(vec![(7, cell("3"))]);
        let pointer = observer.graph()[0].2;
        // Deliberately broken STORAGE control, not an interpreter: replace a
        // still-live allocation while retaining its logical ID and contents.
        // Allocate before dropping the old Box so address recycling cannot
        // accidentally disguise this particular violation.
        let replacement = Box::new(api.read(7).unwrap());
        observer.0.borrow_mut().cells.insert(7, replacement);
        api.write(7, "4".into(), None).unwrap();
        assert_eq!(
            observer.events().last().unwrap().pointer,
            pointer,
            "live allocation changed"
        );
    }

    #[test]
    fn numeric_frame_gates_are_independent_and_deny_before_allocation() {
        let (api, observer) = fixture(vec![(7, cell("3"))]);
        let graph = observer.graph();
        let events = observer.events();
        observer.fail_resource(Resource::Number, 2);
        observer.fail_resource(Resource::Frame, 1);
        assert_eq!(
            api.allocate(Resource::Number, || Box::new(17)),
            Ok(Box::new(17))
        );
        let allocated = std::cell::Cell::new(false);
        for domain in [Resource::Frame, Resource::Number] {
            let failure = api.allocate(domain, || {
                allocated.set(true);
                Box::new(23)
            });
            assert_eq!(failure, Err(Error::InjectedAllocationFailure));
        }
        assert!(!allocated.get());
        assert_eq!(observer.graph(), graph);
        assert_eq!(observer.events(), events);
        assert_eq!(
            observer.resource_log(),
            vec![
                (Resource::Number, 1, true),
                (Resource::Frame, 1, false),
                (Resource::Number, 2, false)
            ]
        );
    }
}
