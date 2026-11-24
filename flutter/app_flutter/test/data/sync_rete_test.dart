// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Sync vero su 127.0.0.1: due database in memoria (PC e telefono).
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/data/archivio.dart';
import 'package:traker_ia/data/archivio_progetti.dart';
import 'package:traker_ia/data/database.dart';
import 'package:traker_ia/data/sync_rete.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/sync_dati.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';

import 'finti.dart';

class _Lato {
  _Lato() : db = DatabaseTraker(NativeDatabase.memory()) {
    a = Archivio(db);
    p = ArchivioProgetti(db);
    dati = DatiSync(a, p);
  }
  final DatabaseTraker db;
  late final Archivio a;
  late final ArchivioProgetti p;
  late final DatiSync dati;
  final CassaforteMemoria c = CassaforteMemoria();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late _Lato pc;
  late _Lato tel;
  late ServerSync server;
  final DateTime t0 = DateTime(2026, 11, 20, 10);

  ClientSync client() => ClientSync(
    dati: tel.dati,
    cassaforte: tel.c,
    porta: server.portaVera,
    portaUdp: server.portaUdpVera,
    controllaWifi: () async => true,
    indirizzoRicerca: InternetAddress.loopbackIPv4,
  );

  Future<String?> abbina({String? codiceSbagliato}) async {
    final Completer<String> codice = Completer<String>();
    String? nome;
    await server.apriAbbinamento(
      mostraCodice: codice.complete,
      abbinato: (String n) => nome = n,
    );
    final EsitoSync e = await client().abbina(
      () async => codiceSbagliato ?? await codice.future,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return e.ok ? nome : null;
  }

  setUp(() async {
    pc = _Lato();
    tel = _Lato();
    server = ServerSync(
      dati: pc.dati,
      cassaforte: pc.c,
      nome: 'PC-MIRKO',
      porta: 0,
      portaUdp: 0,
    );
    expect(await server.avvia(), isTrue);
  });

  tearDown(() async {
    await server.ferma();
    await pc.a.chiudi();
    await tel.a.chiudi();
  });

  test('B23 interfaccia Wi-Fi: Android wlan*, iPhone solo en0', () {
    expect(interfacciaWifi('wlan0', iphone: false), isTrue);
    expect(interfacciaWifi('rmnet0', iphone: false), isFalse);
    expect(interfacciaWifi('en0', iphone: true), isTrue);
    expect(interfacciaWifi('pdp_ip0', iphone: true), isFalse);
    expect(interfacciaWifi('en2', iphone: true), isFalse);
  });

  test('B23 vicini /24: 253 indirizzi, senza il proprio, solo IPv4', () {
    final List<InternetAddress> v = indirizziVicini(
      InternetAddress('192.168.1.37'),
    );
    expect(v, hasLength(253));
    expect(v.first.address, '192.168.1.1');
    expect(v.last.address, '192.168.1.254');
    expect(
      v.map((InternetAddress a) => a.address),
      isNot(contains('192.168.1.37')),
    );
    expect(indirizziVicini(InternetAddress('::1')), isEmpty);
  });

  test(
    'B23 iPhone: trova il PC chiedendo ai vicini (senza broadcast)',
    () async {
      final ClientSync c = ClientSync(
        dati: tel.dati,
        cassaforte: tel.c,
        porta: server.portaVera,
        portaUdp: server.portaUdpVera,
        controllaWifi: () async => true,
        // Domanda "broadcast" verso un indirizzo dove nessuno risponde
        // (192.0.2.1 = rete di esempio): il PC risponde solo al vicino.
        indirizzoRicerca: InternetAddress('192.0.2.1'),
        sottoRete: true,
        mieiIndirizzi: () async => <InternetAddress>[
          InternetAddress('127.0.0.2'),
        ],
      );
      final ({InternetAddress ip, int porta})? t = await c.cerca();
      expect(t, isNotNull);
      expect(t!.ip.address, '127.0.0.1');
      expect(t.porta, server.portaVera);
    },
  );

  test('B23 senza vicini lo stesso indirizzo muto non trova niente', () async {
    final ClientSync c = ClientSync(
      dati: tel.dati,
      cassaforte: tel.c,
      porta: server.portaVera,
      portaUdp: server.portaUdpVera,
      controllaWifi: () async => true,
      indirizzoRicerca: InternetAddress('192.0.2.1'),
      mieiIndirizzi: () async => <InternetAddress>[
        InternetAddress('127.0.0.2'),
      ],
    );
    expect(await c.cerca(), isNull);
  });

  test(
    'abbinamento: ricerca UDP + codice giusto -> coppia salvata da entrambi',
    () async {
      expect(await abbina(), 'Telefono');
      expect((await leggiCoppie(pc.c)).single.nome, 'Telefono');
      final Coppia ct = (await leggiCoppie(tel.c)).single;
      expect(ct.nome, 'PC-MIRKO');
      expect(ct.chiave, (await leggiCoppie(pc.c)).single.chiave);
      expect(await tel.a.impostazione(ChiaviSync.ipPc), '127.0.0.1');
      // Chiave mai nelle impostazioni (solo cassaforte).
      expect(pc.c.valori[chiaveCoppieSync], isNotNull);
    },
  );

  test('codice sbagliato: niente coppia', () async {
    expect(await abbina(codiceSbagliato: '000000x'), isNull);
    expect(await leggiCoppie(tel.c), isEmpty);
    expect(await leggiCoppie(pc.c), isEmpty);
  });

  test('abbinamento chiuso sul PC: messaggio giusto', () async {
    final EsitoSync e = await client().abbina(() async => '1');
    expect(e.ok, isFalse);
    expect(e.messaggio, Testi.syncApriAbbinaSulPc);
  });

  test('non abbinato / telefono sconosciuto', () async {
    expect((await client().sincronizza()).messaggio, Testi.syncNonAbbinato);
    await abbina();
    await pc.c.cancella(chiaveCoppieSync);
    expect((await client().sincronizza()).messaggio, Testi.syncRiabbina);
  });

  test('sync: letture/eventi/progetti nei due sensi, solo aggiunte, impostazioni più recenti', () async {
    await abbina();
    await pc.a.aggiungiLettura(Lettura(ora: t0, sett: 21, sess: 14));
    await pc.a.aggiungiLettura(
      Lettura(ora: t0.add(const Duration(minutes: 6)), sett: 21, sess: 15),
    );
    await tel.a.aggiungiLettura(
      Lettura(ora: t0.add(const Duration(seconds: 30)), sett: 21, sess: 14),
    );
    await tel.a.aggiungiLettura(
      Lettura(
        ora: t0.add(const Duration(hours: 1)),
        sett: 23,
        sess: 20,
        fable: 4,
      ),
    );
    await tel.a.aggiungiEvento(
      Evento(ora: t0, tipo: TipoEvento.nota, testo: 'dal tel'),
    );
    await pc.p.aggiungiProgetto(const Progetto(nome: 'App', colore: 7));
    await tel.p.aggiungiProgetto(const Progetto(nome: 'Sito'));
    await pc.a.salvaImpostazione(Chiavi.v2SogliaRosso, '90');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await tel.a.salvaImpostazione(Chiavi.v2SogliaRosso, '80');
    await pc.a.salvaImpostazione(Chiavi.minuti, '3');
    final int idPcPrima = (await pc.db.select(pc.db.letture).get()).first.id;

    final Future<int> arrivo = server.sincronizzati.first;
    final EsitoSync e = await client().sincronizza();
    expect(e.ok, isTrue, reason: e.messaggio);
    expect(e.ricevute, 2); // lettura +6 min + progetto App (t0 = doppione)
    expect(await arrivo, 3); // lettura +1 h + evento + progetto Sito

    for (final _Lato l in <_Lato>[pc, tel]) {
      l.a.dimenticaCache();
      expect((await l.a.letture()).length, 3);
      expect((await l.a.eventi()).single.testo, 'dal tel');
      expect(
        (await l.p.progetti()).map((Progetto p) => p.nome).toSet(),
        <String>{'App', 'Sito'},
      );
      expect(await l.a.impostazione(Chiavi.v2SogliaRosso), '80');
    }
    expect(await tel.a.impostazione(Chiavi.minuti), isNull);
    expect((await pc.a.letture()).last.fable, 4);
    // Solo aggiunte: la riga vecchia del PC ha lo stesso id.
    expect((await pc.db.select(pc.db.letture).get()).first.id, idPcPrima);
    expect(await tel.a.impostazione(ChiaviSync.ultimo), isNotNull);

    // Secondo giro: già tutto uguale.
    final EsitoSync e2 = await client().sincronizza();
    expect(e2.ok, isTrue);
    expect(e2.ricevute, 0);
    expect(e2.messaggio, Testi.syncFatto('PC-MIRKO', 0));
  });

  test('settimane per nome progetto + token a mano', () async {
    await abbina();
    final Progetto app = await pc.p.aggiungiProgetto(
      const Progetto(nome: 'App'),
    );
    await pc.db
        .into(pc.db.progettoSettimane)
        .insert(
          ProgettoSettimaneCompanion.insert(
            progettoId: app.id!,
            settInizio: '2026-11-10 20:00',
            settFine: const Value<String?>('2026-11-17 20:00'),
            snapshotJson: const Value<String>('{"x":1}'),
            tokenManuali: const Value<int?>(1234),
          ),
        );
    await tel.p.aggiungiProgetto(const Progetto(nome: 'Altro'));
    expect((await client().sincronizza()).ok, isTrue);
    final List<SettimanaSync> s = await tel.p.settimaneSync(null);
    expect(s.single.progetto, 'App');
    expect(s.single.token, 1234);
    expect(s.single.istantanea, '{"x":1}');
  });

  test(
    'sottofondo senza ricerca: indirizzo vecchio sbagliato -> PC non trovato',
    () async {
      await abbina();
      await tel.a.salvaImpostazione(ChiaviSync.ipPc, '127.0.0.2');
      final EsitoSync e = await ClientSync(
        dati: tel.dati,
        cassaforte: tel.c,
        porta: 1,
        controllaWifi: () async => true,
      ).sincronizza(cerca: false);
      expect(e.messaggio, Testi.syncPcNonTrovato);
    },
  );

  test('niente Wi-Fi: nessuna rete toccata', () async {
    await abbina();
    final EsitoSync e = await ClientSync(
      dati: tel.dati,
      cassaforte: tel.c,
      controllaWifi: () async => false,
    ).sincronizza();
    expect(e.messaggio, Testi.syncNoWifi);
  });

  test('indirizzi di casa', () {
    expect(indirizzoDiCasa(InternetAddress('192.168.1.5')), isTrue);
    expect(indirizzoDiCasa(InternetAddress('10.0.0.2')), isTrue);
    expect(indirizzoDiCasa(InternetAddress('172.20.0.1')), isTrue);
    expect(indirizzoDiCasa(InternetAddress('8.8.8.8')), isFalse);
  });
}
