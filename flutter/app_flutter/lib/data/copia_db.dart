// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato data: copia di sicurezza del file database PRIMA di aggiornare lo
// schema (perdita dati = 0%). Legge la versione direttamente dal file
// SQLite, senza aprirlo.
import 'dart:io';
import 'dart:typed_data';

/// Byte 60-63 dell'intestazione SQLite: "user_version" (versione schema).
const int _posVersione = 60;

/// Versione dello schema scritta nel file SQLite [f].
/// null = file assente, troppo corto o non SQLite.
Future<int?> versioneFileDb(File f) async {
  if (!f.existsSync()) {
    return null;
  }
  final RandomAccessFile r = await f.open();
  try {
    final Uint8List b = await r.read(_posVersione + 4);
    if (b.length < _posVersione + 4 ||
        String.fromCharCodes(b.sublist(0, 15)) != 'SQLite format 3') {
      return null;
    }
    return ByteData.sublistView(b).getUint32(_posVersione);
  } finally {
    await r.close();
  }
}

/// Se [f] ha versione tra 1 e [nuova]-1, copia il file in
/// `<f>.bak-v<versione>` (e '-wal' se c'è). Copia già presente = non
/// la riscrive. Ritorna la copia fatta, oppure null.
Future<File?> copiaPrimaDiMigrare(File f, int nuova) async {
  final int? v = await versioneFileDb(f);
  if (v == null || v < 1 || v >= nuova) {
    return null;
  }
  final File bak = File('${f.path}.bak-v$v');
  if (bak.existsSync()) {
    return null;
  }
  final File wal = File('${f.path}-wal');
  if (wal.existsSync()) {
    await _copiaSicura(wal, File('${bak.path}-wal'));
  }
  await _copiaSicura(f, bak);
  return bak;
}

/// Copia in un file temporaneo e poi rinomina: mai una copia a metà.
Future<void> _copiaSicura(File da, File a) async {
  final File tmp = File('${a.path}.tmp');
  await da.copy(tmp.path);
  await tmp.rename(a.path);
}
