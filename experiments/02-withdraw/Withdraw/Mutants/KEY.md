# Mutant key, Experiment 2

Promises: P1 correct result, P2 succeeds when it should, P3 fails when it
should, P4 zero is invalid.

| Mutant | Bug | Breaks | Triggering input (balance, amount) |
|---|---|---|---|
| M01 | The balance check is backwards (`amount < balance` instead of `balance < amount`), so ordinary withdrawals are refused. | P2 | (10000, 3000) |
| M02 | Too-large withdrawals fail with "invalid amount" instead of "insufficient funds". | P3 | (0, 100) |
| M03 | The subtraction is the wrong way round (`amount - balance`), so the new balance is wrong (usually 0). | P1 | (10000, 3000) |
| M04 | Uses `≤` instead of `<`, so withdrawing the exact balance is refused. | P2 | (10000, 10000) |
| M05 | The zero-amount check is missing, so withdrawing 0 succeeds. | P4 | (10000, 0) |
| M06 | Off by one (`balance + 1 < amount`): an overdraft of exactly 1 cent is allowed and the balance quietly stops at 0. | P1 (and P3) | (100, 101) |
| M07 | The new balance is computed in 32-bit arithmetic, so it wraps for balances of 2^32 cents or more. | P1 | (4294967301, 3) |
| M08 | The zero check converts the amount to a signed 32-bit number, so amounts of 2^31 or more look negative and are called "invalid". | P3 (and P2 when the balance covers it) | (0, 2147483648) |
| M09 | A hidden limit: any amount over 1,000,000 cents is refused as "insufficient funds" even when the balance covers it. | P2 | (2000000, 1000001) |
| M10 | The balance check compares in 64-bit arithmetic, so amounts of 2^64 or more wrap to small numbers and pass; the balance quietly stops at 0. | P1 (and P3) | (5, 18446744073709551617) |

M06 to M10 pass all six approved examples; M01 to M05 fail at least one.
