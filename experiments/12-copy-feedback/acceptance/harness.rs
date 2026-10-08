extern crate helper;
mod task { include!(env!("TASK_SOURCE")); }
use std::{alloc::{GlobalAlloc, Layout, System}, io::{self, Read}, sync::atomic::{AtomicUsize, Ordering::SeqCst}, time::Instant};
static CALLS: AtomicUsize = AtomicUsize::new(0);
static BYTES: AtomicUsize = AtomicUsize::new(0);
static LIVE: AtomicUsize = AtomicUsize::new(0);
static PEAK: AtomicUsize = AtomicUsize::new(0);
struct Meter;
fn add(n: usize) { CALLS.fetch_add(1, SeqCst); BYTES.fetch_add(n, SeqCst); let live=LIVE.fetch_add(n, SeqCst)+n; PEAK.fetch_max(live, SeqCst); }
unsafe impl GlobalAlloc for Meter {
 unsafe fn alloc(&self,l:Layout)->*mut u8 { let p=unsafe{System.alloc(l)}; if !p.is_null(){add(l.size());} p }
 unsafe fn alloc_zeroed(&self,l:Layout)->*mut u8 { let p=unsafe{System.alloc_zeroed(l)}; if !p.is_null(){add(l.size());} p }
 unsafe fn dealloc(&self,p:*mut u8,l:Layout){unsafe{System.dealloc(p,l)}; LIVE.fetch_sub(l.size(),SeqCst);}
 unsafe fn realloc(&self,p:*mut u8,l:Layout,n:usize)->*mut u8 {let q=unsafe{System.realloc(p,l,n)}; if !q.is_null(){ LIVE.fetch_sub(l.size(),SeqCst); add(n); } q}
}
#[cfg(measure)] #[global_allocator] static ALLOC: Meter=Meter;
fn start()->(usize,usize,usize){let live=LIVE.load(SeqCst);PEAK.store(live,SeqCst);(CALLS.load(SeqCst),BYTES.load(SeqCst),live)}
fn finish(s:(usize,usize,usize))->(usize,usize,usize,usize,usize){(CALLS.load(SeqCst)-s.0,BYTES.load(SeqCst)-s.1,s.2,LIVE.load(SeqCst),PEAK.load(SeqCst))}
fn main(){
 // Calibrate actual unchanged Rc<ListCell> allocation requests, with teardown proof.
 let cal=start(); let one=std::hint::black_box(helper::List::new().push_front(7)); let c1=finish(cal); drop(one); let restored=LIVE.load(SeqCst)==cal.2;
 let cal=start(); let two=std::hint::black_box(helper::List::new().push_front(8).push_front(7)); let c2=finish(cal); drop(two); let restored=restored&&LIVE.load(SeqCst)==cal.2;
 let mut text=String::new();io::stdin().read_to_string(&mut text).unwrap();
 let values:Vec<i64>=text.split_whitespace().map(|x|x.parse().unwrap()).collect();
 let before_input=LIVE.load(SeqCst);
 let mut input=helper::List::new(); for v in values.iter().rev(){input=input.push_front(*v);}
 let s=start();let now=Instant::now();
 let (out,old)=std::hint::black_box(task::run(std::hint::black_box(input)));
 let ns=now.elapsed().as_nanos();let m=finish(s);
 // Verification storage and formatting are deliberately after measurement.
 let result:Vec<i64>=out.iter().collect();let original:Option<Vec<i64>>=old.as_ref().map(|v|v.iter().collect());
 let verify_bytes=(result.capacity()+original.as_ref().map_or(0,|v|v.capacity()))*std::mem::size_of::<i64>();
 drop(out);drop(old);let cleanup=LIVE.load(SeqCst);
 println!("{{\"instrumented\":{},\"calibration\":{{\"one_calls\":{},\"one_bytes\":{},\"two_calls\":{},\"two_bytes\":{},\"restored\":{}}},\"ns\":{},\"calls\":{},\"requested\":{},\"live_start\":{},\"live_end\":{},\"peak_live\":{},\"cleanup_ok\":{},\"result\":{:?},\"original\":{} }}",cfg!(measure),c1.0,c1.1,c2.0,c2.1,restored,ns,m.0,m.1,m.2,m.3,m.4,!cfg!(measure)||cleanup==before_input+verify_bytes,result,original.map_or_else(||"null".to_string(),|v|format!("{:?}",v)));
}
