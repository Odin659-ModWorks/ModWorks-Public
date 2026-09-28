param(
    [Parameter(Mandatory = $true)][string]$TextureDir,
    [ValidateSet('OptionPad','Station')][string]$Set,
    [switch]$Blank,
    [switch]$CircleDPad
)

Add-Type -AssemblyName System.Drawing

function Get-AlphaBounds([Drawing.Bitmap]$Bitmap) {
    $minX = $Bitmap.Width; $minY = $Bitmap.Height; $maxX = -1; $maxY = -1
    for ($y = 0; $y -lt $Bitmap.Height; $y++) {
        for ($x = 0; $x -lt $Bitmap.Width; $x++) {
            if ($Bitmap.GetPixel($x, $y).A -gt 8) {
                if ($x -lt $minX) { $minX = $x }; if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }; if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }
    if ($maxX -lt 0) { throw 'Texture has no visible pixels.' }
    [Drawing.RectangleF]::new($minX, $minY, $maxX - $minX + 1, $maxY - $minY + 1)
}

function New-RoundedPath([Drawing.RectangleF]$Rect, [single]$Radius) {
    $path = [Drawing.Drawing2D.GraphicsPath]::new()
    $d = [Math]::Min($Radius * 2, [Math]::Min($Rect.Width, $Rect.Height))
    $path.AddArc($Rect.X, $Rect.Y, $d, $d, 180, 90)
    $path.AddArc($Rect.Right - $d, $Rect.Y, $d, $d, 270, 90)
    $path.AddArc($Rect.Right - $d, $Rect.Bottom - $d, $d, $d, 0, 90)
    $path.AddArc($Rect.X, $Rect.Bottom - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    $path
}

function Inset-Rect([Drawing.RectangleF]$Rect, [single]$Amount) {
    [Drawing.RectangleF]::new($Rect.X + $Amount, $Rect.Y + $Amount,
        [Math]::Max(1, $Rect.Width - 2 * $Amount), [Math]::Max(1, $Rect.Height - 2 * $Amount))
}

function New-Canvas([string]$Path) {
    $source = [Drawing.Bitmap]::FromFile($Path)
    try {
        $bounds = Get-AlphaBounds $source
        $canvas = [Drawing.Bitmap]::new($source.Width, $source.Height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
        [pscustomobject]@{ Canvas = $canvas; Bounds = $bounds }
    }
    finally { $source.Dispose() }
}

function Add-FaceGradient([Drawing.Graphics]$G, [Drawing.Drawing2D.GraphicsPath]$Path, [Drawing.RectangleF]$Rect) {
    $brush = [Drawing.Drawing2D.LinearGradientBrush]::new(
        $Rect, [Drawing.Color]::FromArgb(255, 255, 255, 255),
        [Drawing.Color]::FromArgb(255, 204, 208, 213), 90)
    try {
        $blend = [Drawing.Drawing2D.ColorBlend]::new(4)
        $blend.Colors = [Drawing.Color[]]@(
            [Drawing.Color]::FromArgb(255,255,255,255),
            [Drawing.Color]::FromArgb(255,245,247,250),
            [Drawing.Color]::FromArgb(255,224,227,231),
            [Drawing.Color]::FromArgb(255,197,201,207))
        $blend.Positions = [single[]]@(0.0,0.35,0.72,1.0)
        $brush.InterpolationColors = $blend
        $G.FillPath($brush, $Path)
    }
    finally { $brush.Dispose() }
}

function Draw-Symbol([Drawing.Graphics]$G, [Drawing.RectangleF]$Face, [string]$Symbol) {
    if ($Blank -or [string]::IsNullOrWhiteSpace($Symbol)) { return }
    $cx = $Face.X + $Face.Width / 2.0
    $cy = $Face.Y + $Face.Height / 2.0 - [Math]::Max(0.2, $Face.Height * 0.015)
    $unit = [Math]::Min($Face.Width, $Face.Height)
    $width = [Math]::Max(1.35, $unit * 0.095)
    $ink = [Drawing.Pen]::new([Drawing.Color]::FromArgb(255, 31, 32, 34), $width)
    $ink.StartCap = 'Round'; $ink.EndCap = 'Round'; $ink.LineJoin = 'Round'
    try {
        $size = $unit * 0.54
        switch ($Symbol) {
            'triangle' {
                $half = $size * 0.52
                $points = [Drawing.PointF[]]@(
                    [Drawing.PointF]::new($cx, $cy - $half),
                    [Drawing.PointF]::new($cx + $half, $cy + $half * 0.78),
                    [Drawing.PointF]::new($cx - $half, $cy + $half * 0.78),
                    [Drawing.PointF]::new($cx, $cy - $half))
                $G.DrawLines($ink, $points)
            }
            'circle' { $G.DrawEllipse($ink, $cx - $size/2, $cy - $size/2, $size, $size) }
            'cross' {
                $h = $size * 0.42
                $G.DrawLine($ink, $cx-$h, $cy-$h, $cx+$h, $cy+$h)
                $G.DrawLine($ink, $cx+$h, $cy-$h, $cx-$h, $cy+$h)
            }
            'square' { $G.DrawRectangle($ink, $cx-$size/2, $cy-$size/2, $size, $size) }
            'options' {
                $h = $size * 0.48
                foreach ($dy in @(-$h,0,$h)) { $G.DrawLine($ink, $cx-$size/2, $cy+$dy, $cx+$size/2, $cy+$dy) }
            }
            'create' {
                # DualSense Create mark: three offset rays, distinct from Options.
                # The rays begin close together at the lower center and fan
                # upward, matching the orientation of the physical button.
                $G.DrawLine($ink,$cx-$size*.08,$cy+$size*.42,$cx-$size*.36,$cy-$size*.34)
                $G.DrawLine($ink,$cx,$cy+$size*.45,$cx,$cy-$size*.44)
                $G.DrawLine($ink,$cx+$size*.08,$cy+$size*.42,$cx+$size*.36,$cy-$size*.34)
            }
        }
    }
    finally { $ink.Dispose() }
}

function Draw-Label([Drawing.Graphics]$G, [Drawing.RectangleF]$Face, [string]$Text) {
    if ($Blank -or [string]::IsNullOrWhiteSpace($Text)) { return }
    if ($Text -in @('L1','R1','L2','R2')) {
        # Use one monospaced face and one common ink scale for all four labels.
        # Fitting each label independently made R1 look larger than L1.
        $family = [Drawing.FontFamily]::new('Consolas')
        $format = [Drawing.StringFormat]::new([Drawing.StringFormat]::GenericTypographic)
        $path = [Drawing.Drawing2D.GraphicsPath]::new()
        $brush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,31,32,34))
        try {
            $path.AddString($Text, $family, [int][Drawing.FontStyle]::Bold,
                [single]100.0, [Drawing.PointF]::new(0,0), $format)
            $ink = $path.GetBounds()
            $commonHeight = 0.0; $commonWidth = 0.0
            foreach ($label in @('L1','R1','L2','R2')) {
                $reference = [Drawing.Drawing2D.GraphicsPath]::new()
                try {
                    $reference.AddString($label, $family, [int][Drawing.FontStyle]::Bold,
                        [single]100.0, [Drawing.PointF]::new(0,0), $format)
                    $bounds = $reference.GetBounds()
                    $commonHeight = [Math]::Max($commonHeight, $bounds.Height)
                    $commonWidth = [Math]::Max($commonWidth, $bounds.Width)
                }
                finally { $reference.Dispose() }
            }
            $targetHeight = [Math]::Min(20.0, $Face.Height * 0.65)
            $scale = [Math]::Min($targetHeight / $commonHeight,
                ($Face.Width * 0.78) / $commonWidth)
            $dx = $Face.X + ($Face.Width - $ink.Width * $scale) / 2 - $ink.X * $scale
            $dy = $Face.Y + ($Face.Height - $ink.Height * $scale) / 2 - $ink.Y * $scale
            $fit = [Drawing.Drawing2D.Matrix]::new([single]$scale,0,0,[single]$scale,
                [single]$dx,[single]$dy)
            try { $path.Transform($fit) }
            finally { $fit.Dispose() }
            $G.FillPath($brush, $path)
        }
        finally { $brush.Dispose(); $path.Dispose(); $format.Dispose(); $family.Dispose() }
        return
    }
    # Remaining text labels (such as L3/R3) use the original string renderer.
    $fontSize = [Math]::Min(22.5, [Math]::Min($Face.Height * 0.90, $Face.Width * 0.90))
    $fontSize = [Math]::Max(8, $fontSize)
    # The condensed face lets a genuinely 1.5x two-character label fit the
    # smallest 32px keycap without clipping either character.
    $font = [Drawing.Font]::new('Bahnschrift SemiBold Condensed', $fontSize, [Drawing.FontStyle]::Regular, [Drawing.GraphicsUnit]::Pixel)
    $brush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,31,32,34))
    $format = [Drawing.StringFormat]::new()
    $format.Alignment = 'Center'; $format.LineAlignment = 'Center'
    try { $G.DrawString($Text, $font, $brush, $Face, $format) }
    finally { $format.Dispose(); $brush.Dispose(); $font.Dispose() }
}

