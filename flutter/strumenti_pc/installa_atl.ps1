# TraKer IA by mdls - installa il componente ATL di Visual Studio (serve all'exe).
# Usa l'installer nuovo scaricato da Microsoft (si aggiorna da solo) e riprova 3 volte.
# Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.

$ErrorActionPreference = 'Continue'
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$Atl = 'Microsoft.VisualStudio.Component.VC.ATL'

function HaAtl {
    if (-not (Test-Path $vswhere)) { return $false }
    $r = & $vswhere -products * -requires $Atl -property installationPath
    return [bool]$r
}

if (HaAtl) { Write-Host 'OK: ATL gia'' presente' -ForegroundColor Green; exit 0 }
if (-not (Test-Path $vswhere)) {
    Write-Host 'ERRORE: Visual Studio Build Tools non trovati. Lancia installa_flutter.bat.' -ForegroundColor Red
    exit 1
}
$vs = & $vswhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath | Select-Object -First 1
if (-not $vs) {
    Write-Host 'ERRORE: strumenti C++ non trovati. Lancia installa_flutter.bat.' -ForegroundColor Red
    exit 1
}

$boot = Join-Path $env:TEMP 'vs_buildtools_traker.exe'
for ($prova = 1; $prova -le 3; $prova++) {
    Write-Host ''
    Write-Host "=== Prova $prova di 3 ===" -ForegroundColor Cyan
    Write-Host 'Scarico installer Microsoft aggiornato...'
    & curl.exe -L --fail --retry 3 -o $boot 'https://aka.ms/vs/17/release/vs_buildtools.exe'
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Download fallito: riprovo tra 15 secondi.' -ForegroundColor Yellow
        Start-Sleep -Seconds 15
        continue
    }
    Write-Host 'Installo ATL (circa 5-10 minuti, stima).' -ForegroundColor Yellow
    Write-Host 'Windows chiedera'' il permesso (finestra "Consenti modifiche"): clicca Si''.' -ForegroundColor Yellow
    $argomenti = "modify --installPath `"$vs`" --add $Atl --passive --norestart --wait"
    $p = Start-Process -FilePath $boot -ArgumentList $argomenti -Verb RunAs -Wait -PassThru
    if (HaAtl) {
        Write-Host 'OK: ATL installato' -ForegroundColor Green
        Remove-Item $boot -Force -ErrorAction SilentlyContinue
        exit 0
    }
    Write-Host "Non riuscito (codice $($p.ExitCode)): riprovo tra 15 secondi." -ForegroundColor Yellow
    Start-Sleep -Seconds 15
}
Write-Host 'ERRORE: ATL non installato dopo 3 prove.' -ForegroundColor Red
Write-Host 'Controlla internet / VPN / antivirus. Log Microsoft in: %TEMP%\dd_*.log' -ForegroundColor Yellow
exit 1
