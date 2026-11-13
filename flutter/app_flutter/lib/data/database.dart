// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato data: database locale (drift/SQLite) nella cartella dati dell'app,
// fuori dalla cartella del progetto. Niente segreti qui (stanno in
// cassaforte.dart). Il file database.g.dart lo genera build_runner.
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

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
  BoolColumn get lavoro =>
      boolean().withDefault(const Constant<bool>(false))();

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

/// Database dell'app.
@DriftDatabase(tables: <Type>[Letture, Eventi, Impostazioni])
class DatabaseTraker extends _$DatabaseTraker {
  /// Database su un esecutore qualsiasi (nei test: in memoria).
  DatabaseTraker(super.esecutore);

  /// Database nel file 'traker_ia.sqlite' della cartella dati dell'app
  /// (Windows: %APPDATA%\mdls\...). Mai nella cartella del progetto.
  factory DatabaseTraker.suDisco() => DatabaseTraker(
    driftDatabase(
      name: 'traker_ia',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    ),
  );

  @override
  int get schemaVersion => 1;
}
