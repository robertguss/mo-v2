use num_bigint::BigInt;
use num_traits::{ToPrimitive, Zero};
use std::hint::black_box;
use std::io::{self, BufRead};
use std::time::Instant;

type Res<T> = Result<T, &'static str>;
#[derive(Clone)]
enum Number { Fixed(i64), Big(BigInt) }
impl Number {
    fn big(self) -> BigInt {match self {Self::Fixed(n)=>n.into(),Self::Big(n)=>n}}
    fn output(&self,explicit:bool)->String {match self {Self::Fixed(n)=>format!("{}{}",if explicit {"f:"} else {""},n),Self::Big(n)=>format!("{}{}",if explicit {"b:"} else {""},n)}}
}
fn literal(s:&str,big:bool)->Res<Number> {
    let digits=s.strip_prefix(['+','-']).unwrap_or(s);
    if digits.is_empty() || !digits.bytes().all(|b|b.is_ascii_digit()) {return Err("invalid_literal");}
    if big {Ok(Number::Big(s.parse().map_err(|_|"invalid_literal")?))}
    else {Ok(Number::Fixed(s.parse().map_err(|_|"range")?))}
}
fn calculate(policy:&str,op:&str,a:Number,b:Number)->Res<Number> {
    if false && matches!((&a,&b),(Number::Fixed(_),Number::Big(_))|(Number::Big(_),Number::Fixed(_))) {return Err("type_mismatch");}
    match (a,b) {
        (Number::Fixed(a),Number::Fixed(b))=>{
            if (op=="div" || op=="rem") && b==0 {return Err("divide_by_zero");}
            let n=if policy=="wrapping" {match op {
                "add"=>a.wrapping_add(b),"sub"=>a.wrapping_sub(b),"mul"=>a.wrapping_mul(b),
                "div"=>a.wrapping_div(b),"rem"=>a.wrapping_rem(b),_=>return Err("invalid_op"),
            }} else {match op {
                "add"=>a.checked_add(b),"sub"=>a.checked_sub(b),"mul"=>a.checked_mul(b),
                "div"=>a.checked_div(b),"rem"=>a.checked_rem(b),_=>return Err("invalid_op"),
            }.ok_or("overflow")?};
            Ok(Number::Fixed(n))
        }
        (a,b)=>{
            let a=a.big();let b=b.big();
            if (op=="div" || op=="rem") && b.is_zero() {return Err("divide_by_zero");}
            Ok(Number::Big(match op {"add"=>a+b,"sub"=>a-b,"mul"=>a*b,"div"=>a/b,"rem"=>a%b,_=>return Err("invalid_op")}))
        }
    }
}
fn case(line:&str)->Res<String> {
    let words:Vec<_>=line.split_whitespace().collect();
    if words.len()<3 {return Err("invalid_request");}
    let p=words[0];let op=words[1];
    if !["checked","wrapping","big","explicit"].contains(&p) {return Err("invalid_policy");}
    let mut ns=vec![];
    for token in &words[2..] {
        let (big,s)=if p=="explicit" {
            if let Some(s)=token.strip_prefix("f:") {(false,s)}
            else if let Some(s)=token.strip_prefix("b:") {(true,s)} else {return Err("type_required");}
        } else {(p=="big",*token)};
        ns.push(literal(if s=="~" {""} else {s},big)?);
    }
    let unary=["parse","neg","roundtrip","asfixed","asbig"].contains(&op);
    if ns.len()!=if unary {1} else {2} {return Err("invalid_request");}
    let a=ns.remove(0);
    let result=match op {
        "parse"=>a,
        "asfixed"=>{
            if p!="explicit" {return Err("invalid_op");}
            let x=a.big();Number::Fixed(x.to_i64().ok_or("narrowing")?)
        }
        "asbig"=>{if p!="explicit" {return Err("invalid_op");}Number::Big(a.big())}
        "neg"=>match a {Number::Fixed(n)=>Number::Fixed(if p=="wrapping" {n.wrapping_neg()} else {n.checked_neg().ok_or("overflow")?}),Number::Big(n)=>Number::Big(-n)},
        "roundtrip"=>{
            let one=match &a {Number::Fixed(_)=>Number::Fixed(1),Number::Big(_)=>Number::Big(1.into())};
            let x=calculate(p,"add",a,one.clone())?;calculate(p,"sub",x,one)?
        }
        "cancel"=>{let b=ns.remove(0);let x=calculate(p,"mul",a,b.clone())?;calculate(p,"div",x,b)?}
        _=>calculate(p,op,a,ns.remove(0))?,
    };
    Ok(result.output(p=="explicit"))
}

