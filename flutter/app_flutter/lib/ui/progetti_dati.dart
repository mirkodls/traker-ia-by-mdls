// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui (V2, B13): dati già pronti per la pagina Progetti. Dart puro,
// testato. Leggerezza: la lista delle settimane legge solo il RIASSUNTO
// dell'istantanea (senza decodificare le letture); il disegno completo
// (grafici salvati) si costruisce solo per la settimana aperta.
import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/archivio_settimane.dart';
import 'package:traker_ia/domain/intensita.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/progetti.dart';
import 'package:traker_ia/domain/serie_intensita.dart';
import 'package:traker_ia/domain/serie_piano.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/ui/grafico_dati.dart';

/// Colori proposti per i progetti (ARGB).
const List<int> coloriProgetto = <int>[
  0xFF60A5FA,
  0xFF34D399,
  0xFFFACC15,
  0xFFF472B6,
  0xFFA78BFA,
  0xFFFB923C,
  0xFF2DD4BF,
  0xFFF87171,
];

/// Colore di "Senza progetto" (ARGB).
const int coloreSenzaProgetto = 0xFF8B97AD;

/// Colore del progetto [id]: quello salvato, o uno della tavolozza (per id)
/// se non ne ha. [idSenzaProgetto] = grigio.
Color coloreProgetto(int id, Iterable<Progetto> progetti) {
  if (id == idSenzaProgetto) {
    return const Color(coloreSenzaProgetto);
  }
  for (final Progetto p in progetti) {
    if (p.id == id && p.colore != 0) {
      return Color(p.colore);
    }
  }
  return Color(coloriProgetto[id.abs() % coloriProgetto.length]);
}

/// Riassunto dell'istantanea [json] senza decodificarla tutta: 'riassunto'
/// è l'ultima chiave, si decodifica solo la coda. Se non torna, decodifica
/// completa (mai eccezioni).
Map<String, Object?> riassuntoVeloce(String json) {
  const String chiave = '"riassunto":';
  final int i = json.lastIndexOf(chiave);
  if (i >= 0 && json.endsWith('}')) {
    try {
      final Object? d = jsonDecode(
        json.substring(i + chiave.length, json.length - 1),
      );
      if (d is Map<String, Object?>) {
        return d;
      }
    } on FormatException {
      // si prova la decodifica completa qui sotto
    }
  }
  return leggiIstantanea(json).riassunto;
}

double _num(Object? v) => v is num ? v.toDouble() : 0;

/// Una riga d'archivio con il riassunto già decodificato.
class RigaArchivio {
  /// Crea la riga leggendo il riassunto dell'istantanea.
  factory RigaArchivio(SettimanaProgetto riga) =>
      RigaArchivio._(riga, riassuntoVeloce(riga.istantanea));

  RigaArchivio._(this.riga, this.riassunto)
    : sett = StimaIntervallo.daMappa(riassunto['sett']),
      sess = StimaIntervallo.daMappa(riassunto['sess']),
      oreAttive = _num(riassunto['ore_attive']),
      oreCondivise = _num(riassunto['ore_condivise']),
      mediaSettOra = riassunto['media_sett_ora'] is num
          ? (riassunto['media_sett_ora']! as num).toDouble()
          : null,
      mediaSessOra = riassunto['media_sess_ora'] is num
          ? (riassunto['media_sess_ora']! as num).toDouble()
          : null,
      piccoSessOra = riassunto['picco_sess_ora'] is num
          ? (riassunto['picco_sess_ora']! as num).toDouble()
          : null;

  /// Riga dell'archivio (con istantanea intera).
  final SettimanaProgetto riga;

  /// Riassunto decodificato.
  final Map<String, Object?> riassunto;

  /// Punti settimanali consumati (STIMA se condivisi).
  final StimaIntervallo sett;

  /// Punti sessione consumati (STIMA se condivisi).
  final StimaIntervallo sess;

  /// Ore attive del progetto.
  final double oreAttive;

  /// Ore condivise con altri progetti.
  final double oreCondivise;

  /// Media pt sett/h sulle ore attive (null = non nota).
  final double? mediaSettOra;

