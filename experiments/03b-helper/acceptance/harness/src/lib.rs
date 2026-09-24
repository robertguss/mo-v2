//! Experiment 3b harness library, written by the lead. It picks which helper the
//! programs link (the builder's, or a control), and installs the global allocator:
//! mimalloc for timed builds, a counting allocator for check builds.

#[cfg(feature = "real")]
pub use helper::{List, Tree};
#[cfg(feature = "copies")]
pub use mutant_always_copies::{List, Tree};
#[cfg(feature = "shares")]
pub use mutant_shared_mutation::{List, Tree};

pub const MODULUS: i64 = 1_000_000_007;

/// Build a list from the back, one cell at a time (D52's rule for building inputs).
pub fn build_from_back(values: impl DoubleEndedIterator<Item = i64>) -> List {
    let mut list = List::new();
    for v in values.rev() {
        list = list.push_front(v);
    }
    list
}

#[cfg(feature = "mimalloc")]
mod mi {
    // Identical to Experiment 3's same-container Rust allocator shim.
    use std::alloc::{GlobalAlloc, Layout};
    use std::ffi::c_void;

    const MI_MAX_ALIGN_SIZE: usize = 16;

    extern "C" {
        fn mi_malloc(size: usize) -> *mut c_void;
        fn mi_zalloc(size: usize) -> *mut c_void;
        fn mi_realloc(p: *mut c_void, newsize: usize) -> *mut c_void;
        fn mi_malloc_aligned(size: usize, alignment: usize) -> *mut c_void;
        fn mi_zalloc_aligned(size: usize, alignment: usize) -> *mut c_void;
        fn mi_realloc_aligned(p: *mut c_void, newsize: usize, alignment: usize) -> *mut c_void;
        fn mi_free(p: *mut c_void);
    }

    pub struct MiMalloc;

    unsafe impl GlobalAlloc for MiMalloc {
        #[inline]
        unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
            if layout.align() <= MI_MAX_ALIGN_SIZE {
                mi_malloc(layout.size()) as *mut u8
            } else {
                mi_malloc_aligned(layout.size(), layout.align()) as *mut u8
            }
        }

        #[inline]
        unsafe fn alloc_zeroed(&self, layout: Layout) -> *mut u8 {
            if layout.align() <= MI_MAX_ALIGN_SIZE {
                mi_zalloc(layout.size()) as *mut u8
            } else {
                mi_zalloc_aligned(layout.size(), layout.align()) as *mut u8
            }
        }

        #[inline]
        unsafe fn dealloc(&self, ptr: *mut u8, _layout: Layout) {
            mi_free(ptr as *mut c_void)
        }

        #[inline]
        unsafe fn realloc(&self, ptr: *mut u8, layout: Layout, new_size: usize) -> *mut u8 {
            if layout.align() <= MI_MAX_ALIGN_SIZE {
                mi_realloc(ptr as *mut c_void, new_size) as *mut u8
            } else {
                mi_realloc_aligned(ptr as *mut c_void, new_size, layout.align()) as *mut u8
            }
        }
    }

    #[global_allocator]
    static GLOBAL: MiMalloc = MiMalloc;
}

/// Counts allocation events (alloc, alloc_zeroed and realloc), not bytes, so allocating
/// and then freeing a replacement still counts (Codex, 3b review). Also tracks live blocks
/// (blocks allocated minus blocks freed), so checks can see what is kept and what is freed.
#[cfg(feature = "counting")]
pub mod counting {
    use std::alloc::{GlobalAlloc, Layout, System};
    use std::sync::atomic::{AtomicI64, AtomicU64, Ordering::Relaxed};

    static EVENTS: AtomicU64 = AtomicU64::new(0);
    static LIVE: AtomicI64 = AtomicI64::new(0);

    pub struct Counting;

    unsafe impl GlobalAlloc for Counting {
        unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
            EVENTS.fetch_add(1, Relaxed);
            LIVE.fetch_add(1, Relaxed);
            System.alloc(layout)
        }
        unsafe fn alloc_zeroed(&self, layout: Layout) -> *mut u8 {
            EVENTS.fetch_add(1, Relaxed);
            LIVE.fetch_add(1, Relaxed);
            System.alloc_zeroed(layout)
        }
        unsafe fn dealloc(&self, ptr: *mut u8, layout: Layout) {
            LIVE.fetch_sub(1, Relaxed);
            System.dealloc(ptr, layout)
        }
        unsafe fn realloc(&self, ptr: *mut u8, layout: Layout, new_size: usize) -> *mut u8 {
            EVENTS.fetch_add(1, Relaxed);
            System.realloc(ptr, layout, new_size)
        }
    }

    #[global_allocator]
    static GLOBAL: Counting = Counting;

    /// Allocation events so far in this process.
    pub fn events() -> u64 {
        EVENTS.load(Relaxed)
    }

    /// Blocks currently allocated and not yet freed.
    pub fn live() -> i64 {
        LIVE.load(Relaxed)
    }
}
