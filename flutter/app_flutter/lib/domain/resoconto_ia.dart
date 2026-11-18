// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain (V2, B17): "Resoconto IA" via API di qualsiasi IA.
// Qui solo calcoli puri: impostazioni del fornitore (mai la chiave), come si
// costruisce la richiesta, come si legge la risposta, messaggi di errore in
// italiano, nome e testo del file .md salvato. La chiave API arriva da fuori
// (cassaforte) e non finisce MAI in testi, nomi file o messaggi.
import 'dart:convert';

import 'package:traker_ia/domain/export_ia.dart';
import 'package:traker_ia/domain/tempo.dart';

/// Fornitori di IA supportati.
enum FornitoreIA {
  /// Anthropic (Claude): POST /v1/messages.
  anthropic(
    'anthropic',
    'Anthropic (Claude)',
    'claude-sonnet-5-5',
    'https://api.anthropic.com',
  ),

  /// OpenAI: POST /v1/chat/completions.
  openai('openai', 'OpenAI', 'gpt-5.4-mini', 'https://api.openai.com/v1'),

  /// Google Gemini: POST `/v1beta/models/MODELLO:generateContent`.
  gemini(
    'gemini',
    'Google Gemini',
    'gemini-flash-latest',
    'https://generativelanguage.googleapis.com/v1beta',
  ),

  /// Qualsiasi servizio "compatibile OpenAI" (OpenRouter, Mistral, modelli
  /// sul PC...): URL base scritto a mano + /chat/completions.
  compatibile('compatibile', 'Compatibile OpenAI', '', '');

  const FornitoreIA(this.id, this.nome, this.modelloPredefinito, this.url);

  /// Nome breve salvato nelle impostazioni.
  final String id;

  /// Nome mostrato.
  final String nome;

  /// Modello proposto ('' = da scrivere a mano).
  final String modelloPredefinito;

  /// Indirizzo base fisso ('' = da scrivere a mano).
  final String url;

  /// Chiave della cassaforte dove sta la chiave API di questo fornitore.
  String get chiaveCassaforte => 'ia_api_$id';

  /// Chiave impostazioni del modello scelto per questo fornitore.
  String get chiaveModello => 'v2_ia_modello_$id';

  /// Vero se la chiave API serve per forza (compatibile: modelli sul PC
  /// spesso non la vogliono).
  bool get chiaveObbligatoria => this != FornitoreIA.compatibile;

  /// Fornitore dal nome salvato (sconosciuto/vuoto = Anthropic).
  static FornitoreIA daId(String? s) {
    final String t = (s ?? '').trim();
    for (final FornitoreIA f in FornitoreIA.values) {
      if (f.id == t) {
        return f;
      }
    }
    return FornitoreIA.anthropic;
  }
}

/// Chiave impostazioni del fornitore scelto.
const String chiaveIAFornitore = 'v2_ia_fornitore';

/// Chiave impostazioni dell'URL base del fornitore "compatibile".
const String chiaveIAUrl = 'v2_ia_url';

/// Tutte le chiavi impostazioni del resoconto IA (nessun segreto).
final List<String> chiaviIA = <String>[
  chiaveIAFornitore,
  chiaveIAUrl,
  for (final FornitoreIA f in FornitoreIA.values) f.chiaveModello,
];

/// Lunghezza massima di nome modello e URL.
const int maxLunghezzaCampoIA = 200;

String _pulito(String? s) {
  final String t = (s ?? '').trim();
  return t.length > maxLunghezzaCampoIA
      ? t.substring(0, maxLunghezzaCampoIA)
      : t;
}

/// Impostazioni del resoconto IA (immutabili, MAI la chiave API).
class ConfigIA {
  /// Crea le impostazioni. [modelli] = modello scritto per fornitore.
  ConfigIA({
    this.fornitore = FornitoreIA.anthropic,
    Map<FornitoreIA, String> modelli = const <FornitoreIA, String>{},
    String url = '',
  }) : url = _pulito(url),
       modelli = Map<FornitoreIA, String>.unmodifiable(<FornitoreIA, String>{
         for (final MapEntry<FornitoreIA, String> e in modelli.entries)
           if (_pulito(e.value).isNotEmpty) e.key: _pulito(e.value),
       });

