param(
    [string]$SourceMod = 'K:\EMULATORS\SWITCH\Eden\user\load\0100AE00096EA000\PlayStation Button Prompts v1.0.0-rc21',
    [string]$ResearchRoot = 'K:\EMULATORS\SWITCH\Eden\user\cache\hwde-mod-research',
    [string]$Output = (Join-Path $PSScriptRoot '..\staging\PlayStation Button Prompts v1.0.0-rc22')
)

$ErrorActionPreference = 'Stop'
$sourceTextures = Join-Path $ResearchRoot 'button-work\larger-dpads-rc19\station_ENG'
$buildRoot = Join-Path $ResearchRoot 'button-work\symmetric-dpads-rc22'
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

# RC21 independently rescaled four raster components. Their subtly
# different pixel boxes created uneven center gaps. Render ONE canonical
# vector keycap/arrow and rotate it four times around the shared center.
# The size derives from each RC19 state and is clipped to its exact box.
$states = [ordered]@{
    '042' = @('up','down','left','right')
    '043' = @('down')
    '044' = @('left')
    '045' = @('left','right')
    '046' = @('right')
    '047' = @('up')
    '048' = @('up','down')
}
$angles = @{ up=0; right=90; down=180; left=270 }
foreach ($entry in $states.Keys) {
    $png=Join-Path $station "$entry.png"
    $old=[Drawing.Bitmap]::new($png)
    $left=$old.Width; $top=$old.Height; $right=-1; $bottom=-1
    for ($y=0; $y -lt $old.Height; $y++) {
        for ($x=0; $x -lt $old.Width; $x++) {
            if ($old.GetPixel($x,$y).A -gt 8) {
                $left=[Math]::Min($left,$x); $right=[Math]::Max($right,$x)
                $top=[Math]::Min($top,$y); $bottom=[Math]::Max($bottom,$y)
            }
        }
    }
    if ($right-$left -lt 35 -or $right-$left -ne $bottom-$top) { throw "Unexpected RC19 footprint: $entry" }
    $canvas=[Drawing.Bitmap]::new($old.Width,$old.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $old.Dispose()
    $g=[Drawing.Graphics]::FromImage($canvas)
    $g.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.SetClip([Drawing.Rectangle]::new($left,$top,$right-$left+1,$bottom-$top+1))
    $cx=[single](($left+$right)/2); $cy=[single](($top+$bottom)/2)
    # The outer edge is 0.455d plus half of a 0.042d outline.
    $d=[single](($right-$left)/0.952)
    $white=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,238,238,236))
    $red=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,200,30,42))
    $gray=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,67,62,60))
    $outline=[Drawing.Pen]::new([Drawing.Color]::FromArgb(255,27,22,18),[single]($d*.042))
    $outline.LineJoin=[Drawing.Drawing2D.LineJoin]::Round
    try {
        $key=[Drawing.Drawing2D.GraphicsPath]::new()
        $arrow=[Drawing.Drawing2D.GraphicsPath]::new()
        try {
            # Outer wall matches RC19; the 15%-larger RC21 shape is drawn
            # directly instead of scaling already-compressed pixels.
            $tip=[Drawing.PointF]::new($cx,$cy-$d*.025)
            $shoulderL=[Drawing.PointF]::new($cx-$d*.148,$cy-$d*.18)
            $outerL=[Drawing.PointF]::new($cx-$d*.171,$cy-$d*.39)
            $topL=[Drawing.PointF]::new($cx-$d*.106,$cy-$d*.455)
            $topR=[Drawing.PointF]::new($cx+$d*.106,$cy-$d*.455)
            $outerR=[Drawing.PointF]::new($cx+$d*.171,$cy-$d*.39)
            $shoulderR=[Drawing.PointF]::new($cx+$d*.148,$cy-$d*.18)
            $key.StartFigure()
            $key.AddBezier($tip,[Drawing.PointF]::new($cx-$d*.059,$cy-$d*.07),[Drawing.PointF]::new($cx-$d*.13,$cy-$d*.13),$shoulderL)
            $key.AddLine($shoulderL,$outerL)
            $key.AddBezier($outerL,[Drawing.PointF]::new($cx-$d*.171,$cy-$d*.435),[Drawing.PointF]::new($cx-$d*.142,$cy-$d*.455),$topL)
            $key.AddLine($topL,$topR)
            $key.AddBezier($topR,[Drawing.PointF]::new($cx+$d*.142,$cy-$d*.455),[Drawing.PointF]::new($cx+$d*.171,$cy-$d*.435),$outerR)
            $key.AddLine($outerR,$shoulderR)
            $key.AddBezier($shoulderR,[Drawing.PointF]::new($cx+$d*.13,$cy-$d*.13),[Drawing.PointF]::new($cx+$d*.059,$cy-$d*.07),$tip)
            $key.CloseFigure()
            $arrow.AddPolygon([Drawing.PointF[]]@(
                [Drawing.PointF]::new($cx,$cy-$d*.358),
                [Drawing.PointF]::new($cx-$d*.073,$cy-$d*.252),
                [Drawing.PointF]::new($cx+$d*.073,$cy-$d*.252)
            ))
            $pieces=@{}; $marks=@{}
            try {
                foreach ($direction in @('up','right','down','left')) {
                    $matrix=[Drawing.Drawing2D.Matrix]::new()
                    $matrix.RotateAt([single]$angles[$direction],[Drawing.PointF]::new($cx,$cy))
                    $pieces[$direction]=$key.Clone(); $pieces[$direction].Transform($matrix)
                    $marks[$direction]=$arrow.Clone(); $marks[$direction].Transform($matrix)
                    $matrix.Dispose()
                }
                foreach ($direction in @('up','right','down','left')) { $g.FillPath($white,$pieces[$direction]) }
                foreach ($direction in @('up','right','down','left')) { $g.DrawPath($outline,$pieces[$direction]) }
                foreach ($direction in @('up','right','down','left')) {
                    $markBrush=if ($direction -in $states[$entry]) { $red } else { $gray }
                    $g.FillPath($markBrush,$marks[$direction])
                }
            }
            finally {
                foreach ($piece in $pieces.Values) { $piece.Dispose() }
                foreach ($mark in $marks.Values) { $mark.Dispose() }
            }
        }
        finally { $arrow.Dispose(); $key.Dispose() }
    }
    finally { $outline.Dispose(); $gray.Dispose(); $red.Dispose(); $white.Dispose(); $g.Dispose() }
    $canvas.Save($png+'.new.png',[Drawing.Imaging.ImageFormat]::Png)
    $canvas.Dispose()
    Move-Item -LiteralPath ($png+'.new.png') -Destination $png -Force
    & $texconv -f BC3_UNORM -m 1 -y -o $station $png | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "texconv failed: $entry" }
}
& $g1tTool -y $station | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'gust_g1t failed for station_ENG.' }
Copy-Item -LiteralPath $SourceMod -Destination $Output -Recurse
Copy-Item -LiteralPath (Join-Path $buildRoot 'station_ENG.g1t') -Destination (Join-Path $Output 'romfs\data\ui\station_ENG.g1t.gz') -Force
Set-Content -LiteralPath (Join-Path $Output 'VERSION.txt') -Value '1.0.0-rc22' -NoNewline
Write-Output "Staged RC22 symmetric four-key D-pad: $Output"
