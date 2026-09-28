# Xenoblade Chronicles 2 mods for game 2.1.0

These releases target title `0100E95004038000`, game version 2.1.0, and
executable build `F77F1559371C0EC6D50E78774AC59D95`.

The folders under `eden/individual/` are install-shaped Eden/Ryujinx-style
mods. Copy a selected folder beneath the emulator's load directory for the
XC2 base title or use a compatible mod manager. Close the emulator before
installing or replacing files.

## Included gameplay-confirmed choices

- EXP, SP, and WP gains: 2×, 4×, 8×, and 16×.
- Gold gains: 2×, 4×, 8×, and 16×.
- Monster item drop chance: 2×, 4×, 8×, and 16×.
- Monster accessory quality floor: Minimum Rare or Minimum Legendary.
- Base pickup range: +200 cm or +500 cm.
- Automatic Salvage Perfect.
- Shop buy/sell quantity starts at one.
- Four-frame full-screen menu fade.
- PlayStation prompts v1.0.0, finalized from the gameplay-approved RC4.
- Lite Effects v0.2.0.

Select only one option from each multiplier/floor/range family. Options in the
same family patch the same addresses and are alternatives, not stackable mods.

## Lite Effects v0.2.0

Lite Effects changes exactly eight switches in the game's `lib_nx.ini`:

- screen-space reflections (`ssr`)
- temporal screen-space ambient occlusion (`tssao`)
- god rays (`godray`)
- cloud shadows (`shadowCloud`)
- the second blur pass (`blur2`)
- bloom (`bloom`)
- game-side anti-aliasing (`AntiAliasing`)
- game-side temporal anti-aliasing (`tmaa`)

It does not change scene/output resolution, dynamic-resolution settings,
Eden's emulator-side anti-aliasing, half-resolution shadows, or the game's
already-disabled depth of field, lens flare, and original SSAO settings.

## Not included

Shared-BDAT experiments, save tools, the mod manager, the Blade reroller,
Pyra's game-derived model package, stack-cap combinations, Field Skill
composition, quest-banner diagnostics, Blade roster capacity, and the 900p /
1080p scene-resolution experiments remain private or in development. They are
not silently bundled into these individual releases.
