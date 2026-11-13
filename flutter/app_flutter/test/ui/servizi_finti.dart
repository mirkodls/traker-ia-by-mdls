// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Servizi finti in memoria per i test della ui.
import 'dart:async';

import 'package:traker_ia/domain/catena.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/ui/servizi.dart';

/// Servizi finti: tutto in memoria.
class ServiziFinti implements Servizi {
  /// Letture salvate.
  final List<Lettura> lett = <Lettura>[];

  /// Eventi salvati.
  final List<Evento> ev = <Evento>[];

  /// Impostazioni salvate.
  final Map<String, String> imp = <String, String>{};

  /// Risposte di leggi(): Uso o ErroreLettura, in ordine (l'ultima si ripete).
  final List<Object> risposte = <Object>[];

  /// Metodi chiesti a leggi().
  final List<String> metodi = <String>[];

  /// Letture da dare all'import.
  List<Lettura> daImportare = <Lettura>[];

  /// Cartelle chieste all'import.
  final List<String> importate = <String>[];

  /// Cookie salvato.
  String cookie = '';

  /// Chiamate primo piano.
  final List<bool> primoPianoChiamate = <bool>[];

  // ignore: close_sinks
  final StreamController<void> _est = StreamController<void>.broadcast();

  @override
  Future<List<Lettura>> letture() async => ordinaLetture(lett);

  @override
  Future<List<Evento>> eventi() async => ordinaEventi(ev);

  @override
  Future<void> aggiungiLettura(Lettura l) async => lett.add(l);

  @override
  Future<void> aggiungiEvento(Evento e) async => ev.add(e);

  @override
  Future<Map<String, String?>> impostazioni(List<String> chiavi) async =>
      <String, String?>{for (final String k in chiavi) k: imp[k]};

  @override
  Future<void> salvaImpostazioni(Map<String, String> valori) async =>
      imp.addAll(valori);

  @override
  Future<RisultatoCatena> leggi(String metodo) async {
    metodi.add(metodo);
    final Object r = risposte.length > 1
        ? risposte.removeAt(0)
        : risposte.first;
    if (r is ErroreLettura) {
      throw r;
    }
    return RisultatoCatena(r as Uso, 'estensione');
  }

  @override
  Stream<void> get arriviEstensione => _est.stream;

  @override
  bool get claudeCodeTrovato => false;

  @override
  Future<bool> cookieSalvato() async => cookie.isNotEmpty;

  @override
  Future<void> salvaCookie(String c) async => cookie = c.trim();

  @override
  String get cartellaImportPredefinita => 'vecchi';

  @override
  Future<EsitoImportUi> importaVecchi(String cartella) async {
    importate.add(cartella);
    lett.addAll(daImportare);
    return (
      file: daImportare.isEmpty ? 0 : 1,
      letture: daImportare.length,
      eventi: 0,
      scartate: 0,
    );
  }

  @override
  bool get primoPianoDisponibile => true;

  @override
  Future<void> primoPiano({required bool acceso}) async =>
      primoPianoChiamate.add(acceso);

  /// Avvio con Windows disponibile.
  bool avvioDisponibile = true;

  /// Stato avvio con Windows.
  bool avvio = false;

  /// Chiamate a impostaAvvioWindows.
  final List<bool> avvioChiamate = <bool>[];

  /// Testi mandati al tray.
  final List<String> tray = <String>[];

  @override
  bool get avvioWindowsDisponibile => avvioDisponibile;

  @override
  Future<bool> avvioWindows() async => avvio;

  @override
  Future<void> impostaAvvioWindows({required bool acceso}) async {
    avvioChiamate.add(acceso);
    avvio = acceso;
  }

  @override
  Future<void> aggiornaTray(String testo) async => tray.add(testo);
}
