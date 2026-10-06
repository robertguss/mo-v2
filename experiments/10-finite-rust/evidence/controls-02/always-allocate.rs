use std::alloc::{GlobalAlloc, Layout, System};
use std::io::{self, BufRead};
use std::sync::atomic::{AtomicU64, Ordering::Relaxed};

static ALLOCS: AtomicU64 = AtomicU64::new(0);
static BYTES: AtomicU64 = AtomicU64::new(0);
static CELL_ALLOCS: AtomicU64 = AtomicU64::new(0);
static CELL_FREES: AtomicU64 = AtomicU64::new(0);
struct Counting;
unsafe impl GlobalAlloc for Counting {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        let p = unsafe { System.alloc(layout) };
        if !p.is_null() { ALLOCS.fetch_add(1, Relaxed); BYTES.fetch_add(layout.size() as u64, Relaxed); }
        p
    }
    unsafe fn dealloc(&self, p: *mut u8, layout: Layout) { unsafe { System.dealloc(p, layout) }; }
    unsafe fn realloc(&self, p: *mut u8, layout: Layout, size: usize) -> *mut u8 {
        let q = unsafe { System.realloc(p, layout, size) };
        if !q.is_null() { ALLOCS.fetch_add(1, Relaxed); BYTES.fetch_add(size as u64, Relaxed); }
        q
    }
}
#[global_allocator]
static ALLOCATOR: Counting = Counting;

