// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Test intensità V2 (fonte 5h/7gg, postuma, reset, buchi, solo lavoro).
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/import_csv.dart';
import 'package:traker_ia/domain/intensita.dart';
import 'package:traker_ia/domain/modelli.dart';

import 'aiuti.dart';

/// Letture ogni [passo] minuti da [da] per [n] volte; valori da funzioni.
List<Lettura> serie(
  String da,
  int n, {
  int passo = 6,
  double? Function(int i)? sett,
  double? Function(int i)? sess,
  bool Function(int i)? lavoro,
}) => <Lettura>[
  for (int i = 0; i < n; i++)
    Lettura(
      ora: t(da).add(Duration(minutes: i * passo)),
      sett: sett?.call(i),
      sess: sess?.call(i),
      lavoro: lavoro?.call(i) ?? false,
    ),
];

PuntoIntensita a(List<PuntoIntensita> ps, String ora) =>
    ps.firstWhere((PuntoIntensita p) => p.ora == t(ora));

void tuttiSani(List<PuntoIntensita> ps) {
  for (final PuntoIntensita p in ps) {
    if (p.valore != null) {
      expect(p.valore!.isFinite, isTrue, reason: '${p.ora}');
      expect(p.valore, greaterThanOrEqualTo(0), reason: '${p.ora}');
      expect(p.errore, isNotNull);
      expect(p.errore!.isFinite, isTrue);
      expect(p.errore, greaterThan(0));
    } else {
      expect(p.errore, isNull);
    }
  }
}

