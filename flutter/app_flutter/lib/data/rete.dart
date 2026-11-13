// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato data: richieste HTTP GET che rispondono JSON (dart:io, zero
// pacchetti). Messaggi di errore SENZA segreti e senza indirizzi.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:traker_ia/domain/catena.dart';

/// Nome dell'app nelle richieste.
const String agenteApp = 'TraKer-IA-by-mdls/1.0';

/// Chi fa le richieste GET JSON (interfaccia: nei test c'è un finto).
abstract interface class ClientJson {
  /// GET [url] con [intestazioni]; ritorna il JSON. Errore -> ErroreLettura.
  Future<Object?> prendi(Uri url, Map<String, String> intestazioni);
}

/// Messaggio per un codice HTTP sbagliato.
String messaggioHttp(int codice) {
  if (codice == 401 || codice == 403) {
    return 'accesso negato ($codice): login scaduto o bloccato';
  }
  if (codice == 429) {
    return 'troppe richieste (429): aumenta i minuti';
  }
  return 'errore HTTP $codice';
}

/// Massimo di byte letti da una risposta.
const int maxByteRisposta = 1000000;

/// Client vero con dart:io.
class ClientJsonIo implements ClientJson {
  /// Crea il client con tempo massimo [attesa] per richiesta.
  const ClientJsonIo({this.attesa = const Duration(seconds: 15)});

  /// Tempo massimo di ogni passo della richiesta.
  final Duration attesa;

  @override
  Future<Object?> prendi(Uri url, Map<String, String> intestazioni) async {
    final HttpClient c = HttpClient()..connectionTimeout = attesa;
    try {
      final HttpClientRequest req = await c.getUrl(url).timeout(attesa);
      intestazioni.forEach(req.headers.set);
      final HttpClientResponse r = await req.close().timeout(attesa);
      final List<int> byte = <int>[];
      await for (final List<int> pezzo in r.timeout(attesa)) {
        byte.addAll(pezzo);
        if (byte.length > maxByteRisposta) {
          throw const ErroreLettura('risposta troppo grande');
        }
      }
      if (r.statusCode != HttpStatus.ok) {
        throw ErroreLettura(messaggioHttp(r.statusCode));
      }
      return jsonDecode(utf8.decode(byte));
    } on TimeoutException {
      throw const ErroreLettura('rete: tempo scaduto');
    } on SocketException {
      throw const ErroreLettura('rete: nessuna connessione');
    } on HandshakeException {
      throw const ErroreLettura('rete: connessione sicura fallita');
    } on HttpException {
      throw const ErroreLettura('rete: risposta interrotta');
    } on FormatException {
      throw const ErroreLettura('risposta non valida');
    } finally {
      c.close(force: true);
    }
  }
}
