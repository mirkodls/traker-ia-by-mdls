// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain (V2): divide la settimana (da reset a reset) in fette-giorno
// del piano. Puro: nessun import ui/data/dart:io.
//
// Ora legale: i confini seguono l'orologio locale (stessa ora ogni giorno,
// come prossimoReset in tempo.dart). Un giorno può durare 23 o 25 ore.
import 'piani_progetti.dart';

/// Un "giorno" del piano (immutabile).
class FetteGiorno {
  /// Crea una fetta.
  const FetteGiorno({
    required this.indice,
    required this.inizio,
    required this.fine,
    required this.lavoro,
    this.peso = 1,
  });

  /// Posizione nella settimana (0 = prima fetta dopo il reset).
  final int indice;

  /// Inizio (compreso).
  final DateTime inizio;

  /// Fine (esclusa) = inizio della fetta dopo.
  final DateTime fine;

  /// Vero se giorno di lavoro del piano.
  final bool lavoro;

  /// Quanto conta per la quota: 1 = giorno intero; pezzi corti (confine
  /// mezzanotte) = ore di orologio / 24.
  final double peso;

  /// Giorno della settimana dell'inizio (1 = lunedì ... 7 = domenica).
  int get giorno => inizio.weekday;

  /// Vero se [t] sta dentro la fetta: inizio <= t < fine.
  bool contiene(DateTime t) => !t.isBefore(inizio) && t.isBefore(fine);
}

DateTime _data(
  bool utc,
  int a,
  int me,
  int g, [
  int h = 0,
  int mi = 0,
  int s = 0,
]) => utc ? DateTime.utc(a, me, g, h, mi, s) : DateTime(a, me, g, h, mi, s);

/// Stessa ora di orologio di [d], [giorni] giorni dopo.
DateTime _piuGiorni(DateTime d, int giorni) =>
    _data(d.isUtc, d.year, d.month, d.day + giorni, d.hour, d.minute, d.second);

/// Fine settimana: stessa ora di orologio del [reset], 7 giorni dopo.
DateTime fineSettimanaPiano(DateTime reset) => _piuGiorni(reset, 7);

/// Maschera dei primi [n] giorni dal reset ([giornoReset] come
/// DateTime.weekday). n <= 0 -> 0; n >= 7 -> tutti.
int mascheraPrimiGiorni(int n, {int giornoReset = DateTime.tuesday}) {
  final int k = n.clamp(0, 7);
  return mascheraGiorni(<int>[
    for (int i = 0; i < k; i++) (giornoReset - 1 + i) % 7 + 1,
  ]);
}

/// Fette della settimana che parte da [reset] secondo [piano].
/// reset24h: 7 fette [reset + k giorni, reset + k+1 giorni), peso 1.
/// mezzanotte: giorni di calendario; il pezzo reset->mezzanotte e il pezzo
/// mezzanotte->reset finale sono fette corte (stesso giorno settimana, peso
/// = ore/24). Lavoro = giorno settimana dell'inizio nella maschera.
List<FetteGiorno> costruisciFette(Piano piano, DateTime reset) {
  final DateTime fineSett = fineSettimanaPiano(reset);
  final List<FetteGiorno> out = <FetteGiorno>[];
  if (piano.confine == ConfinePiano.reset24h) {
    for (int k = 0; k < 7; k++) {
      final DateTime ini = _piuGiorni(reset, k);
      out.add(
        FetteGiorno(
          indice: k,
          inizio: ini,
          fine: _piuGiorni(reset, k + 1),
          lavoro: piano.lavoraIl(ini.weekday),
        ),
      );
    }
    return out;
  }
  DateTime cur = reset;
  while (cur.isBefore(fineSett)) {
    final DateTime mezzanotte = _data(
      cur.isUtc,
      cur.year,
      cur.month,
      cur.day + 1,
    );
    final DateTime f = mezzanotte.isBefore(fineSett) ? mezzanotte : fineSett;
    out.add(
      FetteGiorno(
        indice: out.length,
        inizio: cur,
        fine: f,
        lavoro: piano.lavoraIl(cur.weekday),
        peso: _pesoCalendario(cur, f),
      ),
    );
    cur = f;
  }
  return out;
}

/// Minuti di orologio dall'inizio del giorno di [inizio] fino a [d]
/// ([d] mezzanotte del giorno dopo -> 1440).
int _minutiOrologio(DateTime inizio, DateTime d) {
  final bool stessoGiorno =
      d.year == inizio.year && d.month == inizio.month && d.day == inizio.day;
  return stessoGiorno ? d.hour * 60 + d.minute : 1440;
}

double _pesoCalendario(DateTime ini, DateTime fine) {
  final int a = ini.hour * 60 + ini.minute;
  final int b = _minutiOrologio(ini, fine);
  return (b - a) / 1440;
}

/// Ora ultima del piano = fine dell'ultima fetta di lavoro (null = nessuna).
DateTime? oraUltima(List<FetteGiorno> fette) {
  for (int i = fette.length - 1; i >= 0; i--) {
    if (fette[i].lavoro) {
      return fette[i].fine;
    }
  }
  return null;
}

/// Indice della fetta che contiene [t] (-1 = fuori settimana).
int indiceFetta(List<FetteGiorno> fette, DateTime t) {
  for (int i = 0; i < fette.length; i++) {
    if (fette[i].contiene(t)) {
      return i;
    }
  }
  return -1;
}
