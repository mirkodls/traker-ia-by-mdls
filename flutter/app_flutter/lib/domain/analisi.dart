// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: risposta del gestore, reset, intensità, % stimata, verdetto.
import 'coppie.dart';
import 'modelli.dart';
import 'tempo.dart';

/// Verdetto di un confronto tra due ritmi.
enum Verdetto {
  /// Il secondo ritmo è almeno il 10% più basso.
  sceso('SCESO'),

  /// Il secondo ritmo è almeno il 10% più alto.
  salito('SALITO'),

  /// Differenza sotto il 10%.
  costante('COSTANTE'),

  /// Dati mancanti o troppo pochi.
  datoDebole('DATO DEBOLE');

  const Verdetto(this.etichetta);

  /// Testo mostrato.
  final String etichetta;
}

final RegExp _troppeCifre = RegExp(r'(\.\d{6})\d+');
final RegExp _fuso = RegExp(r'(Z|z|[+-]\d{2}:?\d{2})$');

/// Data ISO del gestore (UTC se senza fuso) -> ora locale al minuto.
DateTime? dataUtcALocale(Object? s) {
  if (s is! String || s.trim().isEmpty) {
    return null;
  }
  String t = s.trim().replaceFirstMapped(_troppeCifre, (Match m) => m.group(1)!);
  if (!_fuso.hasMatch(t)) {
    t = '${t}Z';
  }
  final DateTime? d = DateTime.tryParse(t);
  return d == null ? null : alMinuto(d.toLocal());
}

/// Risposta /usage di Anthropic -> Uso. Valori in percento (0-100).
Uso leggiRisposta(Object? body) {
  (double?, DateTime?) blocco(String chiave) {
    final Object? v = body is Map<Object?, Object?> ? body[chiave] : null;
    if (v is! Map<Object?, Object?>) {
      return (null, null);
    }
    final Object? u = v['utilization'];
    return (u is num ? u.toDouble() : null, dataUtcALocale(v['resets_at']));
  }

  final (double?, DateTime?) b5 = blocco('five_hour');
  final (double?, DateTime?) b7 = blocco('seven_day');
  double? sess = b5.$1;
  double? sett = b7.$1;
  // Fable da 'limits' è già in percento: fuori dalla scala 0-1.
  final double? fableLimiti = fableDaLimiti(body);
  double? fable = fableLimiti == null ? cercaFable(body) : null;
  // Alcune versioni danno frazioni 0-1: se tutti <= 1 e uno non intero, scala.
  final List<double> vals = <double>[?sess, ?sett, ?fable];
  if (vals.isNotEmpty &&
      vals.every((double x) => x <= 1) &&
      vals.any((double x) => x > 0 && x < 1)) {
    sess = sess == null ? null : sess * 100;
    sett = sett == null ? null : sett * 100;
    fable = fable == null ? null : fable * 100;
  }
  return Uso(
    sess: sess,
    sett: sett,
    fable: fableLimiti ?? fable,
    resetSess: b5.$2,
    resetSett: b7.$2,
  );
}

/// Parole che indicano ripristino/reimpostazione del limite: da ignorare.
const List<String> _paroleRipristino = <String>[
  'reset',
  'ripristin',
  'reimpost',
];

/// Campi che possono contenere il nome di una voce (es. 'Fable').
const List<String> _campiNome = <String>[
  'name',
  'model',
  'label',
  'display_name',
  'title',
  'type',
  'id',
];

bool _eRipristino(String s) {
  final String t = s.toLowerCase();
  return _paroleRipristino.any(t.contains);
}

double? _utilizzo(Object? v) {
  if (v is! Map<Object?, Object?>) {
    return null;
  }
  final Object? u = v['utilization'];
  return u is num ? u.toDouble() : null;
}

