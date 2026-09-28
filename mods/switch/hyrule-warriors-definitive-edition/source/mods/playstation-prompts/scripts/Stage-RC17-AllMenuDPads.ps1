param(
    [string]$SourceMod = 'K:\EMULATORS\SWITCH\Eden\user\load\0100AE00096EA000\PlayStation Button Prompts v1.0.0-rc16',
    [string]$ResearchRoot = 'K:\EMULATORS\SWITCH\Eden\user\cache\hwde-mod-research',
    [string]$Output = (Join-Path $PSScriptRoot '..\staging\PlayStation Button Prompts v1.0.0-rc17')
)

$ErrorActionPreference = 'Stop'
$sourceTextures = Join-Path $ResearchRoot 'button-work\inset-dpad-arrows-rc16\station_ENG'
$buildRoot = Join-Path $ResearchRoot 'button-work\all-menu-dpads-rc17'
$station = Join-Path $buildRoot 'station_ENG'
$texconv = Join-Path $ResearchRoot 'texconv.exe'
$g1tTool = Join-Path $ResearchRoot 'gust_tools\gust_g1t.exe'
foreach ($path in @($SourceMod,$sourceTextures,$texconv,$g1tTool)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing source: $path" }
}
if (Test-Path -LiteralPath $Output) { throw "Candidate already exists: $Output" }
if (Test-Path -LiteralPath $buildRoot) { throw "Build already exists: $buildRoot" }
New-Item -ItemType Directory -Path $buildRoot | Out-Null
Copy-Item -LiteralPath $sourceTextures -Destination $station -Recurse
Add-Type -AssemblyName System.Drawing

# All seven station menu D-pad states share one geometry. 042 is the
# four-direction Select prompt; 043-048 are directional variants.
$states = [ordered]@{
    '042' = @('up','down','left','right')
    '043' = @('down')
    '044' = @('left')
    '045' = @('left','right')
    '046' = @('right')
    '047' = @('up')
    '048' = @('up','down')
}
foreach ($entry in $states.Keys) {
    $png = Join-Path $station "$entry.png"
    $old = [Drawing.Bitmap]::new($png)
    $left=$old.Width; $top=$old.Height; $right=-1; $bottom=-1
    for ($y=0; $y -lt $old.Height; $y++) {
        for ($x=0; $x -lt $old.Width; $x++) {
            if ($old.GetPixel($x,$y).A -gt 8) {
                $left=[Math]::Min($left,$x); $right=[Math]::Max($right,$x)
                $top=[Math]::Min($top,$y); $bottom=[Math]::Max($bottom,$y)
            }
        }
    }
    if ($right -lt 0 -or $right-$left -lt 20) { throw "Unexpected footprint: $entry" }
    $canvas=[Drawing.Bitmap]::new($old.Width,$old.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $old.Dispose()
    $g=[Drawing.Graphics]::FromImage($canvas)
    $g.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $d=[single][Math]::Min($right-$left+1,$bottom-$top-1)
    $cx=[single](($left+$right)/2); $cy=[single](($top+$bottom-1)/2)
    $outer=[Drawing.RectangleF]::new($cx-$d/2,$cy-$d/2,$d,$d)
    $dark=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,27,22,18))
    $white=[Drawing.SolidBrush]::new([Drawing.Color]::White)
    $red=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,196,35,45))
    $ring=[Drawing.Pen]::new([Drawing.Color]::White,[single]($d*.08))
    try {
        $g.FillEllipse($dark,$outer)
        # 0.08d of dark exterior before the ring, matching the face prompts.
        $ringRect=[Drawing.RectangleF]::new($outer.X+$d*.12,$outer.Y+$d*.12,$d*.76,$d*.76)
        $g.DrawEllipse($ring,$ringRect)
        $reach=[single]($d*.39); $half=[single]($d*.105)
        $g.FillRectangle($white,$cx-$half,$cy-$reach,2*$half,2*$reach)
        $g.FillRectangle($white,$cx-$reach,$cy-$half,2*$reach,2*$half)
        # The arrow tip meets the ring's inner edge at about 0.34d.
        $tip=[single]($d*.345); $base=[single]($d*.205); $width=[single]($d*.125)
        $marks=@{
            up=[Drawing.PointF[]]@([Drawing.PointF]::new($cx,$cy-$tip),[Drawing.PointF]::new($cx-$width*.8,$cy-$base),[Drawing.PointF]::new($cx+$width*.8,$cy-$base))
            down=[Drawing.PointF[]]@([Drawing.PointF]::new($cx,$cy+$tip),[Drawing.PointF]::new($cx-$width*.8,$cy+$base),[Drawing.PointF]::new($cx+$width*.8,$cy+$base))
            left=[Drawing.PointF[]]@([Drawing.PointF]::new($cx-$tip,$cy),[Drawing.PointF]::new($cx-$base,$cy-$width*.8),[Drawing.PointF]::new($cx-$base,$cy+$width*.8))
            right=[Drawing.PointF[]]@([Drawing.PointF]::new($cx+$tip,$cy),[Drawing.PointF]::new($cx+$base,$cy-$width*.8),[Drawing.PointF]::new($cx+$base,$cy+$width*.8))
        }
        foreach ($direction in $states[$entry]) { $g.FillPolygon($red,$marks[$direction]) }
    }
    finally { $ring.Dispose(); $red.Dispose(); $white.Dispose(); $dark.Dispose(); $g.Dispose() }
    $canvas.Save($png,[Drawing.Imaging.ImageFormat]::Png)
    $canvas.Dispose()
    & $texconv -f BC3_UNORM -m 1 -y -o $station $png | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "texconv failed: $entry" }
}
& $g1tTool -y $station | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'gust_g1t failed for station_ENG.' }

Copy-Item -LiteralPath $SourceMod -Destination $Output -Recurse
Copy-Item -LiteralPath (Join-Path $buildRoot 'station_ENG.g1t') -Destination (Join-Path $Output 'romfs\data\ui\station_ENG.g1t.gz') -Force
Set-Content -LiteralPath (Join-Path $Output 'VERSION.txt') -Value '1.0.0-rc17' -NoNewline
Write-Output "Staged RC17 all menu D-pad states: $Output"
