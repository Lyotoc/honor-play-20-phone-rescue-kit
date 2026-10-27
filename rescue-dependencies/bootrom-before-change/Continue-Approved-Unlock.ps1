param([switch]$FreshBootrom, [switch]$WaitForDisconnect)
$ErrorActionPreference = 'Stop'
$taskToolDir = 'D:\honor-play-20-phone-rescue-kit\rescue-dependencies\honor-play-20-bootrom-flash'
$taskReadbackDir = Join-Path $PSScriptRoot 'fdl-readback'
$taskReadyFlag = Join-Path $PSScriptRoot 'stage1-verified.ready'
if (Test-Path -LiteralPath $taskReadyFlag) {
    throw 'A previous ready flag exists; inspect the saved session before starting.'
}
Push-Location -LiteralPath $taskToolDir
try {
    if ($WaitForDisconnect) {
        Write-Host 'Waiting for the current COM4 USB connection to be unplugged.'
        $taskWaitStart = [DateTime]::UtcNow
        while ($true) {
            $taskSerialMap = Get-ItemProperty -LiteralPath 'HKLM:\HARDWARE\DEVICEMAP\SERIALCOMM' -ErrorAction SilentlyContinue
            $taskComPresent = $null -ne $taskSerialMap -and @($taskSerialMap.PSObject.Properties | Where-Object { $_.Value -eq 'COM4' }).Count -gt 0
            if (-not $taskComPresent) { break }
            if (([DateTime]::UtcNow - $taskWaitStart).TotalMinutes -ge 5) { throw 'USB unplug wait timed out.' }
            Start-Sleep -Milliseconds 200
        }
    }
    if ($FreshBootrom) {
        & .\spd_dump.exe --wait 300 fdl .\fdl1-dl-patched.bin 0x5500 fdl .\fdl2-sign.bin 0x9efffe00 exec path $taskReadbackDir
    } else {
        & .\spd_dump.exe --reconnect path $taskReadbackDir
    }
    $taskFdlResult = $LASTEXITCODE
    if (-not (Test-Path -LiteralPath $taskReadyFlag)) {
        Write-Host 'No verified stage-one reset was requested; no startup payload sent.'
        exit $taskFdlResult
    }
    for ($taskPass = 1; $taskPass -le 2; $taskPass++) {
        Write-Host "Sending README startup payload, pass $taskPass of 2."
        # Provide a key for spd_dump's Windows pause if the booting phone disconnects.
        ' ' | & .\spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl .\spl-unlock.bin 0x5500
        Write-Host "Startup payload process exit code: $LASTEXITCODE"
    }
} finally {
    Pop-Location
}
