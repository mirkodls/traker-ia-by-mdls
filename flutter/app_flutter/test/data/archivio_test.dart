// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/data/archivio.dart';
import 'package:traker_ia/data/database.dart';
import 'package:traker_ia/data/import_file.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/tempo.dart';

DateTime _t(String s) => interpreta(s)!;

void main() {
  late Archivio a;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    a = Archivio(DatabaseTraker(NativeDatabase.memory()));
  });

  tearDown(() async {
    await a.chiudi();
  });

  test('lettura: salva e rilegge tutti i campi', () async {
    await a.aggiungiLettura(
      Lettura(
        ora: _t('2026-11-13 06:43'),
        sett: 53,
        sess: 5.5,
        fonte: 'manuale',
        alPc: true,
        lavoro: true,
        modelli: 'Fable|Opus',
        skill: 'caveman',
      ),
    );
    await a.aggiungiLettura(Lettura(ora: _t('2026-11-13 06:00')));
    final List<Lettura> l = await a.letture();
    expect(l.length, 2);
    expect(l.first.ora, _t('2026-11-13 06:00'));
    expect(l.first.sett, isNull);
    expect(l.first.alPc, isNull);
    final Lettura x = l.last;
    expect(x.sett, 53);
    expect(x.sess, 5.5);
    expect(x.fonte, 'manuale');
    expect(x.alPc, isTrue);
    expect(x.lavoro, isTrue);
    expect(x.modelli, 'Fable|Opus');
    expect(x.skill, 'caveman');
    expect(x.gestore, gestoreAnthropic);
  });

  test('B19: % Fable salvata e riletta; senza Fable -> null', () async {
    await a.aggiungiLettura(
      Lettura(ora: _t('2026-11-20 09:00'), sett: 64, sess: 14, fable: 80),
    );
    await a.aggiungiLettura(
      Lettura(ora: _t('2026-11-20 09:15'), sett: 65, sess: 15),
    );
    final List<Lettura> l = await a.letture();
    expect(l.map((Lettura x) => x.fable), <double?>[80, null]);
    expect(l.first.sett, 64);
    expect(l.first.sess, 14);
  });

  test('copia in memoria: stessa lista finché non si scrive', () async {
    final List<Lettura> l1 = await a.letture();
    expect(identical(l1, await a.letture()), isTrue);
    await a.aggiungiLettura(Lettura(ora: _t('2026-11-13 07:00'), sett: 1));
    expect((await a.letture()).length, 1);
  });

  test('eventi: salva e rilegge in ordine', () async {
    await a.aggiungiEvento(
      Evento(ora: _t('2026-11-11 17:30'), tipo: TipoEvento.nota, testo: 'x'),
    );
    await a.aggiungiEvento(
      Evento(ora: _t('2026-11-10 20:00'), tipo: TipoEvento.reset),
    );
    final List<Evento> e = await a.eventi();
    expect(e.map((Evento x) => x.tipo), <TipoEvento>[
      TipoEvento.reset,
      TipoEvento.nota,
    ]);
    expect(e.last.testo, 'x');
  });

  test('senza doppioni: ±1 min stessi valori = doppione', () async {
    await a.aggiungiLettura(Lettura(ora: _t('2026-11-13 06:43'), sett: 53));
    final int n = await a.aggiungiLettureSenzaDoppioni(<Lettura>[
      Lettura(ora: _t('2026-11-13 06:44'), sett: 53),
      Lettura(ora: _t('2026-11-13 06:50'), sett: 54),
    ]);
    expect(n, 1);
    expect((await a.letture()).length, 2);
    expect(
      await a.aggiungiLettureSenzaDoppioni(<Lettura>[
        Lettura(ora: _t('2026-11-13 06:50'), sett: 54),
      ]),
      0,
    );
    final int ne = await a.aggiungiEventiSenzaDoppioni(<Evento>[
      Evento(ora: _t('2026-11-13 06:00'), tipo: TipoEvento.inizio),
      Evento(ora: _t('2026-11-13 06:01'), tipo: TipoEvento.inizio),
    ]);
    expect(ne, 1);
  });

  test('impostazioni: salva, sovrascrive, rifiuta segreti', () async {
    expect(await a.impostazione('minuti'), isNull);
    await a.salvaImpostazione('minuti', '10');
    await a.salvaImpostazione('minuti', '6');
    expect(await a.impostazione('minuti'), '6');
    await expectLater(
      a.salvaImpostazione('cookie', 'x'),
      throwsArgumentError,
    );
    await expectLater(a.impostazione('Token_x'), throwsArgumentError);
  });

  test('import cartella Python: conta e niente doppioni al secondo giro', () async {
    final Directory d = Directory.systemTemp.createTempSync('traker_imp');
    addTearDown(() => d.deleteSync(recursive: true));
    final String s = Platform.pathSeparator;
    File('${d.path}${s}letture.csv').writeAsStringSync(
      'ora;settimanale;sessione;fonte;al_pc;lavoro;modelli;skill\n'
      '2026-11-10 20:00;0;;iniziale;;0;;\n'
      '2026-11-11 17:12;21;14;manuale;;0;;\n'
      'rotta;1;2;auto;;0;;\n',
    );
    File('${d.path}${s}eventi.csv').writeAsStringSync(
      'ora;tipo;testo\n2026-11-10 20:00;reset;reset settimanale\n',
    );
    final EsitoImport e1 = await importaCartellaPython(a, d.path);
    expect(e1.fileTrovati, 2);
    expect(e1.lettureNuove, 2);
    expect(e1.eventiNuovi, 1);
    expect(e1.scartate, 1);
    final EsitoImport e2 = await importaCartellaPython(a, d.path);
    expect(e2.lettureNuove + e2.eventiNuovi, 0);
  });

  test('import cartella mancante: zero file', () async {
    final EsitoImport e = await importaCartellaPython(a, 'non_esiste_xyz');
    expect(e.fileTrovati, 0);
  });

  final String s = Platform.pathSeparator;
  final String veri = '..$s..${s}python-test-alfa${s}dati';
  test(
    'import file vero (python-test-alfa/dati), se presente',
    () async {
      final EsitoImport e = await importaCartellaPython(a, veri);
      expect(e.lettureNuove, greaterThan(0));
      expect((await a.letture()).length, e.lettureNuove);
    },
    skip: File('$veri${s}letture.csv').existsSync()
        ? false
        : 'file vero non presente',
  );
}
