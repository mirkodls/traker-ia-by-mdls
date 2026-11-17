// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain (V2, B14): "Esporta per IA". Crea un testo denso con dati,
// eventi, serie riassunte, parametri del piano e stime (sempre con etichetta
// STIMA) da incollare in Claude, con in cima la richiesta di resoconto.
// L'app NON chiama nessuna IA. Mai cookie/token/chiavi nel testo.
import 'package:traker_ia/domain/archivio_settimane.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';

/// Versione del formato del testo esportato.
const int versioneEsportazione = 1;

/// Parole che NON devono mai comparire nel testo esportato (chiavi/segreti).
/// Le righe di testo libero che le contengono vengono sostituite.
final RegExp parolaVietataEsportazione = RegExp(
  r'cookie|session[-_ ]?key|sk-ant|segret|password|bearer|authorization',
  caseSensitive: false,
);

/// Testo che sostituisce una riga con parole vietate.
const String rigaRimossa = '[RIMOSSO]';

String _pulisci(String s) {
  final String una = s.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
  return parolaVietataEsportazione.hasMatch(una) ? rigaRimossa : una;
}

String _n(Object? v, {int dec = 1}) {
  if (v is! num) {
    return '-';
  }
  final double d = v.toDouble();
  if (dec == 0 || d == d.roundToDouble()) {
    return d.round().toString();
  }
  return d.toStringAsFixed(dec);
}

String _stima(Object? m) {
  if (m is! Map<String, Object?>) {
    return '-';
  }
  return '~${_n(m['stima'])} (min ${_n(m['min'])} - max ${_n(m['max'])}) '
      '${Testi.stima}';
}

String _giorno(DateTime d) => formatta(d).substring(0, 10);

/// Nome file consigliato, es. 'traker-ia_2026-11-10_progetto-x.md'.
/// [nome] vuoto = senza parte progetto.
String nomeFileEsportazione(DateTime inizio, {String nome = ''}) {
  final String slug = nome
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final String corto = slug.length > 30 ? slug.substring(0, 30) : slug;
  return 'traker-ia_${_giorno(inizio)}${corto.isEmpty ? '' : '_$corto'}.md';
}

/// Riga di richiesta all'IA (in italiano), messa in cima.
const String richiestaResoconto =
    'Scrivi un resoconto in italiano, breve e chiaro, di questa settimana '
    "d'uso di Claude: quanto è stato consumato (settimana e sessione 5 ore), "
    'quando e per quale progetto, picchi, giorni anomali, differenza tra '
    'stima minima e massima dove i progetti sono simultanei, e uno o due '
    'consigli. Distingui sempre i DATI (misurati) dalle STIME. Non inventare '
    'numeri e non convertire le percentuali in token.';

/// Riassunto per giorno delle letture: 'aaaa-mm-gg n=.. sett_ultimo=..
/// sess_max=.. lavoro_n=..'.
List<String> _giorni(List<Lettura> letture) {
  final Map<String, List<Lettura>> perGiorno = <String, List<Lettura>>{};
  for (final Lettura l in letture) {
    perGiorno.putIfAbsent(_giorno(l.ora), () => <Lettura>[]).add(l);
  }
  final List<String> chiavi = perGiorno.keys.toList()..sort();
  final List<String> out = <String>[];
  for (final String k in chiavi) {
    final List<Lettura> v = perGiorno[k]!;
    double? settUlt;
    double? sessMax;
    int lavoro = 0;
    for (final Lettura l in v) {
      if (l.sett != null) {
        settUlt = l.sett;
      }
      if (l.sess != null && (sessMax == null || l.sess! > sessMax)) {
        sessMax = l.sess;
      }
      if (l.lavoro) {
        lavoro++;
      }
    }
    out.add(
      '$k n=${v.length} sett_ultimo=${_n(settUlt, dec: 0)} '
      'sess_max=${_n(sessMax, dec: 0)} lavoro_n=$lavoro',
    );
  }
  return out;
}

int _reset(List<Lettura> letture) {
  int n = 0;
  Lettura? prima;
  for (final Lettura l in letture) {
    if (prima != null &&
        prima.sess != null &&
        l.sess != null &&
        l.sess! < prima.sess! - 20) {
      n++;
    }
    prima = l;
  }
  return n;
}

List<List<Object?>> _serie(Object? s, String chiave) {
  if (s is! Map<String, Object?>) {
    return const <List<Object?>>[];
  }
  final Object? l = s[chiave];
  if (l is! List<Object?>) {
    return const <List<Object?>>[];
  }
  return <List<Object?>>[
    for (final Object? r in l)
      if (r is List<Object?> && r.length >= 2) r,
  ];
}

String _riassuntoSerie(List<List<Object?>> s, int colonna) {
  if (s.isEmpty) {
    return 'n=0';
  }
  double somma = 0;
  double? picco;
  int n = 0;
  for (final List<Object?> r in s) {
    final Object? v = r.length > colonna ? r[colonna] : null;
    if (v is num) {
      somma += v.toDouble();
      n++;
      if (picco == null || v > picco) {
        picco = v.toDouble();
      }
    }
  }
  final Object? ultimo = s.last.length > colonna ? s.last[colonna] : null;
  return 'n=${s.length} media=${n == 0 ? '-' : _n(somma / n)} '
      'picco=${_n(picco)} ultimo=${_n(ultimo)}';
}

