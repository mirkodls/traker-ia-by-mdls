@echo off
cd /d "%~dp0"
where pythonw >nul 2>nul
if errorlevel 1 (
  echo Python non trovato.
  echo Installalo da Microsoft Store: cerca "Python 3.12" e premi Installa.
  echo Poi rifai doppio clic su avvia.bat
  pause
  exit /b 1
)
start "" pythonw app.pyw
