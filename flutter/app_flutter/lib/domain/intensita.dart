// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: intensità V2. Sorgente per istante (barra 5 ore se c'è,
// altrimenti barra settimanale "postuma"), finestre mobili, errore ± dovuto
// alle letture a punti interi, reset esclusi (buco), filtro solo lavoro.
// Tutto O(n) dopo l'ordinamento: nessun ciclo annidato sulle letture.
import 'dart:math' as math;

import 'coppie.dart';
import 'lavoro.dart';
import 'modelli.dart';
import 'tempo.dart';

/// Da quale barra viene un punto di intensità.
enum FonteIntensita {
  /// Barra sessione 5 ore: unità punti sessione all'ora.
  cinqueOre('5h'),

  /// Barra settimanale (postuma a campioni): unità punti settimana all'ora.
  setteGiorni('7gg');

  const FonteIntensita(this.codice);

  /// Codice corto ('5h' | '7gg').
  final String codice;

  /// Barra letta per questa fonte.
  Campo get campo => this == cinqueOre ? Campo.sess : Campo.sett;
}

/// Finestre (minuti) ammesse per l'intensità postuma settimanale.
const List<int> finestrePostuma = <int>[30, 60, 120];

/// Finestra postuma predefinita (minuti).
const int finestraPostumaPredefinita = 60;

/// Finestra media mobile barra 5 ore (minuti), come l'intensità V1.
const int finestra5hPredefinita = 30;

/// Minuti senza barra 5 ore dopo i quali si passa alla settimanale.
const int passaggioPredefinito = 15;

/// Due letture più lontane di così (minuti) = buco, non si contano.
const int maxBucoPredefinito = 180;

/// [n] tra le finestre ammesse, altrimenti la predefinita.
int finestraPostumaValida(int? n) =>
    finestrePostuma.contains(n) ? n! : finestraPostumaPredefinita;

/// Opzioni del calcolo intensità.
class OpzioniIntensita {
  /// Crea le opzioni (valori predefiniti = decisioni B10).
  const OpzioniIntensita({
    this.finestra5hMin = finestra5hPredefinita,
    this.finestraPostumaMin = finestraPostumaPredefinita,
    this.passaggioMin = passaggioPredefinito,
    this.maxBucoMin = maxBucoPredefinito,
    this.copertura = 0.5,
  });

  /// Finestra mobile barra 5 ore (minuti).
  final int finestra5hMin;

  /// Finestra mobile postuma settimanale (minuti, 30/60/120).
  final int finestraPostumaMin;

  /// Minuti senza barra 5 ore prima di passare alla settimanale.
  final int passaggioMin;

  /// Intervallo massimo tra due letture per contarlo (minuti).
  final int maxBucoMin;

  /// Frazione minima della finestra coperta da dati validi (0-1).
  final double copertura;
}

/// Un punto della serie intensità.
class PuntoIntensita {
  /// Crea un punto.
  const PuntoIntensita({
    required this.ora,
    required this.fonte,
    this.valore,
    this.errore,
  });

  /// Ora del punto.
  final DateTime ora;

  /// Barra usata (unità: pt sess/h per 5h, pt sett/h per 7gg).
  final FonteIntensita fonte;

  /// Punti all'ora (>= 0); null = buco (dati mancanti o reset).
  final double? valore;

  /// Errore ± (punti all'ora) dovuto alle letture a punti interi.
  final double? errore;

  /// Vero se non c'è un valore.
  bool get buco => valore == null;

  @override
  bool operator ==(Object other) =>
      other is PuntoIntensita &&
      other.ora == ora &&
      other.fonte == fonte &&
      other.valore == valore &&
      other.errore == errore;

  @override
  int get hashCode => Object.hash(ora, fonte, valore, errore);
}

/// Pezzo di tempo con dati validi: [inizio, fine] e punti saliti.
class _Pezzo {
  const _Pezzo(this.inizio, this.fine, this.punti, {required this.attacca});

  final DateTime inizio;
  final DateTime fine;
  final double punti;

  /// Vero se continua il pezzo prima senza buchi (stesso tratto).
  final bool attacca;

  double get ore => oreTra(inizio, fine);
}

/// Coppie valide di [campo] -> pezzi (reset e buchi lunghi esclusi),
/// tagliati dentro [periodi] se dati (periodi ordinati, non sovrapposti).
List<_Pezzo> _pezzi(
  List<Lettura> ordinate,
  Campo campo,
  int maxBucoMin,
  List<Periodo>? periodi,
) {
  final List<_Pezzo> out = <_Pezzo>[];
  final double maxOre = maxBucoMin / 60;
  DateTime? fineUltimo;
  int p = 0;
  void aggiungi(DateTime x, DateTime y, double punti) {
    if (!y.isAfter(x)) {
      return;
    }
    out.add(_Pezzo(x, y, punti, attacca: fineUltimo == x));
    fineUltimo = y;
  }

  for (final Coppia c in coppie(ordinate, campo)) {
    if (c.ore > maxOre) {
      continue;
    }
    final DateTime a = c.partenza.ora;
    final DateTime b = c.arrivo.ora;
    if (periodi == null) {
      aggiungi(a, b, c.punti);
      continue;
    }
    while (p < periodi.length && !periodi[p].fine.isAfter(a)) {
      p++;
    }
    for (int q = p; q < periodi.length && periodi[q].inizio.isBefore(b); q++) {
      final DateTime x = piuTardi(a, periodi[q].inizio);
      final DateTime y = piuPresto(b, periodi[q].fine);
      aggiungi(x, y, c.punti * oreTra(x, y) / c.ore);
    }
  }
  return out;
}

