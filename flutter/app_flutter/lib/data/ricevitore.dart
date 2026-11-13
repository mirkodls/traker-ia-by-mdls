// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato data: ricevitore locale per l'estensione del browser.
// POST http://127.0.0.1:45782/lettura
// Corpo JSON: {"uso": <risposta /usage>} oppure {"errore": "testo"}.
// Risposta: {"minuti": N} (ogni quanto l'estensione deve leggere).
// Ascolta SOLO su 127.0.0.1 (non raggiungibile da altri PC). Accetta solo
// JSON e, se c'è Origin, solo da estensioni. Niente log.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:traker_ia/domain/analisi.dart';
import 'package:traker_ia/domain/catena.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/tempo.dart';

/// Porta del ricevitore (diversa da quella dell'app Python: 45781).
const int portaRicevitore = 45782;

/// Massimo di byte accettati in un messaggio.
const int maxByteMessaggio = 1000000;

/// Lunghezza massima del testo di errore mandato dall'estensione.
const int maxTestoErrore = 200;

/// Messaggio arrivato dall'estensione.
class MessaggioEstensione {
  /// Crea il messaggio.
  const MessaggioEstensione({required this.ora, this.uso, this.errore});

  /// Quando è arrivato.
  final DateTime ora;

  /// Uso letto (null se errore).
  final Uso? uso;

  /// Errore dell'estensione (null se ok).
  final String? errore;
}

/// JSON dell'estensione -> messaggio.
MessaggioEstensione leggiMessaggio(Map<String, Object?> dati, DateTime ora) {
  final Object? e = dati['errore'];
  if (e is String && e.trim().isNotEmpty) {
    final String t = e.trim();
    return MessaggioEstensione(
      ora: ora,
      errore: t.length > maxTestoErrore ? t.substring(0, maxTestoErrore) : t,
    );
  }
  final Object? u = dati['uso'];
  if (u == null) {
    return MessaggioEstensione(ora: ora, errore: 'messaggio vuoto');
  }
  final Uso uso = leggiRisposta(u);
  if (uso.vuoto) {
    return MessaggioEstensione(
      ora: ora,
      errore: 'risposta senza percentuali',
    );
  }
  return MessaggioEstensione(ora: ora, uso: uso);
}

/// Vero se l'Origin è assente o di un'estensione del browser.
bool origineAmmessa(String? origine) =>
    origine == null ||
    origine.startsWith('chrome-extension://') ||
    origine.startsWith('extension://');

/// Server locale che riceve le letture dall'estensione.
class Ricevitore {
  /// Crea il ricevitore. [minuti] = intervallo da dire all'estensione.
  Ricevitore({
    required this.minuti,
    this.porta = portaRicevitore,
    DateTime Function()? orologio,
  }) : _orologio = orologio ?? DateTime.now;

  /// Ogni quanti minuti l'estensione deve leggere.
  final int Function() minuti;

  /// Porta richiesta (0 = qualsiasi, per i test).
  final int porta;

  final DateTime Function() _orologio;
  final StreamController<MessaggioEstensione> _flusso =
      StreamController<MessaggioEstensione>.broadcast();
  HttpServer? _server;
  StreamSubscription<HttpRequest>? _ascolto;
  MessaggioEstensione? _ultimo;

  /// Messaggi in arrivo.
  Stream<MessaggioEstensione> get messaggi => _flusso.stream;

  /// Ultimo messaggio arrivato (null = mai).
  MessaggioEstensione? get ultimo => _ultimo;

  /// Porta in uso (null se fermo).
  int? get portaInUso => _server?.port;

  /// Avvia il server. Falso se la porta è occupata.
  Future<bool> avvia() async {
    if (_server != null) {
      return true;
    }
    try {
      final HttpServer s = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        porta,
      );
      _server = s;
      _ascolto = s.listen((HttpRequest r) {
        unawaited(_gestisci(r));
      });
      return true;
    } on SocketException {
      return false;
    }
  }

  /// Ferma il server (definitivo: per ripartire crea un Ricevitore nuovo).
  Future<void> ferma() async {
    await _ascolto?.cancel();
    _ascolto = null;
    await _server?.close(force: true);
    _server = null;
    await _flusso.close();
  }

  Future<void> _gestisci(HttpRequest req) async {
    final HttpResponse res = req.response;
    try {
      if (req.method != 'POST' || req.uri.path != '/lettura') {
        res.statusCode = HttpStatus.notFound;
        return;
      }
      if (!origineAmmessa(req.headers.value('origin'))) {
        res.statusCode = HttpStatus.forbidden;
        return;
      }
      if (req.headers.contentType?.mimeType != ContentType.json.mimeType) {
        res.statusCode = HttpStatus.unsupportedMediaType;
        return;
      }
      final List<int> byte = <int>[];
      await for (final List<int> pezzo in req) {
        byte.addAll(pezzo);
        if (byte.length > maxByteMessaggio) {
          res.statusCode = HttpStatus.requestEntityTooLarge;
          return;
        }
      }
      final Object? dati = jsonDecode(utf8.decode(byte));
      if (dati is! Map<String, Object?>) {
        res.statusCode = HttpStatus.badRequest;
        return;
      }
      final MessaggioEstensione m = leggiMessaggio(dati, _orologio());
      _ultimo = m;
      if (!_flusso.isClosed) {
        _flusso.add(m);
      }
      res.headers.contentType = ContentType.json;
      res.write(jsonEncode(<String, int>{'minuti': minuti()}));
    } on FormatException {
      res.statusCode = HttpStatus.badRequest;
    } on HttpException {
      // Estensione sparita a metà: niente da fare.
    } finally {
      try {
        await res.close();
      } on Object {
        // Connessione già chiusa dall'altra parte.
      }
    }
  }
}

/// Lettore che usa l'ultimo messaggio dell'estensione, se recente.
class LettoreEstensione implements LettoreUso {
  /// Crea il lettore. [validita] = età massima del dato.
  LettoreEstensione(
    this.ricevitore, {
    required this.validita,
    DateTime Function()? orologio,
  }) : _orologio = orologio ?? DateTime.now;

  /// Ricevitore da cui prendere i dati.
  final Ricevitore ricevitore;

  /// Età massima di un dato valido (es. 2 intervalli + 1 minuto).
  final Duration Function() validita;

  final DateTime Function() _orologio;

  @override
  String get id => 'estensione';

  @override
  String get nome => 'estensione browser';

  @override
  String get gestore => gestoreAnthropic;

  @override
  Future<Uso> leggi() async {
    final MessaggioEstensione? m = ricevitore.ultimo;
    if (m == null) {
      throw const ErroreLettura('nessun dato dall\'estensione');
    }
    if (_orologio().difference(m.ora) > validita()) {
      throw ErroreLettura('dato vecchio (ultimo ${quando(m.ora)})');
    }
    final String? e = m.errore;
    if (e != null) {
      throw ErroreLettura(e);
    }
    final Uso? uso = m.uso;
    if (uso == null) {
      throw const ErroreLettura('risposta senza percentuali');
    }
    return uso;
  }
}
