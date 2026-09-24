// Claim B helper: an ordinary function (not marked fip or fbip) in its own module.
// It hands back the value it is given.
module helper

pub fun pass-along(x : a) : a
  x
