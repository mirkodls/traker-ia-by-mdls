// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui: grafico principale e grafico intensità (CustomPainter, zero
// pacchetti). Mouse/dito sulla linea: riga verticale su tutti e due + riquadro
// che non viene mai tagliato (sta sopra tutta la finestra).
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/analisi.dart';
import 'package:traker_ia/domain/combinazioni.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/riordino.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/grafico_dati.dart';
import 'package:traker_ia/ui/tema.dart';

/// Margini del grafico intensità.
Geometria geometriaIntensita(Size s, DatiGrafico d) => Geometria(
  larg: s.width,
  alt: s.height,
  da: d.da,
  a: d.a,
  t: 20,
  b: 8,
  max: d.maxIntensita,
);

/// Margini del grafico principale.
Geometria geometriaPrincipale(Size s, DatiGrafico d) =>
    Geometria(larg: s.width, alt: s.height, da: d.da, a: d.a);

// ------------------------------------------------------------------ riquadro

// ------------------------------------------------------------------ mouse

/// Stato del mouse condiviso tra i due grafici.
class MouseGrafici extends ValueNotifier<DateTime?> {
  /// Crea lo stato (nessuna ora sotto il mouse).
  MouseGrafici() : super(null);

  /// Riquadro unico per tutti e due i grafici.
  final RiquadroGrafici riquadro = RiquadroGrafici();

  @override
  void dispose() {
    riquadro.nascondi();
    super.dispose();
  }
}

/// Riquadro che si ricostruisce col contenuto nuovo.
class RiquadroGrafici {
  OverlayEntry? _voce;
  Widget _figlio = const SizedBox.shrink();

  static const TextStyle _stile = TextStyle(
    color: Colori.testo,
    fontSize: Misure.normale,
    height: 1.3,
  );

  /// Mostra [testo] vicino a [globale].
  void mostra(
    BuildContext context,
    Offset globale,
    String testo, {
    Color bordo = Colori.spento,
    double? larghezza,
  }) {
    final OverlayState ov = Overlay.of(context);
    final RenderObject? ro = ov.context.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) {
      return;
    }
    final Size area = ro.size;
    final Offset locale = ro.globalToLocal(globale);
    final TextPainter tp = TextPainter(
      text: TextSpan(text: testo, style: _stile),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: larghezza ?? math.max(100, area.width - 40));
    final double w = tp.width + 20;
    final double h = tp.height + 16;
    tp.dispose();
    final ({double x, double y, bool entra}) p = posizionaRiquadro(
      locale.dx,
      locale.dy,
      w,
      h,
      area.width,
      area.height,
    );
    final double x = p.x.clamp(0, math.max(0, area.width - w)).toDouble();
    final double y = p.y.clamp(0, math.max(0, area.height - h)).toDouble();
    _figlio = Positioned(
      left: x,
      top: y,
      child: IgnorePointer(
        child: Container(
          width: w,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colori.carta2,
            border: Border.all(color: bordo),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(testo, style: _stile),
        ),
      ),
    );
    final OverlayEntry? v = _voce;
    if (v == null) {
      final OverlayEntry nuova = OverlayEntry(builder: (_) => _figlio);
      _voce = nuova;
      ov.insert(nuova);
    } else {
      v.markNeedsBuild();
    }
  }

  /// Nasconde il riquadro.
  void nascondi() {
    final OverlayEntry? v = _voce;
    _voce = null;
    if (v != null) {
      v.remove();
      v.dispose();
    }
  }
}

/// Testo del riquadro all'ora [t].
String testoMouse(List<Lettura> letture, DateTime t) {
  String riga(String nome, ValoreA v, String unita) => Testi.rigaValore(
    nome,
    v.valore == null
        ? Testi.trattino
        : '${v.esatto ? '' : '~'}${numero(v.valore, dec: 1)}$unita',
  );
  final ValoreA sett = valoreA(letture, Campo.sett, t);
  final ValoreA sess = valoreA(letture, Campo.sess, t);
  final double? inte = intensitaA(letture, t);
  final List<String> righe = <String>[
    quandoData(t),
    riga(Testi.rqSett, sett, '%'),
    riga(Testi.rqSess, sess, '%'),
    riga(Testi.rqIntensita, ValoreA(inte, esatto: sess.esatto), ' pt/h'),
  ];
  final Combo? c = statoA(letture, t);
  if (c != null) {
    String nomi(String s) =>
        s.isEmpty ? Testi.trattino : s.replaceAll('|', ', ');
    righe
      ..add(Testi.rigaValore(Testi.rqModelli, nomi(c.modelli)))
      ..add(Testi.rigaValore(Testi.rqSkill, nomi(c.skill)));
  }
  return righe.join('\n');
}

