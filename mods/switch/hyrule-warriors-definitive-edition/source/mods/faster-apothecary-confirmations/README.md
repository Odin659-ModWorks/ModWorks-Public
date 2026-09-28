# Faster Apothecary Confirmations — development history

**Goal.** Let the next Apothecary input proceed sooner after creating a mixture while preserving the mixture, costs, and menu state.

**Current result.** `v1.0.0`, Definitive Edition update 1.0.1, build `815A2C19D1767896`. The user tested the Apothecary speed-up and reported it working. It is available alone and in Faster Bazaar.

**How it was built.** `FUN_7100368424` applies the mixture and starts its result effect. The duration supplied at `0x7100368630` was reduced from 60 to five frames. `FUN_7100368758` then waits for the result layout at `0x71003688ec`; that completion query is changed to report success. The patch leaves purchase, inventory, sound, and message logic in place. Assembly was checked against the original instructions before packaging. Exact writes are in `cheats/815A2C19D1767896.txt`.

**Limits.** This is a targeted post-mixture delay, not a global UI speed multiplier. The original technical notes remain in `research/NOTES.txt`.
