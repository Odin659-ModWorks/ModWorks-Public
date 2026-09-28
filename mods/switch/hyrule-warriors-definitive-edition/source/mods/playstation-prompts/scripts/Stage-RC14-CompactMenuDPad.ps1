param(
    [string]$SourceMod = 'K:\EMULATORS\SWITCH\Eden\user\load\0100AE00096EA000\PlayStation Button Prompts v1.0.0-rc13',
    [string]$ResearchRoot = 'K:\EMULATORS\SWITCH\Eden\user\cache\hwde-mod-research',
    [string]$Output = (Join-Path $PSScriptRoot '..\staging\PlayStation Button Prompts v1.0.0-rc14')
)

$ErrorActionPreference = 'Stop'
$sourceTextures = Join-Path $ResearchRoot 'button-work\cohesive-v1.0.0-build-rc13\station_ENG'
$buildRoot = Join-Path $ResearchRoot 'button-work\cohesive-v1.0.0-build-rc14'
$textureDir = Join-Path $buildRoot 'station_ENG'
$texconv = Join-Path $ResearchRoot 'texconv.exe'
$g1tTool = Join-Path $ResearchRoot 'gust_tools\gust_g1t.exe'
foreach ($path in @($SourceMod,$sourceTextures,$texconv,$g1tTool)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing required source: $path" }
}
if (Test-Path -LiteralPath $Output) { throw "Candidate already exists: $Output" }
if (Test-Path -LiteralPath $buildRoot) { throw "Build already exists: $buildRoot" }

New-Item -ItemType Directory -Path $buildRoot | Out-Null
Copy-Item -LiteralPath $sourceTextures -Destination $textureDir -Recurse
Add-Type -AssemblyName System.Drawing

# Draw only station_ENG entry 042. The keycap uses the same size, colors,
# gradient and proportions as the other round menu buttons. The D-pad is
# deliberately a compact glyph within that keycap, not an edge-to-edge pad.
$imagePath = Join-Path $textureDir '042.png'
$referencePath = Join-Path $textureDir '074.png'
$reference = [Drawing.Bitmap]::new($referencePath)
$left=$reference.Width; $top=$reference.Height; $right=-1; $bottom=-1
for ($y=0; $y -lt $reference.Height; $y++) {
    for ($x=0; $x -lt $reference.Width; $x++) {
        if ($reference.GetPixel($x,$y).A -gt 8) {
            $left=[Math]::Min($left,$x); $right=[Math]::Max($right,$x)
            $top=[Math]::Min($top,$y); $bottom=[Math]::Max($bottom,$y)
        }
    }
}
if ($right -lt 0 -or $right-$left -lt 20) { throw 'Unexpected round-button alpha footprint.' }
$canvas = [Drawing.Bitmap]::new($reference.Width,$reference.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
$reference.Dispose()
$g = [Drawing.Graphics]::FromImage($canvas)
$g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$d = [single][Math]::Min($right-$left+1,$bottom-$top-1)
$cx = [single](($left+$right)/2)
$cy = [single](($top+$bottom-1)/2)
$outer = [Drawing.RectangleF]::new($cx-$d/2,$cy-$d/2,$d,$d)
$rimInset = [single][Math]::Max(0.75,$d*.035)
$rim = [Drawing.RectangleF]::new($outer.X+$rimInset,$outer.Y+$rimInset,$d-2*$rimInset,$d-2*$rimInset)
$face = [Drawing.RectangleF]::new($rim.X+$rimInset,$rim.Y+$rimInset,$rim.Width-2*$rimInset,$rim.Height-2*$rimInset)
$shadowBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(135,10,11,12))
$outerBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,42,44,47))
$rimBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,132,137,143))
$faceBrush = [Drawing.Drawing2D.LinearGradientBrush]::new($face,
    [Drawing.Color]::FromArgb(255,255,255,255),
    [Drawing.Color]::FromArgb(255,204,208,213),90)
$symbolBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,31,32,34))
try {
    $g.FillEllipse($shadowBrush,[Drawing.RectangleF]::new($outer.X,$outer.Y+[Math]::Max(1,$d*.05),$d,$d))
    $g.FillEllipse($outerBrush,$outer)
    $g.FillEllipse($rimBrush,$rim)
    $g.FillEllipse($faceBrush,$face)
    # About the same visual footprint as the Options, Cross and Circle marks.
    $reach=[single]($face.Width*.235)
    $halfWidth=[single]($face.Width*.068)
    $g.FillRectangle($symbolBrush,$cx-$halfWidth,$cy-$reach,2*$halfWidth,2*$reach)
    $g.FillRectangle($symbolBrush,$cx-$reach,$cy-$halfWidth,2*$reach,2*$halfWidth)
}
finally {
    $symbolBrush.Dispose(); $faceBrush.Dispose(); $rimBrush.Dispose()
    $outerBrush.Dispose(); $shadowBrush.Dispose(); $g.Dispose()
}
$canvas.Save($imagePath,[Drawing.Imaging.ImageFormat]::Png)
$canvas.Dispose()

& $texconv -f BC3_UNORM -m 1 -y -o $textureDir $imagePath | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'texconv failed for entry 042.' }
& $g1tTool -y $textureDir | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'gust_g1t failed for station_ENG.' }

Copy-Item -LiteralPath $SourceMod -Destination $Output -Recurse
Copy-Item -LiteralPath (Join-Path $buildRoot 'station_ENG.g1t') -Destination (Join-Path $Output 'romfs\data\ui\station_ENG.g1t.gz') -Force
Set-Content -LiteralPath (Join-Path $Output 'VERSION.txt') -Value '1.0.0-rc14' -NoNewline
Write-Output "Staged RC14 compact circular menu D-pad: $Output"
