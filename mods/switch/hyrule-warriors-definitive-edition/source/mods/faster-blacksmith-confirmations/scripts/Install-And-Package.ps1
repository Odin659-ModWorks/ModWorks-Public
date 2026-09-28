$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $projectRoot 'mod\Faster Blacksmith Confirmations v1.0.0'
$installRoot = 'K:\EMULATORS\SWITCH\Eden\user\load\0100AE00096EA000'
$destination = Join-Path $installRoot 'Faster Blacksmith Confirmations v1.0.0'
$releaseRoot = 'K:\EMULATORS\SWITCH\Eden\user\cache\hwde-mod-research\release-packages'
$archive = Join-Path $releaseRoot 'HWDE-Faster-Blacksmith-Confirmations-v1.0.0.zip'

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
[HWDE Faster Blacksmith Confirmations]
04000000 0036EFBC 320003E0
04000000 0036EFCC 320003E0
'@
$expected = $expected.TrimStart("`r", "`n") + "`n"
$installedCheat = Join-Path $destination 'cheats\815A2C19D1767896.txt'
$actual = [IO.File]::ReadAllText($installedCheat).Replace("`r`n", "`n")
if ($actual -ne $expected) {
    throw 'Installed cheat file failed exact-content verification.'
}

Get-FileHash -Algorithm SHA256 -LiteralPath $installedCheat, $archive
