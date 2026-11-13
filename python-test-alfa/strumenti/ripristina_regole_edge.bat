@echo off
net session >nul 2>&1 || (powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs" & exit /b)
set "K=HKLM\SOFTWARE\Policies\Microsoft\Edge"
reg add "%K%" /v BackgroundModeEnabled /t REG_DWORD /d 0 /f >nul
reg add "%K%" /v StartupBoostEnabled /t REG_DWORD /d 0 /f >nul
echo FATTO. Regole di Edge rimesse come prima. Riavvia Edge.
pause