/// Punti [da, a] su griglia di [passoMin] minuti.
List<DateTime> _griglia(DateTime da, DateTime a, int passoMin) {
  final List<DateTime> out = <DateTime>[];
  if (passoMin <= 0 || a.isBefore(da)) {
    return out;
  }
  final Duration passo = Duration(minutes: passoMin);
  for (DateTime t = da; !t.isAfter(a); t = t.add(passo)) {
    out.add(t);
  }
  return out;
}

/// Media mobile sui [pezzi] per ogni ora di [ore] (crescenti), finestra
/// [finestraMin]: (valore, errore) o (null, null). O(pezzi + ore).
List<(double?, double?)> _mobile(
  List<_Pezzo> pezzi,
  List<DateTime> ore,
  int finestraMin,
  double copertura,
) {
  final int n = pezzi.length;
  // Somme prefisse: punti, ore, tratti (pezzi che non attaccano).
  final List<double> sp = List<double>.filled(n + 1, 0);
  final List<double> sh = List<double>.filled(n + 1, 0);
  final List<int> st = List<int>.filled(n + 1, 0);
  for (int i = 0; i < n; i++) {
    sp[i + 1] = sp[i] + pezzi[i].punti;
    sh[i + 1] = sh[i] + pezzi[i].ore;
    st[i + 1] = st[i] + (pezzi[i].attacca ? 0 : 1);
  }
  final Duration finestra = Duration(minutes: finestraMin);
  final double oreFinestra = finestraMin / 60;
  final List<(double?, double?)> out = <(double?, double?)>[];
  int j = 0; // primo pezzo con fine > ini
  int m = 0; // primo pezzo con inizio >= t
  for (final DateTime t in ore) {
    final DateTime ini = t.subtract(finestra);
    while (j < n && !pezzi[j].fine.isAfter(ini)) {
      j++;
    }
    while (m < n && pezzi[m].inizio.isBefore(t)) {
      m++;
    }
    if (finestraMin <= 0 || m <= j) {
      out.add((null, null));
      continue;
    }
    double d = sp[m] - sp[j];
    double h = sh[m] - sh[j];
    // Taglia i pezzi ai bordi in proporzione.
    for (final int k in <int>{j, m - 1}) {
      final _Pezzo z = pezzi[k];
      final DateTime x = piuTardi(z.inizio, ini);
      final DateTime y = piuPresto(z.fine, t);
      final double dentro = y.isAfter(x) ? oreTra(x, y) : 0;
      final double fuori = z.ore - dentro;
      if (fuori > 0) {
        d -= z.punti * fuori / z.ore;
        h -= fuori;
      }
    }
    // Tratti contigui nella finestra: il primo conta sempre come 1.
    final int tratti = 1 + st[m] - st[j + 1];
    if (h <= 0 || h < oreFinestra * copertura - 1e-9) {
      out.add((null, null));
      continue;
    }
    final double v = math.max(0, d) / h;
    final double e = tratti / h;
    out.add(v.isFinite && e.isFinite ? (v, e) : (null, null));
  }
  return out;
}

/// Per ogni ora di [ore]: vero se la barra 5 ore va usata (ultima lettura
/// con sess, a quell'ora o prima, da meno di [passaggioMin] minuti). O(n).
List<bool> _usa5h(
  List<Lettura> ordinate,
  List<DateTime> ore,
  int passaggioMin,
) {
  final List<bool> out = <bool>[];
  final Duration soglia = Duration(minutes: passaggioMin);
  DateTime? ultima;
  int i = 0;
  for (final DateTime t in ore) {
    while (i < ordinate.length && !ordinate[i].ora.isAfter(t)) {
      if (ordinate[i].sess != null) {
        ultima = ordinate[i].ora;
      }
      i++;
    }
    out.add(ultima != null && t.difference(ultima) < soglia);
  }
  return out;
}