fn array(xs: impl IntoIterator<Item = String>) -> String { format!("[{}]", xs.into_iter().collect::<Vec<_>>().join(",")) }
fn string(s: &str) -> String { format!("{s:?}") }
fn pointer(p: usize) -> String { if p == 0 { "null".into() } else { p.to_string() } }
#[derive(Clone, Debug, PartialEq)]
enum Value { Num(i128), Bool(bool), List(usize) }
impl Value {
    fn json(&self) -> String {
        match self {
            Self::Num(n) => format!("[\"n\",\"{n}\"]"),
            Self::Bool(b) => format!("[\"b\",{b}]"),
            Self::List(p) => format!("[\"l\",{}]", pointer(*p)),
        }
    }
    fn ptr(&self) -> usize { if let Self::List(p) = self { *p } else { 0 } }
    fn number(&self) -> i128 { if let Self::Num(n) = self { *n } else { panic!("number required") } }
}
#[derive(Clone)]
struct Cell { id: usize, item: i128, link: usize, count: usize, aside: bool }
impl Cell {
    fn json(&self) -> String {
        format!("[{},\"{}\",{},{},\"{}\"]", self.id, self.item, pointer(self.link), self.count, if self.aside { "aside" } else { "live" })
    }
}
struct LiveCell(Cell);
impl LiveCell {
    fn new(c: Cell) -> Self { CELL_ALLOCS.fetch_add(1, Relaxed); Self(c) }
}
impl Drop for LiveCell {
    fn drop(&mut self) { CELL_FREES.fetch_add(1, Relaxed); }
}
#[derive(Clone)]
struct Binding { name: String, value: Value, status: &'static str }
struct Expr { op: String, names: Vec<String>, number: i128, args: Vec<Expr> }
struct Tokens<'a>(std::str::SplitWhitespace<'a>);
impl Tokens<'_> {
    fn next(&mut self) -> &str { self.0.next().expect("missing token") }
    fn usize(&mut self) -> usize { self.next().parse().expect("invalid unsigned number") }
    fn number(&mut self) -> i128 { self.next().parse().expect("outside finite i128 domain") }
    fn name(&mut self) -> String {
        let n = self.next();
        assert!(!n.is_empty() && n.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'_'), "invalid name");
        n.into()
    }
    fn value(&mut self) -> Value {
        match self.next() { "n" => Value::Num(self.number()), "l" => Value::List(self.usize()), "b" => { let n = self.usize(); assert!(n <= 1); Value::Bool(n == 1) }, _ => panic!("invalid value") }
    }
    fn expr(&mut self) -> Expr {
        let op = self.next().to_owned();
        let mut e = Expr { op, names: vec![], number: 0, args: vec![] };
        let count = match e.op.as_str() {
            "num" => { e.number = self.number(); 0 }, "nil" => 0,
            "var" => { e.names.push(self.name()); 0 },
            "let" => { e.names.push(self.name()); 2 },
            "match" => { e.names.push(self.name()); e.names.push(self.name()); assert_ne!(e.names[0],e.names[1]); 3 },
            "if" => 3, "add" | "sub" | "eq" | "lt" | "le" | "cons" => 2,
            _ => panic!("unknown expression"),
        };
        for _ in 0..count { e.args.push(self.expr()); }
        e
    }
}
type Env = Vec<(String, Option<usize>)>;
#[derive(Clone)]
struct Frame<'a> { expr: &'a Expr, env: Env }
fn extend(env: &Env, name: &str, id: Option<usize>) -> Env {
    let mut result = vec![(name.to_owned(), id)]; result.extend_from_slice(env); result
}
fn uses(e: &Expr, env: &Env, id: usize) -> bool {
    match e.op.as_str() {
        "var" => env.iter().find(|(n,_)| n == &e.names[0]).is_some_and(|(_,i)| *i == Some(id)),
        "let" => uses(&e.args[0],env,id) || uses(&e.args[1],&extend(env,&e.names[0],None),id),
        "match" => uses(&e.args[0],env,id) || uses(&e.args[1],env,id) || uses(&e.args[2],&extend(&extend(env,&e.names[0],None),&e.names[1],None),id),
        _ => e.args.iter().any(|a| uses(a,env,id)),
    }
}
fn later(fs: &[Frame<'_>], id: usize) -> bool { fs.iter().any(|f| uses(f.expr,&f.env,id)) }
fn frames<'a>(e: &'a Expr, env: &Env, rest: &[Frame<'a>]) -> Vec<Frame<'a>> {
    let mut fs = vec![Frame { expr:e,env:env.clone() }]; fs.extend_from_slice(rest); fs
}
struct State {
    cells: Vec<Box<LiveCell>>,
    next: usize,
    bindings: Vec<Binding>,
    scope: Vec<usize>,
    pending: Vec<Value>,
    outside: Vec<usize>,
    aside: Vec<(usize,usize)>,
    branch: usize,
    record: Vec<(&'static str,usize)>,
    log: Vec<(&'static str,usize)>,
    physical: Vec<(&'static str,usize,usize)>,
    states: Vec<String>,
}
impl State {
    fn empty() -> Self { Self { cells:vec![], next:1, bindings:vec![], scope:vec![], pending:vec![], outside:vec![], aside:vec![], branch:0, record:vec![], log:vec![], physical:vec![], states:vec![] } }
    fn cell(&self,a:usize) -> Cell { self.cells.iter().find(|c| c.0.id == a).expect("cell not allocated").0.clone() }
    fn live(&self,a:usize) -> Cell { let c=self.cell(a); assert!(!c.aside,"reserved cell read"); c }
    fn change(&mut self,a:usize,f:impl FnOnce(&mut Cell)) { f(&mut self.cells.iter_mut().find(|c| c.0.id == a).expect("cell missing").0); }
    fn physical_ptr(&self,a:usize) -> usize { self.cells.iter().find(|c| c.0.id == a).map(|c| &**c as *const LiveCell as usize).expect("physical cell missing") }
    fn allocate(&mut self,c:Cell,fixture:bool) {
        let a=c.id;
        let b=Box::new(LiveCell::new(c));
        let p=&*b as *const LiveCell as usize;
        self.cells.push(b);
        self.physical.push((if fixture { "fixture" } else { "create" },a,p));
        if !fixture { self.record.push(("create",a)); }
    }
    fn release(&mut self,a:usize) {
        let i=self.cells.iter().position(|c| c.0.id == a).expect("release missing cell");
        self.physical.push(("free",a,self.physical_ptr(a)));
        drop(self.cells.remove(i));
        self.record.push(("free",a));
    }
    fn write(&mut self,a:usize,n:i128,t:usize) {
        assert!(self.cell(a).aside,"write needs reservation");
        self.change(a,|c| { c.item=n;c.link=t;c.count=1;c.aside=false; });
        self.physical.push(("write",a,self.physical_ptr(a)));
        self.record.push(("write",a));
    }
    fn enter(&mut self,env:&Env) { self.scope=env.iter().rev().map(|(_,i)| i.expect("runtime binding id")).collect(); }
    fn memory(&self) -> String { array(self.cells.iter().map(|c| c.0.json())) }
    fn snapshot(&mut self,kind:&str,bv:Option<&Value>) {
        let bindings=array(self.bindings.iter().enumerate().filter(|(i,b)| self.scope.contains(i) || b.status == "holding").map(|(i,b)| format!("[{i},{},{},{}]",string(&b.name),b.value.json(),string(b.status))));
        self.states.push(format!("{{\"kind\":{},\"memory\":{},\"bindings\":{},\"pending\":{},\"outside\":{},\"aside\":{},\"branch\":{}}}",string(kind),self.memory(),bindings,array(self.pending.iter().map(Value::json)),array(self.outside.iter().map(|p| pointer(*p))),array(self.aside.iter().map(|(b,a)| format!("[{b},{a}]"))),bv.map_or("null".into(),Value::json)));
    }
    fn bind(&mut self,name:&str,value:Value,status:&'static str) -> usize { let id=self.bindings.len(); self.bindings.push(Binding {name:name.into(),value,status});id }
    fn push(&mut self,v:&Value) { if v.ptr()!=0 { self.pending.insert(0,v.clone()); } }
    fn pop(&mut self,v:&Value) { if v.ptr()!=0 { assert_eq!(self.pending.first(),Some(v),"pending order"); self.pending.remove(0); } }
    fn add(&mut self,a:usize) { let c=self.live(a); self.change(a,|c2| c2.count=c.count+1); }
    fn give_up(&mut self,a:usize) {
        if a==0 { return; }
        let c=self.live(a);assert!(c.count>0,"zero holder count");
        let n=c.count-1;self.change(a,|c| c.count=n);self.snapshot("holderGivenUp",None);
        if n==0 {
            self.log.push(("free",a));self.release(a);
            self.push(&Value::List(c.link));self.snapshot("cellFreed",None);
            if c.link!=0 { self.pop(&Value::List(c.link));self.give_up(c.link); }
        }
    }
    fn give_binding(&mut self,id:usize) { self.bindings[id].status="givenUp"; self.give_up(self.bindings[id].value.ptr()); }
    fn dead(&mut self,env:&Env,chosen:&[Frame<'_>]) {
        for (_,id) in env.iter().rev() {
            let id=id.unwrap();let b=&self.bindings[id];
            if b.value.ptr()!=0 && b.status=="holding" && !later(chosen,id) { self.give_binding(id); }
        }
    }
    fn build(&mut self,n:i128,t:usize,enc:&[usize]) -> Value {
        let a=if let Some(&(bid,a))=self.aside.first() {
            assert!(enc.contains(&bid),"expired reservation");self.aside.remove(0);
            self.write(a,n,t);self.log.push(("write",a));a
        } else {
            let a=self.next;self.next+=1;self.allocate(Cell{id:a,item:n,link:t,count:1,aside:false},false);self.log.push(("create",a));a
        };
        self.pop(&Value::List(t));let v=Value::List(a);self.push(&v);self.snapshot("newCellBuilt",None);v
    }
    fn finish(&mut self,bid:usize,inner:&Env,outer:&Env,v:Value) -> Value {
        self.enter(inner);self.snapshot("branchValueWorkedOut",Some(&v));
        while self.aside.first().is_some_and(|(b,_)| *b==bid) {
            let (_,a)=self.aside.remove(0);self.log.push(("free",a));self.release(a);self.snapshot("cellFreed",None);
        }
        assert!(!self.aside.iter().any(|(b,_)| *b==bid));
        self.enter(outer);self.snapshot("branchValueHandedOn",Some(&v));v
    }
    fn eval<'a>(&mut self,e:&'a Expr,env:&Env,fs:&[Frame<'a>],enc:&[usize]) -> Value {
        match e.op.as_str() {
            "num" => Value::Num(e.number), "nil" => Value::List(0),
            "var" => {
                let id=env.iter().find(|(n,_)| n==&e.names[0]).expect("unbound name").1.unwrap();
                let b=self.bindings[id].clone();
                if b.value.ptr()!=0 {
                    assert_eq!(b.status,"holding","name no longer holds value");
                    if later(fs,id) {
                        self.add(b.value.ptr());self.push(&b.value);self.enter(env);self.snapshot("newHolder",None);
                    } else {
                        self.bindings[id].status="movedOn";self.push(&b.value);self.enter(env);self.snapshot("holderMoved",None);
                    }
                }
                b.value
            }
            "add"|"sub"|"eq"|"lt"|"le" => {
                let a=self.eval(&e.args[0],env,&frames(&e.args[1],env,fs),enc).number();
                let b=self.eval(&e.args[1],env,fs,enc).number();
                match e.op.as_str() {
                    "add"=>Value::Num(a.checked_add(b).expect("outside finite arithmetic domain")),
                    "sub"=>Value::Num(a.checked_sub(b).expect("outside finite arithmetic domain")),
                    "eq"=>Value::Bool(a==b),"lt"=>Value::Bool(a<b),_=>Value::Bool(a<=b),
                }
            }
            "cons" => {
                let h=self.eval(&e.args[0],env,&frames(&e.args[1],env,fs),enc);
                let t=self.eval(&e.args[1],env,fs,enc);
                self.enter(env);let Value::List(t)=t else {panic!("list required")};self.build(h.number(),t,enc)
            }
            "let" => {
                let future=extend(env,&e.names[0],None);
                let v=self.eval(&e.args[0],env,&frames(&e.args[1],&future,fs),enc);
                let holding=v.ptr()!=0;
                let id=self.bind(&e.names[0],v.clone(),if holding {"holding"} else {"noHolder"});
                let inner=extend(env,&e.names[0],Some(id));self.pop(&v);self.enter(&inner);
                if holding {self.snapshot("nameBound",None);}
                if holding && !uses(&e.args[1],&inner,id) {self.give_binding(id);}
                self.eval(&e.args[1],&inner,fs,enc)
            }
            "if" => {
                let f=frames(&e.args[1],env,&frames(&e.args[2],env,fs));
                let Value::Bool(b)=self.eval(&e.args[0],env,&f,enc) else {panic!("condition type")};
                self.enter(env);self.snapshot("branchChosen",None);
                let branch=&e.args[if b {1} else {2}];self.dead(env,&frames(branch,env,fs));
                self.enter(env);self.snapshot("branchStarts",None);self.eval(branch,env,fs,enc)
            }
            "match" => {
                let future=extend(&extend(env,&e.names[0],None),&e.names[1],None);
                let f=frames(&e.args[1],env,&frames(&e.args[2],&future,fs));
                let r=self.eval(&e.args[0],env,&f,enc);self.enter(env);
                let Value::List(a)=r else {panic!("match type")};
                if a!=0 {self.live(a);}
                let bid=self.branch;self.branch+=1;
                let mut nested=vec![bid];nested.extend_from_slice(enc);
                self.snapshot("branchChosen",None);
                if a==0 {
                    self.dead(env,&frames(&e.args[1],env,fs));self.enter(env);self.snapshot("branchStarts",None);
                    let v=self.eval(&e.args[1],env,fs,&nested);return self.finish(bid,env,env,v);
                }
                self.dead(env,&frames(&e.args[2],&future,fs));
                let c=self.live(a);
                let h=self.bind(&e.names[0],Value::Num(c.item),"noHolder");
                let t=self.bind(&e.names[1],Value::List(c.link),"noHolder");
                let inner=extend(&extend(env,&e.names[0],Some(h)),&e.names[1],Some(t));
                let used=uses(&e.args[2],&inner,t);
                if false && c.count==1 {
                    self.pop(&r);self.change(a,|c|{c.aside=true;c.count=0;c.link=0;});self.aside.insert(0,(bid,a));
                    if c.link!=0 {self.bindings[t].status="holding";}
                    self.enter(&inner);self.snapshot("matchStep4Done",None);
                    if c.link!=0 && !used {self.give_binding(t);}
                } else {
                    if c.link!=0 && used {
                        self.add(c.link);self.bindings[t].status="holding";self.enter(&inner);self.snapshot("newHolder",None);
                    }
                    self.pop(&r);self.give_up(a);self.enter(&inner);self.snapshot("matchStep4Done",None);
                }
                self.enter(&inner);self.snapshot("branchStarts",None);
                let v=self.eval(&e.args[2],&inner,fs,&nested);self.finish(bid,&inner,env,v)
            }
            _=>panic!("unknown evaluator operation"),
        }
    }
    fn list(&self,mut a:usize) -> Vec<i128> {
        let mut result=vec![];let mut seen=vec![];
        while a!=0 {assert!(!seen.contains(&a),"cycle");seen.push(a);let c=self.live(a);result.push(c.item);a=c.link;}
        result
    }
    fn validate_start(&self,inputs:&[(String,Value)]) {
        let ids:Vec<_>=self.cells.iter().map(|c|c.0.id).collect();
        for a in &ids {assert_eq!(ids.iter().filter(|b|*b==a).count(),1,"duplicate identity");}
        for (i,(name,_)) in inputs.iter().enumerate() {assert!(!inputs[..i].iter().any(|(n,_)|n==name),"duplicate input");}
        let roots:Vec<_>=inputs.iter().map(|(_,v)|v.ptr()).chain(self.outside.iter().copied()).filter(|p|*p!=0).collect();
        let mut reached=vec![];
        for a in &roots {self.list(*a);let mut p=*a;while p!=0 {reached.push(p);p=self.live(p).link;}}
        for c in &self.cells {
            let c=&c.0;assert!(reached.contains(&c.id),"unreachable fixture");
            let holders=roots.iter().filter(|a|**a==c.id).count()+self.cells.iter().filter(|x|x.0.link==c.id).count();
            assert_eq!(c.count,holders,"invalid fixture count");
        }
    }
}
fn events(xs:&[(&str,usize)]) -> String {array(xs.iter().map(|(k,a)|format!("[{},{}]",string(k),a)))}
fn run(line:&str) -> String {
    let mut t=Tokens(line.split_whitespace());let mut s=State::empty();
    let initial=CELL_ALLOCS.load(Relaxed);
    for _ in 0..t.usize() {
        let id=t.usize();assert!(id>0);let item=t.number();let link=t.usize();let count=t.usize();s.next=s.next.max(id+1);
        s.allocate(Cell{id,item,link,count,aside:false},true);
    }
    let fixture=CELL_ALLOCS.load(Relaxed)-initial;
    let mut inputs=vec![];
    for _ in 0..t.usize() {inputs.push((t.name(),t.value()));}
    for _ in 0..t.usize() {s.outside.push(t.usize());}
    let e=t.expr();assert!(t.0.next().is_none(),"extra input");s.validate_start(&inputs);
    let before=(ALLOCS.load(Relaxed),BYTES.load(Relaxed),CELL_ALLOCS.load(Relaxed),CELL_FREES.load(Relaxed));
    // The measured interval begins before all evaluation preparation.
    let mut env=vec![];
    for (name,value) in inputs {
        let status=if value.ptr()!=0 {"holding"} else {"noHolder"};let id=s.bind(&name,value,status);env=extend(&env,&name,Some(id));
    }
    s.enter(&env);
    for (_,id) in env.iter().rev() {let id=id.unwrap();if s.bindings[id].value.ptr()!=0 && !uses(&e,&env,id) {s.give_binding(id);}}
    s.snapshot("start",None);
    let result=s.eval(&e,&env,&[],&[]);s.snapshot("end",None);
    let after=(ALLOCS.load(Relaxed),BYTES.load(Relaxed),CELL_ALLOCS.load(Relaxed),CELL_FREES.load(Relaxed));
    let value=match &result {Value::List(p)=>format!("[\"l\",{}]",array(s.list(*p).iter().map(|n|format!("\"{n}\"")))),_=>result.json()};
    format!("{{\"outcome\":{{\"answer\":{},\"value\":{},\"memory\":{},\"record\":{},\"log\":{},\"states\":{}}},\"physical\":{},\"alloc\":{{\"fixture_cells\":{},\"cell_allocs\":{},\"cell_frees\":{},\"system_allocs\":{},\"system_bytes\":{}}}}}",result.json(),value,s.memory(),events(&s.record),events(&s.log),array(s.states.iter().cloned()),array(s.physical.iter().map(|(k,a,p)|format!("[{},{a},{p}]",string(k)))),fixture,after.2-before.2,after.3-before.3,after.0-before.0,after.1-before.1)
}
fn main() {
    for (i,line) in io::stdin().lock().lines().enumerate() {
        let line=line.expect("stdin read failed");
        match std::panic::catch_unwind(||run(&line)) {
            Ok(result)=>println!("{result}"),Err(_)=>{eprintln!("failed input index {i}");std::process::exit(1);}
        }
    }
}
