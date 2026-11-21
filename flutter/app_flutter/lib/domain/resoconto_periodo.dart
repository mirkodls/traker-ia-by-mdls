// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain (V2, B20): resoconto IA per PERIODO scelto (giorno,
// settimana, progetto). Il testo per l'IA contiene SOLO i dati dentro
// [da, a): letture, note, eventi, piano, Fable. Riusa archiviaSettimana
// (funziona su qualsiasi intervallo) ed esportaPerIA (stesso formato B14).
// Puro: nessun I/O. Mai cookie/token/chiavi nel testo.
import 'archivio_settimane.dart';
import 'export_ia.dart';
import 'modelli.dart';
import 'piani_progetti.dart';
import 'progetti.dart';
import 'tempo.dart';
import 'traduzioni/testi_it.dart';

/// Tipo di periodo del resoconto.
enum TipoPeriodo {
  /// Un giorno (mezzanotte -> mezzanotte).
  giorno('giorno'),

  /// Una settimana (reset -> reset, martedì 20:00).
  settimana('settimana'),

  /// Un progetto (nota "NOME inizio" -> "NOME fine", o adesso).
  progetto('progetto');

  const TipoPeriodo(this.codice);

  /// Codice nel testo e nei nomi file.
  final String codice;
}

/// Periodo scelto per il resoconto.
class PeriodoIA {
  /// Crea un periodo.
  const PeriodoIA({
    required this.tipo,
    required this.da,
    required this.a,
    this.progettoId,
    this.aperto = false,
    this.fineAMano = false,
  });

  /// Tipo.
  final TipoPeriodo tipo;

  /// Inizio (compreso).
  final DateTime da;

  /// Fine (esclusa).
  final DateTime a;

  /// Progetto (solo per [TipoPeriodo.progetto]).
  final int? progettoId;

  /// Vero se il periodo arriva ad adesso (giorno/settimana in corso o
  /// progetto senza nota "fine").
  final bool aperto;

  /// Vero se la fine del progetto è stata scelta a mano.
  final bool fineAMano;

  /// Ore del periodo.
  double get ore => a.isAfter(da) ? oreTra(da, a) : 0;
}

DateTime _mezzanotte(DateTime d) => DateTime(d.year, d.month, d.day);

/// Giorno di [giorno] (mezzanotte -> mezzanotte dopo); se è oggi finisce
/// ad [adesso].
PeriodoIA periodoGiorno(DateTime giorno, DateTime adesso) {
  final DateTime da = _mezzanotte(giorno);
  final DateTime fine = DateTime(da.year, da.month, da.day + 1);
  final bool aperto = adesso.isBefore(fine);
  return PeriodoIA(
    tipo: TipoPeriodo.giorno,
    da: da,
    a: aperto ? piuTardi(adesso, da) : fine,
    aperto: aperto,
  );
}

/// Settimana che contiene [t] (reset -> reset); se è in corso finisce ad
/// [adesso].
PeriodoIA periodoSettimana(
  DateTime t,
  DateTime adesso, {
  int giorno = DateTime.tuesday,
  int h = 20,
  int m = 0,
}) {
  final DateTime da = inizioSettimana(t, giorno: giorno, h: h, m: m);
  final DateTime fine = DateTime(da.year, da.month, da.day + 7, h, m);
  final bool aperto = adesso.isBefore(fine);
  return PeriodoIA(
    tipo: TipoPeriodo.settimana,
    da: da,
    a: aperto ? piuTardi(adesso, da) : fine,
    aperto: aperto,
  );
}

/// Periodi (inizio -> fine) del progetto [id] dalle note-comando, dal più
/// vecchio. Aperto = fino ad [adesso].
List<IntervalloProgetto> periodiProgetto(
  int id,
  Iterable<Evento> eventi,
  Iterable<Progetto> progetti,
  DateTime adesso,
) => <IntervalloProgetto>[
  for (final IntervalloProgetto i in intervalliProgetti(
    eventi,
    progetti,
    adesso,
  ))
    if (i.progettoId == id) i,
];

/// Periodo del progetto [id] che copre [scelti] (dal primo inizio
/// all'ultima fine). [fine] scelta a mano (null = automatica: nota "fine"
/// o adesso se aperto). Null se [scelti] è vuoto o la fine è prima
/// dell'inizio.
PeriodoIA? periodoProgetto(
  int id,
  List<IntervalloProgetto> scelti, {
  DateTime? fine,
}) {
  if (scelti.isEmpty) {
    return null;
  }
  DateTime da = scelti.first.inizio;
  DateTime a = scelti.first.fine;
  bool aperto = false;
  for (final IntervalloProgetto i in scelti) {
    da = piuPresto(da, i.inizio);
    if (!i.fine.isBefore(a)) {
      a = i.fine;
      aperto = i.aperto;
    }
  }
  if (fine != null) {
    if (!fine.isAfter(da)) {
      return null;
    }
    return PeriodoIA(
      tipo: TipoPeriodo.progetto,
      da: da,
      a: fine,
      progettoId: id,
      fineAMano: true,
    );
  }
  return PeriodoIA(
    tipo: TipoPeriodo.progetto,
    da: da,
    a: a,
    progettoId: id,
    aperto: aperto,
  );
}

