//! Sole host-side construction boundary. Never delivered to a builder.
use crate::{Backend, Cell, Error, Resource, RuntimeCells, abi};

// SAFETY contract for every thunk: context is Box<Backend>::into_raw, kept
// alive by the unique RuntimeCells until its Drop; Backend uses Rc/RefCell.
unsafe fn backend<'a>(context: *const ()) -> &'a Backend {
    unsafe { &*context.cast::<Backend>() }
}
unsafe fn drop_context(context: *const ()) {
    unsafe {
        drop(Box::from_raw(context.cast_mut().cast::<Backend>()));
    }
}
unsafe fn gate(context: *const (), domain: Resource) -> Result<(), Error> {
    unsafe { backend(context) }.allocate(domain, || ())
}
unsafe fn read(context: *const (), id: u64) -> Result<Cell, Error> {
    unsafe { backend(context) }.read(id)
}
unsafe fn create(context: *const (), cell: Cell) -> Result<u64, Error> {
    unsafe { backend(context) }.create(cell)
}
unsafe fn write(context: *const (), id: u64, item: String, tail: Option<u64>) -> Result<(), Error> {
    unsafe { backend(context) }.write(id, item, tail)
}
unsafe fn detach(context: *const (), id: u64) -> Result<Option<u64>, Error> {
    unsafe { backend(context) }.detach(id)
}
unsafe fn metadata(context: *const (), id: u64, holders: u64, aside: bool) -> Result<(), Error> {
    unsafe { backend(context) }.metadata(id, holders, aside)
}
unsafe fn free(context: *const (), id: u64) -> Result<(), Error> {
    unsafe { backend(context) }.free(id)
}
static FUNCTIONS: abi::Functions = abi::Functions {
    drop: drop_context,
    gate,
    read,
    create,
    write,
    detach,
    metadata,
    free,
};

pub(crate) fn capability(backend: Backend) -> RuntimeCells {
    let handle = abi::Handle {
        context: Box::into_raw(Box::new(backend)).cast(),
        functions: &FUNCTIONS,
    };
    // SAFETY: RuntimeCells is repr(transparent) over exactly this repr(C)
    // handle layout. Both definitions include the same file and use the same
    // public Cell/Error/Resource definitions. Function pointers have identical
    // Rust signatures. Ownership moves, never copies; Drop calls drop_context.
    // Changing either side requires rebuilding both from the pinned inventory.
    unsafe { std::mem::transmute::<abi::Handle, RuntimeCells>(handle) }
}
