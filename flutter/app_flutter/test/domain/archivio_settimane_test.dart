// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// B12: settimane da archiviare, righe per progetto, istantanea completa.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/archivio_settimane.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/progetti.dart';

import 'aiuti.dart';

const Progetto _a = Progetto(id: 1, nome: 'Traker', colore: 0xFF00AA00);
const Progetto _b = Progetto(id: 2, nome: 'Sito');

Evento _n(String ora, String testo) =>
    Evento(ora: t(ora), tipo: TipoEvento.nota, testo: testo);

/// Settimana 10/11 20:00 -> 17/11 20:00, lettura ogni 30 min, sett +1/h.
List<Lettura> _settimana() => <Lettura>[
  for (int i = 0; i < 7 * 48; i++)
    Lettura(
      ora: t('2026-11-10 20:00').add(Duration(minutes: 30 * i)),
      sett: (i ~/ 2).toDouble() / 4,
      sess: (i % 10).toDouble() * 3,
      fonte: i.isEven ? 'auto' : 'manuale',
      alPc: i % 3 == 0 ? null : i.isEven,
      lavoro: i % 4 == 0,
      modelli: i % 7 == 0 ? 'Opus|Fable' : '',
    ),
];

double _stima(String json, String campo) {
  final Map<String, Object?> m =
      leggiIstantanea(json).riassunto[campo]! as Map<String, Object?>;
  return (m['stima']! as num).toDouble();
}

