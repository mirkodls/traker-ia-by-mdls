// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/archivio_settimane.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/progetti.dart';
import 'package:traker_ia/ui/progetti_dati.dart';
import 'package:traker_ia/ui/stato_app.dart';

import 'progetti_helper.dart';
import 'servizi_finti.dart';

Future<ServiziFinti> _archiviato({int settimane = 3, int passoMin = 30}) async {
  final ServiziFinti f = ServiziFinti();
  riempi(f, settimane: settimane, passoMin: passoMin);
  await f.archiviaSettimaneChiuse(
    letture: await f.letture(),
    eventi: await f.eventi(),
    adesso: adessoFinto,
    piano: Piano(
      nome: 'Piano',
      giorniMask: tuttiIGiorni,
      inizio: t('2026-11-10 20:00'),
    ),
  );
  return f;
}

void main() {
  test('riassuntoVeloce = riassunto della decodifica completa', () async {
    final ServiziFinti f = await _archiviato();
    expect(f.sett, isNotEmpty);
    for (final SettimanaProgetto r in f.sett) {
      final Map<String, Object?> pieno = leggiIstantanea(r.istantanea)
          .riassunto;
      expect(pieno, isNotEmpty);
      expect(riassuntoVeloce(r.istantanea), pieno);
    }
  });

  test('riassuntoVeloce: json rotto o corto -> vuoto, mai eccezioni', () {
    expect(riassuntoVeloce(''), isEmpty);
    expect(riassuntoVeloce('{"riassunto":{'), isEmpty);
    expect(riassuntoVeloce('non json'), isEmpty);
    expect(
      riassuntoVeloce('{"v":1,"riassunto":{"sett":{"stima":1}}}'),
      isNotEmpty,
    );
  });

  test('riassuntoVeloce: nome/note con la parola riassunto non confondono', () {
    final ServiziFinti f = ServiziFinti();
    riempi(f, settimane: 1);
    f.prog[0] = const Progetto(
      id: 1,
      nome: 'Alfa',
      note: 'ecco "riassunto": falso',
    );
    final List<SettimanaProgetto> r = archiviaSettimana(
      letture: f.lett,
      eventi: f.ev,
      progetti: f.prog,
      inizio: t('2026-11-03 20:00'),
      fine: t('2026-11-10 20:00'),
    );
    for (final SettimanaProgetto x in r) {
      expect(
        riassuntoVeloce(x.istantanea),
        leggiIstantanea(x.istantanea).riassunto,
      );
    }
  });

  test('RigaArchivio: stime lette dal riassunto, token con conToken', () async {
    final ServiziFinti f = await _archiviato(settimane: 1);
    final RigaArchivio r = RigaArchivio(f.sett.first);
    expect(r.leggibile, isTrue);
    expect(r.sett.max, greaterThanOrEqualTo(r.sett.min));
    expect(r.token, isNull);
    final RigaArchivio q = r.conToken(1234);
    expect(q.token, 1234);
    expect(q.sett.stima, r.sett.stima);
    expect(q.riga.istantanea, r.riga.istantanea);
  });

  test(
    'raggruppaSettimane: recenti prima, righe per id; barre: vecchie prima',
    () async {
      final ServiziFinti f = await _archiviato();
      final List<RigaArchivio> righe = <RigaArchivio>[
        for (final SettimanaProgetto r in f.sett) RigaArchivio(r),
      ];
      final List<GruppoSettimana> g = raggruppaSettimane(righe);
      expect(g.length, 3);
      expect(g.first.inizio.isAfter(g.last.inizio), isTrue);
      for (final GruppoSettimana x in g) {
        final List<int> ids = <int>[
          for (final RigaArchivio r in x.righe) r.progettoId,
        ];
        expect(ids, <int>[...ids]..sort());
      }
      final List<BarraSettimana> tutte = barreSettimane(righe);
      expect(tutte.length, 3);
      expect(tutte.first.inizio.isBefore(tutte.last.inizio), isTrue);
      final List<BarraSettimana> alfa = barreSettimane(righe, progettoId: 1);
      expect(alfa.length, 3);
      for (final BarraSettimana b in alfa) {
        expect(
          b.segmenti.every(
            (({int progettoId, double valore}) s) => s.progettoId == 1,
          ),
          isTrue,
        );
      }
      // Barra "tutti" = somma delle stime delle sue righe.
      for (final BarraSettimana b in tutte) {
        double tot = 0;
        for (final ({int progettoId, double valore}) s in b.segmenti) {
          tot += s.valore;
        }
        expect(b.totale, closeTo(tot, 1e-9));
      }
      expect(barreSettimane(righe, max: 2).length, 2);
      expect(cimaBarre(<BarraSettimana>[]), 1);
    },
  );

  test('coloreProgetto: salvato, tavolozza per id, grigio senza progetto', () {
    const List<Progetto> ps = <Progetto>[
      Progetto(id: 1, nome: 'A', colore: 0xFF112233),
      Progetto(id: 2, nome: 'B'),
    ];
    expect(coloreProgetto(1, ps).toARGB32(), 0xFF112233);
    expect(coloreProgetto(2, ps).toARGB32(), coloriProgetto[2]);
    expect(coloreProgetto(idSenzaProgetto, ps).toARGB32(), coloreSenzaProgetto);
    expect(
      coloreProgetto(99, ps).toARGB32(),
      coloriProgetto[99 % coloriProgetto.length],
    );
  });

  test('costruisciScheda: grafico ridisegnato dai dati SALVATI', () async {
    final ServiziFinti f = await _archiviato(settimane: 1);
    final RigaArchivio r = RigaArchivio(
      f.sett.firstWhere((SettimanaProgetto x) => x.progettoId == 1),
    );
    final SchedaSettimana s = costruisciScheda(r);
    expect(s.dati.versione, versioneIstantanea);
    expect(s.grafico, isNotNull);
    expect(s.conPiano, isTrue);
    expect(s.grafico!.da, r.inizio);
    expect(s.grafico!.a, r.fine);
    expect(s.grafico!.sett, isNotEmpty);
    expect(s.grafico!.intensitaV2, isNotNull);
    expect(s.grafico!.intensitaV2!.punti, isNotEmpty);
    expect(s.grafico!.piano, isNotNull);
    // Punti intensità = quelli salvati, non ricalcolati.
    final Object? serie = s.dati.grezza['serie'];
    final List<Object?> salvati =
        (serie! as Map<String, Object?>)['intensita']! as List<Object?>;
    expect(s.grafico!.intensitaV2!.punti.length, salvati.length);
  });

  test(
    'costruisciScheda: istantanea rotta -> senza grafico, mai eccezioni',
    () {
      final RigaArchivio r = RigaArchivio(
        SettimanaProgetto(
          id: 1,
          progettoId: 1,
          inizio: t('2026-11-03 20:00'),
          fine: t('2026-11-10 20:00'),
          istantanea: 'rotta',
          log: '',
        ),
      );
      expect(r.leggibile, isFalse);
      final SchedaSettimana s = costruisciScheda(r);
      expect(s.grafico, isNull);
      expect(s.conPiano, isFalse);
    },
  );

  test(
    'velocità: 20 settimane (6 min) lista < 300 ms, scheda < 300 ms',
    () async {
      final ServiziFinti f = await _archiviato(settimane: 20, passoMin: 6);
      expect(f.sett.length, greaterThanOrEqualTo(20));
      final StatoApp s = StatoApp(f, orologio: () => adessoFinto, giri: false);
      await s.avvia();
      final Stopwatch sw = Stopwatch()..start();
      await s.caricaSettimane();
      sw.stop();
      // ignore: avoid_print
      print('lista ${f.sett.length} righe: ${sw.elapsedMilliseconds} ms');
      expect(sw.elapsedMilliseconds, lessThan(300));
      expect(s.settimane!.length, f.sett.length);
      final Stopwatch sc = Stopwatch()..start();
      costruisciScheda(s.settimane!.first);
      sc.stop();
      // ignore: avoid_print
      print('scheda: ${sc.elapsedMilliseconds} ms');
      expect(sc.elapsedMilliseconds, lessThan(300));
      s.rilasciaSettimane();
      expect(s.settimane, isNull);
    },
  );

  group('StatoApp progetti', () {
    Future<(StatoApp, ServiziFinti)> apri({bool archivio = false}) async {
      final ServiziFinti f = ServiziFinti();
      riempi(f);
      f.risposte.add(const Uso(sett: 30, sess: 10));
      final StatoApp s = StatoApp(f, orologio: () => adessoFinto, giri: false);
      await s.avvia();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return (s, f);
    }

    test(
      'avvio: progetti caricati e settimane chiuse archiviate 1 volta',
      () async {
        final (StatoApp s, ServiziFinti f) = await apri();
        expect(s.progetti.map((Progetto p) => p.nome), <String>[
          'Alfa',
          'Beta',
        ]);
        expect(f.archiviazioni, 1);
        expect(f.sett, isNotEmpty);
        final int righe = f.sett.length;
        await s.leggi();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        // Stessa settimana: non ci riprova (leggero).
        expect(f.archiviazioni, 1);
        expect(f.sett.length, righe);
      },
    );

    test('v2_lavoro=0: niente progetti, niente archiviazione', () async {
      final ServiziFinti f = ServiziFinti();
      riempi(f);
      f.imp['v2_lavoro'] = '0';
      final StatoApp s = StatoApp(f, orologio: () => adessoFinto, giri: false);
      await s.avvia();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(s.progetti, isEmpty);
      expect(f.archiviazioni, 0);
    });

    test(
      'cambiaProgettoAttivo: scrive la nota-comando, due progetti insieme',
      () async {
        final (StatoApp s, ServiziFinti f) = await apri();
        // Alle 12:00 di martedì le note finte sono chiuse: nessun attivo.
        expect(s.progettiAttivi, isEmpty);
        await s.cambiaProgettoAttivo(s.progetti[0]);
        expect(f.ev.last.testo, 'Alfa inizio');
        expect(f.ev.last.tipo, TipoEvento.nota);
        expect(s.progettiAttivi, <int>{1});
        await s.cambiaProgettoAttivo(s.progetti[1]);
        expect(s.progettiAttivi, <int>{1, 2});
        await s.cambiaProgettoAttivo(s.progetti[0]);
        expect(f.ev.last.testo, 'Alfa fine');
        expect(s.progettiAttivi, <int>{2});
      },
    );

    test('salvaProgetto: nuovo, doppio, vuoto, modifica', () async {
      final (StatoApp s, ServiziFinti f) = await apri();
      expect(await s.salvaProgetto(const Progetto(nome: 'Gamma')), isNull);
      expect(s.progetti.length, 3);
      expect(await s.salvaProgetto(const Progetto(nome: ' gamma ')), isNotNull);
      expect(await s.salvaProgetto(const Progetto(nome: '  ')), isNotNull);
      final Progetto g = s.progetti.last;
      expect(
        await s.salvaProgetto(
          Progetto(id: g.id, nome: 'Gamma 2', colore: 0xFF123456),
        ),
        isNull,
      );
      expect(s.progetti.last.nome, 'Gamma 2');
      expect(s.progetti.last.colore, 0xFF123456);
      // Nome di un altro progetto = rifiutato.
      expect(
        await s.salvaProgetto(Progetto(id: g.id, nome: 'alfa')),
        isNotNull,
      );
      expect(f.prog.length, 3);
    });

    test('ripartizione corrente: solo a pagina aperta, in cache', () async {
      final (StatoApp s, _) = await apri();
      expect(s.ripartizioneCorrente, isNull);
      expect(s.calcoliRipartizione, 0);
      await s.caricaSettimane();
      expect(s.ripartizioneCorrente, isNotNull);
      expect(s.calcoliRipartizione, 1);
      // Nessun dato nuovo (cambio periodo): non ricalcola.
      await s.cambiaPeriodo(2);
      await s.cambiaPeriodo(3);
      expect(s.calcoliRipartizione, 1);
      // Dato nuovo: ricalcola.
      await s.cambiaProgettoAttivo(s.progetti[1]);
      expect(s.calcoliRipartizione, 2);
      s.rilasciaSettimane();
      expect(s.ripartizioneCorrente, isNull);
    });

    test('token a mano: salvati e riletti, cancellabili', () async {
      final (StatoApp s, ServiziFinti f) = await apri();
      await s.caricaSettimane();
      final RigaArchivio r = s.settimane!.first;
      await s.salvaTokenSettimana(r, 5000);
      expect(
        f.sett.firstWhere((SettimanaProgetto x) => x.id == r.id).tokenManuali,
        5000,
      );
      expect(
        s.settimane!.firstWhere((RigaArchivio x) => x.id == r.id).token,
        5000,
      );
      await s.salvaTokenSettimana(s.settimane!.first, null);
      expect(
        f.sett.firstWhere((SettimanaProgetto x) => x.id == r.id).tokenManuali,
        isNull,
      );
    });
  });
}
