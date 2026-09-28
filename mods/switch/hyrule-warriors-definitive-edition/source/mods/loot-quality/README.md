# HWDE Loot Quality

Standalone, mutually exclusive loot-quality variants for Hyrule Warriors: Definitive Edition 1.0.1.

- **Min 3 Stars, 6 Slots v1.5.0-rc1** is a new test candidate. It starts the weighted star roll at tier 3, retaining possible 4- and 5-star results. It floors the base slot count at 6, before the original bonuses and eight-slot cap. Fixed scenario rewards are not raised by this candidate.
- **Min 4 Stars, 7 Slots v1.5.1** is the tested v1.5.0 patch under a shorter, descriptive name. It floors stars at 4 while keeping 5 possible, and floors generated skill-slot capacity at 7 while keeping 8 possible.
- **Min 5 Stars, 8 Slots v1.1.0** forces those values for generated weapons. They are also the game's maximum values. It keeps Perfect's two quality writes and removes its old weapon-group selection tweak. This revised build is pending an in-game test.

Excellent Floors v1.5.0 does not cap natural rolls at its floors. Its slot floor governs the number of slot entries created; it does not require every slot to arrive with a skill. It uses only inline changes to existing instructions; no game function is overwritten as helper space.

Versions 1.3 and 1.4 used a live game function as helper space and caused battle-start failures. They have been retired from Eden. The v1.5 inline star floor also covers fixed scenario rewards while retaining their predefined weapon identity/rank and curated skill layout. The old rank-bias instructions were not restored: they act on eligible weapon-group selection and can generate an out-of-range index.

Only enable one Loot Quality variant at a time. These cheats target update 1.0.1 and build ID `815A2C19D1767896`.

## Development and test record

The user's requested behavior was to raise the *floor* for star rating and available skill-slot capacity while retaining the natural ceiling and the ability to roll higher values. Filling every slot with a skill was explicitly lower priority. Earlier builds mixed this with a weapon-group/rank bias; the rank change could select outside an eligible group and was dropped. Versions 1.3/1.4 placed a helper in code that was not truly free, producing battle-start hangs or crashes. The later inline approach avoids using a live function as helper space.

The user completed a battle with the three-star/six-slot test and reported it working. Earlier four-star/seven-slot and Perfect-style versions were also used successfully, but the current five-star/eight-slot revision in this README should not inherit a gameplay-tested label merely from its predecessor. For future work, compare the *exact version* on a completed battle, including fixed scenario rewards, normal random rewards, star range, slot count, and whether the weapon identity stays appropriate. Keep any disagreement between normal and fixed rewards explicit rather than folding it into one success claim.
