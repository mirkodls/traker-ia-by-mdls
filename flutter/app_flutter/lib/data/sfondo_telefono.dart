// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato data (solo telefono): lettura in sottofondo con WorkManager di
// Android (pacchetto workmanager, MIT) e canale "traker_ia/telefono"
// (MainActivity.kt) per cookie della pagina di login, batteria, permessi.
// Cookie: solo dalla pagina di login alla cassaforte, mai nei log.
import 'package:flutter/services.dart';

import 'package:traker_ia/data/archivio.dart';
import 'package:traker_ia/data/cassaforte.dart';
import 'package:traker_ia/data/database.dart';
import 'package:traker_ia/data/lettori_anthropic.dart';
import 'package:traker_ia/data/rete.dart';
import 'package:traker_ia/domain/catena.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/sfondo.dart';
import 'package:workmanager/workmanager.dart';

/// Nome unico del lavoro periodico.
const String lavoroLetture = 'traker_ia_letture';

/// Esito di una lettura in sottofondo (per i test).
enum EsitoSfondo {
  /// Lettura salvata.
  salvata,

  /// Niente da fare (solo manuale o login mancante).
  saltata,

  /// Il sito ha rifiutato l'accesso: rifare il login.
  loginScaduto,

  /// Rete o risposta sbagliata: si riprova al prossimo giro.
  fallita,
}

/// Punto di partenza di Android per il lavoro in sottofondo.
@pragma('vm:entry-point')
void avvioSfondo() {
  Workmanager().executeTask((String compito, Map<String, Object?>? _) async {
    final Archivio a = Archivio(DatabaseTraker.suDisco());
    try {
      await letturaSfondo(
        a,
        LettoreClaudeWeb(
          client: const ClientJsonIo(),
          cassaforte: CassaforteSistema(),
        ),
      );
    } finally {
      await a.chiudi();
    }
    // Sempre "riuscito": niente nuovi tentativi (= batteria); il prossimo
    // giro arriva comunque.
    return true;
  });
}

/// Una lettura in sottofondo col [web] salvata in [a] (senza doppioni).
Future<EsitoSfondo> letturaSfondo(
  Archivio a,
  LettoreClaudeWeb web, {
  DateTime Function() orologio = DateTime.now,
}) async {
  final Map<String, String?> imp = <String, String?>{
    for (final String k in Chiavi.tutte) k: await a.impostazione(k),
  };
  final Preferenze pref = Preferenze.daMappa(imp);
  // Interruttore spento: niente rete, niente batteria (anche se Android
  // non ha ancora tolto il lavoro).
  if (!sfondoDaAccendere(pref, login: true) || !await web.disponibile()) {
    return EsitoSfondo.saltata;
  }
  try {
    final Uso uso = await web.leggi();
    if (uso.vuoto) {
      return EsitoSfondo.fallita;
    }
    await a.aggiungiLettureSenzaDoppioni(<Lettura>[
      letturaAutomatica(uso, orologio(), pref, await a.eventi()),
    ]);
    if (imp[Chiavi.loginScaduto] == '1') {
      await a.salvaImpostazione(Chiavi.loginScaduto, '0');
    }
    return EsitoSfondo.salvata;
  } on ErroreLettura catch (e) {
    if (e.loginScaduto) {
      await a.salvaImpostazione(Chiavi.loginScaduto, '1');
      return EsitoSfondo.loginScaduto;
    }
    return EsitoSfondo.fallita;
  }
}

/// Comandi del telefono (solo Android).
class Telefono {
  /// Crea i comandi.
  const Telefono();

  static const MethodChannel _canale = MethodChannel('traker_ia/telefono');

  /// Prepara WorkManager (una volta all'avvio dell'app).
  Future<void> prepara() => Workmanager().initialize(avvioSfondo);

  /// Accende (ogni [minuti], mai sotto 15) o spegne la lettura in sottofondo.
  /// Leggerezza: solo con internet e batteria non bassa.
  Future<void> sfondo({required int minuti, required bool acceso}) async {
    if (!acceso) {
      await Workmanager().cancelByUniqueName(lavoroLetture);
      return;
    }
    await Workmanager().registerPeriodicTask(
      lavoroLetture,
      lavoroLetture,
      frequency: Duration(minutes: minutiSfondo(minuti)),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }

  /// Cookie della pagina di login per [sito] ('' = nessuno).
  Future<String> cookie(String sito) async =>
      await _chiama<String>('cookie', <String, String>{'sito': sito}) ?? '';

  /// Sistema la pagina di login [id] (popup, cookie di terze parti).
  Future<void> preparaWeb(int id) =>
      _chiama<bool>('preparaWeb', <String, int>{'id': id});

  /// Vero se la batteria è "senza limiti" per l'app (null = non so).
  Future<bool?> batteriaLibera() => _chiama<bool>('batteriaLibera');

  /// Apre la pagina del permesso [voce] (vedi Permesso); se manca su
  /// questo telefono apre Info app.
  Future<void> apriPermesso(String voce) =>
      _chiama<bool>('apriPermesso', <String, String>{'voce': voce});

  /// B21: menu Android "Condividi" col [testo] (falso se non riuscito).
  Future<bool> condividi(String testo, String titolo) async =>
      await _chiama<bool>('condividi', <String, String>{
        'testo': testo,
        'titolo': titolo,
      }) ??
      false;

  /// B21: salva [testo] in Documenti/TraKer IA/[nome]; ritorna il percorso.
  /// Errore -> eccezione (il dialogo mostra il messaggio).
  Future<String> salvaDocumento(String nome, String testo) async {
    final String? p = await _canale.invokeMethod<String>(
      'salvaDocumento',
      <String, String>{'nome': nome, 'testo': testo},
    );
    if (p == null) {
      throw StateError('salva');
    }
    return p;
  }

  Future<T?> _chiama<T>(String metodo, [Object? argomenti]) async {
    try {
      return await _canale.invokeMethod<T>(metodo, argomenti);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
