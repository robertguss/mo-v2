use std::collections::{BTreeMap, VecDeque};
use std::io::{self, BufRead, BufReader, Write};
use std::net::{TcpListener, TcpStream};
use std::sync::{Arc, Condvar, Mutex};
use std::thread;
use std::time::{Duration, Instant};

#[derive(Clone, Debug, PartialEq, Eq)]
struct Job {
    seq: u64,
    id: u64,
    payload: u64,
}
impl Job {
    fn row(&self) -> [u64; 3] {
        [self.seq, self.id, self.payload]
    }
}
enum Queue {
    Deque(VecDeque<Job>),
    Map(BTreeMap<u64, Job>),
}
impl Queue {
    fn jobs(&self) -> Vec<Job> {
        match self {
            Self::Deque(q) => q.iter().cloned().collect(),
            Self::Map(q) => q.values().cloned().collect(),
        }
    }
    fn len(&self) -> usize {
        match self {
            Self::Deque(q) => q.len(),
            Self::Map(q) => q.len(),
        }
    }
    fn push(&mut self, j: Job) {
        match self {
            Self::Deque(q) => q.push_back(j),
            Self::Map(q) => {
                q.insert(j.seq, j);
            }
        }
    }
    fn pop(&mut self) -> Option<Job> {
        match self {
            Self::Deque(q) => q.pop_front(),
            Self::Map(q) => q.pop_first().map(|(_, j)| j),
        }
    }
    fn from_jobs(epoch: u64, jobs: Vec<Job>) -> Self {
        if epoch % 2 == 0 {
            Self::Deque(jobs.into())
        } else {
            Self::Map(jobs.into_iter().map(|j| (j.seq, j)).collect())
        }
    }
    fn schema(&self) -> &'static str {
        match self {
            Self::Deque(_) => "deque",
            Self::Map(_) => "map",
        }
    }
}
struct Attempt {
    id: usize,
    mode: String,
    status: &'static str,
    base_epoch: u64,
    finished_epoch: Option<u64>,
    started_us: u64,
    deadline_us: u64,
    finished_us: Option<u64>,
    deadline: Instant,
    stage: &'static str,
    worker_returned: bool,
    late_discarded: bool,
    released: bool,
}
struct State {
    queue: Queue,
    flight: Option<(Job, u64)>,
    accepted: Vec<Job>,
    completed: Vec<[u64; 4]>,
    attempts: Vec<Attempt>,
    epoch: u64,
    pending: usize,
    phase: &'static str,
    work_held: bool,
    shutdown: bool,
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
    fn terminal(&self, s: &mut State, status: &'static str, now: u64) {
        let a = &mut s.attempts[s.pending - 1];
        a.status = status;
        a.stage = "done";
        a.finished_us = Some(now);
        a.finished_epoch = Some(s.epoch);
        s.pending = 0;
        s.phase = "running";
        self.changed.notify_all();
    }
}
fn worker(sh: Arc<Shared>) {
    loop {
        let mut s = sh.state.lock().unwrap();
        while !s.shutdown && (s.phase != "running" || s.queue.len() == 0) {
            s = sh.changed.wait(s).unwrap();
        }
        if s.shutdown {
            return;
        }
        let job = s.queue.pop().unwrap();
        let epoch = s.epoch;
        s.flight = Some((job, epoch));
        drop(s);
        thread::sleep(Duration::from_millis(5));
        let mut s = sh.state.lock().unwrap();
        while s.work_held && !s.shutdown {
            s = sh.changed.wait(s).unwrap();
        }
        if s.shutdown {
            return;
        }
        let (job, epoch) = s.flight.take().unwrap();
        s.completed.push([job.seq, job.id, job.payload, epoch]);
        sh.changed.notify_all();
    }
}
fn watchdog(sh: Arc<Shared>) {
    loop {
        let mut s = sh.state.lock().unwrap();
        if s.shutdown {
            return;
        }
        if s.pending != 0 && Instant::now() >= s.attempts[s.pending - 1].deadline {
            sh.terminal(&mut s, "timeout", sh.now());
        }
        let (_s, _) = sh
            .changed
            .wait_timeout(s, Duration::from_millis(1))
            .unwrap();
    }
}
fn migrate(sh: Arc<Shared>, id: usize) {
    let mut s = sh.state.lock().unwrap();
    while !s.shutdown && s.pending == id && s.flight.is_some() {
        s = sh.changed.wait(s).unwrap();
    }
    if s.shutdown || s.pending != id {
        return;
    }
    if Instant::now() >= s.attempts[id - 1].deadline {
        sh.terminal(&mut s, "timeout", sh.now());
        return;
    }
    s.phase = "copying";
    s.attempts[id - 1].stage = "copying";
    let source = s.queue.jobs();
    let base = s.epoch;
    let mode = s.attempts[id - 1].mode.clone();
    drop(s);
    let mut candidate = Queue::from_jobs(base + 1, source.clone());
    thread::sleep(Duration::from_millis(20));
    if mode == "hold" {
        let mut s = sh.state.lock().unwrap();
        while !s.shutdown && !s.attempts[id - 1].released {
            s = sh.changed.wait(s).unwrap();
        }
        if s.shutdown {
            return;
        }
    }
    if mode == "corrupt" {
        let mut jobs = candidate.jobs();
        if let Some(job) = jobs.first_mut() {
            job.payload += 1;
        } else {
            jobs.push(Job {
                seq: 0,
                id: 0,
                payload: 0,
            });
        }
        candidate = Queue::from_jobs(base + 1, jobs);
    }
    let mut s = sh.state.lock().unwrap();
    if s.shutdown {
        return;
    }
    s.attempts[id - 1].worker_returned = true;
    // Token and epoch fencing must precede every authoritative write.
    if s.pending != id || s.epoch != base {
        s.attempts[id - 1].late_discarded = true;
        return;
    }
    if Instant::now() >= s.attempts[id - 1].deadline {
        sh.terminal(&mut s, "timeout", sh.now());
        s.attempts[id - 1].late_discarded = true;
        return;
    }
    if s.flight.is_some() || candidate.jobs() != source || s.queue.jobs() != source {
        sh.terminal(&mut s, "invalid", sh.now());
        return;
    }
    let finished = sh.now();
    if Instant::now() >= s.attempts[id - 1].deadline || finished >= s.attempts[id - 1].deadline_us {
        sh.terminal(&mut s, "timeout", sh.now());
        return;
    }
    s.queue = candidate;
    s.epoch += 1;
    sh.terminal(&mut s, "activated", finished);
}
fn opt(n: Option<u64>) -> String {
    n.map_or_else(|| "null".into(), |n| n.to_string())
}
fn snapshot(sh: &Shared, s: &State) -> String {
    let queue: Vec<_> = s.queue.jobs().iter().map(Job::row).collect();
    let accepted: Vec<_> = s.accepted.iter().map(Job::row).collect();
    let flight = s.flight.as_ref().map_or_else(
        || "null".into(),
        |(j, e)| format!("{:?}", [j.seq, j.id, j.payload, *e]),
    );
    let attempts=s.attempts.iter().map(|a|format!("{{\"id\":{},\"mode\":\"{}\",\"status\":\"{}\",\"base_epoch\":{},\"finished_epoch\":{},\"started_us\":{},\"deadline_us\":{},\"finished_us\":{},\"stage\":\"{}\",\"worker_returned\":{},\"late_discarded\":{}}}",a.id,a.mode,a.status,a.base_epoch,opt(a.finished_epoch),a.started_us,a.deadline_us,opt(a.finished_us),a.stage,a.worker_returned,a.late_discarded)).collect::<Vec<_>>().join(",");
    format!(
        "{{\"status\":\"ok\",\"now_us\":{},\"epoch\":{},\"schema\":\"{}\",\"phase\":\"{}\",\"pending\":{},\"work_held\":{},\"queue\":{:?},\"flight\":{},\"accepted\":{:?},\"completed\":{:?},\"attempts\":[{}]}}",
        sh.now(),
        s.epoch,
        s.queue.schema(),
        s.phase,
        s.pending,
        s.work_held,
        queue,
        flight,
        accepted,
        s.completed,
        attempts
    )
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
fn command(sh: &Arc<Shared>, line: &str) -> String {
    let parts: Vec<_> = line.split(' ').collect();
    let mut s = sh.state.lock().unwrap();
    match parts.as_slice() {
        ["submit", id, payload] => {
            let (Some(id), Some(payload)) = (number(id), number(payload)) else {
                return status("invalid");
            };
            if !(1..=1_000_000).contains(&id) || !(1..=1_000_000).contains(&payload) {
                return status("invalid");
            }
            if let Some(j) = s.accepted.iter().find(|j| j.id == id) {
                return if j.payload == payload {
                    format!("{{\"status\":\"duplicate\",\"seq\":{}}}", j.seq)
                } else {
                    status("conflict")
                };
            }
            if s.phase == "copying" || s.queue.len() + usize::from(s.flight.is_some()) >= 8 {
                return status("busy");
            }
            if s.accepted.len() >= 256 {
                return status("limit");
            }
            let seq = s.accepted.len() as u64 + 1;
            let j = Job { seq, id, payload };
            s.accepted.push(j.clone());
            s.queue.push(j);
            sh.changed.notify_all();
            format!("{{\"status\":\"accepted\",\"seq\":{seq}}}")
        }
        ["update", mode @ ("normal" | "hold" | "corrupt")] => {
            if s.pending != 0 {
                return status("busy");
            }
            if s.attempts.len() >= 32 {
                return status("limit");
            }
            let id = s.attempts.len() + 1;
            let started = Instant::now();
            let started_us = started.duration_since(sh.origin).as_micros() as u64;
            let base_epoch = s.epoch;
            s.attempts.push(Attempt {
                id,
                mode: mode.to_string(),
                status: "pending",
                base_epoch,
                finished_epoch: None,
                started_us,
                deadline_us: started_us + 200_000,
                finished_us: None,
                deadline: started + Duration::from_millis(200),
                stage: "draining",
                worker_returned: false,
                late_discarded: false,
                released: false,
            });
            s.pending = id;
            s.phase = "draining";
            sh.changed.notify_all();
            let other = Arc::clone(sh);
            thread::spawn(move || migrate(other, id));
            format!("{{\"status\":\"started\",\"attempt\":{id}}}")
        }
        ["release", id] => {
            let Some(id) = number(id).and_then(|x| usize::try_from(x).ok()) else {
                return status("invalid");
            };
            let Some(a) = id.checked_sub(1).and_then(|i| s.attempts.get_mut(i)) else {
                return status("blocked");
            };
            if a.mode != "hold" || a.released || a.worker_returned {
                return status("blocked");
            }
            a.released = true;
            sh.changed.notify_all();
            status("ok")
        }
        ["hold_work"] => {
            s.work_held = true;
            status("ok")
        }
        ["release_work"] => {
            s.work_held = false;
            sh.changed.notify_all();
            status("ok")
        }
        ["snapshot"] => snapshot(sh, &s),
        ["shutdown"] => status("ok"),
        _ => status("invalid"),
    }
}
fn connection(sh: Arc<Shared>, mut stream: TcpStream) -> io::Result<()> {
    stream.set_nodelay(true)?;
    let mut reader = BufReader::new(stream.try_clone()?);
    loop {
        let mut line = String::new();
        if reader.read_line(&mut line)? == 0 {
            return Ok(());
        }
        if line.ends_with('\n') {
            line.pop();
        }
        let response = command(&sh, &line);
        writeln!(stream, "{response}")?;
        stream.flush()?;
        if line == "shutdown" {
            sh.state.lock().unwrap().shutdown = true;
            sh.changed.notify_all();
        }
        if sh.state.lock().unwrap().shutdown {
            return Ok(());
        }
    }
}
fn main() -> io::Result<()> {
    let args: Vec<_> = std::env::args().skip(1).collect();
    if args != ["--listen", "127.0.0.1:0"] {
        return Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            "usage: mo-concurrent-updates --listen 127.0.0.1:0",
        ));
    }
    let listener = TcpListener::bind("127.0.0.1:0")?;
    listener.set_nonblocking(true)?;
    let sh = Arc::new(Shared {
        origin: Instant::now(),
        changed: Condvar::new(),
        state: Mutex::new(State {
            queue: Queue::Deque(VecDeque::new()),
            flight: None,
            accepted: Vec::new(),
            completed: Vec::new(),
            attempts: Vec::new(),
            epoch: 0,
            pending: 0,
            phase: "running",
            work_held: false,
            shutdown: false,
        }),
    });
    println!("LISTEN {}", listener.local_addr()?);
    io::stdout().flush()?;
    let a = Arc::clone(&sh);
    let work = thread::spawn(move || worker(a));
    let a = Arc::clone(&sh);
    let watch = thread::spawn(move || watchdog(a));
    while !sh.state.lock().unwrap().shutdown {
        match listener.accept() {
            Ok((stream, _)) => {
                let a = Arc::clone(&sh);
                thread::spawn(move || {
                    let _ = connection(a, stream);
                });
            }
            Err(e) if e.kind() == io::ErrorKind::WouldBlock => {
                thread::sleep(Duration::from_millis(1))
            }
            Err(e) => return Err(e),
        }
    }
    sh.changed.notify_all();
    work.join().unwrap();
    watch.join().unwrap();
    Ok(())
}
