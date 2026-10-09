//! Private, version-matched host/runtime linkage. Not a candidate constructor.
//! Both sides compile this file, using the SAME public Cell/Error/Resource types.
//! repr(C) fixes field order; each function uses Rust ABI with those same types.
use crate::{Cell, Error, Resource};

#[repr(C)]
pub(crate) struct Handle {
    pub context: *const (),
    pub functions: &'static Functions,
}

#[repr(C)]
pub(crate) struct Functions {
    pub drop: unsafe fn(*const ()),
    pub gate: unsafe fn(*const (), Resource) -> Result<(), Error>,
    pub read: unsafe fn(*const (), u64) -> Result<Cell, Error>,
    pub create: unsafe fn(*const (), Cell) -> Result<u64, Error>,
    pub write: unsafe fn(*const (), u64, String, Option<u64>) -> Result<(), Error>,
    pub detach: unsafe fn(*const (), u64) -> Result<Option<u64>, Error>,
    pub metadata: unsafe fn(*const (), u64, u64, bool) -> Result<(), Error>,
    pub free: unsafe fn(*const (), u64) -> Result<(), Error>,
}
