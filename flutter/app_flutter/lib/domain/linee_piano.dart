// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain (V2): linee del piano sul grafico settimanale.
// - IDEALE: quota fissa per giorno di lavoro (target / giorni lavoro).
// - ADATTIVA: da un istante t ricalcola la quota su quello che resta.
// Linee a gradino: in ogni fetta il valore = limite % settimanale a fine
// fetta. Due punti per fetta (inizio, fine) con lo stesso valore: unendo i
// punti in ordine viene la scala. Calcoli O(n), da fare fuori da paint.
import 'modelli.dart';
import 'piani_progetti.dart';
import 'piano_giorni.dart';

/// Un punto di una linea del piano.
class PuntoLinea {
  /// Crea un punto.
  const PuntoLinea(this.ora, this.valore);

  /// Ora del punto.
  final DateTime ora;

  /// % settimanale.
  final double valore;

  @override
  bool operator ==(Object other) =>
      other is PuntoLinea && other.ora == ora && other.valore == valore;

  @override
  int get hashCode => Object.hash(ora, valore);

  @override
  String toString() => 'PuntoLinea($ora, $valore)';
}

double _pesoLavoro(Iterable<FetteGiorno> fette) {
  double s = 0;
  for (final FetteGiorno f in fette) {
    if (f.lavoro) {
      s += f.peso;
    }
  }
  return s;
}

/// Fette fino all'ultima di lavoro compresa (dopo: niente linea).
List<FetteGiorno> _finoUltima(List<FetteGiorno> fette) {
  int u = -1;
  for (int i = fette.length - 1; i >= 0 && u < 0; i--) {
    if (fette[i].lavoro) {
      u = i;
    }
  }
  return fette.sublist(0, u + 1);
}

/// Linea IDEALE: ogni fetta di lavoro aggiunge target * peso / pesi lavoro;
/// fette non lavoro = piatto. Ultima fetta di lavoro = [target] esatto.
/// Nessun giorno di lavoro -> lista vuota.
List<PuntoLinea> lineaIdeale(
  List<FetteGiorno> fette, {
  double target = targetPredefinito,
}) {
  final List<FetteGiorno> usa = _finoUltima(fette);
  final double tot = _pesoLavoro(usa);
  if (tot <= 0) {
    return <PuntoLinea>[];
  }
  final List<PuntoLinea> out = <PuntoLinea>[];
  double fatto = 0;
  for (int i = 0; i < usa.length; i++) {
    final FetteGiorno f = usa[i];
    if (f.lavoro) {
      fatto += f.peso;
    }
    final double v = i == usa.length - 1 ? target : target * fatto / tot;
    out
      ..add(PuntoLinea(f.inizio, v))
      ..add(PuntoLinea(f.fine, v));
  }
  return out;
}

/// Ultima % settimanale nota a [t]: lettura più recente con sett in
/// [da, t] (letture prima di [da] = settimana vecchia, ignorate).
/// Nessuna -> 0 (dopo il reset si parte da 0). Nessuna interpolazione.
double settNota(List<Lettura> letture, DateTime t, {DateTime? da}) {
  double v = 0;
  DateTime? piuRecente;
  for (final Lettura l in letture) {
    final double? s = l.sett;
    if (s == null || l.ora.isAfter(t) || (da != null && l.ora.isBefore(da))) {
      continue;
    }
    if (piuRecente == null || !l.ora.isBefore(piuRecente)) {
      piuRecente = l.ora;
      v = s;
    }
  }
  return v;
}

/// Stato adattivo a un istante (risultato interno, anche per la UI).
class StatoAdattivo {
  /// Crea lo stato.
  const StatoAdattivo({
    required this.ora,
    required this.sett,
    required this.indice,
    required this.frazioneRestante,
    required this.giorniRimasti,
    required this.quota,
  });

  /// Istante usato (dentro la settimana).
  final DateTime ora;

  /// % settimanale nota a [ora].
  final double sett;

  /// Fetta corrente.
  final int indice;

  /// Parte della fetta corrente ancora da passare (0-1).
  final double frazioneRestante;