  /// Da impostazioni salvate. Valori rotti -> predefiniti.
  factory ConfigIA.daMappa(Map<String, String?> m) => ConfigIA(
    fornitore: FornitoreIA.daId(m[chiaveIAFornitore]),
    modelli: <FornitoreIA, String>{
      for (final FornitoreIA f in FornitoreIA.values)
        f: m[f.chiaveModello] ?? '',
    },
    url: m[chiaveIAUrl] ?? '',
  );

  /// Fornitore scelto.
  final FornitoreIA fornitore;

  /// Modelli scritti a mano (mancante = predefinito del fornitore).
  final Map<FornitoreIA, String> modelli;

  /// URL base del fornitore "compatibile".
  final String url;

  /// Modello da usare per [f] (scritto o predefinito).
  String modelloDi(FornitoreIA f) => modelli[f] ?? f.modelloPredefinito;

  /// Modello del fornitore scelto.
  String get modello => modelloDi(fornitore);

  /// Indirizzo base del fornitore scelto (fisso o scritto a mano).
  String get urlBase =>
      fornitore == FornitoreIA.compatibile ? url : fornitore.url;

  /// Impostazioni da salvare.
  Map<String, String> aMappa() => <String, String>{
    chiaveIAFornitore: fornitore.id,
    chiaveIAUrl: url,
    for (final FornitoreIA f in FornitoreIA.values)
      f.chiaveModello: modelli[f] ?? '',
  };

  /// Copia con alcuni valori cambiati ([modello] = del fornitore scelto
  /// dopo il cambio).
  ConfigIA copia({FornitoreIA? fornitore, String? modello, String? url}) {
    final FornitoreIA f = fornitore ?? this.fornitore;
    final Map<FornitoreIA, String> m = Map<FornitoreIA, String>.of(modelli);
    if (modello != null) {
      final String t = _pulito(modello);
      if (t.isEmpty || t == f.modelloPredefinito) {
        m.remove(f);
      } else {
        m[f] = t;
      }
    }
    return ConfigIA(fornitore: f, modelli: m, url: url ?? this.url);
  }

  @override
  bool operator ==(Object other) =>
      other is ConfigIA &&
      other.fornitore == fornitore &&
      other.url == url &&
      FornitoreIA.values.every(
        (FornitoreIA f) => other.modelli[f] == modelli[f],
      );

  @override
  int get hashCode => Object.hash(
    fornitore,
    url,
    Object.hashAll(FornitoreIA.values.map((FornitoreIA f) => modelli[f])),
  );
}

/// Errore del resoconto IA: messaggio in italiano, MAI chiavi o header.
class ErroreIA implements Exception {
  /// Crea l'errore.
  const ErroreIA(this.messaggio);

  /// Messaggio per l'utente.
  final String messaggio;

  @override
  String toString() => messaggio;
}

/// Lunghezza minima di una chiave API plausibile.
const int minLunghezzaChiave = 8;

/// Lunghezza massima di una chiave API.
const int maxLunghezzaChiave = 400;

/// Controlla una chiave API incollata. Ritorna null se va bene, altrimenti
/// il motivo (mai la chiave).
String? problemaChiave(String chiave) {
  final String k = chiave.trim();
  if (k.isEmpty) {
    return 'chiave vuota';
  }
  if (k.length < minLunghezzaChiave) {
    return 'chiave troppo corta';
  }
  if (k.length > maxLunghezzaChiave) {
    return 'chiave troppo lunga';
  }
  if (!RegExp(r'^[\x21-\x7E]+$').hasMatch(k)) {
    return 'chiave con spazi o caratteri strani: ricopiala';
  }
  return null;
}

/// Ultimi 4 caratteri della chiave, per mostrare "salvata ••••1234".
String fineChiave(String chiave) {
  final String k = chiave.trim();
  return k.length <= 4 ? '' : k.substring(k.length - 4);
}

