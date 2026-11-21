@echo off
title TraKer IA by mdls - compila APK telefono
echo Compila l'APK Android (versione finale, firmata con la tua chiave).
echo Il risultato va in una cartella nuova: release\019, release\020, ...
echo Tempo: 3-10 minuti (stima). La prima volta di piu'.
echo.
echo Serve: Flutter + Android SDK (se manca: installa_android.bat).
echo La chiave di firma resta SOLO sul PC (cartella firma-backup).
echo.
pause
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0compila_apk.ps1"
echo.
echo Chiudi questa finestra quando hai letto.
pause
