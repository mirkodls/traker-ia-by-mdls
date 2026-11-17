// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain (V2, B12): progetti nel tempo.
// - note-comando "NOME inizio" / "NOME fine" / "NOME 70%"
//   (il tasto "Progetto attivo" scrive la stessa nota: una sola fonte);
// - intervalli di attività per progetto;
// - ripartizione del consumo tra progetti attivi insieme (STIMA con min/max);
// - costo energia (pt consumati + intensità; token SOLO se scritti a mano);
// - log cronologico della settimana (testo strutturato per il resoconto).
// Puro: nessun I/O. La somma delle parti è sempre il totale.
import 'analisi.dart';
import 'coppie.dart';
import 'intensita.dart';
import 'modelli.dart';
import 'piani_progetti.dart';
import 'serie_intensita.dart';
import 'tempo.dart';
import 'traduzioni/testi_it.dart';

/// Id riservato a "Senza progetto" (gli id veri partono da 1).
const int idSenzaProgetto = 0;

/// Cosa fa una nota-comando di progetto.
enum TipoComandoProgetto {
  /// Il progetto parte.
  inizio,

  /// Il progetto si ferma.
  fine,

  /// Quota del consumo quando è attivo insieme ad altri ("NOME 70%").
  quota,
}

/// Nota-comando di progetto riconosciuta.
class ComandoProgetto {
  /// Crea un comando.
  const ComandoProgetto(this.progettoId, this.tipo, {this.quota});

  /// Id del progetto.
  final int progettoId;

  /// Inizio, fine o quota.
  final TipoComandoProgetto tipo;

  /// Quota 0-100 (solo per [TipoComandoProgetto.quota]).
  final double? quota;

  @override
  bool operator ==(Object other) =>
      other is ComandoProgetto &&
      other.progettoId == progettoId &&
      other.tipo == tipo &&
      other.quota == quota;

  @override
  int get hashCode => Object.hash(progettoId, tipo, quota);

  @override
  String toString() => 'ComandoProgetto($progettoId, ${tipo.name}, $quota)';
}

