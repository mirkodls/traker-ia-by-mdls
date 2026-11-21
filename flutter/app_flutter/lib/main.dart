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
import 'package:traker_ia/data/cliente_ia.dart';
import 'package:traker_ia/data/collegamenti_pc.dart';
import 'package:traker_ia/data/database.dart';
import 'package:traker_ia/data/import_file.dart';
import 'package:traker_ia/data/lettori_anthropic.dart';
import 'package:traker_ia/data/rete.dart';
import 'package:traker_ia/data/ricevitore.dart';
import 'package:traker_ia/data/sfondo_telefono.dart';
import 'package:traker_ia/data/sync_rete.dart';
import 'package:traker_ia/domain/archivio_settimane.dart';
import 'package:traker_ia/domain/catena.dart';
import 'package:traker_ia/domain/collegamenti.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/resoconto_ia.dart';
import 'package:traker_ia/domain/sfondo.dart';
import 'package:traker_ia/domain/sync_dati.dart';
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
    _ia = ClienteIA(cassaforte: _cassaforte);
    _dati = DatiSync(_archivio, _progetti);
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
  late final ClienteIA _ia;
  late final DatiSync _dati;
  ServerSync? _server;

  ServerSync get _serverPc => _server ??= ServerSync(
    dati: _dati,
    cassaforte: _cassaforte,
    nome: Platform.localHostname,
  );

  late final ClientSync _syncTel = ClientSync(
    dati: _dati,
    cassaforte: _cassaforte,
  );

  /// B22 PC: ascolta i telefoni solo se ce n'è almeno uno abbinato.
  Future<void> avviaSync() async {
    if (!telefono && (await leggiCoppie(_cassaforte)).isNotEmpty) {
      await _serverPc.avvia();
    }
  }

  @override
  Future<bool> apriAbbinamento({
    required void Function(String codice) codice,
    required void Function(String nome) fatto,
  }) => _serverPc.apriAbbinamento(mostraCodice: codice, abbinato: fatto);

  @override
  void chiudiAbbinamento() => _server?.chiudiAbbinamento();

  @override
  Future<List<String>> abbinati() async => <String>[
    for (final Coppia c in await leggiCoppie(_cassaforte)) c.nome,
  ];

  @override
  Future<void> dimenticaAbbinati() async {
    await _cassaforte.cancella(chiaveCoppieSync);
    await _server?.ferma();
  }

  @override
  Future<EsitoSync> abbinaAlPc(Future<String?> Function() chiediCodice) =>
      _syncTel.abbina(chiediCodice);

  @override
  Future<EsitoSync> sincronizza({bool tutto = false}) =>
      _syncTel.sincronizza(tutto: tutto);

  @override
  Stream<int> get arriviSync =>
      telefono ? const Stream<int>.empty() : _serverPc.sincronizzati;

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
  String get cartellaEsportaPredefinita {
    if (telefono) {
      return cartellaEsportaTelefono;
    }
    final String casa =
        Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        '';
    return casa.isEmpty
        ? ''
        : '$casa${Platform.pathSeparator}Documents${Platform.pathSeparator}'
              'TraKer IA export';
  }

  @override
  Future<String> salvaTestoInCartella({
    required String cartella,
    required String nome,
    required String testo,
  }) async {
    if (telefono) {
      return _telefono.salvaDocumento(nome, testo);
    }
    final Directory d = Directory(cartella);
    await d.create(recursive: true);
    final File f = File('${d.path}${Platform.pathSeparator}$nome');
    await f.writeAsString(testo, flush: true);
    return f.path;
  }

  @override
  Future<String?> fineChiaveIA(FornitoreIA f) => _ia.fineChiaveSalvata(f);

  @override
  Future<void> salvaChiaveIA(FornitoreIA f, String chiave) =>
      _ia.salvaChiave(f, chiave);

  @override
  Future<String> chiediIA(ConfigIA c, String testo) => _ia.chiedi(c, testo);

  @override
  Future<String> provaIA(ConfigIA c) => _ia.prova(c);

  @override
  Future<List<FileResoconto>> resocontiSalvati(
    String cartella, {
    DateTime? inizio,
  }) => elencaResoconti(cartella, inizio: inizio);

  @override
  Future<String> leggiTestoFile(String percorso) =>
      File(percorso).readAsString();

  @override
  Future<void> apriFile(String percorso) => _collegamenti.apriFile(percorso);

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
  Future<void> apriPermesso(String voce) => _telefono.apriPermesso(voce);

  @override
  Future<bool> condividiTesto(String testo, {required String titolo}) async =>
      telefono && await _telefono.condividi(testo, titolo);

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
    unawaited(servizi.avviaSync());
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
