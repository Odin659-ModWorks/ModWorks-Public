param(
    [string]$SourceMod = 'K:\EMULATORS\SWITCH\Eden\user\load\0100AE00096EA000\PlayStation Button Prompts v1.0.0-rc14',
    [string]$ResearchRoot = 'K:\EMULATORS\SWITCH\Eden\user\cache\hwde-mod-research',
    [string]$Output = (Join-Path $PSScriptRoot '..\staging\PlayStation Button Prompts v1.0.0-rc15')
)

$ErrorActionPreference = 'Stop'
$stationSource = Join-Path $ResearchRoot 'button-work\cohesive-v1.0.0-build-rc14\station_ENG'
$fontSource = Join-Path $ResearchRoot 'button-work\ps-glyph-build-rc10'
$buildRoot = Join-Path $ResearchRoot 'button-work\matching-menu-icons-rc15'
$texconv = Join-Path $ResearchRoot 'texconv.exe'
$g1tTool = Join-Path $ResearchRoot 'gust_tools\gust_g1t.exe'
foreach ($path in @($SourceMod,$stationSource,$fontSource,$texconv,$g1tTool)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing required source: $path" }
}
if (Test-Path -LiteralPath $Output) { throw "Candidate already exists: $Output" }
if (Test-Path -LiteralPath $buildRoot) { throw "Build already exists: $buildRoot" }

New-Item -ItemType Directory -Path $buildRoot | Out-Null
$station = Join-Path $buildRoot 'station_ENG'
Copy-Item -LiteralPath $stationSource -Destination $station -Recurse
Add-Type -AssemblyName System.Drawing

# Main-menu Select is station_ENG entry 042, not one of the font cells used
# by the adjacent face buttons. Render it white-on-charcoal to match those
# cells, with a large white pad crossing into the white inner ring.
$padPath = Join-Path $station '042.png'
$oldPad = [Drawing.Bitmap]::new($padPath)
$left=$oldPad.Width; $top=$oldPad.Height; $right=-1; $bottom=-1
for ($y=0;$y -lt $oldPad.Height;$y++) {
    for ($x=0;$x -lt $oldPad.Width;$x++) {
        if ($oldPad.GetPixel($x,$y).A -gt 8) {
            $left=[Math]::Min($left,$x); $right=[Math]::Max($right,$x)
            $top=[Math]::Min($top,$y); $bottom=[Math]::Max($bottom,$y)
        }
    }
}
if ($right -lt 0 -or $right-$left -lt 20) { throw 'Unexpected Select icon footprint.' }
$canvas=[Drawing.Bitmap]::new($oldPad.Width,$oldPad.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
$oldPad.Dispose()
$g=[Drawing.Graphics]::FromImage($canvas)
$g.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$d=[single][Math]::Min($right-$left+1,$bottom-$top-1)
$cx=[single](($left+$right)/2); $cy=[single](($top+$bottom-1)/2)
$outer=[Drawing.RectangleF]::new($cx-$d/2,$cy-$d/2,$d,$d)
$dark=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,27,22,18))
$white=[Drawing.SolidBrush]::new([Drawing.Color]::White)
$red=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,196,35,45))
$ring=[Drawing.Pen]::new([Drawing.Color]::White,[single]($d*.092))
try {
    $g.FillEllipse($dark,$outer)
    $ringRect=[Drawing.RectangleF]::new($outer.X+$d*.09,$outer.Y+$d*.09,$d*.82,$d*.82)
    $g.DrawEllipse($ring,$ringRect)
    $reach=[single]($d*.405)
    $half=[single]($d*.087)
    $g.FillRectangle($white,$cx-$half,$cy-$reach,2*$half,2*$reach)
    $g.FillRectangle($white,$cx-$reach,$cy-$half,2*$reach,2*$half)
    # Small red tips sit on top of the four white directional arms.
    $t=[single]($d*.09)
    $marks=@(
        [Drawing.PointF[]]@([Drawing.PointF]::new($cx,$cy-$reach),[Drawing.PointF]::new($cx-$t*.75,$cy-$reach+$t*1.2),[Drawing.PointF]::new($cx+$t*.75,$cy-$reach+$t*1.2)),
        [Drawing.PointF[]]@([Drawing.PointF]::new($cx,$cy+$reach),[Drawing.PointF]::new($cx-$t*.75,$cy+$reach-$t*1.2),[Drawing.PointF]::new($cx+$t*.75,$cy+$reach-$t*1.2)),
        [Drawing.PointF[]]@([Drawing.PointF]::new($cx-$reach,$cy),[Drawing.PointF]::new($cx-$reach+$t*1.2,$cy-$t*.75),[Drawing.PointF]::new($cx-$reach+$t*1.2,$cy+$t*.75)),
        [Drawing.PointF[]]@([Drawing.PointF]::new($cx+$reach,$cy),[Drawing.PointF]::new($cx+$reach-$t*1.2,$cy-$t*.75),[Drawing.PointF]::new($cx+$reach-$t*1.2,$cy+$t*.75))
    )
    foreach ($points in $marks) { $g.FillPolygon($red,$points) }
}
finally { $ring.Dispose(); $red.Dispose(); $white.Dispose(); $dark.Dispose(); $g.Dispose() }
$canvas.Save($padPath,[Drawing.Imaging.ImageFormat]::Png)
$canvas.Dispose()
& $texconv -f BC3_UNORM -m 1 -y -o $station $padPath | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'texconv failed for Select icon.' }
& $g1tTool -y $station | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'gust_g1t failed for station_ENG.' }

