@echo off
rem TraKer IA by mdls - controllo completo: pacchetti, codice database, lint, test.
rem Risultato in app_flutter\controllo.txt
cd /d "%~dp0..\app_flutter"
echo Controllo in corso, aspetta (anche 2-5 minuti la prima volta)...
echo === pub get === > controllo.txt
call flutter pub get >> controllo.txt 2>&1
echo === build_runner === >> controllo.txt
call dart run build_runner build >> controllo.txt 2>&1
echo === analyze === >> controllo.txt
call flutter analyze --fatal-infos --fatal-warnings >> controllo.txt 2>&1
echo === test === >> controllo.txt
call flutter test --reporter expanded >> controllo.txt 2>&1
echo === fine === >> controllo.txt
echo.
echo FATTO. Scrivi "fatto" nella chat.
pause
