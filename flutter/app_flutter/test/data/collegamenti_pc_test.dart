// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/data/collegamenti_pc.dart';
import 'package:traker_ia/domain/collegamenti.dart';

void main() {
  late Directory tmp;
  final List<String> avviati = <String>[];
  final List<String> query = <String>[];

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('traker_coll_');
    avviati.clear();
    query.clear();
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  CollegamentiPc nuovo({String? hklm}) => CollegamentiPc(
    cartellaBase: () async => tmp,
    cartellaDocumenti: () async =>
        Directory('${tmp.path}${Platform.pathSeparator}Documenti'),
    leggiAsset: (String k) async => 'contenuto di $k',
    esegui: (String exe, List<String> a) async {
      query.add(a[1]);
      final bool ok = a[1].startsWith('HKLM') && hklm != null;
      return ProcessResult(
        1,
        ok ? 0 : 1,
        ok ? '    (Predefinito)    REG_SZ    $hklm\r\n' : '',
        '',
      );
    },
    avvia: (String exe, List<String> a) async =>
        avviati.add('$exe ${a.join(' ')}'),
  );

  BrowserEstensione browser(String id) =>
      browserEstensione.firstWhere((BrowserEstensione b) => b.id == id);

  test('preparaEstensione scrive i file nella cartella fissa', () async {
    final String dir = await nuovo().preparaEstensione();
    expect(
      dir,
      '${tmp.path}/Documenti/TraKer IA by mdls/estensioni/chromium'.replaceAll(
        '/',
        Platform.pathSeparator,
      ),
    );
    for (final String f in fileEstensione) {
      expect(
        File('$dir${Platform.pathSeparator}$f').readAsStringSync(),
        'contenuto di assets/estensione/$f',
      );
    }
    // seconda volta: sovrascrive senza errori
    await nuovo().preparaEstensione();
  });

  test('browser trovato in HKLM: apre la pagina estensioni', () async {
    final bool ok = await nuovo(hklm: r'C:\Brave\brave.exe')
        .apriPaginaEstensioni(browser('brave'));
    expect(ok, isTrue);
    expect(query.first, startsWith('HKCU'));
    expect(query.last, endsWith(r'App Paths\brave.exe'));
    expect(avviati, <String>[r'C:\Brave\brave.exe brave://extensions']);
  });

  test('browser non trovato: falso, niente avviato', () async {
    expect(await nuovo().apriPaginaEstensioni(browser('opera')), isFalse);
    expect(avviati, isEmpty);
  });

  test(
    'mostraInEsplora apre Esplora risorse con la cartella selezionata',
    () async {
      await nuovo().mostraInEsplora(r'C:\Doc\chromium');
      expect(avviati, <String>[r'explorer.exe /select, C:\Doc\chromium']);
    },
  );

  test('accediClaudeCode scrive il .bat e lo apre', () async {
    expect(await nuovo().accediClaudeCode(), isTrue);
    final File bat = File(
      '${tmp.path}${Platform.pathSeparator}accedi_claude_code.bat',
    );
    expect(bat.readAsStringSync(), scriptAccessoClaudeCode());
    expect(avviati, <String>['explorer.exe ${bat.path}']);
  });
}
