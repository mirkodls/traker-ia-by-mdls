// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: dati per collegare le fonti di lettura (estensione nei
// browser, accesso a Claude Code). Niente I/O: solo elenchi e testi.

/// Un browser dove installare l'estensione.
typedef BrowserEstensione = ({
  String id,
  String nome,
  String exe,
  String pagina,
  String tasto,
  bool pronto,
});

/// Browser supportati (Chromium). Firefox: serve firma Mozilla → dopo.
const List<BrowserEstensione> browserEstensione = <BrowserEstensione>[
  (
    id: 'brave',
    nome: 'Brave',
    exe: 'brave.exe',
    pagina: 'brave://extensions',
    tasto: 'Carica estensione non pacchettizzata',
    pronto: true,
  ),
  (
    id: 'edge',
    nome: 'Edge',
    exe: 'msedge.exe',
    pagina: 'edge://extensions',
    tasto: 'Carica decompressa',
    pronto: true,
  ),
  (
    id: 'chrome',
    nome: 'Chrome',
    exe: 'chrome.exe',
    pagina: 'chrome://extensions',
    tasto: 'Carica estensione non pacchettizzata',
    pronto: true,
  ),
  (
    id: 'opera',
    nome: 'Opera',
    exe: 'opera.exe',
    pagina: 'opera://extensions',
    tasto: 'Carica estensione non pacchettizzata',
    pronto: true,
  ),
  (
    id: 'vivaldi',
    nome: 'Vivaldi',
    exe: 'vivaldi.exe',
    pagina: 'vivaldi://extensions',
    tasto: 'Carica estensione non pacchettizzata',
    pronto: true,
  ),
  (
    id: 'firefox',
    nome: 'Firefox',
    exe: 'firefox.exe',
    pagina: 'about:addons',
    tasto: '',
    pronto: false,
  ),
];

/// Cartella fissa (in Documenti) con le estensioni: stessa a ogni versione
/// dell'app, così il browser la ritrova sempre.
const List<String> cartellaEstensioni = <String>[
  'TraKer IA by mdls',
  'estensioni',
  'chromium',
];

/// File dell'estensione (stessi nomi in assets/estensione e
/// flutter/estensione_chromium).
const List<String> fileEstensione = <String>[
  'manifest.json',
  'sfondo.js',
  'LEGGIMI.txt',
];

/// Percorso dell'exe da `reg query ... App Paths\x.exe /ve`: la riga col
/// valore predefinito "REG_SZ". Null se non trovato.
String? exeDaReg(String uscita) {
  for (final String riga in uscita.split(RegExp(r'\r?\n'))) {
    final int i = riga.indexOf('REG_SZ');
    if (i < 0) {
      continue;
    }
    String v = riga.substring(i + 'REG_SZ'.length).trim();
    if (v.length >= 2 && v.startsWith('"') && v.endsWith('"')) {
      v = v.substring(1, v.length - 1);
    }
    return v.isEmpty ? null : v;
  }
  return null;
}

/// Comando ufficiale Anthropic per installare Claude Code su Windows.
const String comandoInstallaClaudeCode =
    'irm https://claude.ai/install.ps1 | iex';

/// Script .bat (solo ASCII, righe CRLF) che apre cmd, installa Claude Code
/// se manca (dopo un tasto) e guida all'accesso.
String scriptAccessoClaudeCode() {
  const List<String> righe = <String>[
    '@echo off',
    'title TraKer IA by mdls - accesso a Claude Code',
    'cd /d "%USERPROFILE%"',
    'set "CLAUDE=%USERPROFILE%\\.local\\bin\\claude.exe"',
    'if exist "%CLAUDE%" goto accedi',
    'set "CLAUDE=%APPDATA%\\npm\\claude.cmd"',
    'if exist "%CLAUDE%" goto accedi',
    'set "CLAUDE=claude"',
    'where claude >nul 2>&1',
    'if not errorlevel 1 goto accedi',
    ':installa',
    'echo ==============================================================',
    "echo  Claude Code NON e' installato su questo PC.",
    'echo ==============================================================',
    'echo  Serve un abbonamento Claude Pro, Max, Team o Enterprise.',
    "echo  Installazione ufficiale Anthropic (non serve l'amministratore):",
    'echo     powershell -c "$comandoInstallaClaudeCode"',
    'echo.',
    'echo  Premi un tasto per installarlo ADESSO (2-3 minuti, stima).',
    'echo  Oppure chiudi questa finestra per annullare.',
    'pause >nul',
    'powershell -NoProfile -ExecutionPolicy Bypass -Command '
        '"$comandoInstallaClaudeCode"',
    'set "CLAUDE=%USERPROFILE%\\.local\\bin\\claude.exe"',
    'if exist "%CLAUDE%" goto installato',
    'echo.',
    'echo  ERRORE: installazione non riuscita. Controlla internet e riprova.',
    'pause',
    'exit /b 1',
    ':installato',
    'echo.',
    'echo  OK: Claude Code installato.',
    ':accedi',
    'echo.',
    'echo ==============================================================',
    "echo  ACCESSO A CLAUDE CODE - fai cosi':",
    'echo ==============================================================',
    'echo  1. Tra poco parte Claude Code.',
    'echo     Prima volta: scegli il tema e premi Invio.',
    'echo  2. Se chiede di accedere: scegli "Claude account with subscription".',
    'echo     Se NON chiede: scrivi  /login  e premi Invio, poi quella voce.',
    'echo  3. Si apre il browser: clic su "Autorizza" (Authorize).',
    'echo  4. Se chiede se ti fidi della cartella: premi Invio (Yes).',
    'echo  5. Torna qui. Scrivi  /exit  e premi Invio.',
    "echo  6. Chiudi questa finestra: l'app legge da sola entro pochi minuti.",
    'echo ==============================================================',
    'echo  Premi un tasto per partire.',
    'pause >nul',
    '"%CLAUDE%"',
    'echo.',
    'echo  Finito. Puoi chiudere questa finestra.',
    'pause',
  ];
  return '${righe.join('\r\n')}\r\n';
}
