@echo off
title TraKer IA by mdls - misura RAM e CPU
echo Misura quanta memoria e CPU usa TraKer IA nascosto vicino all'orologio.
echo Tempo: 13 minuti (stima).
echo.
echo PRIMA: apri release\NUMERO PIU' ALTO\traker_ia.exe,
echo poi chiudilo con la X (resta acceso vicino all'orologio).
echo Durante la misura NON riaprire la finestra di TraKer IA.
echo.
pause
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0misura_ram.ps1"
echo.
echo Chiudi questa finestra quando hai letto.
pause