void main() {
  test('settimane chiuse: con dati, non già fatte, non quella in corso', () {
    final List<Lettura> ls = <Lettura>[
      l('2026-11-11 10:00', 1, 1),
      l('2026-11-18 10:00', 1, 1),
      l('2026-11-26 10:00', 1, 1),
    ];
    expect(
      settimaneDaArchiviare(ls, t('2026-11-25 10:00')),
      <({DateTime inizio, DateTime fine})>[
        (inizio: t('2026-11-10 20:00'), fine: t('2026-11-17 20:00')),
        (inizio: t('2026-11-17 20:00'), fine: t('2026-11-24 20:00')),
      ],
    );
    expect(
      settimaneDaArchiviare(
        ls,
        t('2026-11-25 10:00'),
        gia: <DateTime>{t('2026-11-10 20:00')},
      ).single.inizio,
      t('2026-11-17 20:00'),
    );
    // Reset preciso: alle 20:00 la settimana è chiusa.
    expect(settimaneDaArchiviare(ls, t('2026-11-17 19:59')), isEmpty);
    expect(settimaneDaArchiviare(ls, t('2026-11-17 20:00')).length, 1);
    // Settimana senza letture saltata.
    expect(
      settimaneDaArchiviare(
        <Lettura>[l('2026-11-11 10:00', 1, 1), l('2026-11-26 10:00', 1, 1)],
        t('2026-12-02 10:00'),
      ).map((({DateTime inizio, DateTime fine}) s) => s.inizio),
      <DateTime>[t('2026-11-10 20:00'), t('2026-11-24 20:00')],
    );
    expect(
      settimaneDaArchiviare(const <Lettura>[], t('2026-12-02 10:00')),
      isEmpty,
    );
  });

  test('nessun progetto attivo -> una riga Senza progetto', () {
    final List<SettimanaProgetto> r = archiviaSettimana(
      letture: _settimana(),
      eventi: <Evento>[_n('2026-11-12 10:00', 'nota qualsiasi')],
      progetti: const <Progetto>[_a, _b],
      inizio: t('2026-11-10 20:00'),
      fine: t('2026-11-17 20:00'),
    );
    expect(r.single.progettoId, idSenzaProgetto);
    final IstantaneaLetta s = leggiIstantanea(r.single.istantanea);
    expect(s.versione, versioneIstantanea);
    expect(s.grezza['progetto'], containsPair('nome', 'Senza progetto'));
    expect(s.riassunto['stima'], true);
    expect(
      _stima(r.single.istantanea, 'sett'),
      closeTo((s.riassunto['totale_sett']! as num).toDouble(), 1e-9),
    );
    expect(r.single.log, contains('| NOTA |  | nota qualsiasi'));
  });

  test('progetti: righe per progetto, somma = totale, copia integrale', () {
    final List<Lettura> ls = _settimana();
    final List<Evento> es = <Evento>[
      // Aperto PRIMA del reset: resta attivo dentro la settimana.
      _n('2026-11-09 10:00', 'traker inizio'),
      _n('2026-11-12 08:00', 'sito inizio'),
      _n('2026-11-12 08:00', 'sito 25%'),
      _n('2026-11-13 08:00', 'traker fine'),
      _n('2026-11-14 08:00', 'sito fine'),
      _n('2026-11-18 08:00', 'dopo la settimana'),
    ];
    final Piano piano = Piano(
      nome: 'Piano',
      giorniMask: 0x1F,
      inizio: DateTime(2026, 11, 10, 20),
    );
    final List<SettimanaProgetto> r = archiviaSettimana(
      letture: ls,
      eventi: es,
      progetti: const <Progetto>[_a, _b],
      inizio: t('2026-11-10 20:00'),
      fine: t('2026-11-17 20:00'),
      piano: piano,
    );
    expect(r.map((SettimanaProgetto x) => x.progettoId).toList(), <int>[
      idSenzaProgetto,
      1,
      2,
    ]);
    final double tot =
        (leggiIstantanea(r.first.istantanea).riassunto['totale_sett']! as num)
            .toDouble();
    expect(tot, greaterThan(0));
    double somma = 0;
    double sommaSess = 0;
    for (final SettimanaProgetto x in r) {
      somma += _stima(x.istantanea, 'sett');
      sommaSess += _stima(x.istantanea, 'sess');
    }
    expect(somma, closeTo(tot, 1e-9));
    expect(
      sommaSess,
      closeTo(
        (leggiIstantanea(r.first.istantanea).riassunto['totale_sess']! as num)
            .toDouble(),
        1e-9,
      ),
    );
    // Traker: dall'inizio settimana al 13/11 08:00 (60 h).
    final IstantaneaLetta sa = leggiIstantanea(r[1].istantanea);
    expect((sa.riassunto['ore_attive']! as num).toDouble(), closeTo(60, 1e-9));
    expect(sa.intervalli.single.inizio, t('2026-11-10 20:00'));
    expect(sa.grezza['progetto'], containsPair('colore', 0xFF00AA00));
    expect((sa.grezza['piano']! as Map<String, Object?>)['giorni_mask'], 0x1F);
    final Map<String, Object?> serie =
        sa.grezza['serie']! as Map<String, Object?>;
    expect((serie['intensita']! as List<Object?>).length, 7 * 24 * 4 + 1);
    expect(serie['ideale'], isNotEmpty);
    // Copia integrale: stesse letture campo per campo.
    expect(sa.letture.length, ls.length);
    for (int i = 0; i < ls.length; i++) {
      final Lettura x = ls[i];
      final Lettura y = sa.letture[i];
      expect(
        <Object?>[
          y.ora,
          y.sett,
          y.sess,
          y.fonte,
          y.alPc,
          y.lavoro,
          y.modelli,
          y.skill,
          y.gestore,
        ],
        <Object?>[
          x.ora,
          x.sett,
          x.sess,
          x.fonte,
          x.alPc,
          x.lavoro,
          x.modelli,
          x.skill,
          x.gestore,
        ],
      );
    }
    // Eventi: solo della settimana.
    expect(sa.eventi.length, 4);
    // Log con cambi progetto.
    expect(r[1].log, contains('PROGETTO_QUOTA | Sito | sito 25%'));
    expect(r[1].log, isNot(contains('dopo la settimana')));
    // Istantanea = testo: cambiare i dati grezzi dopo non la tocca.
    final String prima = r[1].istantanea;
    ls.clear();
    expect(r[1].istantanea, prima);
    expect(jsonDecode(prima), isA<Map<String, Object?>>());
  });

  test('istantanea rotta -> versione 0, liste vuote, nessuna eccezione', () {
    for (final String s in <String>['', '{', '[]', '{"v":1,"letture":5}']) {
      final IstantaneaLetta x = leggiIstantanea(s);
      expect(x.letture, isEmpty, reason: s);
      expect(x.eventi, isEmpty, reason: s);
    }
    expect(leggiIstantanea('{').versione, 0);
  });
}
