// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Cliente IA contro un server HTTP finto locale (nessuna rete vera, chiavi
// finte "test-..."). Controlla anche che la chiave non esca mai.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/data/cliente_ia.dart';
import 'package:traker_ia/domain/resoconto_ia.dart';

import 'finti.dart';

const String _k = 'test-xxx-chiave-finta-9876';

/// Richiesta ricevuta dal server finto.
typedef _Ricevuta = ({
  String metodo,
  String percorso,
  Map<String, String> h,
  Map<String, Object?> corpo,
});

class _Server {
  late HttpServer s;
  final List<_Ricevuta> ricevute = <_Ricevuta>[];
  int codice = 200;
  Object? risposta;
  Duration ritardo = Duration.zero;

  Uri get base => Uri.parse('http://127.0.0.1:${s.port}');

  Future<void> avvia() async {
    s = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    s.listen((HttpRequest r) async {
      final String testo = await utf8.decodeStream(r);
      final Map<String, String> h = <String, String>{};
      r.headers.forEach((String n, List<String> v) => h[n] = v.join(','));
      ricevute.add((
        metodo: r.method,
        percorso: r.uri.toString(),
        h: h,
        corpo: jsonDecode(testo) as Map<String, Object?>,
      ));
      if (ritardo > Duration.zero) {
        await Future<void>.delayed(ritardo);
      }
      r.response
        ..statusCode = codice
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(risposta));
      await r.response.close();
    });
  }
}

Object _rispostaPer(FornitoreIA f, String t) => switch (f) {
  FornitoreIA.anthropic => <String, Object?>{
    'content': <Object?>[
      <String, Object?>{'type': 'text', 'text': t},
    ],
  },
  FornitoreIA.gemini => <String, Object?>{
    'candidates': <Object?>[
      <String, Object?>{
        'content': <String, Object?>{
          'parts': <Object?>[
            <String, Object?>{'text': t},
          ],
        },
      },
    ],
  },
  FornitoreIA.openai || FornitoreIA.compatibile => <String, Object?>{
    'choices': <Object?>[
      <String, Object?>{
        'message': <String, Object?>{'content': t},
      },
    ],
  },
};

ConfigIA _config(FornitoreIA f) => ConfigIA(
  fornitore: f,
  modelli: f == FornitoreIA.compatibile
      ? <FornitoreIA, String>{f: 'modello-finto'}
      : const <FornitoreIA, String>{},
  url: f == FornitoreIA.compatibile ? 'https://non-usato.it/v1' : '',
);

