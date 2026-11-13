@echo off
echo Completa Android sul PC: cmdline-tools + licenze. Circa 300 MB, 5-15 minuti (stima).
echo Puoi rilanciarlo: salta cio' che c'e' gia'.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0installa_android.ps1"
echo.
pause