/// Intensità V2 in [da, a], un punto ogni [passoMin] minuti. Fonte scelta per
/// istante: barra 5 ore se presente, altrimenti (dopo [OpzioniIntensita.
/// passaggioMin]) barra settimanale postuma. Unità diverse per fonte: mai
/// convertite. [periodi] = conta solo dentro questi (es. lavoro).
List<PuntoIntensita> serieIntensitaV2(
  Iterable<Lettura> letture,
  DateTime da,
  DateTime a, {
  int passoMin = 5,
  OpzioniIntensita opzioni = const OpzioniIntensita(),
  List<Periodo>? periodi,
}) {
  final List<Lettura> ls = ordinaLetture(letture);
  final List<DateTime> ore = _griglia(da, a, passoMin);
  final List<bool> usa5h = _usa5h(ls, ore, opzioni.passaggioMin);
  final List<(double?, double?)> v5 = _mobile(
    _pezzi(ls, Campo.sess, opzioni.maxBucoMin, periodi),
    ore,
    opzioni.finestra5hMin,
    opzioni.copertura,
  );
  final List<(double?, double?)> v7 = _mobile(
    _pezzi(ls, Campo.sett, opzioni.maxBucoMin, periodi),
    ore,
    finestraPostumaValida(opzioni.finestraPostumaMin),
    opzioni.copertura,
  );
  return <PuntoIntensita>[
    for (int i = 0; i < ore.length; i++)
      if (usa5h[i])
        PuntoIntensita(
          ora: ore[i],
          fonte: FonteIntensita.cinqueOre,
          valore: v5[i].$1,
          errore: v5[i].$2,
        )
      else
        PuntoIntensita(
          ora: ore[i],
          fonte: FonteIntensita.setteGiorni,
          valore: v7[i].$1,
          errore: v7[i].$2,
        ),
  ];
}

/// Intensità postuma solo dalla barra settimanale (punti sett all'ora),
/// finestra [finestraMin] (30/60/120, altro -> 60). Stima: vedi errore.
List<PuntoIntensita> seriePostuma(
  Iterable<Lettura> letture,
  DateTime da,
  DateTime a, {
  int passoMin = 5,
  int finestraMin = finestraPostumaPredefinita,
  int maxBucoMin = maxBucoPredefinito,
  double copertura = 0.5,
  List<Periodo>? periodi,
}) {
  final List<Lettura> ls = ordinaLetture(letture);
  final List<DateTime> ore = _griglia(da, a, passoMin);
  final List<(double?, double?)> v = _mobile(
    _pezzi(ls, Campo.sett, maxBucoMin, periodi),
    ore,
    finestraPostumaValida(finestraMin),
    copertura,
  );
  return <PuntoIntensita>[
    for (int i = 0; i < ore.length; i++)
      PuntoIntensita(
        ora: ore[i],
        fonte: FonteIntensita.setteGiorni,
        valore: v[i].$1,
        errore: v[i].$2,
      ),
  ];
}

/// Periodi di lavoro: unione di eventi Inizio->Fine e intervalli tra letture
/// consecutive con arrivo lavoro=true. Ordinati, non sovrapposti.
List<Periodo> periodiSoloLavoro(
  Iterable<Lettura> letture,
  Iterable<Evento> eventi,
  DateTime fino,
) {
  final List<Lettura> ls = ordinaLetture(letture);
  final List<Periodo> tutti = <Periodo>[
    ...periodiLavoro(eventi, fino),
    for (int i = 1; i < ls.length; i++)
      if (ls[i].lavoro && ls[i].ora.isAfter(ls[i - 1].ora))
        (inizio: ls[i - 1].ora, fine: ls[i].ora),
  ]..sort((Periodo x, Periodo y) => x.inizio.compareTo(y.inizio));
  final List<Periodo> out = <Periodo>[];
  for (final Periodo p in tutti) {
    if (out.isNotEmpty && !p.inizio.isAfter(out.last.fine)) {
      final Periodo u = out.removeLast();
      out.add((inizio: u.inizio, fine: piuTardi(u.fine, p.fine)));
    } else {
      out.add(p);
    }
  }
  return out;
}

/// Intensità V2 contando solo la fascia Lavoro (letture lavoro=true o dentro
/// eventi Inizio/Fine). Fuori lavoro = buco.
List<PuntoIntensita> intensitaSoloLavoro(
  Iterable<Lettura> letture,
  DateTime da,
  DateTime a, {
  Iterable<Evento> eventi = const <Evento>[],
  int passoMin = 5,
  OpzioniIntensita opzioni = const OpzioniIntensita(),
}) => serieIntensitaV2(
  letture,
  da,
  a,
  passoMin: passoMin,
  opzioni: opzioni,
  periodi: periodiSoloLavoro(letture, eventi, a),
);

/// Arrotonda [v] senza falsa precisione: errore >= 1 -> intero; >= 0,1 ->
/// 1 decimale; meno -> 2 decimali.
double arrotondaStima(double v, double errore) {
  final double passo = errore >= 1
      ? 1
      : errore >= 0.1
      ? 0.1
      : 0.01;
  final double r = (v / passo).roundToDouble() * passo;
  return double.parse(
    r.toStringAsFixed(passo == 1 ? 0 : (passo == 0.1 ? 1 : 2)),
  );
}