void _riga(StringBuffer b, SettimanaProgetto r, Map<int, String> nomi) {
  final IstantaneaLetta d = leggiIstantanea(r.istantanea);
  final String nome = _pulisci(nomi[r.progettoId] ?? '#${r.progettoId}');
  final DateTime? fine = r.fine;
  b.writeln(
    '## PROGETTO "$nome" | SETT ${formatta(r.inizio)} -> '
    '${fine == null ? 'in corso' : formatta(fine)}',
  );
  if (d.versione == 0) {
    b.writeln('DATI: istantanea non leggibile (salto serie e piano)');
  }
  final Map<String, Object?> ri = d.riassunto;
  b.writeln('STIMA_SETT_PT: ${_stima(ri['sett'])}');
  b.writeln('STIMA_SESS_PT: ${_stima(ri['sess'])}');
  b.writeln(
    'ORE_ATTIVE=${_n(ri['ore_attive'])} '
    'ORE_CONDIVISE=${_n(ri['ore_condivise'])} '
    '(ore: dato; riparto tra progetti: ${Testi.stima})',
  );
  b.writeln(
    'STIMA_MEDIA_PT_ORA: sett=${_n(ri['media_sett_ora'], dec: 2)} '
    'sess=${_n(ri['media_sess_ora'])} picco_sess=${_n(ri['picco_sess_ora'])} '
    '${Testi.stima}',
  );
  b.writeln(
    'TOTALE_UTENTE_PT (tutti i progetti, dato): '
    'sett=${_n(ri['totale_sett'])} sess=${_n(ri['totale_sess'])}',
  );
  b.writeln(
    'TOKEN_MANUALI (scritti a mano, dato): '
    '${r.tokenManuali ?? 'non noti'}',
  );
  final Object? piano = d.grezza['piano'];
  if (piano is Map<String, Object?>) {
    b.writeln(
      'PIANO: nome="${_pulisci('${piano['nome']}')}" '
      'giorni_mask=${piano['giorni_mask']} target_pct=${piano['target_pct']} '
      'confine=${piano['confine']}',
    );
  } else {
    b.writeln('PIANO: nessuno');
  }
  b.writeln(
    'LETTURE: n=${d.letture.length} reset_sess_visti=${_reset(d.letture)}',
  );
  for (final String g in _giorni(d.letture)) {
    b.writeln('  $g');
  }
  final Object? serie = d.grezza['serie'];
  b.writeln(
    'SERIE intensita pt_sess/h (passo '
    '${serie is Map<String, Object?> ? serie['passo_min'] : '-'} min): '
    '${_riassuntoSerie(_serie(serie, 'intensita'), 2)}',
  );
  b.writeln(
    'SERIE ideale: ${_riassuntoSerie(_serie(serie, 'ideale'), 1)} | '
    'adattiva: ${_riassuntoSerie(_serie(serie, 'adattiva'), 1)}',
  );
  b.writeln(
    'INTERVALLI_PROGETTO: ${d.intervalli.length}'
    '${d.intervalli.isEmpty ? '' : ' ('
              '${d.intervalli.map((({DateTime inizio, DateTime fine}) i) => '${formatta(i.inizio)}>${formatta(i.fine)}').join('; ')})'}',
  );
  b.writeln('EVENTI/LOG (ora | codice | progetto | testo):');
  final List<String> righe = r.log
      .split(RegExp(r'[\r\n]+'))
      .map((String s) => s.trim())
      .where((String s) => s.isNotEmpty)
      .toList();
  if (righe.isEmpty) {
    b.writeln('  (nessun evento)');
  }
  for (final String l in righe) {
    b.writeln('  ${_pulisci(l)}');
  }
  b.writeln();
}

/// Testo da incollare in Claude per le [righe] (1 progetto o tutta una
/// settimana). [nomi] = nome per id progetto. [creato] = ora della
/// creazione (null = non scritta).
String esportaPerIA(
  Iterable<SettimanaProgetto> righe,
  Map<int, String> nomi, {
  DateTime? creato,
}) {
  final List<SettimanaProgetto> ordine = righe.toList()
    ..sort((SettimanaProgetto a, SettimanaProgetto b) {
      final int c = a.inizio.compareTo(b.inizio);
      return c != 0 ? c : a.progettoId.compareTo(b.progettoId);
    });
  final StringBuffer b = StringBuffer()
    ..writeln('RICHIESTA: $richiestaResoconto')
    ..writeln()
    ..writeln(
      '# TraKer IA export v$versioneEsportazione'
      '${creato == null ? '' : ' creato ${formatta(creato)}'}',
    )
    ..writeln(
      'LEGENDA: DATI = misurati dalle letture. ${Testi.stima} = calcolata '
      '(riparto tra progetti simultanei, min/max). pt = punti percentuali '
      'di % settimanale o % sessione 5 ore. Nessun token calcolato dalle %.',
    )
    ..writeln();
  if (ordine.isEmpty) {
    b.writeln('(nessuna settimana da esportare)');
  }
  for (final SettimanaProgetto r in ordine) {
    _riga(b, r, nomi);
  }
  return b.toString();
}