  /// Media pt sess/h sulle ore attive (null = non nota).
  final double? mediaSessOra;

  /// Picco intensità 5 ore dentro le ore attive (null = non noto).
  final double? piccoSessOra;

  /// Id riga nel database (-1 = non salvata).
  int get id => riga.id ?? -1;

  /// Id del progetto.
  int get progettoId => riga.progettoId;

  /// Inizio settimana.
  DateTime get inizio => riga.inizio;

  /// Fine settimana (null = in corso).
  DateTime? get fine => riga.fine;

  /// Token scritti a mano.
  int? get token => riga.tokenManuali;

  /// Vero se il riassunto si è letto.
  bool get leggibile => riassunto.isNotEmpty;

  /// Stessa riga con altri token (nessuna nuova decodifica).
  RigaArchivio conToken(int? t) => RigaArchivio._(
    SettimanaProgetto(
      id: riga.id,
      progettoId: riga.progettoId,
      inizio: riga.inizio,
      fine: riga.fine,
      istantanea: riga.istantanea,
      log: riga.log,
      tokenManuali: t,
    ),
    riassunto,
  );
}

/// Righe della stessa settimana (un gruppo per settimana).
class GruppoSettimana {
  /// Crea il gruppo.
  const GruppoSettimana(this.inizio, this.fine, this.righe);

  /// Inizio settimana.
  final DateTime inizio;

  /// Fine settimana.
  final DateTime? fine;

  /// Righe (Senza progetto per prima, poi per id progetto).
  final List<RigaArchivio> righe;
}

/// Gruppi per settimana, dalla più recente.
List<GruppoSettimana> raggruppaSettimane(Iterable<RigaArchivio> righe) {
  final Map<DateTime, List<RigaArchivio>> per =
      <DateTime, List<RigaArchivio>>{};
  for (final RigaArchivio r in righe) {
    per.putIfAbsent(r.inizio, () => <RigaArchivio>[]).add(r);
  }
  final List<DateTime> inizi = per.keys.toList()
    ..sort((DateTime a, DateTime b) => b.compareTo(a));
  return <GruppoSettimana>[
    for (final DateTime d in inizi)
      GruppoSettimana(
        d,
        per[d]!.first.fine,
        per[d]!..sort(
          (RigaArchivio a, RigaArchivio b) =>
              a.progettoId.compareTo(b.progettoId),
        ),
      ),
  ];
}

/// Una barra del confronto settimane.
class BarraSettimana {
  /// Crea la barra.
  const BarraSettimana(this.inizio, this.totale, this.segmenti);

  /// Inizio settimana.
  final DateTime inizio;

  /// Punti settimanali totali della barra (STIMA).
  final double totale;

  /// Pezzi per progetto (stima punti settimanali), in ordine di id.
  final List<({int progettoId, double valore})> segmenti;
}

/// Barre del confronto, dalla settimana più vecchia, al massimo [max]
/// (le più recenti). [progettoId] null = tutti (barra a pezzi).
List<BarraSettimana> barreSettimane(
  Iterable<RigaArchivio> righe, {
  int? progettoId,
  int max = 26,
}) {
  final List<GruppoSettimana> gruppi = raggruppaSettimane(righe);
  final List<BarraSettimana> out = <BarraSettimana>[];
  for (final GruppoSettimana g in gruppi.reversed) {
    final List<({int progettoId, double valore})> seg =
        <({int progettoId, double valore})>[
          for (final RigaArchivio r in g.righe)
            if (progettoId == null || r.progettoId == progettoId)
              (progettoId: r.progettoId, valore: r.sett.stima),
        ];
    double tot = 0;
    for (final ({int progettoId, double valore}) s in seg) {
      tot += s.valore;
    }
    out.add(BarraSettimana(g.inizio, tot, seg));
  }
  return out.length <= max ? out : out.sublist(out.length - max);
}

/// Cima comune delle barre (almeno 1).
double cimaBarre(List<BarraSettimana> barre) {
  double m = 1;
  for (final BarraSettimana b in barre) {
    if (b.totale > m) {
      m = b.totale;
    }
  }
  return m;
}

