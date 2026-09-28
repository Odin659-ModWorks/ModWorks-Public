param(
    [string]$SourceMod = 'K:\EMULATORS\SWITCH\Eden\user\load\0100AE00096EA000\PlayStation Button Prompts v1.0.0-rc10',
    [string]$BuiltStation = 'K:\EMULATORS\SWITCH\Eden\user\cache\hwde-mod-research\button-work\cohesive-v1.0.0-build-rc11\station_ENG.g1t',
    [string]$Output = (Join-Path $PSScriptRoot '..\staging\PlayStation Button Prompts v1.0.0-rc11')
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $SourceMod -PathType Container)) { throw "Missing known-good source: $SourceMod" }
if (-not (Test-Path -LiteralPath $BuiltStation -PathType Leaf)) { throw "Missing staged D-pad archive: $BuiltStation" }
if (Test-Path -LiteralPath $Output) { throw "RC11 candidate already exists: $Output" }

Copy-Item -LiteralPath $SourceMod -Destination $Output -Recurse
$ui = Join-Path $Output 'romfs\data\ui'
Copy-Item -LiteralPath $BuiltStation -Destination (Join-Path $ui 'station_ENG.g1t.gz') -Force

# The three-byte Nintendo prompt escape was replaced by a custom glyph and
# two spaces in RC10. Bottom-bar strings add another space before each label.
# Keep every byte count and string offset unchanged; move two of the three
# post-icon spaces to the pre-icon side so icons read as prefixes to labels.
$messagePath = Join-Path $Output 'romfs\data\common\msgdata.bin'
$bytes = [IO.File]::ReadAllBytes($messagePath)
$icons = [byte[]]@(0x7b,0x7c,0x7d,0x7e,0x5e,0x5f)
$patched = 0
$strings = 0
$start = 0
for ($end = 0; $end -le $bytes.Length; $end++) {
    if ($end -lt $bytes.Length -and $bytes[$end] -ne 0) { continue }
    $length = $end - $start
    if ($length -gt 0 -and $length -lt 300) {
        $value = [Text.Encoding]::ASCII.GetString($bytes, $start, $length)
        if ($value.Contains('Select') -or $value.Contains('Return')) {
            $changed = $false
            for ($i = $start; $i -le $end - 5; $i++) {
                if (($bytes[$i] -in $icons) -and
                    $bytes[$i+1] -eq 0x20 -and $bytes[$i+2] -eq 0x20 -and
                    $bytes[$i+3] -eq 0x20 -and
                    (($bytes[$i+4] -ge 0x41 -and $bytes[$i+4] -le 0x5a) -or
                     ($bytes[$i+4] -ge 0x61 -and $bytes[$i+4] -le 0x7a))) {
                    $glyph = $bytes[$i]
                    $bytes[$i] = 0x20
                    $bytes[$i+1] = 0x20
                    $bytes[$i+2] = $glyph
                    $bytes[$i+3] = 0x20
                    $patched++
                    $changed = $true
                    $i += 3
                }
            }
            if ($changed) { $strings++ }
        }
    }
    $start = $end + 1
}
if ($patched -lt 20) { throw "Unexpectedly few menu prompts patched: $patched" }
[IO.File]::WriteAllBytes($messagePath, $bytes)
Set-Content -LiteralPath (Join-Path $Output 'VERSION.txt') -Value '1.0.0-rc11' -NoNewline
Write-Output "Staged RC11: $Output"
Write-Output "Aligned $patched icon markers in $strings Select/Return menu strings."
