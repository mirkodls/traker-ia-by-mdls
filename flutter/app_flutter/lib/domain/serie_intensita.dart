// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain (V2): serie intensità pronta per il grafico, in cache (si
// ricalcola solo se cambiano letture, eventi o scelte), medie "statistiche",
// punto sotto il mouse e note-comando "lavoro" / "fine lavoro".
import 'dart:math' as math;

import 'intensita.dart';
import 'modelli.dart';

/// Medie dei punti validi di una serie intensità (una per fonte).
class StatIntensita {
  /// Crea le medie.
  const StatIntensita({
    this.media5h,
    this.errore5h,
    this.media7gg,
    this.errore7gg,
    this.n5h = 0,
    this.n7gg = 0,
  });

  /// Media punti sessione all'ora (null = nessun punto 5h).
  final double? media5h;

  /// Errore ± medio della media 5h.
  final double? errore5h;

  /// Media punti settimana all'ora (null = nessun punto 7gg).
  final double? media7gg;

  /// Errore ± medio della media 7gg.
  final double? errore7gg;

  /// Punti 5h validi.
  final int n5h;

  /// Punti 7gg validi.
  final int n7gg;

  /// Vero se non c'è nessuna media.
  bool get vuota => media5h == null && media7gg == null;
}

/// Medie per fonte dei punti validi (buchi esclusi).
StatIntensita statIntensita(Iterable<PuntoIntensita> punti) {
  double s5 = 0;
  double e5 = 0;
  double s7 = 0;
  double e7 = 0;
  int n5 = 0;
  int n7 = 0;
  for (final PuntoIntensita p in punti) {
    final double? v = p.valore;
    if (v == null) {
      continue;
    }
    if (p.fonte == FonteIntensita.cinqueOre) {
      s5 += v;
      e5 += p.errore ?? 0;
      n5++;
    } else {
      s7 += v;
      e7 += p.errore ?? 0;
      n7++;
    }
  }
  return StatIntensita(
    media5h: n5 == 0 ? null : s5 / n5,
    errore5h: n5 == 0 ? null : e5 / n5,
    media7gg: n7 == 0 ? null : s7 / n7,
    errore7gg: n7 == 0 ? null : e7 / n7,
    n5h: n5,
    n7gg: n7,
  );
}

/// Serie intensità V2 pronta da disegnare.
class IntensitaV2 {
  /// Crea la serie. [punti] diventa non modificabile.
  IntensitaV2({
    required List<PuntoIntensita> punti,
    required this.stat,
    required this.max5h,
    required this.max7gg,
    this.soloLavoro = false,
    this.finestraPostumaMin = finestraPostumaPredefinita,
  }) : punti = List<PuntoIntensita>.unmodifiable(punti);

  /// Serie vuota.
  factory IntensitaV2.vuota({
    bool soloLavoro = false,
    int finestraPostumaMin = finestraPostumaPredefinita,
  }) => IntensitaV2(
    punti: const <PuntoIntensita>[],
    stat: const StatIntensita(),
    max5h: 1,
    max7gg: 1,
    soloLavoro: soloLavoro,
    finestraPostumaMin: finestraPostumaMin,
  );

  /// Punti, in ordine di tempo, passo fisso.
  final List<PuntoIntensita> punti;

  /// Medie per fonte.
  final StatIntensita stat;

  /// Cima dell'asse per i punti 5h (pt sess/h, almeno 1).
  final double max5h;

  /// Cima dell'asse per i punti 7gg (pt sett/h, almeno 1).
  final double max7gg;

  /// Serie calcolata contando solo la fascia Lavoro.
  final bool soloLavoro;

  /// Finestra (minuti) della postuma settimanale usata.
  final int finestraPostumaMin;
}

/// Calcola la serie intensità V2 e le medie (senza cache).
IntensitaV2 calcolaIntensitaV2(
  List<Lettura> letture,
  List<Evento> eventi,
  DateTime da,
  DateTime a, {
  int passoMin = 5,
  int finestraPostumaMin = finestraPostumaPredefinita,
  bool soloLavoro = false,
}) {
  final int n = finestraPostumaValida(finestraPostumaMin);
  if (!a.isAfter(da)) {
    return IntensitaV2.vuota(soloLavoro: soloLavoro, finestraPostumaMin: n);
  }
  final OpzioniIntensita opz = OpzioniIntensita(finestraPostumaMin: n);
  final List<PuntoIntensita> punti = soloLavoro
      ? intensitaSoloLavoro(
          letture,
          da,
          a,
          eventi: eventi,
          passoMin: passoMin,
          opzioni: opz,
        )
      : serieIntensitaV2(letture, da, a, passoMin: passoMin, opzioni: opz);
  double m5 = 1;
  double m7 = 1;
  for (final PuntoIntensita p in punti) {
    final double? v = p.valore;
    if (v == null) {
      continue;
    }
    if (p.fonte == FonteIntensita.cinqueOre) {
      m5 = math.max(m5, v);
    } else {
      m7 = math.max(m7, v);
    }
  }
  return IntensitaV2(
    punti: punti,
    stat: statIntensita(punti),
    max5h: m5,
    max7gg: m7,
    soloLavoro: soloLavoro,
    finestraPostumaMin: n,
  );
}

