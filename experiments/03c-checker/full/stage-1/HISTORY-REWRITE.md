# Stage-1 history migration — 10 October 2026

At Robert's direction, the proof branch was saved, rebased onto the rewritten
`origin/main`, and stripped of gzip evidence in every replayed commit before
pushing. Only this thread's eight commits were replayed. The original frozen
documents and checksum manifests remain byte-identical; their old commit
references map to the revisions below. This is a storage migration, not a new
model amendment or stage-1 acceptance.

| Original revision | Rebased revision |
| --- | --- |
| `2dcea716a917635ef51cd523401a7551722d9fe8` | `05ff0794dd4005b989b41752971515e1fda3b83b` |
| `a17f65215ed14288416c92e8af028078ffb827ff` | `f427d0fe1a4badb9d1fd470e6e3ef83a06f2f6a5` |
| `cd33b7cbfd59ea9a3a8e424b3212e7432637f7d0` | `3827b0e290df885bb257f3ba0128242f203ccd18` |
| `ea0fde992d7f9d59bf5f5bedda6e911f4edb8baf` | `6b985f07d04677139a6bb5dd9cbc60e6632a1863` |
| `37914e13e175a2f0ad1eec19aa83ac0c2e87a16f` | `d181b0c520321bd74abe0319f18c7cf52593cc50` |
| `7800eab109caca85b9d2c03d0abf18df3701e856` | `ca4a020a6c66ea54aead82c63662a9edb7220bf0` |
| `1a8a18c55886ad99cc4b5bc75c33df0a080fa009` | `9f96f1d15739711cd8f4dd64f361b0c279c4a339` |
| `9740c5941d290d98b6b258ccd17a4a9a1c4042ba` | `8341c199d510dec94f798ff512d527668be7d633` |

The old-model counterexample can be reproduced at the rebased counterpart of
its original checkpoint. The amended model, sealed regressions, all proof
sources, and original manifests are unchanged by this migration.

Both raw traces are now restored from the
[`gz-evidence-archive` release](https://github.com/robertguss/mo-v2/releases/tag/gz-evidence-archive),
using the instructions in `experiments/GZ_ARCHIVE.md`:

- Original verification: `gz-03c-checker-history.tar`, already archived.
- Amended-rank verification: `gz-03c-checker-rank-amendment-01.tar`, uploaded
  during this migration and downloaded again to verify byte identity.

`experiments/GZ_ARCHIVE.sha256` includes both original-path checksums. The
restored files are ignored by Git and still satisfy the existing evidence and
preparation manifests. Do not change those manifests to excuse missing data.

The saved proof continuation remains partial: F5 and L1 are the only complete
unconditional targets. No full ProofGate pass is claimed by this migration.