/// Testo normalizzato per confronti: minuscolo, spazi singoli, senza
/// punteggiatura finale.
String normalizzaNome(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll(RegExp(r'[\s.!;:,]+$'), '')
    .trim();

final RegExp _quota = RegExp(r'^(.+?)\s+(\d+(?:[.,]\d+)?)\s*%$');

/// Nota -> comando di progetto, o null (nota normale).
/// Riconosce "NOME inizio", "inizio NOME", "NOME fine",
/// "fine NOME", "NOME 70%" (0-100). Nome = nome del progetto (maiuscole
/// e spazi ignorati). Le note-comando Lavoro ('lavoro', 'fine lavoro')
/// vincono sempre. Progetti senza id ignorati.
ComandoProgetto? comandoProgettoDaNota(
  String testo,
  Iterable<Progetto> progetti,
) {
  if (comandoLavoroDaNota(testo) != null) {
    return null;
  }
  final String t = normalizzaNome(testo);
  if (t.isEmpty) {
    return null;
  }
  final Map<String, int> perNome = <String, int>{};
  for (final Progetto p in progetti) {
    final int? id = p.id;
    final String n = normalizzaNome(p.nome);
    if (id != null && n.isNotEmpty) {
      perNome.putIfAbsent(n, () => id);
    }
  }
  int? cerca(String nome) => perNome[nome.trim()];
  for (final (String parola, TipoComandoProgetto tipo)
      in <(String, TipoComandoProgetto)>[
        ('inizio', TipoComandoProgetto.inizio),
        ('fine', TipoComandoProgetto.fine),
      ]) {
    if (t.endsWith(' $parola')) {
      final int? id = cerca(t.substring(0, t.length - parola.length - 1));
      if (id != null) {
        return ComandoProgetto(id, tipo);
      }
    }
    if (t.startsWith('$parola ')) {
      final int? id = cerca(t.substring(parola.length + 1));
      if (id != null) {
        return ComandoProgetto(id, tipo);
      }
    }
  }
  final RegExpMatch? m = _quota.firstMatch(t);
  if (m != null) {
    final int? id = cerca(m.group(1)!);
    final double? q = double.tryParse(m.group(2)!.replaceAll(',', '.'));
    if (id != null && q != null && q >= 0 && q <= 100) {
      return ComandoProgetto(id, TipoComandoProgetto.quota, quota: q);
    }
  }
  return null;
}

/// Testo della nota scritta dal tasto "Progetto attivo" (stessa sintassi
/// delle note a mano).
String notaComandoProgetto(
  Progetto p,
  TipoComandoProgetto tipo, {
  double? quota,
}) => switch (tipo) {
  TipoComandoProgetto.inizio => '${p.nome.trim()} inizio',
  TipoComandoProgetto.fine => '${p.nome.trim()} fine',
  TipoComandoProgetto.quota => '${p.nome.trim()} ${_numero(quota ?? 0)}%',
};

String _numero(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// Periodo di attività di un progetto.
class IntervalloProgetto {
  /// Crea un intervallo.
  const IntervalloProgetto(
    this.progettoId,
    this.inizio,
    this.fine, {
    this.aperto = false,
  });

  /// Id del progetto.
  final int progettoId;

  /// Inizio.
  final DateTime inizio;

  /// Fine (se [aperto]: il "fino" del calcolo).
  final DateTime fine;

  /// Vero se il progetto non è ancora stato fermato.
  final bool aperto;

  @override
  bool operator ==(Object other) =>
      other is IntervalloProgetto &&
      other.progettoId == progettoId &&
      other.inizio == inizio &&
      other.fine == fine &&
      other.aperto == aperto;

  @override
  int get hashCode => Object.hash(progettoId, inizio, fine, aperto);

  @override
  String toString() =>
      'IntervalloProgetto($progettoId, $inizio, $fine, aperto: $aperto)';
}

/// Cambio di quota di un progetto (da [ora] in poi, fino a nuova quota o
/// fine del progetto).
class CambioQuota {
  /// Crea un cambio.
  const CambioQuota(this.progettoId, this.ora, this.quota);

  /// Id del progetto.
  final int progettoId;

  /// Da quando.
  final DateTime ora;

  /// Quota 0-100.
  final double quota;
}

/// Comandi di progetto trovati nelle note, in ordine di tempo.
List<({DateTime ora, ComandoProgetto c})> comandiProgetti(
  Iterable<Evento> eventi,
  Iterable<Progetto> progetti,
) {
  final List<Progetto> ps = progetti.toList();
  return <({DateTime ora, ComandoProgetto c})>[
    for (final Evento e in ordinaEventi(eventi))
      if (e.tipo == TipoEvento.nota)
        if (comandoProgettoDaNota(e.testo, ps) case final ComandoProgetto c)
          (ora: e.ora, c: c),
  ];
}

/// Note-comando -> intervalli per progetto (ordinati per inizio).
/// 'inizio' doppio ignorato; 'fine' senza inizio ignorato; aperto = fino a
/// [fino]. Intervalli vuoti scartati.
List<IntervalloProgetto> intervalliProgetti(
  Iterable<Evento> eventi,
  Iterable<Progetto> progetti,
  DateTime fino,
) {
  final Map<int, DateTime> aperti = <int, DateTime>{};
  final List<IntervalloProgetto> out = <IntervalloProgetto>[];
  for (final ({DateTime ora, ComandoProgetto c}) x in comandiProgetti(
    eventi,
    progetti,
  )) {
    final int id = x.c.progettoId;
    if (x.c.tipo == TipoComandoProgetto.inizio) {
      aperti.putIfAbsent(id, () => x.ora);
    } else if (x.c.tipo == TipoComandoProgetto.fine) {
      final DateTime? ini = aperti.remove(id);
      if (ini != null && x.ora.isAfter(ini)) {
        out.add(IntervalloProgetto(id, ini, x.ora));
      }
    }
  }
  aperti.forEach((int id, DateTime ini) {
    if (fino.isAfter(ini)) {
      out.add(IntervalloProgetto(id, ini, fino, aperto: true));
    }
  });
  out.sort((IntervalloProgetto a, IntervalloProgetto b) {
    final int c = a.inizio.compareTo(b.inizio);
    return c != 0 ? c : a.progettoId.compareTo(b.progettoId);
  });
  return out;
}

/// Quote dalle note "NOME 70%". La quota vale solo mentre il progetto è
/// attivo: una 'fine' la cancella (cambio con quota negativa = tolta).
List<CambioQuota> cambiQuota(
  Iterable<Evento> eventi,
  Iterable<Progetto> progetti,
) => <CambioQuota>[
  for (final ({DateTime ora, ComandoProgetto c}) x in comandiProgetti(
    eventi,
    progetti,
  ))
    if (x.c.tipo == TipoComandoProgetto.quota)
      CambioQuota(x.c.progettoId, x.ora, x.c.quota!)
    else if (x.c.tipo == TipoComandoProgetto.fine)
      CambioQuota(x.c.progettoId, x.ora, -1),
];

/// Progetti attivi all'istante [t] (inizio incluso, fine esclusa).
Set<int> attiviA(List<IntervalloProgetto> intervalli, DateTime t) => <int>{
  for (final IntervalloProgetto i in intervalli)
    if (!t.isBefore(i.inizio) && t.isBefore(i.fine)) i.progettoId,
};

/// Quote (0-1) dei progetti [attivi]. Vuoto -> {Senza progetto: 1}.
/// Uno solo -> 100%. Più di uno: chi ha quota da nota la prende, il resto
/// va in parti uguali a chi non ce l'ha; senza note = parti uguali
/// (50/50). Quote oltre il 100% (o tutte date) -> riproporzionate. Somma
/// sempre 1.
Map<int, double> quoteSegmento(Set<int> attivi, Map<int, double> quoteNote) {
  if (attivi.isEmpty) {
    return <int, double>{idSenzaProgetto: 1};
  }
  final List<int> ids = attivi.toList()..sort();
  if (ids.length == 1) {
    return <int, double>{ids.first: 1};
  }
  final List<int> conQuota = <int>[
    for (final int id in ids)
      if (quoteNote.containsKey(id)) id,
  ];
  final List<int> senza = <int>[
    for (final int id in ids)
      if (!quoteNote.containsKey(id)) id,
  ];
  double somma = 0;
  for (final int id in conQuota) {
    somma += quoteNote[id]! / 100;
  }
  final Map<int, double> out = <int, double>{};
  if (senza.isNotEmpty && somma < 1) {
    for (final int id in conQuota) {
      out[id] = quoteNote[id]! / 100;
    }
    final double resto = (1 - somma) / senza.length;
    for (final int id in senza) {
      out[id] = resto;
    }
  } else if (somma > 0) {
    for (final int id in ids) {
      out[id] = conQuota.contains(id) ? quoteNote[id]! / 100 / somma : 0;
    }
  } else {
    for (final int id in ids) {
      out[id] = 1 / ids.length;
    }
  }
  return out;
}

/// Stima con intervallo: [min] = niente dei tratti condivisi, [max] =
/// tutti i tratti condivisi a questo progetto.
class StimaIntervallo {
  /// Crea una stima.
  const StimaIntervallo(this.stima, this.min, this.max);

  /// Zero.
  static const StimaIntervallo zero = StimaIntervallo(0, 0, 0);

  /// Valore stimato (ripartizione).
  final double stima;

  /// Minimo possibile.
  final double min;

  /// Massimo possibile.
  final double max;

  /// Vero se min == max (nessuna condivisione).
  bool get esatta => (max - min).abs() < 1e-9;

  /// In mappa JSON.
  Map<String, double> aMappa() => <String, double>{
    'stima': stima,
    'min': min,
    'max': max,
  };

  /// Da mappa JSON (dato strano -> 0).
  static StimaIntervallo daMappa(Object? m) {
    double v(String k) => m is Map<String, Object?> && m[k] is num
        ? (m[k]! as num).toDouble()
        : 0;
    return StimaIntervallo(v('stima'), v('min'), v('max'));
  }
}

/// Consumo di un progetto in un intervallo di tempo.
class ConsumoProgetto {
  /// Crea un consumo.
  const ConsumoProgetto({
    required this.progettoId,
    required this.sett,
    required this.sess,
    required this.oreAttive,
    required this.oreCondivise,
  });

  /// Id del progetto ([idSenzaProgetto] = nessuno attivo).
  final int progettoId;

  /// Punti % settimanali consumati (STIMA se condivisi).
  final StimaIntervallo sett;

  /// Punti % sessione 5 ore consumati (STIMA se condivisi).
  final StimaIntervallo sess;

  /// Ore in cui il progetto era attivo.
  final double oreAttive;

  /// Di queste, ore con altri progetti attivi insieme.
  final double oreCondivise;
}

/// Ripartizione del consumo tra progetti in [da, a].
class Ripartizione {
  /// Crea una ripartizione.
  const Ripartizione({
    required this.da,
    required this.a,
    required this.totaleSett,
    required this.totaleSess,
    required this.voci,
  });

  /// Inizio.
  final DateTime da;

  /// Fine.
  final DateTime a;

  /// Punti % settimanali saliti in [da, a] (reset esclusi).
  final double totaleSett;

  /// Punti % sessione saliti in [da, a] (reset esclusi).
  final double totaleSess;

  /// Una voce per progetto con ore o consumo (+ Senza progetto), per id.
  final List<ConsumoProgetto> voci;

  /// Voce del progetto [id], null se assente.
  ConsumoProgetto? voce(int id) {
    for (final ConsumoProgetto c in voci) {
      if (c.progettoId == id) {
        return c;
      }
    }
    return null;
  }
}

class _Segmento {
  _Segmento(this.inizio, this.fine, this.quote);
  final DateTime inizio;
  final DateTime fine;
  final Map<int, double> quote;
}

class _Accumulo {
  double stimaSett = 0, minSett = 0, maxSett = 0;
  double stimaSess = 0, minSess = 0, maxSess = 0;
  double ore = 0, oreCondivise = 0;
}

/// Segmenti di [da, a) con insieme di progetti attivi e quote costanti.
List<_Segmento> _segmenti(
  List<IntervalloProgetto> intervalli,
  List<CambioQuota> quote,
  DateTime da,
  DateTime a,
) {
  final Set<DateTime> tagli = <DateTime>{da, a};
  for (final IntervalloProgetto i in intervalli) {
    for (final DateTime t in <DateTime>[i.inizio, i.fine]) {
      if (t.isAfter(da) && t.isBefore(a)) {
        tagli.add(t);
      }
    }
  }
  for (final CambioQuota q in quote) {
    if (q.ora.isAfter(da) && q.ora.isBefore(a)) {
      tagli.add(q.ora);
    }
  }
  final List<DateTime> ts = tagli.toList()..sort();
  final List<CambioQuota> qs = List<CambioQuota>.of(quote)
    ..sort((CambioQuota x, CambioQuota y) => x.ora.compareTo(y.ora));
  final Map<int, double> correnti = <int, double>{};
  int iq = 0;
  final List<_Segmento> out = <_Segmento>[];
  for (int i = 0; i + 1 < ts.length; i++) {
    final DateTime ini = ts[i];
    while (iq < qs.length && !qs[iq].ora.isAfter(ini)) {
      final CambioQuota q = qs[iq++];
      if (q.quota < 0) {
        correnti.remove(q.progettoId);
      } else {
        correnti[q.progettoId] = q.quota;
      }
    }
    final Set<int> attivi = attiviA(intervalli, ini);
    out.add(
      _Segmento(
        ini,
        ts[i + 1],
        quoteSegmento(attivi, <int, double>{
          for (final int id in attivi)
            if (correnti.containsKey(id)) id: correnti[id]!,
        }),
      ),
    );
  }
  return out;
}

/// Distribuisce i punti di [cs] (clip a [da, a], in proporzione al tempo)
/// sui [segs]. [sett] sceglie i campi. Ultima quota = resto (somma esatta).
void _distribuisci(
  List<Coppia> cs,
  List<_Segmento> segs,
  Map<int, _Accumulo> acc,
  DateTime da,
  DateTime a, {
  required bool sett,
  required List<double> totale,
}) {
  int s0 = 0;
  for (final Coppia c in cs) {
    final DateTime ci = piuTardi(c.partenza.ora, da);
    final DateTime cf = piuPresto(c.arrivo.ora, a);
    if (!cf.isAfter(ci) || c.punti <= 0) {
      continue;
    }
    final double perOra = c.punti / c.ore;
    totale[0] += perOra * oreTra(ci, cf);
    while (s0 < segs.length && !segs[s0].fine.isAfter(ci)) {
      s0++;
    }
    for (int s = s0; s < segs.length && segs[s].inizio.isBefore(cf); s++) {
      final _Segmento g = segs[s];
      final double ore = oreTra(piuTardi(g.inizio, ci), piuPresto(g.fine, cf));
      if (ore <= 0) {
        continue;
      }
      final double pezzo = perOra * ore;
      final List<int> ids = g.quote.keys.toList()..sort();
      final bool condiviso = ids.length > 1;
      double dato = 0;
      for (int k = 0; k < ids.length; k++) {
        final int id = ids[k];
        final double parte = k == ids.length - 1
            ? pezzo - dato
            : pezzo * g.quote[id]!;
        dato += parte;
        final _Accumulo x = acc.putIfAbsent(id, _Accumulo.new);
        final double mi = condiviso ? 0 : pezzo;
        if (sett) {
          x
            ..stimaSett += parte
            ..minSett += mi
            ..maxSett += pezzo;
        } else {
          x
            ..stimaSess += parte
            ..minSess += mi
            ..maxSess += pezzo;
        }
      }
    }
  }
}

/// Ripartisce il consumo di [da, a] tra i progetti attivi (intervalli da
/// note-comando). 1 attivo -> 100%; N attivi -> quote da nota "NOME N%",
/// altrimenti parti uguali. Fuori dai progetti -> Senza progetto.
/// Somma delle stime = totale (per sett e per sess).
Ripartizione ripartisci(
  Iterable<Lettura> letture,
  Iterable<Evento> eventi,
  Iterable<Progetto> progetti, {
  required DateTime da,
  required DateTime a,
}) {
  final List<Lettura> ls = ordinaLetture(letture);
  final List<Evento> es = ordinaEventi(eventi);
  final List<IntervalloProgetto> iv = intervalliProgetti(es, progetti, a);
  final List<_Segmento> segs = a.isAfter(da)
      ? _segmenti(iv, cambiQuota(es, progetti), da, a)
      : <_Segmento>[];
  final Map<int, _Accumulo> acc = <int, _Accumulo>{};
  for (final _Segmento g in segs) {
    final double ore = oreTra(g.inizio, g.fine);
    for (final int id in g.quote.keys) {
      if (id == idSenzaProgetto) {
        continue;
      }
      final _Accumulo x = acc.putIfAbsent(id, _Accumulo.new)..ore += ore;
      if (g.quote.length > 1) {
        x.oreCondivise += ore;
      }
    }
  }
  final List<double> totSett = <double>[0];
  final List<double> totSess = <double>[0];
  _distribuisci(
    coppie(ls, Campo.sett),
    segs,
    acc,
    da,
    a,
    sett: true,
    totale: totSett,
  );
  _distribuisci(
    coppie(ls, Campo.sess),
    segs,
    acc,
    da,
    a,
    sett: false,
    totale: totSess,
  );
  final List<int> ids = acc.keys.toList()..sort();
  return Ripartizione(
    da: da,
    a: a,
    totaleSett: totSett[0],
    totaleSess: totSess[0],
    voci: List<ConsumoProgetto>.unmodifiable(<ConsumoProgetto>[
      for (final int id in ids)
        ConsumoProgetto(
          progettoId: id,
          sett: StimaIntervallo(
            acc[id]!.stimaSett,
            acc[id]!.minSett,
            acc[id]!.maxSett,
          ),
          sess: StimaIntervallo(
            acc[id]!.stimaSess,
            acc[id]!.minSess,
            acc[id]!.maxSess,
          ),
          oreAttive: acc[id]!.ore,
          oreCondivise: acc[id]!.oreCondivise,
        ),
    ]),
  );
}

// ------------------------------------------------------------ costo energia

/// Costo energia di un progetto (U07): punti consumati + intensità.
/// Token SOLO se scritti a mano: mai ricavati dalle %.
class CostoEnergia {
  /// Crea un costo.
  const CostoEnergia({
    required this.sett,
    required this.sess,
    required this.oreAttive,
    this.mediaSettOra,
    this.mediaSessOra,
    this.piccoSessOra,
    this.tokenManuali,
  });

  /// Punti % settimanali (STIMA ± se condivisi).
  final StimaIntervallo sett;

  /// Punti % sessione (STIMA ± se condivisi).
  final StimaIntervallo sess;

  /// Ore attive.
  final double oreAttive;

  /// Media pt sett/h sulle ore attive (STIMA), null se 0 ore.
  final double? mediaSettOra;

  /// Media pt sess/h sulle ore attive (STIMA), null se 0 ore.
  final double? mediaSessOra;

  /// Picco intensità barra 5h (pt sess/h) dentro le ore attive, null se
  /// nessun punto.
  final double? piccoSessOra;

  /// Token scritti a mano (null = non noti).
  final int? tokenManuali;

  /// In mappa JSON.
  Map<String, Object?> aMappa() => <String, Object?>{
    'sett': sett.aMappa(),
    'sess': sess.aMappa(),
    'ore_attive': oreAttive,
    'media_sett_ora': mediaSettOra,
    'media_sess_ora': mediaSessOra,
    'picco_sess_ora': piccoSessOra,
    'token_manuali': tokenManuali,
  };
}

/// Costo del progetto [id] dalla [r]ipartizione. [intensita] = punti
/// serieIntensitaV2 (solo quelli 5h dentro [intervalli] del progetto
/// contano per il picco). Senza progetto: picco su tutto il fuori-progetto
/// non calcolato (null).
CostoEnergia costoEnergia(
  Ripartizione r,
  int id, {
  List<PuntoIntensita> intensita = const <PuntoIntensita>[],
  List<IntervalloProgetto> intervalli = const <IntervalloProgetto>[],
  int? tokenManuali,
}) {
  final ConsumoProgetto? c = r.voce(id);
  final double ore = c?.oreAttive ?? 0;
  double? picco;
  final List<IntervalloProgetto> miei = <IntervalloProgetto>[
    for (final IntervalloProgetto i in intervalli)
      if (i.progettoId == id) i,
  ];
  for (final PuntoIntensita p in intensita) {
    final double? v = p.valore;
    if (v == null || p.fonte != FonteIntensita.cinqueOre) {
      continue;
    }
    if (attiviA(miei, p.ora).isEmpty) {
      continue;
    }
    if (picco == null || v > picco) {
      picco = v;
    }
  }
  return CostoEnergia(
    sett: c?.sett ?? StimaIntervallo.zero,
    sess: c?.sess ?? StimaIntervallo.zero,
    oreAttive: ore,
    mediaSettOra: ore > 0 ? (c?.sett.stima ?? 0) / ore : null,
    mediaSessOra: ore > 0 ? (c?.sess.stima ?? 0) / ore : null,
    piccoSessOra: picco,
    tokenManuali: tokenManuali,
  );
}

// ---------------------------------------------------------------------- log

/// Tipo di voce del log.
enum TipoVoceLog {
  /// Nota (anche marcatore).
  nota,

  /// Inizio lavoro.
  inizioLavoro,

  /// Fine lavoro.
  fineLavoro,

  /// Reset segnato a mano.
  reset,

  /// Reset trovato nelle letture (barra settimanale).
  resetSett,

  /// Reset trovato nelle letture (barra 5 ore).
  resetSess,

  /// Progetto parte.
  progettoInizio,

  /// Progetto si ferma.
  progettoFine,

  /// Quota di un progetto.
  progettoQuota;

  /// Codice stabile (per il testo del log).
  String get codice => switch (this) {
    TipoVoceLog.nota => 'NOTA',
    TipoVoceLog.inizioLavoro => 'LAVORO_INIZIO',
    TipoVoceLog.fineLavoro => 'LAVORO_FINE',
    TipoVoceLog.reset => 'RESET',
    TipoVoceLog.resetSett => 'RESET_SETT',
    TipoVoceLog.resetSess => 'RESET_SESS',
    TipoVoceLog.progettoInizio => 'PROGETTO_INIZIO',
    TipoVoceLog.progettoFine => 'PROGETTO_FINE',
    TipoVoceLog.progettoQuota => 'PROGETTO_QUOTA',
  };
}

/// Voce del log.
class VoceLog {
  /// Crea una voce.
  const VoceLog(this.ora, this.tipo, this.testo, {this.progettoId});

  /// Ora.
  final DateTime ora;

  /// Tipo.
  final TipoVoceLog tipo;

  /// Testo (nota originale o descrizione).
  final String testo;

  /// Progetto coinvolto (voci progetto).
  final int? progettoId;
}

/// Log cronologico di [da, a): note, lavoro (eventi e note-comando),
/// reset (segnati e trovati nelle letture), cambi progetto. Ordine stabile
/// per ora.
List<VoceLog> logSettimana(
  Iterable<Lettura> letture,
  Iterable<Evento> eventi,
  Iterable<Progetto> progetti, {
  required DateTime da,
  required DateTime a,
}) {
  bool dentro(DateTime t) => !t.isBefore(da) && t.isBefore(a);
  final List<Progetto> ps = progetti.toList();
  final List<VoceLog> out = <VoceLog>[];
  for (final Evento e in ordinaEventi(eventi)) {
    if (!dentro(e.ora)) {
      continue;
    }
    switch (e.tipo) {
      case TipoEvento.inizio:
        out.add(VoceLog(e.ora, TipoVoceLog.inizioLavoro, e.testo));
      case TipoEvento.fine:
        out.add(VoceLog(e.ora, TipoVoceLog.fineLavoro, e.testo));
      case TipoEvento.reset:
        out.add(VoceLog(e.ora, TipoVoceLog.reset, e.testo));
      case TipoEvento.nota:
        final TipoEvento? lav = comandoLavoroDaNota(e.testo);
        final ComandoProgetto? c = comandoProgettoDaNota(e.testo, ps);
        if (lav != null) {
          out.add(
            VoceLog(
              e.ora,
              lav == TipoEvento.inizio
                  ? TipoVoceLog.inizioLavoro
                  : TipoVoceLog.fineLavoro,
              e.testo,
            ),
          );
        } else if (c != null) {
          out.add(
            VoceLog(
              e.ora,
              switch (c.tipo) {
                TipoComandoProgetto.inizio => TipoVoceLog.progettoInizio,
                TipoComandoProgetto.fine => TipoVoceLog.progettoFine,
                TipoComandoProgetto.quota => TipoVoceLog.progettoQuota,
              },
              e.testo,
              progettoId: c.progettoId,
            ),
          );
        } else {
          out.add(VoceLog(e.ora, TipoVoceLog.nota, e.testo));
        }
    }
  }
  for (final (Campo campo, TipoVoceLog tipo) in <(Campo, TipoVoceLog)>[
    (Campo.sett, TipoVoceLog.resetSett),
    (Campo.sess, TipoVoceLog.resetSess),
  ]) {
    for (final DateTime t in trovaReset(letture, campo)) {
      if (dentro(t)) {
        out.add(VoceLog(t, tipo, ''));
      }
    }
  }
  return ordinaPerOra(out, (VoceLog v) => v.ora);
}

/// Log in testo strutturato (una riga per voce, per il resoconto):
/// "aaaa-mm-gg hh:mm | CODICE | progetto | testo". Testo su una riga.
String testoLog(List<VoceLog> voci, Map<int, String> nomiProgetti) {
  final StringBuffer b = StringBuffer();
  for (final VoceLog v in voci) {
    final String p = v.progettoId == null
        ? ''
        : nomiProgetti[v.progettoId] ?? '#${v.progettoId}';
    final String t = v.testo
        .replaceAll(RegExp(r'[\r\n|]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    b.writeln('${formatta(v.ora)} | ${v.tipo.codice} | $p | $t');
  }
  return b.toString();
}

/// Nome da mostrare per l'id [id] (Senza progetto compreso).
String nomeProgetto(int id, Iterable<Progetto> progetti) {
  if (id == idSenzaProgetto) {
    return Testi.senzaProgetto;
  }
  for (final Progetto p in progetti) {
    if (p.id == id) {
      return p.nome;
    }
  }
  return '#$id';
}
