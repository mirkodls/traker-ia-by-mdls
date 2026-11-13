// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/analisi.dart';
import 'package:traker_ia/domain/coppie.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/tempo.dart';

import 'aiuti.dart';

void main() {
  test('leggi risposta: percento e reset in ora locale', () {
    final Uso u = leggiRisposta(<String, Object?>{
      'five_hour': <String, Object?>{
        'utilization': 14,
        'resets_at': '2026-11-11T20:00:00.123456789Z',
      },
      'seven_day': <String, Object?>{'utilization': 21.0, 'resets_at': null},
    });
    expect(u.sess, 14);
    expect(u.sett, 21);
    expect(u.resetSess, alMinuto(DateTime.utc(2026, 11, 11, 20).toLocal()));
    expect(u.resetSett, isNull);
  });

  test('leggi risposta: frazioni 0-1 scalate, roba strana ignorata', () {
    final Uso u = leggiRisposta(<String, Object?>{
      'five_hour': <String, Object?>{'utilization': 0.25},
      'seven_day': <String, Object?>{'utilization': 1},
    });
    expect(u.sess, 25);
    expect(u.sett, 100);
    expect(leggiRisposta('rotto').vuoto, isTrue);
    expect(leggiRisposta(null).vuoto, isTrue);
  });

  test('data senza fuso = UTC', () {
    expect(
      dataUtcALocale('2026-11-11T20:00:00'),
      alMinuto(DateTime.utc(2026, 11, 11, 20).toLocal()),
    );
    expect(dataUtcALocale(''), isNull);
    expect(dataUtcALocale(5), isNull);
  });

  final List<Lettura> dati = <Lettura>[
    l('2026-11-11 10:00', 10, 50),
    l('2026-11-11 11:00', 12, 60),
    l('2026-11-11 12:00', 13, 2),
    l('2026-11-11 13:00', 13, 4),
  ];

  test('coppie: reset escluso', () {
    expect(coppie(dati, Campo.sess).length, 2);
    expect(coppie(dati, Campo.sett).length, 3);
  });

  test('ritmo intero e tagliato in proporzione', () {
    expect(ritmo(dati, Campo.sett), closeTo(1, 1e-9));
    expect(
      ritmo(dati, Campo.sett, da: t('2026-11-11 10:30'), a: t('2026-11-11 11:30')),
      closeTo(1.5, 1e-9),
    );
    expect(ritmo(<Lettura>[], Campo.sett), isNull);
  });

  test('trova reset', () {
    expect(trovaReset(dati, Campo.sess), <DateTime>[t('2026-11-11 12:00')]);
  });

  test('intensità: media mobile 30 min e reset esclusi', () {
    final List<PuntoSerie> s = serieIntensita(
      dati,
      t('2026-11-11 10:00'),
      t('2026-11-11 13:00'),
      passoMin: 60,
    );
    expect(s.length, 4);
    expect(s[0].valore, isNull);
    expect(s[1].valore, closeTo(10, 1e-9));
    expect(s[2].valore, isNull);
    expect(s[3].valore, closeTo(2, 1e-9));
    expect(intensitaA(dati, t('2026-11-11 11:00')), closeTo(10, 1e-9));
  });

  test('intensità uguale al ritmo a finestra', () {
    final List<PuntoSerie> s = serieIntensita(
      dati,
      t('2026-11-11 10:10'),
      t('2026-11-11 13:00'),
      passoMin: 7,
    );
    for (final PuntoSerie p in s) {
      final double? atteso = intensitaA(dati, p.ora);
      if (atteso == null) {
        expect(p.valore, isNull);
      } else {
        expect(p.valore, closeTo(atteso, 1e-9));
      }
    }
  });

  test('valore a: esatto, stimato, reset', () {
    final ValoreA e = valoreA(dati, Campo.sett, t('2026-11-11 11:00'));
    expect(e.valore, 12);
    expect(e.esatto, isTrue);
    final ValoreA s = valoreA(dati, Campo.sett, t('2026-11-11 10:30'));
    expect(s.valore, closeTo(11, 1e-9));
    expect(s.esatto, isFalse);
    expect(valoreA(dati, Campo.sess, t('2026-11-11 11:30')).valore, isNull);
    expect(valoreA(dati, Campo.sett, t('2026-11-11 09:00')).valore, isNull);
  });

  test('ritmo per presenza', () {
    final List<Lettura> d = <Lettura>[
      l('2026-11-11 10:00', 10, null),
      l('2026-11-11 11:00', 12, null, alPc: true),
      l('2026-11-11 13:00', 13, null, alPc: false),
      l('2026-11-11 14:00', 20, null),
    ];
    final ({double? alPc, double? automatico}) r = ritmoPerPresenza(d);
    expect(r.alPc, closeTo(2, 1e-9));
    expect(r.automatico, closeTo(0.5, 1e-9));
  });

  test('verdetto ±10%', () {
    expect(verdetto(1, 0.89), Verdetto.sceso);
    expect(verdetto(1, 1.1), Verdetto.salito);
    expect(verdetto(1, 1.05), Verdetto.costante);
    expect(verdetto(null, 1), Verdetto.datoDebole);
    expect(verdetto(0, 0), Verdetto.costante);
    expect(verdetto(0, 1), Verdetto.salito);
  });
}
