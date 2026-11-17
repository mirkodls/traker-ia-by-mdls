// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/intensita.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/serie_intensita.dart';
import 'package:traker_ia/domain/tempo.dart';

DateTime _t(String s) => interpreta(s)!;

/// 07:00-09:00 ogni 10 min: sess +1 (6 pt/h), sett +1 ogni 30 min.
/// 09:10-11:00 ogni 10 min: solo sett (+1 ogni 30 min = 2 pt/h).
List<Lettura> _letture() {
  final DateTime base = _t('2026-11-13 07:00');
  final List<Lettura> out = <Lettura>[];
  for (int i = 0; i <= 24; i++) {
    out.add(
      Lettura(
        ora: base.add(Duration(minutes: 10 * i)),
        sett: 20.0 + i ~/ 3,
        sess: i <= 12 ? 1.0 + i : null,
      ),
    );
  }
  return out;
}

void main() {
  final DateTime da = _t('2026-11-13 07:00');
  final DateTime a = _t('2026-11-13 11:00');

  group('calcolaIntensitaV2 + statIntensita', () {
    test('due fonti, medie separate, nessuna conversione di unità', () {
      final IntensitaV2 r = calcolaIntensitaV2(
        _letture(),
        const <Evento>[],
        da,
        a,
        passoMin: 10,
      );
      expect(r.punti, isNotEmpty);
      expect(r.stat.n5h, greaterThan(0));
      expect(r.stat.n7gg, greaterThan(0));
      expect(r.stat.media5h, closeTo(6, 1.5));
      expect(r.stat.media7gg, closeTo(2, 1.5));
      expect(r.max5h, greaterThanOrEqualTo(1));
      expect(r.max7gg, greaterThanOrEqualTo(1));
      expect(r.soloLavoro, isFalse);
      expect(r.finestraPostumaMin, 60);
    });

    test('finestra non ammessa -> 60; 30/120 ok', () {
      expect(
        calcolaIntensitaV2(
          _letture(),
          const <Evento>[],
          da,
          a,
          finestraPostumaMin: 45,
        ).finestraPostumaMin,
        60,
      );
      expect(
        calcolaIntensitaV2(
          _letture(),
          const <Evento>[],
          da,
          a,
          finestraPostumaMin: 120,
        ).finestraPostumaMin,
        120,
      );
    });

    test('intervallo vuoto o rovesciato -> serie vuota, asse >= 1', () {
      final IntensitaV2 r = calcolaIntensitaV2(
        _letture(),
        const <Evento>[],
        a,
        da,
      );
      expect(r.punti, isEmpty);
      expect(r.stat.vuota, isTrue);
      expect(r.max5h, 1);
      expect(r.max7gg, 1);
    });

    test('nessuna lettura: nessun punto valido, nessuna media', () {
      final IntensitaV2 r = calcolaIntensitaV2(
        const <Lettura>[],
        const <Evento>[],
        da,
        a,
      );
      expect(r.stat.vuota, isTrue);
    });

    test('solo lavoro: fuori fascia = buco, dentro come prima', () {
      final List<Evento> ev = <Evento>[
        Evento(ora: _t('2026-11-13 07:00'), tipo: TipoEvento.inizio),
        Evento(ora: _t('2026-11-13 09:00'), tipo: TipoEvento.fine),
      ];
      final IntensitaV2 tutto = calcolaIntensitaV2(
        _letture(),
        ev,
        da,
        a,
        passoMin: 10,
      );
      final IntensitaV2 lav = calcolaIntensitaV2(
        _letture(),
        ev,
        da,
        a,
        passoMin: 10,
        soloLavoro: true,
      );
      expect(lav.soloLavoro, isTrue);
      expect(lav.stat.n7gg, lessThan(tutto.stat.n7gg));
      expect(lav.stat.media5h, closeTo(6, 1.5));
      // dopo le 09:30 (fuori Lavoro) nessun punto valido
      for (final PuntoIntensita p in lav.punti) {
        if (p.ora.isAfter(_t('2026-11-13 09:30'))) {
          expect(p.valore, isNull);
        }
      }
    });

    test('statIntensita: buchi esclusi, errore medio', () {
      final StatIntensita s = statIntensita(<PuntoIntensita>[
        PuntoIntensita(
          ora: da,
          fonte: FonteIntensita.cinqueOre,
          valore: 4,
          errore: 2,
        ),
        PuntoIntensita(
          ora: da,
          fonte: FonteIntensita.cinqueOre,
          valore: 8,
          errore: 4,
        ),
        PuntoIntensita(ora: da, fonte: FonteIntensita.cinqueOre),
        PuntoIntensita(
          ora: da,
          fonte: FonteIntensita.setteGiorni,
          valore: 1,
          errore: 1,
        ),
      ]);
      expect(s.media5h, 6);
      expect(s.errore5h, 3);
      expect(s.n5h, 2);
      expect(s.media7gg, 1);
      expect(s.n7gg, 1);
      expect(statIntensita(const <PuntoIntensita>[]).vuota, isTrue);
    });
  });

  group('CacheIntensita', () {
    final List<Lettura> ls = _letture();
    final DateTime adesso = _t('2026-11-13 11:00');

    IntensitaV2 chiama(
      CacheIntensita c, {
      List<Lettura>? l,
      List<Evento> ev = const <Evento>[],
      DateTime? dal,
      DateTime? al,
      int n = 60,
      bool lav = false,
    }) => c.serie(
      l ?? ls,
      ev,
      dal ?? da,
      al ?? a,
      adesso,
      passoMin: 10,
      finestraPostumaMin: n,
      soloLavoro: lav,
    );

    test('stessi dati: 1 calcolo solo, stesso oggetto', () {
      final CacheIntensita c = CacheIntensita();
      final IntensitaV2 x = chiama(c);
      final IntensitaV2 y = chiama(c);
      expect(identical(x, y), isTrue);
      expect(c.calcoli, 1);
    });

    test('asse che avanza di meno di un passo: nessun ricalcolo', () {
      final CacheIntensita c = CacheIntensita();
      chiama(c, dal: _t('2026-11-13 07:01'), al: _t('2026-11-13 10:51'));
      chiama(c, dal: _t('2026-11-13 07:03'), al: _t('2026-11-13 10:55'));
      expect(c.calcoli, 1);
      chiama(c, dal: _t('2026-11-13 07:03'), al: _t('2026-11-13 11:00'));
      expect(c.calcoli, 2);
    });

    test('cambio finestra, solo lavoro, nuova lettura, nuovo evento', () {
      final CacheIntensita c = CacheIntensita();
      chiama(c);
      chiama(c, n: 120);
      expect(c.calcoli, 2);
      chiama(c, n: 120, lav: true);
      expect(c.calcoli, 3);
      chiama(c, n: 120, lav: true);
      expect(c.calcoli, 3);
      chiama(
        c,
        n: 120,
        lav: true,
        l: <Lettura>[
          ...ls,
          Lettura(ora: _t('2026-11-13 11:00'), sett: 29),
        ],
      );
      expect(c.calcoli, 4);
      chiama(
        c,
        n: 120,
        lav: true,
        l: <Lettura>[
          ...ls,
          Lettura(ora: _t('2026-11-13 11:00'), sett: 29),
        ],
        ev: <Evento>[
          Evento(ora: _t('2026-11-13 08:00'), tipo: TipoEvento.inizio),
        ],
      );
      expect(c.calcoli, 5);
    });

    test('asse nel futuro: punti solo fino ad adesso', () {
      final CacheIntensita c = CacheIntensita();
      final IntensitaV2 r = chiama(c, al: _t('2026-11-20 20:00'));
      expect(r.punti, isNotEmpty);
      expect(r.punti.last.ora.isAfter(adesso), isFalse);
    });

    test('20.000 letture: secondo giro gratis (cache)', () {
      final List<Lettura> grandi = <Lettura>[
        for (int i = 0; i < 20000; i++)
          Lettura(
            ora: _t('2026-10-01 00:00').add(Duration(minutes: 3 * i)),
            sett: (i % 1000) / 10,
            sess: (i % 50).toDouble(),
          ),
      ];
      final CacheIntensita c = CacheIntensita();
      final DateTime fine = grandi.last.ora;
      c.serie(
        grandi,
        const <Evento>[],
        _t('2026-10-01 00:00'),
        fine,
        fine,
        passoMin: 60,
      );
      final Stopwatch sw = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        c.serie(
          grandi,
          const <Evento>[],
          _t('2026-10-01 00:00'),
          fine,
          fine,
          passoMin: 60,
        );
      }
      sw.stop();
      expect(c.calcoli, 1);
      expect(sw.elapsedMilliseconds, lessThan(500));
    });
  });

  group('puntoIntensitaA', () {
    final List<PuntoIntensita> pts = <PuntoIntensita>[
      for (int i = 0; i < 5; i++)
        PuntoIntensita(
          ora: da.add(Duration(minutes: 10 * i)),
          fonte: FonteIntensita.cinqueOre,
          valore: i.toDouble(),
        ),
    ];

    test('più vicino, in mezzo e ai bordi', () {
      expect(puntoIntensitaA(pts, _t('2026-11-13 07:21'))!.valore, 2);
      expect(puntoIntensitaA(pts, _t('2026-11-13 07:26'))!.valore, 3);
      expect(puntoIntensitaA(pts, _t('2026-11-13 07:00'))!.valore, 0);
      expect(puntoIntensitaA(pts, _t('2026-11-13 07:40'))!.valore, 4);
    });

    test('lontano o vuota -> null', () {
      expect(puntoIntensitaA(pts, _t('2026-11-13 12:00')), isNull);
      expect(puntoIntensitaA(pts, _t('2026-11-13 05:00')), isNull);
      expect(puntoIntensitaA(const <PuntoIntensita>[], da), isNull);
    });
  });

  group('comandoLavoroDaNota', () {
    test('comandi esatti', () {
      expect(comandoLavoroDaNota('lavoro'), TipoEvento.inizio);
      expect(comandoLavoroDaNota('  Lavoro '), TipoEvento.inizio);
      expect(comandoLavoroDaNota('LAVORO.'), TipoEvento.inizio);
      expect(comandoLavoroDaNota('fine lavoro'), TipoEvento.fine);
      expect(comandoLavoroDaNota('Fine   Lavoro!'), TipoEvento.fine);
    });

    test('note normali NON sono comandi', () {
      expect(comandoLavoroDaNota('lavoro su excel'), isNull);
      expect(comandoLavoroDaNota('attivato caveman'), isNull);
      expect(comandoLavoroDaNota('finelavoro'), isNull);
      expect(comandoLavoroDaNota('fine lavoro oggi'), isNull);
      expect(comandoLavoroDaNota(''), isNull);
    });
  });
}
