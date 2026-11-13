// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/tempo.dart';

import 'aiuti.dart';

void main() {
  test('formatta e interpreta', () {
    expect(formatta(DateTime(2026, 3, 4, 5, 6)), '2026-03-04 05:06');
    expect(interpreta(' 2026-11-10 20:00 '), DateTime(2026, 11, 10, 20));
    expect(interpreta('2026-02-31 10:00'), isNull);
    expect(interpreta('2026-11-10 25:00'), isNull);
    expect(interpreta('ciao'), isNull);
  });

  test('inizio settimana = martedì 20:00', () {
    expect(inizioSettimana(t('2026-11-11 17:12')), t('2026-11-10 20:00'));
    expect(inizioSettimana(t('2026-11-10 19:59')), t('2026-11-03 20:00'));
    expect(inizioSettimana(t('2026-11-10 20:00')), t('2026-11-10 20:00'));
    expect(prossimoReset(t('2026-11-13 10:00')), t('2026-11-17 20:00'));
  });

  test('reset arrotondato ±2 min', () {
    expect(arrotondaReset(t('2026-11-17 19:59')), t('2026-11-17 20:00'));
    expect(arrotondaReset(t('2026-11-17 20:02')), t('2026-11-17 20:00'));
    expect(arrotondaReset(t('2026-11-17 20:03')), t('2026-11-17 20:03'));
    expect(arrotondaReset(t('2026-11-17 19:57')), t('2026-11-17 19:57'));
    expect(arrotondaReset(null), isNull);
  });

  test('quando e ore', () {
    expect(quando(t('2026-11-17 20:00')), 'mar 20:00');
    expect(quandoData(t('2026-11-17 20:05')), 'mar 17/11 20:05');
    expect(oreTra(t('2026-11-17 20:00'), t('2026-11-17 21:30')), 1.5);
  });

  test('ordina per ora stabile', () {
    final List<(DateTime, int)> v = <(DateTime, int)>[
      (t('2026-01-01 10:00'), 1),
      (t('2026-01-01 09:00'), 2),
      (t('2026-01-01 10:00'), 3),
    ];
    final List<int> o = ordinaPerOra(v, ((DateTime, int) x) => x.$1)
        .map(((DateTime, int) x) => x.$2)
        .toList();
    expect(o, <int>[2, 1, 3]);
  });
}
