// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: unione dati per il sync, senza doppioni.
// Doppione lettura = stesso gestore, ±1 minuto, stessi valori.
// Doppione evento = stesso tipo e testo, ±1 minuto.
import 'modelli.dart';
import 'tempo.dart';

/// Distanza massima tra due doppioni.
const Duration tolleranzaDoppione = Duration(minutes: 1);

/// Risultato di un'unione: tutte le voci ordinate e quante nuove.
class RisultatoUnione<T> {
  /// Crea il risultato.
  const RisultatoUnione(this.voci, this.aggiunte);

  /// Voci unite, ordinate per ora.
  final List<T> voci;

  /// Voci arrivate e aggiunte (non doppioni).
  final int aggiunte;
}

bool _vicine(DateTime x, DateTime y) =>
    x.difference(y).abs() <= tolleranzaDoppione;

/// Vero se [x] e [y] sono la stessa lettura.
bool stessaLettura(Lettura x, Lettura y) =>
    x.gestore == y.gestore &&
    x.sett == y.sett &&
    x.sess == y.sess &&
    _vicine(x.ora, y.ora);

/// Vero se [x] e [y] sono lo stesso evento.
bool stessoEvento(Evento x, Evento y) =>
    x.tipo == y.tipo && x.testo == y.testo && _vicine(x.ora, y.ora);

/// Primo indice di [l] (ordinata) con ora >= [t].
int _primoDa<T>(List<T> l, DateTime Function(T) ora, DateTime t) {
  int lo = 0;
  int hi = l.length;
  while (lo < hi) {
    final int mid = (lo + hi) ~/ 2;
    if (ora(l[mid]).isBefore(t)) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo;
}

bool _presente<T>(
  List<T> l,
  T v,
  DateTime Function(T) ora,
  bool Function(T, T) uguali,
) {
  final DateTime t = ora(v);
  final DateTime fine = t.add(tolleranzaDoppione);
  for (int i = _primoDa(l, ora, t.subtract(tolleranzaDoppione));
      i < l.length && !ora(l[i]).isAfter(fine);
      i++) {
    if (uguali(l[i], v)) {
      return true;
    }
  }
  return false;
}

RisultatoUnione<T> _unisci<T>(
  Iterable<T> mie,
  Iterable<T> arrivate,
  DateTime Function(T) ora,
  bool Function(T, T) uguali,
) {
  final List<T> base = ordinaPerOra(mie, ora);
  final List<T> nuove = <T>[];
  for (final T v in ordinaPerOra(arrivate, ora)) {
    if (!_presente(base, v, ora, uguali) && !_presente(nuove, v, ora, uguali)) {
      nuove.add(v);
    }
  }
  return RisultatoUnione<T>(
    ordinaPerOra(<T>[...base, ...nuove], ora),
    nuove.length,
  );
}

/// Unisce le letture arrivate dal sync alle mie, senza doppioni.
RisultatoUnione<Lettura> unisciLetture(
  Iterable<Lettura> mie,
  Iterable<Lettura> arrivate,
) =>
    _unisci(mie, arrivate, (Lettura l) => l.ora, stessaLettura);

/// Unisce gli eventi arrivati dal sync ai miei, senza doppioni.
RisultatoUnione<Evento> unisciEventi(
  Iterable<Evento> mie,
  Iterable<Evento> arrivati,
) =>
    _unisci(mie, arrivati, (Evento e) => e.ora, stessoEvento);
