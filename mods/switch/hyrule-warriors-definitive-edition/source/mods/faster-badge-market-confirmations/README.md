# Faster Badge Market Confirmations — development history

**Goal.** Shorten badge-creation and result animations without skipping the purchase or altering costs.

**Current result.** `v1.0.0`, Definitive Edition update 1.0.1, build `815A2C19D1767896`. The user tested the Badge Market and reported it working. It is available alone and in Faster Bazaar.

**How it was built.** `FUN_71003034b4` identifies the selected tile and calls `FUN_7100301954`, which starts the badge-making and result effects. Five animation-rate instructions were changed from `fmov s0, #1.0` to `fmov s0, #4.0`, reducing those effects to roughly one quarter of their original duration. The animations still play; surrounding state updates are untouched. Exact writes are in `cheats/815A2C19D1767896.txt`, with instruction verification in `research/NOTES.txt`.

**Limits.** No other Bazaar screens are accelerated by this standalone add-on.
