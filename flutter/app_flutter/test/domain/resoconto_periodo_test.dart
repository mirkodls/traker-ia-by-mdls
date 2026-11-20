// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// B20: resoconto IA per periodo (giorno, settimana, progetto): solo dati
// dentro [da, a), progetto aperto fino ad adesso, fine a mano, progetto su
// 2 settimane, nomi file, nessun segreto.
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/archivio_settimane.dart';
import 'package:traker_ia/domain/export_ia.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/progetti.dart';
import 'package:traker_ia/domain/resoconto_periodo.dart';

import 'aiuti.dart';

const Progetto _a = Progetto(id: 1, nome: 'App Luca');
const Progetto _b = Progetto(id: 2, nome: 'Sito');
const List<Progetto> _ps = <Progetto>[_a, _b];

Evento _n(String ora, String testo) =>
    Evento(ora: t(ora), tipo: TipoEvento.nota, testo: testo);

/// Letture ogni 30 min dal 03/11 20:00 al 20/11 12:00 (2+ settimane).
List<Lettura> _letture() {
  final List<Lettura> out = <Lettura>[];
  DateTime x = t('2026-11-03 20:00');
  int i = 0;
  while (x.isBefore(t('2026-11-20 12:00'))) {
    out.add(
      Lettura(
        ora: x,
        sett: ((i ~/ 4) % 100).toDouble(),
        sess: (i % 10).toDouble() * 3,
        fable: i.isEven ? 5 : null,
      ),
    );
    x = x.add(const Duration(minutes: 30));
    i++;
  }
  return out;
}

final DateTime _adesso = t('2026-11-20 12:00');

/// Tutte le letture dentro le righe stanno in [da, a).
void _soloDentro(List<SettimanaProgetto> righe, DateTime da, DateTime a) {
  expect(righe, isNotEmpty);
  for (final SettimanaProgetto r in righe) {
    final IstantaneaLetta d = leggiIstantanea(r.istantanea);
    expect(d.letture, isNotEmpty);
    for (final Lettura l in d.letture) {
      expect(!l.ora.isBefore(da) && l.ora.isBefore(a), isTrue, reason: '$l');
    }
    for (final Evento e in d.eventi) {
      expect(!e.ora.isBefore(da) && e.ora.isBefore(a), isTrue);
    }
  }
}