#[cfg(feature="measure")]
mod memory {
    use std::alloc::{GlobalAlloc,Layout,System};
    use std::sync::atomic::{AtomicU64,Ordering::Relaxed};
    pub static CALLS:AtomicU64=AtomicU64::new(0);
    pub static REQUESTED:AtomicU64=AtomicU64::new(0);
    pub static LIVE:AtomicU64=AtomicU64::new(0);
    pub static PEAK:AtomicU64=AtomicU64::new(0);
    pub struct Allocator;
    fn add(n:usize){CALLS.fetch_add(1,Relaxed);REQUESTED.fetch_add(n as u64,Relaxed);let live=LIVE.fetch_add(n as u64,Relaxed)+n as u64;PEAK.fetch_max(live,Relaxed);if live>512*1024*1024 {std::process::abort();}}
    unsafe impl GlobalAlloc for Allocator {
        unsafe fn alloc(&self,l:Layout)->*mut u8 {let p=unsafe{System.alloc(l)};if !p.is_null(){add(l.size());}p}
        unsafe fn dealloc(&self,p:*mut u8,l:Layout){unsafe{System.dealloc(p,l)};LIVE.fetch_sub(l.size() as u64,Relaxed);}
        unsafe fn realloc(&self,p:*mut u8,l:Layout,n:usize)->*mut u8 {let q=unsafe{System.realloc(p,l,n)};if !q.is_null(){LIVE.fetch_sub(l.size() as u64,Relaxed);add(n);}q}
    }
    pub fn start()->[u64;3]{let live=LIVE.load(Relaxed);PEAK.store(live,Relaxed);[CALLS.load(Relaxed),REQUESTED.load(Relaxed),live]}
    pub fn end(a:[u64;3])->[u64;5]{[CALLS.load(Relaxed)-a[0],REQUESTED.load(Relaxed)-a[1],a[2],LIVE.load(Relaxed),PEAK.load(Relaxed)]}
    pub fn live()->u64 {LIVE.load(Relaxed)}
}
#[cfg(feature="measure")]
#[global_allocator]
static ALLOC:memory::Allocator=memory::Allocator;
#[cfg(not(feature="measure"))]
mod memory {pub fn start()->[u64;3]{[0;3]}pub fn end(_: [u64;3])->[u64;5]{[0;5]}pub fn live()->u64{0}}
struct Phase {ns:u128,m:[u64;5]}
impl Phase {fn json(&self)->String {format!("{{\"ns\":{},\"memory\":{{\"calls\":{},\"requested\":{},\"live_start\":{},\"live_end\":{},\"peak_live\":{}}}}}",self.ns,self.m[0],self.m[1],self.m[2],self.m[3],self.m[4])}}
fn begin()->(Instant,[u64;3]){(Instant::now(),memory::start())}
fn end(a:(Instant,[u64;3]))->Phase {let ns=a.0.elapsed().as_nanos();let m=memory::end(a.1);Phase{ns,m}}
fn pool(work:&str)->Vec<String>{match work {"parse"=>(0..1000).map(|i|i.to_string()).collect(),"wide128"|"wide1024"=>{let bits:usize=work[4..].parse().unwrap();vec![((BigInt::from(1)<< (bits-1))+BigInt::from(17)).to_string()]},_=>vec![]}}
fn report(answer:String,setup:Phase,parse:Phase,arithmetic:Phase,cleanup:u64){println!("{{\"answer\":\"{}\",\"instrumented\":{},\"setup\":{},\"parse\":{},\"arithmetic\":{},\"cleanup_live\":{}}}",answer,cfg!(feature="measure"),setup.json(),parse.json(),arithmetic.json(),cleanup);}
fn bench_fixed<const WRAP:bool>(work:&str,n:usize)->Res<()> {
    let a=begin();let strings=pool(work);let setup=end(a);
    let a=begin();
    let values:Vec<i64>=if work=="counter" {vec![]} else if work=="total" {(0..n).map(|i|(i%1000+1) as i64).collect()}
        else {(0..n).map(|i|strings[i%strings.len()].parse().map_err(|_|"range")).collect::<Res<_>>()?};
    let parse=end(a);let a=begin();let mut value=if work=="counter"{1i64}else{0i64};
    if work=="counter" {
        for _ in 0..n {let x=black_box(value);value=if WRAP{x.wrapping_mul(1664525).wrapping_add(1013904223)%1000003}else{x.checked_mul(1664525).and_then(|x|x.checked_add(1013904223)).ok_or("overflow")?%1000003};}
    } else {for &v in &values {value=if WRAP{black_box(value).wrapping_add(black_box(v))}else{black_box(value).checked_add(black_box(v)).ok_or("overflow")?};}}
    black_box(value);let arithmetic=end(a);drop(values);drop(strings);let cleanup=memory::live();
    report(value.to_string(),setup,parse,arithmetic,cleanup);Ok(())
}
fn bench_big(work:&str,n:usize)->Res<()> {
    let a=begin();let strings=pool(work);let setup=end(a);
    let a=begin();
    let values:Vec<BigInt>=if work=="counter"{vec![]}else if work=="total"{(0..n).map(|i|BigInt::from(i%1000+1)).collect()}
        else {(0..n).map(|i|strings[i%strings.len()].parse().map_err(|_|"invalid_literal")).collect::<Res<_>>()?};
    let parse=end(a);let a=begin();let mut value=BigInt::from(if work=="counter"{1}else{0});
    if work=="counter" {for _ in 0..n {value=(black_box(&value)*1664525+1013904223)%1000003;}}
    else {for v in &values {value=black_box(&value)+black_box(v);}}
    black_box(&value);let arithmetic=end(a);
    // Format after measurement; drop the result string before sampling cleanup.
    let answer=value.to_string();drop(value);drop(values);drop(strings);
    let answer_bytes=answer.capacity() as u64;
    let cleanup=if cfg!(feature="measure"){memory::live()-answer_bytes}else{0};
    report(answer,setup,parse,arithmetic,cleanup);Ok(())
}
fn calibration(){
    #[cfg(feature="measure")]
    {
        use std::alloc::{alloc,dealloc,realloc,Layout};
        let a=memory::start();
        unsafe {let l=Layout::from_size_align(64,8).unwrap();let p=alloc(l);assert!(!p.is_null());black_box(p);let p=realloc(p,l,128);assert!(!p.is_null());black_box(p);dealloc(p,Layout::from_size_align(128,8).unwrap());}
        let m=memory::end(a);assert_eq!(m[0],2);assert_eq!(m[1],192);assert_eq!(m[3],m[2]);assert_eq!(m[4],m[2]+128);
        println!("calibrated calls=2 requested=192 extra_peak=128 live_restored=true");
    }
    #[cfg(not(feature="measure"))]
    panic!("calibration requires measure feature");
}
fn main(){
    let args:Vec<_>=std::env::args().collect();
    match args.get(1).map(String::as_str){
        Some("cases")=>for line in io::stdin().lock().lines(){match case(&line.unwrap()){Ok(n)=>println!("ok {n}"),Err(e)=>println!("err {e}")}},
        Some("calibrate")=>calibration(),
        Some("bench")=>{
            assert_eq!(args.len(),5);let p=&args[2];let w=&args[3];let n:usize=args[4].parse().unwrap();assert!((1..=1000000).contains(&n));assert!(["total","parse","counter","wide128","wide1024"].contains(&w.as_str()));
            let r=match p.as_str(){"checked"|"explicit-fixed"=>bench_fixed::<false>(w,n),"wrapping"=>bench_fixed::<true>(w,n),"big"|"explicit-big"=>bench_big(w,n),_=>Err("invalid_policy")};
            if let Err(e)=r {eprintln!("err {e}");std::process::exit(2);}
        }
        _=>panic!("usage: cases | calibrate | bench POLICY WORK N"),
    }
}
