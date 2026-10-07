//! Acceptance-only same-store fixture transaction and incremental observation.
use crate::{Cell, Event, Observer, Resource};
use std::collections::{BTreeMap, BTreeSet};

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum Phase {
    #[default]
    Frontend,
    Fixture,
    Begin,
    Execution,
    Destroy,
    Teardown,
}
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ResourceAttempt {
    pub domain: Resource,
    pub ordinal: u64,
    pub allowed: bool,
    pub phase: Phase,
}
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct Cursor {
    pub events: usize,
    pub mutations: usize,
    pub resources: usize,
    pub creates: usize,
}
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Delta {
    pub cursor: Cursor,
    pub events: Vec<Event>,
    pub mutations: Vec<Event>,
    pub resources: Vec<ResourceAttempt>,
    pub creates: Vec<(u64, bool, Phase)>,
}
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct FixtureError {
    pub class: &'static str,
    pub path: String,
}

fn invalid(class: &'static str, path: impl Into<String>) -> FixtureError {
    FixtureError {
        class,
        path: path.into(),
    }
}
fn decimal(n: &str) -> bool {
    if n == "0" {
        return true;
    }
    let digits = n.strip_prefix('-').unwrap_or(n).as_bytes();
    !digits.is_empty()
        && (b'1'..=b'9').contains(&digits[0])
        && digits.iter().all(u8::is_ascii_digit)
}

impl Observer {
    pub fn phase(&self, phase: Phase) {
        self.0.borrow_mut().phase = phase;
    }

