@echo off
title TraKer IA by mdls - misura batteria telefono
echo Misura quanta batteria usa TraKer IA sul telefono in 24 ore.
echo Serve: cavo USB + "Debug USB" acceso sul telefono (guida nella chat).
echo.
echo  1 = INIZIO misura (telefono attaccato col cavo)
echo  2 = FINE misura (dopo circa 24 ore, riattacca il cavo e scegli SUBITO 2)
echo.
choice /c 12 /n /m "Scegli 1 o 2: "
if errorlevel 2 (set FASE=fine) else (set FASE=inizio)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0misura_batteria.ps1" %FASE%
echo.
echo Chiudi questa finestra quando hai letto.
pause
