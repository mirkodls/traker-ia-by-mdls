// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato data: cassaforte per i segreti (cookie/token claude.ai).
// Cifrati dal sistema (Windows: legati al tuo utente), solo su questo
// dispositivo. Mai nel database, mai nei log, mai nel sync.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Chiave del cookie di claude.ai (sessionKey).
const String chiaveCookieAnthropic = 'anthropic_cookie';

/// Chiave dell'id organizzazione claude.ai trovato col cookie.
const String chiaveOrgAnthropic = 'anthropic_org';

/// Posto sicuro per i segreti.
abstract interface class Cassaforte {
  /// Valore di [chiave], null se non c'è.
  Future<String?> leggi(String chiave);

  /// Salva [valore] in [chiave] (sovrascrive).
  Future<void> scrivi(String chiave, String valore);

  /// Cancella [chiave].
  Future<void> cancella(String chiave);
}

/// Cassaforte del sistema operativo (flutter_secure_storage).
class CassaforteSistema implements Cassaforte {
  /// Crea la cassaforte ([archivio] solo per prove).
  CassaforteSistema([FlutterSecureStorage? archivio])
    : _s = archivio ?? const FlutterSecureStorage();

  final FlutterSecureStorage _s;

  @override
  Future<String?> leggi(String chiave) => _s.read(key: chiave);

  @override
  Future<void> scrivi(String chiave, String valore) =>
      _s.write(key: chiave, value: valore);

  @override
  Future<void> cancella(String chiave) => _s.delete(key: chiave);
}

/// Salva il cookie incollato a mano e dimentica l'organizzazione vecchia.
/// Cookie vuoto = cancella.
Future<void> salvaCookieAnthropic(Cassaforte c, String cookie) async {
  await c.cancella(chiaveOrgAnthropic);
  final String pulito = cookie.trim();
  if (pulito.isEmpty) {
    await c.cancella(chiaveCookieAnthropic);
  } else {
    await c.scrivi(chiaveCookieAnthropic, pulito);
  }
}
