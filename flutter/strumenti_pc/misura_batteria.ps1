# TraKer IA by mdls - misura batteria del telefono (Android batterystats via adb).
# Lanciato da misura_batteria.bat con "inizio" o "fine".
# Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
# Numeri = STIMA di Android (non un misuratore vero). Obiettivo B22: <= 1% al giorno.
param([string]$Fase = 'inizio')

$ErrorActionPreference = 'Continue'
$Radice = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Release = Join-Path $Radice 'release'
$FileInizio = Join-Path $Release 'misura_batteria_inizio.txt'
$FileEsito = Join-Path $Release 'misura_batteria.txt'
$Pacchetto = 'mdls.traker_ia'

function Ok($t) { Write-Host "OK: $t" -ForegroundColor Green }
function Ferma($t) { Write-Host "ERRORE: $t" -ForegroundColor Red; exit 1 }

# 1. adb (Android SDK, lo stesso di compila_apk)
$Sdk = $env:ANDROID_HOME
if (-not $Sdk -or -not (Test-Path $Sdk)) { $Sdk = Join-Path $env:LOCALAPPDATA 'Android\sdk' }
$Adb = Join-Path $Sdk 'platform-tools\adb.exe'
if (-not (Test-Path $Adb)) { Ferma "adb non trovato in $Adb. Lancia prima installa_android.bat." }

# 2. telefono collegato e autorizzato
& $Adb start-server | Out-Null
$Righe = (& $Adb devices) | Select-Object -Skip 1 | Where-Object { $_ -match '\S' }
if (-not $Righe) { Ferma 'Nessun telefono. Attacca il cavo e accendi Debug USB.' }
if ($Righe -match 'unauthorized') { Ferma 'Sul telefono tocca "Consenti" (debug USB), poi rilancia.' }
if (@($Righe).Count -gt 1) { Ferma 'Piu di un dispositivo collegato (emulatori aperti?): chiudili e rilancia.' }
Ok 'telefono collegato'

$Uid = ((& $Adb shell pm list packages -U $Pacchetto) -join ' ')
if ($Uid -notmatch 'uid:(\d+)') { Ferma 'TraKer IA non installato sul telefono.' }
$NumUid = [int]$Matches[1]
$NomeUid = 'u0a' + ($NumUid - 10000)
$Livello = ((& $Adb shell dumpsys battery) -join "`n")
$Perc = if ($Livello -match 'level:\s*(\d+)') { [int]$Matches[1] } else { -1 }

if ($Fase -eq 'inizio') {
    & $Adb shell dumpsys batterystats --reset | Out-Null
    "$(Get-Date -Format o)|$Perc" | Out-File -FilePath $FileInizio -Encoding ascii
    Ok "conteggio batteria azzerato (batteria ora: $Perc%)"
    Write-Host ''
    Write-Host 'ADESSO: stacca il cavo e usa il telefono come sempre per circa 24 ore.' -ForegroundColor Yellow
    Write-Host 'NON caricare il telefono in queste 24 ore (la carica azzera il conteggio).' -ForegroundColor Yellow
    Write-Host 'Poi riattacca il cavo e lancia di nuovo misura_batteria.bat, scegli 2 SUBITO.' -ForegroundColor Yellow
    exit 0
}

# 3. fine: legge la stima di Android
if (-not (Test-Path $FileInizio)) { Ferma 'Manca l''inizio: lancia prima con 1.' }
$Ini = (Get-Content $FileInizio -Raw).Trim().Split('|')
$Ore = ((Get-Date) - [datetime]::Parse($Ini[0])).TotalHours
$Testo = ((& $Adb shell dumpsys batterystats --charged $Pacchetto) -join "`n")
$Cap = if ($Testo -match 'Capacity:\s*([\d.]+)') { [double]$Matches[1] } else { 3900 }
$Riga = [regex]::Match($Testo, "(?m)^\s*UID $NomeUid\s*:\s*([\d.,]+)")
if (-not $Riga.Success) { Ferma "Nessun consumo trovato per $NomeUid (app mai partita?). Riprova piu tardi." }
$mAh = [double]($Riga.Groups[1].Value.Replace(',', '.'))
$PercApp = $mAh / $Cap * 100
$AlGiorno = if ($Ore -gt 0.5) { $PercApp * 24 / $Ore } else { 0 }
$Esito = "{0} | ore={1:N1} | app={2:N2} mAh su {3} mAh | {4:N2}% nel periodo | {5:N2}% al giorno (STIMA Android) | batteria {6}% -> {7}%" -f `
    (Get-Date -Format 'yyyy-MM-dd HH:mm'), $Ore, $mAh, $Cap, $PercApp, $AlGiorno, $Ini[1], $Perc
$Esito | Out-File -FilePath $FileEsito -Append -Encoding utf8
Write-Host ''
Write-Host $Esito
if ($AlGiorno -le 1) { Ok 'sotto 1% al giorno: obiettivo raggiunto' }
else { Write-Host 'Sopra 1% al giorno: incolla questa riga nella chat.' -ForegroundColor Yellow }
Write-Host "Salvato in: $FileEsito"