    /// Copies only the unseen suffix, never the whole prefix. Future/stale
    /// positions are integrity errors, not empty observations or implicit resets.
    pub fn since(&self, cursor: Cursor) -> Result<Delta, &'static str> {
        let s = self.0.borrow();
        let next = Cursor {
            events: s.events.len(),
            mutations: s.mutations.len(),
            resources: s.resource_log.len(),
            creates: s.create_log.len(),
        };
        if cursor.events > next.events
            || cursor.mutations > next.mutations
            || cursor.resources > next.resources
            || cursor.creates > next.creates
        {
            return Err("observer cursor ahead");
        }
        Ok(Delta {
            cursor: next,
            events: s.events[cursor.events..].to_vec(),
            mutations: s.mutations[cursor.mutations..].to_vec(),
            resources: s.resource_log[cursor.resources..].to_vec(),
            creates: s.create_log[cursor.creates..].to_vec(),
        })
    }

    pub fn frontend_clean(&self) -> bool {
        let s = self.0.borrow();
        s.reads == 0
            && s.attempts == 0
            && s.mutations.is_empty()
            && s.resource_attempts
                .get(&Resource::Frame)
                .copied()
                .unwrap_or(0)
                == 0
    }

    /// Caller also checks declared input names/types with the independent source
    /// contract. Roots include input holders AND outside holders (duplicates count).
    /// Staged Box allocations drop on any error; no store/event/ID/log change.
    pub fn install(
        &self,
        rows: Vec<(u64, Cell)>,
        roots: &[Option<u64>],
    ) -> Result<(), FixtureError> {
        let mut s = self.0.borrow_mut();
        if s.fixture_installed || !s.cells.is_empty() || s.next != 0 || s.attempts != 0 {
            return Err(invalid("installation-state", "cells"));
        }
        let mut staged = BTreeMap::new();
        let mut order = Vec::new();
        let mut next = 0;
        for (i, (id, cell)) in rows.into_iter().enumerate() {
            let path = format!("cells/{i}");
            if staged.contains_key(&id) {
                return Err(invalid("duplicate", path));
            }
            if !decimal(&cell.item) {
                return Err(invalid("integer", path));
            }
            if cell.holders == 0 || cell.aside {
                return Err(invalid("initial-live-count", path));
            }
            next = next.max(
                id.checked_add(1)
                    .ok_or_else(|| invalid("identity-range", &path))?,
            );
            staged.insert(id, Box::new(cell));
            order.push(id);
        }
        let mut counts = BTreeMap::<u64, u64>::new();
        for (i, root) in roots.iter().enumerate() {
            if let Some(id) = root {
                if !staged.contains_key(id) {
                    return Err(invalid("dangling", format!("roots/{i}")));
                }
                *counts.entry(*id).or_default() += 1;
            }
        }
        for (id, cell) in &staged {
            if let Some(tail) = cell.tail {
                if !staged.contains_key(&tail) {
                    return Err(invalid("dangling", format!("cell/{id}/tail")));
                }
                *counts.entry(tail).or_default() += 1;
            }
        }
        for (id, cell) in &staged {
            if counts.get(id).copied().unwrap_or(0) != cell.holders {
                return Err(invalid("holder-count", format!("cell/{id}")));
            }
        }
        let mut reachable = BTreeSet::new();
        for root in roots {
            let mut visiting = BTreeSet::new();
            let mut here = *root;
            while let Some(id) = here {
                if reachable.contains(&id) {
                    break;
                }
                if !visiting.insert(id) {
                    return Err(invalid("cycle", format!("cell/{id}")));
                }
                here = staged[&id].tail;
            }
            reachable.extend(visiting);
        }
        if reachable.len() != staged.len() {
            return Err(invalid("unreachable", "cells"));
        }
        // No fallible validation follows this commit point. Host OOM is not a
        // controlled candidate allocation failure or a promised recovery path.
        let previous_phase = s.phase;
        s.phase = Phase::Fixture;
        for id in order {
            s.record("fixture", id, &*staged[&id] as *const Cell as usize);
        }
        s.cells = staged;
        s.next = next;
        s.fixture_installed = true;
        s.phase = previous_phase;
        Ok(())
    }

    /// Final HOST fixture teardown, separate from candidate destroy evidence.
    pub fn teardown(&self) {
        let mut s = self.0.borrow_mut();
        s.phase = Phase::Teardown;
        let cells = std::mem::take(&mut s.cells);
        for (id, cell) in cells {
            s.record("free", id, &*cell as *const Cell as usize);
            drop(cell);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{Error, fixture};
    fn cell(n: &str, tail: Option<u64>, holders: u64) -> Cell {
        Cell {
            item: n.into(),
            tail,
            holders,
            aside: false,
        }
    }
    #[test]
    fn create_denial_is_observed_without_inventing_a_cell_event() {
        let (api, observer) = fixture(vec![]);
        observer.phase(Phase::Execution);
        observer.fail_create(2);
        let first = api.create(cell("7", None, 1)).unwrap();
        let before = observer.since(Cursor::default()).unwrap();
        let graph = observer.graph();
        assert_eq!(
            api.create(cell("9", None, 1)),
            Err(Error::InjectedAllocationFailure)
        );
        let denial = observer.since(before.cursor).unwrap();
        assert_eq!(denial.creates, vec![(2, false, Phase::Execution)]);
        assert!(denial.events.is_empty() && denial.mutations.is_empty());
        assert_eq!(observer.graph(), graph);
        assert_eq!(api.create(cell("11", None, 1)), Ok(first + 1));
        assert_eq!(
            observer.since(denial.cursor).unwrap().creates,
            vec![(3, true, Phase::Execution)]
        );
    }
    #[test]
    fn same_store_gate_install_read_and_drop_order() {
        let (api, observer) = fixture(vec![]);
        api.allocate(Resource::Number, || String::from("123"))
            .unwrap();
        assert!(observer.frontend_clean());
        observer
            .install(
                vec![(9, cell("37", Some(2), 1)), (2, cell("-4", None, 2))],
                &[Some(9), Some(2)],
            )
            .unwrap();
        let cursor = observer.since(Cursor::default()).unwrap().cursor;
        observer.phase(Phase::Execution);
        assert_eq!(
            api.allocate(Resource::Number, || api.read(9))
                .unwrap()
                .unwrap()
                .item,
            "37"
        );
        observer.fail_resource(Resource::Number, 3);
        assert_eq!(
            api.allocate(Resource::Number, || api.read(2)),
            Err(Error::InjectedAllocationFailure)
        );
        let delta = observer.since(cursor).unwrap();
        assert!(delta.events.is_empty());
        assert_eq!(
            delta
                .resources
                .iter()
                .map(|r| (r.ordinal, r.allowed, r.phase))
                .collect::<Vec<_>>(),
            vec![(2, true, Phase::Execution), (3, false, Phase::Execution)]
        );
        assert!(observer.since(delta.cursor).unwrap().resources.is_empty());
        assert_eq!(
            observer.since(Cursor {
                events: 100,
                ..delta.cursor
            }),
            Err("observer cursor ahead")
        );
        drop(api); // observer retains the very same live boxes
        assert_eq!(observer.graph().len(), 2);
        observer.teardown();
        assert!(observer.graph().is_empty());
    }
    #[test]
    fn rejected_fixture_rolls_back_allocations_ids_events_and_resource_prefix() {
        let (api, observer) = fixture(vec![]);
        api.allocate(Resource::Number, || ()).unwrap();
        let before = observer.since(Cursor::default()).unwrap();
        // First row has already been boxed when the bad second row is found.
        assert_eq!(
            observer
                .install(
                    vec![(1, cell("3", None, 1)), (1, cell("7", None, 1))],
                    &[Some(1)]
                )
                .unwrap_err()
                .class,
            "duplicate"
        );
        assert_eq!(observer.since(Cursor::default()).unwrap(), before);
        assert!(observer.graph().is_empty());
        observer
            .install(vec![(4, cell("9", None, 1))], &[Some(4)])
            .unwrap();
        assert_eq!(api.create(cell("11", None, 1)).unwrap(), 5);
        assert_eq!(
            observer.install(vec![], &[]).unwrap_err().class,
            "installation-state"
        );
    }
    #[test]
    fn dangling_cycles_counts_and_unreachable_are_rejected_before_commit() {
        for (rows, roots, class) in [
            (vec![(1, cell("3", Some(8), 1))], vec![Some(1)], "dangling"),
            (vec![(1, cell("3", Some(1), 2))], vec![Some(1)], "cycle"),
            (vec![(1, cell("3", None, 2))], vec![Some(1)], "holder-count"),
            (vec![(1, cell("3", Some(1), 1))], vec![], "unreachable"),
        ] {
            let (_, observer) = fixture(vec![]);
            assert_eq!(observer.install(rows, &roots).unwrap_err().class, class);
            assert!(observer.graph().is_empty() && observer.events().is_empty());
        }
    }
    #[test]
    fn runtime_survives_observer_drop_and_frontend_reads_are_detected() {
        let (api, observer) = fixture(vec![]);
        assert_eq!(api.read(77), Err(Error::UnknownCell));
        assert!(!observer.frontend_clean());
        drop(observer);
        let id = api.create(cell("8", None, 1)).unwrap();
        assert_eq!(api.read(id).unwrap().item, "8");
        api.free(id).unwrap();
    }

    #[test]
    fn approved_begin_omits_outside_order_required_by_snapshot() {
        // Contract witness, NOT an interpreter. In both fixtures begin would
        // receive exactly [("xs", ListInt(Some(9)))] and this opaque API.
        // The required state.outside differs but nothing in read exposes it.
        let mut views = Vec::new();
        for outside in [[Some(9), Some(2)], [Some(2), Some(9)]] {
            let (api, observer) = fixture(vec![]);
            let roots = [Some(9), outside[0], outside[1]];
            observer
                .install(
                    vec![(9, cell("37", Some(2), 2)), (2, cell("-4", None, 2))],
                    &roots,
                )
                .unwrap();
            views.push((
                api.allocate(Resource::Number, || api.read(9))
                    .unwrap()
                    .unwrap(),
                api.allocate(Resource::Number, || api.read(2))
                    .unwrap()
                    .unwrap(),
            ));
        }
        assert_eq!(views[0], views[1]);
        assert_ne!([Some(9), Some(2)], [Some(2), Some(9)]);
    }
}