function Write-RoundButton([string]$Name, [string]$Symbol) {
    $path = Join-Path $TextureDir "$Name.png"; $item = New-Canvas $path
    $canvas = $item.Canvas; $bounds = $item.Bounds
    $g = [Drawing.Graphics]::FromImage($canvas)
    try {
        $g.SmoothingMode = 'AntiAlias'; $g.PixelOffsetMode = 'HighQuality'
        $diameter = [Math]::Min($bounds.Width, $bounds.Height - 1)
        $rect = [Drawing.RectangleF]::new($bounds.X + ($bounds.Width-$diameter)/2, $bounds.Y, $diameter, $diameter)
        $shadowRect = [Drawing.RectangleF]::new($rect.X, $rect.Y + [Math]::Max(1,$diameter*0.05), $rect.Width, $rect.Height)
        $shadow = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(135,10,11,12)); $g.FillEllipse($shadow,$shadowRect); $shadow.Dispose()
        $outer = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,42,44,47)); $g.FillEllipse($outer,$rect); $outer.Dispose()
        $rim = Inset-Rect $rect ([Math]::Max(0.75,$diameter*0.035))
        $rimBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,132,137,143)); $g.FillEllipse($rimBrush,$rim); $rimBrush.Dispose()
        $face = Inset-Rect $rim ([Math]::Max(0.75,$diameter*0.035))
        $facePath = [Drawing.Drawing2D.GraphicsPath]::new(); $facePath.AddEllipse($face)
        try { Add-FaceGradient $g $facePath $face; Draw-Symbol $g $face $Symbol }
        finally { $facePath.Dispose() }
    }
    finally { $g.Dispose() }
    $temp="$path.new.png"; $canvas.Save($temp,[Drawing.Imaging.ImageFormat]::Png); $canvas.Dispose(); Move-Item -LiteralPath $temp -Destination $path -Force
}

