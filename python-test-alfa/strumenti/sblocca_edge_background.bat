@echo off
net session >nul 2>&1 || (powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs" & exit /b)
set "K=HKLM\SOFTWARE\Policies\Microsoft\Edge"
echo Copia di sicurezza delle regole di Edge in: %~dp0backup_regole_edge.reg
reg export "%K%" "%~dp0backup_regole_edge.reg" /y >nul 2>&1
reg delete "%K%" /v BackgroundModeEnabled /f >nul 2>&1
reg delete "%K%" /v StartupBoostEnabled /f >nul 2>&1
echo.
echo FATTO. Tolte solo 2 regole: BackgroundModeEnabled e StartupBoostEnabled.
echo Ora chiudi TUTTE le finestre di Edge e riaprilo.
echo Poi vai su edge://settings/system e accendi le 2 opzioni.
pause
