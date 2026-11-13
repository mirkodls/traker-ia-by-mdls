// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: previsione 100%, budget del giorno, frasi "Cosa dicono i dati".
// Niente IA: frasi fisse riempite coi numeri.
import 'dart:math' as math;

import 'coppie.dart';
import 'modelli.dart';
import 'tempo.dart';
import 'testi.dart';

/// Consumo nel periodo <= questi punti = dato debole.
const double puntiDeboli = 1;

/// Previsione di fine piano settimanale.
class Previsione {
  /// Crea la previsione.
  const Previsione({
    required this.consumo,
    required this.debole,
    this.att,
    this.ritmo,
    this.ora100,
    this.primaDelReset = false,
  });

  /// Punti consumati nel periodo guardato.
  final double consumo;

  /// Poco dato: non fidarsi.
  final bool debole;

  /// % settimanale attuale.
  final double? att;

  /// pt%/h sulle ultime ore (pause incluse).
  final double? ritmo;

  /// Ora stimata del 100% (null se ritmo 0 o ignoto).
  final DateTime? ora100;

  /// Vero se il 100% arriva prima del reset.
  final bool primaDelReset;
}

Lettura? _ultima(Iterable<Lettura> letture, Campo campo) {
  Lettura? u;
  for (final Lettura l in letture) {
    if (l.valore(campo) != null && (u == null || l.ora.isAfter(u.ora))) {
      u = l;
    }
  }
  return u;
}

/// Ora stimata del 100% settimanale al ritmo delle ultime [ore] ore
/// (fino all'ultima lettura). [resetSett] = prossimo reset (già arrotondato).
Previsione previsione(
  Iterable<Lettura> letture,
  DateTime resetSett, {
  double ore = 6,
}) {
  final Lettura? ult = _ultima(letture, Campo.sett);
  if (ult == null) {
    return const Previsione(consumo: 0, debole: true);
  }
  final DateTime da = ult.ora.subtract(durataOre(ore));
  final RitmoOre ro = ritmoOre(letture, Campo.sett, da: da, a: ult.ora);
  final double? r = ro.ritmo;
  final double consumo = (r ?? 0) * ro.ore;
  DateTime? ora100;
  if (r != null && r > 0) {
    ora100 = ult.ora.add(durataOre((100 - ult.sett!) / r));
  }
  return Previsione(
    consumo: consumo,
    debole: r == null || consumo <= puntiDeboli,
    att: ult.sett,
    ritmo: r,
    ora100: ora100,
    primaDelReset: ora100 != null && ora100.isBefore(resetSett),
  );
}

/// Punti % al giorno fino al reset: (100 - att) / giorni al reset.
double? budgetGiorno(double? att, DateTime adesso, DateTime resetSett) {
  if (att == null) {
    return null;
  }
  final double giorni = oreTra(adesso, resetSett) / 24;
  if (giorni <= 0) {
    return null;
  }
  return math.max(0, 100 - att) / giorni;
}

/// pt%/h settimanale solo sulle coppie con consumo (> 0), ultime [ore] ore.
double? ritmoAttivo(Iterable<Lettura> letture, {double ore = 6}) {
  final List<Coppia> cs =
      coppie(letture, Campo.sett).where((Coppia c) => c.punti > 0).toList();
  double d = 0;
  double h = 0;
  for (final Coppia c in cs.reversed) {
    if (h >= ore) {
      break;
    }
    d += c.punti;
    h += c.ore;
  }
  return h > 0 ? d / h : null;
}

/// Ore di uso continuo al ritmo "attivo" prima del 100%.
double? oreFullGasRimaste(Iterable<Lettura> letture, {double ore = 6}) {
  final Lettura? ult = _ultima(letture, Campo.sett);
  final double? r = ritmoAttivo(letture, ore: ore);
  if (ult == null || r == null || r == 0) {
    return null;
  }
  return math.max(0, 100 - ult.sett!) / r;
}

/// Frasi del riquadro "Cosa dicono i dati".
List<String> frasi(
  Iterable<Lettura> letture,
  DateTime resetSett,
  DateTime adesso, {
  double ore = 6,
}) {
  final Previsione p = previsione(letture, resetSett, ore: ore);
  if (p.att == null) {
    return <String>[Testi.nessunDato];
  }
  final List<String> out = <String>[];
  if (p.debole) {
    out.add(Testi.datoDebole);
  } else if (p.primaDelReset) {
    out.add(
      'A questo ritmo finisci ${quando(p.ora100!)}. Reset ${quando(resetSett)}.',
    );
  } else {
    out.add(
      'A questo ritmo arrivi al reset senza finire. Reset ${quando(resetSett)}.',
    );
  }
  final double? b = budgetGiorno(p.att, adesso, resetSett);
  if (b != null) {
    out.add('Oggi puoi usare ancora ${numero(b, dec: 1)} punti.');
  }
  final double? h = oreFullGasRimaste(letture, ore: ore);
  if (h != null) {
    out.add('A pieno regime ti restano circa ${durata(h)} di lavoro.');
  }
  return out;
}
