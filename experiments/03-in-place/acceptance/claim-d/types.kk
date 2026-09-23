// Shared data types for claim D. Written by the lead; the builder may not change this file.
module types

pub value struct item(quantity : int, price : int)
pub struct product(name : string, price : int)
pub struct stock(sku : string, count : int)
pub type tree
  Leaf
  Node(left : tree, key : int, right : tree)
pub struct address(street : string, city : string)
pub struct customer(name : string, address : address)
