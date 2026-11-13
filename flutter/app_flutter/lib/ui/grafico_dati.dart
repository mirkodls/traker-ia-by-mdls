// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui: dati del grafico già pronti (calcolati 1 volta fuori da paint)
// e geometria tempo/valore <-> pixel. Dart puro, testato.
import 'dart:math' as math;

import 'package:traker_ia/domain/analisi.dart';
import 'package:traker_ia/domain/coppie.dart';
import 'package:traker_ia/domain/lavoro.dart';
import 'package:traker_ia/domain/modelli.dart';

/// Punto di una linea del grafico.
class PuntoG {
  /// Crea un punto.
  const PuntoG(this.ora, this.valore, {this.manuale = false});

  /// Ora.
  final DateTime ora;

  /// Valore %.
  final double valore;

  /// Lettura non automatica (cerchietto vuoto).
  final bool manuale;
}

/// Nota da disegnare.
class NotaG {
  /// Crea la nota.
  const NotaG(this.numero, this.ora, this.testo);

  /// Numero (contando tutte le note, dalla prima).
  final int numero;

  /// Ora.
  final DateTime ora;

  /// Testo.
  final String testo;
}

/// Tutto quello che serve per disegnare grafico e intensità.
class DatiGrafico {
  /// Crea i dati.
  const DatiGrafico({
    required this.da,
    required this.a,
    required this.sett,
    required this.sess,
    required this.reset,
    required this.fasce,
    required this.note,
    required this.intensita,
    required this.maxIntensita,
  });

  /// Inizio asse tempo.
  final DateTime da;

  /// Fine asse tempo.
  final DateTime a;

  /// Linea settimanale (un punto prima di [da] e uno dopo [a] se ci sono).
  final List<PuntoG> sett;

  /// Linea sessione 5 ore.
  final List<PuntoG> sess;

  /// Reset dentro [da, a].
  final List<DateTime> reset;

  /// Periodi di lavoro tagliati su [da, a].
  final List<Periodo> fasce;

  /// Note dentro [da, a].
  final List<NotaG> note;

  /// Serie intensità.
  final List<PuntoSerie> intensita;

  /// Valore massimo dell'asse intensità (almeno 1).
  final double maxIntensita;

  /// Vero se non c'è nessuna lettura da disegnare.
  bool get vuoto => sett.isEmpty && sess.isEmpty;
}

bool _dentro(DateTime t, DateTime da, DateTime a) =>
    !t.isBefore(da) && !t.isAfter(a);

List<PuntoG> _linea(List<Lettura> ls, Campo campo, DateTime da, DateTime a) {
  final List<Lettura> pts = ls
      .where((Lettura l) => l.valore(campo) != null)
      .toList();
  final List<PuntoG> out = <PuntoG>[];
  Lettura? prima;
  for (final Lettura l in pts) {
    if (l.ora.isBefore(da)) {
      prima = l;
    } else if (!l.ora.isAfter(a)) {
      if (prima != null && out.isEmpty) {
        out.add(PuntoG(prima.ora, prima.valore(campo)!));
      }
      out.add(PuntoG(l.ora, l.valore(campo)!, manuale: l.fonte != 'auto'));
    } else {
      if (out.isEmpty && prima != null) {
        out.add(PuntoG(prima.ora, prima.valore(campo)!));
      }
      out.add(PuntoG(l.ora, l.valore(campo)!));
      break;
    }
  }
  return out;
}

/// Passo (minuti) della serie intensità: max ~240 punti, almeno 5 minuti.
int passoIntensita(DateTime da, DateTime a) =>
    math.max(5, a.difference(da).inMinutes ~/ 240);