  /// Giorni di lavoro rimasti (pesi), fetta corrente solo per la parte
  /// restante.
  final double giorniRimasti;

  /// % settimanale per giorno di lavoro intero da qui in poi (>= 0).
  final double quota;
}

/// Stato adattivo a [ora] (null = piano finito o senza lavoro).
/// [ora] prima del reset -> inizio settimana. restante = target - sett(t)
/// (mai sotto 0); quota = restante / giorni lavoro rimasti.
StatoAdattivo? statoAdattivo(
  List<FetteGiorno> fette,
  List<Lettura> letture, {
  required DateTime ora,
  double target = targetPredefinito,
}) {
  final List<FetteGiorno> usa = _finoUltima(fette);
  if (usa.isEmpty || !ora.isBefore(usa.last.fine)) {
    return null;
  }
  final DateTime t = ora.isBefore(usa.first.inizio) ? usa.first.inizio : ora;
  final int c = indiceFetta(usa, t);
  final FetteGiorno fc = usa[c];
  final double durata = fc.fine.difference(fc.inizio).inMicroseconds.toDouble();
  final double resta = durata <= 0
      ? 0
      : fc.fine.difference(t).inMicroseconds / durata;
  double rimasti = fc.lavoro ? fc.peso * resta : 0;
  rimasti += _pesoLavoro(usa.sublist(c + 1));
  final double s = settNota(letture, t, da: usa.first.inizio);
  final double restante = target - s > 0 ? target - s : 0;
  return StatoAdattivo(
    ora: t,
    sett: s,
    indice: c,
    frazioneRestante: resta,
    giorniRimasti: rimasti,
    quota: rimasti > 0 ? restante / rimasti : 0,
  );
}

/// Quota adattiva a [ora] (% sett per giorno di lavoro intero); 0 se piano
/// finito, senza lavoro o target già raggiunto.
double quotaAdattiva(
  List<FetteGiorno> fette,
  List<Lettura> letture, {
  required DateTime ora,
  double target = targetPredefinito,
}) => statoAdattivo(fette, letture, ora: ora, target: target)?.quota ?? 0;

/// Linea ADATTIVA da [ora] (predefinita: ora dell'ultima lettura) a fine
/// piano. Primo punto (t, sett nota); poi fetta corrente con il limite a
/// fine fetta (solo parte restante), poi le fette dopo a gradino. Ultima
/// fetta di lavoro = [target] (o sett se già sopra). Piano finito -> vuota.
List<PuntoLinea> lineaAdattiva(
  List<FetteGiorno> fette,
  List<Lettura> letture, {
  DateTime? ora,
  double target = targetPredefinito,
}) {
  DateTime? t = ora;
  if (t == null) {
    for (final Lettura l in letture) {
      if (t == null || l.ora.isAfter(t)) {
        t = l.ora;
      }
    }
  }
  final List<FetteGiorno> usa = _finoUltima(fette);
  if (usa.isEmpty) {
    return <PuntoLinea>[];
  }
  final StatoAdattivo? st = statoAdattivo(
    usa,
    letture,
    ora: t ?? usa.first.inizio,
    target: target,
  );
  if (st == null) {
    return <PuntoLinea>[];
  }
  final double fineValore = st.sett > target ? st.sett : target;
  final FetteGiorno fc = usa[st.indice];
  double v = st.sett;
  if (fc.lavoro) {
    v += st.quota * fc.peso * st.frazioneRestante;
  }
  if (st.indice == usa.length - 1) {
    v = fineValore;
  }
  final List<PuntoLinea> out = <PuntoLinea>[
    PuntoLinea(st.ora, st.sett),
    PuntoLinea(st.ora, v),
    PuntoLinea(fc.fine, v),
  ];
  for (int i = st.indice + 1; i < usa.length; i++) {
    final FetteGiorno f = usa[i];
    if (f.lavoro) {
      v += st.quota * f.peso;
    }
    if (i == usa.length - 1) {
      v = fineValore;
    }
    out
      ..add(PuntoLinea(f.inizio, v))
      ..add(PuntoLinea(f.fine, v));
  }
  return out;
}
