// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Radice: UNICO posto che collega data e ui. Qui si creano archivio,
// cassaforte, ricevitore e lettori, e si passano alla grafica come Servizi.
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/data/archivio.dart';
import 'package:traker_ia/data/cassaforte.dart';
import 'package:traker_ia/data/database.dart';
import 'package:traker_ia/data/import_file.dart';
import 'package:traker_ia/data/lettori_anthropic.dart';
import 'package:traker_ia/data/rete.dart';
import 'package:traker_ia/data/ricevitore.dart';
import 'package:traker_ia/domain/catena.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/ui/app.dart';
import 'package:traker_ia/ui/servizi.dart';
import 'package:traker_ia/ui/stato_app.dart';

/// Canale verso la finestra Windows (windows/runner/flutter_window.cpp).
const MethodChannel _canaleFinestra = MethodChannel('traker_ia/finestra');

/// Servizi veri: collegano lo strato data alla grafica.
class ServiziVeri implements Servizi {
  /// Crea i servizi. [minuti] = intervallo letture attuale.
  ServiziVeri({required this.minuti})
    : _archivio = Archivio(DatabaseTraker.suDisco()),
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
    final List<LettoreUso> tutti = await lettoriAnthropic(
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
  Future<void> primoPiano({required bool acceso}) async {
    try {
      await _canaleFinestra.invokeMethod<void>('primoPiano', acceso);
    } on PlatformException {
      // finestra non pronta: niente
    } on MissingPluginException {
      // canale assente (es. test): niente
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ServiziVeri servizi = ServiziVeri(minuti: () => 10);
  final StatoApp stato = StatoApp(servizi);
  servizi.minuti = () => stato.preferenze.minuti;
  unawaited(servizi.avviaRicevitore());
  runApp(TrakerApp(stato: stato));
  await stato.avvia();
}