/// Settimana archiviata aperta: dati per ridisegnare i grafici salvati.
class SchedaSettimana {
  /// Crea la scheda.
  const SchedaSettimana({
    required this.riga,
    required this.dati,
    required this.grafico,
    required this.conPiano,
  });

  /// Riga aperta.
  final RigaArchivio riga;

  /// Istantanea letta.
  final IstantaneaLetta dati;

  /// Dati dei due grafici (null se l'istantanea non si legge).
  final DatiGrafico? grafico;

  /// Vero se l'istantanea ha il piano (linee ideale/adattiva).
  final bool conPiano;
}

List<PuntoIntensita> _puntiIntensita(Map<String, Object?> grezza) {
  final Object? serie = grezza['serie'];
  final Object? lista = serie is Map<String, Object?>
      ? serie['intensita']
      : null;
  final List<PuntoIntensita> out = <PuntoIntensita>[];
  if (lista is! List<Object?>) {
    return out;
  }
  for (final Object? r in lista) {
    if (r is! List<Object?> || r.length < 4 || r[0] is! String) {
      continue;
    }
    final DateTime? ora = interpreta(r[0]! as String);
    FonteIntensita? fonte;
    for (final FonteIntensita f in FonteIntensita.values) {
      if (f.codice == r[1]) {
        fonte = f;
      }
    }
    if (ora == null || fonte == null) {
      continue;
    }
    out.add(
      PuntoIntensita(
        ora: ora,
        fonte: fonte,
        valore: r[2] is num ? (r[2]! as num).toDouble() : null,
        errore: r[3] is num ? (r[3]! as num).toDouble() : null,
      ),
    );
  }
  return out;
}

Piano? _piano(Map<String, Object?> grezza, DateTime inizio) {
  final Object? p = grezza['piano'];
  if (p is! Map<String, Object?>) {
    return null;
  }
  final Object? mask = p['giorni_mask'];
  final Object? target = p['target_pct'];
  return Piano(
    nome: p['nome'] is String ? p['nome']! as String : 'Piano',
    giorniMask: mask is int ? mask : tuttiIGiorni,
    targetPct: target is num ? target.toDouble() : targetPredefinito,
    confine: ConfinePiano.daTesto(
      p['confine'] is String ? p['confine']! as String : null,
    ),
    inizio: inizio,
  );
}

/// Costruisce la scheda della riga [r]: legge l'istantanea e prepara i dati
/// dei grafici (una volta, fuori da build/paint). La serie intensità è
/// quella SALVATA (non si ricalcola); il piano si ridisegna dai parametri
/// salvati sulle letture salvate.
SchedaSettimana costruisciScheda(RigaArchivio r) {
  final IstantaneaLetta d = leggiIstantanea(r.riga.istantanea);
  if (d.versione == 0) {
    return SchedaSettimana(riga: r, dati: d, grafico: null, conPiano: false);
  }
  final DateTime ini = r.inizio;
  final DateTime fine = r.fine ?? ini.add(const Duration(days: 7));
  final Piano? piano = _piano(d.grezza, ini);
  final SeriePiano? sp = piano == null
      ? null
      : calcolaSeriePiano(piano, d.letture, da: ini, reset: ini);
  final List<PuntoIntensita> punti = _puntiIntensita(d.grezza);
  double max5 = 1;
  double max7 = 1;
  for (final PuntoIntensita p in punti) {
    final double v = p.valore ?? 0;
    if (p.fonte == FonteIntensita.cinqueOre) {
      if (v > max5) {
        max5 = v;
      }
    } else if (v > max7) {
      max7 = v;
    }
  }
  final IntensitaV2 iv = IntensitaV2(
    punti: punti,
    stat: statIntensita(punti),
    max5h: max5,
    max7gg: max7,
  );
  return SchedaSettimana(
    riga: r,
    dati: d,
    grafico: calcolaDatiGrafico(
      d.letture,
      d.eventi,
      ini,
      fine,
      fine,
      piano: sp,
      intensitaV2: iv,
    ),
    conPiano: piano != null,
  );
}
