// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato data: archivio = letture, eventi e impostazioni sul database.
// Leggerezza: letture/eventi letti 1 volta e tenuti in memoria; la copia in
// memoria si butta solo quando si scrive.
import 'package:drift/drift.dart';

import 'package:traker_ia/data/database.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/unione.dart';

/// Parole vietate nei nomi delle impostazioni (i segreti vanno in Cassaforte).
const List<String> _paroleSegrete = <String>[
  'cookie',
  'token',
  'segret',
  'password',
];

/// Archivio locale dei dati.
class Archivio {
  /// Crea l'archivio sul [_db].
  Archivio(this._db);

  final DatabaseTraker _db;
  List<Lettura>? _letture;
  List<Evento>? _eventi;

  /// Tutte le letture, ordinate per ora (lista non modificabile).
  Future<List<Lettura>> letture() async {
    final List<Lettura>? c = _letture;
    if (c != null) {
      return c;
    }
    final List<RigaLettura> righe = await (_db.select(_db.letture)
          ..orderBy(<OrderClauseGenerator<$LettureTable>>[
            ($LettureTable t) => OrderingTerm.asc(t.ora),
            ($LettureTable t) => OrderingTerm.asc(t.id),
          ]))
        .get();
    final List<Lettura> out = List<Lettura>.unmodifiable(
      righe.map(_daRigaLettura).whereType<Lettura>(),
    );
    _letture = out;
    return out;
  }

  /// Tutti gli eventi, ordinati per ora (lista non modificabile).
  Future<List<Evento>> eventi() async {
    final List<Evento>? c = _eventi;
    if (c != null) {
      return c;
    }
    final List<RigaEvento> righe = await (_db.select(_db.eventi)
          ..orderBy(<OrderClauseGenerator<$EventiTable>>[
            ($EventiTable t) => OrderingTerm.asc(t.ora),
            ($EventiTable t) => OrderingTerm.asc(t.id),
          ]))
        .get();
    final List<Evento> out = List<Evento>.unmodifiable(
      righe.map(_daRigaEvento).whereType<Evento>(),
    );
    _eventi = out;
    return out;
  }

  /// Butta la copia in memoria: il database può essere cambiato da fuori
  /// (lettura in sottofondo sul telefono).
  void dimenticaCache() {
    _letture = null;
    _eventi = null;
  }

  /// Salva una lettura.
  Future<void> aggiungiLettura(Lettura l) async {
    await _db.into(_db.letture).insert(_rigaLettura(l));
    _letture = null;
  }

  /// Salva un evento.
  Future<void> aggiungiEvento(Evento e) async {
    await _db.into(_db.eventi).insert(_rigaEvento(e));
    _eventi = null;
  }

  /// Aggiunge le letture [arrivate] (import o sync) saltando i doppioni.
  /// Ritorna quante sono state aggiunte.
  Future<int> aggiungiLettureSenzaDoppioni(Iterable<Lettura> arrivate) async {
    final RisultatoUnione<Lettura> r = unisciLetture(
      await letture(),
      arrivate,
    );
    if (r.aggiunte == 0) {
      return 0;
    }
    await _db.transaction(() async {
      await _db.delete(_db.letture).go();
      await _db.batch((Batch b) {
        b.insertAll(_db.letture, r.voci.map(_rigaLettura).toList());
      });
    });
    _letture = null;
    return r.aggiunte;
  }

  /// Aggiunge gli eventi [arrivati] (import o sync) saltando i doppioni.
  /// Ritorna quanti sono stati aggiunti.
  Future<int> aggiungiEventiSenzaDoppioni(Iterable<Evento> arrivati) async {
    final RisultatoUnione<Evento> r = unisciEventi(await eventi(), arrivati);
    if (r.aggiunte == 0) {
      return 0;
    }
    await _db.transaction(() async {
      await _db.delete(_db.eventi).go();
      await _db.batch((Batch b) {
        b.insertAll(_db.eventi, r.voci.map(_rigaEvento).toList());
      });
    });
    _eventi = null;
    return r.aggiunte;
  }

  /// Valore dell'impostazione [chiave], null se non c'è.
  Future<String?> impostazione(String chiave) async {
    _controllaChiave(chiave);
    final RigaImpostazione? r = await (_db.select(_db.impostazioni)
          ..where(($ImpostazioniTable t) => t.chiave.equals(chiave)))
        .getSingleOrNull();
    return r?.valore;
  }

  /// Salva l'impostazione [chiave] (sovrascrive). Mai segreti.
  Future<void> salvaImpostazione(String chiave, String valore) async {
    _controllaChiave(chiave);
    await _db
        .into(_db.impostazioni)
        .insertOnConflictUpdate(
          ImpostazioniCompanion.insert(chiave: chiave, valore: valore),
        );
  }

  /// Chiude il database.
  Future<void> chiudi() => _db.close();
}

void _controllaChiave(String chiave) {
  final String c = chiave.toLowerCase();
  for (final String p in _paroleSegrete) {
    if (c.contains(p)) {
      throw ArgumentError.value(
        chiave,
        'chiave',
        'i segreti vanno nella cassaforte, non nelle impostazioni',
      );
    }
  }
}

LettureCompanion _rigaLettura(Lettura l) => LettureCompanion.insert(
  ora: formatta(l.ora),
  sett: Value<double?>(l.sett),
  sess: Value<double?>(l.sess),
  fonte: Value<String>(l.fonte),
  alPc: Value<bool?>(l.alPc),
  lavoro: Value<bool>(l.lavoro),
  modelli: Value<String>(l.modelli),
  skill: Value<String>(l.skill),
  gestore: l.gestore,
);

EventiCompanion _rigaEvento(Evento e) => EventiCompanion.insert(
  ora: formatta(e.ora),
  tipo: e.tipo.name,
  testo: Value<String>(e.testo),
);

Lettura? _daRigaLettura(RigaLettura r) {
  final DateTime? ora = interpreta(r.ora);
  if (ora == null) {
    return null;
  }
  return Lettura(
    ora: ora,
    sett: r.sett,
    sess: r.sess,
    fonte: r.fonte,
    alPc: r.alPc,
    lavoro: r.lavoro,
    modelli: r.modelli,
    skill: r.skill,
    gestore: r.gestore,
  );
}

Evento? _daRigaEvento(RigaEvento r) {
  final DateTime? ora = interpreta(r.ora);
  final TipoEvento? tipo = TipoEvento.daTesto(r.tipo);
  if (ora == null || tipo == null) {
    return null;
  }
  return Evento(ora: ora, tipo: tipo, testo: r.testo);
}
