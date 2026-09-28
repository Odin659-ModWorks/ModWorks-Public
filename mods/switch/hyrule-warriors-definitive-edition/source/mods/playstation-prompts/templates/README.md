# Blank prompt creator templates

These PNGs are older blank prompt canvases. The current PlayStation artwork baseline is **RC23**, so this folder must be refreshed against RC23 before being presented as the final creator kit. In particular, the D-pad blanks here do not yet encode RC23's symmetric four-piece shape. The RC23 mod package and its source art are the reference, not these older files.

- `option_pad_blank` contains the nine 32 x 32 controller/option textures.
- `station_ENG_blank` contains the confirmed battle-HUD prompt slots at their original canvas sizes.
- `../assets/option-pad-blank-contact.png` and `../assets/station-blank-contact.png` are numbered visual indexes.

Add artwork inside the existing keycap face without resizing or cropping the PNG canvas. Use the same filename when converting the image back to DDS so the original `g1t.json` entry order remains intact.

Do not use `scripts/New-CohesivePromptArt.ps1 -Blank` alone for an RC23 creator kit: that older renderer predates the RC23 D-pad revisions. Regenerate the blanks from RC23 artwork, retaining each canvas, keycap outline, and face while removing only the symbol or directional highlight intended for editing.
