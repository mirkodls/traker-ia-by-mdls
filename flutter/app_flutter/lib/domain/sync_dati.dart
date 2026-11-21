// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: cosa passa nel sync Wi-Fi (B22) e come si unisce.
// Regole: si AGGIUNGE soltanto (letture, eventi, progetti, settimane);
// impostazioni = solo quelle dell'elenco [chiaviSync], vince la più recente.
// MAI segreti: cookie, chiavi IA, cassaforte non entrano nel pacco (chi
// riceve scarta comunque ogni chiave fuori elenco).
import 'modelli.dart';
import 'piani_progetti.dart';
import 'preferenze.dart';
import 'stile_linee.dart';
import 'tempo.dart';

/// Versione del protocollo.
const int versioneSync = 1;

/// Porta UDP della ricerca in rete.
const int portaRicerca = 45790;

/// Porta TCP del PC.
const int portaSync = 45791;

/// Domanda della ricerca (telefono -> tutti).
const String domandaRicerca = 'TRAKERIA?1';

/// Inizio della risposta del PC: `TRAKERIA!1 porta id`.
const String rispostaRicerca = 'TRAKERIA!1';

/// Minuti in cui il PC accetta un abbinamento dopo il tasto.
const int minutiAbbinamento = 3;

/// Giorni ripassati a ogni sync (righe aggiunte tardi, orologi storti).
const int giorniMargineSync = 7;

/// Impostazioni sincronizzate (tutte le altre restano del dispositivo:
/// minuti, metodo, vista, cartelle, sottofondo, permessi, IA, login).
final List<String> chiaviSync = <String>[
  for (final LineaGrafico l in LineaGrafico.values) ...<String>[
    l.chiaveAlfa,
    l.chiaveSpessore,
    l.chiaveColore,
  ],
  Chiavi.v2RossoAcceso,
  Chiavi.v2SogliaRosso,
  Chiavi.v2Lavoro,
  Chiavi.v2PianoGiorni,
  Chiavi.v2LineaIdeale,
  Chiavi.v2LineaAdattiva,
  Chiavi.v2FinestraPostuma,
];

/// Chiave (impostazioni) con l'ora dell'ultimo cambio di [k], in ms.
String chiaveOrario(String k) => 'sync_t_$k';

/// Chiavi impostazioni del sync (non segrete).
abstract final class ChiaviSync {
  /// Id di questo dispositivo (16 esadecimali).
  static const String id = 'sync_id';

  /// Telefono: ultimo indirizzo del PC.
  static const String ipPc = 'sync_ip_pc';

  /// Telefono: fine dell'ultimo sync riuscito ('aaaa-mm-gg hh:mm').
  static const String ultimo = 'sync_ultimo';
}

/// Chiave in CASSAFORTE con le coppie (JSON, contiene chiavi segrete).
const String chiaveCoppieSync = 'sync_coppie';

/// Da quando mandare le righe: null = tutto (primo sync o "tutto").
DateTime? daQuando(DateTime? ultimo, {bool tutto = false}) =>
    tutto || ultimo == null
    ? null
    : ultimo.subtract(const Duration(days: giorniMargineSync));

/// Settimana di progetto nel pacco (il progetto per nome: gli id cambiano
/// tra PC e telefono).
class SettimanaSync {
  /// Crea la riga.
  const SettimanaSync({
    required this.progetto,
    required this.inizio,
    required this.fine,
    required this.istantanea,
    required this.log,
    this.token,
  });

  /// Nome del progetto.
  final String progetto;

  /// Inizio settimana.
  final DateTime inizio;

  /// Fine settimana (null = in corso).
  final DateTime? fine;

  /// Istantanea JSON.
  final String istantanea;

  /// Log testuale.
  final String log;

  /// Token scritti a mano.
  final int? token;
}

/// Impostazione nel pacco: valore e ora del cambio (ms, 0 = mai cambiata).
typedef ValoreSync = ({String valore, int ora});

/// Tutto quello che un lato manda all'altro.
class PaccoSync {
  /// Crea il pacco.
  const PaccoSync({
    this.da,
    this.letture = const <Lettura>[],
    this.eventi = const <Evento>[],
    this.progetti = const <Progetto>[],
    this.settimane = const <SettimanaSync>[],
    this.impostazioni = const <String, ValoreSync>{},
  });

