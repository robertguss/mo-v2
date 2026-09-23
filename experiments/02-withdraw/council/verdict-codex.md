V01: BUGGY - Promise 3 breaks at (0, 1): returns invalidAmount instead of insufficientFunds.
V02: BUGGY - Promise 2 breaks at (4294967296, 4294967296): amount.toInt32 is 0, so returns invalidAmount instead of succeeding.
V03: BUGGY - Promise 1 breaks at (2, 1): returns .ok 0, but 0 + 1 ≠ 2.
V04: BUGGY - Promise 2 breaks at (1000001, 1000001): returns insufficientFunds instead of succeeding.
V05: BUGGY - Promises 1 and 3 break at (0, 1): returns .ok 0 instead of insufficientFunds, and 0 + 1 ≠ 0.
V06: BUGGY - Promise 1 breaks at (4294967297, 1): UInt32 conversion and subtraction yield .ok 0, but 0 + 1 ≠ 4294967297.
V07: BUGGY - Promise 2 breaks at (1, 1): returns insufficientFunds instead of succeeding.
V08: CORRECT
V09: BUGGY - Promise 2 breaks at (2, 1): returns insufficientFunds instead of succeeding.
V10: BUGGY - Promise 4 breaks at (0, 0): returns .ok 0 instead of invalidAmount.
V11: BUGGY - Promise 2 breaks at (18446744073709551616, 1): balance.toUInt64 is 0, so returns insufficientFunds instead of succeeding.