/// % Fable dall'elenco 'limits' (forma vera di claude.ai, 20/11/2026):
/// voce con scope.model.display_name 'Fable' e 'percent' (già 0-100).
/// Voci di ripristino ignorate. Niente voce -> null.
double? fableDaLimiti(Object? body) {
  final Object? ls = body is Map<Object?, Object?> ? body['limits'] : null;
  if (ls is! List<Object?>) {
    return null;
  }
  for (final Object? x in ls) {
    if (x is! Map<Object?, Object?>) {
      continue;
    }
    final Object? kind = x['kind'];
    if (kind is String && _eRipristino(kind)) {
      continue;
    }
    final Object? scope = x['scope'];
    final Object? model = scope is Map<Object?, Object?> ? scope['model'] : null;
    final Object? nome = model is Map<Object?, Object?>
        ? model['display_name']
        : null;
    final Object? p = x['percent'];
    if (nome is String &&
        nome.toLowerCase().contains('fable') &&
        !_eRipristino(nome) &&
        p is num) {
      return p.toDouble();
    }
  }
  return null;
}

/// % Fable nella risposta /usage (valore grezzo, prima della scala 0-1).
/// Trova: una chiave con 'fable' (es. 'seven_day_fable') con dentro
/// 'utilization', oppure una voce con nome 'Fable' e 'utilization'.
/// Ripristino/reimpostazione ignorati. Nessuna riga Fable -> null.
double? cercaFable(Object? body, {int profondita = 0}) {
  if (profondita > 3) {
    return null;
  }
  if (body is List<Object?>) {
    for (final Object? x in body) {
      final double? f = cercaFable(x, profondita: profondita + 1);
      if (f != null) {
        return f;
      }
    }
    return null;
  }
  if (body is! Map<Object?, Object?>) {
    return null;
  }
  // Voce con nome 'Fable' (dentro un elenco di limiti).
  if (profondita > 0) {
    final double? u = _utilizzo(body);
    if (u != null) {
      for (final String c in _campiNome) {
        final Object? n = body[c];
        if (n is String && n.toLowerCase().contains('fable')) {
          return _eRipristino(n) ? null : u;
        }
      }
    }
  }
  // Chiave con 'fable'.
  for (final MapEntry<Object?, Object?> e in body.entries) {
    final Object? k = e.key;
    if (k is String && k.toLowerCase().contains('fable') && !_eRipristino(k)) {
      final double? u = _utilizzo(e.value);
      if (u != null) {
        return u;
      }
    }
  }
  // Più in profondità (saltando ripristino e i blocchi già noti).
  for (final MapEntry<Object?, Object?> e in body.entries) {
    final Object? k = e.key;
    if (k is! String ||
        _eRipristino(k) ||
        k == 'five_hour' ||
        k == 'seven_day') {
      continue;
    }
    final Object? v = e.value;
    if (v is Map<Object?, Object?> || v is List<Object?>) {
      final double? f = cercaFable(v, profondita: profondita + 1);
      if (f != null) {
        return f;
      }
    }
  }
  return null;
}

/// Momenti in cui la barra [campo] scende (= reset).
List<DateTime> trovaReset(Iterable<Lettura> letture, Campo campo) {
  final List<DateTime> out = <DateTime>[];
  double? prec;
  for (final Lettura l in ordinaLetture(letture)) {
    final double? v = l.valore(campo);
    if (v == null) {
      continue;
    }
    if (prec != null && v < prec - sogliaReset) {
      out.add(l.ora);
    }
    prec = v;
  }
  return out;
}

/// Punto di una serie nel tempo (valore null = nessun dato).
class PuntoSerie {
  /// Crea un punto.
  const PuntoSerie(this.ora, this.valore);

  /// Ora del punto.
  final DateTime ora;

  /// Valore (null = buco).
  final double? valore;
}