/// Controlla l'URL base. Ritorna null se va bene, altrimenti il motivo.
/// HTTPS obbligatorio; HTTP solo verso questo PC (localhost/127.0.0.1).
String? problemaUrl(String url) {
  final Uri? u = Uri.tryParse(url.trim());
  if (url.trim().isEmpty || u == null || u.host.isEmpty) {
    return 'indirizzo mancante o sbagliato';
  }
  if (u.scheme == 'https') {
    return null;
  }
  final bool locale = const <String>{
    'localhost',
    '127.0.0.1',
    '::1',
  }.contains(u.host);
  if (u.scheme == 'http' && locale) {
    return null;
  }
  return 'serve un indirizzo https:// (http solo per questo PC)';
}

/// Richiesta HTTP pronta (POST JSON). toString NON mostra le intestazioni.
class RichiestaIA {
  /// Crea la richiesta.
  const RichiestaIA({
    required this.url,
    required this.intestazioni,
    required this.corpo,
  });

  /// Indirizzo completo (mai la chiave dentro).
  final Uri url;

  /// Intestazioni (QUI c'è la chiave: mai stampare).
  final Map<String, String> intestazioni;

  /// Corpo JSON.
  final String corpo;

  @override
  String toString() => 'RichiestaIA(POST ${url.host}${url.path})';
}

/// Token massimi della risposta del resoconto (i modelli che ragionano
/// spendono qui anche i token del ragionamento).
const int maxTokenResoconto = 16000;

/// Sforzo di ragionamento chiesto ad Anthropic (basso = meno token, meno
/// costo: per un riassunto basta).
const String sforzoAnthropic = 'low';

/// Token massimi della risposta di "Prova" (spazio anche per il
/// ragionamento dei modelli che pensano prima di rispondere).
const int maxTokenProva = 1024;

/// Testo mandato con "Prova".
const String testoProva = 'Rispondi solo con la parola: OK';

/// Versione API Anthropic.
const String versioneAnthropic = '2023-06-01';

String _senzaBarra(String s) =>
    s.endsWith('/') ? _senzaBarra(s.substring(0, s.length - 1)) : s;

/// Costruisce la richiesta per [c] con [testo] e [chiave] (vuota = nessuna,
/// solo "compatibile"). [base] = indirizzo base al posto di quello vero
/// (solo prove). Errore -> ErroreIA.
RichiestaIA costruisciRichiesta(
  ConfigIA c,
  String testo,
  String chiave, {
  int maxToken = maxTokenResoconto,
  Uri? base,
}) {
  final FornitoreIA f = c.fornitore;
  final String modello = c.modello;
  if (modello.isEmpty) {
    throw const ErroreIA('scrivi il nome del modello');
  }
  final String k = chiave.trim();
  if (f.chiaveObbligatoria && k.isEmpty) {
    throw const ErroreIA('manca la chiave API: mettila in Impostazioni');
  }
  final String radice = _senzaBarra(base?.toString() ?? c.urlBase);
  final String? probl = problemaUrl(radice);
  if (probl != null) {
    throw ErroreIA(probl);
  }
  final Map<String, String> h = <String, String>{
    'content-type': 'application/json',
  };
  switch (f) {
    case FornitoreIA.anthropic:
      h['x-api-key'] = k;
      h['anthropic-version'] = versioneAnthropic;
      return RichiestaIA(
        url: Uri.parse('$radice/v1/messages'),
        intestazioni: h,
        corpo: jsonEncode(<String, Object?>{
          'model': modello,
          'max_tokens': maxToken,
          'output_config': <String, Object?>{'effort': sforzoAnthropic},
          'messages': <Object?>[
            <String, Object?>{'role': 'user', 'content': testo},
          ],
        }),
      );
    case FornitoreIA.gemini:
      h['x-goog-api-key'] = k;
      return RichiestaIA(
        url: Uri.parse(
          '$radice/models/${Uri.encodeComponent(modello)}:generateContent',
        ),
        intestazioni: h,
        corpo: jsonEncode(<String, Object?>{
          'contents': <Object?>[
            <String, Object?>{
              'role': 'user',
              'parts': <Object?>[
                <String, Object?>{'text': testo},
              ],
            },
          ],
          'generationConfig': <String, Object?>{'maxOutputTokens': maxToken},
        }),
      );
    case FornitoreIA.openai:
    case FornitoreIA.compatibile:
      if (k.isNotEmpty) {
        h['authorization'] = 'Bearer $k';
      }
      final String fine = radice.endsWith('/chat/completions')
          ? radice
          : '$radice/chat/completions';
      // Niente max_tokens: i modelli nuovi OpenAI vogliono un altro nome,
      // molti compatibili il vecchio. La risposta è comunque breve.
      return RichiestaIA(
        url: Uri.parse(fine),
        intestazioni: h,
        corpo: jsonEncode(<String, Object?>{
          'model': modello,
          'messages': <Object?>[
            <String, Object?>{'role': 'user', 'content': testo},
          ],
        }),
      );
  }
}

