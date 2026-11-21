// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/data/archivio.dart';
import 'package:traker_ia/data/cassaforte.dart';
import 'package:traker_ia/data/database.dart';
import 'package:traker_ia/data/lettori_anthropic.dart';
import 'package:traker_ia/data/sfondo_telefono.dart';
import 'package:traker_ia/domain/catena.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/preferenze.dart';

import 'finti.dart';

const Map<String, Object?> _uso = <String, Object?>{
  'five_hour': <String, Object?>{'utilization': 14},
  'seven_day': <String, Object?>{'utilization': 21},
};

const String _org = '/api/organizations/org1/usage';

void main() {
  late Archivio a;
  late CassaforteMemoria c;
  final DateTime ora = DateTime(2026, 11, 14, 10, 7, 30);

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() async {
    a = Archivio(DatabaseTraker(NativeDatabase.memory()));
    c = CassaforteMemoria();
    await c.scrivi(chiaveCookieAnthropic, 'sk');
    await c.scrivi(chiaveOrgAnthropic, 'org1');
  });

  tearDown(() async {
    await a.chiudi();
  });

  LettoreClaudeWeb web(Object? risposta) => LettoreClaudeWeb(
    client: ClientFinto(<String, Object?>{_org: risposta}),
    cassaforte: c,
  );

  test('salva la lettura una volta sola (doppioni saltati)', () async {
    expect(
      await letturaSfondo(a, web(_uso), orologio: () => ora),
      EsitoSfondo.salvata,
    );
    await letturaSfondo(a, web(_uso), orologio: () => ora);
    final List<Lettura> l = await a.letture();
    expect(l, hasLength(1));
    expect(l.single.sess, 14);
    expect(l.single.sett, 21);
    expect(l.single.ora, DateTime(2026, 11, 14, 10, 7));
  });

  test('senza cookie o solo manuale: niente', () async {
    await c.cancella(chiaveCookieAnthropic);
    expect(await letturaSfondo(a, web(_uso)), EsitoSfondo.saltata);
    await c.scrivi(chiaveCookieAnthropic, 'sk');
    await a.salvaImpostazione(Chiavi.metodo, metodoManuale);
    expect(await letturaSfondo(a, web(_uso)), EsitoSfondo.saltata);
    expect(await a.letture(), isEmpty);
  });

  test('interruttore Sottofondo spento: niente rete, niente lettura', () async {
    await a.salvaImpostazione(Chiavi.sfondoAcceso, '0');
    expect(await letturaSfondo(a, web(_uso)), EsitoSfondo.saltata);
    expect(await a.letture(), isEmpty);
  });

  test('401: segna login scaduto, poi lettura buona lo toglie', () async {
    const Object scaduto = ErroreLettura('401', loginScaduto: true);
    expect(await letturaSfondo(a, web(scaduto)), EsitoSfondo.loginScaduto);
    expect(await a.impostazione(Chiavi.loginScaduto), '1');
    await letturaSfondo(a, web(_uso), orologio: () => ora);
    expect(await a.impostazione(Chiavi.loginScaduto), '0');
  });

  test('rete giù: fallita, niente segno', () async {
    expect(
      await letturaSfondo(a, web(const ErroreLettura('rete'))),
      EsitoSfondo.fallita,
    );
    expect(await a.impostazione(Chiavi.loginScaduto), isNull);
  });

  test('B21: forma vera /usage (20/11, B19): five_hour null, Fable da '
      'limits, crediti -> salva sett+Fable, sess vuota', () async {
    const Map<String, Object?> vera = <String, Object?>{
      'five_hour': null,
      'seven_day': <String, Object?>{
        'utilization': 71,
        'resets_at': '2026-11-24T19:00:00.331964+00:00',
      },
      'seven_day_opus': null,
      'limits': <Object?>[
        <String, Object?>{'kind': 'weekly_all', 'percent': 71, 'scope': null},
        <String, Object?>{
          'kind': 'weekly_scoped',
          'percent': 93,
          'scope': <String, Object?>{
            'model': <String, Object?>{'id': null, 'display_name': 'Fable'},
          },
        },
      ],
      'spend': <String, Object?>{
        'enabled': true,
        'used': <String, Object?>{
          'amount_minor': 1250,
          'exponent': 2,
          'currency': 'USD',
        },
      },
    };
    expect(
      await letturaSfondo(a, web(vera), orologio: () => ora),
      EsitoSfondo.salvata,
    );
    final Lettura l = (await a.letture()).single;
    expect(l.sett, 71);
    expect(l.sess, isNull);
    expect(l.fable, 93);
  });
}
