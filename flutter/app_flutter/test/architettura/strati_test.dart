// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Controlla le regole dei 3 strati leggendo gli import dei file in lib/.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final RegExp _import = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''');

List<String> _importDi(File file) => file
    .readAsLinesSync()
    .map(_import.firstMatch)
    .whereType<RegExpMatch>()
    .map((RegExpMatch m) => m.group(1)!)
    .toList();

Iterable<File> _fileDart(String cartella) =>
    Directory(cartella)
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'));

void _nessunImportVietato(String cartella, List<String> vietati) {
  for (final File file in _fileDart(cartella)) {
    for (final String imp in _importDi(file)) {
      for (final String v in vietati) {
        expect(
          imp.startsWith(v) || imp.contains('/$v'),
          isFalse,
          reason: '${file.path} importa "$imp" (vietato: $v)',
        );
      }
    }
  }
}

void main() {
  test('domain è puro: niente Flutter, I/O, ui o data', () {
    _nessunImportVietato('lib/domain', <String>[
      'package:flutter',
      'package:material_ui',
      'dart:ui',
      'dart:io',
      'ui/',
      'data/',
    ]);
  });

  test('data non usa ui', () {
    _nessunImportVietato('lib/data', <String>['ui/']);
  });

  test('ui non usa data direttamente', () {
    _nessunImportVietato('lib/ui', <String>['data/']);
  });
}
