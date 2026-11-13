param([switch]$Togli)
$lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'Traker Claude.lnk'
if ($Togli) {
  Remove-Item $lnk -ErrorAction SilentlyContinue
  Write-Host "Avvio automatico TOLTO."
  exit 0
}
$dir = Split-Path -Parent $PSScriptRoot
$pyw = (Get-Command pythonw -ErrorAction SilentlyContinue).Source
if (-not $pyw) { Write-Host "Python non trovato. Installa Python 3.12 da Microsoft Store."; exit 1 }
$s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
$s.TargetPath = $pyw
$s.Arguments = '"' + (Join-Path $dir 'app.pyw') + '" --ridotto'
$s.WorkingDirectory = $dir
$s.WindowStyle = 7
$s.Save()
Write-Host "Avvio automatico ATTIVO: il traker parte da solo all'accensione (ridotto a icona)."
