// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Finti per i test dello strato data (niente rete, niente cassaforte vera).
import 'package:traker_ia/data/cassaforte.dart';
import 'package:traker_ia/data/rete.dart';

/// Richiesta registrata dal client finto.
typedef Richiesta = ({Uri url, Map<String, String> intestazioni});

/// Client finto: risponde in base al percorso dell'URL.
class ClientFinto implements ClientJson {
  /// Crea il client con le [risposte] per percorso (Object = JSON,
  /// Exception = da lanciare).
  ClientFinto(this.risposte);

  /// Risposte per percorso URL.
  final Map<String, Object?> risposte;

  /// Richieste fatte.
  final List<Richiesta> richieste = <Richiesta>[];

  @override
  Future<Object?> prendi(Uri url, Map<String, String> intestazioni) async {
    richieste.add((url: url, intestazioni: intestazioni));
    final Object? r = risposte[url.path];
    if (r is Exception) {
      throw r;
    }
    return r;
  }
}

/// Cassaforte in memoria.
class CassaforteMemoria implements Cassaforte {
  /// Valori salvati.
  final Map<String, String> valori = <String, String>{};

  @override
  Future<String?> leggi(String chiave) async => valori[chiave];

  @override
  Future<void> scrivi(String chiave, String valore) async {
    valori[chiave] = valore;
  }

  @override
  Future<void> cancella(String chiave) async {
    valori.remove(chiave);
  }
}
