# TraKer IA by mdls - compila l'APK Android firmato e lo copia in release\NNN.
# Lanciato da compila_apk.bat. Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
# La chiave di firma resta SOLO sul PC (firma-backup): mai nel repo, mai nel log.

$ErrorActionPreference = 'Continue'
$Radice = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$App = Join-Path $Radice 'flutter\app_flutter'
$Release = Join-Path $Radice 'release'
$Firma = Join-Path $Radice 'firma-backup'
$FileFirma = Join-Path $Firma 'firma.properties'
$Chiave = Join-Path $Firma 'traker-ia.jks'
$Log = Join-Path $App 'compila_apk.txt'
$Versione = '2.3.0'
$Uscita = Join-Path $App 'build\app\outputs\flutter-apk\app-release.apk'
# Impronta SHA-256 della chiave vera (firma-backup\LEGGIMI.txt).
$ImprontaInizio = 'e3bd59'
$ImprontaFine = 'ee08'

function Passo($testo) { Write-Host ''; Write-Host "=== $testo ===" -ForegroundColor Cyan }
function Ok($testo) { Write-Host "OK: $testo" -ForegroundColor Green }
function Ferma($testo) {
    Write-Host "ERRORE: $testo" -ForegroundColor Red
    Write-Host "Dettagli in: $Log" -ForegroundColor Yellow
    Write-Host 'Scrivi nella chat: "errore compila apk".' -ForegroundColor Yellow
    $env:TRAKER_FIRMA = $null
    exit 1
}

"=== compila apk $(Get-Date -Format 'yyyy-MM-dd HH:mm') ===" | Out-File -FilePath $Log -Encoding Unicode

# 1. Flutter nel PATH
Passo '1/6 Controllo Flutter'
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Ferma 'Flutter non trovato. Lancia prima installa_flutter.bat (poi apri una finestra nuova).'
}
Ok 'Flutter presente'

# 2. Android SDK + Java
Passo '2/6 Controllo Android SDK e Java'
$Sdk = $env:ANDROID_HOME
if (-not $Sdk -or -not (Test-Path $Sdk)) { $Sdk = Join-Path $env:LOCALAPPDATA 'Android\sdk' }
if (-not (Test-Path $Sdk)) {
    Ferma 'Android SDK non trovato. Lancia prima installa_android.bat, poi rilancia.'
}
Ok "Android SDK: $Sdk"
if (-not $env:JAVA_HOME) {
    $jbr = 'C:\Program Files\Android\Android Studio\jbr'
    if (Test-Path (Join-Path $jbr 'bin\java.exe')) { $env:JAVA_HOME = $jbr }
}
if ($env:JAVA_HOME) {
    $env:Path = (Join-Path $env:JAVA_HOME 'bin') + ';' + $env:Path
    Ok "Java: $env:JAVA_HOME"
} elseif (Get-Command java -ErrorAction SilentlyContinue) {
    Ok 'Java presente'
} else {
    Ferma 'Java non trovato. Lancia prima installa_android.bat, poi rilancia.'
}

# 3. Chiave di firma (SOLO sul PC)
Passo '3/6 Controllo chiave di firma'
$ChiaveNuova = $false
$haFile = Test-Path $FileFirma
$haChiave = Test-Path $Chiave
if ($haFile -and $haChiave) {
    Ok 'chiave trovata in firma-backup'
} elseif (-not $haFile -and -not $haChiave) {
    Write-Host 'Chiave di firma NON trovata in firma-backup.' -ForegroundColor Yellow
    Write-Host 'ATTENZIONE: con una chiave NUOVA il telefono NON aggiorna l''app vecchia:' -ForegroundColor Yellow
    Write-Host 'bisogna disinstallarla e i dati sul telefono si perdono.' -ForegroundColor Yellow
    Write-Host 'Se hai una copia della cartella firma-backup (chiavetta), rimettila e rilancia.' -ForegroundColor Yellow
    $r = Read-Host 'Scrivi SI per creare una chiave nuova (altro = esci)'
    if ($r -ne 'SI') { Ferma 'chiave non creata (scelta tua).' }
    $kt = Get-Command keytool -ErrorAction SilentlyContinue
    if (-not $kt) { Ferma 'keytool non trovato (arriva con Java). Lancia installa_android.bat.' }
    New-Item -ItemType Directory -Force -Path $Firma | Out-Null
    $car = [char[]]'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789'
    $pw = -join (1..24 | ForEach-Object { $car[(Get-Random -Maximum $car.Length)] })
    & keytool -genkeypair -keystore $Chiave -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias traker-ia -storepass $pw -keypass $pw -dname 'CN=Mirko Del Sette, O=mdls, C=IT' 2>&1 | Out-Null
    if (-not (Test-Path $Chiave)) { Ferma 'chiave non creata.' }
    "storeFile=traker-ia.jks`nstorePassword=$pw`nkeyAlias=traker-ia`nkeyPassword=$pw" | Out-File -FilePath $FileFirma -Encoding ascii
    $pw = $null
    $ChiaveNuova = $true
    Write-Host 'Chiave nuova creata in firma-backup.' -ForegroundColor Green
    Write-Host 'FAI SUBITO UNA COPIA della cartella firma-backup su chiavetta. MAI nel repo.' -ForegroundColor Yellow
} else {
    Ferma 'in firma-backup manca firma.properties o traker-ia.jks (uno dei due). Rimetti la copia da chiavetta.'
}
# Solo per questa finestra: build.gradle.kts legge da qui la firma.
$env:TRAKER_FIRMA = $FileFirma