function Write-KeyButton([string]$Name, [string]$Text) {
    $path = Join-Path $TextureDir "$Name.png"; $item = New-Canvas $path
    $canvas=$item.Canvas; $bounds=$item.Bounds; $g=[Drawing.Graphics]::FromImage($canvas)
    try {
        $g.SmoothingMode='AntiAlias'; $g.PixelOffsetMode='HighQuality'
        $shadowRect=[Drawing.RectangleF]::new($bounds.X,$bounds.Y+[Math]::Max(1,$bounds.Height*0.05),$bounds.Width,$bounds.Height-[Math]::Max(1,$bounds.Height*0.05))
        $outerRect=[Drawing.RectangleF]::new($bounds.X,$bounds.Y,$bounds.Width,$bounds.Height-[Math]::Max(1,$bounds.Height*0.05))
        $sp=New-RoundedPath $shadowRect ([Math]::Min($shadowRect.Height,$shadowRect.Width)*0.18)
        $op=New-RoundedPath $outerRect ([Math]::Min($outerRect.Height,$outerRect.Width)*0.18)
        $shadow=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(135,10,11,12)); $outer=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,42,44,47))
        try{$g.FillPath($shadow,$sp);$g.FillPath($outer,$op)}finally{$shadow.Dispose();$outer.Dispose();$sp.Dispose();$op.Dispose()}
        $rimRect=Inset-Rect $outerRect ([Math]::Max(0.75,$outerRect.Height*0.035)); $rp=New-RoundedPath $rimRect ([Math]::Min($rimRect.Height,$rimRect.Width)*0.15)
        $rim=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,132,137,143));try{$g.FillPath($rim,$rp)}finally{$rim.Dispose();$rp.Dispose()}
        $face=Inset-Rect $rimRect ([Math]::Max(0.75,$outerRect.Height*0.035));$fp=New-RoundedPath $face ([Math]::Min($face.Height,$face.Width)*0.13)
        try{Add-FaceGradient $g $fp $face;Draw-Label $g $face $Text}finally{$fp.Dispose()}
    }finally{$g.Dispose()}
    $temp="$path.new.png";$canvas.Save($temp,[Drawing.Imaging.ImageFormat]::Png);$canvas.Dispose();Move-Item -LiteralPath $temp -Destination $path -Force
}

