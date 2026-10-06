use std::collections::BTreeMap;
use std::ffi::{CStr, CString, c_char, c_int, c_void};
use std::io::{self, BufRead, BufReader, Write};
use std::net::{TcpListener, TcpStream};
use std::sync::{Arc, Condvar, Mutex};
use std::thread;
use std::time::{Duration, Instant};

static LOADER: Mutex<()> = Mutex::new(());

unsafe extern "C" {
    fn dlopen(path: *const c_char, flags: c_int) -> *mut c_void;
    fn dlsym(handle: *mut c_void, symbol: *const c_char) -> *mut c_void;
    fn dlclose(handle: *mut c_void) -> c_int;
    fn _dyld_image_count() -> u32;
    fn _dyld_get_image_name(index: u32) -> *const c_char;
}
type Step = unsafe extern "C" fn(u64, Option<extern "C" fn(*mut c_void)>, *mut c_void) -> u64;
type Row = [u64; 4];
type Migrate = unsafe extern "C" fn(
    *const Row,
    u64,
    Option<extern "C" fn(*mut c_void)>,
    *mut c_void,
) -> *mut c_void;
type Push = unsafe extern "C" fn(*mut c_void, *const Row) -> u64;
type Pop = unsafe extern "C" fn(*mut c_void, *mut Row) -> u64;
type Export = unsafe extern "C" fn(*mut c_void, *mut Row) -> u64;
type Free = unsafe extern "C" fn(*mut c_void);
struct Module {
    handle: *mut c_void,
    version: u64,
    step: Step,
    migrate: Migrate,
    push: Push,
    pop: Pop,
    export: Export,
    free: Free,
    layout: u64,
}
// Trusted ABI: pure synchronous functions, no retained callbacks, threads or TLS.
// All pointers stay private and every call borrows the owning Arc<Module>.
unsafe impl Send for Module {}
unsafe impl Sync for Module {}
impl Drop for Module {
    fn drop(&mut self) {
        let _loader = LOADER.lock().unwrap();
        assert_eq!(unsafe { dlclose(self.handle) }, 0, "dlclose failed");
    }
}
impl Module {
    fn load(path: &str) -> Result<Self, ()> {
        let _loader = LOADER.lock().unwrap();
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
            if unsafe { abi() } != 3 {
                return Err(());
            }
            let version: unsafe extern "C" fn() -> u64 =
                unsafe { std::mem::transmute(symbol(c"mo_version")?) };
            let step: Step = unsafe { std::mem::transmute(symbol(c"mo_step")?) };
            let migrate: Migrate = unsafe { std::mem::transmute(symbol(c"mo_migrate")?) };
            let push: Push = unsafe { std::mem::transmute(symbol(c"mo_push")?) };
            let pop: Pop = unsafe { std::mem::transmute(symbol(c"mo_pop")?) };
            let export: Export = unsafe { std::mem::transmute(symbol(c"mo_export")?) };
            let free: Free = unsafe { std::mem::transmute(symbol(c"mo_free")?) };
            let layout: unsafe extern "C" fn() -> u64 =
                unsafe { std::mem::transmute(symbol(c"mo_layout")?) };
            let layout = unsafe { layout() };
            if !(1..=2).contains(&layout) {
                return Err(());
            }
            Ok(Self {
                handle,
                version: unsafe { version() },
                step,
                migrate,
                push,
                pop,
                export,
                free,
                layout,
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
struct NativeQueue {
    code: Arc<Module>,
    handle: *mut c_void,
}
// Each queue is uniquely owned; only its owner/mutex calls its synchronous ABI.
unsafe impl Send for NativeQueue {}
impl NativeQueue {
    fn migrate(
        code: Arc<Module>,
        rows: &[Row],
        gate: Option<extern "C" fn(*mut c_void)>,
        context: *mut c_void,
    ) -> Option<Self> {
        let handle = unsafe { (code.migrate)(rows.as_ptr(), rows.len() as u64, gate, context) };
        if handle.is_null() {
            None
        } else {
            Some(Self { code, handle })
        }
    }
    fn rows(&self) -> Vec<Row> {
        let mut rows = [[0; 4]; 8];
        let count = unsafe { (self.code.export)(self.handle, rows.as_mut_ptr()) } as usize;
        assert!(count <= 8);
        rows[..count].to_vec()
    }
    fn len(&self) -> usize {
        self.rows().len()
    }
    fn is_empty(&self) -> bool {
        self.len() == 0
    }
    fn push(&mut self, row: Row) -> bool {
        unsafe { (self.code.push)(self.handle, &row) == 1 }
    }
    fn pop(&mut self) -> Row {
        let mut row = [0; 4];
        assert_eq!(unsafe { (self.code.pop)(self.handle, &mut row) }, 1);
        row
    }
}
impl Drop for NativeQueue {
    fn drop(&mut self) {
        unsafe { (self.code.free)(self.handle) };
    }
}
#[derive(Clone)]
struct Job {
    row: [u64; 4],
    code: Arc<Module>,
}
struct Attempt {
    base: u64,
    requested_us: u64,
    started_us: Option<u64>,
    deadline: Option<Instant>,
    finished_us: Option<u64>,
    status: &'static str,
    hold: bool,
    entered: bool,
    returned: bool,
    discarded: bool,
    released: bool,
}
struct State {
    active: u64,
    modules: BTreeMap<u64, Arc<Module>>,
    queue: NativeQueue,
    owners: BTreeMap<u64, Arc<Module>>,
    frozen: usize,
    flight: Option<[u64; 4]>,
    accepted: Vec<[u64; 4]>,
    completed: Vec<[u64; 6]>,
    held: bool,
    inside: bool,
    permits: usize,
    shutdown: bool,
    pending: usize,
    attempts: Vec<Attempt>,
    updaters: Vec<thread::JoinHandle<()>>,
}
struct Shared {
    state: Mutex<State>,
    changed: Condvar,
    origin: Instant,
}
impl Shared {
    fn now(&self) -> u64 {
        self.origin.elapsed().as_micros() as u64
    }
    fn terminal(&self, s: &mut State, id: usize, status: &'static str) {
        s.attempts[id - 1].status = status;
        s.attempts[id - 1].finished_us = Some(self.now());
        s.pending = 0;
        if s.frozen == id {
            s.frozen = 0;
        }
        self.changed.notify_all();
    }
}
struct Preparation<'a> {
    shared: &'a Shared,
    id: usize,
}
extern "C" fn preparing(context: *mut c_void) {
    let ctx = unsafe { &*(context as *const Preparation<'_>) };
    let sh = ctx.shared;
    let mut s = sh.state.lock().unwrap();
    s.attempts[ctx.id - 1].entered = true;
    sh.changed.notify_all();
    while s.attempts[ctx.id - 1].hold && !s.attempts[ctx.id - 1].released {
        s = sh.changed.wait(s).unwrap();
    }
}
fn watchdog(sh: Arc<Shared>) {
    let mut s = sh.state.lock().unwrap();
    loop {
        if s.shutdown {
            return;
        }
        let id = s.pending;
        if id != 0
            && s.attempts[id - 1]
                .deadline
                .is_some_and(|d| Instant::now() >= d)
        {
            sh.terminal(&mut s, id, "timeout");
        }
        s = sh
            .changed
            .wait_timeout(s, Duration::from_millis(1))
            .unwrap()
            .0;
    }
}
fn update(sh: Arc<Shared>, id: usize, path: String) {
    // Neither dlopen nor user preparation retains the authoritative-state mutex.
    let loaded = Module::load(&path).map(Arc::new);
    let mut s = sh.state.lock().unwrap();
    let mut candidate = None;
    let mut source = vec![];
    if let Ok(module) = &loaded {
        if s.pending == id && module.version > s.active && !s.modules.contains_key(&module.version)
        {
            s.modules.insert(module.version, Arc::clone(module));
            candidate = Some(Arc::clone(module));
            source = s.queue.rows();
            s.frozen = id;
            let started = Instant::now();
            s.attempts[id - 1].started_us =
                Some(started.duration_since(sh.origin).as_micros() as u64);
            s.attempts[id - 1].deadline = Some(started + Duration::from_millis(200));
            s.attempts[id - 1].status = "pending";
        }
    }
    if candidate.is_none() && s.pending == id {
        sh.terminal(&mut s, id, "invalid");
    }
    drop(s);
    // One updater ownership reference, plus registry; no raw pointer outlives it.
    drop(loaded);
    if let Some(module) = candidate {
        let context = Preparation { shared: &sh, id };
        let mut migrated = NativeQueue::migrate(
            Arc::clone(&module),
            &source,
            Some(preparing),
            &context as *const _ as *mut c_void,
        );
        let valid = migrated.as_ref().is_some_and(|q| q.rows() == source);
        let mut s = sh.state.lock().unwrap();
        let base = s.attempts[id - 1].base;
        let authorized = s.pending == id && s.active == base && s.frozen == id;
        let mut activated = false;
        let mut old_queue = None;
        if !authorized {
            s.attempts[id - 1].discarded = true;
        } else if Instant::now() >= s.attempts[id - 1].deadline.unwrap() {
            sh.terminal(&mut s, id, "timeout");
            s.attempts[id - 1].discarded = true;
        } else if !valid || s.queue.rows() != source {
            sh.terminal(&mut s, id, "invalid");
        } else {
            old_queue = Some(std::mem::replace(&mut s.queue, migrated.take().unwrap()));
            s.active = module.version;
            sh.terminal(&mut s, id, "activated");
            activated = true;
        }
        if !activated {
            s.modules.remove(&module.version);
        }
        drop(s);
        // The registry is gone on refusal, but this last native owner is released
        // only after preparation returned. Destructors run outside the state lock.
        drop(old_queue);
        drop(migrated);
        drop(module);
    }
    let mut s = sh.state.lock().unwrap();
    s.attempts[id - 1].returned = true;
    sh.changed.notify_all();
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
        while (s.queue.is_empty() || s.frozen != 0) && !s.shutdown {
            s = sh.changed.wait(s).unwrap();
        }
        if s.shutdown {
            return;
        }
        let row = s.queue.pop();
        let job = Job {
            row,
            code: s.owners.remove(&row[0]).unwrap(),
        };
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
fn snapshot(sh: &Shared, s: &State, inspect_images: bool) -> String {
    let queue = s.queue.rows();
    let versions: Vec<_> = s.modules.keys().copied().collect();
    // Caller holds LOADER only for image inventory, never for ordinary state.
    let images: Vec<_> = if inspect_images {
        unsafe {
            (0.._dyld_image_count())
                .map(|i| {
                    CStr::from_ptr(_dyld_get_image_name(i))
                        .to_string_lossy()
                        .into_owned()
                })
                .collect()
        }
    } else {
        vec![]
    };
    let flight = s.flight.map_or("null".into(), |r| format!("{r:?}"));
    let opt = |n: Option<u64>| n.map_or("null".into(), |n| n.to_string());
    let attempts = s.attempts.iter().enumerate().map(|(i,a)| format!(
        "{{\"id\":{},\"base\":{},\"status\":\"{}\",\"requested_us\":{},\"started_us\":{},\"deadline_us\":{},\"finished_us\":{},\"entered\":{},\"returned\":{},\"discarded\":{},\"released\":{}}}",
        i+1,a.base,a.status,a.requested_us,opt(a.started_us),opt(a.started_us.map(|n|n+200_000)),opt(a.finished_us),a.entered,a.returned,a.discarded,a.released)).collect::<Vec<_>>().join(",");
    format!(
        "{{\"now_us\":{},\"pending\":{},\"attempts\":[{}],\"status\":\"ok\",\"active\":{},\"layout\":{},\"frozen\":{},\"queue\":{:?},\"flight\":{},\"accepted\":{:?},\"completed\":{:?},\"loaded\":{:?},\"held\":{},\"inside\":{},\"images\":{:?}}}",
        sh.now(),
        s.pending,
        attempts,
        s.active,
        s.queue.code.layout,
        s.frozen,
        queue,
        flight,
        s.accepted,
        s.completed,
        versions,
        s.held,
        s.inside,
        images
    )
}
fn command(sh: &Arc<Shared>, line: &str) -> String {
    let parts: Vec<_> = line.split(' ').collect();
    // Never wait for the OS loader while retaining the service mutex.
    let _inventory = if line == "snapshot" {
        Some(LOADER.lock().unwrap())
    } else {
        None
    };
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
            if s.frozen != 0 || s.queue.len() + usize::from(s.flight.is_some()) >= 8 {
                return status("busy");
            }
            if s.accepted.len() >= 256 {
                return status("limit");
            }
            let seq = s.accepted.len() as u64 + 1;
            let row = [seq, id, payload, s.active];
            let code = Arc::clone(&s.modules[&s.active]);
            if !s.queue.push(row) {
                return status("busy");
            }
            s.owners.insert(seq, code);
            s.accepted.push(row);
            sh.changed.notify_all();
            format!("{{\"status\":\"accepted\",\"seq\":{seq}}}")
        }
        ["update", path, mode @ ("normal" | "hold")] => {
            if s.pending != 0 {
                return status("busy");
            }
            if s.modules.len() >= 8 || s.attempts.len() >= 32 {
                return status("limit");
            }
            let id = s.attempts.len() + 1;
            let base = s.active;
            let requested_us = sh.now();
            s.attempts.push(Attempt {
                base,
                requested_us,
                started_us: None,
                deadline: None,
                finished_us: None,
                status: "staging",
                hold: *mode == "hold",
                entered: false,
                returned: false,
                discarded: false,
                released: false,
            });
            s.pending = id;
            let shared = Arc::clone(sh);
            let path = path.to_string();
            s.updaters
                .push(thread::spawn(move || update(shared, id, path)));
            format!("{{\"status\":\"started\",\"attempt\":{id}}}")
        }
        ["release", id] => {
            let Some(id) = number(id).and_then(|x| usize::try_from(x).ok()) else {
                return status("invalid");
            };
            let Some(a) = id.checked_sub(1).and_then(|i| s.attempts.get_mut(i)) else {
                return status("missing");
            };
            if !a.hold || a.released || a.returned {
                return status("blocked");
            }
            a.released = true;
            sh.changed.notify_all();
            status("ok")
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
            let retired = s.modules.remove(&version);
            drop(s);
            drop(retired);
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
        ["snapshot"] => snapshot(sh, &s, true),
        ["state"] => snapshot(sh, &s, false),
        ["shutdown"] => {
            if s.flight.is_some() || !s.queue.is_empty() || s.attempts.iter().any(|a| !a.returned) {
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
    let module = Arc::new(module);
    let queue = NativeQueue::migrate(Arc::clone(&module), &[], None, std::ptr::null_mut())
        .expect("initial native queue");
    let listener = TcpListener::bind("127.0.0.1:0")?;
    listener.set_nonblocking(true)?;
    let sh = Arc::new(Shared {
        changed: Condvar::new(),
        origin: Instant::now(),
        state: Mutex::new(State {
            active: 1,
            modules: BTreeMap::from([(1, module)]),
            queue,
            owners: BTreeMap::new(),
            frozen: 0,
            flight: None,
            accepted: vec![],
            completed: vec![],
            held: false,
            inside: false,
            permits: 0,
            shutdown: false,
            pending: 0,
            attempts: vec![],
            updaters: vec![],
        }),
    });
    println!("LISTEN {}", listener.local_addr()?);
    io::stdout().flush()?;
    let other = Arc::clone(&sh);
    let worker = thread::spawn(move || worker(other));
    let other = Arc::clone(&sh);
    let watch = thread::spawn(move || watchdog(other));
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
    watch.join().unwrap();
    for client in clients {
        client.join().unwrap();
    }
    let updaters = std::mem::take(&mut sh.state.lock().unwrap().updaters);
    for updater in updaters {
        updater.join().unwrap();
    }
    Ok(())
}