Object? _a(Object? o, Object k) {
  if (k is String && o is Map<String, Object?>) {
    return o[k];
  }
  if (k is int && o is List<Object?> && k < o.length) {
    return o[k];
  }
  return null;
}

/// Testo della risposta JSON [json] di [f]. Vuota -> ErroreIA.
String leggiRisposta(FornitoreIA f, Object? json) {
  final StringBuffer b = StringBuffer();
  switch (f) {
    case FornitoreIA.anthropic:
      final Object? cont = _a(json, 'content');
      if (cont is List<Object?>) {
        for (final Object? p in cont) {
          if (_a(p, 'type') == 'text' && _a(p, 'text') is String) {
            b.write(_a(p, 'text'));
          }
        }
      }
    case FornitoreIA.gemini:
      final Object? parti = _a(
        _a(_a(_a(json, 'candidates'), 0), 'content'),
        'parts',
      );
      if (parti is List<Object?>) {
        for (final Object? p in parti) {
          if (_a(p, 'thought') != true && _a(p, 'text') is String) {
            b.write(_a(p, 'text'));
          }
        }
      }
    case FornitoreIA.openai:
    case FornitoreIA.compatibile:
      final Object? t = _a(
        _a(_a(_a(json, 'choices'), 0), 'message'),
        'content',
      );
      if (t is String) {
        b.write(t);
      }
  }
  final String s = b.toString().trim();
  if (s.isEmpty) {
    final Object? fine =
        _a(json, 'stop_reason') ??
        _a(_a(_a(json, 'candidates'), 0), 'finishReason') ??
        _a(_a(_a(json, 'choices'), 0), 'finish_reason');
    if (fine == 'max_tokens' || fine == 'MAX_TOKENS' || fine == 'length') {
      throw const ErroreIA(
        'risposta tagliata: l\'IA ha finito i token mentre ragionava '
        '(riprova o usa un modello più leggero)',
      );
    }
    throw const ErroreIA('risposta vuota: riprova o cambia modello');
  }
  return s;
}

/// Lunghezza massima del dettaglio d'errore mostrato.
const int maxDettaglioErrore = 240;

final RegExp _aspettoChiave = RegExp(
  r'(sk-[A-Za-z0-9_\-]{6,}|AIza[0-9A-Za-z_\-]{10,}|[A-Za-z0-9_\-]{32,})',
);

/// Motivo scritto dal fornitore nel corpo d'errore [json] (Anthropic,
/// OpenAI, Gemini, compatibili): 'tipo: messaggio', una riga, corto, con
/// tutto ciò che sembra una chiave sostituito. '' = niente da mostrare.
String dettaglioErroreIA(Object? json) {
  final Object? e = _a(json, 'error');
  String tipo = '';
  String msg = '';
  if (e is Map<String, Object?>) {
    final Object? t = e['type'] ?? e['status'] ?? e['code'];
    final Object? m = e['message'];
    tipo = t is String ? t : '';
    msg = m is String ? m : '';
  } else if (e is String) {
    msg = e;
  }
  final Object? m2 = _a(json, 'message');
  if (msg.isEmpty && m2 is String) {
    msg = m2;
  }
  String d = <String>[
    tipo,
    msg,
  ].where((String x) => x.trim().isNotEmpty).join(': ');
  d = d
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(_aspettoChiave, rigaRimossa)
      .trim();
  return d.length > maxDettaglioErrore
      ? '${d.substring(0, maxDettaglioErrore)}…'
      : d;
}

