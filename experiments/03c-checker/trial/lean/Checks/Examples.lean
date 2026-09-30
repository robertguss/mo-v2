import Trial.Broken

/-! Independently copied from the locked EXAMPLES.md. Addresses c1, c2, ...
are 1, 2, ... . Input order is preserved, including the number inputs. -/
namespace Checks
open Trial

def p1 : Expr := .matchE (.var "xs") .nil "h" "t"
  (.cons (.add (.var "h") (.num 1)) (.var "t"))
def p2 : Expr := .matchE (.var "xs") .nil "a" "t"
  (.matchE (.var "t") (.cons (.var "a") .nil) "b" "u"
    (.cons (.var "b") (.cons (.var "a") (.var "u"))))
def p3 : Expr := .matchE (.var "xs") .nil "h" "t" (.var "t")
def p4 : Expr := .matchE (.var "xs") (.num 0) "a" "t"
  (.matchE (.var "t") (.var "a") "b" "u" (.add (.var "a") (.var "b")))
def p5 : Expr := .matchE (.var "xs") (.num 0) "h" "t" (.var "h")
def p6 : Expr := .cons (.var "n") (.var "xs")
def p7 : Expr := .matchE (.var "xs") .nil "h" "t"
  (.cons (.var "h") (.cons (.var "h") (.var "t")))
def p8 : Expr := .letE "ys"
  (.matchE (.var "xs") .nil "h" "t" (.cons (.add (.var "h") (.num 1)) (.var "t")))
  (.matchE (.var "xs") (.var "ys") "h" "t" (.cons (.var "h") (.var "ys")))
def p9 : Expr := .matchE (.var "xs") (.var "ys") "h" "t"
  (.matchE (.var "ys") (.var "t") "k" "u"
    (.cons (.add (.var "h") (.var "k")) (.var "u")))
def p10 : Expr := .matchE (.var "xs") .nil "h" "t"
  (.ifE (.lt (.var "h") (.var "n"))
    (.cons (.add (.var "h") (.num 1)) (.var "t")) (.var "t"))
def p11 : Expr := .matchE (.var "xs") .nil "h" "t"
  (.ifE (.le (.var "h") (.var "n"))
    (.cons (.add (.var "h") (.num 1)) (.var "t")) (.var "t"))
def p12 : Expr := .matchE (.var "xs") .nil "h" "t"
  (.ifE (.eq (.var "h") (.var "n"))
    (.cons (.add (.var "h") (.num 1)) (.var "t")) (.var "t"))
def p13 : Expr := .matchE (.var "xs") (.var "ys") "h" "t"
  (.cons (.add (.var "h") (.num 1)) (.var "t"))
def p14 : Expr := .ifE (.lt (.var "n") (.num 0)) (.var "ys")
  (.matchE (.var "xs") .nil "h" "t" (.cons (.add (.var "h") (.num 1)) (.var "t")))
def p15 : Expr := .matchE (.var "xs") .nil "a" "t"
  (.letE "r"
    (.matchE (.var "t") .nil "b" "u" (.cons (.add (.var "b") (.num 1)) (.var "u")))
    (.cons (.var "a") (.var "r")))
def p16 : Expr := .letE "xs"
  (.matchE (.var "xs") .nil "h" "t" (.cons (.add (.var "h") (.num 1)) (.var "t")))
  (.var "xs")
def p17 : Expr := .matchE (.var "xs") (.lt (.num 0) (.num 0)) "h" "t"
  (.lt (.var "h") (.num 0))
def p18 : Expr := .cons
  (.matchE (.var "xs") (.num 0) "h" "t" (.var "h"))
  (.matchE (.var "xs") .nil "h" "t" (.cons (.add (.var "h") (.num 1)) (.var "t")))
def p19 : Expr := .cons (.var "n") .nil
def p20 : Expr := .matchE (.var "xs") .nil "h" "t"
  (.cons (.sub (.var "h") (.num 5)) (.var "t"))

def mEmpty : Start := ⟨[], [("xs", .list none)], []⟩
def mOne : Start := ⟨[⟨1, 1, none, 1⟩], [("xs", .list (some 1))], []⟩
def mTwo : Start := ⟨[⟨1, 1, some 2, 1⟩, ⟨2, 2, none, 1⟩],
  [("xs", .list (some 1))], []⟩