  /// Pacco da JSON; righe rotte saltate, impostazioni fuori elenco scartate.
  factory PaccoSync.daJson(Map<String, Object?> j) {
    final List<Lettura> ls = <Lettura>[];
    for (final Object? o in _lista(j['letture'])) {
      final Lettura? l = _lettura(o);
      if (l != null) {
        ls.add(l);
      }
    }
    final List<Evento> es = <Evento>[];
    for (final Object? o in _lista(j['eventi'])) {
      final Evento? e = _evento(o);
      if (e != null) {
        es.add(e);
      }
    }
    final List<Progetto> ps = <Progetto>[];
    for (final Object? o in _lista(j['progetti'])) {
      if (o is Map &&
          o['nome'] is String &&
          (o['nome'] as String).trim() != '') {
        ps.add(
          Progetto(
            nome: (o['nome'] as String).trim(),
            colore: o['colore'] is int ? o['colore'] as int : 0,
            note: o['note'] is String ? o['note'] as String : '',
          ),
        );
      }
    }
    final List<SettimanaSync> ss = <SettimanaSync>[];
    for (final Object? o in _lista(j['settimane'])) {
      if (o is! Map) {
        continue;
      }
      final DateTime? ini = interpreta('${o['inizio']}');
      final Object? p = o['progetto'];
      if (ini == null || p is! String || p.trim() == '') {
        continue;
      }
      ss.add(
        SettimanaSync(
          progetto: p.trim(),
          inizio: ini,
          fine: o['fine'] is String ? interpreta(o['fine'] as String) : null,
          istantanea: o['istantanea'] is String
              ? o['istantanea'] as String
              : '{}',
          log: o['log'] is String ? o['log'] as String : '',
          token: o['token'] is int && (o['token'] as int) >= 0
              ? o['token'] as int
              : null,
        ),
      );
    }
    final Map<String, ValoreSync> imp = <String, ValoreSync>{};
    final Object? mi = j['impostazioni'];
    if (mi is Map) {
      for (final String k in chiaviSync) {
        final Object? v = mi[k];
        if (v is Map && v['v'] is String && v['t'] is int) {
          imp[k] = (valore: v['v'] as String, ora: v['t'] as int);
        }
      }
    }
    final Object? da = j['da'];
    return PaccoSync(
      da: da is String ? interpreta(da) : null,
      letture: ls,
      eventi: es,
      progetti: ps,
      settimane: ss,
      impostazioni: imp,
    );
  }

  /// Da quando sono le righe (null = tutte).
  final DateTime? da;

  /// Letture.
  final List<Lettura> letture;

  /// Eventi.
  final List<Evento> eventi;

  /// Progetti (sempre tutti: sono pochi).
  final List<Progetto> progetti;

  /// Settimane archiviate.
  final List<SettimanaSync> settimane;

  /// Impostazioni dell'elenco [chiaviSync].
  final Map<String, ValoreSync> impostazioni;

  /// Pacco in JSON (chiavi corte: meno byte in rete).
  Map<String, Object?> aJson() => <String, Object?>{
    'da': da == null ? null : formatta(da!),
    'letture': <Object?>[
      for (final Lettura l in letture)
        <String, Object?>{
          'o': formatta(l.ora),
          'w': l.sett,
          's': l.sess,
          if (l.fable != null) 'b': l.fable,
          'f': l.fonte,
          if (l.alPc != null) 'p': l.alPc,
          'l': l.lavoro,
          if (l.modelli != '') 'm': l.modelli,
          if (l.skill != '') 'k': l.skill,
          'g': l.gestore,
        },
    ],
    'eventi': <Object?>[
      for (final Evento e in eventi)
        <String, Object?>{'o': formatta(e.ora), 't': e.tipo.name, 'x': e.testo},
    ],
    'progetti': <Object?>[
      for (final Progetto p in progetti)
        <String, Object?>{'nome': p.nome, 'colore': p.colore, 'note': p.note},
    ],
    'settimane': <Object?>[
      for (final SettimanaSync s in settimane)
        <String, Object?>{
          'progetto': s.progetto,
          'inizio': formatta(s.inizio),
          'fine': s.fine == null ? null : formatta(s.fine!),
          'istantanea': s.istantanea,
          'log': s.log,
          'token': s.token,
        },
    ],
    'impostazioni': <String, Object?>{
      for (final MapEntry<String, ValoreSync> e in impostazioni.entries)
        if (chiaviSync.contains(e.key))
          e.key: <String, Object?>{'v': e.value.valore, 't': e.value.ora},
    },
  };

