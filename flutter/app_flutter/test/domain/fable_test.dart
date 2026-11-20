// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// B19: % Fable letta dalla risposta /usage, salvata nella lettura
// automatica e nelle istantanee (vecchie istantanee ancora leggibili).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/analisi.dart';
import 'package:traker_ia/domain/archivio_settimane.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/sfondo.dart';

Map<String, Object?> _base() => <String, Object?>{
  'five_hour': <String, Object?>{
    'utilization': 14,
    'resets_at': '2026-11-20T10:00:00Z',
  },
  'seven_day': <String, Object?>{
    'utilization': 64,
    'resets_at': '2026-11-24T19:00:00Z',
  },
};

void main() {
  test('chiave con fable (seven_day_fable) -> % Fable', () {
    final Uso u = leggiRisposta(<String, Object?>{
      ..._base(),
      'seven_day_fable': <String, Object?>{
        'utilization': 80,
        'resets_at': '2026-11-24T19:00:00Z',
      },
    });
    expect(u.sett, 64);
    expect(u.sess, 14);
    expect(u.fable, 80);
  });

  test('riga Fable assente -> nessun errore, Fable null', () {
    final Uso u = leggiRisposta(_base());
    expect(u.sett, 64);
    expect(u.sess, 14);
    expect(u.fable, isNull);
    expect(leggiRisposta(null).fable, isNull);
    expect(leggiRisposta('rotto').fable, isNull);
    expect(
      leggiRisposta(<String, Object?>{..._base(), 'seven_day_fable': null})
          .fable,
      isNull,
    );
    expect(
      leggiRisposta(<String, Object?>{
        ..._base(),
        'seven_day_fable': <String, Object?>{'utilization': null},
      }).fable,
      isNull,
    );
  });

  test('ripristino/reimpostazione Fable ignorati', () {
    final Uso u = leggiRisposta(<String, Object?>{
      ..._base(),
      'fable_reset': <String, Object?>{'utilization': 5},
      'limits': <Object?>[
        <String, Object?>{'name': 'Reimpostazione Fable', 'utilization': 7},
      ],
    });
    expect(u.fable, isNull);
  });

  test('voce con nome Fable dentro un elenco', () {
    final Uso u = leggiRisposta(<String, Object?>{
      ..._base(),
      'limits': <Object?>[
        <String, Object?>{'name': 'Opus', 'utilization': 30},
        <String, Object?>{'name': 'Fable', 'utilization': 80.5},
      ],
    });
    expect(u.fable, 80.5);
  });

  test('frazioni 0-1: anche Fable scalata a percento', () {
    final Uso u = leggiRisposta(<String, Object?>{
      'five_hour': <String, Object?>{'utilization': 0.14},
      'seven_day': <String, Object?>{'utilization': 0.64},
      'seven_day_fable': <String, Object?>{'utilization': 0.8},
    });
    expect(u.sess, closeTo(14, 1e-9));
    expect(u.sett, closeTo(64, 1e-9));
    expect(u.fable, closeTo(80, 1e-9));
  });

  test('lettura automatica porta la % Fable', () {
    final Lettura l = letturaAutomatica(
      const Uso(sess: 14, sett: 64, fable: 80),
      DateTime(2026, 11, 20, 9, 30),
      Preferenze.daMappa(const <String, String?>{}),
      const <Evento>[],
    );
    expect(l.fable, 80);
    expect(l.sett, 64);
    expect(l.sess, 14);
  });

  test('istantanea: vecchia (9 voci) leggibile, nuova con Fable', () {
    final String json = jsonEncode(<String, Object?>{
      'v': 1,
      'letture': <Object?>[
        <Object?>[
          '2026-11-18 10:00',
          50,
          10,
          'auto',
          null,
          false,
          '',
          '',
          'anthropic',
        ],
        <Object?>[
          '2026-11-18 11:00',
          52,
          12,
          'auto',
          true,
          false,
          '',
          '',
          'anthropic',
          77,
        ],
      ],
    });
    final List<Lettura> ls = leggiIstantanea(json).letture;
    expect(ls.length, 2);
    expect(ls[0].sett, 50);
    expect(ls[0].fable, isNull);
    expect(ls[1].sett, 52);
    expect(ls[1].fable, 77);
  });

  test('istantanea: la % Fable si salva e si rilegge', () {
    final List<SettimanaProgetto> r = archiviaSettimana(
      letture: <Lettura>[
        Lettura(ora: DateTime(2026, 11, 11, 10), sett: 10, sess: 5, fable: 40),
        Lettura(ora: DateTime(2026, 11, 11, 11), sett: 12, sess: 7),
      ],
      eventi: const <Evento>[],
      progetti: const <Progetto>[],
      inizio: DateTime(2026, 11, 10, 20),
      fine: DateTime(2026, 11, 17, 20),
    );
    final List<Lettura> ls = leggiIstantanea(r.single.istantanea).letture;
    expect(ls.map((Lettura l) => l.fable), <double?>[40, null]);
  });
}
