$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $projectRoot 'mod\Immediate Enemy Loot v1.0.0'
$installRoot = 'K:\EMULATORS\SWITCH\Eden\user\load\0100AE00096EA000'
$destination = Join-Path $installRoot 'Immediate Enemy Loot v1.0.0'
$releaseRoot = 'K:\EMULATORS\SWITCH\Eden\user\cache\hwde-mod-research\release-packages'
$archive = Join-Path $releaseRoot 'HWDE-Immediate-Enemy-Loot-v1.0.0.zip'

if (-not (Test-Path -LiteralPath $source)) {
    throw "Missing source folder: $source"
}
if (Test-Path -LiteralPath $destination) {
    throw "Destination already exists; refusing to overwrite: $destination"
}
if (Test-Path -LiteralPath $archive) {
    throw "Release archive already exists; refusing to overwrite: $archive"
}

New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
Copy-Item -LiteralPath $source -Destination $destination -Recurse

New-Item -ItemType Directory -Path $releaseRoot -Force | Out-Null
Compress-Archive -LiteralPath $source -DestinationPath $archive -CompressionLevel Optimal

$expected = @'
[HWDE Immediate Enemy Loot]
04000000 001D9A94 1408821C
04000000 003FA304 A9BF7BFD
04000000 003FA308 910003FD
04000000 003FA30C 2A1503E0
04000000 003FA310 2A1F03E1
04000000 003FA314 320003E2
04000000 003FA318 AA1F03E3
04000000 003FA31C 97F77F0E
04000000 003FA320 AA1B03E0
04000000 003FA324 97F57D35
04000000 003FA328 A8C17BFD
04000000 003FA32C 17F77DDC
'@
$expected = $expected.TrimStart("`r", "`n") + "`n"
$installedCheat = Join-Path $destination 'cheats\815A2C19D1767896.txt'
$actual = [IO.File]::ReadAllText($installedCheat).Replace("`r`n", "`n")
if ($actual -ne $expected) {
    throw 'Installed cheat file failed exact-content verification.'
}

Get-FileHash -Algorithm SHA256 -LiteralPath $installedCheat, $archive
