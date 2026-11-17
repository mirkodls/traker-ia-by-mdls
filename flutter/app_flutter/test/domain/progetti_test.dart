// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// B12: note-comando progetto, intervalli, quote, ripartizione simultanei
// (somma parti = totale), costo energia, log.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/intensita.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/progetti.dart';

import 'aiuti.dart';

const Progetto _a = Progetto(id: 1, nome: 'Traker');
const Progetto _b = Progetto(id: 2, nome: 'Sito Web');
const Progetto _c = Progetto(id: 3, nome: 'v2');
const List<Progetto> _ps = <Progetto>[_a, _b, _c];

Evento _n(String ora, String testo) =>
    Evento(ora: t(ora), tipo: TipoEvento.nota, testo: testo);

/// Letture ogni ora: sett +2/h, sess +10/h da [da] per [ore] ore.
List<Lettura> _orarie(String da, int ore) => <Lettura>[
  for (int i = 0; i <= ore; i++)
    Lettura(
      ora: t(da).add(Duration(hours: i)),
      sett: 10.0 + 2 * i,
      sess: 10.0 + 10 * i,
    ),
];

void main() {
  group('note-comando', () {
    test('inizio / fine / quota, maiuscole e spazi ignorati', () {
      expect(
        comandoProgettoDaNota('Traker inizio', _ps),
        const ComandoProgetto(1, TipoComandoProgetto.inizio),
      );
      expect(
        comandoProgettoDaNota('  inizio   SITO  web. ', _ps),
        const ComandoProgetto(2, TipoComandoProgetto.inizio),
      );
      expect(
        comandoProgettoDaNota('sito web fine', _ps),
        const ComandoProgetto(2, TipoComandoProgetto.fine),
      );
      expect(
        comandoProgettoDaNota('fine traker!', _ps),
        const ComandoProgetto(1, TipoComandoProgetto.fine),
      );
      expect(
        comandoProgettoDaNota('traker 70%', _ps),
        const ComandoProgetto(1, TipoComandoProgetto.quota, quota: 70),
      );
      expect(
        comandoProgettoDaNota('v2 12,5 %', _ps),
        const ComandoProgetto(3, TipoComandoProgetto.quota, quota: 12.5),
      );
    });

    test('note normali e casi limite -> null', () {
      for (final String s in <String>[
        '',
        'traker',
        'traker va bene',
        'altro inizio',
        'traker 120%',
        'traker70%',
        'lavoro',
        'fine lavoro',
        'inizio',
      ]) {
        expect(comandoProgettoDaNota(s, _ps), isNull, reason: s);
      }
      // Progetto chiamato "lavoro": la nota-comando Lavoro vince.
      const Progetto lav = Progetto(id: 9, nome: 'lavoro');
      expect(comandoProgettoDaNota('fine lavoro', <Progetto>[lav]), isNull);
      expect(
        comandoProgettoDaNota('lavoro inizio', <Progetto>[lav]),
        const ComandoProgetto(9, TipoComandoProgetto.inizio),
      );
      // Progetto senza id ignorato.
      expect(
        comandoProgettoDaNota('nuovo inizio', <Progetto>[
          const Progetto(nome: 'nuovo'),
        ]),
        isNull,
      );
    });

    test('il tasto scrive una nota che si rilegge uguale', () {
      for (final Progetto p in _ps) {
        for (final TipoComandoProgetto tipo in TipoComandoProgetto.values) {
          final String nota = notaComandoProgetto(p, tipo, quota: 40);
          final ComandoProgetto? c = comandoProgettoDaNota(nota, _ps);
          expect(c?.progettoId, p.id, reason: nota);
          expect(c?.tipo, tipo, reason: nota);
        }
      }
      expect(
        notaComandoProgetto(_a, TipoComandoProgetto.quota, quota: 12.5),
        'Traker 12.5%',
      );
    });
  });

  group('intervalli', () {
    test('doppio inizio ignorato, fine senza inizio ignorata, aperto', () {
      final List<IntervalloProgetto> iv = intervalliProgetti(
        <Evento>[
          _n('2026-11-12 09:00', 'traker fine'),
          _n('2026-11-12 10:00', 'traker inizio'),
          _n('2026-11-12 10:30', 'traker inizio'),
          _n('2026-11-12 12:00', 'traker fine'),
          _n('2026-11-12 11:00', 'sito web inizio'),
          Evento(
            ora: DateTime(2026, 11, 12, 11, 30),
            tipo: TipoEvento.inizio,
            testo: 'traker inizio',
          ),
        ],
        _ps,
        t('2026-11-12 15:00'),
      );
      expect(iv, <IntervalloProgetto>[
        IntervalloProgetto(1, t('2026-11-12 10:00'), t('2026-11-12 12:00')),
        IntervalloProgetto(
          2,
          t('2026-11-12 11:00'),
          t('2026-11-12 15:00'),
          aperto: true,
        ),
      ]);
      expect(attiviA(iv, t('2026-11-12 11:00')), <int>{1, 2});
      expect(attiviA(iv, t('2026-11-12 12:00')), <int>{2});
    });
  });

  group('quote', () {
    test('casi base', () {
      expect(quoteSegmento(<int>{}, <int, double>{}), <int, double>{0: 1});
      expect(quoteSegmento(<int>{2}, <int, double>{2: 30}), <int, double>{
        2: 1,
      });
      expect(quoteSegmento(<int>{1, 2}, <int, double>{}), <int, double>{
        1: 0.5,
        2: 0.5,
      });
      final Map<int, double> q70 = quoteSegmento(
        <int>{1, 2},
        <int, double>{1: 70},
      );
      expect(q70[1], 0.7);
      expect(q70[2], closeTo(0.3, 1e-12));
      expect(quoteSegmento(<int>{1, 2, 3}, <int, double>{1: 50}), <int, double>{
        1: 0.5,
        2: 0.25,
        3: 0.25,
      });
      expect(
        quoteSegmento(<int>{1, 2}, <int, double>{1: 30, 2: 30}),
        <int, double>{1: 0.5, 2: 0.5},
      );
      expect(
        quoteSegmento(<int>{1, 2, 3}, <int, double>{1: 80, 2: 80}),
        <int, double>{1: 0.5, 2: 0.5, 3: 0},
      );
      expect(
        quoteSegmento(<int>{1, 2}, <int, double>{1: 0, 2: 0}),
        <int, double>{1: 0.5, 2: 0.5},
      );
    });

    test('somma sempre 1 (fuzz)', () {
      final math.Random r = math.Random(12);
      for (int k = 0; k < 2000; k++) {
        final Set<int> attivi = <int>{
          for (int i = 1; i <= 5; i++)
            if (r.nextBool()) i,
        };
        final Map<int, double> note = <int, double>{
          for (int i = 1; i <= 5; i++)
            if (r.nextInt(3) == 0) i: r.nextInt(101).toDouble(),
        };
        final Map<int, double> q = quoteSegmento(attivi, note);
        double s = 0;
        for (final double v in q.values) {
          expect(v, greaterThanOrEqualTo(0));
          s += v;
        }
        expect(s, closeTo(1, 1e-9));
      }
    });
  });

  group('ripartizione', () {
    final List<Evento> base = <Evento>[
      _n('2026-11-12 10:00', 'traker inizio'),
      _n('2026-11-12 11:00', 'sito web inizio'),
      _n('2026-11-12 12:00', 'traker fine'),
      _n('2026-11-12 13:00', 'sito web fine'),
    ];

    test('1 attivo = 100%; 2 insieme = 50/50 con min/max', () {
      final Ripartizione r = ripartisci(
        _orarie('2026-11-12 10:00', 3),
        base,
        _ps,
        da: t('2026-11-12 10:00'),
        a: t('2026-11-12 13:00'),
      );
      expect(r.totaleSett, closeTo(6, 1e-9));
      expect(r.totaleSess, closeTo(30, 1e-9));
      final ConsumoProgetto a = r.voce(1)!;
      final ConsumoProgetto b = r.voce(2)!;
      expect(a.sett.stima, closeTo(3, 1e-9));
      expect(a.sett.min, closeTo(2, 1e-9));
      expect(a.sett.max, closeTo(4, 1e-9));
      expect(b.sett.stima, closeTo(3, 1e-9));
      expect(a.sess.stima, closeTo(15, 1e-9));
      expect(a.oreAttive, closeTo(2, 1e-9));
      expect(a.oreCondivise, closeTo(1, 1e-9));
      expect(a.sett.esatta, isFalse);
      expect(r.voce(idSenzaProgetto), isNull);
      expect(r.voce(3), isNull);
    });

    test('quota da nota: traker 70% -> 70/30 nel tratto condiviso', () {
      final Ripartizione r = ripartisci(
        _orarie('2026-11-12 10:00', 3),
        <Evento>[...base, _n('2026-11-12 11:00', 'traker 70%')],
        _ps,
        da: t('2026-11-12 10:00'),
        a: t('2026-11-12 13:00'),
      );
      expect(r.voce(1)!.sett.stima, closeTo(3.4, 1e-9));
      expect(r.voce(2)!.sett.stima, closeTo(2.6, 1e-9));
      // min/max non dipendono dalla quota.
      expect(r.voce(1)!.sett.min, closeTo(2, 1e-9));
      expect(r.voce(1)!.sett.max, closeTo(4, 1e-9));
    });

    test('la quota sparisce alla fine del progetto', () {
      final Ripartizione r = ripartisci(
        _orarie('2026-11-12 10:00', 4),
        <Evento>[
          _n('2026-11-12 10:00', 'traker inizio'),
          _n('2026-11-12 10:00', 'sito web inizio'),
          _n('2026-11-12 10:00', 'traker 90%'),
          _n('2026-11-12 11:00', 'traker fine'),
          _n('2026-11-12 12:00', 'traker inizio'),
        ],
        _ps,
        da: t('2026-11-12 10:00'),
        a: t('2026-11-12 13:00'),
      );
      // 10-11: 90/10 · 11-12: solo sito · 12-13: 50/50 (quota tolta).
      expect(r.voce(1)!.sett.stima, closeTo(1.8 + 1, 1e-9));
      expect(r.voce(2)!.sett.stima, closeTo(0.2 + 2 + 1, 1e-9));
    });

    test('fuori dai progetti = Senza progetto; coppia tagliata a metà', () {
      final Ripartizione r = ripartisci(
        <Lettura>[
          l('2026-11-12 10:00', 10, null),
          l('2026-11-12 12:00', 14, null),
        ],
        <Evento>[_n('2026-11-12 11:00', 'traker inizio')],
        _ps,
        da: t('2026-11-12 10:00'),
        a: t('2026-11-12 12:00'),
      );
      expect(r.voce(idSenzaProgetto)!.sett.stima, closeTo(2, 1e-9));
      expect(r.voce(idSenzaProgetto)!.sett.esatta, isTrue);
      expect(r.voce(1)!.sett.stima, closeTo(2, 1e-9));
      expect(r.voce(1)!.sett.esatta, isTrue);
      expect(r.totaleSess, 0);
    });

    test('reset escluso; finestra da-a taglia le coppie', () {
      final Ripartizione r = ripartisci(
        <Lettura>[
          l('2026-11-12 10:00', 50, 90),
          l('2026-11-12 11:00', 2, 1),
          l('2026-11-12 13:00', 6, 11),
        ],
        const <Evento>[],
        _ps,
        da: t('2026-11-12 12:00'),
        a: t('2026-11-12 14:00'),
      );
      expect(r.totaleSett, closeTo(2, 1e-9));
      expect(r.totaleSess, closeTo(5, 1e-9));
      expect(r.voce(idSenzaProgetto)!.sett.stima, closeTo(2, 1e-9));
    });

    test('vuoto / intervallo rovescio: tutto zero, nessuna voce', () {
      final Ripartizione r = ripartisci(
        const <Lettura>[],
        base,
        _ps,
        da: t('2026-11-12 13:00'),
        a: t('2026-11-12 10:00'),
      );
      expect(r.totaleSett, 0);
      expect(r.voci, isEmpty);
    });

    test('FUZZ: somma parti = totale, min <= stima <= max', () {
      final math.Random r = math.Random(7);
      final DateTime t0 = t('2026-11-10 20:00');
      for (int k = 0; k < 150; k++) {
        double sett = r.nextInt(30).toDouble();
        double sess = r.nextInt(30).toDouble();
        DateTime ora = t0;
        final List<Lettura> ls = <Lettura>[];
        for (int i = 0; i < 300; i++) {
          ora = ora.add(Duration(minutes: 1 + r.nextInt(30)));
          if (r.nextInt(60) == 0) {
            sess = 0;
          }
          sett += r.nextInt(3) == 0 ? 1 : 0;
          sess += r.nextInt(2).toDouble();
          ls.add(
            Lettura(
              ora: ora,
              sett: r.nextInt(20) == 0 ? null : sett,
              sess: math.min(sess, 100),
            ),
          );
        }
        final List<Evento> es = <Evento>[];
        for (int i = 0; i < 40; i++) {
          final Progetto p = _ps[r.nextInt(_ps.length)];
          final int tipo = r.nextInt(5);
          es.add(
            Evento(
              ora: t0.add(Duration(minutes: r.nextInt(5000))),
              tipo: TipoEvento.nota,
              testo: tipo < 2
                  ? '${p.nome} inizio'
                  : tipo < 4
                  ? '${p.nome} fine'
                  : '${p.nome} ${r.nextInt(101)}%',
            ),
          );
        }
        final DateTime da = t0.add(Duration(minutes: r.nextInt(600)));
        final DateTime a = da.add(Duration(minutes: 500 + r.nextInt(4000)));
        final Ripartizione rp = ripartisci(ls, es, _ps, da: da, a: a);
        double ss = 0;
        double ssess = 0;
        double sMin = 0;
        for (final ConsumoProgetto c in rp.voci) {
          ss += c.sett.stima;
          ssess += c.sess.stima;
          sMin += c.sett.min;
          for (final StimaIntervallo x in <StimaIntervallo>[c.sett, c.sess]) {
            expect(x.min, lessThanOrEqualTo(x.stima + 1e-9));
            expect(x.stima, lessThanOrEqualTo(x.max + 1e-9));
            expect(x.min, greaterThanOrEqualTo(-1e-9));
          }
          expect(c.sett.max, lessThanOrEqualTo(rp.totaleSett + 1e-9));
          expect(c.oreCondivise, lessThanOrEqualTo(c.oreAttive + 1e-9));
        }
        expect(ss, closeTo(rp.totaleSett, 1e-9), reason: 'giro $k');
        expect(ssess, closeTo(rp.totaleSess, 1e-9), reason: 'giro $k');
        expect(sMin, lessThanOrEqualTo(rp.totaleSett + 1e-9));
      }
    });
  });

  test('leggero: 20.000 letture + 400 note in meno di 1 s', () {
    final DateTime t0 = t('2026-11-01 00:00');
    final List<Lettura> ls = <Lettura>[
      for (int i = 0; i < 20000; i++)
        Lettura(
          ora: t0.add(Duration(minutes: 6 * i)),
          sett: (i ~/ 50 % 100).toDouble(),
          sess: (i % 50).toDouble(),
        ),
    ];
    final List<Evento> es = <Evento>[
      for (int i = 0; i < 400; i++)
        Evento(
          ora: t0.add(Duration(hours: 4 * i)),
          tipo: TipoEvento.nota,
          testo: '${_ps[i % 3].nome} ${i.isEven ? 'inizio' : 'fine'}',
        ),
    ];
    final Stopwatch w = Stopwatch()..start();
    final Ripartizione r = ripartisci(
      ls,
      es,
      _ps,
      da: t0,
      a: t0.add(const Duration(days: 80)),
    );
    w.stop();
    double s = 0;
    for (final ConsumoProgetto c in r.voci) {
      s += c.sett.stima;
    }
    expect(s, closeTo(r.totaleSett, 1e-6));
    expect(w.elapsedMilliseconds, lessThan(1000));
  });

  group('costo energia', () {
    test('media sulle ore attive, picco 5h nel progetto, token a mano', () {
      final List<Lettura> ls = _orarie('2026-11-12 10:00', 3);
      final List<Evento> es = <Evento>[
        _n('2026-11-12 11:00', 'traker inizio'),
        _n('2026-11-12 13:00', 'traker fine'),
      ];
      final Ripartizione r = ripartisci(
        ls,
        es,
        _ps,
        da: t('2026-11-12 10:00'),
        a: t('2026-11-12 13:00'),
      );
      final List<IntervalloProgetto> iv = intervalliProgetti(
        es,
        _ps,
        t('2026-11-12 13:00'),
      );
      final CostoEnergia c = costoEnergia(
        r,
        1,
        intervalli: iv,
        intensita: <PuntoIntensita>[
          PuntoIntensita(
            ora: t('2026-11-12 10:30'),
            fonte: FonteIntensita.cinqueOre,
            valore: 99,
          ),
          PuntoIntensita(
            ora: t('2026-11-12 11:30'),
            fonte: FonteIntensita.cinqueOre,
            valore: 12,
          ),
          PuntoIntensita(
            ora: t('2026-11-12 12:00'),
            fonte: FonteIntensita.setteGiorni,
            valore: 50,
          ),
          PuntoIntensita(
            ora: t('2026-11-12 12:30'),
            fonte: FonteIntensita.cinqueOre,
          ),
        ],
        tokenManuali: 123456,
      );
      expect(c.sett.stima, closeTo(4, 1e-9));
      expect(c.oreAttive, closeTo(2, 1e-9));
      expect(c.mediaSettOra, closeTo(2, 1e-9));
      expect(c.mediaSessOra, closeTo(10, 1e-9));
      expect(c.piccoSessOra, 12);
      expect(c.tokenManuali, 123456);
      final CostoEnergia vuoto = costoEnergia(r, 3);
      expect(vuoto.oreAttive, 0);
      expect(vuoto.mediaSettOra, isNull);
      expect(vuoto.tokenManuali, isNull);
      expect(vuoto.aMappa()['token_manuali'], isNull);
    });
  });

  group('log', () {
    test('tipi giusti, ordine per ora, testo strutturato su una riga', () {
      final List<VoceLog> v = logSettimana(
        <Lettura>[l('2026-11-12 10:00', 10, 80), l('2026-11-12 11:00', 11, 2)],
        <Evento>[
          _n('2026-11-12 12:00', 'pausa\ncaffè | ok'),
          _n('2026-11-12 10:30', 'Traker inizio'),
          _n('2026-11-12 10:40', 'lavoro'),
          _n('2026-11-12 10:50', 'traker 60%'),
          Evento(ora: DateTime(2026, 11, 12, 9), tipo: TipoEvento.inizio),
          Evento(ora: DateTime(2026, 11, 12, 13), tipo: TipoEvento.reset),
          _n('2026-11-11 10:00', 'fuori settimana'),
        ],
        _ps,
        da: t('2026-11-12 00:00'),
        a: t('2026-11-13 00:00'),
      );
      expect(v.map((VoceLog x) => x.tipo).toList(), <TipoVoceLog>[
        TipoVoceLog.inizioLavoro,
        TipoVoceLog.progettoInizio,
        TipoVoceLog.inizioLavoro,
        TipoVoceLog.progettoQuota,
        TipoVoceLog.resetSess,
        TipoVoceLog.nota,
        TipoVoceLog.reset,
      ]);
      expect(v[1].progettoId, 1);
      final String s = testoLog(v, <int, String>{1: 'Traker'});
      final List<String> righe = s.trim().split('\n');
      expect(righe.length, 7);
      expect(
        righe[1],
        '2026-11-12 10:30 | PROGETTO_INIZIO | Traker | Traker inizio',
      );
      expect(righe[4], '2026-11-12 11:00 | RESET_SESS |  | ');
      expect(righe[5], '2026-11-12 12:00 | NOTA |  | pausa caffè ok');
    });

    test('nome progetto: Senza progetto e id sconosciuto', () {
      expect(nomeProgetto(idSenzaProgetto, _ps), 'Senza progetto');
      expect(nomeProgetto(2, _ps), 'Sito Web');
      expect(nomeProgetto(77, _ps), '#77');
    });
  });
}
