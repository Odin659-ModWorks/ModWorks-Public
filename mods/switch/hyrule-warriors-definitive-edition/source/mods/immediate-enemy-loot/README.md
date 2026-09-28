# Immediate Enemy Loot — development history

**Goal.** Materialize an enemy's loot when it is defeated, instead of waiting for its death animation or for further hits to stop. Keep the normal death animation and cleanup.

**Current result.** `v1.0.0` for Definitive Edition update 1.0.1, build `815A2C19D1767896`, is installed. The user tested it in battles and reported that loot appeared at defeat with no observed issue. That is gameplay feedback, not a proof for every enemy type or boss.

**How it was built.** The death handler `FUN_71001d982c` creates a valid drop record through `FUN_71001d8bf0` near `0x71001d9a90`. The patch branches from `0x71001d9a94` to a helper at `0x71003fa304`, calls the existing materialization routine `FUN_71001d9f54(enemy_index, 0, 1, NULL)`, replays the displaced instructions, and returns at `0x71001d9a9c`. The rest of the death path remains in place. The helper location was checked for analyzed references and pointer occurrences in the source executable before use. The exact hook is in `mod/Immediate Enemy Loot v1.0.0/cheats/815A2C19D1767896.txt`.

**Issues and limits.** The change deliberately affects the timing of a valid drop record, not the drop table, quantity, or rarity. Simultaneous boss deaths and unusual scripted deaths remain worth checking; none has been reported broken. Earlier investigation details are preserved in `research/NOTES.txt`.
