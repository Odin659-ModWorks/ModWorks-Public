# Rupee Multiplier — development history

**Goal.** Multiply rupees earned in Definitive Edition without also multiplying EXP or materials. Available independent choices are x2, x4, x8, and x16, each labeled `(Only One Rupee)` in Eden.

**Current result.** All four `v1.0.0` folders are installed for update 1.0.1, build `815A2C19D1767896`. The user personally tried x2 and x8 and considered the family release-ready; x4 and x16 share the same two patch locations but were not separately confirmed in the reported runs. Do not upgrade that inference into a test claim.

**Implementation record.** Each version changes the two executable cheat offsets `0x001A10F4` and `0x001A1108` in its `cheats/815A2C19D1767896.txt`. The version folders are presently under Eden's `user/load/0100AE00096EA000/`. The wider reverse-engineering trail for these two locations was not preserved in the existing workspace; future changes should begin by verifying the original instructions against the 1.0.1 executable, not by assuming these offsets are portable.

**Issues / outcome.** No rupee-specific failure was reported. The per-category split was made because users may want different rates for rupees, EXP, and materials. Keep new tests versioned and record a concrete before/after reward amount here.
