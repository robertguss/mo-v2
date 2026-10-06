use std::collections::{BTreeMap, BTreeSet, VecDeque};
use std::io::{self, BufRead, BufReader, Write};
use std::net::TcpListener;

#[derive(Clone, PartialEq, Eq)]
struct Job {
    id: u8,
    payload: u16,
}

enum Queue {
    V1(VecDeque<Job>),
    V2(BTreeMap<usize, Job>),
}
impl Queue {
    fn jobs(&self) -> Vec<&Job> {
        match self {
            Self::V1(q) => q.iter().collect(),
            Self::V2(q) => q.values().collect(),
        }
    }
    fn push(&mut self, job: Job) {
        match self {
            Self::V1(q) => q.push_back(job),
            Self::V2(q) => {
                let key = q.last_key_value().map_or(0, |(k, _)| k + 1);
                q.insert(key, job);
            }
        }
    }
    fn pop(&mut self) -> Option<Job> {
        match self {
            Self::V1(q) => q.pop_front(),
            Self::V2(q) => q.pop_first().map(|(_, job)| job),
        }
    }
    fn version(&self) -> u8 {
        match self {
            Self::V1(_) => 1,
            Self::V2(_) => 2,
        }
    }
}

struct Service {
    queue: Queue,
    phase: &'static str,
    flight: Option<Job>,
    flight_version: u8,
    accepted: BTreeSet<u8>,
    completed: Vec<u8>,
    completed_values: Vec<u16>,
    candidate: BTreeMap<usize, Job>,
    remaining: u8,
    attempted: bool,
    outcome: &'static str,
}
impl Service {
    fn new() -> Self {
        Self {
            queue: Queue::V1(VecDeque::new()),
            phase: "running",
            flight: None,
            flight_version: 0,
            accepted: BTreeSet::new(),
            completed: Vec::new(),
            completed_values: Vec::new(),
            candidate: BTreeMap::new(),
            remaining: 0,
            attempted: false,
            outcome: "none",
        }
    }
    // ID zero is an injected hidden structural fault, never an accepted job.
    fn candidate_jobs(&self) -> Vec<&Job> {
        self.candidate.values().filter(|job| job.id != 0).collect()
    }
    fn corrupt(&self) -> bool {
        self.candidate
            .values()
            .any(|job| job.id == 0 || job.payload != u16::from(job.id) * 10)
    }
    fn valid_candidate(&self) -> bool {
        !self.corrupt() && self.candidate_jobs() == self.queue.jobs()
    }
    fn refuse(&mut self) {
        self.phase = "running";
        self.outcome = "refused";
        self.remaining = 0;
        self.candidate.clear();
    }
    fn command(&mut self, command: &str) -> &'static str {
        match command {
            "snapshot" => return "ok",
            "reset" => {
                *self = Self::new();
                return "ok";
            }
            "enqueue 1" | "enqueue 2" | "enqueue 3" => {
                let id = command.as_bytes()[8] - b'0';
                if self.accepted.contains(&id) {
                    return "duplicate";
                }
                if matches!(self.phase, "copying" | "ready")
                    || self.queue.jobs().len() + usize::from(self.flight.is_some()) >= 2
                {
                    return "busy";
                }
                self.queue.push(Job {
                    id,
                    payload: u16::from(id) * 10,
                });
                self.accepted.insert(id);
            }
            "start" => {
                if self.phase != "running" || self.flight.is_some() || self.queue.jobs().is_empty()
                {
                    return "blocked";
                }
                self.flight_version = self.queue.version();
                self.flight = self.queue.pop();
            }
            "finish" => {
                let Some(job) = self.flight.take() else {
                    return "blocked";
                };
                self.completed.push(job.id);
                self.completed_values.push(job.payload);
                self.flight_version = 0;
            }
            "begin" => {
                if self.phase != "running" || self.queue.version() != 1 || self.attempted {
                    return "blocked";
                }
                self.phase = "draining";
                self.attempted = true;
                self.remaining = 3;
                self.outcome = "pending";
            }
            "prepare" => {
                if self.phase != "draining" || self.flight.is_some() {
                    return "blocked";
                }
                self.phase = "copying";
                self.candidate.clear();
            }
            "copy" => {
                let copied = self.candidate_jobs().len();
                let jobs = self.queue.jobs();
                if self.phase != "copying" || copied >= jobs.len() {
                    return "blocked";
                }
                let job = jobs[copied].clone();
                self.candidate.insert(copied, job);
            }
            "corrupt" => {
                if !matches!(self.phase, "copying" | "ready") || self.corrupt() {
                    return "blocked";
                }
                if let Some((_, job)) = self.candidate.first_key_value() {
                    let key = *self.candidate.first_key_value().unwrap().0;
                    let mut bad = job.clone();
                    bad.payload += 1;
                    self.candidate.insert(key, bad);
                } else {
                    self.candidate.insert(usize::MAX, Job { id: 0, payload: 1 });
                }
            }
            "validate" => {
                if self.phase != "copying" {
                    return "blocked";
                }
                if self.valid_candidate() {
                    self.phase = "ready";
                } else {
                    self.refuse();
                }
            }
            "activate" => {
                if self.phase != "ready" {
                    return "blocked";
                }
                if self.valid_candidate() && self.flight.is_none() {
                    self.queue = Queue::V2(std::mem::take(&mut self.candidate));
                    self.phase = "running";
                    self.outcome = "activated";
                    self.remaining = 0;
                } else {
                    self.refuse();
                }
            }
            "fail" => {
                if self.outcome != "pending" {
                    return "blocked";
                }
                self.refuse();
            }
            "tick" => {
                if self.outcome != "pending" {
                    return "blocked";
                }
                if self.remaining > 1 {
                    self.remaining -= 1;
                } else {
                    self.refuse();
                }
            }
            _ => return "invalid",
        }
        "ok"
    }
    fn response(&self, status: &str) -> String {
        let queue: Vec<_> = self.queue.jobs().iter().map(|j| j.id).collect();
        let candidate: Vec<_> = self.candidate_jobs().iter().map(|j| j.id).collect();
        let accepted: Vec<_> = self.accepted.iter().copied().collect();
        format!(
            "{{\"status\":\"{}\",\"state\":{{\"version\":{},\"phase\":\"{}\",\"queue\":{:?},\"flight\":{},\"flight_version\":{},\"accepted\":{:?},\"completed\":{:?},\"completed_values\":{:?},\"candidate\":{:?},\"corrupt\":{},\"remaining\":{},\"attempted\":{},\"outcome\":\"{}\"}}}}",
            status,
            self.queue.version(),
            self.phase,
            queue,
            self.flight.as_ref().map_or(0, |j| j.id),
            self.flight_version,
            accepted,
            self.completed,
            self.completed_values,
            candidate,
            self.corrupt(),
            self.remaining,
            self.attempted,
            self.outcome
        )
    }
}
fn serve(reader: impl BufRead, mut writer: impl Write) -> io::Result<()> {
    let mut service = Service::new();
    for line in reader.lines() {
        let command = line?;
        let status = service.command(&command);
        writeln!(writer, "{}", service.response(status))?;
        writer.flush()?;
    }
    Ok(())
}
fn main() -> io::Result<()> {
    let args: Vec<_> = std::env::args().skip(1).collect();
    if args == ["--stdio"] {
        serve(io::stdin().lock(), io::stdout().lock())
    } else if args == ["--listen", "127.0.0.1:0"] {
        let listener = TcpListener::bind("127.0.0.1:0")?;
        println!("LISTEN {}", listener.local_addr()?);
        io::stdout().flush()?;
        let (stream, _) = listener.accept()?;
        stream.set_nodelay(true)?;
        serve(BufReader::new(stream.try_clone()?), stream)
    } else {
        Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            "usage: mo-live-update --stdio | --listen 127.0.0.1:0",
        ))
    }
}
