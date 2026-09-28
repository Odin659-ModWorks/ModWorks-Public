# Making Button-Prompt Mods for Hyrule Warriors: Definitive Edition

This document records the working process used to build the PlayStation prompt replacement for the Switch release of *Hyrule Warriors: Definitive Edition*. It is intended to spare other creators the trial-and-error that was required to locate the correct prompt systems, align their glyphs, and rebuild the game's texture containers without corruption.

## Target version

- Title ID: `0100AE00096EA000`
- Game update: `1.0.1`
- ExeFS build ID used by companion cheats: `815A2C19D1767896`
- Tested mod loader layout: Eden layered filesystem

The button mod itself is a RomFS mod. It does not use the build ID, but the game update still matters because archives and message data can change between updates.

## Why one texture swap was not enough

The game renders prompts through three separate systems:

1. `option_pad.g1t.gz` contains the small 32 x 32 option/controller-screen textures.
2. `station_ENG.g1t.gz` contains battle-HUD prompts and many animation/state variants.
3. The ordinary text menus use special prompt codes in `msgdata.bin` that resolve to glyphs stored in the game's font atlases.

A complete prompt mod therefore needs all three. Replacing only `option_pad` changes the controller diagram but leaves text menus and battle prompts untouched. Replacing only the font glyphs changes menu prompts but leaves the HUD's baked textures untouched.

## Final RomFS layout

```text
<mod name>/
  romfs/
    data/
      common/
        msgdata.bin
      ui/
        font.g1t.gz
        font_p.g1t.gz
        font_eu.g1t.gz
        font_eu_p.g1t.gz
        station_ENG.g1t.gz
        option_pad/
          option_pad.g1t.gz
```

Despite the `.gz` suffix, the files used here begin with the raw `GT1G0600` G1T signature. Do not gzip the rebuilt archive. Name the raw G1T output with the game's expected `.g1t.gz` filename.

## `option_pad` texture map

All entries are 32 x 32 pixels.

| Index | Original role | PlayStation replacement |
|---:|---|---|
| `000` | D-pad | Neutral D-pad |
| `001` | L shoulder | L1 |
| `002` | R shoulder | R1 |
| `003` | Nintendo X, top position | Triangle |
| `004` | Nintendo A, right position | Circle |
| `005` | Nintendo B, bottom position | Cross |
| `006` | Nintendo Y, left position | Square |
| `007` | Directional D-pad state | Horizontal D-pad |
| `008` | Directional D-pad state | Vertical D-pad |

Important format rule: convert all nine edited images to BC3/DXT5 before rebuilding the G1T. Feeding BC7/DX10 DDS files to this G1T rebuilding path produced multicolored garbage in indices `003` through `006` even though the source PNGs looked correct.

## `station_ENG` prompt map

Most source canvases are 128 x 128 pixels, but the visible prompt occupies only a smaller alpha-bounded region near the upper-left. Combined prompts `062` through `073` use 256 x 128 canvases. Preserve the original canvas dimensions and draw inside the original nontransparent bounds.

| Indices | Replacement |
|---|---|
| `002`-`006`, `037` | Circle animation/state variants |
| `007`-`011`, `038` | Cross animation/state variants |
| `034`, `081` | R2 |
| `042` | Neutral D-pad |
| `043` | Down |
| `044` | Left |
| `045` | Left and right |
| `046` | Right |
| `047` | Up |
| `048` | Up and down |
| `050`, `051` | L1 variants |
| `052` | L3 |
| `053` | L3 press |
| `054`, `055` | R1 variants |
| `057` | R3 |
| `058` | R3 press |
| `059` | Create |
| `060` | L1, converted from SL |
| `061` | R1, converted from SR |
| `062`-`073` | Combined shoulder-plus-face/D-pad/stick/Options/Create prompts |
| `074` | Options |
| `076` | Triangle |
| `077` | Square |
| `078` | R2, converted from Z |
| `079`, `080` | L2 variants |

The original asset family includes legacy and unused controller art as well. Do not assume that every image containing a letter is active on Switch. Confirm a texture in-game or through a numbered diagnostic before assigning it a new meaning.

## Menu-font glyph system

The English prompt atlas is 4096 pixels wide and 512 pixels high. Glyph cells are 48 x 64 pixels. The 2048-pixel-high atlas encountered alongside it was not the atlas used by the tested English menus and was deliberately left unchanged.

