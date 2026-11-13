// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: coppie di letture consecutive e ritmo (punti % all'ora).
import 'dart:math' as math;

import 'modelli.dart';
import 'tempo.dart';

/// Due letture consecutive valide (stessa finestra, nessun reset in mezzo).
class Coppia {
  /// Crea una coppia.
  const Coppia(this.partenza, this.arrivo, this.punti, this.ore);

  /// Lettura di partenza.
  final Lettura partenza;

  /// Lettura di arrivo.
  final Lettura arrivo;

  /// Punti % saliti (>= 0).
  final double punti;

  /// Ore tra le due letture (> 0).
  final double ore;
}

/// Periodo con inizio e fine (es. Inizio -> Fine lavoro).
typedef Periodo = ({DateTime inizio, DateTime fine});

/// Calo più grande di questo = reset.
const double sogliaReset = 0.5;

/// Coppie consecutive valide per [campo]. Cali (reset) esclusi.
List<Coppia> coppie(Iterable<Lettura> letture, Campo campo) {
  final List<Lettura> ls = ordinaLetture(
    letture.where((Lettura l) => l.valore(campo) != null),
  );
  final List<Coppia> out = <Coppia>[];
  for (int i = 1; i < ls.length; i++) {
    final Lettura a = ls[i - 1];
    final Lettura b = ls[i];
    final double d = b.valore(campo)! - a.valore(campo)!;
    final double h = oreTra(a.ora, b.ora);
    if (d < -sogliaReset || h <= 0) {
      continue;
    }
    out.add(Coppia(a, b, math.max(d, 0), h));
  }
  return out;
}

/// Ore di [ini, fin] dentro i [periodi]. periodi null -> tutto l'intervallo.
double sovrapposizione(DateTime ini, DateTime fin, List<Periodo>? periodi) {
  if (!fin.isAfter(ini)) {
    return 0;
  }
  if (periodi == null) {
    return oreTra(ini, fin);
  }
  double tot = 0;
  for (final Periodo p in periodi) {
    final DateTime x = piuTardi(ini, p.inizio);
    final DateTime y = piuPresto(fin, p.fine);
    if (y.isAfter(x)) {
      tot += oreTra(x, y);
    }
  }
  return tot;
}

/// Pezzo di coppia contato: lettura di arrivo, punti e ore.
class Quota {
  /// Crea una quota.
  const Quota(this.arrivo, this.punti, this.ore);

  /// Lettura di arrivo della coppia.
  final Lettura arrivo;

  /// Punti contati.
  final double punti;

  /// Ore contate.
  final double ore;
}

/// Per ogni coppia valida: la parte dentro [da, a] e dentro i [periodi].
/// Coppie a cavallo tagliate in proporzione.
List<Quota> quote(
  Iterable<Lettura> letture,
  Campo campo, {
  DateTime? da,
  DateTime? a,
  List<Periodo>? periodi,
}) {
  final List<Quota> out = <Quota>[];
  for (final Coppia c in coppie(letture, campo)) {
    final DateTime ini = da == null ? c.partenza.ora : piuTardi(c.partenza.ora, da);
    final DateTime fin = a == null ? c.arrivo.ora : piuPresto(c.arrivo.ora, a);
    final double q = sovrapposizione(ini, fin, periodi);
    if (q > 0) {
      out.add(Quota(c.arrivo, c.punti * q / c.ore, q));
    }
  }
  return out;
}

/// Ritmo (pt%/h, null se nessun dato) e ore contate.
class RitmoOre {
  /// Crea il risultato.
  const RitmoOre(this.ritmo, this.ore);

  /// Punti % all'ora.
  final double? ritmo;

  /// Ore di letture usate.
  final double ore;
}

/// Ritmo e ore nel periodo [da, a], solo dentro [periodi] se dati.
RitmoOre ritmoOre(
  Iterable<Lettura> letture,
  Campo campo, {
  DateTime? da,
  DateTime? a,
  List<Periodo>? periodi,
}) {
  double d = 0;
  double h = 0;
  for (final Quota q in quote(letture, campo, da: da, a: a, periodi: periodi)) {
    d += q.punti;
    h += q.ore;
  }
  return RitmoOre(h > 0 ? d / h : null, h);
}

/// Punti % all'ora nel periodo [da, a] (coppie a cavallo in proporzione).
double? ritmo(
  Iterable<Lettura> letture,
  Campo campo, {
  DateTime? da,
  DateTime? a,
}) =>
    ritmoOre(letture, campo, da: da, a: a).ritmo;

/// Ore di letture usate dal ritmo nel periodo [da, a].
double oreContate(
  Iterable<Lettura> letture,
  Campo campo, {
  DateTime? da,
  DateTime? a,
}) =>
    ritmoOre(letture, campo, da: da, a: a).ore;
