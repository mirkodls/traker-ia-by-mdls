// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/sync_dati.dart';
import 'package:traker_ia/domain/unione.dart';

void main() {
  final DateTime t0 = DateTime(2026, 11, 20, 10);

  test('pacco JSON andata e ritorno', () {
    final PaccoSync p = PaccoSync(
      da: t0,
      letture: <Lettura>[
        Lettura(
          ora: t0,
          sett: 21,
          sess: 14,
          fable: 3,
          lavoro: true,
          modelli: 'opus',
        ),
        Lettura(ora: t0.add(const Duration(minutes: 6)), sett: 22),
      ],
      eventi: <Evento>[Evento(ora: t0, tipo: TipoEvento.nota, testo: 'ciao')],
      progetti: const <Progetto>[Progetto(nome: 'App', colore: 5, note: 'n')],
      settimane: <SettimanaSync>[
        SettimanaSync(
          progetto: 'App',
          inizio: t0,
          fine: null,
          istantanea: '{}',
          log: 'l',
          token: 9,
        ),
      ],
      impostazioni: <String, ValoreSync>{
        Chiavi.v2SogliaRosso: (valore: '90', ora: 5),
      },
    );
    final PaccoSync q = PaccoSync.daJson(
      jsonDecode(jsonEncode(p.aJson())) as Map<String, Object?>,
    );
    expect(q.da, t0);
    expect(q.letture.length, 2);
    expect(q.letture.first.fable, 3);
    expect(q.letture.first.lavoro, isTrue);
    expect(q.letture.first.modelli, 'opus');
    expect(q.letture.last.sess, isNull);
    expect(q.eventi.single.testo, 'ciao');
    expect(q.progetti.single.colore, 5);
    expect(q.settimane.single.token, 9);
    expect(q.impostazioni[Chiavi.v2SogliaRosso], (valore: '90', ora: 5));
  });

  test(
    'ricevendo: righe rotte saltate, chiavi fuori elenco/segrete scartate',
    () {
      final PaccoSync q = PaccoSync.daJson(<String, Object?>{
        'letture': <Object?>[
          <String, Object?>{'o': 'rotta', 'w': 1},
          <String, Object?>{'o': '2026-11-20 10:00'},
          <String, Object?>{'o': '2026-11-20 10:00', 'w': -5, 's': 7},
          3,
        ],
        'eventi': <Object?>[
          <String, Object?>{'o': '2026-11-20 10:00', 't': 'boh'},
        ],
        'impostazioni': <String, Object?>{
          'anthropic_cookie': <String, Object?>{'v': 'x', 't': 9},
          'ia_api_anthropic': <String, Object?>{'v': 'x', 't': 9},
          Chiavi.minuti: <String, Object?>{'v': '1', 't': 9},
          Chiavi.v2RossoAcceso: <String, Object?>{'v': '0', 't': 9},
        },
      });
      expect(q.letture.single.sett, isNull);
      expect(q.letture.single.sess, 7);
      expect(q.eventi, isEmpty);
      expect(q.impostazioni.keys, <String>[Chiavi.v2RossoAcceso]);
    },
  );

  test('elenco sync: niente segreti né chiavi del dispositivo', () {
    for (final String k in chiaviSync) {
      expect(
        k.contains('cookie') || k.contains('ia_api') || k.contains('token'),
        isFalse,
      );
    }
    for (final String k in <String>[
      Chiavi.minuti,
      Chiavi.metodo,
      Chiavi.vista,
      Chiavi.sfondoAcceso,
      Chiavi.minutiSfondo,
      Chiavi.permessiChiesti,
      Chiavi.cartellaImport,
    ]) {
      expect(chiaviSync, isNot(contains(k)));
    }
  });

  test('impostazioni: vince la più recente, uguali saltate', () {
    final Map<String, ValoreSync> r = impostazioniDaApplicare(
      <String, String?>{
        Chiavi.v2SogliaRosso: '95',
        Chiavi.v2RossoAcceso: '1',
        Chiavi.v2Lavoro: '1',
      },
      <String, int>{Chiavi.v2SogliaRosso: 10, Chiavi.v2RossoAcceso: 50},
      <String, ValoreSync>{
        Chiavi.v2SogliaRosso: (valore: '90', ora: 20),
        Chiavi.v2RossoAcceso: (valore: '0', ora: 40),
        Chiavi.v2Lavoro: (valore: '1', ora: 99),
        Chiavi.minuti: (valore: '1', ora: 99),
      },
    );
    expect(r.keys, <String>[Chiavi.v2SogliaRosso]);
  });

  test('progetti nuovi per nome (maiuscole/spazi ignorati)', () {
    final List<Progetto> n = progettiNuovi(
      const <Progetto>[Progetto(nome: 'App')],
      const <Progetto>[
        Progetto(nome: ' app '),
        Progetto(nome: 'Sito'),
        Progetto(nome: 'SITO'),
      ],
    );
    expect(n.map((Progetto p) => p.nome), <String>['Sito']);
  });

  test('daQuando: primo sync/tutto = null, poi 7 giorni prima', () {
    expect(daQuando(null), isNull);
    expect(daQuando(t0, tutto: true), isNull);
    expect(daQuando(t0), t0.subtract(const Duration(days: 7)));
  });

  test('lettureNuove: doppioni ±1 min esclusi, solo le nuove', () {
    final List<Lettura> mie = <Lettura>[Lettura(ora: t0, sett: 21, sess: 14)];
    final List<Lettura> n = lettureNuove(mie, <Lettura>[
      Lettura(ora: t0.add(const Duration(seconds: 50)), sett: 21, sess: 14),
      Lettura(ora: t0.add(const Duration(minutes: 30)), sett: 22, sess: 15),
      Lettura(ora: t0.add(const Duration(minutes: 30)), sett: 22, sess: 15),
    ]);
    expect(n.length, 1);
    expect(n.single.sett, 22);
    expect(
      eventiNuovi(
        <Evento>[Evento(ora: t0, tipo: TipoEvento.nota, testo: 'a')],
        <Evento>[Evento(ora: t0, tipo: TipoEvento.nota, testo: 'a')],
      ),
      isEmpty,
    );
  });
}
