// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato data: database locale (drift/SQLite) nella cartella dati dell'app,
// fuori dalla cartella del progetto. Niente segreti qui (stanno in
// cassaforte.dart). Il file database.g.dart lo genera build_runner.
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'copia_db.dart';

part 'database.g.dart';

/// Tabella delle letture (una riga = una lettura).
@DataClassName('RigaLettura')
@TableIndex(name: 'letture_ora', columns: <Symbol>{#ora})
class Letture extends Table {
  /// Id automatico (ordine di arrivo).
  IntColumn get id => integer().autoIncrement()();

  /// Ora 'aaaa-mm-gg hh:mm', ora locale (stesso formato dei CSV).
  TextColumn get ora => text()();

  /// % settimanale.
  RealColumn get sett => real().nullable()();

  /// % sessione 5 ore.
  RealColumn get sess => real().nullable()();

  /// Origine: auto | manuale | iniziale.
  TextColumn get fonte => text().withDefault(const Constant<String>('auto'))();

  /// Input tastiera/mouse nell'intervallo (null = non noto).
  BoolColumn get alPc => boolean().nullable()();

  /// Periodo di lavoro attivo.
  BoolColumn get lavoro => boolean().withDefault(const Constant<bool>(false))();

  /// Modelli accesi, separati da '|'.
  TextColumn get modelli => text().withDefault(const Constant<String>(''))();

  /// Skill accese, separate da '|'.
  TextColumn get skill => text().withDefault(const Constant<String>(''))();

  /// Gestore IA (es. 'anthropic').
  TextColumn get gestore => text()();
}

/// Tabella degli eventi (note, inizio/fine lavoro, reset).
@DataClassName('RigaEvento')
@TableIndex(name: 'eventi_ora', columns: <Symbol>{#ora})
class Eventi extends Table {
  /// Id automatico (ordine di arrivo).
  IntColumn get id => integer().autoIncrement()();

  /// Ora 'aaaa-mm-gg hh:mm', ora locale.
  TextColumn get ora => text()();

  /// Tipo: nota | inizio | fine | reset.
  TextColumn get tipo => text()();

  /// Testo libero.
  TextColumn get testo => text().withDefault(const Constant<String>(''))();
}

/// Impostazioni chiave -> valore (testo/JSON). MAI segreti.
@DataClassName('RigaImpostazione')
class Impostazioni extends Table {
  /// Nome dell'impostazione.
  TextColumn get chiave => text()();

  /// Valore (testo o JSON).
  TextColumn get valore => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{chiave};
}

/// Piani di lavoro (V2, schema 2). Vuota finché non la usa la V2.
@DataClassName('RigaPiano')
class Piani extends Table {
  /// Id automatico.
  IntColumn get id => integer().autoIncrement()();

  /// Nome del piano.
  TextColumn get nome => text()();

  /// Giorni di lavoro: bit 0 = lunedì ... bit 6 = domenica.
  IntColumn get giorniMask => integer()();

  /// % settimanale da raggiungere a fine piano.
  RealColumn get targetPct => real().withDefault(const Constant<double>(99))();

  /// Confine del giorno ('reset24h' = 24 h dal reset settimanale).
  TextColumn get confine =>
      text().withDefault(const Constant<String>('reset24h'))();

  /// Inizio validità 'aaaa-mm-gg hh:mm'.
  TextColumn get inizio => text()();

  /// Fine validità 'aaaa-mm-gg hh:mm' (null = ancora valido).
  TextColumn get fine => text().nullable()();
}

/// Progetti (V2, schema 2). Vuota finché non la usa la V2.
@DataClassName('RigaProgetto')
class Progetti extends Table {
  /// Id automatico.
  IntColumn get id => integer().autoIncrement()();

  /// Nome del progetto.
  TextColumn get nome => text()();

  /// Colore ARGB (0xAARRGGBB).
  IntColumn get colore => integer().withDefault(const Constant<int>(0))();

  /// Note libere.
  TextColumn get note => text().withDefault(const Constant<String>(''))();
}

/// Settimane di un progetto (V2, schema 2). Vuota finché non la usa la V2.
@DataClassName('RigaProgettoSettimana')
class ProgettoSettimane extends Table {
  /// Id automatico.
  IntColumn get id => integer().autoIncrement()();

  /// Id del progetto.
  IntColumn get progettoId => integer()();

  /// Inizio settimana 'aaaa-mm-gg hh:mm'.
  TextColumn get settInizio => text()();

  /// Fine settimana 'aaaa-mm-gg hh:mm' (null = in corso).
  TextColumn get settFine => text().nullable()();

  /// Istantanea dei numeri (JSON).
  TextColumn get snapshotJson =>
      text().withDefault(const Constant<String>('{}'))();

  /// Log testuale della settimana.
  TextColumn get logTesto => text().withDefault(const Constant<String>(''))();
}

/// Versione attuale dello schema del database.
const int versioneSchema = 2;

/// Nome del file del database (senza '.sqlite').
const String nomeDb = 'traker_ia';

/// Database dell'app.
@DriftDatabase(
  tables: <Type>[
    Letture,
    Eventi,
    Impostazioni,
    Piani,
    Progetti,
    ProgettoSettimane,
  ],
)
class DatabaseTraker extends _$DatabaseTraker {
  /// Database su un esecutore qualsiasi (nei test: in memoria).
  DatabaseTraker(super.esecutore);

  /// Database nel file 'traker_ia.sqlite' della cartella dati dell'app
  /// (Windows: %APPDATA%\mdls\...). Mai nella cartella del progetto.
  /// Prima di aggiornare lo schema copia il file in '<db>.bak-v<N>'.
  factory DatabaseTraker.suDisco() => DatabaseTraker(
    driftDatabase(
      name: nomeDb,
      native: const DriftNativeOptions(
        databasePath: _percorsoConCopia,
        // Telefono: la lettura in sottofondo usa lo stesso database.
        shareAcrossIsolates: true,
      ),
    ),
  );

  @override
  int get schemaVersion => versioneSchema;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int da, int a) async {
      // 1 -> 2: SOLO tabelle nuove vuote. Letture/Eventi/Impostazioni
      // non si toccano.
      if (da < 2) {
        await m.createTable(piani);
        await m.createTable(progetti);
        await m.createTable(progettoSettimane);
      }
    },
  );
}

Future<String> _percorsoConCopia() async {
  final Directory d = await getApplicationSupportDirectory();
  final File f = File('${d.path}${Platform.pathSeparator}$nomeDb.sqlite');
  await copiaPrimaDiMigrare(f, versioneSchema);
  return f.path;
}
