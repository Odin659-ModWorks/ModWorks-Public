param(
    [string]$SourceMod = 'K:\EMULATORS\SWITCH\Eden\user\load\0100AE00096EA000\PlayStation Button Prompts v1.0.0-rc11',
    [string]$BuiltStation = 'K:\EMULATORS\SWITCH\Eden\user\cache\hwde-mod-research\button-work\cohesive-v1.0.0-build-rc12\station_ENG.g1t',
    [string]$Output = (Join-Path $PSScriptRoot '..\staging\PlayStation Button Prompts v1.0.0-rc12')
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $SourceMod -PathType Container)) { throw "Missing RC11 source: $SourceMod" }
if (-not (Test-Path -LiteralPath $BuiltStation -PathType Leaf)) { throw "Missing D-pad archive: $BuiltStation" }
if (Test-Path -LiteralPath $Output) { throw "RC12 candidate already exists: $Output" }

Copy-Item -LiteralPath $SourceMod -Destination $Output -Recurse
Copy-Item -LiteralPath $BuiltStation -Destination (Join-Path $Output 'romfs\data\ui\station_ENG.g1t.gz') -Force

# RC11 has two spaces before each icon and one after. Shift it back by one
# position, leaving one before and two after. File and string lengths stay put.
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
                if ($bytes[$i] -eq 0x20 -and $bytes[$i+1] -eq 0x20 -and
                    ($bytes[$i+2] -in $icons) -and $bytes[$i+3] -eq 0x20 -and
                    (($bytes[$i+4] -ge 0x41 -and $bytes[$i+4] -le 0x5a) -or
                     ($bytes[$i+4] -ge 0x61 -and $bytes[$i+4] -le 0x7a))) {
                    $glyph = $bytes[$i+2]
                    $bytes[$i+1] = $glyph
                    $bytes[$i+2] = 0x20
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
if ($patched -ne 262 -or $strings -ne 109) {
    throw "Unexpected menu marker coverage: $patched icons in $strings strings"
}
[IO.File]::WriteAllBytes($messagePath, $bytes)
Set-Content -LiteralPath (Join-Path $Output 'VERSION.txt') -Value '1.0.0-rc12' -NoNewline
Write-Output "Staged RC12: $Output"
Write-Output "Repositioned $patched icons in $strings menu strings."
