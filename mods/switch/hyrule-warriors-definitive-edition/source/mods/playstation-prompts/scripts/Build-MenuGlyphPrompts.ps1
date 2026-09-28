param(
    [string]$ResearchRoot = 'K:\EMULATORS\SWITCH\Eden\user\cache\hwde-mod-research',
    [string]$BuildTag = 'rc8'
)

$work = Join-Path $ResearchRoot "button-work\ps-glyph-build-$BuildTag"
$fontSource = Join-Path $ResearchRoot 'button-work\fonts'
$romfsSource = Join-Path $ResearchRoot 'romfs-101'
$texconv = Join-Path $ResearchRoot 'texconv.exe'
$g1tTool = Join-Path $ResearchRoot 'gust_tools\gust_g1t.exe'

if (Test-Path -LiteralPath $work) {
    throw "Build folder already exists: $work"
}
New-Item -ItemType Directory -Path $work | Out-Null
Copy-Item -LiteralPath (Join-Path $fontSource 'font_eu') -Destination (Join-Path $work 'font_eu') -Recurse
Copy-Item -LiteralPath (Join-Path $fontSource 'font_eu_p') -Destination (Join-Path $work 'font_eu_p') -Recurse
Copy-Item -LiteralPath (Join-Path $fontSource 'font') -Destination (Join-Path $work 'font') -Recurse
Copy-Item -LiteralPath (Join-Path $fontSource 'font_p') -Destination (Join-Path $work 'font_p') -Recurse

Add-Type -AssemblyName System.Drawing

function Set-PromptGlyphs([string]$imagePath) {
    $source = [Drawing.Bitmap]::new($imagePath)
    $canvas = [Drawing.Bitmap]::new($source.Width, $source.Height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($canvas)
    try {
        $graphics.DrawImageUnscaled($source, 0, 0)
        $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
        $clear = [Drawing.SolidBrush]::new([Drawing.Color]::Transparent)
        $white = [Drawing.Pen]::new([Drawing.Color]::White, 4)
        $white.StartCap = [Drawing.Drawing2D.LineCap]::Round
        $white.EndCap = [Drawing.Drawing2D.LineCap]::Round
        $white.LineJoin = [Drawing.Drawing2D.LineJoin]::Round
        $rim = [Drawing.Pen]::new([Drawing.Color]::White, 3.5)
        try {
            # The English atlas packs glyphs into 48x64 slots. Row 4 starts
            # with ASCII space and fits through lowercase t; row 5 continues
            # at lowercase u. The large atlas is not used by the English menu
            # and must remain untouched.
            if ($source.Height -eq 512) {
                $glyphs = @(
                    # Nintendo A/B occupy the physical right/bottom positions,
                    # corresponding to PlayStation Circle/Cross respectively.
                    @{ Row = 5; Col = 6; Kind = 'circle' },
                    @{ Row = 5; Col = 7; Kind = 'cross' },
                    @{ Row = 5; Col = 8; Kind = 'triangle' },
                    @{ Row = 5; Col = 9; Kind = 'square' },
                    @{ Row = 4; Col = 62; Kind = 'options' },
                    @{ Row = 4; Col = 63; Kind = 'create' }
                )
            }
            elseif ($source.Height -eq 2048) {
                $glyphs = @()
            }
            else { throw "Unexpected font-atlas height: $($source.Height)" }
            foreach ($glyph in $glyphs) {
                $slotX = $glyph.Col * 48
                # The menu renders each 48x64 cell as a prefix for its label.
                # Keep the complete keycap near the cell's right edge, with
                # two pixels of breathing room after the antialiased rim.
                $x = $slotX + 27
                $y = $glyph.Row * 64
                $graphics.FillRectangle($clear, $slotX, $y, 48, 64)
                $graphics.DrawEllipse($rim, $slotX + 10, $y + 15, 34, 34)
                switch ($glyph.Kind) {
                    'cross' {
                        $graphics.DrawLine($white, $x - 8, $y + 24, $x + 8, $y + 40)
                        $graphics.DrawLine($white, $x + 8, $y + 24, $x - 8, $y + 40)
                    }
                    'circle' { $graphics.DrawEllipse($white, $x - 8, $y + 24, 16, 16) }
                    'triangle' {
                        $points = [Drawing.Point[]]@(
                            [Drawing.Point]::new($x, $y + 24),
                            [Drawing.Point]::new($x + 9, $y + 39),
                            [Drawing.Point]::new($x - 9, $y + 39),
                            [Drawing.Point]::new($x, $y + 24)
                        )
                        $graphics.DrawLines($white, $points)
                    }
                    'square' { $graphics.DrawRectangle($white, $x - 8, $y + 24, 16, 16) }
                    'options' {
                        $graphics.DrawLine($white, $x - 8, $y + 26, $x + 8, $y + 26)
                        $graphics.DrawLine($white, $x - 8, $y + 32, $x + 8, $y + 32)
                        $graphics.DrawLine($white, $x - 8, $y + 38, $x + 8, $y + 38)
                    }
                    'create' {
                        # DualSense Create: three separate rays that start
                        # close together below and fan upward.
                        $graphics.DrawLine($white, $x - 2, $y + 39, $x - 9, $y + 24)
                        $graphics.DrawLine($white, $x, $y + 41, $x, $y + 23)
                        $graphics.DrawLine($white, $x + 2, $y + 39, $x + 9, $y + 24)
                    }
                }
            }
        }
        finally {
            $rim.Dispose(); $white.Dispose(); $clear.Dispose()
        }
    }
    finally {
        $graphics.Dispose(); $source.Dispose()
    }
    $temporary = $imagePath + '.new.png'
    $canvas.Save($temporary, [Drawing.Imaging.ImageFormat]::Png)
    $canvas.Dispose()
    Move-Item -LiteralPath $temporary -Destination $imagePath -Force
}

foreach ($fontName in @('font', 'font_p', 'font_eu', 'font_eu_p')) {
    $folder = Join-Path $work $fontName
    $png = Join-Path $folder '000.png'
    $dds = Join-Path $folder '000.dds'
    $originalDds = Join-Path $folder '000.original.dds'
    Copy-Item -LiteralPath $dds -Destination $originalDds -Force
    Set-PromptGlyphs $png
    & $texconv -f BC3_UNORM -m 1 -y -o $folder $png | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "texconv failed for $fontName" }

    # Preserve every original BC3 block except the six 48x64 glyph slots.
    # BC3 stores one 16-byte block per 4x4 pixels; the DDS has a 128-byte header.
    $originalBytes = [IO.File]::ReadAllBytes($originalDds)
    $editedBytes = [IO.File]::ReadAllBytes($dds)
    if ($originalBytes.Length -ne $editedBytes.Length) { throw "DDS size mismatch for $fontName" }
    $blockRowBytes = (4096 / 4) * 16
    $ddsHeight = [BitConverter]::ToInt32($originalBytes, 12)
    if ($ddsHeight -eq 512) {
        $glyphCells = @(
            @{ Row = 5; Col = 6 }, @{ Row = 5; Col = 7 },
            @{ Row = 5; Col = 8 }, @{ Row = 5; Col = 9 },
            @{ Row = 4; Col = 62 }, @{ Row = 4; Col = 63 }
        )
    }
    elseif ($ddsHeight -eq 2048) {
        $glyphCells = @()
    }
    else { throw "Unexpected DDS height: $ddsHeight" }
    foreach ($cell in $glyphCells) {
        $firstBlockX = ($cell.Col * 48) / 4
        $firstBlockY = ($cell.Row * 64) / 4
        for ($blockY = 0; $blockY -lt 16; $blockY++) {
            $offset = 128 + (($firstBlockY + $blockY) * $blockRowBytes) + ($firstBlockX * 16)
            [Array]::Copy($editedBytes, $offset, $originalBytes, $offset, 12 * 16)
        }
    }
    [IO.File]::WriteAllBytes($dds, $originalBytes)
    Remove-Item -LiteralPath $originalDds -Force
    & $g1tTool $folder | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "gust_g1t failed for $fontName" }
}

