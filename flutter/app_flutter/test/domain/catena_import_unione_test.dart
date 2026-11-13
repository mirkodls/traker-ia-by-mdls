// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/catena.dart';
import 'package:traker_ia/domain/import_csv.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/unione.dart';

import 'aiuti.dart';

class _Finto implements LettoreUso {
  _Finto(this.id, this.risposta);

  @override
  final String id;

  final Object risposta;

  @override
  String get nome => id;

  @override
  String get gestore => gestoreAnthropic;

  @override
  Future<Uso> leggi() async {
    final Object r = risposta;
    if (r is Uso) {
      return r;
    }
    if (r is ErroreLettura) {
      throw r;
    }
    throw StateError('rotto');
  }
}

void main() {
  test('scegli lettori', () {
    final List<LettoreUso> tutti = <LettoreUso>[
      _Finto('claude_code', const Uso(sett: 1)),
      _Finto('cookie', const Uso(sett: 1)),
    ];
    expect(scegliLettori(metodoManuale, tutti), isEmpty);
    expect(scegliLettori(metodoAuto, tutti).length, 2);
    expect(scegliLettori('cookie', tutti).single.id, 'cookie');
  });

  test('catena: primo che risponde vince', () async {
    final RisultatoCatena r = await leggiCatena(<LettoreUso>[
      _Finto('a', const ErroreLettura('giù')),
      _Finto('b', const Uso()),
      _Finto('c', const Uso(sett: 20, sess: 5)),
    ]);
    expect(r.lettore, 'c');
    expect(r.uso.sett, 20);
  });

  test('catena: tutti giù = un errore unico', () async {
    await expectLater(
      leggiCatena(<LettoreUso>[
        _Finto('a', const ErroreLettura('giù')),
        _Finto('b', 'boh'),
      ]),
      throwsA(
        isA<ErroreLettura>().having(
          (ErroreLettura e) => e.messaggio,
          'messaggio',
          'a: giù | b: errore StateError',
        ),
      ),
    );
    await expectLater(leggiCatena(<LettoreUso>[]), throwsA(isA<ErroreLettura>()));
  });

  test('avviso dopo 2 giri falliti, una volta', () {
    final AvvisoFallimenti a = AvvisoFallimenti();
    expect(a.ko(), isFalse);
    expect(a.ko(), isTrue);
    expect(a.ko(), isFalse);
    expect(a.koDiFila, 3);
    a.ok();
    expect(a.ko(), isFalse);
    expect(a.ko(), isTrue);
  });

  test('csv con virgolette e righe vuote', () {
    expect(
      leggiCsv('﻿a;b\r\n"x;1";"di ""lui"""\n\n'),
      <List<String>>[
        <String>['a', 'b'],
        <String>['x;1', 'di "lui"'],
      ],
    );
  });

  test('import letture: colonne vecchie e righe rotte', () {
    const String csv = 'ora;settimanale;sessione;fonte\n'
        '2026-11-11 17:12;21;14;iniziale\n'
        '2026-11-11 21:13;25;;\n'
        'rotta;1;2;auto\n'
        '2026-11-11 22:00;abc;2;auto\n';
    final RisultatoImport<Lettura> r = importaLetture(csv);
    expect(r.voci.length, 2);
    expect(r.scartate, 2);
    expect(r.voci[0].fonte, 'iniziale');
    expect(r.voci[1].sess, isNull);
    expect(r.voci[1].fonte, 'auto');
    expect(r.voci[1].alPc, isNull);
  });

  test('import letture: colonne nuove', () {
    const String csv = 'ora;settimanale;sessione;fonte;al_pc;lavoro;modelli;skill\n'
        '2026-11-12 10:00;30;5;auto;1;1;Opus;caveman\n';
    final Lettura x = importaLetture(csv).voci.single;
    expect(x.alPc, isTrue);
    expect(x.lavoro, isTrue);
    expect(x.modelli, 'Opus');
    expect(x.skill, 'caveman');
  });

  test('import eventi', () {
    const String csv = 'ora;tipo;testo\n'
        '2026-11-11 17:30;nota;modifiche risparmio token\n'
        '2026-11-11 18:00;inizio;\n'
        '2026-11-11 19:00;boh;x\n';
    final RisultatoImport<Evento> r = importaEventi(csv);
    expect(r.voci.length, 2);
    expect(r.scartate, 1);
    expect(r.voci.first.testo, 'modifiche risparmio token');
    expect(importaEventi('').voci, isEmpty);
  });

  test('unione letture senza doppioni', () {
    final List<Lettura> mie = <Lettura>[
      l('2026-11-11 10:00', 10, 1),
      l('2026-11-11 11:00', 11, 2),
    ];
    final List<Lettura> arrivate = <Lettura>[
      l('2026-11-11 10:01', 10, 1),
      l('2026-11-11 10:30', 10, 1),
      l('2026-11-11 10:31', 10, 1),
      l('2026-11-11 11:00', 11, 3),
      l('2026-11-11 11:00', 11, 2, gestore: 'openai'),
    ];
    final RisultatoUnione<Lettura> r = unisciLetture(mie, arrivate);
    expect(r.aggiunte, 3);
    expect(r.voci.length, 5);
    expect(unisciLetture(r.voci, arrivate).aggiunte, 0);
  });

  test('unione eventi', () {
    final List<Evento> mie = <Evento>[
      Evento(ora: t('2026-11-11 10:00'), tipo: TipoEvento.nota, testo: 'x'),
    ];
    final RisultatoUnione<Evento> r = unisciEventi(mie, <Evento>[
      Evento(ora: t('2026-11-11 10:01'), tipo: TipoEvento.nota, testo: 'x'),
      Evento(ora: t('2026-11-11 10:01'), tipo: TipoEvento.nota, testo: 'y'),
    ]);
    expect(r.aggiunte, 1);
    expect(r.voci.length, 2);
  });
}
