// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/data/cassaforte.dart';
import 'package:traker_ia/data/lettori_anthropic.dart';
import 'package:traker_ia/data/rete.dart';
import 'package:traker_ia/domain/catena.dart';
import 'package:traker_ia/domain/modelli.dart';

import 'finti.dart';

const String _segreto = 'SEGRETO-123';

const Map<String, Object?> _uso = <String, Object?>{
  'five_hour': <String, Object?>{'utilization': 14},
  'seven_day': <String, Object?>{'utilization': 21},
};

Matcher _errore(String parte) => throwsA(
  isA<ErroreLettura>().having(
    (ErroreLettura e) => e.messaggio,
    'messaggio',
    allOf(contains(parte), isNot(contains(_segreto))),
  ),
);

void main() {
  test('messaggi HTTP', () {
    expect(messaggioHttp(401), contains('login scaduto'));
    expect(messaggioHttp(403), contains('403'));
    expect(messaggioHttp(429), contains('aumenta i minuti'));
    expect(messaggioHttp(500), 'errore HTTP 500');
  });

  test('token dal file credenziali', () {
    expect(
      tokenDaCredenziali('{"claudeAiOauth":{"accessToken":"$_segreto"}}'),
      _segreto,
    );
    expect(tokenDaCredenziali('{"claudeAiOauth":{}}'), isNull);
    expect(tokenDaCredenziali('rotto'), isNull);
    expect(tokenDaCredenziali('[1]'), isNull);
  });

  group('Claude Code', () {
    late Directory d;
    late String file;

    setUp(() {
      d = Directory.systemTemp.createTempSync('traker_cc');
      file = '${d.path}${Platform.pathSeparator}.credentials.json';
    });

    tearDown(() => d.deleteSync(recursive: true));

    test('legge con il token', () async {
      File(file).writeAsStringSync(
        '{"claudeAiOauth":{"accessToken":"$_segreto"}}',
      );
      final ClientFinto c = ClientFinto(<String, Object?>{
        urlUsoOauth.path: _uso,
      });
      final LettoreClaudeCode l = LettoreClaudeCode(
        client: c,
        fileCredenziali: file,
      );
      expect(l.disponibile, isTrue);
      final Uso u = await l.leggi();
      expect(u.sess, 14);
      expect(u.sett, 21);
      expect(c.richieste.single.intestazioni['Authorization'], 'Bearer $_segreto');
    });

    test('file mancante o senza login', () async {
      final LettoreClaudeCode l = LettoreClaudeCode(
        client: ClientFinto(<String, Object?>{}),
        fileCredenziali: file,
      );
      expect(l.disponibile, isFalse);
      await expectLater(l.leggi(), _errore('non trovato'));
      File(file).writeAsStringSync('{}');
      await expectLater(l.leggi(), _errore('login non trovato'));
    });

    test('errore di rete: messaggio senza token', () async {
      File(file).writeAsStringSync(
        '{"claudeAiOauth":{"accessToken":"$_segreto"}}',
      );
      final LettoreClaudeCode l = LettoreClaudeCode(
        client: ClientFinto(<String, Object?>{
          urlUsoOauth.path: ErroreLettura(messaggioHttp(401)),
        }),
        fileCredenziali: file,
      );
      await expectLater(l.leggi(), _errore('401'));
    });
  });

  group('cookie claude.ai', () {
    test('intestazioni: aggiunge sessionKey e toglie a capo', () {
      expect(intestazioniCookie(' abc\n')['Cookie'], 'sessionKey=abc');
      expect(intestazioniCookie('sessionKey=abc')['Cookie'], 'sessionKey=abc');
    });

    test('sceglie organizzazione con chat', () {
      expect(
        scegliOrganizzazione(<Object?>[
          <String, Object?>{'uuid': 'a', 'capabilities': <Object?>['api']},
          <String, Object?>{'uuid': 'b', 'capabilities': <Object?>['chat']},
        ]),
        'b',
      );
      expect(
        scegliOrganizzazione(<Object?>[
          <String, Object?>{'uuid': 'a'},
        ]),
        'a',
      );
      expect(() => scegliOrganizzazione(<Object?>[]), _errore('nessuna'));
      expect(() => scegliOrganizzazione(null), _errore('nessuna'));
    });

    test('cookie mancante', () async {
      final LettoreClaudeWeb l = LettoreClaudeWeb(
        client: ClientFinto(<String, Object?>{}),
        cassaforte: CassaforteMemoria(),
      );
      expect(await l.disponibile(), isFalse);
      await expectLater(l.leggi(), _errore('cookie mancante'));
    });

    test('trova org, la salva e la riusa', () async {
      final CassaforteMemoria cf = CassaforteMemoria();
      await salvaCookieAnthropic(cf, _segreto);
      final ClientFinto c = ClientFinto(<String, Object?>{
        urlOrganizzazioni.path: <Object?>[
          <String, Object?>{'uuid': 'org1', 'capabilities': <Object?>['chat']},
        ],
        urlUsoOrg('org1').path: _uso,
      });
      final LettoreClaudeWeb l = LettoreClaudeWeb(client: c, cassaforte: cf);
      expect(await l.disponibile(), isTrue);
      expect((await l.leggi()).sett, 21);
      expect(cf.valori[chiaveOrgAnthropic], 'org1');
      expect(c.richieste.length, 2);
      await l.leggi();
      expect(c.richieste.length, 3);
      expect(c.richieste.last.intestazioni['Cookie'], 'sessionKey=$_segreto');
    });

    test('nuovo cookie dimentica la org; vuoto cancella', () async {
      final CassaforteMemoria cf = CassaforteMemoria();
      cf.valori[chiaveOrgAnthropic] = 'vecchia';
      await salvaCookieAnthropic(cf, 'nuovo');
      expect(cf.valori[chiaveOrgAnthropic], isNull);
      await salvaCookieAnthropic(cf, '  ');
      expect(cf.valori[chiaveCookieAnthropic], isNull);
    });
  });

  test('lettori disponibili: estensione sempre, gli altri se pronti', () async {
    final ClientFinto c = ClientFinto(<String, Object?>{});
    final CassaforteMemoria cf = CassaforteMemoria();
    final LettoreClaudeCode cc = LettoreClaudeCode(
      client: c,
      fileCredenziali: 'non_esiste_xyz.json',
    );
    final LettoreClaudeWeb web = LettoreClaudeWeb(client: c, cassaforte: cf);
    List<LettoreUso> l = await lettoriAnthropic(
      estensione: web,
      claudeCode: cc,
      web: web,
    );
    expect(l.length, 1);
    await salvaCookieAnthropic(cf, 'x');
    l = await lettoriAnthropic(estensione: cc, claudeCode: cc, web: web);
    expect(l.map((LettoreUso x) => x.id), <String>['claude_code', 'cookie']);
  });
}