function Write-RoundLabel([string]$Name, [string]$Text) {
    $path = Join-Path $TextureDir "$Name.png"; $item = New-Canvas $path
    $canvas = $item.Canvas; $bounds = $item.Bounds; $g = [Drawing.Graphics]::FromImage($canvas)
    try {
        $g.SmoothingMode='AntiAlias'; $g.PixelOffsetMode='HighQuality'
        $diameter=[Math]::Min($bounds.Width,$bounds.Height-1)
        $rect=[Drawing.RectangleF]::new($bounds.X+($bounds.Width-$diameter)/2,$bounds.Y,$diameter,$diameter)
        $shadowRect=[Drawing.RectangleF]::new($rect.X,$rect.Y+[Math]::Max(1,$diameter*.05),$rect.Width,$rect.Height)
        $shadow=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(135,10,11,12));$g.FillEllipse($shadow,$shadowRect);$shadow.Dispose()
        $outer=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,42,44,47));$g.FillEllipse($outer,$rect);$outer.Dispose()
        $rim=Inset-Rect $rect ([Math]::Max(.75,$diameter*.035));$rb=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,132,137,143));$g.FillEllipse($rb,$rim);$rb.Dispose()
        $face=Inset-Rect $rim ([Math]::Max(.75,$diameter*.035));$fp=[Drawing.Drawing2D.GraphicsPath]::new();$fp.AddEllipse($face)
        try{Add-FaceGradient $g $fp $face;Draw-Label $g $face $Text}finally{$fp.Dispose()}
    }finally{$g.Dispose()}
    $temp="$path.new.png";$canvas.Save($temp,[Drawing.Imaging.ImageFormat]::Png);$canvas.Dispose();Move-Item -LiteralPath $temp -Destination $path -Force
}

function Write-StickPress([string]$Name,[string]$Text) {
    $path=Join-Path $TextureDir "$Name.png";$item=New-Canvas $path;$canvas=$item.Canvas;$b=$item.Bounds;$g=[Drawing.Graphics]::FromImage($canvas)
    try{
        $g.SmoothingMode='AntiAlias';$g.PixelOffsetMode='HighQuality'
        $d=[Math]::Min($b.Width*.78,$b.Height*.58);$cx=$b.X+$b.Width/2;$cy=$b.Bottom-$d*.52
        $rect=[Drawing.RectangleF]::new($cx-$d/2,$cy-$d/2,$d,$d)
        $outer=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,42,44,47));$g.FillEllipse($outer,$rect);$outer.Dispose()
        $face=Inset-Rect $rect ([Math]::Max(.75,$d*.055));$fp=[Drawing.Drawing2D.GraphicsPath]::new();$fp.AddEllipse($face)
        try{Add-FaceGradient $g $fp $face;Draw-Label $g $face $Text}finally{$fp.Dispose()}
        if(-not $Blank){$red=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,205,28,42));$pts=[Drawing.PointF[]]@([Drawing.PointF]::new($cx,$b.Y),[Drawing.PointF]::new($cx+$d*.27,$cy-$d*.48),[Drawing.PointF]::new($cx+$d*.10,$cy-$d*.48),[Drawing.PointF]::new($cx+$d*.10,$cy-$d*.22),[Drawing.PointF]::new($cx-$d*.10,$cy-$d*.22),[Drawing.PointF]::new($cx-$d*.10,$cy-$d*.48),[Drawing.PointF]::new($cx-$d*.27,$cy-$d*.48));try{$g.FillPolygon($red,$pts)}finally{$red.Dispose()}}
    }finally{$g.Dispose()}
    $temp="$path.new.png";$canvas.Save($temp,[Drawing.Imaging.ImageFormat]::Png);$canvas.Dispose();Move-Item -LiteralPath $temp -Destination $path -Force
}

