// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain (V2, B12): archivio delle settimane per progetto.
// Una riga per (progetto, settimana) con ISTANTANEA COMPLETA (copia di
// letture+eventi della settimana + serie calcolate + parametri piano +
// riassunto): la settimana si rivede uguale anche se i dati grezzi cambiano.
// Puro: produce testo JSON, il salvataggio sta in data/.
import 'dart:convert';

import 'intensita.dart';
import 'linee_piano.dart';
import 'modelli.dart';
import 'piani_progetti.dart';
import 'progetti.dart';
import 'serie_piano.dart';
import 'tempo.dart';

/// Versione del formato dell'istantanea.
const int versioneIstantanea = 1;

/// Passo (min) della serie intensità salvata nell'istantanea.
const int passoIstantaneaMin = 15;

/// Settimana di un progetto pronta da salvare.
class SettimanaProgetto {
  /// Crea una settimana.
  const SettimanaProgetto({
    required this.progettoId,
    required this.inizio,
    required this.fine,
    required this.istantanea,
    required this.log,
    this.id,
    this.tokenManuali,
  });

  /// Id riga nel database (null = non salvata).
  final int? id;

  /// Id progetto ([idSenzaProgetto] = Senza progetto).
  final int progettoId;

  /// Inizio settimana (reset).
  final DateTime inizio;

  /// Fine settimana (reset dopo; null = in corso).
  final DateTime? fine;

  /// Istantanea JSON (vedi [istantaneaSettimana]).
  final String istantanea;

  /// Log testuale (vedi [testoLog]).
  final String log;

  /// Token scritti a mano (null = non noti).
  final int? tokenManuali;
}

List<Object?> _lettura(Lettura l) => <Object?>[
  formatta(l.ora),
  l.sett,
  l.sess,
  l.fonte,
  l.alPc,
  l.lavoro,
  l.modelli,
  l.skill,
  l.gestore,
];

List<Object?> _evento(Evento e) => <Object?>[
  formatta(e.ora),
  e.tipo.name,
  e.testo,
];

/// Istantanea JSON della settimana [inizio, fine) per il progetto [id].
/// [letture]/[eventi] = solo quelli della settimana (copia integrale).
String istantaneaSettimana({
  required int id,
  required String nome,
  required DateTime inizio,
  required DateTime fine,
  required List<Lettura> letture,
  required List<Evento> eventi,
  required Ripartizione ripartizione,
  required List<IntervalloProgetto> intervalli,
  required List<PuntoIntensita> intensita,
  required CostoEnergia costo,
  Progetto? progetto,
  Piano? piano,
  SeriePiano? seriePiano,
}) {
  final ConsumoProgetto? c = ripartizione.voce(id);
  final Map<String, Object?> m = <String, Object?>{
    'v': versioneIstantanea,
    'progetto': <String, Object?>{
      'id': id,
      'nome': nome,
      'colore': progetto?.colore ?? 0,
      'note': progetto?.note ?? '',
    },
    'settimana': <String, String>{
      'inizio': formatta(inizio),
      'fine': formatta(fine),
    },
    'letture': <List<Object?>>[for (final Lettura l in letture) _lettura(l)],
    'eventi': <List<Object?>>[for (final Evento e in eventi) _evento(e)],
    'intervalli': <List<Object?>>[
      for (final IntervalloProgetto i in intervalli)
        if (i.progettoId == id) <Object?>[formatta(i.inizio), formatta(i.fine)],
    ],
    'serie': <String, Object?>{
      'passo_min': passoIstantaneaMin,
      'intensita': <List<Object?>>[
        for (final PuntoIntensita p in intensita)
          <Object?>[formatta(p.ora), p.fonte.codice, p.valore, p.errore],
      ],
      'ideale': <List<Object?>>[
        for (final PuntoLinea p in seriePiano?.ideale ?? const <PuntoLinea>[])
          <Object?>[formatta(p.ora), p.valore],
      ],
      'adattiva': <List<Object?>>[
        for (final PuntoLinea p in seriePiano?.adattiva ?? const <PuntoLinea>[])
          <Object?>[formatta(p.ora), p.valore],
      ],
    },
    'piano': piano == null
        ? null
        : <String, Object?>{
            'nome': piano.nome,
            'giorni_mask': piano.giorniMask,
            'target_pct': piano.targetPct,
            'confine': piano.confine.testo,
          },
    'riassunto': <String, Object?>{
      'stima': true,
      'totale_sett': ripartizione.totaleSett,
      'totale_sess': ripartizione.totaleSess,
      'ore_condivise': c?.oreCondivise ?? 0,
      ...costo.aMappa(),
    },
  };
  return jsonEncode(m);
}

