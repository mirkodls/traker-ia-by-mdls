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
}
