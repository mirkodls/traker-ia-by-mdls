// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain (V2): serie del piano pronte per il grafico (fette giorno +
// linea ideale + linea adattiva) e la loro cache. Il grafico NON calcola
// mai: prende queste liste già fatte. Puro: nessun import ui/data/dart:io.
import 'coppie.dart' show Periodo;
import 'linee_piano.dart';
import 'modelli.dart';
import 'piani_progetti.dart';
import 'piano_giorni.dart';

/// Quante settimane al massimo si dividono in giorni (oltre: solo l'attuale).
const int maxSettimaneGiorni = 8;

/// Serie del piano per il grafico (immutabile, mai modificare le liste).
class SeriePiano {
  /// Crea la serie.
  const SeriePiano({
    required this.fette,
    required this.ideale,
    required this.adattiva,
    required this.inizioSettimana,
    this.soglie = const <SogliaGiorno>[],
    this.rosso = const <Periodo>[],
  });

  /// Fette-giorno di tutte le settimane visibili, in ordine di tempo.
  final List<FetteGiorno> fette;

  /// Linea ideale della settimana attuale (a gradini).
  final List<PuntoLinea> ideale;

  /// Linea adattiva della settimana attuale (a gradini).
  final List<PuntoLinea> adattiva;

  /// Reset che apre la settimana attuale.
  final DateTime inizioSettimana;

  /// Soglia di ogni giorno della settimana attuale (limite adattivo a
  /// inizio giorno). Vuota se il rosso è spento.
  final List<SogliaGiorno> soglie;

  /// Tratti di tempo in cui la linea Settimana è a P% o più della soglia
  /// del giorno (da disegnare rossi). Vuota se il rosso è spento.
  final List<Periodo> rosso;
}

/// Reset settimanali (stessa ora di orologio, 7 giorni l'uno dall'altro) da
/// quello della settimana che contiene [da] fino a [reset] compreso.
/// Più di [maxSettimaneGiorni] settimane -> solo [reset].
List<DateTime> resetVisibili(DateTime da, DateTime reset) {
  final List<DateTime> out = <DateTime>[reset];
  DateTime r = reset;
  while (r.isAfter(da) && out.length < maxSettimaneGiorni + 1) {
    r = DateTime(r.year, r.month, r.day - 7, r.hour, r.minute);
    out.add(r);
  }
  if (r.isAfter(da)) {
    return <DateTime>[reset];
  }
  return out.reversed.toList();
}

/// Calcola le serie del piano ([piano] vale per tutte le settimane).
/// [da] = inizio del periodo mostrato, [reset] = reset della settimana
/// attuale. Linee solo per la settimana attuale. [rossoPct] = P (50-100):
/// calcola soglie e tratti rossi; null = rosso spento.
SeriePiano calcolaSeriePiano(
  Piano piano,
  List<Lettura> letture, {
  required DateTime da,
  required DateTime reset,
  double? rossoPct,
}) {
  final List<FetteGiorno> fette = <FetteGiorno>[
    for (final DateTime r in resetVisibili(da, reset))
      ...costruisciFette(piano, r),
  ];
  final List<FetteGiorno> attuali = costruisciFette(piano, reset);
  final List<Lettura> settimana = letture
      .where((Lettura l) => !l.ora.isBefore(reset))
      .toList();
  final List<SogliaGiorno> soglie = rossoPct == null
      ? const <SogliaGiorno>[]
      : sogliaGiorni(attuali, settimana, target: piano.targetPct);
  return SeriePiano(
    soglie: List<SogliaGiorno>.unmodifiable(soglie),
    rosso: List<Periodo>.unmodifiable(
      rossoPct == null
          ? const <Periodo>[]
          : trattiRossi(soglie, settimana, percento: rossoPct),
    ),
    fette: List<FetteGiorno>.unmodifiable(fette),
    ideale: List<PuntoLinea>.unmodifiable(
      lineaIdeale(attuali, target: piano.targetPct),
    ),
    adattiva: List<PuntoLinea>.unmodifiable(
      lineaAdattiva(attuali, settimana, target: piano.targetPct),
    ),
    inizioSettimana: reset,
  );
}

typedef _Chiave = (int, int, int, double, int, int, int, double?, double?);

/// Cache: ricalcola le serie SOLO se cambiano piano, settimana, periodo o
/// letture. Stessi dati = stesso oggetto (identical).
class CachePiano {
  _Chiave? _chiave;
  SeriePiano? _serie;

  /// Quante volte ha davvero calcolato (per i test).
  int calcoli = 0;

  /// Serie per [piano]/[letture]/[da]/[reset]/[rossoPct]; riusa quella in
  /// cache se i dati sono gli stessi. Trasparenza e spessore delle linee NON
  /// entrano qui: cambiarli non ricalcola nulla.
  SeriePiano serie(
    Piano piano,
    List<Lettura> letture, {
    required DateTime da,
    required DateTime reset,
    double? rossoPct,
  }) {
    // Letture solo aggiunte: lunghezza + ultima lettura bastano.
    final Lettura? ult = letture.isEmpty ? null : letture.last;
    final _Chiave k = (
      reset.microsecondsSinceEpoch,
      resetVisibili(da, reset).first.microsecondsSinceEpoch,
      piano.giorniMask,
      piano.targetPct,
      piano.confine.index,
      letture.length,
      ult?.ora.microsecondsSinceEpoch ?? 0,
      ult?.sett,
      rossoPct,
    );
    final SeriePiano? s = _serie;
    if (s != null && k == _chiave) {
      return s;
    }
    calcoli++;
    final SeriePiano n = calcolaSeriePiano(
      piano,
      letture,
      da: da,
      reset: reset,
      rossoPct: rossoPct,
    );
    _chiave = k;
    _serie = n;
    return n;
  }
}
