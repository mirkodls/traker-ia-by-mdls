// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/analisi.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/tray.dart';

import 'aiuti.dart';

void main() {
  group('inizioSessione', () {
    test('reset noto nel futuro -> reset meno 5 ore', () {
      expect(
        inizioSessione(
          <Lettura>[],
          t('2026-11-13 12:00'),
          resetSess: t('2026-11-13 14:00'),
        ),
        t('2026-11-13 09:00'),
      );
    });

    test('reset passato ignorato, usa ultimo calo della barra', () {
      final List<Lettura> ls = <Lettura>[
        l('2026-11-13 08:00', 20, 60),
        l('2026-11-13 09:30', 21, 2),
        l('2026-11-13 11:00', 22, 10),
      ];
      expect(
        inizioSessione(
          ls,
          t('2026-11-13 12:00'),
          resetSess: t('2026-11-13 09:00'),
        ),
        t('2026-11-13 09:30'),
      );
    });

    test('nessun calo -> adesso meno 5 ore', () {
      final List<Lettura> ls = <Lettura>[l('2026-11-13 11:00', 22, 10)];
      expect(inizioSessione(ls, t('2026-11-13 12:00')), t('2026-11-13 07:00'));
    });
  });

  group('tendenzaUltimaOra', () {
    test('ultima ora più veloce di prima -> salita', () {
      final List<Lettura> ls = <Lettura>[
        l('2026-11-13 09:00', 20, 0),
        l('2026-11-13 11:00', 21, 4), // prima: 2 pt/h
        l('2026-11-13 12:00', 22, 10), // ultima ora: 6 pt/h
      ];
      final TendenzaOra r = tendenzaUltimaOra(
        ls,
        t('2026-11-13 12:00'),
        resetSess: t('2026-11-13 14:00'),
      );
      expect(r.ultima, closeTo(6, 1e-9));
      expect(r.prima, closeTo(2, 1e-9));
      expect(r.verdetto, Verdetto.salito);
    });

    test('ultima ora più lenta -> discesa', () {
      final List<Lettura> ls = <Lettura>[
        l('2026-11-13 09:00', 20, 0),
        l('2026-11-13 11:00', 21, 10), // prima: 5 pt/h
        l('2026-11-13 12:00', 22, 11), // ultima: 1 pt/h
      ];
      final TendenzaOra r = tendenzaUltimaOra(
        ls,
        t('2026-11-13 12:00'),
        resetSess: t('2026-11-13 14:00'),
      );
      expect(r.verdetto, Verdetto.sceso);
    });

    test('sessione iniziata da meno di 1 ora -> niente freccia', () {
      final List<Lettura> ls = <Lettura>[
        l('2026-11-13 11:30', 20, 0),
        l('2026-11-13 12:00', 21, 3),
      ];
      final TendenzaOra r = tendenzaUltimaOra(
        ls,
        t('2026-11-13 12:00'),
        resetSess: t('2026-11-13 16:30'),
      );
      expect(r.ultima, closeTo(6, 1e-9));
      expect(r.prima, isNull);
      expect(r.verdetto, Verdetto.datoDebole);
    });

    test('prima con poche letture -> dato debole', () {
      final List<Lettura> ls = <Lettura>[
        l('2026-11-13 10:50', 20, 0),
        l('2026-11-13 11:10', 20, 1),
        l('2026-11-13 12:00', 21, 3),
      ];
      final TendenzaOra r = tendenzaUltimaOra(
        ls,
        t('2026-11-13 12:00'),
        resetSess: t('2026-11-13 14:00'),
      );
      expect(r.prima, isNull);
      expect(r.verdetto, Verdetto.datoDebole);
    });
  });

  group('testoTray', () {
    test('nessuna lettura', () {
      expect(
        testoTray(<Lettura>[], t('2026-11-13 12:00')),
        'TraKer IA by mdls\nNessuna lettura ancora',
      );
    });

    test('percentuali, intensità e salita', () {
      final List<Lettura> ls = <Lettura>[
        l('2026-11-13 09:00', 20, 0),
        l('2026-11-13 11:00', 21, 4),
        l('2026-11-13 12:00', 25.5, 10),
      ];
      final String s = testoTray(
        ls,
        t('2026-11-13 12:00'),
        resetSess: t('2026-11-13 14:00'),
      );
      expect(
        s,
        'TraKer IA by mdls\n'
        'Sessione 10% · Settimana 25,5%\n'
        'Ultima ora 6,0 pt/h ↑ in salita (prima 2,0)',
      );
      expect(s.length, lessThanOrEqualTo(maxTestoTray));
    });

    test('ultima ora senza coppie -> riga vuota', () {
      final List<Lettura> ls = <Lettura>[l('2026-11-13 08:00', 20, 5)];
      expect(
        testoTray(ls, t('2026-11-13 12:00')).split('\n').last,
        'Ultima ora: nessun dato',
      );
    });

    test('letture nel futuro ignorate, valore vuoto saltato', () {
      final List<Lettura> ls = <Lettura>[
        l('2026-11-13 11:00', 20, 5),
        l('2026-11-13 11:30', null, 6),
        l('2026-11-13 13:00', 90, 90),
      ];
      expect(
        testoTray(ls, t('2026-11-13 12:00')).split('\n')[1],
        'Sessione 6% · Settimana 20%',
      );
    });
  });
}
