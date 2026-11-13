@echo off
title TraKer IA by mdls - compila exe
echo Compila l'exe Windows (versione finale, leggera).
echo Il risultato va in una cartella nuova: release\001, release\002, ...
echo Tempo: 2-6 minuti (stima). La prima volta di piu'.
echo.
echo PRIMA: se TraKer IA e' aperto, clic destro sull'icona vicino
echo all'orologio, poi Esci.
echo.
pause
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0compila_exe.ps1"
echo.
echo Chiudi questa finestra quando hai letto.
pause
