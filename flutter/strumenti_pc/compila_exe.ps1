# TraKer IA by mdls - compila l'exe Windows e lo copia in release\NNN.
# Lanciato da compila_exe.bat. Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.

$ErrorActionPreference = 'Continue'
$Radice = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$App = Join-Path $Radice 'flutter\app_flutter'
$Release = Join-Path $Radice 'release'
$Log = Join-Path $App 'compila.txt'
$Uscita = Join-Path $App 'build\windows\x64\runner\Release'

function Passo($testo) { Write-Host ''; Write-Host "=== $testo ===" -ForegroundColor Cyan }
function Ok($testo) { Write-Host "OK: $testo" -ForegroundColor Green }
function Ferma($testo) {
    Write-Host "ERRORE: $testo" -ForegroundColor Red
    Write-Host "Dettagli in: $Log" -ForegroundColor Yellow
    Write-Host 'Scrivi nella chat: "errore compila".' -ForegroundColor Yellow
    exit 1
}

"=== compila $(Get-Date -Format 'yyyy-MM-dd HH:mm') ===" | Out-File -FilePath $Log -Encoding Unicode

# 1. App gia' aperta? (una sola copia: la nuova non partirebbe)
Passo '1/5 Controllo app aperta'
if (Get-Process -Name 'traker_ia' -ErrorAction SilentlyContinue) {
    Ferma 'TraKer IA e'' aperto. Clic destro sull''icona vicino all''orologio > Esci, poi rilancia.'
}
Ok 'nessuna copia aperta'

# 2. Flutter nel PATH
Passo '2/5 Controllo Flutter'
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Ferma 'Flutter non trovato. Lancia prima installa_flutter.bat (poi apri una finestra nuova).'
}
Ok 'Flutter presente'

# 3. ATL di Visual Studio (serve alla cassaforte del cookie)
Passo '3/5 Controllo componente ATL di Visual Studio'
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) { Ferma 'Visual Studio Build Tools non trovati. Lancia installa_flutter.bat.' }
$conAtl = & $vswhere -products * -requires Microsoft.VisualStudio.Component.VC.ATL -property installationPath
if ($conAtl) {
    Ok 'ATL presente'
} else {
    Write-Host 'Manca ATL: lo installo.' -ForegroundColor Yellow
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'installa_atl.ps1')
    if ($LASTEXITCODE -ne 0) { Ferma 'ATL non installato. Vedi messaggi sopra.' }
    Ok 'ATL installato'
}

# 3b. Modalita' sviluppatore di Windows (Flutter ne ha bisogno per i plugin)
$chiaveSvil = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
$svil = (Get-ItemProperty -Path $chiaveSvil -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
if ($svil -eq 1) {
    Ok 'Modalita'' sviluppatore attiva'
} else {
    Write-Host 'Attivo la Modalita'' sviluppatore di Windows.' -ForegroundColor Yellow
    Write-Host 'Windows chiedera'' il permesso (finestra "Consenti modifiche"): clicca Si''.' -ForegroundColor Yellow
    $cmd = 'reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense /t REG_DWORD /d 1 /f'
    Start-Process -FilePath 'cmd.exe' -ArgumentList "/c $cmd" -Verb RunAs -Wait
    $svil = (Get-ItemProperty -Path $chiaveSvil -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
    if ($svil -ne 1) { Ferma 'Modalita'' sviluppatore non attivata (permesso negato). Rilancia e clicca Si''.' }
    Ok 'Modalita'' sviluppatore attivata'
}

# 4. Compila
Passo '4/5 Compilo (qualche minuto)'
Set-Location $App
& flutter pub get 2>&1 | Tee-Object -FilePath $Log -Append
if ($LASTEXITCODE -ne 0) { Ferma 'flutter pub get fallito.' }
& flutter build windows --release --obfuscate --split-debug-info=build\simboli --tree-shake-icons 2>&1 | Tee-Object -FilePath $Log -Append
if ($LASTEXITCODE -ne 0) { Ferma 'compilazione fallita.' }
if (-not (Test-Path (Join-Path $Uscita 'traker_ia.exe'))) { Ferma 'traker_ia.exe non trovato dopo la compilazione.' }
Ok 'compilato'

# 5. Copia in release\NNN (numero nuovo, le vecchie restano)
Passo '5/5 Copio in release'
New-Item -ItemType Directory -Force -Path $Release | Out-Null
$n = 1
while (Test-Path (Join-Path $Release ('{0:D3}' -f $n))) { $n++ }
$Nome = '{0:D3}' -f $n
$Dest = Join-Path $Release $Nome
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
Copy-Item -Path (Join-Path $Uscita '*') -Destination $Dest -Recurse -Force
# Simboli per leggere eventuali errori: a parte, NON da distribuire.
$Simboli = Join-Path $Release ("simboli\" + $Nome)
New-Item -ItemType Directory -Force -Path $Simboli | Out-Null
Copy-Item -Path (Join-Path $App 'build\simboli\*') -Destination $Simboli -Recurse -Force -ErrorAction SilentlyContinue
$mb = [math]::Round(((Get-ChildItem $Dest -Recurse | Measure-Object Length -Sum).Sum / 1MB), 1)
"release $Nome, $mb MB" | Out-File -FilePath $Log -Append -Encoding Unicode
Ok "release\$Nome ($mb MB)"

Write-Host ''
Write-Host "FATTO. L'exe e': release\$Nome\traker_ia.exe" -ForegroundColor Green
Write-Host 'Si apre la cartella. Scrivi nella chat: "compilato".' -ForegroundColor Green
Start-Process explorer.exe $Dest
