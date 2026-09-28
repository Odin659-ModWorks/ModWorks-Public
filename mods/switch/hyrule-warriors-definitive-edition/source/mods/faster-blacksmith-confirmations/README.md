# Faster Blacksmith Confirmations — development history

**Goal.** Remove the wait for blacksmith result animations before the next confirmation while preserving the upgrade and its costs.

**Current result.** `v1.0.0`, Definitive Edition update 1.0.1, build `815A2C19D1767896`. The user reported the smithy speed-up working in play. The standalone add-on remains available even though Faster Bazaar bundles it.

**How it was built.** `FUN_710036ee30` handles the blacksmith's top-level result flow. Once the result flag at object `+0x41364` is set, it checks subordinate states and two animation collections. The patch changes only the two animation-completion queries at `0x710036efbc` and `0x710036efcc` to return success (`mov w0, #1`). Subordinate-state checks, the result message, sounds, and inventory updates remain untouched. The exact writes are in `mod/Faster Blacksmith Confirmations v1.0.0`.

**Scope and lessons.** Other Bazaar actions have separate state machines. This patch intentionally did not treat every Bazaar menu as the same wait gate; Apothecary, Badge Market, and Training Dojo were developed independently. Earlier disassembly findings are in `research/NOTES.txt`.
