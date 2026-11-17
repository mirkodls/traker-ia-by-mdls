// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Radice: UNICO posto che collega data e ui. Qui si creano archivio,
// cassaforte, ricevitore e lettori, e si passano alla grafica come Servizi.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import 'package:traker_ia/data/archivio.dart';
import 'package:traker_ia/data/archivio_progetti.dart';
import 'package:traker_ia/data/cassaforte.dart';
import 'package:traker_ia/data/collegamenti_pc.dart';
import 'package:traker_ia/data/database.dart';
import 'package:traker_ia/data/import_file.dart';
import 'package:traker_ia/data/lettori_anthropic.dart';
import 'package:traker_ia/data/rete.dart';
import 'package:traker_ia/data/ricevitore.dart';
import 'package:traker_ia/data/sfondo_telefono.dart';
import 'package:traker_ia/domain/archivio_settimane.dart';
import 'package:traker_ia/domain/catena.dart';
import 'package:traker_ia/domain/collegamenti.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/app.dart';
import 'package:traker_ia/ui/servizi.dart';
import 'package:traker_ia/ui/stato_app.dart';

/// Canale verso la finestra Windows (windows/runner/flutter_window.cpp):
/// primo piano, tray, avvio con Windows.
const MethodChannel _canaleFinestra = MethodChannel('traker_ia/finestra');

/// Servizi veri: collegano lo strato data alla grafica.
class ServiziVeri implements Servizi {
  /// Crea i servizi. [minuti] = intervallo letture attuale.
  factory ServiziVeri({required int Function() minuti}) =>
      ServiziVeri._(minuti, DatabaseTraker.suDisco());

  ServiziVeri._(this.minuti, DatabaseTraker db)
    : _archivio = Archivio(db),
      _progetti = ArchivioProgetti(db),
      _cassaforte = CassaforteSistema() {
    _ricevitore = Ricevitore(minuti: () => minuti());
    _estensione = LettoreEstensione(
      _ricevitore,
      validita: () => Duration(minutes: 2 * minuti() + 1),
    );
    _claudeCode = LettoreClaudeCode(client: _client);
    _web = LettoreClaudeWeb(client: _client, cassaforte: _cassaforte);
  }

  /// Minuti tra due letture (dalle preferenze).
  int Function() minuti;

  final Archivio _archivio;
  final ArchivioProgetti _progetti;
  final Cassaforte _cassaforte;
  final ClientJson _client = const ClientJsonIo();
  late final Ricevitore _ricevitore;
  late final LettoreEstensione _estensione;
  late final LettoreClaudeCode _claudeCode;
  late final LettoreClaudeWeb _web;

  /// Avvia il ricevitore dell'estensione (falso se la porta è occupata).
  Future<bool> avviaRicevitore() => _ricevitore.avvia();

  @override
  Future<List<Lettura>> letture() => _archivio.letture();

  @override
  Future<List<Evento>> eventi() => _archivio.eventi();

  @override
  Future<void> aggiungiLettura(Lettura l) => _archivio.aggiungiLettura(l);

  @override
  Future<void> aggiungiEvento(Evento e) => _archivio.aggiungiEvento(e);

  @override
  Future<Map<String, String?>> impostazioni(List<String> chiavi) async =>
      <String, String?>{
        for (final String k in chiavi) k: await _archivio.impostazione(k),
      };

  @override
  Future<void> salvaImpostazioni(Map<String, String> valori) async {
    for (final MapEntry<String, String> e in valori.entries) {
      await _archivio.salvaImpostazione(e.key, e.value);
    }
  }

  @override
  Future<RisultatoCatena> leggi(String metodo) async {
    final List<LettoreUso> tutti = telefono
        ? <LettoreUso>[if (await _web.disponibile()) _web]
        : await lettoriAnthropic(
            estensione: _estensione,
            claudeCode: _claudeCode,
            web: _web,
          );
    return leggiCatena(scegliLettori(metodo, tutti));
  }

  @override
  Stream<void> get arriviEstensione => _ricevitore.messaggi;

  @override
  bool get claudeCodeTrovato => _claudeCode.disponibile;

  @override
  Future<bool> cookieSalvato() => _web.disponibile();

  @override
  Future<void> salvaCookie(String cookie) =>
      salvaCookieAnthropic(_cassaforte, cookie);

  @override
  String get cartellaImportPredefinita {
    if (!Platform.isWindows) {
      return '';
    }
    final String casa = Platform.environment['USERPROFILE'] ?? '';
    return '$casa\\Desktop\\applicazione traker claude\\python-test-alfa\\dati';
  }

  @override
  Future<EsitoImportUi> importaVecchi(String cartella) async {
    if (cartella.isEmpty) {
      return (file: 0, letture: 0, eventi: 0, scartate: 0);
    }
    final EsitoImport e = await importaCartellaPython(_archivio, cartella);
    return (
      file: e.fileTrovati,
      letture: e.lettureNuove,
      eventi: e.eventiNuovi,
      scartate: e.scartate,
    );
  }