/// Istantanea letta (per rivedere una settimana archiviata).
class IstantaneaLetta {
  /// Crea.
  const IstantaneaLetta({
    required this.versione,
    required this.letture,
    required this.eventi,
    required this.intervalli,
    required this.riassunto,
    required this.grezza,
  });

  /// Versione formato (0 = non leggibile).
  final int versione;

  /// Letture copiate.
  final List<Lettura> letture;

  /// Eventi copiati.
  final List<Evento> eventi;

  /// Intervalli del progetto.
  final List<({DateTime inizio, DateTime fine})> intervalli;

  /// Riassunto (chiavi come in [istantaneaSettimana]).
  final Map<String, Object?> riassunto;

  /// Mappa intera (serie, piano...).
  final Map<String, Object?> grezza;
}

double? _num(Object? v) => v is num ? v.toDouble() : null;

/// Legge un'istantanea. JSON rotto o formato sconosciuto -> versione 0 e
/// liste vuote (mai eccezioni).
IstantaneaLetta leggiIstantanea(String json) {
  Object? d;
  try {
    d = jsonDecode(json);
  } on FormatException {
    d = null;
  }
  if (d is! Map<String, Object?>) {
    return const IstantaneaLetta(
      versione: 0,
      letture: <Lettura>[],
      eventi: <Evento>[],
      intervalli: <({DateTime inizio, DateTime fine})>[],
      riassunto: <String, Object?>{},
      grezza: <String, Object?>{},
    );
  }
  List<Object?> lista(Object? x) => x is List<Object?> ? x : const <Object?>[];
  final List<Lettura> ls = <Lettura>[];
  for (final Object? r in lista(d['letture'])) {
    if (r is! List<Object?> || r.length < 9 || r[0] is! String) {
      continue;
    }
    final DateTime? ora = interpreta(r[0]! as String);
    if (ora == null) {
      continue;
    }
    ls.add(
      Lettura(
        ora: ora,
        sett: _num(r[1]),
        sess: _num(r[2]),
        fonte: r[3] is String ? r[3]! as String : 'auto',
        alPc: r[4] is bool ? r[4]! as bool : null,
        lavoro: r[5] == true,
        modelli: r[6] is String ? r[6]! as String : '',
        skill: r[7] is String ? r[7]! as String : '',
        gestore: r[8] is String ? r[8]! as String : gestoreAnthropic,
      ),
    );
  }
  final List<Evento> es = <Evento>[];
  for (final Object? r in lista(d['eventi'])) {
    if (r is! List<Object?> || r.length < 3 || r[0] is! String) {
      continue;
    }
    final DateTime? ora = interpreta(r[0]! as String);
    final TipoEvento? t = r[1] is String
        ? TipoEvento.daTesto(r[1]! as String)
        : null;
    if (ora == null || t == null) {
      continue;
    }
    es.add(
      Evento(ora: ora, tipo: t, testo: r[2] is String ? r[2]! as String : ''),
    );
  }
  final List<({DateTime inizio, DateTime fine})> iv =
      <({DateTime inizio, DateTime fine})>[];
  for (final Object? r in lista(d['intervalli'])) {
    if (r is List<Object?> &&
        r.length >= 2 &&
        r[0] is String &&
        r[1] is String) {
      final DateTime? a = interpreta(r[0]! as String);
      final DateTime? b = interpreta(r[1]! as String);
      if (a != null && b != null) {
        iv.add((inizio: a, fine: b));
      }
    }
  }
  final Object? ri = d['riassunto'];
  return IstantaneaLetta(
    versione: d['v'] is int ? d['v']! as int : 0,
    letture: List<Lettura>.unmodifiable(ls),
    eventi: List<Evento>.unmodifiable(es),
    intervalli: List<({DateTime inizio, DateTime fine})>.unmodifiable(iv),
    riassunto: ri is Map<String, Object?> ? ri : const <String, Object?>{},
    grezza: d,
  );
}

