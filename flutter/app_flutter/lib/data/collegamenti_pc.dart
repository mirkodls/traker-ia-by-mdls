// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato data (solo Windows): prepara la cartella dell'estensione, apre la
// pagina estensioni del browser, lancia l'accesso guidato a Claude Code.
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:traker_ia/domain/collegamenti.dart';

/// Legge un file di testo dagli asset dell'app.
typedef LeggiAsset = Future<String> Function(String chiave);

/// Esegue un comando e aspetta il risultato (es. reg query).
typedef Esegui = Future<ProcessResult> Function(String exe, List<String> arg);

/// Avvia un programma senza aspettarlo.
typedef Avvia = Future<void> Function(String exe, List<String> arg);

/// Collegamenti con browser e Claude Code sul PC.
class CollegamentiPc {
  /// [cartellaBase] = cartella dati dell'app (stabile tra le release).
  /// [cartellaDocumenti] = Documenti dell'utente (estensioni, visibili).
  CollegamentiPc({
    required this.cartellaBase,
    required this.cartellaDocumenti,
    LeggiAsset? leggiAsset,
    Esegui? esegui,
    Avvia? avvia,
  }) : _leggi = leggiAsset ?? rootBundle.loadString,
       _esegui = esegui ?? Process.run,
       _avvia = avvia ?? _avviaStaccato;

  /// Cartella dati dell'app.
  final Future<Directory> Function() cartellaBase;

  /// Cartella Documenti dell'utente.
  final Future<Directory> Function() cartellaDocumenti;
  final LeggiAsset _leggi;
  final Esegui _esegui;
  final Avvia _avvia;

  static Future<void> _avviaStaccato(String exe, List<String> arg) async {
    await Process.start(exe, arg, mode: ProcessStartMode.detached);
  }

  /// Scrive (o aggiorna) l'estensione in
  /// `Documenti\TraKer IA by mdls\estensioni\chromium` e ne restituisce il
  /// percorso. Cartella fissa: il browser la ricarica sempre da lì.
  Future<String> preparaEstensione() async {
    final Directory doc = await cartellaDocumenti();
    final Directory dir = Directory(
      <String>[doc.path, ...cartellaEstensioni].join(Platform.pathSeparator),
    );
    await dir.create(recursive: true);
    for (final String f in fileEstensione) {
      final String testo = await _leggi('assets/estensione/$f');
      await File('${dir.path}${Platform.pathSeparator}$f')
          .writeAsString(testo, flush: true);
    }
    return dir.path;
  }

  /// Percorso dell'exe del browser (App Paths utente, poi di sistema).
  Future<String?> trovaBrowser(BrowserEstensione b) async {
    for (final String radice in <String>['HKCU', 'HKLM']) {
      try {
        final ProcessResult r = await _esegui('reg', <String>[
          'query',
          '$radice\\Software\\Microsoft\\Windows\\CurrentVersion\\App Paths\\'
              '${b.exe}',
          '/ve',
        ]);
        if (r.exitCode == 0) {
          final String? exe = exeDaReg('${r.stdout}');
          if (exe != null) {
            return exe;
          }
        }
      } on ProcessException {
        return null;
      }
    }
    return null;
  }

  /// Apre la pagina estensioni del browser. Falso = browser non trovato.
  Future<bool> apriPaginaEstensioni(BrowserEstensione b) async {
    final String? exe = await trovaBrowser(b);
    if (exe == null) {
      return false;
    }
    try {
      await _avvia(exe, <String>[b.pagina]);
      return true;
    } on ProcessException {
      return false;
    }
  }

  /// Apre Esplora risorse con [percorso] selezionato (da trascinare).
  Future<void> mostraInEsplora(String percorso) async {
    try {
      await _avvia('explorer.exe', <String>['/select,', percorso]);
    } on ProcessException {
      // niente: i passi dicono comunque dove sta la cartella
    }
  }

  /// Apre il file [percorso] col programma scelto da Windows.
  Future<void> apriFile(String percorso) async {
    try {
      await _avvia('explorer.exe', <String>[percorso]);
    } on ProcessException {
      // niente: il percorso si vede comunque nel dialogo
    }
  }

  /// Scrive accedi_claude_code.bat nella cartella dati e lo apre (finestra
  /// cmd nuova con la guida). Falso = non partito.
  Future<bool> accediClaudeCode() async {
    final Directory base = await cartellaBase();
    await base.create(recursive: true);
    final File bat = File(
      '${base.path}${Platform.pathSeparator}accedi_claude_code.bat',
    );
    await bat.writeAsString(scriptAccessoClaudeCode(), flush: true);
    try {
      await _avvia('explorer.exe', <String>[bat.path]);
      return true;
    } on ProcessException {
      return false;
    }
  }
}
