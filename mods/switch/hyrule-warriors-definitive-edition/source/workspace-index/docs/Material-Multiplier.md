# Material Multiplier — development history

**Goal.** Multiply material rewards independently of rupees and EXP. Choices: x2, x4, x8, x16, with one rate selected for this category.

**Current result.** Four `v1.0.0` packages target Definitive Edition update 1.0.1, build `815A2C19D1767896`. The user reported x2, x8, and especially x16 working across play; x4 uses the same patch site but was not separately reported as tested. The user considered the multiplier family release-ready.

**Implementation record.** Each factor writes a different instruction at executable offset `0x00034220` in `cheats/815A2C19D1767896.txt`. Installed packages are under Eden's `user/load/0100AE00096EA000/`. The original derivation is not preserved in the existing workspace. If a later game build changes, re-identify the material-award path; do not transplant this address by number.

**Issues / outcome.** No material-specific failure was reported. A 16x variant was added because some crafting recipes consume substantial quantities. Future checks should compare a known drop before and after, including any inventory cap behavior.
