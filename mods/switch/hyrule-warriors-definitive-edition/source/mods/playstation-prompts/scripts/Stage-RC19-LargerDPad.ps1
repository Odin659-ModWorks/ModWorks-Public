param(
    [string]$SourceMod = 'K:\EMULATORS\SWITCH\Eden\user\load\0100AE00096EA000\PlayStation Button Prompts v1.0.0-rc18',
    [string]$ResearchRoot = 'K:\EMULATORS\SWITCH\Eden\user\cache\hwde-mod-research',
    [string]$Output = (Join-Path $PSScriptRoot '..\staging\PlayStation Button Prompts v1.0.0-rc19')
)

$ErrorActionPreference = 'Stop'
$sourceTextures = Join-Path $ResearchRoot 'button-work\dualsense-dpads-rc18\station_ENG'
$buildRoot = Join-Path $ResearchRoot 'button-work\larger-dpads-rc19'
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

# The seven D-pad sprites are smaller than adjacent round menu sprites.
# Enlarge around each sprite's own center, preserving its placement.
$scale=[single]1.18
foreach ($entry in 42..48) {
    $png=Join-Path $station ('{0:D3}.png' -f $entry)
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
    if ($right-$left -lt 20) { throw "Unexpected footprint: $entry" }
    $width=[single]($right-$left+1); $height=[single]($bottom-$top+1)
    $cx=[single](($left+$right)/2); $cy=[single](($top+$bottom)/2)
    $destination=[Drawing.RectangleF]::new($cx-$width*$scale/2,$cy-$height*$scale/2,$width*$scale,$height*$scale)
    if ($destination.X -lt 2 -or $destination.Y -lt 2 -or $destination.Right -gt 62 -or $destination.Bottom -gt 62) {
        throw "Scaled sprite could exceed first 64x64 cell: $entry"
    }
    $canvas=[Drawing.Bitmap]::new($old.Width,$old.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g=[Drawing.Graphics]::FromImage($canvas)
    $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceCopy
    try {
        $g.DrawImage($old,$destination,[Drawing.RectangleF]::new($left,$top,$width,$height),[Drawing.GraphicsUnit]::Pixel)
    }
    finally { $g.Dispose(); $old.Dispose() }
    $canvas.Save($png,[Drawing.Imaging.ImageFormat]::Png)
    $canvas.Dispose()
    & $texconv -f BC3_UNORM -m 1 -y -o $station $png | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "texconv failed: $entry" }
}
& $g1tTool -y $station | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'gust_g1t failed for station_ENG.' }
Copy-Item -LiteralPath $SourceMod -Destination $Output -Recurse
Copy-Item -LiteralPath (Join-Path $buildRoot 'station_ENG.g1t') -Destination (Join-Path $Output 'romfs\data\ui\station_ENG.g1t.gz') -Force
Set-Content -LiteralPath (Join-Path $Output 'VERSION.txt') -Value '1.0.0-rc19' -NoNewline
Write-Output "Staged RC19 larger D-pad states: $Output"
