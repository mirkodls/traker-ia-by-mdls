// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: modelli/skill accesi = combinazione; ritmo, confronto,
// classifica modelli.
import 'dart:math' as math;

import 'analisi.dart';
import 'coppie.dart';
import 'modelli.dart';
import 'testi.dart';

/// Combinazione: modelli e skill normalizzati ('A|B').
typedef Combo = ({String modelli, String skill});

/// Combinazione vuota (letture senza tasti).
const Combo comboVuota = (modelli: '', skill: '');

/// Ore sotto le quali un confronto è dato debole.
const double oreMinime = 1;

/// 'Sonnet| Opus|Opus' -> 'Opus|Sonnet' (ordinati, senza doppioni né vuoti).
String norm(String? s) {
  final Set<String> nomi = <String>{
    for (final String x in (s ?? '').split('|'))
      if (x.trim().isNotEmpty) x.trim(),
  };
  final List<String> l = nomi.toList()..sort();
  return l.join('|');
}

/// Lista di nomi -> testo normalizzato.
String unisci(Iterable<String> nomi) => norm(nomi.join('|'));

/// Combinazione segnata nella lettura.
Combo comboDi(Lettura l) => (modelli: norm(l.modelli), skill: norm(l.skill));

/// 'Opus + Sonnet  ·  caveman'.
String etichetta(Combo c) {
  if (c.modelli.isEmpty && c.skill.isEmpty) {
    return Testi.nonSegnato;
  }
  final String mm =
      c.modelli.isEmpty ? Testi.nessunModello : c.modelli.replaceAll('|', ' + ');
  return c.skill.isEmpty ? mm : '$mm  ·  ${c.skill.replaceAll('|', ' + ')}';
}

/// Ritmo di una combinazione.
class RitmoCombo {
  /// Crea il risultato.
  const RitmoCombo({required this.ore, this.sett, this.sess});

  /// Ore raccolte (la più alta tra le due barre).
  final double ore;

  /// pt%/h settimanale.
  final double? sett;

  /// pt%/h sessione.
  final double? sess;

  /// Ritmo della barra [campo].
  double? valore(Campo campo) => campo == Campo.sett ? sett : sess;
}

/// {combinazione: ritmo}. Ogni intervallo va alla combinazione della lettura
/// di arrivo. Reset esclusi. [periodi] = conta solo dentro i periodi lavoro.
Map<Combo, RitmoCombo> ritmoPerCombinazione(
  Iterable<Lettura> letture, {
  List<Periodo>? periodi,
}) {
  final Map<Combo, List<double>> acc = <Combo, List<double>>{};
  for (final Campo campo in Campo.values) {
    final int o = campo == Campo.sett ? 0 : 2;
    for (final Quota q in quote(letture, campo, periodi: periodi)) {
      final List<double> r =
          acc.putIfAbsent(comboDi(q.arrivo), () => <double>[0, 0, 0, 0]);
      r[o] += q.punti;
      r[o + 1] += q.ore;
    }
  }
  return <Combo, RitmoCombo>{
    for (final MapEntry<Combo, List<double>> e in acc.entries)
      e.key: RitmoCombo(
        ore: math.max(e.value[1], e.value[3]),
        sett: e.value[1] > 0 ? e.value[0] / e.value[1] : null,
        sess: e.value[3] > 0 ? e.value[2] / e.value[3] : null,
      ),
  };
}

/// c1 = riferimento, c2 = altra. Sotto [oreMin] ore -> dato debole.
Verdetto confronta(
  RitmoCombo? c1,
  RitmoCombo? c2, {
  Campo campo = Campo.sett,
  double soglia = 0.10,
  double oreMin = oreMinime,
}) {
  if (c1 == null || c2 == null || c1.ore < oreMin || c2.ore < oreMin) {
    return Verdetto.datoDebole;
  }
  return verdetto(c1.valore(campo), c2.valore(campo), soglia: soglia);
}

/// Voce della classifica modelli.
class VoceClassifica {
  /// Crea la voce.
  const VoceClassifica(this.modello, this.ore, this.ritmo);

  /// Nome modello.
  final String modello;

  /// Ore raccolte.
  final double ore;

  /// pt%/h.
  final double ritmo;
}

/// Classifica dal modello più vorace. Più modelli accesi insieme:
/// l'intervallo conta per ognuno.
List<VoceClassifica> classificaModelli(
  Iterable<Lettura> letture, {
  Campo campo = Campo.sett,
}) {
  final Map<String, List<double>> tab = <String, List<double>>{};
  for (final Coppia c in coppie(letture, campo)) {
    final String m = norm(c.arrivo.modelli);
    if (m.isEmpty) {
      continue;
    }
    for (final String nome in m.split('|')) {
      final List<double> r = tab.putIfAbsent(nome, () => <double>[0, 0]);
      r[0] += c.punti;
      r[1] += c.ore;
    }
  }
  final List<VoceClassifica> out = <VoceClassifica>[
    for (final MapEntry<String, List<double>> e in tab.entries)
      if (e.value[1] > 0) VoceClassifica(e.key, e.value[1], e.value[0] / e.value[1]),
  ];
  out.sort((VoceClassifica a, VoceClassifica b) {
    final int c = b.ritmo.compareTo(a.ritmo);
    return c != 0 ? c : a.modello.compareTo(b.modello);
  });
  return out;
}

/// Combinazione valida all'ora [t] = quella della prima lettura >= t.
Combo? statoA(Iterable<Lettura> letture, DateTime t) {
  final List<Lettura> ls = ordinaLetture(letture);
  for (final Lettura l in ls) {
    if (!l.ora.isBefore(t)) {
      return comboDi(l);
    }
  }
  return ls.isEmpty ? null : comboDi(ls.last);
}