function Write-DPad([string]$Name, [ValidateSet('neutral','horizontal','vertical','up','down','left','right')][string]$State) {
    $path=Join-Path $TextureDir "$Name.png";$item=New-Canvas $path;$canvas=$item.Canvas;$b=$item.Bounds;$g=[Drawing.Graphics]::FromImage($canvas)
    try{
        $g.SmoothingMode='AntiAlias';$g.PixelOffsetMode='HighQuality'
        $cx=$b.X+$b.Width/2;$cy=$b.Y+$b.Height/2
        if($CircleDPad -and $Set -eq 'Station'){
            $diameter=[Math]::Min($b.Width,$b.Height-1)
            $round=[Drawing.RectangleF]::new($cx-$diameter/2,$cy-$diameter/2,$diameter,$diameter)
            $shadow=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(135,10,11,12))
            $outer=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,42,44,47))
            $rimBrush=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,240,242,244))
            $faceBrush=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,42,44,47))
            try{
                $g.FillEllipse($shadow,[Drawing.RectangleF]::new($round.X,$round.Y+1,$round.Width,$round.Height))
                $g.FillEllipse($outer,$round)
                $rim=Inset-Rect $round ([Math]::Max(.75,$diameter*.035))
                $g.FillEllipse($rimBrush,$rim)
                $face=Inset-Rect $rim ([Math]::Max(.75,$diameter*.035))
                $g.FillEllipse($faceBrush,$face)
            }finally{$faceBrush.Dispose();$rimBrush.Dispose();$outer.Dispose();$shadow.Dispose()}
            $arm=$diameter*.29
        }else{$arm=[Math]::Min($b.Width,$b.Height)*0.29}
        $hub=$arm*$(if($CircleDPad -and $Set -eq 'Station'){1.02}else{0.72})
        $padBounds=$b
        if($CircleDPad -and $Set -eq 'Station'){
            $span=$arm*1.27
            $padBounds=[Drawing.RectangleF]::new($cx-$span,$cy-$span,2*$span,2*$span)
        }
        $crossColor=if($CircleDPad -and $Set -eq 'Station'){
            [Drawing.Color]::FromArgb(255,226,229,233)
        }else{[Drawing.Color]::FromArgb(255,91,95,100)}
        $dark=[Drawing.SolidBrush]::new($crossColor);$pearl=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,226,229,233));$mark=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,196,35,45))
        try{
            $g.FillRectangle($dark,$cx-$hub/2,$padBounds.Y,$hub,$padBounds.Height);$g.FillRectangle($dark,$padBounds.X,$cy-$hub/2,$padBounds.Width,$hub)
            $positions=@{
                up=@($cx,($cy-$arm)); down=@($cx,($cy+$arm))
                left=@(($cx-$arm),$cy); right=@(($cx+$arm),$cy)
            }
            foreach($dir in $positions.Keys){$p=$positions[$dir];$g.FillEllipse($pearl,$p[0]-$arm*0.38,$p[1]-$arm*0.38,$arm*0.76,$arm*0.76)}
            $active=switch($State){'horizontal'{@('left','right')};'vertical'{@('up','down')};'neutral'{@()};default{@($State)}}
            if(-not $Blank){foreach($dir in $active){$p=$positions[$dir];$pts=switch($dir){'up'{@([Drawing.PointF]::new($p[0],$p[1]-$arm*.26),[Drawing.PointF]::new($p[0]+$arm*.24,$p[1]+$arm*.18),[Drawing.PointF]::new($p[0]-$arm*.24,$p[1]+$arm*.18))};'down'{@([Drawing.PointF]::new($p[0],$p[1]+$arm*.26),[Drawing.PointF]::new($p[0]+$arm*.24,$p[1]-$arm*.18),[Drawing.PointF]::new($p[0]-$arm*.24,$p[1]-$arm*.18))};'left'{@([Drawing.PointF]::new($p[0]-$arm*.26,$p[1]),[Drawing.PointF]::new($p[0]+$arm*.18,$p[1]-$arm*.24),[Drawing.PointF]::new($p[0]+$arm*.18,$p[1]+$arm*.24))};'right'{@([Drawing.PointF]::new($p[0]+$arm*.26,$p[1]),[Drawing.PointF]::new($p[0]-$arm*.18,$p[1]-$arm*.24),[Drawing.PointF]::new($p[0]-$arm*.18,$p[1]+$arm*.24))}};$g.FillPolygon($mark,[Drawing.PointF[]]$pts)}}
            if($CircleDPad -and $Set -eq 'Station'){
                $centerBrush=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,42,44,47))
                try{$diam=$diameter*.16;$g.FillEllipse($centerBrush,$cx-$diam/2,$cy-$diam/2,$diam,$diam)}finally{$centerBrush.Dispose()}
            }
        }finally{$mark.Dispose();$pearl.Dispose();$dark.Dispose()}
    }finally{$g.Dispose()}
    $temp="$path.new.png";$canvas.Save($temp,[Drawing.Imaging.ImageFormat]::Png);$canvas.Dispose();Move-Item -LiteralPath $temp -Destination $path -Force
}