# 4. Numero release (le vecchie restano)
Passo '4/6 Scelgo numero release'
New-Item -ItemType Directory -Force -Path $Release | Out-Null
$n = 1
while (Test-Path (Join-Path $Release ('{0:D3}' -f $n))) { $n++ }
$Nome = '{0:D3}' -f $n
Ok "release\$Nome (numero versione telefono $n)"

# 5. Compila
Passo '5/6 Compilo APK (qualche minuto)'
Set-Location $App
& flutter pub get 2>&1 | Tee-Object -FilePath $Log -Append
if ($LASTEXITCODE -ne 0) { Ferma 'flutter pub get fallito.' }
& flutter build apk --release --target-platform android-arm64 --obfuscate --split-debug-info=build\simboli_apk --tree-shake-icons --build-name $Versione --build-number $n 2>&1 | Tee-Object -FilePath $Log -Append
if ($LASTEXITCODE -ne 0) { Ferma 'compilazione fallita.' }
if (-not (Test-Path $Uscita)) { Ferma 'app-release.apk non trovato dopo la compilazione.' }
Ok 'compilato'

# 6. Controllo firma + copia in release\NNN
Passo '6/6 Controllo firma e copio in release'
$apksigner = Get-ChildItem (Join-Path $Sdk 'build-tools') -Directory -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending |
    ForEach-Object { Join-Path $_.FullName 'apksigner.bat' } |
    Where-Object { Test-Path $_ } |
    Select-Object -First 1
if ($apksigner) {
    $cert = (& $apksigner verify --print-certs $Uscita 2>&1) -join "`n"
    $m = [regex]::Match($cert, 'SHA-256 digest:\s*([0-9a-fA-F]+)')
    if (-not $m.Success) { Ferma 'APK non firmato (apksigner).' }
    $impronta = $m.Groups[1].Value.ToLower()
    if (-not $ChiaveNuova -and -not ($impronta.StartsWith($ImprontaInizio) -and $impronta.EndsWith($ImprontaFine))) {
        Ferma 'APK firmato con una chiave DIVERSA da quella vera. NON installarlo.'
    }
    Ok 'firma giusta (chiave di firma-backup)'
} else {
    Write-Host 'Avviso: apksigner non trovato, firma non controllata.' -ForegroundColor Yellow
}
$env:TRAKER_FIRMA = $null
$Dest = Join-Path $Release $Nome
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
$Apk = "traker-ia_$Versione-$Nome.apk"
Copy-Item -Path $Uscita -Destination (Join-Path $Dest $Apk) -Force
# Simboli per leggere eventuali errori: a parte, NON da distribuire.
$Simboli = Join-Path $Release ("simboli\" + $Nome)
New-Item -ItemType Directory -Force -Path $Simboli | Out-Null
Copy-Item -Path (Join-Path $App 'build\simboli_apk\*') -Destination $Simboli -Recurse -Force -ErrorAction SilentlyContinue
$mb = [math]::Round(((Get-Item (Join-Path $Dest $Apk)).Length / 1MB), 1)
"release $Nome, $Apk, $mb MB" | Out-File -FilePath $Log -Append -Encoding Unicode
Ok "release\$Nome\$Apk ($mb MB)"

Write-Host ''
Write-Host "FATTO. L'APK e': release\$Nome\$Apk" -ForegroundColor Green
Write-Host 'Mandalo al telefono con LocalSend, poi toccalo per installare.' -ForegroundColor Green
Write-Host 'Si apre la cartella. Scrivi nella chat: "apk compilato".' -ForegroundColor Green
Start-Process explorer.exe $Dest
