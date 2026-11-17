// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// B07: migrazione database 1 -> 2 senza perdere righe + copia .bak-v1.
import 'dart:io';

import 'package:drift/backends.dart';
import 'package:drift/drift.dart'
    show OpeningDetails, QueryRow, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/data/copia_db.dart';
import 'package:traker_ia/data/database.dart';

/// Schema 1 vero (copiato da sqlite_master del database v1).
const List<String> _schemaV1 = <String>[
  'CREATE TABLE "letture" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"ora" TEXT NOT NULL, "sett" REAL NULL, "sess" REAL NULL, '
      '"fonte" TEXT NOT NULL DEFAULT \'auto\', '
      '"al_pc" INTEGER NULL CHECK ("al_pc" IN (0, 1)), '
      '"lavoro" INTEGER NOT NULL DEFAULT 0 CHECK ("lavoro" IN (0, 1)), '
      '"modelli" TEXT NOT NULL DEFAULT \'\', '
      '"skill" TEXT NOT NULL DEFAULT \'\', "gestore" TEXT NOT NULL)',
  'CREATE TABLE "eventi" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"ora" TEXT NOT NULL, "tipo" TEXT NOT NULL, '
      '"testo" TEXT NOT NULL DEFAULT \'\')',
  'CREATE TABLE "impostazioni" ("chiave" TEXT NOT NULL, '
      '"valore" TEXT NOT NULL, PRIMARY KEY ("chiave"))',
  'CREATE INDEX letture_ora ON letture (ora)',
  'CREATE INDEX eventi_ora ON eventi (ora)',
];

class _UtenteV1 extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(QueryExecutor e, OpeningDetails d) async {
    await e.ensureOpen(this);
    if (d.wasCreated) {
      for (final String s in _schemaV1) {
        await e.runCustom(s);
      }
    }
  }
}

const List<String> _tabelleVecchie = <String>[
  'letture',
  'eventi',
  'impostazioni',
];

Future<Map<String, List<Map<String, Object?>>>> _tutto(QueryExecutor e) async =>
    <String, List<Map<String, Object?>>>{
      for (final String t in _tabelleVecchie)
        t: await e.runSelect(
          'SELECT * FROM $t ORDER BY ${t == 'impostazioni' ? 'chiave' : 'id'}',
          const <Object?>[],
        ),
    };

/// Crea un database v1 popolato in [f]; ritorna le righe scritte.
Future<Map<String, List<Map<String, Object?>>>> _creaV1(File f) async {
  final NativeDatabase e = NativeDatabase(f);
  await e.ensureOpen(_UtenteV1());
  for (int i = 0; i < 300; i++) {
    final String ora =
        '2026-11-${(10 + i ~/ 100).toString().padLeft(2, '0')} '
        '${(i % 24).toString().padLeft(2, '0')}:${(i % 60).toString().padLeft(2, '0')}';
    await e.runInsert(
      'INSERT INTO letture (ora, sett, sess, fonte, al_pc, lavoro, modelli, '
      'skill, gestore) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        ora,
        i.isEven ? 21.0 + i % 50 : null,
        i % 3 == 0 ? null : 9.5,
        i % 5 == 0 ? 'manuale' : 'auto',
        i % 4 == 0 ? null : i % 2,
        i % 2,
        i % 7 == 0 ? 'Opus|Fable' : '',
        i % 11 == 0 ? 'caveman' : '',
        'anthropic',
      ],
    );
  }
  for (final List<String> ev in <List<String>>[
    <String>['2026-11-11 17:30', 'nota', 'modifiche risparmio token'],
    <String>['2026-11-12 08:00', 'inizio', ''],
    <String>['2026-11-12 12:00', 'fine', ''],
    <String>['2026-11-10 20:00', 'reset', 'ok; con ; e \' apice'],
  ]) {
    await e.runInsert(
      'INSERT INTO eventi (ora, tipo, testo) VALUES (?, ?, ?)',
      ev,
    );
  }
  for (final List<String> kv in <List<String>>[
    <String>['minuti', '6'],
    <String>['modelli', '["Opus","Sonnet"]'],
    <String>['modelli_attivi', '["Opus"]'],
    <String>['vista', '{"a":1}'],
  ]) {
    await e.runInsert(
      'INSERT INTO impostazioni (chiave, valore) VALUES (?, ?)',
      kv,
    );
  }
  final Map<String, List<Map<String, Object?>>> righe = await _tutto(e);
  await e.close();
  return righe;
}

