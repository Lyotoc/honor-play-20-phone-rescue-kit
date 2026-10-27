$ErrorActionPreference = 'Stop'
$testRoot = $PSScriptRoot
$toolRoot = Join-Path (Split-Path $testRoot -Parent) 'honor-play-20-bootrom-flash'
Write-Host 'This restores the previously working tethered boot state by clearing both SPL slots.'
Write-Host 'Connect this HONOR Play 20 in BROM download mode. Physical test point may be needed.'
Push-Location $toolRoot
try {
    & .\spd_dump.exe --wait 300 fdl .\fdl1-dl-patched.bin 0x5500 fdl .\fdl2-sign.bin 0x9efffe00 exec e splloader e splloader_bak reset
    if ($LASTEXITCODE -ne 0) { throw 'FDL rollback did not finish; inspect tool output before retrying.' }
    ' ' | & .\spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl .\spl-unlock.bin 0x5500
} finally {
    Pop-Location
}
