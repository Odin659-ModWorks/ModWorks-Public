param(
    [string]$SourceMod = 'K:\EMULATORS\SWITCH\Eden\user\load\0100AE00096EA000\PlayStation Button Prompts v1.0.0-rc17',
    [string]$ResearchRoot = 'K:\EMULATORS\SWITCH\Eden\user\cache\hwde-mod-research',
    [string]$Output = (Join-Path $PSScriptRoot '..\staging\PlayStation Button Prompts v1.0.0-rc18'),
    [string]$BuildRoot,
    [string]$Version = '1.0.0-rc18',
    [ValidateRange(0.005,0.09)][double]$InnerTipRadius = 0.09,
    [ValidateRange(1.0,1.3)][double]$PaddleWidthScale = 1.0
)

$ErrorActionPreference = 'Stop'
$sourceTextures = Join-Path $ResearchRoot 'button-work\all-menu-dpads-rc17\station_ENG'
if (-not $BuildRoot) { $BuildRoot = Join-Path $ResearchRoot 'button-work\dualsense-dpads-rc18' }
$buildRoot = $BuildRoot
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

# station_ENG 042-048 are the seven menu direction states. The four
# separate tapered paddles follow the user's DualSense photo reference.
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
    if ($right -lt 0 -or $right-$left -lt 20) { throw "Unexpected footprint: $entry" }
    $canvas=[Drawing.Bitmap]::new($old.Width,$old.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $old.Dispose()
    $g=[Drawing.Graphics]::FromImage($canvas)
    $g.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $d=[single][Math]::Min($right-$left+1,$bottom-$top-1)
    $cx=[single](($left+$right)/2); $cy=[single](($top+$bottom-1)/2)
    $key=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,238,238,236))
    $red=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,200,30,42))
    $gray=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,67,62,60))
    $outline=[Drawing.Pen]::new([Drawing.Color]::FromArgb(255,27,22,18),[single]($d*.042))
    $outline.LineJoin=[Drawing.Drawing2D.LineJoin]::Round
    try {
        $keyPath=[Drawing.Drawing2D.GraphicsPath]::new()
        try {
            # Draw the upper paddle, from narrow inward tip to rounded
            # broad outer edge; rotate copies through the other directions.
            $tip=[Drawing.PointF]::new($cx,$cy-$d*$InnerTipRadius)
            $leftSide=[Drawing.PointF]::new($cx-$d*.125*$PaddleWidthScale,$cy-$d*.21)
            $leftOuter=[Drawing.PointF]::new($cx-$d*.145*$PaddleWidthScale,$cy-$d*.39)
            $topLeft=[Drawing.PointF]::new($cx-$d*.09*$PaddleWidthScale,$cy-$d*.455)
            $topRight=[Drawing.PointF]::new($cx+$d*.09*$PaddleWidthScale,$cy-$d*.455)
            $rightOuter=[Drawing.PointF]::new($cx+$d*.145*$PaddleWidthScale,$cy-$d*.39)
            $rightSide=[Drawing.PointF]::new($cx+$d*.125*$PaddleWidthScale,$cy-$d*.21)
            $keyPath.StartFigure()
            $keyPath.AddBezier($tip,[Drawing.PointF]::new($cx-$d*.05*$PaddleWidthScale,$cy-$d*($InnerTipRadius+.04)),[Drawing.PointF]::new($cx-$d*.11*$PaddleWidthScale,$cy-$d*.17),$leftSide)
            $keyPath.AddLine($leftSide,$leftOuter)
            $keyPath.AddBezier($leftOuter,[Drawing.PointF]::new($cx-$d*.145*$PaddleWidthScale,$cy-$d*.435),[Drawing.PointF]::new($cx-$d*.12*$PaddleWidthScale,$cy-$d*.455),$topLeft)
            $keyPath.AddLine($topLeft,$topRight)
            $keyPath.AddBezier($topRight,[Drawing.PointF]::new($cx+$d*.12*$PaddleWidthScale,$cy-$d*.455),[Drawing.PointF]::new($cx+$d*.145*$PaddleWidthScale,$cy-$d*.435),$rightOuter)
            $keyPath.AddLine($rightOuter,$rightSide)
            $keyPath.AddBezier($rightSide,[Drawing.PointF]::new($cx+$d*.11*$PaddleWidthScale,$cy-$d*.17),[Drawing.PointF]::new($cx+$d*.05*$PaddleWidthScale,$cy-$d*($InnerTipRadius+.04)),$tip)
            $keyPath.CloseFigure()
            $arrow=[Drawing.Drawing2D.GraphicsPath]::new()
            try {
                $arrow.AddPolygon([Drawing.PointF[]]@(
                    [Drawing.PointF]::new($cx,$cy-$d*.365),
                    [Drawing.PointF]::new($cx-$d*.062*$PaddleWidthScale,$cy-$d*.275),
                    [Drawing.PointF]::new($cx+$d*.062*$PaddleWidthScale,$cy-$d*.275)
                ))
                foreach ($direction in @('up','right','down','left')) {
                    $matrix=[Drawing.Drawing2D.Matrix]::new()
                    $matrix.RotateAt([single]$angles[$direction],[Drawing.PointF]::new($cx,$cy))
                    $paddle=$keyPath.Clone(); $paddle.Transform($matrix)
                    $mark=$arrow.Clone(); $mark.Transform($matrix)
                    try {
                        $g.FillPath($key,$paddle)
                        $g.DrawPath($outline,$paddle)
                        $markBrush=if ($direction -in $states[$entry]) { $red } else { $gray }
                        $g.FillPath($markBrush,$mark)
                    }
                    finally { $mark.Dispose(); $paddle.Dispose(); $matrix.Dispose() }
                }
            }
            finally { $arrow.Dispose() }
        }
        finally { $keyPath.Dispose() }
    }
    finally { $outline.Dispose(); $gray.Dispose(); $red.Dispose(); $key.Dispose(); $g.Dispose() }
    $canvas.Save($png,[Drawing.Imaging.ImageFormat]::Png)
    $canvas.Dispose()
    & $texconv -f BC3_UNORM -m 1 -y -o $station $png | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "texconv failed: $entry" }
}
& $g1tTool -y $station | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'gust_g1t failed for station_ENG.' }

Copy-Item -LiteralPath $SourceMod -Destination $Output -Recurse
Copy-Item -LiteralPath (Join-Path $buildRoot 'station_ENG.g1t') -Destination (Join-Path $Output 'romfs\data\ui\station_ENG.g1t.gz') -Force
Set-Content -LiteralPath (Join-Path $Output 'VERSION.txt') -Value $Version -NoNewline
Write-Output "Staged $Version DualSense-style menu D-pad states: $Output"
