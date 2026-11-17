// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato data (V2, B12): progetti e settimane archiviate sul database.
// Solo aggiunte: le settimane archiviate non si riscrivono (solo il campo
// token scritto a mano). Letture/Eventi qui si leggono soltanto.
import 'package:drift/drift.dart';

import 'package:traker_ia/data/database.dart';
import 'package:traker_ia/domain/archivio_settimane.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/progetti.dart';
import 'package:traker_ia/domain/tempo.dart';

/// Archivio dei progetti.
class ArchivioProgetti {
  /// Crea l'archivio sul [_db].
  ArchivioProgetti(this._db);

  final DatabaseTraker _db;

  /// Tutti i progetti, per id.
  Future<List<Progetto>> progetti() async {
    final List<RigaProgetto> righe =
        await (_db.select(_db.progetti)
              ..orderBy(<OrderClauseGenerator<$ProgettiTable>>[
                ($ProgettiTable t) => OrderingTerm.asc(t.id),
              ]))
            .get();
    return List<Progetto>.unmodifiable(<Progetto>[
      for (final RigaProgetto r in righe)
        Progetto(id: r.id, nome: r.nome, colore: r.colore, note: r.note),
    ]);
  }

  /// Aggiunge un progetto; ritorna il progetto con id.
  /// Nome vuoto o già usato (maiuscole/spazi ignorati) -> ArgumentError.
  Future<Progetto> aggiungiProgetto(Progetto p) async {
    await _controllaNome(p.nome, null);
    final int id = await _db
        .into(_db.progetti)
        .insert(
          ProgettiCompanion.insert(
            nome: p.nome.trim(),
            colore: Value<int>(p.colore),
            note: Value<String>(p.note),
          ),
        );
    return Progetto(
      id: id,
      nome: p.nome.trim(),
      colore: p.colore,
      note: p.note,
    );
  }

  /// Cambia nome/colore/note del progetto [p] (id obbligatorio).
  /// ATTENZIONE: le note-comando vecchie usano il nome vecchio.
  Future<void> modificaProgetto(Progetto p) async {
    final int? id = p.id;
    if (id == null) {
      throw ArgumentError.value(p, 'p', 'progetto senza id');
    }
    await _controllaNome(p.nome, id);
    await (_db.update(
      _db.progetti,
    )..where(($ProgettiTable t) => t.id.equals(id))).write(
      ProgettiCompanion(
        nome: Value<String>(p.nome.trim()),
        colore: Value<int>(p.colore),
        note: Value<String>(p.note),
      ),
    );
  }

  Future<void> _controllaNome(String nome, int? escluso) async {
    final String n = normalizzaNome(nome);
    if (n.isEmpty) {
      throw ArgumentError.value(nome, 'nome', 'nome vuoto');
    }
    for (final Progetto p in await progetti()) {
      if (p.id != escluso && normalizzaNome(p.nome) == n) {
        throw ArgumentError.value(nome, 'nome', 'nome già usato');
      }
    }
  }

  /// Settimane archiviate (tutte o del progetto [progettoId]), per inizio.
  Future<List<SettimanaProgetto>> settimane({int? progettoId}) async {
    final SimpleSelectStatement<$ProgettoSettimaneTable, RigaProgettoSettimana>
    q = _db.select(_db.progettoSettimane)
      ..orderBy(<OrderClauseGenerator<$ProgettoSettimaneTable>>[
        ($ProgettoSettimaneTable t) => OrderingTerm.asc(t.settInizio),
        ($ProgettoSettimaneTable t) => OrderingTerm.asc(t.progettoId),
      ]);
    if (progettoId != null) {
      q.where(($ProgettoSettimaneTable t) => t.progettoId.equals(progettoId));
    }
    final List<SettimanaProgetto> out = <SettimanaProgetto>[];
    for (final RigaProgettoSettimana r in await q.get()) {
      final DateTime? ini = interpreta(r.settInizio);
      if (ini == null) {
        continue;
      }
      out.add(
        SettimanaProgetto(
          id: r.id,
          progettoId: r.progettoId,
          inizio: ini,
          fine: r.settFine == null ? null : interpreta(r.settFine!),
          istantanea: r.snapshotJson,
          log: r.logTesto,
          tokenManuali: r.tokenManuali,
        ),
      );
    }
    return out;
  }

  /// Token scritti a mano per la riga [idRiga] (null = cancella).
  /// Negativi -> ArgumentError.
  Future<void> salvaTokenManuali(int idRiga, int? token) async {
    if (token != null && token < 0) {
      throw ArgumentError.value(token, 'token', 'negativo');
    }
    await (_db.update(_db.progettoSettimane)
          ..where(($ProgettoSettimaneTable t) => t.id.equals(idRiga)))
        .write(ProgettoSettimaneCompanion(tokenManuali: Value<int?>(token)));
  }

  /// Archivia le settimane CHIUSE (reset passato) non ancora archiviate.
  /// Settimane già presenti non si toccano. Ritorna le righe aggiunte.
  /// Da chiamare all'avvio e dopo ogni lettura (costa poco se non c'è
  /// nulla da fare).
  Future<int> archiviaSettimaneChiuse({
    required List<Lettura> letture,
    required List<Evento> eventi,
    required DateTime adesso,
    Piano? piano,
    int giorno = DateTime.tuesday,
    int h = 20,
    int m = 0,
  }) async {
    // Solo la colonna dell'inizio: le istantanee (~50 KB a riga) non si
    // caricano a ogni controllo.
    final GeneratedColumn<String> colInizio = _db.progettoSettimane.settInizio;
    final List<TypedResult> gia = await (_db.selectOnly(
      _db.progettoSettimane,
    )..addColumns(<Expression<Object>>[colInizio])).get();
    final Set<DateTime> inizi = <DateTime>{
      for (final TypedResult r in gia) ?interpreta(r.read(colInizio) ?? ''),
    };
    final List<({DateTime inizio, DateTime fine})> da = settimaneDaArchiviare(
      letture,
      adesso,
      gia: inizi,
      giorno: giorno,
      h: h,
      m: m,
    );
    if (da.isEmpty) {
      return 0;
    }
    final List<Progetto> ps = await progetti();
    int n = 0;
    await _db.transaction(() async {
      for (final ({DateTime inizio, DateTime fine}) s in da) {
        for (final SettimanaProgetto r in archiviaSettimana(
          letture: letture,
          eventi: eventi,
          progetti: ps,
          inizio: s.inizio,
          fine: s.fine,
          piano: piano,
        )) {
          await _db
              .into(_db.progettoSettimane)
              .insert(
                ProgettoSettimaneCompanion.insert(
                  progettoId: r.progettoId,
                  settInizio: formatta(r.inizio),
                  settFine: Value<String?>(
                    r.fine == null ? null : formatta(r.fine!),
                  ),
                  snapshotJson: Value<String>(r.istantanea),
                  logTesto: Value<String>(r.log),
                ),
                mode: InsertMode.insertOrIgnore,
              );
          n++;
        }
      }
    });
    return n;
  }
}