/// [da, a) tagliato ai reset settimanali: una parte per settimana.
List<({DateTime da, DateTime a})> partiSettimanali(
  DateTime da,
  DateTime a, {
  int giorno = DateTime.tuesday,
  int h = 20,
  int m = 0,
}) {
  final List<({DateTime da, DateTime a})> out = <({DateTime da, DateTime a})>[];
  DateTime x = da;
  while (x.isBefore(a)) {
    final DateTime ini = inizioSettimana(x, giorno: giorno, h: h, m: m);
    final DateTime fine = DateTime(ini.year, ini.month, ini.day + 7, h, m);
    final DateTime y = piuPresto(fine, a);
    out.add((da: x, a: y));
    x = y;
  }
  return out;
}

/// Richiesta all'IA, adattata al periodo.
String richiestaPeriodo(TipoPeriodo t) => switch (t) {
  TipoPeriodo.giorno =>
    "Scrivi un resoconto in italiano, breve e chiaro, di questo GIORNO d'uso "
        "di Claude: com'è andato il giorno, quanto è stato consumato "
        '(settimana e sessione 5 ore), picchi e a che ora, cosa ha consumato '
        'di più (progetti, note, lavoro), e uno o due consigli. Parla solo '
        'di questo giorno. Distingui sempre i DATI (misurati) dalle STIME. '
        'Non inventare numeri e non convertire le percentuali in token.',
  TipoPeriodo.settimana =>
    'Scrivi un resoconto in italiano, breve e chiaro, di questa SETTIMANA '
        "d'uso di Claude: andamento giorno per giorno, giorni più pesanti, "
        'consumo per progetto, picchi, differenza tra stima minima e massima '
        'dove i progetti sono simultanei, previsione per il resto della '
        'settimana se è in corso, e uno o due consigli. Distingui sempre i '
        'DATI (misurati) dalle STIME. Non inventare numeri e non convertire '
        'le percentuali in token.',
  TipoPeriodo.progetto =>
    'Scrivi un resoconto in italiano, breve e chiaro, di questo PROGETTO: '
        'quanto è costato in punti % settimanali e % sessione 5 ore (con '
        'stima minima e massima), token solo se scritti a mano, ore di '
        'lavoro, fasi (giorni e momenti più pesanti), cosa ha consumato di '
        'più, e uno o due consigli per il prossimo progetto simile. Parla '
        'solo di questo progetto. Distingui sempre i DATI (misurati) dalle '
        'STIME. Non inventare numeri e non convertire le percentuali in '
        'token.',
};

/// Parte del nome file dopo la data: 'giorno', 'settimana',
/// `progetto-NOME`.
String parteNomePeriodo(PeriodoIA p, {String nomeProgetto = ''}) =>
    p.tipo == TipoPeriodo.progetto ? 'progetto-$nomeProgetto' : p.tipo.codice;

/// Nome file del testo per l'IA, es. 'traker-ia_2026-11-20_giorno.md'.
String nomeFilePeriodo(PeriodoIA p, {String nomeProgetto = ''}) =>
    nomeFileEsportazione(
      p.da,
      nome: parteNomePeriodo(p, nomeProgetto: nomeProgetto),
    );

/// Vero se [nomeFile] è il resoconto salvato di questo periodo.
bool resocontoDelPeriodo(
  String nomeFile,
  PeriodoIA p, {
  String nomeProgetto = '',
}) {
  final String base = nomeFilePeriodo(p, nomeProgetto: nomeProgetto);
  return nomeFile.endsWith('_resoconto.md') &&
      nomeFile.startsWith('${base.substring(0, base.length - 3)}_');
}

