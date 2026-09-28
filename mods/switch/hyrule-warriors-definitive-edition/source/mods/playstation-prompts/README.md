# Hyrule Warriors: Definitive Edition - PlayStation Button Prompts

Replaces Nintendo-style prompts with a cohesive PlayStation prompt family for Hyrule Warriors: Definitive Edition.

## Compatibility

- Title ID: `0100AE00096EA000`
- Game update: `1.0.1`
- Tested emulator target: Eden
- Current artwork baseline: `v1.0.0-rc23` (the version now in Eden for user testing)

## Included prompt families

- Triangle, Circle, Cross, and Square
- Neutral, horizontal, vertical, and individual-direction D-pad prompts
- L1, R1, L2, R2, L3, and R3
- Options and Create
- Combined shoulder-plus-button prompts
- Menu-font glyph replacements and battle-HUD texture replacements

## Installation

Copy the versioned mod folder into:

`Eden\user\load\0100AE00096EA000\`

Enable only one version of the PlayStation Button Prompts add-on at a time. Restart the game after switching versions.

## Release status

`v1.0.0-rc23` is the source of truth for the editable blank-button templates and the visual design of the Age of Calamity port. Keep its shape, scale, outline, face colors, red active directions, gray inactive directions, and menu-glyph alignment. The Age of Calamity game files must be mapped and rebuilt separately; its texture containers are not interchangeable with Definitive Edition's.

## Development and test record

The first passes established the game's separate menu-glyph, battle-HUD, and shoulder-button texture paths. They also exposed mismatched button assignments (including Circle/OK), inconsistent glyph placement, and old Nintendo labels in battle. The art was rebuilt as cohesive PlayStation-styled buttons, not just white symbols painted over the old images. L1/R1/L2/R2 labels were enlarged and aligned; menu icons were shifted toward their associated text; the Triangle and D-pad geometry went through several visual corrections. RC23 uses the user's preferred symmetric, DualSense-like four-piece D-pad, red active arrows, gray inactive directions, and matching icon alignment.

An earlier RC4 package caused battle-load crashes in the user's tests and was retired. Subsequent candidates were tested one at a time; the user reported RC9 working in battle and then selected RC23 as the current baseline. Exact artwork/rebuild instructions for third-party authors remain in `docs/MAKING-BUTTON-PROMPT-MODS.md`; the release-generating scripts and source assets remain in this project. A full game-wide audit of every prompt location has not been claimed.
