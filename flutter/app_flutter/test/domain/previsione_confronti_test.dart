// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/analisi.dart';
import 'package:traker_ia/domain/combinazioni.dart';
import 'package:traker_ia/domain/confronti.dart';
import 'package:traker_ia/domain/coppie.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/previsione.dart';
import 'package:traker_ia/domain/testi.dart';

import 'aiuti.dart';

void main() {
  final DateTime reset = t('2026-11-17 20:00');

  test('numeri in italiano', () {
    expect(numero(0.944), '0,94');
    expect(numero(null), '-');
    expect(testoOre(0.14), '0,1 h');
    expect(durata(1.5), '1h 30m');
  });

  test('previsione: finisce prima del reset', () {
    final List<Lettura> d = <Lettura>[
      l('2026-11-13 10:00', 50, null),
      l('2026-11-13 12:00', 60, null),
    ];
    final Previsione p = previsione(d, reset);
    expect(p.att, 60);
    expect(p.ritmo, closeTo(5, 1e-9));
    expect(p.consumo, closeTo(10, 1e-9));
    expect(p.ora100, t('2026-11-13 20:00'));
    expect(p.primaDelReset, isTrue);
    expect(p.debole, isFalse);
  });

  test('previsione: niente dati / consumo piccolo = debole', () {
    expect(previsione(<Lettura>[], reset).debole, isTrue);
    final List<Lettura> poco = <Lettura>[
      l('2026-11-13 10:00', 50, null),
      l('2026-11-13 12:00', 51, null),
    ];
    final Previsione p = previsione(poco, reset);
    expect(p.debole, isTrue);
  });

  test('budget del giorno', () {
    expect(budgetGiorno(60, t('2026-11-15 20:00'), reset), closeTo(20, 1e-9));
    expect(budgetGiorno(null, t('2026-11-15 20:00'), reset), isNull);
    expect(budgetGiorno(60, t('2026-11-18 20:00'), reset), isNull);
  });

  test('ritmo attivo e ore a pieno regime', () {
    final List<Lettura> d = <Lettura>[
      l('2026-11-13 08:00', 40, null),
      l('2026-11-13 10:00', 40, null),
      l('2026-11-13 12:00', 50, null),
    ];
    expect(ritmoAttivo(d), closeTo(5, 1e-9));
    expect(oreFullGasRimaste(d), closeTo(10, 1e-9));
  });

  test('frasi cosa dicono i dati', () {
    expect(frasi(<Lettura>[], reset, t('2026-11-13 12:00')), <String>[Testi.nessunDato]);
    final List<Lettura> d = <Lettura>[
      l('2026-11-13 10:00', 50, null),
      l('2026-11-13 12:00', 60, null),
    ];
    final List<String> f = frasi(d, reset, t('2026-11-15 20:00'));
    expect(f[0], 'A questo ritmo finisci ven 20:00. Reset mar 20:00.');
    expect(f[1], 'Oggi puoi usare ancora 20,0 punti.');
    expect(f[2], 'A pieno regime ti restano circa 8h 00m di lavoro.');
  });

  final List<Lettura> d = <Lettura>[
    l('2026-11-11 08:00', 10, null),
    l('2026-11-11 10:00', 14, null),
    l('2026-11-11 12:00', 15, null),
    l('2026-11-11 14:00', 16, null),
  ];

  test('confronto nota prima/dopo', () {
    final ConfrontoNota c = confrontoNota(d, t('2026-11-11 10:00'));
    expect(c.prima, closeTo(2, 1e-9));
    expect(c.dopo, closeTo(0.5, 1e-9));
    expect(c.orePrima, closeTo(2, 1e-9));
    expect(c.oreDopo, closeTo(4, 1e-9));
    expect(c.verdetto, Verdetto.sceso);
    expect(c.da, t('2026-11-10 20:00'));
    expect(testoOreNota(c), '(2,0 h prima / 4,0 h dopo)');
  });

  test('conta solo lavoro: filtro e ripiego', () {
    final List<Periodo> p = <Periodo>[
      (inizio: t('2026-11-11 09:00'), fine: t('2026-11-11 11:00')),
    ];
    final ConfrontoNota c = confrontoNota(d, t('2026-11-11 10:00'), periodi: p);
    expect(c.filtro, FiltroLavoro.lavoro);
    expect(c.orePrima, closeTo(1, 1e-9));
    expect(c.oreDopo, closeTo(1, 1e-9));
    final List<Periodo> solo = <Periodo>[
      (inizio: t('2026-11-11 08:00'), fine: t('2026-11-11 09:00')),
    ];
    final ConfrontoNota c2 = confrontoNota(d, t('2026-11-11 10:00'), periodi: solo);
    expect(c2.filtro, FiltroLavoro.tutto);
    expect(c2.oreDopo, closeTo(4, 1e-9));
    expect(testoFiltro(c2.filtro), Testi.nessunLavoro);
  });

  test('confronto combinazioni e motivo debole', () {
    const Combo a = (modelli: 'Opus', skill: '');
    const Combo b = (modelli: 'Opus', skill: 'caveman');
    final Map<Combo, RitmoCombo> tab = <Combo, RitmoCombo>{
      a: const RitmoCombo(ore: 3, sett: 1),
      b: const RitmoCombo(ore: 0.1, sett: 0.5),
    };
    final ConfrontoCombo c = confrontoCombinazioni(tab, a, b);
    expect(c.verdetto, Verdetto.datoDebole);
    expect(c.motivo, '(B solo 0,1 h)');
    final ConfrontoCombo c2 = confrontoCombinazioni(
      tab,
      a,
      b,
      tabLavoro: <Combo, RitmoCombo>{a: const RitmoCombo(ore: 2, sett: 1)},
    );
    expect(c2.filtro, FiltroLavoro.tutto);
    expect(motivoDebole(null, 2), '(manca un dato)');
    expect(motivoDebole(2, 2), '');
  });

  test('periodo combo e testi', () {
    final Periodo? p = periodoCombo(d, comboVuota);
    expect(p, (inizio: t('2026-11-11 08:00'), fine: t('2026-11-11 14:00')));
    expect(testoClassifica(<VoceClassifica>[]), Testi.classificaVuota);
    expect(
      testoClassifica(<VoceClassifica>[const VoceClassifica('Opus', 2, 0.87)]),
      'Classifica modelli (dal più vorace): Opus 0,87 (2,0 h)',
    );
    expect(spiegaVerdetto(Verdetto.sceso), startsWith('SCESO'));
    expect(spiegaCombo('A', comboVuota, p, 6), contains(Testi.spiegaNonSegnato));
    final ConfrontoNota c = confrontoNota(d, t('2026-11-11 10:00'));
    expect(spiegaPrima(c), contains('mar 10/11 20:00'));
    expect(spiegaDopo(c, t('2026-11-11 14:00')), contains('mer 11/11 14:00'));
  });
}