# The in-menu Triangle is a glyph at row 5, column 8 of the 4096x512
# English font atlas. Its old top/base Y coordinates were 24/39 inside
# the 64px cell. 22/37 puts all three corners approximately equally far
# from the ring center at Y=32. Preserve every other BC3 block verbatim.
foreach ($fontName in @('font_eu','font_eu_p')) {
    $fontDir=Join-Path $buildRoot $fontName
    Copy-Item -LiteralPath (Join-Path $fontSource $fontName) -Destination $fontDir -Recurse
    $png=Join-Path $fontDir '000.png'
    $dds=Join-Path $fontDir '000.dds'
    $bitmap=[Drawing.Bitmap]::new($png)
    if ($bitmap.Width -ne 4096 -or $bitmap.Height -ne 512) { throw "Unexpected $fontName atlas dimensions." }
    $g=[Drawing.Graphics]::FromImage($bitmap)
    $g.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceCopy
    $cellX=8*48; $cellY=5*64; $iconX=$cellX+27
    $clear=[Drawing.SolidBrush]::new([Drawing.Color]::Transparent)
    $rim=[Drawing.Pen]::new([Drawing.Color]::White,[single]3.5)
    $ink=[Drawing.Pen]::new([Drawing.Color]::White,[single]4)
    $ink.StartCap=[Drawing.Drawing2D.LineCap]::Round
    $ink.EndCap=[Drawing.Drawing2D.LineCap]::Round
    $ink.LineJoin=[Drawing.Drawing2D.LineJoin]::Round
    try {
        $g.FillRectangle($clear,$cellX,$cellY,48,64)
        $g.DrawEllipse($rim,$cellX+10,$cellY+15,34,34)
        $points=[Drawing.Point[]]@(
            [Drawing.Point]::new($iconX,$cellY+22),
            [Drawing.Point]::new($iconX+9,$cellY+37),
            [Drawing.Point]::new($iconX-9,$cellY+37),
            [Drawing.Point]::new($iconX,$cellY+22)
        )
        $g.DrawLines($ink,$points)
    }
    finally { $ink.Dispose(); $rim.Dispose(); $clear.Dispose(); $g.Dispose() }
    $bitmap.Save($png+'.new.png',[Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
    Move-Item -LiteralPath ($png+'.new.png') -Destination $png -Force

    $original=[IO.File]::ReadAllBytes($dds)
    & $texconv -f BC3_UNORM -m 1 -y -o $fontDir $png | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "texconv failed for $fontName Triangle glyph." }
    $edited=[IO.File]::ReadAllBytes($dds)
    if ($original.Length -ne $edited.Length) { throw "DDS length changed for $fontName." }
    $rowBytes=(4096/4)*16
    $firstX=(8*48)/4; $firstY=(5*64)/4
    for ($blockY=0;$blockY -lt 16;$blockY++) {
        $offset=128+(($firstY+$blockY)*$rowBytes)+($firstX*16)
        [Array]::Copy($edited,$offset,$original,$offset,12*16)
    }
    [IO.File]::WriteAllBytes($dds,$original)
    & $g1tTool -y $fontDir | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "gust_g1t failed for $fontName." }
}

Copy-Item -LiteralPath $SourceMod -Destination $Output -Recurse
$ui=Join-Path $Output 'romfs\data\ui'
Copy-Item -LiteralPath (Join-Path $buildRoot 'station_ENG.g1t') -Destination (Join-Path $ui 'station_ENG.g1t.gz') -Force
foreach ($fontName in @('font_eu','font_eu_p')) {
    Copy-Item -LiteralPath (Join-Path $buildRoot "$fontName.g1t") -Destination (Join-Path $ui "$fontName.g1t.gz") -Force
}
Set-Content -LiteralPath (Join-Path $Output 'VERSION.txt') -Value '1.0.0-rc15' -NoNewline
Write-Output "Staged RC15 matching Select and centered Triangle: $Output"
