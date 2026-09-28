param(
    [string]$SourceMod = 'K:\EMULATORS\SWITCH\Eden\user\load\0100AE00096EA000\PlayStation Button Prompts v1.0.0-rc22',
    [string]$ResearchRoot = 'K:\EMULATORS\SWITCH\Eden\user\cache\hwde-mod-research',
    [string]$Output = (Join-Path $PSScriptRoot '..\staging\PlayStation Button Prompts v1.0.0-rc23')
)

$ErrorActionPreference = 'Stop'
$baseScript = Join-Path $PSScriptRoot 'Stage-RC22-SymmetricDPad.ps1'
$source = [IO.File]::ReadAllText($baseScript)

# Reuse the same canonical geometry and the seven proven direction maps.
# Rendering every outline before every face removes the overlap-order seam
# visible to the left of the vertical keys in rc22. Inactive arrows are gray.
$changes = [ordered]@{
    'PlayStation Button Prompts v1.0.0-rc21' = 'PlayStation Button Prompts v1.0.0-rc22'
    'symmetric-dpads-rc22' = 'quiet-symmetric-dpads-rc23'
    'PlayStation Button Prompts v1.0.0-rc22' = 'PlayStation Button Prompts v1.0.0-rc23'
    'FromArgb(255,67,62,60)' = 'FromArgb(255,120,116,112)'
    "foreach (`$direction in @('up','right','down','left')) { `$g.FillPath(`$white,`$pieces[`$direction]) }`n                foreach (`$direction in @('up','right','down','left')) { `$g.DrawPath(`$outline,`$pieces[`$direction]) }" = "foreach (`$direction in @('up','right','down','left')) { `$g.DrawPath(`$outline,`$pieces[`$direction]) }`n                foreach (`$direction in @('up','right','down','left')) { `$g.FillPath(`$white,`$pieces[`$direction]) }"
    "foreach (`$direction in @('up','right','down','left')) { `$g.FillPath(`$white,`$pieces[`$direction]) }" = @'
foreach ($direction in @('up','right','down','left')) { $g.FillPath($white,$pieces[$direction]) }
                # Copy the clean right half of the shared keycap art to the
                # left, so the vertical key edges cannot differ by a pixel.
                $g.Flush()
                for ($yy=$top; $yy -le $bottom; $yy++) {
                    for ($xx=$left; $xx -lt $cx; $xx++) {
                        $canvas.SetPixel($xx,$yy,$canvas.GetPixel([int](2*$cx-$xx),$yy))
                    }
                }
'@.TrimEnd()
    "'1.0.0-rc22'" = "'1.0.0-rc23'"
    '    $canvas.Save($png+' = @'
    # States with matching left/right arrows are mirror-symmetric in full.
    # The right side is the clean reference in the screenshot.
    if ($entry -in @('042','043','045','047','048')) {
        for ($yy=$top; $yy -le $bottom; $yy++) {
            for ($xx=$left; $xx -lt $cx; $xx++) {
                $canvas.SetPixel($xx,$yy,$canvas.GetPixel([int](2*$cx-$xx),$yy))
            }
        }
    }
    $canvas.Save($png+
'@.TrimEnd()
    'Staged RC22 symmetric four-key D-pad' = 'Staged RC23 quieter symmetric four-key D-pad'
}
foreach ($old in $changes.Keys) {
    if (-not $source.Contains($old)) { throw "RC22 script changed; missing expected text: $old" }
    $source = $source.Replace($old,$changes[$old])
}
$block = [ScriptBlock]::Create($source)
& $block -SourceMod $SourceMod -ResearchRoot $ResearchRoot -Output $Output
$readme = Join-Path $Output 'README.md'
$description = @'
`v1.0.0-rc23` keeps rc22's size and seven direction mappings. The white keycaps and dark outlines are rendered symmetrically, and the clean right edge is mirrored onto the left to remove the tiny mismatch on the up/down pieces. Inactive arrows are lighter gray; active arrows stay red. The Triangle glyph and Manual spacing are unchanged. This is a visual test candidate.
'@.Trim()
$readmeText = [IO.File]::ReadAllText($readme)
$readmeText = [Text.RegularExpressions.Regex]::Replace($readmeText,'Current package: `v1\.0\.0-rc22`[^\r\n]*','Current package: `v1.0.0-rc23` (pending in-game test)')
$readmeText = [Text.RegularExpressions.Regex]::Replace($readmeText,'(?s)(## Release status\s*).*','$1' + $description + [Environment]::NewLine)
[IO.File]::WriteAllText($readme,$readmeText)
