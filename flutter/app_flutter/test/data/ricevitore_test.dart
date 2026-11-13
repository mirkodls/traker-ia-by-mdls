// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/data/ricevitore.dart';
import 'package:traker_ia/domain/catena.dart';

/// Risposta di una POST di prova.
typedef Esito = ({int codice, String corpo});

Future<Esito> _post(
  int porta,
  String corpo, {
  String percorso = '/lettura',
  ContentType? tipo,
  String? origine,
}) async {
  final HttpClient c = HttpClient();
  try {
    final HttpClientRequest req = await c.post('127.0.0.1', porta, percorso);
    req.headers.contentType = tipo ?? ContentType.json;
    if (origine != null) {
      req.headers.set('origin', origine);
    }
    req.write(corpo);
    final HttpClientResponse r = await req.close();
    return (codice: r.statusCode, corpo: await r.transform(utf8.decoder).join());
  } finally {
    c.close(force: true);
  }
}

const String _uso =
    '{"uso":{"five_hour":{"utilization":9},"seven_day":{"utilization":25}}}';

void main() {
  late Ricevitore r;
  late int porta;
  DateTime adesso = DateTime(2026, 11, 13, 10);

  setUp(() async {
    adesso = DateTime(2026, 11, 13, 10);
    r = Ricevitore(minuti: () => 7, porta: 0, orologio: () => adesso);
    expect(await r.avvia(), isTrue);
    porta = r.portaInUso!;
  });

  tearDown(() => r.ferma());

  test('riceve uso e risponde coi minuti', () async {
    final Future<MessaggioEstensione> primo = r.messaggi.first;
    final Esito e = await _post(porta, _uso, origine: 'chrome-extension://abc');
    expect(e.codice, 200);
    expect(jsonDecode(e.corpo), <String, Object?>{'minuti': 7});
    final MessaggioEstensione m = await primo;
    expect(m.uso!.sess, 9);
    expect(r.ultimo!.uso!.sett, 25);
  });

  test('riceve errore dell\'estensione (accorciato)', () async {
    final String corpo = jsonEncode(<String, String>{'errore': 'x' * 500});
    final Esito e = await _post(porta, corpo);
    expect(e.codice, 200);
    expect(r.ultimo!.errore!.length, maxTestoErrore);
  });

  test('rifiuta: percorso, tipo, origine, JSON rotto', () async {
    expect((await _post(porta, _uso, percorso: '/altro')).codice, 404);
    expect((await _post(porta, _uso, tipo: ContentType.text)).codice, 415);
    expect(
      (await _post(porta, _uso, origine: 'https://sito-cattivo.com')).codice,
      403,
    );
    expect((await _post(porta, '{rotto')).codice, 400);
    expect((await _post(porta, '[1,2]')).codice, 400);
    expect(r.ultimo, isNull);
  });

  test('porta occupata -> falso', () async {
    final Ricevitore r2 = Ricevitore(minuti: () => 1, porta: porta);
    expect(await r2.avvia(), isFalse);
    await r2.ferma();
  });

  test('lettore estensione: nessuno, fresco, vecchio, errore', () async {
    final LettoreEstensione l = LettoreEstensione(
      r,
      validita: () => const Duration(minutes: 15),
      orologio: () => adesso,
    );
    await expectLater(l.leggi(), throwsA(isA<ErroreLettura>()));
    await _post(porta, _uso);
    expect((await l.leggi()).sess, 9);
    adesso = adesso.add(const Duration(minutes: 16));
    await expectLater(
      l.leggi(),
      throwsA(
        isA<ErroreLettura>().having(
          (ErroreLettura e) => e.messaggio,
          'm',
          contains('vecchio'),
        ),
      ),
    );
    await _post(porta, '{"errore":"non sei collegato"}');
    await expectLater(
      l.leggi(),
      throwsA(
        isA<ErroreLettura>().having(
          (ErroreLettura e) => e.messaggio,
          'm',
          'non sei collegato',
        ),
      ),
    );
  });

  test('messaggio: vuoto o senza percentuali = errore', () {
    final DateTime t = DateTime(2026);
    expect(leggiMessaggio(<String, Object?>{}, t).errore, 'messaggio vuoto');
    final Map<String, Object?> vuoto = <String, Object?>{
      'uso': <String, Object?>{},
    };
    final MessaggioEstensione m = leggiMessaggio(vuoto, t);
    expect(m.uso, isNull);
    expect(m.errore, isNotNull);
    expect(origineAmmessa(null), isTrue);
    expect(origineAmmessa('extension://x'), isTrue);
    expect(origineAmmessa('http://localhost'), isFalse);
  });
}