void main() {
  late Directory dir;
  late File f;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    dir = Directory.systemTemp.createTempSync('traker_mig_');
    f = File('${dir.path}${Platform.pathSeparator}traker_ia.sqlite');
  });

  tearDown(() {
    dir.deleteSync(recursive: true);
  });

  test('versione file: assente / non SQLite -> null; v1 -> 1', () async {
    expect(await versioneFileDb(f), isNull);
    f.writeAsStringSync(
      'non sono un database, solo testo lungo abbastanza '
      'da superare i sessantaquattro byte di intestazione.',
    );
    expect(await versioneFileDb(f), isNull);
    expect(await copiaPrimaDiMigrare(f, versioneSchema), isNull);
    f.deleteSync();
    await _creaV1(f);
    expect(await versioneFileDb(f), 1);
  });

  test(
    '1 -> 2: copia .bak-v1, nessuna riga persa, tabelle nuove vuote',
    () async {
      final Map<String, List<Map<String, Object?>>> prima = await _creaV1(f);
      expect(prima['letture']!.length, 300);
      expect(prima['eventi']!.length, 4);
      expect(prima['impostazioni']!.length, 4);

      final File? bak = await copiaPrimaDiMigrare(f, versioneSchema);
      expect(bak, isNotNull);
      expect(bak!.path, '${f.path}.bak-v1');
      expect(await versioneFileDb(bak), 1);
      // Seconda volta: la copia esiste già, non si riscrive.
      expect(await copiaPrimaDiMigrare(f, versioneSchema), isNull);

      final DatabaseTraker db = DatabaseTraker(NativeDatabase(f));
      final List<Map<String, Object?>> nuove =
          (await db
                  .customSelect(
                    "SELECT name FROM sqlite_master WHERE type='table' "
                    "AND name IN ('piani','progetti','progetto_settimane')",
                  )
                  .get())
              .map((QueryRow r) => r.data)
              .toList();
      expect(nuove.length, 3);
      expect(await db.select(db.piani).get(), isEmpty);
      expect(await db.select(db.progetti).get(), isEmpty);
      expect(await db.select(db.progettoSettimane).get(), isEmpty);
      final Map<String, List<Map<String, Object?>>> dopo = await _tutto(
        db.executor,
      );
      await db.close();

      for (final String t in _tabelleVecchie) {
        expect(dopo[t], prima[t], reason: t);
      }
      expect(await versioneFileDb(f), versioneSchema);
      // Già alla 2: nessuna nuova copia.
      expect(await copiaPrimaDiMigrare(f, versioneSchema), isNull);

      // La copia è il database vecchio intero.
      final NativeDatabase vecchio = NativeDatabase(bak);
      await vecchio.ensureOpen(_UtenteV1());
      expect(await _tutto(vecchio), prima);
      await vecchio.close();
    },
  );

  test('database nuovo: crea tutte le tabelle alla versione 2', () async {
    final DatabaseTraker db = DatabaseTraker(NativeDatabase(f));
    expect(await db.select(db.piani).get(), isEmpty);
    await db
        .into(db.piani)
        .insert(
          PianiCompanion.insert(
            nome: 'Lavoro',
            giorniMask: 0x1D,
            inizio: '2026-11-17 20:00',
          ),
        );
    final RigaPiano p = (await db.select(db.piani).get()).single;
    expect(p.targetPct, 99);
    expect(p.confine, 'reset24h');
    expect(p.fine, isNull);
    await db.close();
    expect(await versioneFileDb(f), versioneSchema);
  });
}
