//! Exclusive monotonic wall attribution, not CPU or evaluator-only timing.
use crate::{Result, json};
use std::{cell::RefCell, marker::PhantomData, path::Path, rc::Rc, time::Instant};

#[derive(Clone, Copy)]
pub enum Category {
    Frontend,
    Evaluation,
    Cleanup,
    Observation,
    Collector,
    Transport,
    ApprovalWait,
}
const NAMES: [&str; 7] = [
    "frontend",
    "evaluation",
    "cleanup",
    "observation",
    "collector",
    "transport",
    "approval_wait",
];
struct Ledger {
    started: Instant,
    last: Instant,
    current: Category,
    totals: [u128; 7],
}
impl Ledger {
    fn accrue(&mut self, now: Instant) {
        self.totals[self.current as usize] += now.duration_since(self.last).as_nanos();
        self.last = now;
    }
}
thread_local! {
    static LEDGER: RefCell<Option<Ledger>> = const { RefCell::new(None) };
}
// Guards cannot migrate between threads: the ledger belongs to this thread.
pub struct Scope(Option<Category>, PhantomData<Rc<()>>);
pub fn scope(category: Category) -> Scope {
    Scope(
        LEDGER.with(|slot| {
            slot.borrow_mut().as_mut().map(|ledger| {
                ledger.accrue(Instant::now());
                let prior = ledger.current;
                ledger.current = category;
                prior
            })
        }),
        PhantomData,
    )
}
impl Drop for Scope {
    fn drop(&mut self) {
        if let Some(prior) = self.0 {
            LEDGER.with(|slot| {
                if let Some(ledger) = slot.borrow_mut().as_mut() {
                    ledger.accrue(Instant::now());
                    ledger.current = prior;
                }
            });
        }
    }
}
pub fn in_category<T>(category: Category, body: impl FnOnce() -> T) -> T {
    let _scope = scope(category);
    body()
}

/// Includes implicit candidate drops on error returns as well as explicit drop.
pub struct CleanupDrop<T>(Option<T>);
impl<T> CleanupDrop<T> {
    pub fn new(value: T) -> Self {
        Self(Some(value))
    }
}
impl<T> std::ops::Deref for CleanupDrop<T> {
    type Target = T;
    fn deref(&self) -> &T {
        self.0.as_ref().unwrap()
    }
}
impl<T> std::ops::DerefMut for CleanupDrop<T> {
    fn deref_mut(&mut self) -> &mut T {
        self.0.as_mut().unwrap()
    }
}
impl<T> Drop for CleanupDrop<T> {
    fn drop(&mut self) {
        in_category(Category::Cleanup, || drop(self.0.take()));
    }
}

pub fn measured(path: &Path, body: impl FnOnce() -> Result<()>) -> Result<()> {
    // Preflight without creating anything; create_new below also closes races.
    if path.symlink_metadata().is_ok() {
        return Err("timing sidecar already exists".into());
    }
    LEDGER.with(|slot| -> Result<()> {
        let mut slot = slot.borrow_mut();
        if slot.is_some() {
            return Err("timing measurement already active".into());
        }
        let started = Instant::now();
        *slot = Some(Ledger {
            started,
            last: started,
            current: Category::Collector,
            totals: [0; 7],
        });
        Ok(())
    })?;
    let result = body(); // All body's locals (including candidate drops) end here.
    let ended = Instant::now();
    let ledger = LEDGER.with(|slot| {
        let mut ledger = slot.borrow_mut().take().unwrap();
        ledger.accrue(ended);
        ledger
    });
    let elapsed = ended.duration_since(ledger.started).as_nanos();
    assert_eq!(elapsed, ledger.totals.iter().sum::<u128>());
    let categories: serde_json::Map<String, crate::Json> = NAMES
        .into_iter()
        .zip(ledger.totals)
        .map(|(name, ns)| (name.into(), json!(ns)))
        .collect();
    let record = json!({"format":"ROB-1333 native timing 01","unit":"ns",
        "completed":result.is_ok(),"elapsed_ns":elapsed,"exclusive_wall_ns":categories});
    let persisted = (|| -> Result<()> {
        let mut file = std::fs::OpenOptions::new()
            .write(true)
            .create_new(true)
            .open(path)
            .map_err(|e| e.to_string())?;
        serde_json::to_writer(&mut file, &record).map_err(|e| e.to_string())?;
        std::io::Write::flush(&mut file).map_err(|e| e.to_string())
    })();
    match (result, persisted) {
        (Err(body), Err(sidecar)) => Err(format!("{body}; timing sidecar: {sidecar}")),
        (Err(body), _) => Err(body),
        (Ok(()), persisted) => persisted,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn nested_restoration_error_completion_and_exclusive_creation() {
        let path = std::env::temp_dir().join(format!(
            "rob1333-timing-{}-{:?}.json",
            std::process::id(),
            std::thread::current().id()
        ));
        let result = measured(&path, || {
            let _evaluation = scope(Category::Evaluation);
            std::thread::sleep(std::time::Duration::from_millis(1));
            {
                let _collector = scope(Category::Collector);
                let _transport = scope(Category::Transport);
                std::thread::sleep(std::time::Duration::from_millis(1));
            }
            LEDGER.with(|slot| {
                assert!(matches!(
                    slot.borrow().as_ref().unwrap().current,
                    Category::Evaluation
                ))
            });
            Err("probe error".into())
        });
        assert_eq!(result, Err("probe error".into()));
        let bytes = std::fs::read(&path).unwrap();
        let record: crate::Json = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(record.as_object().unwrap().len(), 5);
        assert_eq!(record["format"], "ROB-1333 native timing 01");
        assert_eq!(record["unit"], "ns");
        assert_eq!(record["completed"], false);
        let categories = record["exclusive_wall_ns"].as_object().unwrap();
        assert_eq!(categories.len(), 7);
        for name in NAMES {
            assert!(categories[name].as_u64().is_some());
        }
        assert_eq!(
            record["elapsed_ns"].as_u64().unwrap(),
            categories
                .values()
                .map(|v| v.as_u64().unwrap())
                .sum::<u64>()
        );
        assert!(categories["evaluation"].as_u64().unwrap() > 0);
        assert!(categories["transport"].as_u64().unwrap() > 0);
        assert!(measured(&path, || panic!("existing path must fail before body")).is_err());
        assert_eq!(std::fs::read(&path).unwrap(), bytes);
        std::fs::remove_file(path).unwrap();
        let _inactive = scope(Category::Observation);
    }
}
