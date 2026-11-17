// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/coppie.dart' show Periodo;
import 'package:traker_ia/domain/linee_piano.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/piano_giorni.dart';

final DateTime reset = DateTime(2026, 11, 17, 20);

List<FetteGiorno> _fette(
  List<int> giorni, {
  ConfinePiano confine = ConfinePiano.reset24h,
}) => costruisciFette(
  Piano(
    nome: 'p',
    giorniMask: mascheraGiorni(giorni),
    inizio: reset,
    confine: confine,
  ),
  reset,
);

Lettura _l(DateTime ora, double? sett) => Lettura(ora: ora, sett: sett);

/// Valore della linea a gradino dentro la fetta che inizia a [ini].
double _valoreIn(List<PuntoLinea> linea, DateTime ini) =>
    linea.lastWhere((PuntoLinea p) => p.ora == ini).valore;

const List<int> _marMerGio = <int>[
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
];

void main() {
  final DateTime g2 = DateTime(2026, 11, 18, 20);
  final DateTime g3 = DateTime(2026, 11, 19, 20);
  final DateTime fine = DateTime(2026, 11, 20, 20);

  group('ideale', () {
    test('3 giorni: 33/66/99 a gradino, 99 a fine', () {
      final List<PuntoLinea> l = lineaIdeale(_fette(_marMerGio));
      expect(l, <PuntoLinea>[
        PuntoLinea(reset, 33),
        PuntoLinea(g2, 33),
        PuntoLinea(g2, 66),
        PuntoLinea(g3, 66),
        PuntoLinea(g3, 99),
        PuntoLinea(fine, 99),
      ]);
    });

    test('giorno non lavoro in mezzo = piatto; 5 giorni ultimo esatto', () {
      final List<PuntoLinea> l = lineaIdeale(
        _fette(<int>[DateTime.tuesday, DateTime.thursday]),
      );
      expect(_valoreIn(l, reset), 49.5);
      expect(_valoreIn(l, g2), 49.5);
      expect(_valoreIn(l, g3), 99);
      expect(l.last, PuntoLinea(fine, 99));
      final List<PuntoLinea> c = lineaIdeale(
        _fette(<int>[1, 2, 3, 4, 5]),
        target: 99,
      );
      expect(c.last.valore, 99);
      expect(c.length, 14); // tutte le fette fino a lunedì compreso
    });

    test('piano 1 giorno, giorno non primo: piatto a 0 poi 99', () {
      final List<PuntoLinea> l = lineaIdeale(_fette(<int>[DateTime.thursday]));
      expect(l.first, PuntoLinea(reset, 0));
      expect(_valoreIn(l, g2), 0);
      expect(_valoreIn(l, g3), 99);
      expect(l.last, PuntoLinea(fine, 99));
    });

    test('nessun giorno di lavoro: vuota', () {
      expect(lineaIdeale(_fette(<int>[])), isEmpty);
    });

    test('mezzanotte: pezzo corto conta per le sue ore', () {
      final List<FetteGiorno> f = _fette(
        _marMerGio,
        confine: ConfinePiano.mezzanotte,
      );
      // mar 20-24 (4/24), mer, gio, ... lun, mar 00-20 (20/24): pesi lavoro
      // = 4/24 + 1 + 1 + 20/24 = 3.
      final List<PuntoLinea> l = lineaIdeale(f);
      expect(l.first.valore, closeTo(99 * (4 / 24) / 3, 1e-9));
      expect(l.last, PuntoLinea(DateTime(2026, 11, 24, 20), 99));
    });
  });

  group('adattiva', () {
    test('esempio ordine: g1 chiude 50 -> 24,5; g2 chiude 90 -> 9', () {
      final List<FetteGiorno> f = _fette(_marMerGio);
      final List<Lettura> lett = <Lettura>[_l(reset, 0), _l(g2, 50)];
      expect(quotaAdattiva(f, lett, ora: g2), 24.5);
      final List<PuntoLinea> a = lineaAdattiva(f, lett);
      expect(a, <PuntoLinea>[
        PuntoLinea(g2, 50),
        PuntoLinea(g2, 74.5),
        PuntoLinea(g3, 74.5),
        PuntoLinea(g3, 99),
        PuntoLinea(fine, 99),
      ]);
      final List<Lettura> lett2 = <Lettura>[...lett, _l(g3, 90)];
      expect(quotaAdattiva(f, lett2, ora: g3), 9);
      expect(lineaAdattiva(f, lett2), <PuntoLinea>[
        PuntoLinea(g3, 90),
        PuntoLinea(g3, 99),
        PuntoLinea(fine, 99),
      ]);
    });

    test('stesso esempio con target 100: 25 poi 10', () {
      final List<FetteGiorno> f = _fette(_marMerGio);
      final List<Lettura> lett = <Lettura>[_l(g2, 50), _l(g3, 90)];
      expect(quotaAdattiva(f, lett, ora: g2, target: 100), 25);
      expect(quotaAdattiva(f, lett, ora: g3, target: 100), 10);
      expect(lineaAdattiva(f, lett, target: 100).last.valore, 100);
    });

    test('a metà giornata: conta solo la parte restante di oggi', () {
      final List<FetteGiorno> f = _fette(_marMerGio);
      final DateTime meta = DateTime(2026, 11, 19, 8); // metà di g2
      final StatoAdattivo s = statoAdattivo(f, <Lettura>[
        _l(meta, 60),
      ], ora: meta)!;
      expect(s.indice, 1);
      expect(s.frazioneRestante, 0.5);
      expect(s.giorniRimasti, 1.5);
      expect(s.quota, closeTo(39 / 1.5, 1e-12)); // 26
      final List<PuntoLinea> a = lineaAdattiva(f, <Lettura>[_l(meta, 60)]);
      expect(a[0], PuntoLinea(meta, 60));
      expect(a[1].valore, closeTo(73, 1e-9)); // 60 + 26*0,5
      expect(a.last, PuntoLinea(fine, 99));
    });

    test('nessuna lettura o ora prima del reset: uguale alla ideale', () {
      final List<FetteGiorno> f = _fette(_marMerGio);
      expect(quotaAdattiva(f, <Lettura>[], ora: reset), 33);
      final List<PuntoLinea> a = lineaAdattiva(
        f,
        <Lettura>[],
        ora: DateTime(2026, 11, 10),
      );
      expect(a.first, PuntoLinea(reset, 0));
      expect(a.sublist(1), lineaIdeale(f));
    });

    test('letture mancanti: usa ultima nota, mai interpolare', () {
      final List<FetteGiorno> f = _fette(_marMerGio);
      final List<Lettura> lett = <Lettura>[
        _l(DateTime(2026, 11, 18, 10), 30),
        _l(DateTime(2026, 11, 18, 15), null), // lettura senza sett
        _l(DateTime(2026, 11, 19, 10), 70), // dopo g2: non conta a g2
      ];
      expect(settNota(lett, g2, da: reset), 30);
      expect(quotaAdattiva(f, lett, ora: g2), closeTo(69 / 2, 1e-12));
    });

    test('lettura settimana vecchia ignorata', () {
      final List<FetteGiorno> f = _fette(_marMerGio);
      final List<Lettura> lett = <Lettura>[
        _l(DateTime(2026, 11, 17, 19, 50), 97), // prima del reset
      ];
      expect(quotaAdattiva(f, lett, ora: reset), 33);
    });

    test('sett già >= target: quota 0, linea piatta sul valore', () {
      final List<FetteGiorno> f = _fette(_marMerGio);
      final List<Lettura> lett = <Lettura>[_l(g2, 100)];
      expect(quotaAdattiva(f, lett, ora: g2), 0);
      final List<PuntoLinea> a = lineaAdattiva(f, lett);
      expect(a.every((PuntoLinea p) => p.valore == 100), isTrue);
      expect(a.last.ora, fine);
    });

    test(
      'giorno non lavoro in mezzo: piatto, quota solo sui giorni lavoro',
      () {
        final List<FetteGiorno> f = _fette(<int>[
          DateTime.tuesday,
          DateTime.thursday,
        ]);
        final List<Lettura> lett = <Lettura>[_l(g2, 40)]; // inizio mer (riposo)
        expect(quotaAdattiva(f, lett, ora: g2), 59);
        final List<PuntoLinea> a = lineaAdattiva(f, lett);
        expect(a, <PuntoLinea>[
          PuntoLinea(g2, 40),
          PuntoLinea(g2, 40),
          PuntoLinea(g3, 40),
          PuntoLinea(g3, 99),
          PuntoLinea(fine, 99),
        ]);
      },
    );

    test('piano 1 giorno: tutto il resto nel giorno', () {
      final List<FetteGiorno> f = _fette(<int>[DateTime.tuesday]);
      final List<Lettura> lett = <Lettura>[_l(DateTime(2026, 11, 18, 2), 30)];
      final StatoAdattivo s = statoAdattivo(
        f,
        lett,
        ora: DateTime(2026, 11, 18, 2),
      )!;
      expect(s.giorniRimasti, 0.75);
      expect(s.quota, closeTo(69 / 0.75, 1e-9));
      expect(lineaAdattiva(f, lett).last, PuntoLinea(g2, 99));
    });

    test('reset a metà piano (sett scende): riparte dal valore nuovo', () {
      final List<FetteGiorno> f = _fette(_marMerGio);
      final List<Lettura> lett = <Lettura>[
        _l(DateTime(2026, 11, 18, 12), 60),
        _l(DateTime(2026, 11, 18, 18), 2), // reset improvviso
        _l(g2, 5),
      ];
      expect(quotaAdattiva(f, lett, ora: g2), 47);
      final List<PuntoLinea> a = lineaAdattiva(f, lett);
      expect(a.first, PuntoLinea(g2, 5));
      expect(a.last, PuntoLinea(fine, 99));
    });

    test('piano finito o senza lavoro: vuota', () {
      final List<FetteGiorno> f = _fette(_marMerGio);
      expect(lineaAdattiva(f, <Lettura>[_l(fine, 80)]), isEmpty);
      expect(statoAdattivo(f, <Lettura>[], ora: fine), isNull);
      expect(quotaAdattiva(f, <Lettura>[], ora: fine), 0);
      expect(lineaAdattiva(_fette(<int>[]), <Lettura>[_l(g2, 1)]), isEmpty);
    });

    test('letture in disordine: conta la più recente', () {
      final List<Lettura> lett = <Lettura>[
        _l(DateTime(2026, 11, 18, 12), 40),
        _l(DateTime(2026, 11, 18, 10), 20),
      ];
      expect(settNota(lett, g2), 40);
      final List<PuntoLinea> a = lineaAdattiva(_fette(_marMerGio), lett);
      expect(a.first, PuntoLinea(DateTime(2026, 11, 18, 12), 40));
    });
  });
  group('soglie giorno e rosso', () {
    test('esempio ordine: g1 33, g2 74,5 (g1 chiude 50), g3 99', () {
      final List<Lettura> lett = <Lettura>[_l(reset, 0), _l(g2, 50)];
      final List<SogliaGiorno> s = sogliaGiorni(_fette(_marMerGio), lett);
      expect(s.length, 7);
      expect(s[0], SogliaGiorno(inizio: reset, fine: g2, limite: 33));
      expect(s[1].limite, 74.5);
      expect(s[2].limite, 99);
      // giorni non lavoro dopo l'ultimo: piatta all'ultimo limite
      for (final SogliaGiorno x in s.skip(3)) {
        expect(x.limite, 99);
      }
      // 95% di 74,5 = 70,775 (il "70,8" dell'ordine)
      expect(s[1].limite! * 0.95, closeTo(70.775, 1e-9));
    });

    test(
      'la soglia di un giorno non cambia con letture dopo inizio giorno',
      () {
        final List<Lettura> a = <Lettura>[_l(reset, 0), _l(g2, 50)];
        final List<Lettura> b = <Lettura>[
          ...a,
          _l(DateTime(2026, 11, 18, 23), 60),
          _l(DateTime(2026, 11, 19, 3), 70),
        ];
        expect(
          sogliaGiorni(_fette(_marMerGio), a)[1],
          sogliaGiorni(_fette(_marMerGio), b)[1],
        );
        // g3 invece vede la lettura nuova: (99-70?) no, a inizio g3 vale 70
        expect(sogliaGiorni(_fette(_marMerGio), b)[2].limite, 99);
      },
    );

    test('giorni non lavoro prima del primo: nessuna soglia; poi piatta', () {
      final List<SogliaGiorno> s = sogliaGiorni(
        _fette(<int>[DateTime.thursday]),
        <Lettura>[],
      );
      expect(s[0].limite, isNull); // mar
      expect(s[1].limite, isNull); // mer
      expect(s[2].limite, 99); // gio = ultimo giorno = target
      expect(s[3].limite, 99); // ven non lavoro: piatta
    });

    test('piano senza lavoro: nessuna soglia', () {
      final List<SogliaGiorno> s = sogliaGiorni(_fette(<int>[]), <Lettura>[]);
      expect(s.length, 7);
      expect(s.every((SogliaGiorno x) => x.limite == null), isTrue);
    });

    test('sett gia sopra il target a inizio giorno: soglia = sett', () {
      final List<Lettura> lett = <Lettura>[_l(reset, 0), _l(g3, 99.5)];
      final List<SogliaGiorno> s = sogliaGiorni(_fette(_marMerGio), lett);
      expect(s[2].limite, 99.5);
    });

    test('rosso: attraversa la soglia dentro il giorno', () {
      final List<Lettura> lett = <Lettura>[_l(reset, 0), _l(g2, 50)];
      final List<SogliaGiorno> sg = sogliaGiorni(_fette(_marMerGio), lett);
      final List<Periodo> r = trattiRossi(sg, lett);
      // g1: soglia 33 * 0,95 = 31,35; segmento 0 -> 50 in 24 h
      expect(r.length, 1);
      const double h = 24 * 31.35 / 50;
      expect(
        r.single.inizio.difference(reset).inMicroseconds / 3.6e9,
        closeTo(h, 1e-6),
      );
      expect(r.single.fine, g2);
    });

    test('rosso g2: da 70,8 in poi (esempio ordine)', () {
      final DateTime fine2 = DateTime(2026, 11, 19, 6);
      final List<Lettura> lett = <Lettura>[
        _l(reset, 0),
        _l(g2, 50),
        _l(fine2, 75),
      ];
      final List<SogliaGiorno> sg = sogliaGiorni(_fette(_marMerGio), lett);
      final List<Periodo> r = trattiRossi(sg, lett);
      expect(r.length, 2);
      // g1 rosso fino a g2; poi g2 rosso da (70,775-50)/25 di 10 h
      expect(r[0].fine, g2);
      expect(r[1].fine, fine2);
      final double ore = r[1].inizio.difference(g2).inMicroseconds / 3.6e9;
      expect(ore, closeTo(10 * (70.775 - 50) / 25, 1e-6));
    });

    test(
      'rosso: soglia piu alta -> meno rosso; 100 = solo da soglia piena',
      () {
        final List<Lettura> lett = <Lettura>[_l(reset, 0), _l(g2, 50)];
        final List<SogliaGiorno> sg = sogliaGiorni(_fette(_marMerGio), lett);
        final List<Periodo> a = trattiRossi(sg, lett, percento: 50);
        final List<Periodo> b = trattiRossi(sg, lett, percento: 100);
        expect(
          a.single.fine.difference(a.single.inizio) >
              b.single.fine.difference(b.single.inizio),
          isTrue,
        );
      },
    );

    test(
      'rosso: tutto sotto soglia, un solo punto, nessuna lettura = vuoto',
      () {
        final List<SogliaGiorno> sg = sogliaGiorni(
          _fette(_marMerGio),
          <Lettura>[],
        );
        expect(trattiRossi(sg, <Lettura>[]), isEmpty);
        expect(trattiRossi(sg, <Lettura>[_l(reset, 99)]), isEmpty);
        final List<Lettura> basse = <Lettura>[
          _l(reset, 0),
          _l(DateTime(2026, 11, 18, 8), 10),
        ];
        expect(
          trattiRossi(sogliaGiorni(_fette(_marMerGio), basse), basse),
          isEmpty,
        );
      },
    );

    test('rosso: segmento a cavallo di due giorni si spezza al confine', () {
      final DateTime fine2 = DateTime(2026, 11, 19, 2);
      final List<Lettura> lett = <Lettura>[
        _l(reset, 0),
        _l(DateTime(2026, 11, 18, 14), 40),
        _l(fine2, 80),
      ];
      final List<SogliaGiorno> sg = sogliaGiorni(_fette(_marMerGio), lett);
      expect(sg[0].limite, 33);
      expect(sg[1].limite, closeTo(69.5, 1e-9)); // sett a inizio g2 = 40
      final List<Periodo> r = trattiRossi(sg, lett);
      expect(r.length, 2);
      double ore(DateTime a, DateTime b) =>
          a.difference(b).inMicroseconds / 3.6e9;
      // g1: soglia 31,35 su 0 -> 40 in 18 h, poi rosso fino al confine g2
      expect(ore(r[0].inizio, reset), closeTo(18 * 31.35 / 40, 1e-6));
      expect(r[0].fine, g2); // spezzato al confine (tratti uniti prima)
      // g2: valore al confine 60, soglia 69,5 * 0,95 = 66,025, 60 -> 80 in 6 h
      expect(ore(r[1].inizio, g2), closeTo(6 * (66.025 - 60) / 20, 1e-6));
      expect(r[1].fine, fine2);
    });

    test('O(n): 5000 letture in tempo breve', () {
      final List<Lettura> lett = <Lettura>[
        for (int i = 0; i < 5000; i++)
          _l(reset.add(Duration(minutes: i)), i * 99 / 5000),
      ];
      final Stopwatch w = Stopwatch()..start();
      final List<SogliaGiorno> sg = sogliaGiorni(_fette(_marMerGio), lett);
      trattiRossi(sg, lett);
      expect(w.elapsedMilliseconds, lessThan(1500));
    });
  });
}
