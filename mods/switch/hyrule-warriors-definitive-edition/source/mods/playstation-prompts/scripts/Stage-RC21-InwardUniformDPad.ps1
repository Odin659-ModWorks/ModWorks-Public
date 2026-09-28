param(
    [string]$SourceMod = 'K:\EMULATORS\SWITCH\Eden\user\load\0100AE00096EA000\PlayStation Button Prompts v1.0.0-rc19',
    [string]$ResearchRoot = 'K:\EMULATORS\SWITCH\Eden\user\cache\hwde-mod-research',
    [string]$Output = (Join-Path $PSScriptRoot '..\staging\PlayStation Button Prompts v1.0.0-rc21')
)

$ErrorActionPreference = 'Stop'
$sourceTextures = Join-Path $ResearchRoot 'button-work\larger-dpads-rc19\station_ENG'
$buildRoot = Join-Path $ResearchRoot 'button-work\inward-uniform-dpads-rc21'
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

# RC19's four keycaps are separate components. Scale each entire keycap
# uniformly by 15% while anchoring its OUTER straight wall. The extra
# width goes sideways and the extra length goes inward. Clip to the RC19
# aggregate footprint so no part of the overall icon expands outward.
$scale=[single]1.15
$directions=@('up','right','down','left')
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
    if ($right-$left -lt 25) { throw "Unexpected footprint: $entry" }
    $centerX=[single](($left+$right)/2); $centerY=[single](($top+$bottom)/2)
    $components=@{}
    foreach ($direction in $directions) {
        $components[$direction]=@{Bitmap=[Drawing.Bitmap]::new($old.Width,$old.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb);Left=$old.Width;Top=$old.Height;Right=-1;Bottom=-1;Count=0}
    }
    try {
        for ($y=$top; $y -le $bottom; $y++) {
            for ($x=$left; $x -le $right; $x++) {
                $color=$old.GetPixel($x,$y)
                if ($color.A -eq 0) { continue }
                $dx=$x-$centerX; $dy=$y-$centerY
                if ([Math]::Abs($dy) -ge [Math]::Abs($dx)) {
                    $direction=if ($dy -lt 0) { 'up' } else { 'down' }
                }
                else { $direction=if ($dx -lt 0) { 'left' } else { 'right' } }
                $part=$components[$direction]
                $part.Bitmap.SetPixel($x,$y,$color)
                if ($color.A -gt 8) {
                    $part.Left=[Math]::Min($part.Left,$x)
                    $part.Right=[Math]::Max($part.Right,$x)
                    $part.Top=[Math]::Min($part.Top,$y)
                    $part.Bottom=[Math]::Max($part.Bottom,$y)
                    $part.Count++
                }
            }
        }
        $canvas=[Drawing.Bitmap]::new($old.Width,$old.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g=[Drawing.Graphics]::FromImage($canvas)
        $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceOver
        $g.SetClip([Drawing.Rectangle]::new($left,$top,$right-$left+1,$bottom-$top+1))
        try {
            foreach ($direction in $directions) {
                $part=$components[$direction]
                if ($part.Count -lt 80) { throw "Missing $direction keycap in entry $entry" }
                $w=[single]($part.Right-$part.Left+1); $h=[single]($part.Bottom-$part.Top+1)
                $midX=[single](($part.Left+$part.Right)/2); $midY=[single](($part.Top+$part.Bottom)/2)
                $newW=$w*$scale; $newH=$h*$scale
                switch ($direction) {
                    up { $dest=[Drawing.RectangleF]::new($midX-$newW/2,$part.Top,$newW,$newH) }
                    down { $dest=[Drawing.RectangleF]::new($midX-$newW/2,$part.Bottom+1-$newH,$newW,$newH) }
                    left { $dest=[Drawing.RectangleF]::new($part.Left,$midY-$newH/2,$newW,$newH) }
                    right { $dest=[Drawing.RectangleF]::new($part.Right+1-$newW,$midY-$newH/2,$newW,$newH) }
                }
                $source=[Drawing.RectangleF]::new($part.Left,$part.Top,$w,$h)
                $g.DrawImage($part.Bitmap,$dest,$source,[Drawing.GraphicsUnit]::Pixel)
            }
        }
        finally { $g.Dispose() }
        $temp="$png.rc21.tmp.png"
        $canvas.Save($temp,[Drawing.Imaging.ImageFormat]::Png)
        $canvas.Dispose()
    }
    finally {
        foreach ($part in $components.Values) { $part.Bitmap.Dispose() }
        $old.Dispose()
    }
    Move-Item -LiteralPath $temp -Destination $png -Force
    & $texconv -f BC3_UNORM -m 1 -y -o $station $png | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "texconv failed: $entry" }
}
& $g1tTool -y $station | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'gust_g1t failed for station_ENG.' }
Copy-Item -LiteralPath $SourceMod -Destination $Output -Recurse
Copy-Item -LiteralPath (Join-Path $buildRoot 'station_ENG.g1t') -Destination (Join-Path $Output 'romfs\data\ui\station_ENG.g1t.gz') -Force
Set-Content -LiteralPath (Join-Path $Output 'VERSION.txt') -Value '1.0.0-rc21' -NoNewline
Write-Output "Staged RC21 outer-anchored, uniformly enlarged keycaps: $Output"