// ------------------------------------------------------------------ widget

/// Tipo di grafico.
enum TipoGrafico {
  /// Grafico principale (% settimana e sessione).
  principale,

  /// Grafico piccolo intensità.
  intensita,
}

/// Uno dei due grafici, con mouse/dito.
class Grafico extends StatefulWidget {
  /// Crea il grafico.
  const Grafico({
    required this.tipo,
    required this.dati,
    required this.letture,
    required this.mouse,
    super.key,
  });

  /// Quale grafico.
  final TipoGrafico tipo;

  /// Dati già pronti.
  final DatiGrafico dati;

  /// Letture (per valori sotto il mouse).
  final List<Lettura> letture;

  /// Mouse condiviso.
  final MouseGrafici mouse;

  @override
  State<Grafico> createState() => _StatoGrafico();
}

class _StatoGrafico extends State<Grafico> {
  Size _taglia = Size.zero;

  Geometria _geo() => widget.tipo == TipoGrafico.principale
      ? geometriaPrincipale(_taglia, widget.dati)
      : geometriaIntensita(_taglia, widget.dati);

  void _muovi(Offset locale, Offset globale) {
    final Geometria g = _geo();
    if (!g.disegnabile) {
      return;
    }
    if (widget.tipo == TipoGrafico.principale) {
      final NotaG? n = notaVicina(
        postiNote(widget.dati.note, g),
        locale.dx,
        locale.dy,
      );
      if (n != null) {
        widget.mouse.value = null;
        widget.mouse.riquadro.mostra(
          context,
          globale,
          '${quandoData(n.ora)}\n${n.testo}',
          bordo: Colori.nota,
          larghezza: 280,
        );
        return;
      }
    }
    final DateTime? t0 = g.tempo(locale.dx);
    if (t0 == null) {
      _esci();
      return;
    }
    final int microPx =
        (g.a.difference(g.da).inMicroseconds / math.max(1, g.utile)).round();
    final DateTime t = agganciaLettura(
      widget.letture,
      t0,
      6 * microPx,
      g.da,
      g.a,
    );
    widget.mouse.value = t;
    widget.mouse.riquadro.mostra(
      context,
      globale,
      testoMouse(widget.letture, t),
    );
  }

