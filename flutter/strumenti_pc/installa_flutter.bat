@echo off
title TraKer IA by mdls - installa Flutter
echo Installa Git, Visual Studio Build Tools (C++) e Flutter.
echo Spazio su disco: circa 10 GB. Tempo: 30-60 minuti (stima).
echo Puoi rilanciarlo: salta cio' che c'e' gia'.
echo.
pause
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0installa_flutter.ps1"
echo.
echo Chiudi questa finestra quando hai letto.
pause
