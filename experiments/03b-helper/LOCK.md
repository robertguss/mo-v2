# Experiment 3b: lock

Fingerprints (SHA-256) of the locked files, recorded on 23 Sep 2026 after
Robert approved the plan (D68) and the acceptance file (D69). This is the
first lock. The builder may not change any of these files, and the lead
re-checks them before scoring.

## This experiment's files

```
ebd280c9572db6f60415791358435b796832970504b65b542b10af085a9d59f6  PLAN.md
531b55f87f814ec7bbd62ebb8dc7cf7447251286a4daac5d52613467f57f73e3  ACCEPTANCE.md
c8793853b7ec0e3a87b860dc066c09c8364f7ac7dc28c684366fb0940d46bdb5  run.sh
703274e343e7e5f8682ec190344d083d446fa9c1480967e14ae46001fdd25a25  acceptance/measure.py
e31ae8dcb463dbefab53e5bdbcee6401e845363d76a52c40686dd327a83a7309  acceptance/harness/Cargo.toml
6f72009ed47523d29fff55a8c5c212228af78a76a9e81194ddba77687b40bc66  acceptance/harness/Cargo.lock
1c11550598258f068417d453cabcf2adaaa0b62ec5a5cd613c533d2e577a4f4c  acceptance/harness/build.rs
a5b64afd5213c395189f3cf95c258237f5a4c9a981ab200fc79a6c8254d2a865  acceptance/harness/src/lib.rs
43d44739c8e723373c5787e703b16774bf78c40e38b8af0b96f367e4c7e8087d  acceptance/harness/src/bin/b1.rs
6bf0a695d068ea3cb069f89bfb88117c7163f468886dc2219f20d0663382a9bf  acceptance/harness/src/bin/b2.rs
01109b2950a79e94cfe886e8e69aab3c039a6bd40d9b16d69c969b270b4588fc  acceptance/harness/src/bin/b3.rs
8e0684456467bf9f0193d4c951033cab78c889a46b90a63573abf644d86f8ef4  acceptance/harness/src/bin/b4.rs
8e9c73f6072062014481ad04503cfe9a556fd8dc07d25c453a15be589679ae46  acceptance/harness/src/bin/c1.rs
6cfba885f6cc9947cd29bebec9bba34da961b6f841ef8fbd5c713c1ec5241a07  acceptance/harness/src/bin/c2.rs
c22a550698259fa3daeba29f4d1bb5d3187df9c6405cc47177956a022ae1c7be  acceptance/harness/src/bin/share-b1.rs
206cd7df8b6309c6ebc61345de521fe176379611b720c722155cff54dff95930  acceptance/mutants/always-copies/Cargo.toml
740435b5981e03ad50884edfe832e9485ed7b2e366b3e3611934ac97f018cfc8  acceptance/mutants/always-copies/src/lib.rs
72c5a56586071695846484ac2a7bf96b995fcad2dee053e9991506c5974c4322  acceptance/mutants/shared-mutation/Cargo.toml
52ec7f92a1f302558e2300ca4d43f2afe7920ac1ce01287f4dd0b7c088b6b44f  acceptance/mutants/shared-mutation/src/lib.rs
```

## Experiment 3's baselines, reused unchanged (D64)

Paths are relative to this folder.

```
0ca8b3a65f011cadd37ebfc30a109ac41a5e1942037ba97960e755d108872b00  ../03-in-place/bench/rust-same/Cargo.toml
15fe4e98be2656344f72a989441b70d02bb5ab3e85380bc208cbdde80ade106e  ../03-in-place/bench/rust-same/Cargo.lock
dee332e53f9c950d04a15357b989457a5f1be0ccb2819a08ea0bb0ab4e76044d  ../03-in-place/bench/rust-same/build.rs
832b25e5bf7bd101808f885571be420bc883f7a1c24c36b6595a391b62e0583a  ../03-in-place/bench/rust-same/src/lib.rs
f4bef5cdb9aa6597731d65dc0778b8b5cb742e6b938f329fd40017ccb4cc3a05  ../03-in-place/bench/rust-same/src/bin/b1.rs
9bc15a62f94f5f6488eaae8de59f244f566c3afea88cc3f338cfd840061d935e  ../03-in-place/bench/rust-same/src/bin/b2.rs
e32eb0fe6c71a55be6aa8e15037ae8ca3ae0e6368697ecc0bd4264634d94e354  ../03-in-place/bench/rust-same/src/bin/b3.rs
c466c0f49f326d184f31977e1eda24ad5ade2eba4a76eed02573d4f35ad6ce88  ../03-in-place/bench/rust-same/src/bin/b4.rs
5fb563e2dc7d8221740f61376aa58b98038c4c9d30b0e4d71d4663f8abee0d8b  ../03-in-place/bench/koka/b1.kk
29d292cc7b0ae029fd0c3e7fa6742e2e5cc6fcc9d0d855e83c005b528b01b601  ../03-in-place/bench/koka/b2.kk
adf930bf6b9a8469c1d1c9250d4f5e01755f0de8b6f1af84748f20a84cb6c0e9  ../03-in-place/bench/koka/b3.kk
e16a5eddc5118a9837d8308fb5efa03a6cd9e7aa68563205517ed6ef12af1b35  ../03-in-place/bench/koka/b4.kk
```

Re-check with:

```
cd experiments/03b-helper && shasum -a 256 -c <(sed -n '/^[0-9a-f]\{64\}  /p' LOCK.md)
```
