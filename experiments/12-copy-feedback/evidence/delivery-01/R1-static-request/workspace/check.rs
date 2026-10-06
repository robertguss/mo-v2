extern crate helper;
mod task {include!(env!("TASK_SOURCE"));}
fn main(){
let mut input=helper::List::new(); for v in vec![].into_iter().rev() {input=input.push_front(v);}
let (out,old)=task::run(input); assert_eq!(out.iter().collect::<Vec<_>>(),vec![]);assert_eq!(old.as_ref().map(|x|x.iter().collect::<Vec<_>>()),Some(vec![]));
let mut input=helper::List::new(); for v in vec![3, -2, 7].into_iter().rev() {input=input.push_front(v);}
let (out,old)=task::run(input); assert_eq!(out.iter().collect::<Vec<_>>(),vec![4, -1, 8]);assert_eq!(old.as_ref().map(|x|x.iter().collect::<Vec<_>>()),Some(vec![3, -2, 7]));
println!("Example values and required original: PASS");}