void main() {
  late _Server srv;
  late CassaforteMemoria cass;
  late ClienteIA ia;

  setUp(() async {
    srv = _Server();
    await srv.avvia();
    cass = CassaforteMemoria();
    ia = ClienteIA(cassaforte: cass, base: srv.base);
  });

  tearDown(() async => srv.s.close(force: true));

  for (final FornitoreIA f in FornitoreIA.values) {
    test(
      '${f.id}: POST giusto, chiave solo in header, risposta letta',
      () async {
        await ia.salvaChiave(f, '  $_k  ');
        expect(cass.valori[f.chiaveCassaforte], _k);
        expect(await ia.fineChiaveSalvata(f), '9876');
        srv.risposta = _rispostaPer(f, 'Resoconto pronto');
        final String r = await ia.chiedi(_config(f), 'DATI SETTIMANA');
        expect(r, 'Resoconto pronto');
        final _Ricevuta q = srv.ricevute.single;
        expect(q.metodo, 'POST');
        expect(q.percorso, isNot(contains(_k)));
        expect(jsonEncode(q.corpo), contains('DATI SETTIMANA'));
        expect(jsonEncode(q.corpo), isNot(contains(_k)));
        expect(q.h['content-type'], contains('application/json'));
        expect(q.h['user-agent'], contains('TraKer-IA'));
        switch (f) {
          case FornitoreIA.anthropic:
            expect(q.percorso, '/v1/messages');
            expect(q.h['x-api-key'], _k);
            expect(q.h['anthropic-version'], versioneAnthropic);
          case FornitoreIA.gemini:
            expect(q.percorso, '/models/gemini-flash-latest:generateContent');
            expect(q.h['x-goog-api-key'], _k);
          case FornitoreIA.openai:
          case FornitoreIA.compatibile:
            expect(q.percorso, '/chat/completions');
            expect(q.h['authorization'], 'Bearer $_k');
        }
      },
    );
  }

  test('prova = chiamata minima (Anthropic max_tokens 16)', () async {
    await ia.salvaChiave(FornitoreIA.anthropic, _k);
    srv.risposta = _rispostaPer(FornitoreIA.anthropic, 'OK');
    expect(await ia.prova(ConfigIA()), 'OK');
    expect(srv.ricevute.single.corpo['max_tokens'], maxTokenProva);
    expect(jsonEncode(srv.ricevute.single.corpo), contains(testoProva));
  });

  test('compatibile senza chiave: nessun header authorization', () async {
    srv.risposta = _rispostaPer(FornitoreIA.compatibile, 'ok locale');
    expect(await ia.chiedi(_config(FornitoreIA.compatibile), 'x'), 'ok locale');
    expect(srv.ricevute.single.h.containsKey('authorization'), isFalse);
  });

  test('chiave mancante: errore senza chiamare il server', () async {
    await expectLater(ia.chiedi(ConfigIA(), 'x'), throwsA(isA<ErroreIA>()));
    expect(srv.ricevute, isEmpty);
  });

  test('codici HTTP -> messaggi italiani, mai chiave o corpo', () async {
    await ia.salvaChiave(FornitoreIA.openai, _k);
    final ConfigIA c = _config(FornitoreIA.openai);
    final Map<int, String> attesi = <int, String>{
      401: 'chiave API sbagliata',
      403: 'chiave API sbagliata',
      402: 'credito',
      429: 'limite',
      404: 'modello',
      500: 'riprova',
    };
    for (final MapEntry<int, String> e in attesi.entries) {
      srv
        ..codice = e.key
        ..risposta = <String, Object?>{
          'error': <String, Object?>{'message': 'Incorrect API key $_k'},
        };
      try {
        await ia.chiedi(c, 'x');
        fail('doveva fallire ${e.key}');
      } on ErroreIA catch (err) {
        expect(err.messaggio, contains(e.value), reason: '${e.key}');
        expect(err.messaggio, isNot(contains(_k)));
        expect('$err', isNot(contains('Incorrect')));
      }
    }
  });

  test('risposta vuota o non JSON', () async {
    await ia.salvaChiave(FornitoreIA.anthropic, _k);
    srv.risposta = <String, Object?>{'content': <Object?>[]};
    await expectLater(
      ia.chiedi(ConfigIA(), 'x'),
      throwsA(
        isA<ErroreIA>().having(
          (ErroreIA e) => e.messaggio,
          'm',
          contains('vuota'),
        ),
      ),
    );
  });

  test('la chiave rimandata indietro dall\'IA viene tolta', () async {
    await ia.salvaChiave(FornitoreIA.anthropic, _k);
    srv.risposta = _rispostaPer(FornitoreIA.anthropic, 'la tua chiave: $_k');
    final String r = await ia.chiedi(ConfigIA(), 'x');
    expect(r, isNot(contains(_k)));
    expect(r, contains('[RIMOSSO]'));
  });

  test('rete assente e tempo scaduto', () async {
    await ia.salvaChiave(FornitoreIA.anthropic, _k);
    final int porta = srv.s.port;
    await srv.s.close(force: true);
    final ClienteIA morto = ClienteIA(
      cassaforte: cass,
      base: Uri.parse('http://127.0.0.1:$porta'),
    );
    await expectLater(
      morto.chiedi(ConfigIA(), 'x'),
      throwsA(
        isA<ErroreIA>().having(
          (ErroreIA e) => e.messaggio,
          'm',
          contains('rete'),
        ),
      ),
    );
    srv = _Server();
    await srv.avvia();
    srv
      ..ritardo = const Duration(seconds: 2)
      ..risposta = _rispostaPer(FornitoreIA.anthropic, 'tardi');
    final ClienteIA lento = ClienteIA(
      cassaforte: cass,
      base: srv.base,
      attesa: const Duration(milliseconds: 300),
    );
    await expectLater(
      lento.chiedi(ConfigIA(), 'x'),
      throwsA(
        isA<ErroreIA>().having(
          (ErroreIA e) => e.messaggio,
          'm',
          contains('tempo scaduto'),
        ),
      ),
    );
  });

  test('salva/cancella chiave, chiave non valida rifiutata', () async {
    await expectLater(
      ia.salvaChiave(FornitoreIA.gemini, 'con spazi dentro'),
      throwsA(isA<ErroreIA>()),
    );
    expect(cass.valori, isEmpty);
    await ia.salvaChiave(FornitoreIA.gemini, _k);
    await ia.salvaChiave(FornitoreIA.gemini, '');
    expect(cass.valori, isEmpty);
    expect(await ia.fineChiaveSalvata(FornitoreIA.gemini), isNull);
    expect(ia.attesa, attesaIA);
    expect(attesaIA, const Duration(seconds: 60));
  });

  test('elencaResoconti: solo _resoconto.md della settimana, più nuovi '
      'prima; cartella mancante = vuoto', () async {
    final Directory d = await Directory.systemTemp.createTemp('resoconti');
    addTearDown(() => d.delete(recursive: true));
    for (final String n in <String>[
      'traker-ia_2026-11-10_resoconto.md',
      'traker-ia_2026-11-10_alfa_resoconto.md',
      'traker-ia_2026-11-10_alfa.md',
      'traker-ia_2026-11-03_resoconto.md',
      'note.txt',
    ]) {
      await File('${d.path}${Platform.pathSeparator}$n').writeAsString('x');
    }
    final List<FileResoconto> tutti = await elencaResoconti(d.path);
    expect(tutti.length, 3);
    final List<FileResoconto> sett = await elencaResoconti(
      d.path,
      inizio: DateTime(2026, 11, 10, 20),
    );
    expect(sett.map((FileResoconto f) => f.nome), <String>[
      'traker-ia_2026-11-10_resoconto.md',
      'traker-ia_2026-11-10_alfa_resoconto.md',
    ]);
    expect(await elencaResoconti('${d.path}/manca'), isEmpty);
    expect(await elencaResoconti(''), isEmpty);
  });
}
