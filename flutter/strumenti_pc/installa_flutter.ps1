# TraKer IA by mdls - installa Git, Visual Studio Build Tools (C++) e Flutter sul PC.
# Lanciato da installa_flutter.bat. Si puo' rilanciare: salta cio' che c'e' gia'.
# Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.

$ErrorActionPreference = 'Stop'
$VersioneFlutter = '3.50.0'
$CartellaSrc = 'C:\src'
$CartellaFlutter = Join-Path $CartellaSrc 'flutter'
$BinFlutter = Join-Path $CartellaFlutter 'bin'

function Passo($testo) { Write-Host ''; Write-Host "=== $testo ===" -ForegroundColor Cyan }
function Ok($testo) { Write-Host "OK: $testo" -ForegroundColor Green }
function Ferma($testo) { Write-Host "ERRORE: $testo" -ForegroundColor Red; exit 1 }

# 0. winget
Passo '0/5 Controllo winget'
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Ferma 'winget non trovato. Apri Microsoft Store, cerca "Programma di installazione app", aggiornalo, poi rilancia.'
}
Ok 'winget presente'

# 1. Git (serve a Flutter)
Passo '1/5 Git'
if (Get-Command git -ErrorAction SilentlyContinue) {
    Ok 'Git gia'' installato'
} else {
    winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
    Ok 'Git installato'
}

# 2. Visual Studio Build Tools 2022 con C++ (serve per l'exe Windows)
Passo '2/5 Visual Studio Build Tools (C++) - lungo, circa 6-8 GB'
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$haCpp = $false
if (Test-Path $vswhere) {
    $trovato = & $vswhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($trovato) { $haCpp = $true }
}
if ($haCpp) {
    Ok 'Strumenti C++ gia'' installati'
} else {
    Write-Host 'Windows chiedera'' il permesso (finestra "Consenti modifiche"): clicca Si''.' -ForegroundColor Yellow
    winget install --id Microsoft.VisualStudio.2022.BuildTools -e --accept-package-agreements --accept-source-agreements --override "--passive --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
    Ok 'Build Tools installati'
}

# 3. Flutter (versione fissa, uguale a quella usata nel cloud)
Passo "3/5 Flutter $VersioneFlutter - download circa 1,9 GB"
if (Test-Path (Join-Path $BinFlutter 'flutter.bat')) {
    Ok "Flutter gia' presente in $CartellaFlutter"
} else {
    New-Item -ItemType Directory -Force -Path $CartellaSrc | Out-Null
    $zip = Join-Path $env:TEMP "flutter_windows_$VersioneFlutter-stable.zip"
    $url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_$VersioneFlutter-stable.zip"
    Write-Host "Scarico $url"
    & curl.exe -L --fail -o $zip $url
    if ($LASTEXITCODE -ne 0) { Ferma 'download Flutter fallito. Controlla internet e rilancia.' }
    Write-Host 'Estraggo (qualche minuto)...'
    & tar.exe -xf $zip -C $CartellaSrc
    if ($LASTEXITCODE -ne 0) { Ferma 'estrazione fallita.' }
    Remove-Item $zip -Force
    Ok "Flutter estratto in $CartellaFlutter"
}

# 4. PATH utente
Passo '4/5 PATH'
$pathUtente = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($pathUtente -notlike "*$BinFlutter*") {
    [Environment]::SetEnvironmentVariable('Path', ($pathUtente.TrimEnd(';') + ';' + $BinFlutter), 'User')
    Ok "Aggiunto $BinFlutter al PATH"
} else {
    Ok 'PATH gia'' a posto'
}
$env:Path = $env:Path + ';' + $BinFlutter

# 5. Configurazione e controllo
Passo '5/5 Controllo finale (flutter doctor)'
& flutter config --no-analytics | Out-Null
& flutter config --enable-windows-desktop | Out-Null
& flutter precache --windows
& flutter doctor -v

Write-Host ''
Write-Host 'ULTIMO PASSO A MANO: attiva la Modalita'' sviluppatore di Windows.' -ForegroundColor Yellow
Write-Host 'Si apre Impostazioni: accendi "Modalita'' sviluppatore" (serve a Flutter per i plugin).' -ForegroundColor Yellow
Start-Process 'ms-settings:developers'
Write-Host ''
Write-Host 'Fatto. Nel controllo sopra: "Windows Version" e "Visual Studio" devono avere la spunta [v].' -ForegroundColor Green
Write-Host 'Android Studio / Chrome con [X] o [!] vanno bene: non servono adesso.' -ForegroundColor Green