/// Spiegazione in italiano di alcuni motivi noti del fornitore ('' = no).
String spiegaDettaglioIA(String dettaglio) {
  final String d = dettaglio.toLowerCase();
  if (d.contains('credit balance') || d.contains('insufficient_quota')) {
    return 'credito finito sul conto API';
  }
  if (d.contains('model') &&
      (d.contains('not found') ||
          d.contains('not_found') ||
          d.contains('does not exist') ||
          d.contains('invalid model'))) {
    return 'nome del modello sbagliato';
  }
  if (d.contains('max_tokens')) {
    return 'limite token della risposta non accettato';
  }
  if (d.contains('thinking')) {
    return 'impostazione "ragionamento" non accettata dal modello';
  }
  if (d.contains('api key') ||
      d.contains('api_key') ||
      d.contains('authentication')) {
    return 'chiave API non accettata';
  }
  return '';
}

/// Messaggio per un codice HTTP sbagliato del fornitore. [dettaglio] =
/// motivo del fornitore già ripulito (dettaglioErroreIA), aggiunto in fondo.
String messaggioErroreIA(int codice, {String dettaglio = ''}) {
  final String base;
  if (codice == 401 || codice == 403) {
    base = 'chiave API sbagliata o senza permessi ($codice)';
  } else if (codice == 402) {
    base = 'credito finito sul conto API del fornitore (402)';
  } else if (codice == 429) {
    base =
        'limite raggiunto o credito finito (429): riprova più tardi '
        'o controlla il conto API';
  } else if (codice == 404) {
    base =
        'modello o indirizzo sbagliato (404): controlla il nome del '
        'modello';
  } else if (codice == 400 || codice == 422) {
    base = 'richiesta rifiutata dal fornitore ($codice)';
  } else if (codice >= 500) {
    base = 'il fornitore ha un problema ($codice): riprova più tardi';
  } else {
    base = 'errore dal fornitore ($codice)';
  }
  final String d = dettaglio.trim();
  if (d.isEmpty) {
    return base;
  }
  final String it = spiegaDettaglioIA(d);
  return '$base${it.isEmpty ? '' : ' — $it'}. Motivo del fornitore: $d';
}

/// Toglie [chiave] (se c'è) da [testo]: la risposta non deve mai salvarla.
String senzaChiave(String testo, String chiave) {
  final String k = chiave.trim();
  return k.length < minLunghezzaChiave
      ? testo
      : testo.replaceAll(k, rigaRimossa);
}

/// Un file resoconto trovato nella cartella.
typedef FileResoconto = ({String percorso, String nome});

/// Parte finale dei nomi dei file resoconto.
const String fineNomeResoconto = '_resoconto.md';

/// Nome del file resoconto, es. 'traker-ia_2026-11-10_progetto_resoconto.md'.
String nomeFileResoconto(DateTime inizio, {String nome = ''}) {
  final String base = nomeFileEsportazione(inizio, nome: nome);
  return '${base.substring(0, base.length - 3)}$fineNomeResoconto';
}

/// Vero se [nome] è un file resoconto della settimana che inizia il giorno
/// di [inizio] (null = di qualsiasi settimana).
bool eResoconto(String nome, {DateTime? inizio}) {
  if (!nome.startsWith('traker-ia_') || !nome.endsWith(fineNomeResoconto)) {
    return false;
  }
  if (inizio == null) {
    return true;
  }
  return nome.startsWith('traker-ia_${formatta(inizio).substring(0, 10)}');
}

/// Testo del file .md salvato: intestazione + risposta dell'IA.
String testoFileResoconto({
  required String risposta,
  required ConfigIA config,
  required DateTime creato,
  String chiave = '',
}) {
  final String pulita = senzaChiave(risposta, chiave);
  return '# Resoconto IA — TraKer IA by mdls\n'
      '\n'
      'Creato: ${formatta(creato)} · Fornitore: ${config.fornitore.nome} · '
      'Modello: ${config.modello}\n'
      '\n'
      '$pulita\n';
}
