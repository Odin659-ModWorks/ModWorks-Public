param(
    [string]$SourceMod = 'K:\EMULATORS\SWITCH\Eden\user\load\0100AE00096EA000\PlayStation Button Prompts v1.0.0-rc12',
    [string]$ResearchRoot = 'K:\EMULATORS\SWITCH\Eden\user\cache\hwde-mod-research',
    [string]$Output = (Join-Path $PSScriptRoot '..\staging\PlayStation Button Prompts v1.0.0-rc13')
)

$ErrorActionPreference = 'Stop'
$sourceTextures = Join-Path $ResearchRoot 'button-work\cohesive-v1.0.0-build-rc12\station_ENG'
$buildRoot = Join-Path $ResearchRoot 'button-work\cohesive-v1.0.0-build-rc13'
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

# The menu Select icon is station_ENG entry 042. Keep its original alpha
# footprint, but give it the same dark rim / pale face as the face buttons.
$imagePath = Join-Path $textureDir '042.png'
$source = [Drawing.Bitmap]::new($imagePath)
$left = $source.Width; $top = $source.Height; $right = -1; $bottom = -1
for ($y=0; $y -lt $source.Height; $y++) {
    for ($x=0; $x -lt $source.Width; $x++) {
        if ($source.GetPixel($x,$y).A -gt 8) {
            $left=[Math]::Min($left,$x); $right=[Math]::Max($right,$x)
            $top=[Math]::Min($top,$y); $bottom=[Math]::Max($bottom,$y)
        }
    }
}
if ($right -lt 0 -or $right-$left -lt 20) { throw 'Unexpected entry 042 alpha footprint.' }
$canvas = [Drawing.Bitmap]::new($source.Width,$source.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
$source.Dispose()
$g = [Drawing.Graphics]::FromImage($canvas)
$g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$d = [single][Math]::Min($right-$left+1,$bottom-$top)
$cx = [single](($left+$right)/2)
$cy = [single](($top+$bottom-1)/2)
$outer = [Drawing.RectangleF]::new($cx-$d/2,$cy-$d/2,$d,$d)
$rim = [Drawing.RectangleF]::new($outer.X+1.5,$outer.Y+1.5,$d-3,$d-3)
$face = [Drawing.RectangleF]::new($rim.X+1.5,$rim.Y+1.5,$rim.Width-3,$rim.Height-3)
$shadowBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(135,10,11,12))
$outerBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,42,44,47))
$rimBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,132,137,143))
$faceBrush = [Drawing.Drawing2D.LinearGradientBrush]::new($face,
    [Drawing.Color]::FromArgb(255,255,255,255),
    [Drawing.Color]::FromArgb(255,202,206,212),90)
$symbolBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,31,32,34))
$redBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,194,35,45))
try {
    $g.FillEllipse($shadowBrush,[Drawing.RectangleF]::new($outer.X,$outer.Y+1,$outer.Width,$outer.Height))
    $g.FillEllipse($outerBrush,$outer)
    $g.FillEllipse($rimBrush,$rim)
    $g.FillEllipse($faceBrush,$face)
    # A single dark D-pad silhouette reads like the other buttons' dark
    # symbols, with four restrained red directional tips.
    $span = [single]($d*0.255)
    $halfWidth = [single]($d*0.085)
    $g.FillRectangle($symbolBrush,$cx-$halfWidth,$cy-$span,2*$halfWidth,2*$span)
    $g.FillRectangle($symbolBrush,$cx-$span,$cy-$halfWidth,2*$span,2*$halfWidth)
    $tip = [single]($d*0.082)
    foreach ($direction in @('up','down','left','right')) {
        $points = switch ($direction) {
            'up' { @([Drawing.PointF]::new($cx,$cy-$span-$tip*.15),[Drawing.PointF]::new($cx-$tip*.65,$cy-$span+$tip),[Drawing.PointF]::new($cx+$tip*.65,$cy-$span+$tip)) }
            'down' { @([Drawing.PointF]::new($cx,$cy+$span+$tip*.15),[Drawing.PointF]::new($cx-$tip*.65,$cy+$span-$tip),[Drawing.PointF]::new($cx+$tip*.65,$cy+$span-$tip)) }
            'left' { @([Drawing.PointF]::new($cx-$span-$tip*.15,$cy),[Drawing.PointF]::new($cx-$span+$tip,$cy-$tip*.65),[Drawing.PointF]::new($cx-$span+$tip,$cy+$tip*.65)) }
            'right' { @([Drawing.PointF]::new($cx+$span+$tip*.15,$cy),[Drawing.PointF]::new($cx+$span-$tip,$cy-$tip*.65),[Drawing.PointF]::new($cx+$span-$tip,$cy+$tip*.65)) }
        }
        $g.FillPolygon($redBrush,[Drawing.PointF[]]$points)
    }
}
finally {
    $redBrush.Dispose(); $symbolBrush.Dispose(); $faceBrush.Dispose()
    $rimBrush.Dispose(); $outerBrush.Dispose(); $shadowBrush.Dispose(); $g.Dispose()
}
$canvas.Save($imagePath,[Drawing.Imaging.ImageFormat]::Png)
$canvas.Dispose()

& $texconv -f BC3_UNORM -m 1 -y -o $textureDir $imagePath | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'texconv failed for entry 042.' }
& $g1tTool -y $textureDir | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'gust_g1t failed for station_ENG.' }

Copy-Item -LiteralPath $SourceMod -Destination $Output -Recurse
Copy-Item -LiteralPath (Join-Path $buildRoot 'station_ENG.g1t') -Destination (Join-Path $Output 'romfs\data\ui\station_ENG.g1t.gz') -Force

# Shift only the English Manual icon one space toward its following label:
# "Select  ^  Manual" -> "Select   ^ Manual". The text and byte length stay put.
$messagePath = Join-Path $Output 'romfs\data\common\msgdata.bin'
$bytes = [IO.File]::ReadAllBytes($messagePath)
$changes = 0; $start = 0
for ($end=0; $end -le $bytes.Length; $end++) {
    if ($end -lt $bytes.Length -and $bytes[$end] -ne 0) { continue }
    $length = $end-$start
    if ($length -gt 0 -and $length -lt 300) {
        $value = [Text.Encoding]::ASCII.GetString($bytes,$start,$length)
        if ($value.Contains('Select') -and $value.Contains('Manual')) {
            for ($i=$start; $i -le $end-11; $i++) {
                if ($bytes[$i] -eq 0x20 -and $bytes[$i+1] -eq 0x20 -and
                    $bytes[$i+2] -eq 0x5e -and $bytes[$i+3] -eq 0x20 -and
                    $bytes[$i+4] -eq 0x20 -and $bytes[$i+5] -eq 0x4d -and
                    $bytes[$i+6] -eq 0x61 -and $bytes[$i+7] -eq 0x6e -and
                    $bytes[$i+8] -eq 0x75 -and $bytes[$i+9] -eq 0x61 -and
                    $bytes[$i+10] -eq 0x6c) {
                    $bytes[$i+2]=0x20; $bytes[$i+3]=0x5e
                    $changes++
                }
            }
        }
    }
    $start=$end+1
}
if ($changes -ne 2) { throw "Unexpected English Manual prompt count: $changes" }
[IO.File]::WriteAllBytes($messagePath,$bytes)
Set-Content -LiteralPath (Join-Path $Output 'VERSION.txt') -Value '1.0.0-rc13' -NoNewline
Write-Output "Staged RC13 with $changes Manual icon adjustments: $Output"
