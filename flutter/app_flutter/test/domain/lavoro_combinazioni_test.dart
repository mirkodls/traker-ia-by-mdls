// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/analisi.dart';
import 'package:traker_ia/domain/combinazioni.dart';
import 'package:traker_ia/domain/coppie.dart';
import 'package:traker_ia/domain/lavoro.dart';
import 'package:traker_ia/domain/modelli.dart';

import 'aiuti.dart';

void main() {
  test('periodi lavoro: doppi ignorati, aperto fino ad adesso', () {
    final List<Evento> e = <Evento>[
      Evento(ora: t('2026-11-11 08:00'), tipo: TipoEvento.fine),
      Evento(ora: t('2026-11-11 09:00'), tipo: TipoEvento.inizio),
      Evento(ora: t('2026-11-11 09:30'), tipo: TipoEvento.inizio),
      Evento(ora: t('2026-11-11 10:00'), tipo: TipoEvento.fine),
      Evento(ora: t('2026-11-11 11:00'), tipo: TipoEvento.nota),
      Evento(ora: t('2026-11-11 12:00'), tipo: TipoEvento.inizio),
    ];
    final List<Periodo> p = periodiLavoro(e, t('2026-11-11 13:00'));
    expect(p.length, 2);
    expect(p[0], (inizio: t('2026-11-11 09:00'), fine: t('2026-11-11 10:00')));
    expect(p[1], (inizio: t('2026-11-11 12:00'), fine: t('2026-11-11 13:00')));
    expect(inLavoro(p, t('2026-11-11 09:30')), isTrue);
    expect(inLavoro(p, t('2026-11-11 11:00')), isFalse);
  });

  test('ritmo solo dentro i periodi', () {
    final List<Lettura> d = <Lettura>[
      l('2026-11-11 08:00', 0, null),
      l('2026-11-11 10:00', 4, null),
    ];
    final List<Periodo> p = <Periodo>[
      (inizio: t('2026-11-11 09:00'), fine: t('2026-11-11 09:30')),
    ];
    final RitmoOre r = ritmoOre(d, Campo.sett, periodi: p);
    expect(r.ore, closeTo(0.5, 1e-9));
    expect(r.ritmo, closeTo(2, 1e-9));
  });

  test('norm ed etichetta', () {
    expect(norm('Sonnet| Opus|Opus||'), 'Opus|Sonnet');
    expect(norm(null), '');
    expect(unisci(<String>['b', 'a']), 'a|b');
    expect(etichetta(comboVuota), '(non segnato)');
    expect(etichetta((modelli: 'Opus|Sonnet', skill: 'caveman')), 'Opus + Sonnet  ·  caveman');
    expect(etichetta((modelli: '', skill: 'x')), 'nessun modello  ·  x');
  });

  final List<Lettura> d = <Lettura>[
    l('2026-11-11 10:00', 10, 10, modelli: 'Opus'),
    l('2026-11-11 12:00', 14, 30, modelli: 'Opus', skill: 'caveman'),
    l('2026-11-11 14:00', 15, 40, modelli: 'Opus|Sonnet'),
    l('2026-11-11 16:00', 17, 50, modelli: 'Opus', skill: 'caveman'),
  ];

  test('ritmo per combinazione: va alla lettura di arrivo', () {
    final Map<Combo, RitmoCombo> tab = ritmoPerCombinazione(d);
    final RitmoCombo c = tab[(modelli: 'Opus', skill: 'caveman')]!;
    expect(c.ore, closeTo(4, 1e-9));
    expect(c.sett, closeTo(1.5, 1e-9));
    expect(c.sess, closeTo(7.5, 1e-9));
    expect(tab[(modelli: 'Opus|Sonnet', skill: '')]!.sett, closeTo(0.5, 1e-9));
  });

  test('confronta combinazioni', () {
    const RitmoCombo a = RitmoCombo(ore: 2, sett: 1);
    const RitmoCombo b = RitmoCombo(ore: 2, sett: 0.5);
    expect(confronta(a, b), Verdetto.sceso);
    expect(confronta(a, const RitmoCombo(ore: 0.5, sett: 0.5)), Verdetto.datoDebole);
    expect(confronta(null, b), Verdetto.datoDebole);
  });

  test('classifica modelli dal più vorace', () {
    final List<VoceClassifica> c = classificaModelli(d);
    expect(c.map((VoceClassifica v) => v.modello).toList(), <String>['Opus', 'Sonnet']);
    expect(c.first.ritmo, closeTo(7 / 6, 1e-9));
    expect(c.last.ore, closeTo(2, 1e-9));
  });

  test('stato a un\'ora', () {
    expect(statoA(d, t('2026-11-11 13:00')), (modelli: 'Opus|Sonnet', skill: ''));
    expect(statoA(d, t('2026-11-11 20:00')), (modelli: 'Opus', skill: 'caveman'));
    expect(statoA(<Lettura>[], t('2026-11-11 20:00')), isNull);
  });
}
