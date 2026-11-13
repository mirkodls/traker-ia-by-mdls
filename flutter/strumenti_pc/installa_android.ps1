$ErrorActionPreference = 'Stop'
function Passo($t) { Write-Host ""; Write-Host "=== $t ===" -ForegroundColor Cyan }
try {
  $sdk = Join-Path $env:LOCALAPPDATA 'Android\sdk'
  if (-not (Test-Path $sdk)) { throw "Android SDK non trovato in $sdk" }

  Passo '1/4 Java'
  $jbr = 'C:\Program Files\Android\Android Studio\jbr'
  if (Test-Path (Join-Path $jbr 'bin\java.exe')) {
    $env:JAVA_HOME = $jbr; Write-Host 'OK: uso Java di Android Studio'
  } elseif (Get-Command java -ErrorAction SilentlyContinue) {
    Write-Host 'OK: Java gia presente'
  } else {
    Write-Host 'Installo Java 21 (Microsoft OpenJDK)...'
    winget install -e --id Microsoft.OpenJDK.21 --accept-package-agreements --accept-source-agreements
    $j = Get-ChildItem 'C:\Program Files\Microsoft' -Directory -Filter 'jdk-21*' -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $j) { throw 'Java non installato' }
    $env:JAVA_HOME = $j.FullName
  }
  if ($env:JAVA_HOME) {
    $env:Path = (Join-Path $env:JAVA_HOME 'bin') + ';' + $env:Path
    [Environment]::SetEnvironmentVariable('JAVA_HOME', $env:JAVA_HOME, 'User')
  }

  Passo '2/4 cmdline-tools'
  $dest = Join-Path $sdk 'cmdline-tools\latest'
  if (Test-Path (Join-Path $dest 'bin\sdkmanager.bat')) {
    Write-Host 'OK: gia presenti'
  } else {
    $z = Join-Path $env:TEMP 'cmdtools.zip'; $t = Join-Path $env:TEMP 'cmdtools_x'
    Write-Host 'Scarico (circa 150 MB)...'
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest 'https://dl.google.com/android/repository/commandlinetools-win-13114758_latest.zip' -OutFile $z
    if (Test-Path $t) { Remove-Item $t -Recurse -Force }
    Write-Host 'Estraggo...'
    Expand-Archive $z $t
    New-Item -ItemType Directory -Force (Join-Path $sdk 'cmdline-tools') | Out-Null
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    Move-Item (Join-Path $t 'cmdline-tools') $dest
    Remove-Item $z, $t -Recurse -Force
    Write-Host 'OK: cmdline-tools installati'
  }

  Passo '3/4 Variabili'
  [Environment]::SetEnvironmentVariable('ANDROID_HOME', $sdk, 'User')
  $env:ANDROID_HOME = $sdk
  & flutter config --android-sdk $sdk
  Write-Host 'OK'

  Passo '4/4 Licenze Android'
  Write-Host 'Ti chiede piu volte (y/N): scrivi  y  e premi Invio ogni volta.' -ForegroundColor Yellow
  & flutter doctor --android-licenses
  & flutter doctor
  Write-Host ''
  Write-Host 'Fatto. "Android toolchain" deve avere la spunta [v]. Chrome [X] va bene.' -ForegroundColor Green
} catch {
  Write-Host ''
  Write-Host ("ERRORE: " + $_.Exception.Message) -ForegroundColor Red
  Write-Host 'Copia queste righe alla chat.'
}