DateTime _alPasso(DateTime t, int passoMin) {
  final int p = math.max(1, passoMin) * Duration.millisecondsPerMinute;
  return DateTime.fromMillisecondsSinceEpoch(
    t.millisecondsSinceEpoch ~/ p * p,
    isUtc: t.isUtc,
  );
}

/// Cache della serie intensità: la ricalcola solo se cambiano letture,
/// eventi, scelte (finestra, solo lavoro) o se l'asse avanza di un passo.
/// Il grafico non calcola mai: legge il risultato.
class CacheIntensita {
  String? _chiave;
  IntensitaV2? _serie;

  /// Quante volte la serie è stata ricalcolata davvero.
  int calcoli = 0;

  /// Serie per [da, a]; mai nel futuro ([adesso]). [letture] in ordine di
  /// tempo.
  IntensitaV2 serie(
    List<Lettura> letture,
    List<Evento> eventi,
    DateTime da,
    DateTime a,
    DateTime adesso, {
    required int passoMin,
    int finestraPostumaMin = finestraPostumaPredefinita,
    bool soloLavoro = false,
  }) {
    final int n = finestraPostumaValida(finestraPostumaMin);
    final DateTime daQ = _alPasso(da, passoMin);
    final DateTime aQ = _alPasso(a.isAfter(adesso) ? adesso : a, passoMin);
    final Lettura? u = letture.isEmpty ? null : letture.last;
    final Evento? ue = eventi.isEmpty ? null : eventi.last;
    final String chiave = <Object?>[
      daQ.microsecondsSinceEpoch,
      aQ.microsecondsSinceEpoch,
      passoMin,
      n,
      soloLavoro,
      letture.length,
      u?.ora.microsecondsSinceEpoch,
      u?.sett,
      u?.sess,
      u?.lavoro,
      eventi.length,
      ue?.ora.microsecondsSinceEpoch,
      ue?.tipo.index,
    ].join('|');
    final IntensitaV2? c = _serie;
    if (c != null && chiave == _chiave) {
      return c;
    }
    calcoli++;
    final IntensitaV2 nuova = calcolaIntensitaV2(
      letture,
      eventi,
      daQ,
      aQ,
      passoMin: passoMin,
      finestraPostumaMin: n,
      soloLavoro: soloLavoro,
    );
    _chiave = chiave;
    _serie = nuova;
    return nuova;
  }
}

/// Punto della serie più vicino a [t], al massimo a [maxDistanza] di distanza
/// (null = nessuno). [punti] in ordine di tempo.
PuntoIntensita? puntoIntensitaA(
  List<PuntoIntensita> punti,
  DateTime t, {
  Duration maxDistanza = const Duration(minutes: 30),
}) {
  if (punti.isEmpty) {
    return null;
  }
  int lo = 0;
  int hi = punti.length - 1;
  while (lo < hi) {
    final int mid = (lo + hi) ~/ 2;
    if (punti[mid].ora.isBefore(t)) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  PuntoIntensita best = punti[lo];
  if (lo > 0) {
    final PuntoIntensita prima = punti[lo - 1];
    if (t.difference(prima.ora).abs() <= best.ora.difference(t).abs()) {
      best = prima;
    }
  }
  return best.ora.difference(t).abs() <= maxDistanza ? best : null;
}

/// Nota-comando: testo che da solo apre o chiude il periodo Lavoro.
/// 'lavoro' -> inizio, 'fine lavoro' -> fine (maiuscole, spazi doppi e
/// punteggiatura finale ignorati). Qualsiasi altro testo -> null (nota
/// normale: "lavoro su excel" NON è un comando).
TipoEvento? comandoLavoroDaNota(String testo) {
  final String t = testo
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[\s.!;:,]+$'), '')
      .trim();
  return switch (t) {
    'lavoro' => TipoEvento.inizio,
    'fine lavoro' => TipoEvento.fine,
    _ => null,
  };
}
