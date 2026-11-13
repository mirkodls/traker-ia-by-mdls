// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/collegamenti.dart';

void main() {
  test('exeDaReg legge il valore predefinito', () {
    const String uscita =
        '\r\nHKEY_LOCAL_MACHINE\\SOFTWARE\\...\\App Paths\\brave.exe\r\n'
        '    (Predefinito)    REG_SZ    '
        'C:\\Program Files\\BraveSoftware\\Brave-Browser\\Application\\brave.exe\r\n';
    expect(
      exeDaReg(uscita),
      'C:\\Program Files\\BraveSoftware\\Brave-Browser\\Application\\brave.exe',
    );
  });

  test('exeDaReg toglie le virgolette, null se manca', () {
    expect(exeDaReg('  (Default)  REG_SZ  "C:\\a b\\x.exe"'), 'C:\\a b\\x.exe');
    expect(exeDaReg('ERRORE: chiave non trovata'), isNull);
    expect(exeDaReg('  (Default)  REG_SZ  '), isNull);
  });

  test('browser: Chromium pronti, Firefox no, id unici', () {
    final Set<String> id = browserEstensione
        .map((BrowserEstensione b) => b.id)
        .toSet();
    expect(id.length, browserEstensione.length);
    expect(
      browserEstensione
          .where((BrowserEstensione b) => b.pronto)
          .map((BrowserEstensione b) => b.id),
      containsAll(<String>['brave', 'edge', 'chrome', 'opera', 'vivaldi']),
    );
    expect(
      browserEstensione
          .firstWhere((BrowserEstensione b) => b.id == 'firefox')
          .pronto,
      isFalse,
    );
  });

  test('script Claude Code: solo ASCII, CRLF, comandi giusti', () {
    final String s = scriptAccessoClaudeCode();
    expect(s.codeUnits.every((int c) => c < 128), isTrue);
    expect(s.split('\r\n').length, greaterThan(20));
    expect(s.replaceAll('\r\n', ''), isNot(contains('\n')));
    expect(s, contains(comandoInstallaClaudeCode));
    expect(s, contains('/login'));
    expect(s, contains('/exit'));
    expect(s, contains(r'%USERPROFILE%\.local\bin\claude.exe'));
    expect(s, contains('"%CLAUDE%"'));
  });

  test('asset estensione uguali a flutter/estensione_chromium', () {
    for (final String f in fileEstensione) {
      expect(
        File('assets/estensione/$f').readAsStringSync(),
        File('../estensione_chromium/$f').readAsStringSync(),
        reason: f,
      );
    }
  });
}