void main() {
  group('fonte per istante', () {
    // 10:00-11:00 sess ogni 6 min (+1 ogni lettura), poi solo sett.
    final List<Lettura> ls = serie(
      '2026-11-17 10:00',
      21,
      sett: (int i) => 20.0 + i ~/ 5,
      sess: (int i) => i <= 10 ? 10.0 + i : null,
    );
    final List<PuntoIntensita> ps = serieIntensitaV2(
      ls,
      t('2026-11-17 10:00'),
      t('2026-11-17 12:00'),
    );

    test('5h presente -> fonte 5h, pt sess/h', () {
      final PuntoIntensita p = a(ps, '2026-11-17 10:30');
      expect(p.fonte, FonteIntensita.cinqueOre);
      expect(p.fonte.codice, '5h');
      expect(p.valore, closeTo(10, 1e-9)); // 1 pt ogni 6 min
      expect(p.errore, closeTo(2, 1e-9)); // ±1 pt su 0,5 h
    });

    test('sess assente da < 15 min resta 5h, da >= 15 passa a 7gg', () {
      // ultima sess alle 11:00
      expect(a(ps, '2026-11-17 11:10').fonte, FonteIntensita.cinqueOre);
      expect(a(ps, '2026-11-17 11:15').fonte, FonteIntensita.setteGiorni);
      expect(a(ps, '2026-11-17 11:15').fonte.codice, '7gg');
    });

    test('7gg = pt sett/h (mai convertiti)', () {
      final PuntoIntensita p = a(ps, '2026-11-17 12:00');
      // sett +1 ogni 30 min -> 2 pt/h su finestra 60
      expect(p.valore, closeTo(2, 1e-9));
      expect(p.errore, closeTo(1, 1e-9));
    });

    test('nessuna lettura sess -> 7gg', () {
      final List<PuntoIntensita> q = serieIntensitaV2(
        serie('2026-11-17 10:00', 20, sett: (int i) => 5.0 + i ~/ 10),
        t('2026-11-17 10:00'),
        t('2026-11-17 11:54'),
      );
      expect(
        q.every((PuntoIntensita p) => p.fonte == FonteIntensita.setteGiorni),
        isTrue,
      );
      tuttiSani(q);
    });

    test('soglia passaggio da opzioni', () {
      final List<PuntoIntensita> q = serieIntensitaV2(
        ls,
        t('2026-11-17 11:05'),
        t('2026-11-17 11:05'),
        opzioni: const OpzioniIntensita(passaggioMin: 5),
      );
      expect(q.single.fonte, FonteIntensita.setteGiorni);
    });
  });

  group('postuma a campioni', () {
    test('finestra 60/30/120 e valori non ammessi -> 60', () {
      expect(finestraPostumaValida(30), 30);
      expect(finestraPostumaValida(120), 120);
      expect(finestraPostumaValida(45), 60);
      expect(finestraPostumaValida(null), 60);
    });

    test('Δ 0 o 1 pt: valore con errore ±1/finestra', () {
      // +1 pt sett ogni 50 min (1,2 pt/h, "full gas"), letture ogni 6 min.
      final List<Lettura> ls = serie(
        '2026-11-17 08:00',
        100,
        sett: (int i) => 30.0 + (i * 6) ~/ 50,
      );
      for (final int f in finestrePostuma) {
        final List<PuntoIntensita> ps = seriePostuma(
          ls,
          t('2026-11-17 10:00'),
          t('2026-11-17 17:00'),
          finestraMin: f,
        );
        tuttiSani(ps);
        for (final PuntoIntensita p in ps) {
          expect(p.fonte, FonteIntensita.setteGiorni);
          expect(p.errore, closeTo(60 / f, 1e-9));
          // vero 1,2 pt/h dentro valore ± errore
          expect((p.valore! - 1.2).abs(), lessThanOrEqualTo(p.errore! + 1e-9));
        }
      }
    });

    test('finestra più corta di metà coperta -> buco', () {
      final List<Lettura> ls = serie(
        '2026-11-17 10:00',
        4,
        sett: (int i) => 1.0 * i,
      );
      // dati 10:00-10:18: alle 10:18 su finestra 60 coperti 18 min < 30
      final List<PuntoIntensita> ps = seriePostuma(
        ls,
        t('2026-11-17 10:18'),
        t('2026-11-17 10:18'),
      );
      expect(ps.single.buco, isTrue);
    });
  });

  group('reset e buchi', () {
    test('reset sess (calo): mai negativo, reset escluso', () {
      // sess sale di 2 ogni 6 min fino a 40, poi reset a 0 e risale.
      final List<Lettura> ls = serie(
        '2026-11-17 10:00',
        12,
        sess: (int i) => i < 6 ? 30.0 + 2 * i : 2.0 * (i - 6),
      );
      final List<PuntoIntensita> ps = serieIntensitaV2(
        ls,
        t('2026-11-17 10:00'),
        t('2026-11-17 11:06'),
        passoMin: 6,
      );
      tuttiSani(ps);
      final PuntoIntensita p = a(ps, '2026-11-17 10:48');
      // finestra 10:18-10:48: reset 10:30->10:36 escluso, 24 min validi
      expect(p.valore, closeTo(20, 1e-9));
      expect(p.errore, closeTo(2 / 0.4, 1e-9)); // 2 tratti / 0,4 h
    });

    test('reset sett (calo): mai negativo, buco se solo reset', () {
      final List<Lettura> ls = <Lettura>[
        l('2026-11-17 19:00', 98, null),
        l('2026-11-17 20:00', 99, null),
        l('2026-11-17 21:00', 0, null),
        l('2026-11-17 22:00', 1, null),
      ];
      final List<PuntoIntensita> ps = seriePostuma(
        ls,
        t('2026-11-17 19:00'),
        t('2026-11-17 22:00'),
        passoMin: 60,
      );
      tuttiSani(ps);
      expect(a(ps, '2026-11-17 20:00').valore, closeTo(1, 1e-9));
      expect(a(ps, '2026-11-17 21:00').buco, isTrue);
      expect(a(ps, '2026-11-17 22:00').valore, closeTo(1, 1e-9));
    });

    test('intervallo > 3 h tra letture = buco', () {
      final List<Lettura> ls = <Lettura>[
        l('2026-11-17 01:00', 10, null),
        l('2026-11-17 09:00', 12, null),
      ];
      final List<PuntoIntensita> ps = seriePostuma(
        ls,
        t('2026-11-17 09:00'),
        t('2026-11-17 09:00'),
      );
      expect(ps.single.buco, isTrue);
    });

    test('nessuna lettura / intervallo vuoto', () {
      expect(
        serieIntensitaV2(
          <Lettura>[],
          t('2026-11-17 10:00'),
          t('2026-11-17 10:10'),
        ).every((PuntoIntensita p) => p.buco),
        isTrue,
      );
      expect(
        serieIntensitaV2(
          <Lettura>[],
          t('2026-11-17 10:10'),
          t('2026-11-17 10:00'),
        ),
        isEmpty,
      );
      expect(
        serieIntensitaV2(
          <Lettura>[],
          t('2026-11-17 10:00'),
          t('2026-11-17 10:10'),
          passoMin: 0,
        ),
        isEmpty,
      );
    });

    test('dati casuali: nessun NaN/inf, mai negativo', () {
      final math.Random r = math.Random(7);
      double sett = 0;
      double sess = 0;
      final List<Lettura> ls = <Lettura>[];
      DateTime ora = t('2026-11-10 20:00');
      for (int i = 0; i < 3000; i++) {
        ora = ora.add(
          Duration(minutes: 1 + r.nextInt(r.nextInt(50) == 0 ? 400 : 12)),
        );
        if (r.nextInt(200) == 0) {
          sess = 0;
        }
        if (r.nextInt(900) == 0) {
          sett = 0;
        }
        sess = math.min(100, sess + r.nextInt(3));
        sett = math.min(100, sett + (r.nextInt(5) == 0 ? 1 : 0));
        ls.add(
          Lettura(
            ora: ora,
            sett: r.nextInt(30) == 0 ? null : sett,
            sess: r.nextInt(10) == 0 ? null : sess,
            lavoro: r.nextBool(),
          ),
        );
      }
      ls.add(Lettura(ora: ora, sett: sett, sess: sess)); // ora doppia
      final List<PuntoIntensita> ps = serieIntensitaV2(ls, ls.first.ora, ora);
      tuttiSani(ps);
      tuttiSani(intensitaSoloLavoro(ls, ls.first.ora, ora));
    });
  });

  group('solo lavoro', () {
    test('letture lavoro=true: fuori = buco', () {
      // lavoro solo 10:00-11:00 (arrivo i in 1..10)
      final List<Lettura> ls = serie(
        '2026-11-17 10:00',
        21,
        sess: (int i) => 1.0 * i,
        lavoro: (int i) => i >= 1 && i <= 10,
      );
      final List<PuntoIntensita> ps = intensitaSoloLavoro(
        ls,
        t('2026-11-17 10:30'),
        t('2026-11-17 12:00'),
      );
      tuttiSani(ps);
      expect(a(ps, '2026-11-17 10:30').valore, closeTo(10, 1e-9));
      expect(a(ps, '2026-11-17 11:30').buco, isTrue);
      // senza filtro c'è valore
      expect(
        a(
          serieIntensitaV2(ls, t('2026-11-17 11:30'), t('2026-11-17 11:30')),
          '2026-11-17 11:30',
        ).valore,
        closeTo(10, 1e-9),
      );
    });

    test('eventi Inizio/Fine: tagliati in proporzione', () {
      final List<Lettura> ls = serie(
        '2026-11-17 10:00',
        21,
        sess: (int i) => 1.0 * i,
      );
      final List<Evento> ev = <Evento>[
        Evento(ora: t('2026-11-17 10:03'), tipo: TipoEvento.inizio),
        Evento(ora: t('2026-11-17 10:33'), tipo: TipoEvento.fine),
      ];
      final List<PuntoIntensita> ps = intensitaSoloLavoro(
        ls,
        t('2026-11-17 10:30'),
        t('2026-11-17 11:30'),
        eventi: ev,
      );
      tuttiSani(ps);
      // 10:03-10:30 = 27 min validi, ritmo 10 pt/h
      expect(a(ps, '2026-11-17 10:30').valore, closeTo(10, 1e-9));
      // 10:33-11:03 fuori lavoro: alle 11:00 solo 3 min -> buco
      expect(a(ps, '2026-11-17 11:00').buco, isTrue);
    });

    test('periodi uniti: eventi + letture sovrapposti', () {
      final List<Lettura> ls = serie(
        '2026-11-17 10:00',
        6,
        lavoro: (int i) => i == 2 || i == 3,
      );
      final List<Evento> ev = <Evento>[
        Evento(ora: t('2026-11-17 10:15'), tipo: TipoEvento.inizio),
        Evento(ora: t('2026-11-17 10:40'), tipo: TipoEvento.fine),
      ];
      expect(
        periodiSoloLavoro(ls, ev, t('2026-11-17 11:00')),
        <({DateTime inizio, DateTime fine})>[
          (inizio: t('2026-11-17 10:06'), fine: t('2026-11-17 10:40')),
        ],
      );
    });
  });

  group('forma CSV reale (mini fixture inventata)', () {
    // Stessa forma di python-test-alfa/dati/letture.csv: interi, ';', 6 min.
    const String csv =
        'ora;settimanale;sessione;fonte;al_pc;lavoro;modelli;skill\n'
        '2026-11-12 09:00;30;0;auto;1;1;;\n'
        '2026-11-12 09:06;30;1;auto;1;1;;\n'
        '2026-11-12 09:12;30;3;auto;1;1;;\n'
        '2026-11-12 09:18;30;4;auto;1;1;;\n'
        '2026-11-12 09:24;31;6;auto;1;1;;\n'
        '2026-11-12 09:30;31;7;auto;1;1;;\n'
        '2026-11-12 09:36;31;;auto;1;1;;\n'
        '2026-11-12 09:42;31;;auto;1;1;;\n'
        '2026-11-12 09:48;31;;auto;1;1;;\n'
        '2026-11-12 09:54;32;;auto;0;1;;\n'
        '2026-11-12 10:00;32;;auto;0;1;;\n';

    test('import + serie: fonti e valori interi sensati', () {
      final List<Lettura> ls = importaLetture(csv).voci;
      expect(ls, hasLength(11));
      final List<PuntoIntensita> ps = serieIntensitaV2(
        ls,
        t('2026-11-12 09:00'),
        t('2026-11-12 10:00'),
        passoMin: 6,
      );
      tuttiSani(ps);
      expect(a(ps, '2026-11-12 09:30').fonte, FonteIntensita.cinqueOre);
      expect(
        a(ps, '2026-11-12 09:30').valore,
        closeTo(14, 1e-9),
      ); // 7 pt / 0,5 h
      expect(a(ps, '2026-11-12 09:48').fonte, FonteIntensita.setteGiorni);
      expect(
        a(ps, '2026-11-12 10:00').valore,
        closeTo(2, 1e-9),
      ); // 30->32 in 1 h
      expect(a(ps, '2026-11-12 10:00').errore, closeTo(1, 1e-9));
    });
  });

  test('arrotondaStima: niente falsa precisione', () {
    expect(arrotondaStima(1.234, 1), 1);
    expect(arrotondaStima(1.66, 2), 2);
    expect(arrotondaStima(1.234, 0.5), 1.2);
    expect(arrotondaStima(1.236, 0.05), 1.24);
  });

  test('O(n): 20.000 letture, 6.000 punti in tempo breve', () {
    final List<Lettura> ls = serie(
      '2026-10-01 00:00',
      20000,
      passo: 3,
      sett: (int i) => (i ~/ 100 % 100).toDouble(),
      sess: (int i) => (i % 100).toDouble(),
    );
    final Stopwatch sw = Stopwatch()..start();
    final List<PuntoIntensita> ps = serieIntensitaV2(
      ls,
      ls.first.ora,
      ls.last.ora,
      passoMin: 10,
    );
    sw.stop();
    expect(ps.length, greaterThan(5000));
    tuttiSani(ps);
    expect(sw.elapsedMilliseconds, lessThan(2000));
  });
}
