use std::collections::{BTreeMap, VecDeque};
use std::ffi::{CStr, CString, c_char, c_int, c_void};
use std::io::{self, BufRead, BufReader, Write};
use std::net::{TcpListener, TcpStream};
use std::sync::{Arc, Condvar, Mutex};
use std::thread;
use std::time::Duration;

unsafe extern "C" {
    fn dlopen(path: *const c_char, flags: c_int) -> *mut c_void;
    fn dlsym(handle: *mut c_void, symbol: *const c_char) -> *mut c_void;
    fn dlclose(handle: *mut c_void) -> c_int;
    fn _dyld_image_count() -> u32;
    fn _dyld_get_image_name(index: u32) -> *const c_char;
}
type Step = unsafe extern "C" fn(u64, Option<extern "C" fn(*mut c_void)>, *mut c_void) -> u64;
struct Module {
    handle: *mut c_void,
    version: u64,
    step: Step,
}
// Trusted ABI: pure synchronous functions, no retained callbacks, threads or TLS.
// All pointers stay private and every call borrows the owning Arc<Module>.
unsafe impl Send for Module {}
unsafe impl Sync for Module {}
impl Drop for Module {
    fn drop(&mut self) {
        let _ = self.handle;
    }
}
impl Module {
    fn load(path: &str) -> Result<Self, ()> {
        let path = CString::new(path).map_err(|_| ())?;
        // macOS RTLD_NOW | RTLD_LOCAL. No NODELETE and no exported global symbols.
        let handle = unsafe { dlopen(path.as_ptr(), 2 | 4) };
        if handle.is_null() {
            return Err(());
        }
        let result = (|| {
            let symbol = |name: &CStr| {
                let p = unsafe { dlsym(handle, name.as_ptr()) };
                if p.is_null() { Err(()) } else { Ok(p) }
            };
            let abi: unsafe extern "C" fn() -> u64 =
                unsafe { std::mem::transmute(symbol(c"mo_abi")?) };
            if unsafe { abi() } != 1 {
                return Err(());
            }
            let version: unsafe extern "C" fn() -> u64 =
                unsafe { std::mem::transmute(symbol(c"mo_version")?) };
            let step: Step = unsafe { std::mem::transmute(symbol(c"mo_step")?) };
            Ok(Self {
                handle,
                version: unsafe { version() },
                step,
            })
        })();
        if result.is_err() {
            assert_eq!(unsafe { dlclose(handle) }, 0);
        }
        result
    }
    fn call(&self, x: u64, gate: Option<extern "C" fn(*mut c_void)>, sh: &Shared) -> u64 {
        unsafe { (self.step)(x, gate, sh as *const Shared as *mut c_void) }
    }
}
#[derive(Clone)]
struct Job {
    row: [u64; 4],
    code: Arc<Module>,
}
struct State {
    active: u64,
    modules: BTreeMap<u64, Arc<Module>>,
    queue: VecDeque<Job>,
    flight: Option<[u64; 4]>,
    accepted: Vec<[u64; 4]>,
    completed: Vec<[u64; 6]>,
    held: bool,
    inside: bool,
    permits: usize,
    shutdown: bool,
}
struct Shared {
    state: Mutex<State>,
    changed: Condvar,
}
extern "C" fn gate(context: *mut c_void) {
    // Callback is synchronous and Shared outlives the joined worker.
    let sh = unsafe { &*(context as *const Shared) };
    let mut s = sh.state.lock().unwrap();
    s.inside = true;
    sh.changed.notify_all();
    while s.held && s.permits == 0 {
        s = sh.changed.wait(s).unwrap();
    }
    if s.held {
        s.permits -= 1;
    }
    s.inside = false;
}
fn worker(sh: Arc<Shared>) {
    loop {
        let mut s = sh.state.lock().unwrap();
        while s.queue.is_empty() && !s.shutdown {
            s = sh.changed.wait(s).unwrap();
        }
        if s.shutdown {
            return;
        }
        let job = s.queue.pop_front().unwrap();
        s.flight = Some(job.row);
        drop(s);
        let first = job.code.call(job.row[2], Some(gate), &sh);
        let result = job.code.call(first, None, &sh);
        let mut s = sh.state.lock().unwrap();
        s.completed.push([
            job.row[0], job.row[1], job.row[2], job.row[3], first, result,
        ]);
        s.flight = None;
        drop(job); // Release function-pointer owner before publishing completion snapshot.
        sh.changed.notify_all();
    }
}
fn status(s: &str) -> String {
    format!("{{\"status\":\"{s}\"}}")
}
fn number(s: &str) -> Option<u64> {
    if s.is_empty() || !s.bytes().all(|b| b.is_ascii_digit()) {
        None
    } else {
        s.parse().ok()
    }
}
fn snapshot(s: &State) -> String {
    let queue: Vec<_> = s.queue.iter().map(|j| j.row).collect();
    let versions: Vec<_> = s.modules.keys().copied().collect();
    // Serialized with all loader mutations under this service's state mutex.
    let images: Vec<_> = unsafe {
        (0.._dyld_image_count())
            .map(|i| {
                CStr::from_ptr(_dyld_get_image_name(i))
                    .to_string_lossy()
                    .into_owned()
            })
            .collect()
    };
    let flight = s.flight.map_or("null".into(), |r| format!("{r:?}"));
    format!(
        "{{\"status\":\"ok\",\"active\":{},\"queue\":{:?},\"flight\":{},\"accepted\":{:?},\"completed\":{:?},\"loaded\":{:?},\"held\":{},\"inside\":{},\"images\":{:?}}}",
        s.active, queue, flight, s.accepted, s.completed, versions, s.held, s.inside, images
    )
}
fn command(sh: &Shared, line: &str) -> String {
    let parts: Vec<_> = line.split(' ').collect();
    let mut s = sh.state.lock().unwrap();
    if s.shutdown {
        return status("closing");
    }
    match parts.as_slice() {
        ["submit", id, payload] => {
            let (Some(id), Some(payload)) = (number(id), number(payload)) else {
                return status("invalid");
            };
            if !(1..=1_000_000).contains(&id) || !(1..=1_000_000).contains(&payload) {
                return status("invalid");
            }
            if let Some(j) = s.accepted.iter().find(|j| j[1] == id) {
                return if j[2] == payload {
                    format!("{{\"status\":\"duplicate\",\"seq\":{}}}", j[0])
                } else {
                    status("conflict")
                };
            }
            if s.queue.len() + usize::from(s.flight.is_some()) >= 8 {
                return status("busy");
            }
            if s.accepted.len() >= 256 {
                return status("limit");
            }
            let seq = s.accepted.len() as u64 + 1;
            let row = [seq, id, payload, s.active];
            let code = Arc::clone(&s.modules[&s.active]);
            s.queue.push_back(Job { row, code });
            s.accepted.push(row);
            sh.changed.notify_all();
            format!("{{\"status\":\"accepted\",\"seq\":{seq}}}")
        }
        ["update", path] => {
            if s.modules.len() >= 8 {
                return status("limit");
            }
            // Trusted tiny modules only: loading/destructors may execute under this lock.
            // ponytail: serialized loader; isolate untrusted or slow preparation in a later experiment.
            let Ok(module) = Module::load(path) else {
                return status("invalid");
            };
            if module.version <= s.active {
                return status("invalid");
            }
            s.active = module.version;
            let active = s.active;
            s.modules.insert(active, Arc::new(module));
            status("activated")
        }
        ["retire", version] => {
            let Some(version) = number(version) else {
                return status("invalid");
            };
            let Some(module) = s.modules.get(&version) else {
                return status("missing");
            };
            if version == s.active || Arc::strong_count(module) != 1 {
                return status("blocked");
            }
            s.modules.remove(&version);
            status("retired")
        }
        ["hold_work"] => {
            s.held = true;
            status("ok")
        }
        ["step_work"] => {
            s.permits += 1;
            sh.changed.notify_all();
            status("ok")
        }
        ["release_work"] => {
            s.held = false;
            sh.changed.notify_all();
            status("ok")
        }
        ["snapshot"] => snapshot(&s),
        ["shutdown"] => {
            if s.flight.is_some() || !s.queue.is_empty() {
                return status("busy");
            }
            s.shutdown = true;
            sh.changed.notify_all();
            status("ok")
        }
        _ => status("invalid"),
    }
}
fn connection(sh: Arc<Shared>, mut stream: TcpStream) -> io::Result<()> {
    // Preserve experiment 5's Darwin accepted-socket correction.
    stream.set_nonblocking(false)?;
    stream.set_nodelay(true)?;
    stream.set_read_timeout(Some(Duration::from_millis(100)))?;
    let mut reader = BufReader::new(stream.try_clone()?);
    let mut line = String::new();
    loop {
        match reader.read_line(&mut line) {
            Ok(0) => return Ok(()),
            Ok(_) => {}
            Err(e)
                if matches!(
                    e.kind(),
                    io::ErrorKind::WouldBlock
                        | io::ErrorKind::TimedOut
                        | io::ErrorKind::Interrupted
                ) =>
            {
                if sh.state.lock().unwrap().shutdown {
                    return Ok(());
                }
                continue;
            }
            Err(e) => return Err(e),
        }
        if line.ends_with('\n') {
            line.pop();
        }
        writeln!(stream, "{}", command(&sh, &line))?;
        stream.flush()?;
        if sh.state.lock().unwrap().shutdown {
            return Ok(());
        }
        line.clear();
    }
}
fn main() -> io::Result<()> {
    let path = std::env::args()
        .nth(1)
        .expect("usage: host /absolute/v1.dylib");
    let module = Module::load(&path).expect("compatible initial module");
    assert_eq!(module.version, 1);
    let listener = TcpListener::bind("127.0.0.1:0")?;
    listener.set_nonblocking(true)?;
    let sh = Arc::new(Shared {
        changed: Condvar::new(),
        state: Mutex::new(State {
            active: 1,
            modules: BTreeMap::from([(1, Arc::new(module))]),
            queue: VecDeque::new(),
            flight: None,
            accepted: vec![],
            completed: vec![],
            held: false,
            inside: false,
            permits: 0,
            shutdown: false,
        }),
    });
    println!("LISTEN {}", listener.local_addr()?);
    io::stdout().flush()?;
    let other = Arc::clone(&sh);
    let worker = thread::spawn(move || worker(other));
    let mut clients = vec![];
    while !sh.state.lock().unwrap().shutdown {
        match listener.accept() {
            Ok((stream, _)) => {
                let other = Arc::clone(&sh);
                clients.push(thread::spawn(move || {
                    let _ = connection(other, stream);
                }));
            }
            Err(e) if e.kind() == io::ErrorKind::WouldBlock => {
                thread::sleep(Duration::from_millis(1))
            }
            Err(e) => return Err(e),
        }
    }
    worker.join().unwrap();
    for client in clients {
        client.join().unwrap();
    }
    Ok(())
}
