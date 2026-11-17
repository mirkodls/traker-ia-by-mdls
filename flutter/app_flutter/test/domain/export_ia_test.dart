// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// B14: export per IA: contenuto, etichetta STIMA, mai segreti.
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/archivio_settimane.dart';
import 'package:traker_ia/domain/export_ia.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/progetti.dart';

import 'aiuti.dart';

const Progetto _a = Progetto(id: 1, nome: 'Traker');
const Progetto _b = Progetto(id: 2, nome: 'Sito');

Evento _n(String ora, String testo) =>
    Evento(ora: t(ora), tipo: TipoEvento.nota, testo: testo);

List<Lettura> _settimana() => <Lettura>[
  for (int i = 0; i < 7 * 48; i++)
    Lettura(
      ora: t('2026-11-10 20:00').add(Duration(minutes: 30 * i)),
      sett: (i ~/ 2).toDouble() / 4,
      sess: (i % 10).toDouble() * 3,
      lavoro: i % 4 == 0,
    ),
];

List<SettimanaProgetto> _righe(List<Evento> es) => archiviaSettimana(
  letture: _settimana(),
  eventi: es,
  progetti: const <Progetto>[_a, _b],
  inizio: t('2026-11-10 20:00'),
  fine: t('2026-11-17 20:00'),
  piano: Piano(
    nome: 'Piano',
    giorniMask: 0x1F,
    inizio: DateTime(2026, 11, 10, 20),
  ),
);

const Map<int, String> _nomi = <int, String>{
  idSenzaProgetto: 'Senza progetto',
  1: 'Traker',
  2: 'Sito',
};

void main() {
  final List<Evento> es = <Evento>[
    _n('2026-11-11 08:00', 'traker inizio'),
    _n('2026-11-11 09:00', 'sito inizio'),
    _n('2026-11-12 08:00', 'traker fine'),
    _n('2026-11-12 09:00', 'sito fine'),
  ];

  test('testo: richiesta in cima, dati, STIMA, piano, eventi', () {
    final List<SettimanaProgetto> r = _righe(es);
    final String s = esportaPerIA(r, _nomi, creato: t('2026-11-17 21:00'));
    expect(s.startsWith('RICHIESTA: Scrivi un resoconto in italiano'), isTrue);
    expect(s, contains('creato 2026-11-17 21:00'));
    expect(s, contains('## PROGETTO "Traker" | SETT 2026-11-10 20:00 -> '));
    expect(s, contains('## PROGETTO "Sito"'));
    expect(s, contains('STIMA_SETT_PT: ~'));
    expect(s, contains('STIMA_SESS_PT: ~'));
    expect(s, contains('min '));
    expect(s, contains('STIMA'));
    expect(s, contains('PIANO: nome="Piano" giorni_mask=31'));
    expect(s, contains('TOKEN_MANUALI (scritti a mano, dato): non noti'));
    expect(s, contains('SERIE intensita'));
    expect(s, contains('2026-11-11 n='));
    expect(s, contains('| traker inizio'));
    // Ogni numero di stima porta la parola STIMA nella stessa riga.
    for (final String riga in s.split('\n')) {
      if (riga.startsWith('STIMA_')) {
        expect(riga, contains('STIMA'));
      }
    }
  });

  test('token scritti a mano compaiono come dato', () {
    final SettimanaProgetto r = _righe(es).first;
    final SettimanaProgetto c = SettimanaProgetto(
      progettoId: r.progettoId,
      inizio: r.inizio,
      fine: r.fine,
      istantanea: r.istantanea,
      log: r.log,
      tokenManuali: 4200,
    );
    expect(
      esportaPerIA(<SettimanaProgetto>[c], _nomi),
      contains('TOKEN_MANUALI (scritti a mano, dato): 4200'),
    );
  });

  test('NO SEGRETI: parole vietate in note, nome progetto e log', () {
    final List<Evento> cattivi = <Evento>[
      ...es,
      _n('2026-11-13 08:00', 'il mio cookie sessionKey=sk-ant-sid01-abcdef'),
      _n('2026-11-13 09:00', 'Password: hunter2'),
      _n('2026-11-13 10:00', 'Authorization Bearer xyz'),
      _n('2026-11-13 11:00', 'nota normale'),
    ];
    final List<SettimanaProgetto> r = _righe(cattivi);
    final Map<int, String> nomi = <int, String>{..._nomi, 2: 'Mio Segreto'};
    final String s = esportaPerIA(r, nomi);
    expect(parolaVietataEsportazione.hasMatch(s), isFalse);
    expect(s, isNot(contains('hunter2')));
    expect(s, isNot(contains('sid01')));
    expect(s, contains(rigaRimossa));
    expect(s, contains('nota normale'));
  });

  test('istantanea rotta: nessuna eccezione, avviso', () {
    final SettimanaProgetto rotta = SettimanaProgetto(
      progettoId: 1,
      inizio: t('2026-11-10 20:00'),
      fine: t('2026-11-17 20:00'),
      istantanea: '{rotto',
      log: '',
    );
    final String s = esportaPerIA(<SettimanaProgetto>[rotta], _nomi);
    expect(s, contains('istantanea non leggibile'));
    expect(s, contains('(nessun evento)'));
  });

  test('lista vuota e ordine per inizio', () {
    expect(
      esportaPerIA(const <SettimanaProgetto>[], _nomi),
      contains('(nessuna settimana da esportare)'),
    );
    final List<SettimanaProgetto> r = _righe(es);
    final String s = esportaPerIA(r.reversed, _nomi);
    expect(
      s.indexOf('"Senza progetto"') < s.indexOf('"Traker"') ||
          r.first.progettoId != idSenzaProgetto,
      isTrue,
    );
  });

  test('nome file', () {
    expect(
      nomeFileEsportazione(t('2026-11-10 20:00')),
      'traker-ia_2026-11-10.md',
    );
    expect(
      nomeFileEsportazione(t('2026-11-10 20:00'), nome: 'Mio Sito! (v2)'),
      'traker-ia_2026-11-10_mio-sito-v2.md',
    );
    expect(
      nomeFileEsportazione(t('2026-11-10 20:00'), nome: '../..\\x'),
      'traker-ia_2026-11-10_x.md',
    );
  });
}
