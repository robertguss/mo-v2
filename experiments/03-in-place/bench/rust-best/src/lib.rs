//! Shared by every benchmark binary: the optional mimalloc global allocator.
//! Each binary links this crate with `extern crate`, so the allocator is always installed
//! when the `mimalloc` feature is on.

#[cfg(feature = "mimalloc")]
mod mi {
    use std::alloc::{GlobalAlloc, Layout};
    use std::ffi::c_void;

    // mimalloc's guaranteed alignment for plain `mi_malloc`.
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