function Write-Combo([string]$Name,[string]$Kind) {
    $path=Join-Path $TextureDir "$Name.png";$item=New-Canvas $path;$canvas=$item.Canvas;$b=$item.Bounds;$g=[Drawing.Graphics]::FromImage($canvas)
    try{
        $g.SmoothingMode='AntiAlias';$g.PixelOffsetMode='HighQuality'
        $h=[Math]::Min(34,$b.Height*.72);$left=[Drawing.RectangleF]::new($b.X,$b.Y+($b.Height-$h)/2,[Math]::Min(40,$b.Width*.31),$h)
        $lp=New-RoundedPath $left 5;$lb=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,65,68,72));try{$g.FillPath($lb,$lp)}finally{$lb.Dispose();$lp.Dispose()}
        $lf=Inset-Rect $left 1.25;$lfp=New-RoundedPath $lf 3;try{Add-FaceGradient $g $lfp $lf;Draw-Label $g $lf 'R1'}finally{$lfp.Dispose()}
        $ink=[Drawing.Pen]::new([Drawing.Color]::FromArgb(255,230,232,235),3);try{if(-not $Blank){$plusX=$left.Right+12;$plusY=$b.Y+$b.Height/2;$g.DrawLine($ink,$plusX-5,$plusY,$plusX+5,$plusY);$g.DrawLine($ink,$plusX,$plusY-5,$plusX,$plusY+5)}}finally{$ink.Dispose()}
        $rightCenterX=$b.Right-$h/2;$rightCenterY=$b.Y+$b.Height/2;$right=[Drawing.RectangleF]::new($rightCenterX-$h/2,$rightCenterY-$h/2,$h,$h)
        if($Kind -eq 'L1'){
            $rp=New-RoundedPath $right 5;$rb=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,65,68,72));try{$g.FillPath($rb,$rp)}finally{$rb.Dispose();$rp.Dispose()};$rf=Inset-Rect $right 1.25;$rfp=New-RoundedPath $rf 3;try{Add-FaceGradient $g $rfp $rf;Draw-Label $g $rf 'L1'}finally{$rfp.Dispose()}
        }elseif($Kind -like 'dpad-*'){
            $state=$Kind.Substring(5);$arm=$h*.25;$hub=$arm*.7;$dark=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,91,95,100));$pearl=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,226,229,233));$red=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,196,35,45));try{$g.FillRectangle($dark,$rightCenterX-$hub/2,$right.Y,$hub,$right.Height);$g.FillRectangle($dark,$right.X,$rightCenterY-$hub/2,$right.Width,$hub);$pos=@{up=@($rightCenterX,($rightCenterY-$arm));down=@($rightCenterX,($rightCenterY+$arm));left=@(($rightCenterX-$arm),$rightCenterY);right=@(($rightCenterX+$arm),$rightCenterY)};foreach($d in $pos.Keys){$p=$pos[$d];$g.FillEllipse($pearl,$p[0]-3,$p[1]-3,6,6)};if((-not $Blank)-and$state-ne'neutral'){$p=$pos[$state];$g.FillEllipse($red,$p[0]-2,$p[1]-2,4,4)}}finally{$red.Dispose();$pearl.Dispose();$dark.Dispose()}
        }else{
            $outer=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,42,44,47));$g.FillEllipse($outer,$right);$outer.Dispose();$rf=Inset-Rect $right 1.25;$fp=[Drawing.Drawing2D.GraphicsPath]::new();$fp.AddEllipse($rf);try{Add-FaceGradient $g $fp $rf;if($Kind -in @('circle','cross','triangle','square','options','create')){Draw-Symbol $g $rf $Kind}elseif($Kind -eq 'stick-down'){Draw-Label $g $rf 'L3'}elseif($Kind -eq 'stick-up'){Draw-Label $g $rf 'R3'}}finally{$fp.Dispose()}
        }
    }finally{$g.Dispose()}
    $temp="$path.new.png";$canvas.Save($temp,[Drawing.Imaging.ImageFormat]::Png);$canvas.Dispose();Move-Item -LiteralPath $temp -Destination $path -Force
}

