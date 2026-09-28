param(
    [string]$SourceMod = 'K:\EMULATORS\SWITCH\Eden\user\load\0100AE00096EA000\PlayStation Button Prompts v1.0.0-rc15',
    [string]$ResearchRoot = 'K:\EMULATORS\SWITCH\Eden\user\cache\hwde-mod-research',
    [string]$Output = (Join-Path $PSScriptRoot '..\staging\PlayStation Button Prompts v1.0.0-rc16')
)

$ErrorActionPreference='Stop'
$sourceTextures=Join-Path $ResearchRoot 'button-work\matching-menu-icons-rc15\station_ENG'
$buildRoot=Join-Path $ResearchRoot 'button-work\inset-dpad-arrows-rc16'
$station=Join-Path $buildRoot 'station_ENG'
$texconv=Join-Path $ResearchRoot 'texconv.exe'
$g1tTool=Join-Path $ResearchRoot 'gust_tools\gust_g1t.exe'
foreach($path in @($SourceMod,$sourceTextures,$texconv,$g1tTool)){
    if(-not(Test-Path -LiteralPath $path)){throw "Missing required source: $path"}
}
if(Test-Path -LiteralPath $Output){throw "Candidate already exists: $Output"}
if(Test-Path -LiteralPath $buildRoot){throw "Build already exists: $buildRoot"}
New-Item -ItemType Directory -Path $buildRoot | Out-Null
Copy-Item -LiteralPath $sourceTextures -Destination $station -Recurse
Add-Type -AssemblyName System.Drawing

# Keep RC15's white ring and large white cross. Bring only the red tips
# inside the ring and make them modestly wider and taller.
$padPath=Join-Path $station '042.png'
$old=[Drawing.Bitmap]::new($padPath)
$left=$old.Width;$top=$old.Height;$right=-1;$bottom=-1
for($y=0;$y -lt $old.Height;$y++){
    for($x=0;$x -lt $old.Width;$x++){
        if($old.GetPixel($x,$y).A -gt 8){
            $left=[Math]::Min($left,$x);$right=[Math]::Max($right,$x)
            $top=[Math]::Min($top,$y);$bottom=[Math]::Max($bottom,$y)
        }
    }
}
if($right -lt 0 -or $right-$left -lt 20){throw 'Unexpected Select icon footprint.'}
$canvas=[Drawing.Bitmap]::new($old.Width,$old.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
$old.Dispose()
$g=[Drawing.Graphics]::FromImage($canvas)
$g.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$d=[single][Math]::Min($right-$left+1,$bottom-$top-1)
$cx=[single](($left+$right)/2);$cy=[single](($top+$bottom-1)/2)
$outer=[Drawing.RectangleF]::new($cx-$d/2,$cy-$d/2,$d,$d)
$dark=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,27,22,18))
$white=[Drawing.SolidBrush]::new([Drawing.Color]::White)
$red=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,196,35,45))
$ring=[Drawing.Pen]::new([Drawing.Color]::White,[single]($d*.092))
try{
    $g.FillEllipse($dark,$outer)
    $ringRect=[Drawing.RectangleF]::new($outer.X+$d*.09,$outer.Y+$d*.09,$d*.82,$d*.82)
    $g.DrawEllipse($ring,$ringRect)
    $reach=[single]($d*.405);$half=[single]($d*.087)
    $g.FillRectangle($white,$cx-$half,$cy-$reach,2*$half,2*$reach)
    $g.FillRectangle($white,$cx-$reach,$cy-$half,2*$reach,2*$half)
    # Ring inner edge is about 0.36*d from center. Tip at 0.31*d gives
    # a reliable gap even after BC3 compression and in-game downscaling.
    $tipRadius=[single]($d*.31)
    $tipWidth=[single]($d*.11)
    $baseRadius=[single]($tipRadius-$d*.13)
    $marks=@(
        [Drawing.PointF[]]@([Drawing.PointF]::new($cx,$cy-$tipRadius),[Drawing.PointF]::new($cx-$tipWidth*.8,$cy-$baseRadius),[Drawing.PointF]::new($cx+$tipWidth*.8,$cy-$baseRadius)),
        [Drawing.PointF[]]@([Drawing.PointF]::new($cx,$cy+$tipRadius),[Drawing.PointF]::new($cx-$tipWidth*.8,$cy+$baseRadius),[Drawing.PointF]::new($cx+$tipWidth*.8,$cy+$baseRadius)),
        [Drawing.PointF[]]@([Drawing.PointF]::new($cx-$tipRadius,$cy),[Drawing.PointF]::new($cx-$baseRadius,$cy-$tipWidth*.8),[Drawing.PointF]::new($cx-$baseRadius,$cy+$tipWidth*.8)),
        [Drawing.PointF[]]@([Drawing.PointF]::new($cx+$tipRadius,$cy),[Drawing.PointF]::new($cx+$baseRadius,$cy-$tipWidth*.8),[Drawing.PointF]::new($cx+$baseRadius,$cy+$tipWidth*.8))
    )
    foreach($points in $marks){$g.FillPolygon($red,$points)}
}
finally{$ring.Dispose();$red.Dispose();$white.Dispose();$dark.Dispose();$g.Dispose()}
$canvas.Save($padPath,[Drawing.Imaging.ImageFormat]::Png)
$canvas.Dispose()
& $texconv -f BC3_UNORM -m 1 -y -o $station $padPath | Out-Null
if($LASTEXITCODE -ne 0){throw 'texconv failed for Select icon.'}
& $g1tTool -y $station | Out-Null
if($LASTEXITCODE -ne 0){throw 'gust_g1t failed for station_ENG.'}

Copy-Item -LiteralPath $SourceMod -Destination $Output -Recurse
Copy-Item -LiteralPath (Join-Path $buildRoot 'station_ENG.g1t') -Destination (Join-Path $Output 'romfs\data\ui\station_ENG.g1t.gz') -Force
Set-Content -LiteralPath (Join-Path $Output 'VERSION.txt') -Value '1.0.0-rc16' -NoNewline
Write-Output "Staged RC16 inset D-pad arrows: $Output"
