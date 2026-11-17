# TraKer IA by mdls - misura RAM e CPU dell'exe nascosto nel tray.
# Lanciato da misura_ram.bat. Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
# Budget (ORDINI V2): RAM <= 80 MB, CPU ~0% tra le letture.

$ErrorActionPreference = 'Continue'
$Radice = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Uscita = Join-Path $Radice 'release\misura_ram.txt'
$AttesaMin = 12
$LimiteMb = 80

function Processo { Get-Process -Name 'traker_ia' -ErrorAction SilentlyContinue | Select-Object -First 1 }

function RamMb($id) {
    # "Memoria" di Gestione attivita' = working set privato: mai piu' del working set.
    # B15: PrivateMemorySize64 = memoria riservata (non RAM): NON usarla come RAM.
    $p = Get-Process -Id $id -ErrorAction SilentlyContinue
    if (-not $p) { return $null }
    $ws = [math]::Round($p.WorkingSet64 / 1MB, 1)
    $w = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfProc_Process -ErrorAction SilentlyContinue |
        Where-Object { $_.IDProcess -eq $id } | Select-Object -First 1
    if ($w -and $w.WorkingSetPrivate -gt 0) {
        $priv = [math]::Round($w.WorkingSetPrivate / 1MB, 1)
        if ($priv -le $ws) { return $priv }
    }
    return $ws
}

$p = Processo
if (-not $p) {
    Write-Host 'TraKer IA non e'' aperto.' -ForegroundColor Red
    Write-Host 'Apri release\<numero piu'' alto>\traker_ia.exe, chiudilo con la X (va vicino all''orologio), poi rilancia misura_ram.bat.' -ForegroundColor Yellow
    exit 1
}

Write-Host "Attendo $AttesaMin minuti (pulizia memoria a 10). Non riaprire la finestra di TraKer IA." -ForegroundColor Cyan
for ($m = $AttesaMin; $m -gt 0; $m--) {
    Write-Host "  mancano $m min..."
    Start-Sleep -Seconds 60
    if (-not (Processo)) { Write-Host 'TraKer IA si e'' chiuso durante l''attesa.' -ForegroundColor Red; exit 1 }
}

$p = Processo
$ram = RamMb $p.Id
$c1 = $p.TotalProcessorTime.TotalSeconds
$t1 = Get-Date
Start-Sleep -Seconds 60
$p = Processo
$c2 = $p.TotalProcessorTime.TotalSeconds
$sec = ((Get-Date) - $t1).TotalSeconds
$cpu = [math]::Round((($c2 - $c1) / ($sec * [Environment]::ProcessorCount)) * 100, 2)
$ram2 = RamMb $p.Id
$ws = [math]::Round($p.WorkingSet64 / 1MB, 1)
$riservata = [math]::Round($p.PrivateMemorySize64 / 1MB, 1)

$esito = if ($null -ne $ram -and $ram -le $LimiteMb -and $ram2 -le $LimiteMb -and $cpu -lt 1) { 'OK' } else { 'TROPPO' }
$riga = "$(Get-Date -Format 'yyyy-MM-dd HH:mm') ram=${ram}MB poi ${ram2}MB working_set=${ws}MB riservata=${riservata}MB cpu_media_60s=${cpu}% limite=${LimiteMb}MB esito=$esito"
$riga | Out-File -FilePath $Uscita -Append -Encoding UTF8

Write-Host ''
Write-Host "RAM (come Gestione attivita'): $ram MB, dopo 1 min $ram2 MB" -ForegroundColor White
Write-Host "Memoria riservata (non e' RAM, solo info): $riservata MB" -ForegroundColor Gray
Write-Host "CPU media 1 minuto: $cpu %" -ForegroundColor White
if ($esito -eq 'OK') { Write-Host 'ESITO: OK (leggera).' -ForegroundColor Green } else { Write-Host 'ESITO: TROPPO (scrivilo nella chat).' -ForegroundColor Red }
Write-Host "Salvato in: $Uscita"
