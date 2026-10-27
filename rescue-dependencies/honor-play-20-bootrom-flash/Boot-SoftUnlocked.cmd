@echo off
setlocal
pushd "%~dp0"
echo Waiting for the configured HONOR Play 20 in download mode.
echo This sends the repository SPL payload to RAM; it does not flash a partition.
echo. | spd_dump.exe --wait 300 exec_addr 0x3ee8 fdl spl-unlock.bin 0x5500
set taskBootResult=%errorlevel%
echo.
echo After EXEC FDL1, a USB disconnect error can occur while the phone starts.
echo Check the phone screen; allow time for Android to finish starting.
popd
pause
exit /b %taskBootResult%