  void _esci() {
    widget.mouse.value = null;
    widget.mouse.riquadro.nascondi();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        _taglia = Size(c.maxWidth, c.maxHeight);
        final CustomPainter pittore = widget.tipo == TipoGrafico.principale
            ? PittorePrincipale(widget.dati)
            : PittoreIntensita(widget.dati);
        return MouseRegion(
          onHover: (PointerHoverEvent e) => _muovi(e.localPosition, e.position),
          onExit: (_) => _esci(),
          child: GestureDetector(
            onLongPressStart: (LongPressStartDetails d) =>
                _muovi(d.localPosition, d.globalPosition),
            onLongPressMoveUpdate: (LongPressMoveUpdateDetails d) =>
                _muovi(d.localPosition, d.globalPosition),
            onLongPressEnd: (_) => _esci(),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                RepaintBoundary(child: CustomPaint(painter: pittore)),
                CustomPaint(
                  painter: PittoreMouse(widget.mouse, widget.dati, widget.tipo),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------------ pittori

void _testo(
  Canvas c,
  String s,
  Offset p, {
  Color colore = Colori.spento,
  double misura = Misure.piccolo,
  bool grassetto = false,
  double ancoraX = 0,
  double ancoraY = 0.5,
}) {
  final TextPainter tp = TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        color: colore,
        fontSize: misura,
        fontWeight: grassetto ? FontWeight.bold : FontWeight.normal,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, p - Offset(tp.width * ancoraX, tp.height * ancoraY));
  tp.dispose();
}

double _larghezzaTesto(String s) {
  final TextPainter tp = TextPainter(
    text: TextSpan(text: s, style: stilePiccolo),
    textDirection: TextDirection.ltr,
  )..layout();
  final double w = tp.width;
  tp.dispose();
  return w;
}

void _tratteggio(
  Canvas c,
  Offset a,
  Offset b,
  Paint p, {
  double pieno = 3,
  double vuoto = 4,
}) {
  final double tot = (b - a).distance;
  if (tot <= 0) {
    return;
  }
  final Offset dir = (b - a) / tot;
  double s = 0;
  while (s < tot) {
    final double e = math.min(s + pieno, tot);
    c.drawLine(a + dir * s, a + dir * e, p);
    s = e + vuoto;
  }
}

String _etichettaTempo(DateTime d, bool corto) {
  final String hm = formatta(d).substring(11);
  return corto
      ? hm
      : '${giorniBrevi[d.weekday - 1]} ${d.day.toString().padLeft(2, '0')} $hm';
}

/// Disegna il grafico principale.
class PittorePrincipale extends CustomPainter {
  /// Crea il pittore.
  PittorePrincipale(this.dati);

  /// Dati.
  final DatiGrafico dati;

  @override
  void paint(Canvas c, Size s) {
    final Geometria g = geometriaPrincipale(s, dati);
    if (!g.disegnabile) {
      return;
    }
    final double y0 = g.t;
    final double y1 = s.height - g.b;
    final double xr = s.width - g.r;

    // legenda
    double lx = g.l;
    for (final (String, Color) v in <(String, Color)>[
      (Testi.legSett, Colori.sett),
      (Testi.legSess, Colori.sess),
      (Testi.legNota, Colori.nota),
      (Testi.legReset, Colori.reset),
      (Testi.legLavoro, Colori.lavoroLegenda),
    ]) {
      final double w = 26 + _larghezzaTesto(v.$1);
      if (lx + w - 12 > xr) {
        break; // finestra stretta: la legenda si ferma, niente testo tagliato
      }
      c.drawCircle(Offset(lx + 5, 15), 5, Paint()..color = v.$2);
      _testo(c, v.$1, Offset(lx + 14, 15));
      lx += w;
    }
    if (xr - lx > 300) {
      _testo(
        c,
        Testi.aiutoNote,
        Offset(xr, 15),
        colore: Colori.reset,
        ancoraX: 1,
      );
    }

    // fasce lavoro
    final Paint fl = Paint()..color = Colori.lavoro;
    for (final ({DateTime inizio, DateTime fine}) p in dati.fasce) {
      c.drawRect(Rect.fromLTRB(g.x(p.inizio), y0, g.x(p.fine), y1), fl);
    }

    // griglia
    final Paint gr = Paint()..color = Colori.griglia;
    for (int v = 0; v <= 100; v += 25) {
      final double y = g.y(v.toDouble());
      c.drawLine(Offset(g.l, y), Offset(xr, y), gr);
      _testo(c, '$v%', Offset(g.l - 8, y), ancoraX: 1);
    }
    final int spanMin = dati.a.difference(dati.da).inMinutes;
    final bool corto = spanMin <= 26 * 60;
    final int n = math.max(2, math.min(7, g.utile ~/ 110));
    for (int i = 0; i <= n; i++) {
      final DateTime d = dati.da.add(
        Duration(minutes: (spanMin * i / n).round()),
      );
      _testo(
        c,
        _etichettaTempo(d, corto),
        Offset(g.x(d), y1 + 15),
        ancoraX: i == 0 ? 0 : (i == n ? 1 : 0.5),
      );
    }

    // reset
    final Paint pr = Paint()
      ..color = Colori.reset
      ..strokeWidth = 1;
    for (final DateTime r in dati.reset) {
      final double x = g.x(r);
      _tratteggio(c, Offset(x, y0), Offset(x, y1), pr);
    }

    if (dati.vuoto) {
      _testo(
        c,
        Testi.graficoVuoto,
        Offset(g.l + g.utile / 2, (y0 + y1) / 2),
        ancoraX: 0.5,
      );
    }

    // linee
    _serie(c, g, dati.sett, Colori.sett, area: true);
    _serie(c, g, dati.sess, Colori.sess);

    // note
    final Paint pn = Paint()
      ..color = Colori.nota
      ..strokeWidth = 1.5;
    for (final PostoNota p in postiNote(dati.note, g)) {
      _tratteggio(
        c,
        Offset(p.x, y0 - 8),
        Offset(p.x, y1),
        pn,
        pieno: 6,
        vuoto: 3,
      );
      c.drawCircle(Offset(p.x, p.cy), 10, Paint()..color = Colori.carta);
      c.drawCircle(Offset(p.x, p.cy), 8.5, Paint()..color = Colori.nota);
      _testo(
        c,
        '${p.nota.numero}',
        Offset(p.x, p.cy),
        colore: Colors.white,
        misura: 10.5,
        grassetto: true,
        ancoraX: 0.5,
      );
    }
  }

  void _serie(
    Canvas c,
    Geometria g,
    List<PuntoG> pts,
    Color col, {
    bool area = false,
  }) {
    if (pts.isEmpty) {
      return;
    }
    final double xl = g.l;
    final double xr = g.larg - g.r;
    double cx(DateTime t) => g.x(t).clamp(xl, xr).toDouble();
    final Path linea = Path()..moveTo(cx(pts.first.ora), g.y(pts.first.valore));
    for (final PuntoG p in pts.skip(1)) {
      linea.lineTo(cx(p.ora), g.y(p.valore));
    }
    if (pts.length > 1) {
      if (area) {
        final Path a = Path.from(linea)
          ..lineTo(cx(pts.last.ora), g.y(0))
          ..lineTo(cx(pts.first.ora), g.y(0))
          ..close();
        c.drawPath(a, Paint()..color = Colori.settArea);
      }
      c.drawPath(
        linea,
        Paint()
          ..color = col
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    bool dentro(DateTime t) => !t.isBefore(dati.da) && !t.isAfter(dati.a);
    final Paint vuoto = Paint()..color = Colori.carta;
    final Paint bordo = Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    PuntoG? ult;
    for (final PuntoG p in pts) {
      if (!dentro(p.ora)) {
        continue;
      }
      ult = p;
      if (p.manuale) {
        final Offset o = Offset(g.x(p.ora), g.y(p.valore));
        c
          ..drawCircle(o, 3.5, vuoto)
          ..drawCircle(o, 3.5, bordo);
      }
    }
    if (ult != null) {
      final Offset o = Offset(g.x(ult.ora), g.y(ult.valore));
      c
        ..drawCircle(o, 7, bordo..strokeWidth = 1)
        ..drawCircle(o, 4, Paint()..color = col);
      _testo(
        c,
        percento(ult.valore),
        o + const Offset(-10, -12),
        colore: col,
        misura: Misure.normale,
        grassetto: true,
        ancoraX: 1,
      );
    }
  }

  @override
  bool shouldRepaint(PittorePrincipale old) => !identical(old.dati, dati);
}

/// Disegna il grafico intensità.
class PittoreIntensita extends CustomPainter {
  /// Crea il pittore.
  PittoreIntensita(this.dati);

  /// Dati.
  final DatiGrafico dati;

  @override
  void paint(Canvas c, Size s) {
    final Geometria g = geometriaIntensita(s, dati);
    if (!g.disegnabile) {
      return;
    }
    final double xr = s.width - g.r;
    _testo(c, Testi.titoloIntensita, Offset(g.l, 9));
    final Paint gr = Paint()..color = Colori.griglia;
    for (final double v in <double>[0, g.max]) {
      final double y = g.y(v);
      c.drawLine(Offset(g.l, y), Offset(xr, y), gr);
      _testo(c, v.toStringAsFixed(0), Offset(g.l - 8, y), ancoraX: 1);
    }
    final Paint p = Paint()
      ..color = Colori.sess
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Path? seg;
    int punti = 0;
    void chiudi() {
      if (seg != null && punti >= 2) {
        c.drawPath(seg!, p);
      }
      seg = null;
      punti = 0;
    }

    for (final PuntoSerie ps in dati.intensita) {
      final double? v = ps.valore;
      if (v == null) {
        chiudi();
        continue;
      }
      final Offset o = Offset(g.x(ps.ora), g.y(v));
      if (seg == null) {
        seg = Path()..moveTo(o.dx, o.dy);
      } else {
        seg!.lineTo(o.dx, o.dy);
      }
      punti++;
    }
    chiudi();
  }

  @override
  bool shouldRepaint(PittoreIntensita old) => !identical(old.dati, dati);
}

/// Riga verticale del mouse (si ridisegna solo lei quando il mouse si muove).
class PittoreMouse extends CustomPainter {
  /// Crea il pittore.
  PittoreMouse(this.mouse, this.dati, this.tipo) : super(repaint: mouse);

  /// Mouse condiviso.
  final MouseGrafici mouse;

  /// Dati (per l'asse del tempo).
  final DatiGrafico dati;

  /// Quale grafico.
  final TipoGrafico tipo;

  @override
  void paint(Canvas c, Size s) {
    final DateTime? t = mouse.value;
    if (t == null) {
      return;
    }
    final Geometria g = tipo == TipoGrafico.principale
        ? geometriaPrincipale(s, dati)
        : geometriaIntensita(s, dati);
    if (!g.disegnabile) {
      return;
    }
    final double x = g.x(t);
    _tratteggio(
      c,
      Offset(x, 0),
      Offset(x, s.height),
      Paint()
        ..color = Colori.spento
        ..strokeWidth = 1,
      pieno: 2,
      vuoto: 3,
    );
  }

  @override
  bool shouldRepaint(PittoreMouse old) =>
      !identical(old.dati, dati) || old.mouse != mouse;
}