/// Calcola i dati del grafico per l'intervallo [da, a].
DatiGrafico calcolaDatiGrafico(
  List<Lettura> letture,
  List<Evento> eventi,
  DateTime da,
  DateTime a,
  DateTime adesso,
) {
  final List<Lettura> ls = ordinaLetture(letture);
  final Set<DateTime> rs = <DateTime>{
    ...trovaReset(ls, Campo.sett),
    ...trovaReset(ls, Campo.sess),
    for (final Evento e in eventi)
      if (e.tipo == TipoEvento.reset) e.ora,
  };
  final List<DateTime> reset =
      rs.where((DateTime t) => _dentro(t, da, a)).toList()..sort();
  final List<Periodo> fasce = <Periodo>[
    for (final Periodo p in periodiLavoro(eventi, adesso))
      if (p.fine.isAfter(da) && p.inizio.isBefore(a))
        (
          inizio: p.inizio.isBefore(da) ? da : p.inizio,
          fine: p.fine.isAfter(a) ? a : p.fine,
        ),
  ];
  final List<NotaG> note = <NotaG>[];
  int n = 0;
  for (final Evento e in ordinaEventi(eventi)) {
    if (e.tipo != TipoEvento.nota) {
      continue;
    }
    n++;
    if (_dentro(e.ora, da, a)) {
      note.add(NotaG(n, e.ora, e.testo));
    }
  }
  final List<PuntoSerie> inten = serieIntensita(
    ls,
    da,
    a,
    passoMin: passoIntensita(da, a),
  );
  double top = 1;
  for (final PuntoSerie p in inten) {
    final double? v = p.valore;
    if (v != null && v > top) {
      top = v;
    }
  }
  return DatiGrafico(
    da: da,
    a: a,
    sett: _linea(ls, Campo.sett, da, a),
    sess: _linea(ls, Campo.sess, da, a),
    reset: reset,
    fasce: fasce,
    note: note,
    intensita: inten,
    maxIntensita: top,
  );
}

/// Geometria di un grafico: tempo/valore <-> pixel.
class Geometria {
  /// Crea la geometria. Margini: sinistro [l], destro [r], alto [t], basso [b].
  const Geometria({
    required this.larg,
    required this.alt,
    required this.da,
    required this.a,
    this.l = 48,
    this.r = 18,
    this.t = 46,
    this.b = 30,
    this.max = 100,
  });

  /// Larghezza totale.
  final double larg;

  /// Altezza totale.
  final double alt;

  /// Inizio tempo.
  final DateTime da;

  /// Fine tempo.
  final DateTime a;

  /// Margine sinistro.
  final double l;

  /// Margine destro.
  final double r;

  /// Margine alto.
  final double t;

  /// Margine basso.
  final double b;

  /// Valore in cima all'asse.
  final double max;

  /// Microsecondi dell'asse (mai 0).
  int get _span => math.max(1, a.difference(da).inMicroseconds);

  /// Larghezza utile.
  double get utile => larg - l - r;

  /// Ora -> x.
  double x(DateTime d) => l + d.difference(da).inMicroseconds / _span * utile;

  /// Valore -> y.
  double y(double v) => t + (1 - v / max) * (alt - t - b);

  /// x -> ora (null se fuori dall'area utile).
  DateTime? tempo(double px) {
    if (utile <= 0 || px < l || px > larg - r) {
      return null;
    }
    return da.add(Duration(microseconds: ((px - l) / utile * _span).round()));
  }

  /// Vero se il grafico ha spazio per essere disegnato.
  bool get disegnabile => utile > 20 && alt - t - b > 10;
}

/// Posto di una nota: x e centro del cerchio (note vicine scendono).
typedef PostoNota = ({NotaG nota, double x, double cy});

/// Posti dei cerchi delle note.
List<PostoNota> postiNote(List<NotaG> note, Geometria g) {
  final List<PostoNota> out = <PostoNota>[];
  for (final NotaG n in note) {
    final double x = g.x(n.ora);
    final int livello = out.where((PostoNota p) => (p.x - x).abs() < 20).length;
    out.add((nota: n, x: x, cy: g.t - 9 + livello * 21));
  }
  return out;
}

/// Nota sotto il mouse ([mx], [my]): sul cerchio o lungo la linea.
NotaG? notaVicina(List<PostoNota> posti, double mx, double my) {
  PostoNota? best;
  double bd = double.infinity;
  for (final PostoNota p in posti) {
    if ((p.x - mx).abs() < 12 && (p.cy - my).abs() < 12) {
      final double d =
          math.pow(p.x - mx, 2) + math.pow(p.cy - my, 2).toDouble();
      if (d < bd) {
        bd = d;
        best = p;
      }
    }
  }
  if (best != null) {
    return best.nota;
  }
  for (final PostoNota p in posti) {
    final double d = (p.x - mx).abs();
    if (d < 6 && d < bd) {
      bd = d;
      best = p;
    }
  }
  return best?.nota;
}

/// Aggancia [t] alla lettura vera più vicina entro [tolMicro] microsecondi.
DateTime agganciaLettura(
  List<Lettura> letture,
  DateTime t,
  int tolMicro,
  DateTime da,
  DateTime a,
) {
  DateTime best = t;
  int bd = tolMicro + 1;
  for (final Lettura l in letture) {
    final int d = l.ora.difference(t).inMicroseconds.abs();
    if (d < bd && _dentro(l.ora, da, a)) {
      bd = d;
      best = l.ora;
    }
  }
  return best;
}
