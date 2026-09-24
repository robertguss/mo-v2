# Experiment 3: lock

Fingerprints (SHA-256) of the locked files. This is the third lock:

1. The first was recorded after Robert approved the plan (D44) and the acceptance file (D50).
2. The second was recorded after the first Codex review and its fixes (D51, D52, D53).
3. This one was recorded on 23 Sep 2026, after the Codex verification and the locked-file fixes Robert approved (D56).

Earlier locks are in git history. The builder may not change any of these files, and the lead re-checks them before scoring.

```
403260c63bd3e4a60e5ec875659d3288901589a9400696c0370cfc197eed49ab  PLAN.md
47631069619a41b42a177fccd623cca924095a76078537fa8d08cdfbd23b6037  ACCEPTANCE.md
ec402d5f1268c10eeaf1f58390694e21162255fa5e26671a3ed4cb49fb99f5d6  run.sh
4575c9a96353e2e3e21c88e3c3fe7499520ca0bebc585abdf0a50de42a43c309  acceptance/measure.py
fa9a4736fe0b69ee6050929dfd488ae09dd4e3742f491fa1012535222f5c4c29  acceptance/claim-c/bad-build-from-nothing.kk
c04f70132f071ef6352eae0fa0a8158f7fa7c42cc7a90d060cb30952e35f4cb5  acceptance/claim-c/bad-calls-normal.kk
789cf8c5ccfbe3d8c1c1236bc0d50b8add901c924db9b7db7c6872f141a85c81  acceptance/claim-c/bad-duplicate.kk
179ac3e9d74a00e2f321b62ddb07f18695793428b35be1cfa78a88bf28a39fb2  acceptance/claim-c/bad-grow-pair.kk
a7bacf0761c66edb939a217d85e8c8761bda199178509cd8aa6142047b780770  acceptance/claim-c/bad-keep-both.kk
ea067910ca63d6d71b0a41cfc8e84b6bac137148dd0273f2a9df436f28236009  acceptance/claim-c/bad-throw-away.kk
76d87f6100ed54928388718129ea5c2dbe6656c77dd96f94a49c07f96bf7e7f4  acceptance/claim-c/good-add-one.kk
3ffd4567d369d41200093efdbd71641bdd4d6669a19d5f907d3c790133aed5f4  acceptance/claim-c/good-map-pairs.kk
77e8a92739a89cd83a41d7b6098df226ec39ebbbff58e1450d2cf2a2e7f2e28d  acceptance/claim-c/good-reverse.kk
ed8151aacd27762da77c1c00e1a5ead0af7f033fa95eb1c3035dd535c09d89c4  acceptance/claim-c/good-rotate.kk
67535167542064c49182d95cc792d46f8f919b904d5e599539ce7d9da1af9ae2  acceptance/claim-c/good-running-total.kk
97a59ea69cb70a057575401d786a25ad9aa2daeadf343425fffdb525b45d51d0  acceptance/claim-c/good-swap.kk
e77a01d3257eea3dbe2a7a3d4aede63b8256590a593b4ba07cef799c4215aa19  acceptance/claim-d/examples.kk
94c542bd0bafeecb3b672f52910b7ebbd91692f3a7fbf9dd6ce0e92c67df9b8a  acceptance/claim-d/types.kk
```