void main() {
  final List<Lettura> ls = _letture();

  group('periodi', () {
    test('giorno passato: mezzanotte -> mezzanotte; oggi: fino ad adesso', () {
      final PeriodoIA g = periodoGiorno(t('2026-11-18 15:00'), _adesso);
      expect(g.da, t('2026-11-18 00:00'));
      expect(g.a, t('2026-11-19 00:00'));
      expect(g.aperto, isFalse);
      final PeriodoIA o = periodoGiorno(_adesso, _adesso);
      expect(o.a, _adesso);
      expect(o.aperto, isTrue);
    });

    test('settimana: reset martedì 20:00; in corso fino ad adesso', () {
      final PeriodoIA s = periodoSettimana(t('2026-11-12 10:00'), _adesso);
      expect(s.da, t('2026-11-10 20:00'));
      expect(s.a, t('2026-11-17 20:00'));
      final PeriodoIA c = periodoSettimana(_adesso, _adesso);
      expect(c.da, t('2026-11-17 20:00'));
      expect(c.a, _adesso);
      expect(c.aperto, isTrue);
    });

    test('progetto chiuso / aperto (fino ad adesso) / fine a mano', () {
      final List<Evento> es = <Evento>[
        _n('2026-11-12 09:00', 'app luca inizio'),
        _n('2026-11-13 18:00', 'app luca fine'),
        _n('2026-11-16 09:00', 'app luca inizio'),
      ];
      final List<IntervalloProgetto> iv = periodiProgetto(1, es, _ps, _adesso);
      expect(iv.length, 2);
      final PeriodoIA chiuso = periodoProgetto(1, <IntervalloProgetto>[
        iv.first,
      ])!;
      expect(chiuso.da, t('2026-11-12 09:00'));
      expect(chiuso.a, t('2026-11-13 18:00'));
      expect(chiuso.aperto, isFalse);
      final PeriodoIA aperto = periodoProgetto(1, <IntervalloProgetto>[
        iv.last,
      ])!;
      expect(aperto.a, _adesso);
      expect(aperto.aperto, isTrue);
      final PeriodoIA mano = periodoProgetto(1, <IntervalloProgetto>[
        iv.last,
      ], fine: t('2026-11-18 18:00'))!;
      expect(mano.a, t('2026-11-18 18:00'));
      expect(mano.fineAMano, isTrue);
      expect(mano.aperto, isFalse);
      final PeriodoIA tutti = periodoProgetto(1, iv)!;
      expect(tutti.da, t('2026-11-12 09:00'));
      expect(tutti.a, _adesso);
      expect(periodoProgetto(1, iv, fine: t('2026-11-01 00:00')), isNull);
      expect(periodoProgetto(1, const <IntervalloProgetto>[]), isNull);
    });

    test('parti settimanali tagliate al reset', () {
      final List<({DateTime da, DateTime a})> p = partiSettimanali(
        t('2026-11-16 09:00'),
        t('2026-11-19 10:00'),
      );
      expect(p.length, 2);
      expect(p[0].a, t('2026-11-17 20:00'));
      expect(p[1].da, t('2026-11-17 20:00'));
      expect(p[1].a, t('2026-11-19 10:00'));
    });
  });

  group('solo dati del periodo', () {
    final List<Evento> es = <Evento>[
      _n('2026-11-05 09:00', 'sito inizio'),
      _n('2026-11-05 18:00', 'sito fine'),
      _n('2026-11-16 09:00', 'app luca inizio'),
      _n('2026-11-18 10:00', 'nota del 18'),
      _n('2026-11-19 10:00', 'app luca fine'),
    ];

    test('giorno -> solo letture e note di quel giorno', () {
      final PeriodoIA g = periodoGiorno(t('2026-11-18 01:00'), _adesso);
      final List<SettimanaProgetto> r = righePeriodo(
        g,
        letture: ls,
        eventi: es,
        progetti: _ps,
      );
      _soloDentro(r, g.da, g.a);
      final String s = esportaPeriodo(
        g,
        letture: ls,
        eventi: es,
        progetti: _ps,
      );
      expect(s, startsWith('RICHIESTA: '));
      expect(s, contains('GIORNO'));
      expect(s, contains('PERIODO: tipo=giorno da=2026-11-18 00:00'));
      expect(s, contains('durata=24h 00m'));
      expect(s, contains('nota del 18'));
      expect(s, isNot(contains('  2026-11-17 n=')));
      expect(s, isNot(contains('  2026-11-19 n=')));
      expect(s, contains('fable_ultimo=5'));
    });

    test('settimana passata -> solo quella settimana; usa archiviata', () {
      final PeriodoIA w = periodoSettimana(t('2026-11-05 10:00'), _adesso);
      final List<SettimanaProgetto> calc = righePeriodo(
        w,
        letture: ls,
        eventi: es,
        progetti: _ps,
      );
      _soloDentro(calc, w.da, w.a);
      final SettimanaProgetto finta = SettimanaProgetto(
        progettoId: 2,
        inizio: w.da,
        fine: w.a,
        istantanea: calc.first.istantanea,
        log: 'ARCHIVIATA',
      );
      final List<SettimanaProgetto> arch = righePeriodo(
        w,
        letture: ls,
        eventi: es,
        progetti: _ps,
        archiviate: <SettimanaProgetto>[finta],
      );
      expect(arch.single.log, 'ARCHIVIATA');
      final String s = esportaPeriodo(
        w,
        letture: ls,
        eventi: es,
        progetti: _ps,
      );
      expect(s, contains('SETTIMANA'));
      expect(s, contains('da=2026-11-03 20:00 a=2026-11-10 20:00'));
    });

    test('settimana in corso -> fino ad adesso (no archiviata)', () {
      final PeriodoIA w = periodoSettimana(_adesso, _adesso);
      final List<SettimanaProgetto> r = righePeriodo(
        w,
        letture: ls,
        eventi: es,
        progetti: _ps,
      );
      _soloDentro(r, w.da, _adesso);
      expect(
        esportaPeriodo(w, letture: ls, eventi: es, progetti: _ps),
        contains('(in corso, fino ad adesso)'),
      );
    });

    test('progetto su 2 settimane -> 2 parti, solo il progetto', () {
      final PeriodoIA p = periodoProgetto(
        1,
        periodiProgetto(1, es, _ps, _adesso),
      )!;
      expect(p.da, t('2026-11-16 09:00'));
      expect(p.a, t('2026-11-19 10:00'));
      final List<SettimanaProgetto> r = righePeriodo(
        p,
        letture: ls,
        eventi: es,
        progetti: _ps,
      );
      expect(r.length, 2);
      expect(r.every((SettimanaProgetto x) => x.progettoId == 1), isTrue);
      _soloDentro(r, p.da, p.a);
      final String s = esportaPeriodo(
        p,
        letture: ls,
        eventi: es,
        progetti: _ps,
      );
      expect(s, contains('PROGETTO'));
      expect(s, contains('PROGETTO: "App Luca"'));
      expect(s, contains('parti_settimanali=2'));
      expect(s, contains('TOTALE_PROGETTO'));
      expect(s, contains('fine=da nota fine'));
    });

    test('progetto aperto -> fino ad adesso; fine a mano -> si ferma lì', () {
      final List<Evento> aperti = es.sublist(0, 4);
      final PeriodoIA p = periodoProgetto(
        1,
        periodiProgetto(1, aperti, _ps, _adesso),
      )!;
      expect(p.a, _adesso);
      final String s = esportaPeriodo(
        p,
        letture: ls,
        eventi: aperti,
        progetti: _ps,
      );
      expect(s, contains('nessuna nota fine: fino ad adesso'));
      final PeriodoIA m = periodoProgetto(
        1,
        periodiProgetto(1, aperti, _ps, _adesso),
        fine: t('2026-11-18 12:00'),
      )!;
      final List<SettimanaProgetto> r = righePeriodo(
        m,
        letture: ls,
        eventi: aperti,
        progetti: _ps,
      );
      _soloDentro(r, m.da, t('2026-11-18 12:00'));
      expect(
        esportaPeriodo(m, letture: ls, eventi: aperti, progetti: _ps),
        contains('scelta a mano'),
      );
    });

    test('nessun segreto nel testo', () {
      final List<Evento> brutti = <Evento>[
        ...es,
        _n('2026-11-18 11:00', 'sessionKey=sk-ant-xxx cookie'),
      ];
      final String s = esportaPeriodo(
        periodoGiorno(t('2026-11-18 01:00'), _adesso),
        letture: ls,
        eventi: brutti,
        progetti: _ps,
      );
      expect(parolaVietataEsportazione.hasMatch(s), isFalse);
      expect(s, contains(rigaRimossa));
    });
  });

  test('nomi file e filtro resoconti salvati', () {
    final PeriodoIA g = periodoGiorno(t('2026-11-18 01:00'), _adesso);
    expect(nomeFilePeriodo(g), 'traker-ia_2026-11-18_giorno.md');
    final PeriodoIA w = periodoSettimana(t('2026-11-12 01:00'), _adesso);
    expect(nomeFilePeriodo(w), 'traker-ia_2026-11-10_settimana.md');
    final PeriodoIA p = PeriodoIA(
      tipo: TipoPeriodo.progetto,
      da: t('2026-11-16 09:00'),
      a: _adesso,
      progettoId: 1,
    );
    expect(
      nomeFilePeriodo(p, nomeProgetto: 'App Luca'),
      'traker-ia_2026-11-16_progetto-app-luca.md',
    );
    expect(
      resocontoDelPeriodo('traker-ia_2026-11-18_giorno_resoconto.md', g),
      isTrue,
    );
    expect(
      resocontoDelPeriodo('traker-ia_2026-11-18_settimana_resoconto.md', g),
      isFalse,
    );
    expect(
      resocontoDelPeriodo(
        'traker-ia_2026-11-16_progetto-app-luca_resoconto.md',
        p,
        nomeProgetto: 'App Luca',
      ),
      isTrue,
    );
  });
}
