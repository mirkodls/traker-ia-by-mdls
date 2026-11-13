// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato data: import dei file letture.csv / eventi.csv dell'app Python
// (cartella python-test-alfa\dati) nel database, senza doppioni.
import 'dart:io';

import 'package:traker_ia/data/archivio.dart';
import 'package:traker_ia/domain/import_csv.dart';
import 'package:traker_ia/domain/modelli.dart';

/// Esito di un import.
class EsitoImport {
  /// Crea l'esito.
  const EsitoImport({
    required this.fileTrovati,
    required this.lettureNuove,
    required this.eventiNuovi,
    required this.scartate,
  });

  /// Quanti file trovati (0-2).
  final int fileTrovati;

  /// Letture aggiunte (non doppioni).
  final int lettureNuove;

  /// Eventi aggiunti (non doppioni).
  final int eventiNuovi;

  /// Righe rotte saltate.
  final int scartate;
}

Future<String?> _testo(String percorso) async {
  final File f = File(percorso);
  if (!f.existsSync()) {
    return null;
  }
  try {
    return await f.readAsString();
  } on FileSystemException {
    return null;
  }
}

/// Importa letture.csv ed eventi.csv dalla [cartella] nell'[archivio].
/// Si può rifare: i doppioni vengono saltati.
Future<EsitoImport> importaCartellaPython(
  Archivio archivio,
  String cartella, {
  String gestore = gestoreAnthropic,
}) async {
  final String s = Platform.pathSeparator;
  final String? tl = await _testo('$cartella${s}letture.csv');
  final String? te = await _testo('$cartella${s}eventi.csv');
  int nuoveL = 0;
  int nuoviE = 0;
  int scartate = 0;
  if (tl != null) {
    final RisultatoImport<Lettura> r = importaLetture(tl, gestore: gestore);
    scartate += r.scartate;
    nuoveL = await archivio.aggiungiLettureSenzaDoppioni(r.voci);
  }
  if (te != null) {
    final RisultatoImport<Evento> r = importaEventi(te);
    scartate += r.scartate;
    nuoviE = await archivio.aggiungiEventiSenzaDoppioni(r.voci);
  }
  return EsitoImport(
    fileTrovati: (tl == null ? 0 : 1) + (te == null ? 0 : 1),
    lettureNuove: nuoveL,
    eventiNuovi: nuoviE,
    scartate: scartate,
  );
}
