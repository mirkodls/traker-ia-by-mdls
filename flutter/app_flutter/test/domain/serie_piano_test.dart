// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/piano_giorni.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/serie_piano.dart';

final DateTime reset = DateTime(2026, 11, 17, 20);

Piano _piano(int mask, {double target = 100}) =>
    Piano(nome: 'p', giorniMask: mask, inizio: reset, targetPct: target);

Lettura _l(DateTime ora, double sett) => Lettura(ora: ora, sett: sett);

void main() {
  group('resetVisibili', () {
    test('da dentro la settimana: solo il suo reset', () {
      expect(resetVisibili(DateTime(2026, 11, 19), reset), <DateTime>[reset]);
    });

    test('da settimana prima: due reset in ordine di tempo', () {
      expect(resetVisibili(DateTime(2026, 11, 12), reset), <DateTime>[
        DateTime(2026, 11, 10, 20),
        reset,
      ]);
    });

    test('troppe settimane: solo l\'attuale', () {
      expect(resetVisibili(DateTime(2025, 6), reset), <DateTime>[reset]);
    });
  });

  group('calcolaSeriePiano', () {
    test('7 fette a settimana e linee solo per la settimana attuale', () {
      final SeriePiano s = calcolaSeriePiano(
        _piano(tuttiIGiorni),
        <Lettura>[],
        da: DateTime(2026, 11, 12),
        reset: reset,
      );
      expect(s.fette.length, 14);
      expect(s.fette.first.inizio, DateTime(2026, 11, 10, 20));
      expect(s.fette.last.fine, DateTime(2026, 11, 24, 20));
      expect(s.inizioSettimana, reset);
      expect(s.ideale.first.ora, reset);
      expect(s.ideale.last.valore, 100);
      expect(s.ideale.last.ora, DateTime(2026, 11, 24, 20));
    });

    test('giorni scelti: fette non lavoro, ideale si ferma all\'ultima', () {
      final int tre = mascheraPrimiGiorni(3);
      final SeriePiano s = calcolaSeriePiano(
        _piano(tre),
        <Lettura>[],
        da: reset,
        reset: reset,
      );
      expect(s.fette.map((FetteGiorno f) => f.lavoro).toList(), <bool>[
        true,
        true,
        true,
        false,
        false,
        false,
        false,
      ]);
      expect(s.ideale.last.ora, DateTime(2026, 11, 20, 20));
      expect(s.ideale.last.valore, 100);
    });

    test('adattiva usa solo le letture della settimana attuale', () {
      final SeriePiano s = calcolaSeriePiano(
        _piano(mascheraPrimiGiorni(3)),
        <Lettura>[
          _l(DateTime(2026, 11, 14, 10), 90), // settimana prima: ignorata
          _l(DateTime(2026, 11, 17, 22), 40),
        ],
        da: reset,
        reset: reset,
      );
      expect(s.adattiva.last.valore, 100);
      expect(s.adattiva.first.valore, 40);
    });

    test('le liste sono bloccate (il grafico non le cambia)', () {
      final SeriePiano s = calcolaSeriePiano(
        _piano(tuttiIGiorni),
        <Lettura>[],
        da: reset,
        reset: reset,
      );
      expect(() => s.fette.add(s.fette.first), throwsUnsupportedError);
      expect(s.ideale.clear, throwsUnsupportedError);
      expect(s.adattiva.clear, throwsUnsupportedError);
    });
  });

  group('CachePiano', () {
    final List<Lettura> ls = <Lettura>[_l(DateTime(2026, 11, 17, 22), 4)];

    test('stessi dati = stesso oggetto, un solo calcolo', () {
      final CachePiano c = CachePiano();
      final SeriePiano a = c.serie(
        _piano(tuttiIGiorni),
        ls,
        da: reset,
        reset: reset,
      );
      final SeriePiano b = c.serie(
        _piano(tuttiIGiorni),
        ls,
        da: reset,
        reset: reset,
      );
      expect(identical(a, b), isTrue);
      expect(c.calcoli, 1);
    });

    test('periodo diverso nella stessa settimana: ancora cache', () {
      final CachePiano c = CachePiano();
      c
        ..serie(_piano(tuttiIGiorni), ls, da: reset, reset: reset)
        ..serie(
          _piano(tuttiIGiorni),
          ls,
          da: DateTime(2026, 11, 18),
          reset: reset,
        );
      expect(c.calcoli, 1);
    });

    test('ricalcola se cambiano giorni, target, letture o settimana', () {
      final CachePiano c = CachePiano();
      c.serie(_piano(tuttiIGiorni), ls, da: reset, reset: reset);
      expect(c.calcoli, 1);
      c.serie(_piano(mascheraPrimiGiorni(3)), ls, da: reset, reset: reset);
      expect(c.calcoli, 2);
      c.serie(
        _piano(mascheraPrimiGiorni(3), target: 99),
        ls,
        da: reset,
        reset: reset,
      );
      expect(c.calcoli, 3);
      c.serie(
        _piano(mascheraPrimiGiorni(3), target: 99),
        <Lettura>[...ls, _l(DateTime(2026, 11, 18, 9), 9)],
        da: reset,
        reset: reset,
      );
      expect(c.calcoli, 4);
      c.serie(
        _piano(mascheraPrimiGiorni(3), target: 99),
        ls,
        da: DateTime(2026, 11, 12),
        reset: reset,
      );
      expect(c.calcoli, 5);
      final DateTime nuovo = DateTime(2026, 11, 24, 20);
      c.serie(
        _piano(mascheraPrimiGiorni(3), target: 99),
        ls,
        da: nuovo,
        reset: nuovo,
      );
      expect(c.calcoli, 6);
    });
  });

  group('preferenze piano', () {
    test('predefiniti: tutti i giorni, due linee accese', () {
      final Preferenze p = Preferenze();
      expect(p.giorniPiano, tuttiIGiorni);
      expect(p.lineaIdeale, isTrue);
      expect(p.lineaAdattiva, isTrue);
    });

    test('andata e ritorno nelle impostazioni', () {
      final Preferenze p = Preferenze(
        giorniPiano: mascheraPrimiGiorni(4),
        lineaIdeale: false,
      );
      final Map<String, String> m = p.aMappa();
      expect(m[Chiavi.v2PianoGiorni], '${mascheraPrimiGiorni(4)}');
      expect(m[Chiavi.v2LineaIdeale], '0');
      expect(m[Chiavi.v2LineaAdattiva], '1');
      final Preferenze q = Preferenze.daMappa(m);
      expect(q.giorniPiano, p.giorniPiano);
      expect(q.lineaIdeale, isFalse);
      expect(q.lineaAdattiva, isTrue);
      expect(
        Chiavi.tutte,
        containsAll(<String>[
          Chiavi.v2PianoGiorni,
          Chiavi.v2LineaIdeale,
          Chiavi.v2LineaAdattiva,
        ]),
      );
    });

    test('maschera rotta o 0 -> tutti i giorni; bit fuori range tolti', () {
      expect(
        Preferenze.daMappa(<String, String?>{Chiavi.v2PianoGiorni: '0'})
            .giorniPiano,
        tuttiIGiorni,
      );
      expect(
        Preferenze.daMappa(<String, String?>{Chiavi.v2PianoGiorni: 'x'})
            .giorniPiano,
        tuttiIGiorni,
      );
      expect(Preferenze(giorniPiano: 0x181).giorniPiano, 1);
    });

    test('toccaGiorno: accende/spegne, l\'ultimo giorno non si spegne', () {
      Preferenze p = Preferenze(giorniPiano: mascheraGiorni(<int>[2, 3]));
      p = p.toccaGiorno(3);
      expect(giorniDaMaschera(p.giorniPiano), <int>[2]);
      expect(p.toccaGiorno(2).giorniPiano, p.giorniPiano);
      p = p.toccaGiorno(7);
      expect(giorniDaMaschera(p.giorniPiano), <int>[2, 7]);
      expect(p.toccaGiorno(0).giorniPiano, p.giorniPiano);
      expect(p.toccaGiorno(8).giorniPiano, p.giorniPiano);
    });
  });
}