def mThree : Start := ⟨[⟨1, 1, some 2, 1⟩, ⟨2, 2, some 3, 1⟩, ⟨3, 3, none, 1⟩],
  [("xs", .list (some 1))], []⟩
def mFourFive : Start := ⟨[⟨1, 4, some 2, 1⟩, ⟨2, 5, none, 1⟩],
  [("xs", .list (some 1))], []⟩
def mSeven : Start := ⟨[⟨1, 7, some 2, 1⟩, ⟨2, 8, some 3, 1⟩, ⟨3, 9, none, 1⟩],
  [("xs", .list (some 1))], []⟩
def mKept : Start := ⟨[⟨1, 1, some 2, 2⟩, ⟨2, 2, some 3, 1⟩, ⟨3, 3, none, 1⟩],
  [("xs", .list (some 1))], [some 1]⟩
def mKeptSecond : Start := ⟨[⟨1, 1, some 2, 1⟩, ⟨2, 2, some 3, 2⟩, ⟨3, 3, none, 1⟩],
  [("xs", .list (some 1))], [some 2]⟩
def mSharedTail : Start := ⟨[⟨1, 1, some 3, 1⟩, ⟨2, 2, some 3, 1⟩,
  ⟨3, 3, some 4, 2⟩, ⟨4, 4, none, 1⟩],
  [("xs", .list (some 1)), ("ys", .list (some 2))], []⟩
def mSameList : Start := ⟨[⟨1, 1, some 2, 2⟩, ⟨2, 2, none, 1⟩],
  [("xs", .list (some 1)), ("ys", .list (some 1))], []⟩
def mLarge : Start := ⟨[⟨1, 9223372036854775807, none, 1⟩],
  [("xs", .list (some 1))], []⟩
def mMinus : Start := ⟨[⟨1, -3, some 2, 1⟩, ⟨2, 4, none, 1⟩],
  [("xs", .list (some 1))], []⟩
def mJustTwo : Start := ⟨[⟨1, 2, none, 1⟩], [("xs", .list (some 1))], []⟩

structure Run where
  number : Nat
  program : Expr
  start : Start

def runs : List Run :=
  [⟨1, p1, mThree⟩, ⟨2, p1, mOne⟩, ⟨3, p1, mEmpty⟩, ⟨4, p1, mLarge⟩,
   ⟨5, p1, mKept⟩, ⟨6, p2, mThree⟩, ⟨7, p2, mOne⟩, ⟨8, p2, mKeptSecond⟩,
   ⟨9, p3, mThree⟩, ⟨10, p4, mFourFive⟩, ⟨11, p5, mSeven⟩,
   ⟨12, p6, { mTwo with inputs := [("n", .num 0), ("xs", .list (some 1))] }⟩,
   ⟨13, p7, mTwo⟩, ⟨14, p8, mTwo⟩, ⟨15, p9, mSharedTail⟩,
   ⟨16, p10, { mTwo with inputs := [("xs", .list (some 1)), ("n", .num 5)] }⟩,
   ⟨17, p10, { mTwo with inputs := [("xs", .list (some 1)), ("n", .num 0)] }⟩,
   ⟨18, p11, { mTwo with inputs := [("xs", .list (some 1)), ("n", .num 1)] }⟩,
   ⟨19, p12, { mTwo with inputs := [("xs", .list (some 1)), ("n", .num 1)] }⟩,
   ⟨20, p12, { mTwo with inputs := [("xs", .list (some 1)), ("n", .num 7)] }⟩,
   ⟨21, p13, mSameList⟩,
   ⟨22, p14, { mSameList with inputs :=
     [("n", .num 1), ("xs", .list (some 1)), ("ys", .list (some 1))] }⟩,
   ⟨23, p15, mThree⟩, ⟨24, p16, mTwo⟩, ⟨25, p17, mMinus⟩, ⟨26, p18, mTwo⟩,
   ⟨27, p19, { mTwo with inputs := [("n", .num 5), ("xs", .list (some 1))] }⟩,
   ⟨28, p20, mJustTwo⟩]

end Checks