String _n(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

double _num(Object? v) => v is num ? v.toDouble() : 0;

/// Righe d'archivio (formato B14) con i soli dati del periodo [p].
/// Settimana: [archiviate] di quella settimana se ci sono (istantanea),
/// altrimenti calcolo dalle letture. Giorno: calcolo. Progetto: una parte
/// per settimana, solo la riga del progetto.
List<SettimanaProgetto> righePeriodo(
  PeriodoIA p, {
  required List<Lettura> letture,
  required List<Evento> eventi,
  required List<Progetto> progetti,
  Iterable<SettimanaProgetto> archiviate = const <SettimanaProgetto>[],
  Piano? piano,
}) {
  if (!p.a.isAfter(p.da)) {
    return <SettimanaProgetto>[];
  }
  List<SettimanaProgetto> calcola(DateTime da, DateTime a, Piano? pi) =>
      archiviaSettimana(
        letture: letture,
        eventi: eventi,
        progetti: progetti,
        inizio: da,
        fine: a,
        piano: pi,
      );
  switch (p.tipo) {
    case TipoPeriodo.giorno:
      return calcola(p.da, p.a, null);
    case TipoPeriodo.settimana:
      final List<SettimanaProgetto> gia = <SettimanaProgetto>[
        for (final SettimanaProgetto r in archiviate)
          if (r.inizio == p.da) r,
      ];
      if (gia.isNotEmpty && !p.aperto) {
        return gia;
      }
      return calcola(p.da, p.a, piano);
    case TipoPeriodo.progetto:
      return <SettimanaProgetto>[
        for (final ({DateTime da, DateTime a}) x in partiSettimanali(p.da, p.a))
          for (final SettimanaProgetto r in calcola(x.da, x.a, null))
            if (r.progettoId == p.progettoId) r,
      ];
  }
}

/// Totale del progetto su tutte le parti (somma dei riassunti).
String _totaleProgetto(List<SettimanaProgetto> righe) {
  double s = 0;
  double sMin = 0;
  double sMax = 0;
  double q = 0;
  double qMin = 0;
  double qMax = 0;
  double ore = 0;
  int? token;
  for (final SettimanaProgetto r in righe) {
    final Map<String, Object?> ri = leggiIstantanea(r.istantanea).riassunto;
    final Object? a = ri['sett'];
    final Object? b = ri['sess'];
    if (a is Map<String, Object?>) {
      s += _num(a['stima']);
      sMin += _num(a['min']);
      sMax += _num(a['max']);
    }
    if (b is Map<String, Object?>) {
      q += _num(b['stima']);
      qMin += _num(b['min']);
      qMax += _num(b['max']);
    }
    ore += _num(ri['ore_attive']);
    if (r.tokenManuali != null) {
      token = (token ?? 0) + r.tokenManuali!;
    }
  }
  return 'TOTALE_PROGETTO (somma parti): '
      'sett_pt=~${_n(s)} (min ${_n(sMin)} - max ${_n(sMax)}) '
      'sess_pt=~${_n(q)} (min ${_n(qMin)} - max ${_n(qMax)}) '
      'ore_attive=${durata(ore)} token_manuali=${token ?? 'non noti'} '
      '${Testi.stima}';
}

/// Testo per l'IA del periodo [p] (solo dati dentro [da, a)).
/// [nomi] = nome per id progetto.
String esportaPeriodo(
  PeriodoIA p, {
  required List<Lettura> letture,
  required List<Evento> eventi,
  required List<Progetto> progetti,
  Iterable<SettimanaProgetto> archiviate = const <SettimanaProgetto>[],
  Piano? piano,
  DateTime? creato,
}) {
  final List<SettimanaProgetto> righe = righePeriodo(
    p,
    letture: letture,
    eventi: eventi,
    progetti: progetti,
    archiviate: archiviate,
    piano: piano,
  );
  final Map<int, String> nomi = <int, String>{
    for (final SettimanaProgetto r in righe)
      r.progettoId: nomeProgetto(r.progettoId, progetti),
    if (p.progettoId != null)
      p.progettoId!: nomeProgetto(p.progettoId!, progetti),
  };
  final String fine = p.aperto
      ? '${formatta(p.a)} (in corso, fino ad adesso)'
      : formatta(p.a);
  final List<String> testa = <String>[
    'PERIODO: tipo=${p.tipo.codice} da=${formatta(p.da)} a=$fine '
        'durata=${durata(p.ore)}',
    'NOTA: dati SOLO dentro questo periodo (letture, note, eventi, piano).',
    if (p.tipo == TipoPeriodo.progetto) ...<String>[
      'PROGETTO: "${nomi[p.progettoId] ?? '#${p.progettoId}'}" '
          'fine=${p.fineAMano
              ? 'scelta a mano (nota fine mancante o sbagliata)'
              : p.aperto
              ? 'nessuna nota fine: fino ad adesso'
              : 'da nota fine'} '
          'parti_settimanali=${righe.length}',
      _totaleProgetto(righe),
    ],
  ];
  return esportaPerIA(
    righe,
    nomi,
    creato: creato,
    richiesta: richiestaPeriodo(p.tipo),
    intestazione: testa,
  );
}