/// Intensità: ritmo pt%/h della barra 5 ore, media mobile su [finestraMin],
/// reset esclusi. Un punto ogni [passoMin] in [da, a].
List<PuntoSerie> serieIntensita(
  Iterable<Lettura> letture,
  DateTime da,
  DateTime a, {
  int passoMin = 5,
  int finestraMin = 30,
}) {
  final List<PuntoSerie> out = <PuntoSerie>[];
  if (passoMin <= 0) {
    return out;
  }
  final List<Coppia> cs = coppie(letture, Campo.sess);
  final Duration finestra = Duration(minutes: finestraMin);
  final Duration passo = Duration(minutes: passoMin);
  int j = 0;
  DateTime t = da;
  while (!t.isAfter(a)) {
    final DateTime ini = t.subtract(finestra);
    while (j < cs.length && !cs[j].arrivo.ora.isAfter(ini)) {
      j++;
    }
    double d = 0;
    double h = 0;
    for (int k = j; k < cs.length && cs[k].partenza.ora.isBefore(t); k++) {
      final Coppia c = cs[k];
      final DateTime x = piuTardi(c.partenza.ora, ini);
      final DateTime y = piuPresto(c.arrivo.ora, t);
      if (y.isAfter(x)) {
        final double q = oreTra(x, y);
        d += c.punti * q / c.ore;
        h += q;
      }
    }
    out.add(PuntoSerie(t, h > 0 ? d / h : null));
    t = t.add(passo);
  }
  return out;
}

/// Intensità (pt%/h barra 5 ore, media mobile) all'ora [t].
double? intensitaA(Iterable<Lettura> letture, DateTime t, {int finestraMin = 30}) =>
    ritmo(
      letture,
      Campo.sess,
      da: t.subtract(Duration(minutes: finestraMin)),
      a: t,
    );

/// Valore della barra a un'ora: esatto = c'è una lettura vera lì.
class ValoreA {
  /// Crea il risultato.
  const ValoreA(this.valore, {required this.esatto});

  /// Valore (null = fuori dai dati o a cavallo di un reset).
  final double? valore;

  /// Vero se c'è una lettura vera a quell'ora (tra due letture = stima "~").
  final bool esatto;
}

/// Valore di [campo] all'ora [t]. Lettura vera entro ±[tolS] secondi ->
/// esatto; tra due letture -> interpolazione lineare; reset in mezzo -> null.
ValoreA valoreA(
  Iterable<Lettura> letture,
  Campo campo,
  DateTime t, {
  double tolS = 0,
}) {
  final List<Lettura> ls = ordinaLetture(
    letture.where((Lettura l) => l.valore(campo) != null),
  );
  for (final Lettura l in ls) {
    if (l.ora.difference(t).inMicroseconds.abs() <= tolS * 1e6) {
      return ValoreA(l.valore(campo), esatto: true);
    }
  }
  for (int i = 1; i < ls.length; i++) {
    final Lettura a = ls[i - 1];
    final Lettura b = ls[i];
    if (a.ora.isBefore(t) && t.isBefore(b.ora)) {
      final double va = a.valore(campo)!;
      final double vb = b.valore(campo)!;
      if (vb < va - sogliaReset) {
        return const ValoreA(null, esatto: false);
      }
      final double f = oreTra(a.ora, t) / oreTra(a.ora, b.ora);
      return ValoreA(va + (vb - va) * f, esatto: false);
    }
  }
  return const ValoreA(null, esatto: false);
}

/// Ritmo quando al PC e quando in automatico (solo coppie con al PC noto).
({double? alPc, double? automatico}) ritmoPerPresenza(
  Iterable<Lettura> letture, {
  Campo campo = Campo.sett,
}) {
  final List<double> acc = <double>[0, 0, 0, 0];
  for (final Coppia c in coppie(letture, campo)) {
    final bool? pc = c.arrivo.alPc;
    if (pc == null) {
      continue;
    }
    final int o = pc ? 0 : 2;
    acc[o] += c.punti;
    acc[o + 1] += c.ore;
  }
  return (
    alPc: acc[1] > 0 ? acc[0] / acc[1] : null,
    automatico: acc[3] > 0 ? acc[2] / acc[3] : null,
  );
}

/// Confronta due ritmi: ±[soglia] (10%). Un dato mancante -> dato debole.
Verdetto verdetto(double? prima, double? dopo, {double soglia = 0.10}) {
  if (prima == null || dopo == null) {
    return Verdetto.datoDebole;
  }
  if (prima == 0) {
    return dopo > 0 ? Verdetto.salito : Verdetto.costante;
  }
  final double r = (dopo - prima) / prima;
  if (r <= -soglia) {
    return Verdetto.sceso;
  }
  if (r >= soglia) {
    return Verdetto.salito;
  }
  return Verdetto.costante;
}
