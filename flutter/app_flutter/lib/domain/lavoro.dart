// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: periodi di lavoro (Inizio -> Fine) per "Conta solo lavoro".
import 'coppie.dart';
import 'modelli.dart';

/// Eventi inizio/fine -> periodi. Periodo ancora aperto = fino a [fino].
/// 'inizio' doppio ignorato; 'fine' senza inizio ignorato.
List<Periodo> periodiLavoro(Iterable<Evento> eventi, DateTime fino) {
  final List<Periodo> out = <Periodo>[];
  DateTime? aperto;
  final Iterable<Evento> utili = eventi.where(
    (Evento e) => e.tipo == TipoEvento.inizio || e.tipo == TipoEvento.fine,
  );
  for (final Evento e in ordinaEventi(utili)) {
    if (e.tipo == TipoEvento.inizio && aperto == null) {
      aperto = e.ora;
    } else if (e.tipo == TipoEvento.fine && aperto != null) {
      if (e.ora.isAfter(aperto)) {
        out.add((inizio: aperto, fine: e.ora));
      }
      aperto = null;
    }
  }
  if (aperto != null && fino.isAfter(aperto)) {
    out.add((inizio: aperto, fine: fino));
  }
  return out;
}

/// Vero se [t] cade dentro un periodo di lavoro.
bool inLavoro(List<Periodo> periodi, DateTime t) => periodi.any(
  (Periodo p) => !t.isBefore(p.inizio) && t.isBefore(p.fine),
);
