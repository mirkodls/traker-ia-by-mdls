@echo off
title TraKer IA by mdls - installa ATL
echo Installa il componente ATL di Visual Studio (serve per compilare l'exe).
echo Riprova da solo fino a 3 volte.
echo.
pause
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0installa_atl.ps1"
echo.
echo Se c'e' scritto OK: lancia compila_exe.bat. Chiudi questa finestra.
pause