if ($Set -eq 'OptionPad') {
    Write-DPad '000' 'neutral'; Write-KeyButton '001' 'L1'; Write-KeyButton '002' 'R1'
    Write-RoundButton '003' 'triangle'; Write-RoundButton '004' 'circle'; Write-RoundButton '005' 'cross'; Write-RoundButton '006' 'square'
    Write-DPad '007' 'horizontal'; Write-DPad '008' 'vertical'
}
else {
    foreach($n in @('002','003','004','005','006','037')){Write-RoundButton $n 'circle'}
    foreach($n in @('007','008','009','010','011','038')){Write-RoundButton $n 'cross'}
    Write-DPad '042' 'neutral';Write-DPad '043' 'down';Write-DPad '044' 'left';Write-DPad '045' 'horizontal';Write-DPad '046' 'right';Write-DPad '047' 'up';Write-DPad '048' 'vertical'
    foreach($n in @('050','051')){Write-KeyButton $n 'L1'}
    foreach($n in @('054','055')){Write-KeyButton $n 'R1'}
    Write-RoundLabel '052' 'L3'; Write-StickPress '053' 'L3'
    Write-RoundLabel '057' 'R3'; Write-StickPress '058' 'R3'
    Write-RoundButton '059' 'create'; Write-RoundButton '074' 'options'; Write-RoundButton '076' 'triangle'; Write-RoundButton '077' 'square'
    Write-KeyButton '060' 'L1'; Write-KeyButton '061' 'R1'
    Write-Combo '062' 'circle'; Write-Combo '063' 'cross'; Write-Combo '064' 'dpad-neutral'; Write-Combo '065' 'dpad-down'
    Write-Combo '066' 'dpad-right'; Write-Combo '067' 'stick-down'; Write-Combo '068' 'stick-up'; Write-Combo '069' 'create'
    Write-Combo '070' 'L1'; Write-Combo '071' 'options'; Write-Combo '072' 'triangle'; Write-Combo '073' 'square'
    Write-KeyButton '078' 'R2'; foreach($n in @('079','080')){Write-KeyButton $n 'L2'}; Write-KeyButton '034' 'R2'; Write-KeyButton '081' 'R2'
}
