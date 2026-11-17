// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/piano_giorni.dart';

Piano _piano(int mask, {ConfinePiano confine = ConfinePiano.reset24h}) => Piano(
  nome: 'p',
  giorniMask: mask,
  inizio: DateTime(2026, 11, 10),
  confine: confine,
);

void main() {
  // Martedì 17/11/2026 20:00 (reset settimanale vero di Mirko).
  final DateTime reset = DateTime(2026, 11, 17, 20);

  test('reset24h: 7 fette da 24h, contigue, lavoro dalla maschera', () {
    final int m = mascheraGiorni(<int>[
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.friday,
    ]);
    final List<FetteGiorno> f = costruisciFette(_piano(m), reset);
    expect(f.length, 7);
    expect(f.first.inizio, reset);
    expect(f.last.fine, DateTime(2026, 11, 24, 20));
    for (int i = 0; i < 7; i++) {
      expect(f[i].indice, i);
      expect(f[i].peso, 1);
      expect(f[i].fine.difference(f[i].inizio), const Duration(hours: 24));
      if (i > 0) {
        expect(f[i].inizio, f[i - 1].fine);
      }
    }
    expect(
      <int>[for (final FetteGiorno x in f) x.giorno],
      <int>[
        2, 3, 4, 5, 6, 7, 1, //
      ],
    );
    expect(
      <bool>[for (final FetteGiorno x in f) x.lavoro],
      <bool>[
        true, true, false, true, false, false, false, //
      ],
    );
    // Fine ultimo giorno di lavoro = sabato 21/11 20:00 (fine fetta ven).
    expect(oraUltima(f), DateTime(2026, 11, 21, 20));
  });

  test('primi N giorni dal reset', () {
    expect(giorniDaMaschera(mascheraPrimiGiorni(3)), <int>[2, 3, 4]);
    expect(giorniDaMaschera(mascheraPrimiGiorni(7)), <int>[
      1,
      2,
      3,
      4,
      5,
      6,
      7,
    ]);
    expect(mascheraPrimiGiorni(9), tuttiIGiorni);
    expect(mascheraPrimiGiorni(0), 0);
    expect(mascheraPrimiGiorni(-2), 0);
    // Reset di domenica: dom, lun.
    expect(
      giorniDaMaschera(mascheraPrimiGiorni(2, giornoReset: DateTime.sunday)),
      <int>[1, 7],
    );
    final List<FetteGiorno> f = costruisciFette(
      _piano(mascheraPrimiGiorni(3)),
      reset,
    );
    expect(
      <bool>[for (final FetteGiorno x in f) x.lavoro],
      <bool>[
        true, true, true, false, false, false, false, //
      ],
    );
    expect(oraUltima(f), DateTime(2026, 11, 20, 20));
  });

  test('nessun giorno di lavoro: ora ultima null', () {
    expect(oraUltima(costruisciFette(_piano(0), reset)), isNull);
  });

  test('indiceFetta: inizio compreso, fine esclusa, fuori = -1', () {
    final List<FetteGiorno> f = costruisciFette(_piano(tuttiIGiorni), reset);
    expect(indiceFetta(f, reset), 0);
    expect(indiceFetta(f, DateTime(2026, 11, 18, 19, 59)), 0);
    expect(indiceFetta(f, DateTime(2026, 11, 18, 20)), 1);
    expect(indiceFetta(f, DateTime(2026, 11, 17, 19, 59)), -1);
    expect(indiceFetta(f, DateTime(2026, 11, 24, 20)), -1);
  });

  test('mezzanotte: pezzi corti ai bordi, pesi sommano 7', () {
    final List<FetteGiorno> f = costruisciFette(
      _piano(tuttiIGiorni, confine: ConfinePiano.mezzanotte),
      reset,
    );
    expect(f.length, 8);
    expect(f.first.inizio, reset);
    expect(f.first.fine, DateTime(2026, 11, 18));
    expect(f.first.peso, closeTo(4 / 24, 1e-12));
    expect(f.last.inizio, DateTime(2026, 11, 24));
    expect(f.last.fine, DateTime(2026, 11, 24, 20));
    expect(f.last.peso, closeTo(20 / 24, 1e-12));
    double s = 0;
    for (final FetteGiorno x in f) {
      s += x.peso;
    }
    expect(s, closeTo(7, 1e-12));
    expect(f[3].peso, 1);
    expect(f[3].giorno, DateTime.friday);
  });

  test('mezzanotte con reset a mezzanotte: 7 giorni interi', () {
    final List<FetteGiorno> f = costruisciFette(
      _piano(tuttiIGiorni, confine: ConfinePiano.mezzanotte),
      DateTime(2026, 11, 17),
    );
    expect(f.length, 7);
    expect(f.every((FetteGiorno x) => x.peso == 1), isTrue);
  });

  test('UTC resta UTC', () {
    final List<FetteGiorno> f = costruisciFette(
      _piano(tuttiIGiorni),
      DateTime.utc(2026, 10, 20, 19),
    );
    expect(f.every((FetteGiorno x) => x.inizio.isUtc), isTrue);
    expect(f.last.fine, DateTime.utc(2026, 10, 27, 19));
  });

  // Ora legale Europa: 25/10/2026 (03:00 -> 02:00) e 28/03/2027 (02 -> 03).
  // I confini restano alle 20:00 di orologio; con fuso italiano un giorno
  // dura 25h (ottobre) o 23h (marzo). Su fuso senza ora legale: 24h.
  for (final (String nome, DateTime r, int fettaCambio, int oreCambio)
      in <(String, DateTime, int, int)>[
        ('ottobre', DateTime(2026, 10, 20, 20), 4, 25),
        ('marzo', DateTime(2027, 3, 23, 20), 4, 23),
      ]) {
    test('ora legale $nome: confini alle 20:00 locali', () {
      final List<FetteGiorno> f = costruisciFette(_piano(tuttiIGiorni), r);
      expect(f.length, 7);
      for (final FetteGiorno x in f) {
        expect(x.inizio.hour, 20);
        expect(x.inizio.minute, 0);
        expect(x.peso, 1);
      }
      final DateTime prima = DateTime(r.year, r.month, r.day + 4, 12);
      final DateTime dopo = DateTime(r.year, r.month, r.day + 5, 12);
      final bool cambia = prima.timeZoneOffset != dopo.timeZoneOffset;
      for (int i = 0; i < 7; i++) {
        final int ore = f[i].fine.difference(f[i].inizio).inHours;
        expect(ore, cambia && i == fettaCambio ? oreCambio : 24);
      }
      expect(f.last.fine, DateTime(r.year, r.month, r.day + 7, 20));
    });
  }

  test('confine mezzanotte: testo', () {
    expect(ConfinePiano.mezzanotte.testo, 'mezzanotte');
    expect(ConfinePiano.daTesto('mezzanotte'), ConfinePiano.mezzanotte);
  });
}