  @override
  bool get primoPianoDisponibile => Platform.isWindows;

  @override
  Future<void> primoPiano({required bool acceso}) =>
      _finestra<void>('primoPiano', acceso);

  /// Solo exe vero (release): in debug il percorso sarebbe quello di prova.
  @override
  bool get avvioWindowsDisponibile => Platform.isWindows && kReleaseMode;

  @override
  Future<bool> avvioWindows() async =>
      await _finestra<bool>('avvioWindows') ?? false;

  @override
  Future<void> impostaAvvioWindows({required bool acceso}) =>
      _finestra<bool>('impostaAvvioWindows', acceso);

  @override
  Future<void> aggiornaTray(String testo) async {
    if (!Platform.isWindows) {
      return;
    }
    await _finestra<void>('tray', <String, String>{
      'testo': testo,
      'mostra': Testi.trayMostra,
      'nascondi': Testi.trayNascondi,
      'esci': Testi.trayEsci,
    });
  }

  final CollegamentiPc _collegamenti = CollegamentiPc(
    cartellaBase: getApplicationSupportDirectory,
    cartellaDocumenti: getApplicationDocumentsDirectory,
  );

  @override
  bool get collegamentiDisponibili => Platform.isWindows;

  @override
  Future<String> preparaEstensione() => _collegamenti.preparaEstensione();

  @override
  Future<void> mostraCartella(String percorso) =>
      _collegamenti.mostraInEsplora(percorso);

  @override
  Future<bool> apriPaginaEstensioni(String idBrowser) async {
    for (final BrowserEstensione b in browserEstensione) {
      if (b.id == idBrowser) {
        return _collegamenti.apriPaginaEstensioni(b);
      }
    }
    return false;
  }

  @override
  Future<bool> accediClaudeCode() => _collegamenti.accediClaudeCode();

  final Telefono _telefono = const Telefono();

  @override
  bool get telefono => Platform.isAndroid;

  /// Prepara la lettura in sottofondo (solo telefono).
  Future<void> preparaTelefono() async {
    if (telefono) {
      await _telefono.prepara();
    }
  }

  @override
  Future<String> cookieWeb(String sito) => _telefono.cookie(sito);

  @override
  Future<void> preparaWeb(int id) => _telefono.preparaWeb(id);

  @override
  Future<bool?> batteriaLibera() async =>
      telefono ? _telefono.batteriaLibera() : null;

  @override
  Future<void> apriInfoApp() => _telefono.apriInfoApp();

  @override
  Future<void> dimenticaCache() async => _archivio.dimenticaCache();

  @override
  Future<void> aggiornaSfondo({
    required int minuti,
    required bool acceso,
  }) async {
    if (telefono) {
      await _telefono.sfondo(minuti: minuti, acceso: acceso);
    }
  }

  @override
  Future<List<Progetto>> progetti() => _progetti.progetti();

  @override
  Future<Progetto> aggiungiProgetto(Progetto p) =>
      _progetti.aggiungiProgetto(p);

  @override
  Future<void> modificaProgetto(Progetto p) => _progetti.modificaProgetto(p);

  @override
  Future<List<SettimanaProgetto>> settimane() => _progetti.settimane();

  @override
  Future<void> salvaTokenManuali(int idRiga, int? token) =>
      _progetti.salvaTokenManuali(idRiga, token);

  @override
  Future<int> archiviaSettimaneChiuse({
    required List<Lettura> letture,
    required List<Evento> eventi,
    required DateTime adesso,
    Piano? piano,
  }) => _progetti.archiviaSettimaneChiuse(
    letture: letture,
    eventi: eventi,
    adesso: adesso,
    piano: piano,
  );

  /// Chiama la finestra Windows; errori = null (finestra non pronta, test).
  Future<T?> _finestra<T>(String metodo, [Object? argomenti]) async {
    try {
      return await _canaleFinestra.invokeMethod<T>(metodo, argomenti);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ServiziVeri servizi = ServiziVeri(minuti: () => 10);
  final StatoApp stato = StatoApp(servizi);
  servizi.minuti = () => stato.preferenze.minuti;
  if (servizi.telefono) {
    await servizi.preparaTelefono();
    WidgetsBinding.instance.addObserver(_Ritorno(stato));
  } else {
    unawaited(servizi.avviaRicevitore());
  }
  runApp(TrakerApp(stato: stato));
  await stato.avvia();
}

/// Telefono: tornando nell'app rilegge i dati (la lettura in sottofondo
/// può averne aggiunti) e legge se l'ultima è vecchia.
class _Ritorno with WidgetsBindingObserver {
  _Ritorno(this.stato);

  final StatoApp stato;

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      unawaited(stato.riprendi());
    }
  }
}