$outputRoot = Join-Path $ResearchRoot "button-work\ps-glyph-prompts-$BuildTag"
if (Test-Path -LiteralPath $outputRoot) { throw "Output folder already exists: $outputRoot" }
$uiOut = Join-Path $outputRoot 'romfs\data\ui'
$commonOut = Join-Path $outputRoot 'romfs\data\common'
New-Item -ItemType Directory -Force -Path $uiOut, $commonOut | Out-Null
Copy-Item -LiteralPath (Join-Path $work 'font_eu.g1t') -Destination (Join-Path $uiOut 'font_eu.g1t.gz') -Force
Copy-Item -LiteralPath (Join-Path $work 'font_eu_p.g1t') -Destination (Join-Path $uiOut 'font_eu_p.g1t.gz') -Force
Copy-Item -LiteralPath (Join-Path $work 'font.g1t') -Destination (Join-Path $uiOut 'font.g1t.gz') -Force
Copy-Item -LiteralPath (Join-Path $work 'font_p.g1t') -Destination (Join-Path $uiOut 'font_p.g1t.gz') -Force

$messageSource = Join-Path $romfsSource 'data\common\msgdata.bin'
$messageDestination = Join-Path $commonOut 'msgdata.bin'
$bytes = [IO.File]::ReadAllBytes($messageSource)
$mapping = [ordered]@{
    0x30 = 0x7B # P0 A -> custom Cross glyph in {
    0x31 = 0x7C # P1 B -> custom Circle glyph in |
    0x32 = 0x7D # P2 X -> custom Triangle glyph in }
    0x33 = 0x7E # P3 Y -> custom Square glyph in ~
    0x48 = 0x5E # PH Plus -> custom Options glyph in ^
    0x49 = 0x5F # PI Minus -> custom Create glyph in _
}
$counts = [ordered]@{}
foreach ($entry in $mapping.GetEnumerator()) {
    $count = 0
    for ($i = 0; $i -le $bytes.Length - 3; $i++) {
        if ($bytes[$i] -eq 0x1B -and $bytes[$i + 1] -eq 0x50 -and $bytes[$i + 2] -eq $entry.Key) {
            $bytes[$i] = $entry.Value
            $bytes[$i + 1] = 0x20
            $bytes[$i + 2] = 0x20
            $count++
            $i += 2
        }
    }
    $counts["0x$('{0:X2}' -f $entry.Key)"] = $count
}
[IO.File]::WriteAllBytes($messageDestination, $bytes)

$counts.GetEnumerator() | ForEach-Object { '{0}={1}' -f $_.Key, $_.Value }
Get-ChildItem -LiteralPath $outputRoot -Recurse -File | ForEach-Object {
    '{0}`t{1}`t{2}' -f $_.FullName, $_.Length, (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
}
