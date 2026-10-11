# Separately executed verification

Run from repository root:

```sh
python3 -B experiments/03c-checker/full/stage-2/completion/reproduce.py experiments/03c-checker/full/stage-2/completion/verifier/reproduction
python3 -B experiments/03c-checker/full/stage-2/completion/verifier/reproduce_independent.py
python3 -B experiments/03c-checker/full/stage-2/completion/verifier/proof_controls.py
```

The first command failed operationally at Gate.lean, after the clean 172-job build:
missing `Lean.Elab.Command` import. Its untouched gate log is preserved. The
second command uses the inspected original runner with exactly one substitution:
copy the verifier's Inventory.lean instead of the builder's Gate.lean. It preserves
the exact target and environment theorem enumeration and adds the missing import.
Neither delivered source nor frozen expectation is changed. The output directory
must not already exist; move prior verifier output aside for another execution.

Individual reconstruction commands, exits, source SHA256s, theorem names and
transitive axiom outputs are in independent-reproduction/. Audit.lean lists every
public/generated theorem found in the actual environment. Fresh leanchecker
rechecks this audit and its imported dependencies, not a fixture substitute.
The clean source is git archive of exact stage1 commit plus 19 additive Demand
sources, with no .lake copied. Only the two checksummed public full3c gzip assets
are restored. No private experiment13 access or external publication occurs.

Proof controls require a passing exact-target baseline, reject True.intro by
elaboration, and reject successfully elaborated placeholder/additional-axiom
candidates by the complete transitive allowlist. The runnable scratch directory
is removed by TemporaryDirectory; exact sources remain only as .lean.txt evidence.
An initial verifier-script path mistake and case-sensitive diagnostic comparison
were corrected in this verifier-only script before its successful full run.

Working-tree inventory cross-check:

```sh
lake env lean ../stage-2/completion/verifier/Inventory.lean
```

Run from full/lean. inventory.log captures the actual public theorem and other
constant names; inventory-coverage.json records exact 19-file manifest coverage.
No suspicious proof trust tokens were found by:

```sh
rg -n 'sorry|admit|axiom |unsafe|native_decide|implemented_by|extern|opaque|elab|syntax|attribute' experiments/03c-checker/full/lean/Full/Demand*
```
