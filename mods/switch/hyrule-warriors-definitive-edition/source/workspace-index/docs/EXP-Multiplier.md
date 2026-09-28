# EXP Multiplier — development history

**Goal.** Multiply experience gain independently of rupees and materials. Choices: x2, x4, x8, x16, with one rate selected for this category.

**Current result.** The four `v1.0.0` add-ons target Definitive Edition update 1.0.1, build `815A2C19D1767896`. The user reported using x2, x4, and x8 successfully and treated the family as release-ready. x16 was built but not specifically reported as played, so retain that test distinction.

**Implementation record.** Each version patches the same executable offset `0x001FC804` with a factor-specific instruction in `cheats/815A2C19D1767896.txt`. Installed packages are in Eden's `user/load/0100AE00096EA000/`. The original derivation of that instruction is not present in the workspace; before altering it, verify the target against the source executable and measure a known EXP award.

**Issues / outcome.** No EXP-specific defect was reported. This is a separate category from the rupee and material patches by user request; do not combine them into an all-or-nothing multiplier package.