/// Settimane chiuse (reset a reset) da archiviare: dalla settimana della
/// prima lettura fino all'ultima finita prima di [adesso]. Escluse quelle
/// in [gia] (inizi già archiviati) e quelle senza letture.
List<({DateTime inizio, DateTime fine})> settimaneDaArchiviare(
  List<Lettura> letture,
  DateTime adesso, {
  Set<DateTime> gia = const <DateTime>{},
  int giorno = DateTime.tuesday,
  int h = 20,
  int m = 0,
}) {
  final List<Lettura> ls = ordinaLetture(letture);
  if (ls.isEmpty) {
    return <({DateTime inizio, DateTime fine})>[];
  }
  final DateTime attuale = inizioSettimana(adesso, giorno: giorno, h: h, m: m);
  DateTime ini = inizioSettimana(ls.first.ora, giorno: giorno, h: h, m: m);
  final List<({DateTime inizio, DateTime fine})> out =
      <({DateTime inizio, DateTime fine})>[];
  int i = 0;
  while (ini.isBefore(attuale)) {
    final DateTime fine = DateTime(ini.year, ini.month, ini.day + 7, h, m);
    while (i < ls.length && ls[i].ora.isBefore(ini)) {
      i++;
    }
    final bool conDati = i < ls.length && ls[i].ora.isBefore(fine);
    if (conDati && !gia.contains(ini)) {
      out.add((inizio: ini, fine: fine));
    }
    ini = fine;
  }
  return out;
}

/// Righe d'archivio della settimana [inizio, fine): una per progetto con
/// ore attive o consumo, + Senza progetto se ha consumo o se nessun
/// progetto era attivo. Tutte con la stessa copia di letture/eventi.
/// Somma delle stime sett/sess delle righe = totale della settimana.
List<SettimanaProgetto> archiviaSettimana({
  required List<Lettura> letture,
  required List<Evento> eventi,
  required List<Progetto> progetti,
  required DateTime inizio,
  required DateTime fine,
  Piano? piano,
}) {
  bool dentro(DateTime t) => !t.isBefore(inizio) && t.isBefore(fine);
  final List<Lettura> ls = <Lettura>[
    for (final Lettura l in ordinaLetture(letture))
      if (dentro(l.ora)) l,
  ];
  // Eventi: anche quelli prima (un progetto aperto prima del reset resta
  // attivo), ma nella copia solo quelli della settimana.
  final List<Evento> tutti = ordinaEventi(eventi);
  final List<Evento> es = <Evento>[
    for (final Evento e in tutti)
      if (dentro(e.ora)) e,
  ];
  final List<Evento> finoAFine = <Evento>[
    for (final Evento e in tutti)
      if (e.ora.isBefore(fine)) e,
  ];
  final Ripartizione r = ripartisci(
    ls,
    finoAFine,
    progetti,
    da: inizio,
    a: fine,
  );
  final List<IntervalloProgetto> iv = <IntervalloProgetto>[
    for (final IntervalloProgetto i in intervalliProgetti(
      finoAFine,
      progetti,
      fine,
    ))
      if (i.fine.isAfter(inizio))
        IntervalloProgetto(
          i.progettoId,
          piuTardi(i.inizio, inizio),
          i.fine,
          aperto: i.aperto,
        ),
  ];
  final List<PuntoIntensita> intensita = serieIntensitaV2(
    ls,
    inizio,
    fine,
    passoMin: passoIstantaneaMin,
  );
  final SeriePiano? sp = piano == null
      ? null
      : calcolaSeriePiano(piano, ls, da: inizio, reset: inizio);
  final String log = testoLog(
    logSettimana(ls, es, progetti, da: inizio, a: fine),
    <int, String>{
      for (final Progetto p in progetti)
        if (p.id != null) p.id!: p.nome,
    },
  );
  final List<int> ids = <int>[
    for (final ConsumoProgetto c in r.voci)
      if (c.progettoId != idSenzaProgetto) c.progettoId,
  ];
  final ConsumoProgetto? senza = r.voce(idSenzaProgetto);
  final bool serveSenza =
      ids.isEmpty ||
      (senza != null && (senza.sett.stima > 0 || senza.sess.stima > 0));
  if (serveSenza) {
    ids.insert(0, idSenzaProgetto);
  }
  Progetto? progetto(int id) {
    for (final Progetto p in progetti) {
      if (p.id == id) {
        return p;
      }
    }
    return null;
  }

  return <SettimanaProgetto>[
    for (final int id in ids)
      SettimanaProgetto(
        progettoId: id,
        inizio: inizio,
        fine: fine,
        log: log,
        istantanea: istantaneaSettimana(
          id: id,
          nome: nomeProgetto(id, progetti),
          progetto: progetto(id),
          inizio: inizio,
          fine: fine,
          letture: ls,
          eventi: es,
          ripartizione: r,
          intervalli: iv,
          intensita: intensita,
          costo: costoEnergia(r, id, intensita: intensita, intervalli: iv),
          piano: piano,
          seriePiano: sp,
        ),
      ),
  ];
}