  /// Righe dal momento [da] in poi (null = tutte).
  static List<T> dal<T>(
    Iterable<T> righe,
    DateTime Function(T) ora,
    DateTime? da,
  ) => <T>[
    for (final T r in righe)
      if (da == null || !ora(r).isBefore(da)) r,
  ];
}

List<Object?> _lista(Object? o) => o is List ? o : const <Object?>[];

double? _num(Object? o) {
  if (o is num && o.isFinite && o >= 0 && o <= 1000) {
    return o.toDouble();
  }
  return null;
}

Lettura? _lettura(Object? o) {
  if (o is! Map) {
    return null;
  }
  final DateTime? t = interpreta('${o['o']}');
  final double? w = _num(o['w']);
  final double? s = _num(o['s']);
  if (t == null || (w == null && s == null)) {
    return null;
  }
  String testo(String k, String predef) =>
      o[k] is String ? o[k] as String : predef;
  return Lettura(
    ora: t,
    sett: w,
    sess: s,
    fable: _num(o['b']),
    fonte: testo('f', 'auto'),
    alPc: o['p'] is bool ? o['p'] as bool : null,
    lavoro: o['l'] == true,
    modelli: testo('m', ''),
    skill: testo('k', ''),
    gestore: testo('g', gestoreAnthropic),
  );
}

Evento? _evento(Object? o) {
  if (o is! Map) {
    return null;
  }
  final DateTime? t = interpreta('${o['o']}');
  TipoEvento? tipo;
  for (final TipoEvento x in TipoEvento.values) {
    if (x.name == o['t']) {
      tipo = x;
    }
  }
  if (t == null || tipo == null) {
    return null;
  }
  return Evento(
    ora: t,
    tipo: tipo,
    testo: o['x'] is String ? o['x'] as String : '',
  );
}

/// Nome normalizzato (maiuscole e spazi ignorati), come il controllo nomi.
String nomeNormale(String n) => n.trim().toLowerCase();

/// Progetti [arrivati] che non ho (per nome).
List<Progetto> progettiNuovi(
  Iterable<Progetto> miei,
  Iterable<Progetto> arrivati,
) {
  final Set<String> gia = <String>{
    for (final Progetto p in miei) nomeNormale(p.nome),
  };
  final List<Progetto> nuovi = <Progetto>[];
  for (final Progetto p in arrivati) {
    if (gia.add(nomeNormale(p.nome))) {
      nuovi.add(p);
    }
  }
  return nuovi;
}

/// Impostazioni [arrivate] da scrivere qui: solo elenco [chiaviSync], solo
/// se cambiate DOPO la mia ([mieOre] in ms; mancante = 0) e diverse.
Map<String, ValoreSync> impostazioniDaApplicare(
  Map<String, String?> mieValori,
  Map<String, int> mieOre,
  Map<String, ValoreSync> arrivate,
) => <String, ValoreSync>{
  for (final MapEntry<String, ValoreSync> e in arrivate.entries)
    if (chiaviSync.contains(e.key) &&
        e.value.ora > (mieOre[e.key] ?? 0) &&
        e.value.valore != mieValori[e.key])
      e.key: e.value,
};

/// Esito di un sync per la grafica.
class EsitoSync {
  /// Crea l'esito.
  const EsitoSync({
    required this.ok,
    required this.messaggio,
    this.ricevute = 0,
    this.nomeAltro = '',
  });

  /// Riuscito.
  final bool ok;

  /// Testo per l'utente (italiano, da Testi).
  final String messaggio;

  /// Righe nuove arrivate qui (letture+eventi+progetti+settimane).
  final int ricevute;

  /// Nome dell'altro dispositivo.
  final String nomeAltro;
}
