// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// B12: archivio progetti sul database (progetti, settimane, token a mano).
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/data/archivio_progetti.dart';
import 'package:traker_ia/data/database.dart';
import 'package:traker_ia/domain/archivio_settimane.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/progetti.dart';
import 'package:traker_ia/domain/tempo.dart';

DateTime _t(String s) => interpreta(s)!;

List<Lettura> _letture() => <Lettura>[
  for (int i = 0; i < 400; i++)
    Lettura(
      ora: _t('2026-11-10 21:00').add(Duration(minutes: 30 * i)),
      sett: (i ~/ 4).toDouble(),
      sess: (i % 10).toDouble(),
    ),
];

void main() {
  late DatabaseTraker db;
  late ArchivioProgetti a;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    db = DatabaseTraker(NativeDatabase.memory());
    a = ArchivioProgetti(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('progetti: aggiungi, modifica, nomi vuoti/doppi rifiutati', () async {
    final Progetto p = await a.aggiungiProgetto(
      const Progetto(nome: ' Traker ', colore: 5, note: 'app'),
    );
    expect(p.id, isNotNull);
    expect(p.id, greaterThan(idSenzaProgetto));
    expect(p.nome, 'Traker');
    await a.aggiungiProgetto(const Progetto(nome: 'Sito'));
    expect(
      () => a.aggiungiProgetto(const Progetto(nome: 'TRAKER')),
      throwsArgumentError,
    );
    expect(
      () => a.aggiungiProgetto(const Progetto(nome: '  ')),
      throwsArgumentError,
    );
    await a.modificaProgetto(
      Progetto(id: p.id, nome: 'Traker IA', colore: 9, note: 'x'),
    );
    expect(
      () => a.modificaProgetto(Progetto(id: p.id, nome: 'sito')),
      throwsArgumentError,
    );
    expect(
      () => a.modificaProgetto(const Progetto(nome: 'senza id')),
      throwsArgumentError,
    );
    final List<Progetto> ps = await a.progetti();
    expect(ps.map((Progetto x) => x.nome), <String>['Traker IA', 'Sito']);
    expect(ps.first.colore, 9);
  });

  test('archivia settimane chiuse una volta sola; token a mano', () async {
    final Progetto p = await a.aggiungiProgetto(const Progetto(nome: 'Traker'));
    final List<Lettura> ls = _letture();
    final List<Evento> es = <Evento>[
      Evento(
        ora: _t('2026-11-12 10:00'),
        tipo: TipoEvento.nota,
        testo: 'traker inizio',
      ),
      Evento(
        ora: _t('2026-11-12 20:00'),
        tipo: TipoEvento.nota,
        testo: 'traker fine',
      ),
    ];
    final DateTime adesso = _t('2026-11-25 09:00');
    final int n = await a.archiviaSettimaneChiuse(
      letture: ls,
      eventi: es,
      adesso: adesso,
      piano: Piano(nome: 'Piano', giorniMask: 0x1F, inizio: adesso),
    );
    // Settimana 10/11: Senza + Traker; settimana 17/11: solo Senza.
    expect(n, 3);
    expect(
      await a.archiviaSettimaneChiuse(letture: ls, eventi: es, adesso: adesso),
      0,
    );
    final List<SettimanaProgetto> tutte = await a.settimane();
    expect(tutte.length, 3);
    expect(tutte.first.fine, _t('2026-11-17 20:00'));
    final List<SettimanaProgetto> mie = await a.settimane(progettoId: p.id);
    expect(mie.single.inizio, _t('2026-11-10 20:00'));
    expect(mie.single.tokenManuali, isNull);
    expect(leggiIstantanea(mie.single.istantanea).letture, isNotEmpty);
    expect(mie.single.log, contains('PROGETTO_INIZIO'));

    await a.salvaTokenManuali(mie.single.id!, 250000);
    expect((await a.settimane(progettoId: p.id)).single.tokenManuali, 250000);
    await a.salvaTokenManuali(mie.single.id!, null);
    expect((await a.settimane(progettoId: p.id)).single.tokenManuali, isNull);
    expect(() => a.salvaTokenManuali(mie.single.id!, -1), throwsArgumentError);
    // Istantanea non riscritta dal token.
    expect(
      (await a.settimane(progettoId: p.id)).single.istantanea,
      mie.single.istantanea,
    );
  });

  test('nessuna lettura -> niente da archiviare', () async {
    expect(
      await a.archiviaSettimaneChiuse(
        letture: const <Lettura>[],
        eventi: const <Evento>[],
        adesso: _t('2026-11-25 09:00'),
      ),
      0,
    );
    expect(await a.settimane(), isEmpty);
  });
}