Working custom cells:

| Atlas row | Column | Replacement |
|---:|---:|---|
| `5` | `6` | Circle |
| `5` | `7` | Cross |
| `5` | `8` | Triangle |
| `5` | `9` | Square |
| `4` | `62` | Options |
| `4` | `63` | Create |

The rendered prompt sits in a 48 x 64 slot. A horizontal drawing offset of `+6` pixels gave the best optical grouping with the menu label on its right. A centered symbol can look too close to the previous label because these glyphs act as prefixes.

The working message remap replaces three-byte prompt escape sequences with otherwise unused single-byte glyph characters:

| Original escape ID | Meaning | Replacement byte | Custom glyph |
|---:|---|---:|---|
| `0x30` | P0 / Nintendo A position | `0x7B` (`{`) | Cross |
| `0x31` | P1 / Nintendo B position | `0x7C` (`|`) | Circle |
| `0x32` | P2 / Nintendo X position | `0x7D` (`}`) | Triangle |
| `0x33` | P3 / Nintendo Y position | `0x7E` (`~`) | Square |
| `0x48` | Plus | `0x5E` (`^`) | Options |
| `0x49` | Minus | `0x5F` (`_`) | Create |

Each source sequence is `1B 50 <ID>`. In the working build it becomes `<replacement> 20 20`, keeping the byte count unchanged. This avoids shifting offsets inside `msgdata.bin`.

## Artwork rules that survived testing

- Rebuild the whole keycap face. Painting an opaque white patch over the Nintendo letter is obvious in-game and produces inconsistent shading.
- Preserve exact canvas dimensions and the original alpha-bounded placement. The battle archive expects many images to live in the upper-left of a larger canvas.
- Use consistent lighting: bright top, pale-gray lower face, medium-gray inner rim, charcoal outer rim, and a restrained lower shadow.
- Keep symbols centered inside the face rather than the full canvas.
- At 24-32 pixel display size, use simple geometry and rounded line caps. Fine detail disappears after BC3 compression.
- Use `L1`, `R1`, `L2`, `R2`, `L3`, and `R3`; silhouette-only distinctions are less immediately readable.
- Provide neutral, horizontal, vertical, and individual-direction D-pad variants. The game does not use one universal D-pad image for every instruction.

## Rebuilding the G1T archives

The repository script `scripts/New-CohesivePromptArt.ps1` regenerates the documented keycaps from an extracted source directory. Use the original extracted archive directory because its `g1t.json` preserves archive metadata and entry order.

Example artwork build:

```powershell
.\scripts\New-CohesivePromptArt.ps1 -TextureDir <option_pad_folder> -Set OptionPad
.\scripts\New-CohesivePromptArt.ps1 -TextureDir <station_ENG_folder> -Set Station
```

Convert edited PNGs to one-mip BC3 DDS files with DirectXTex `texconv`, then rebuild with `gust_g1t`:

```powershell
texconv.exe -f BC3_UNORM -m 1 -y -o <folder> <edited.png>
gust_g1t.exe -y <folder>
```

The archive is written beside the folder. Copy it to the exact RomFS path and add the `.g1t.gz` filename expected by the game.

## Verification procedure

1. Re-extract the newly rebuilt G1T under a different name.
2. Convert the extracted DDS files back to PNG.
3. Generate a numbered contact sheet and inspect every changed index.
4. Check for rainbow/noise corruption, missing alpha, shifted canvases, clipped symbols, and mismatched animation variants.
5. Install as a new versioned add-on folder rather than overwriting the currently working version.
6. In Eden, enable only one prompt version, restart the game, and test both a text menu and an active battle.

This round-trip verification caught a format failure that was invisible in the pre-pack PNGs.

## Diagnostic method for unknown prompt slots

When a prompt's source is unknown, replace candidate slots with unmistakable numbered or striped markers, rebuild the archive, and observe which marker appears in-game. Change one container or one small candidate group at a time. Once the live slot is identified, restore the untouched candidates and replace only the confirmed texture.

## Creator templates

The `templates` directory contains blank, centered PNG keycaps for the confirmed option-pad and station prompt slots. The files keep the game's original canvas sizes, so creators can add symbols without rediscovering placement and scale. The contact sheets in `assets` provide a quick visual index.

