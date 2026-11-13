// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato data: lettori Anthropic.
// 1) token di Claude Code (%USERPROFILE%\.claude\.credentials.json)
//    -> api.anthropic.com/api/oauth/usage
// 2) cookie sessionKey di claude.ai (in Cassaforte)
//    -> claude.ai/api/organizations/{id}/usage
// Scritto da zero; metodo capito dall'app Python di prova.
// Token e cookie: mai nei messaggi di errore, mai nei log.
import 'dart:convert';
import 'dart:io';

import 'package:traker_ia/data/cassaforte.dart';
import 'package:traker_ia/data/rete.dart';
import 'package:traker_ia/domain/analisi.dart';
import 'package:traker_ia/domain/catena.dart';
import 'package:traker_ia/domain/modelli.dart';

/// Indirizzo dell'uso per il token di Claude Code.
final Uri urlUsoOauth = Uri.https('api.anthropic.com', '/api/oauth/usage');

/// Indirizzo dell'elenco organizzazioni di claude.ai.
final Uri urlOrganizzazioni = Uri.https('claude.ai', '/api/organizations');

/// Indirizzo dell'uso di un'organizzazione di claude.ai.
Uri urlUsoOrg(String org) => Uri(
  scheme: 'https',
  host: 'claude.ai',
  pathSegments: <String>['api', 'organizations', org, 'usage'],
);

/// User-Agent da browser: claude.ai rifiuta i client sconosciuti.
const String agenteBrowser =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

/// File delle credenziali di Claude Code dell'utente.
String percorsoCredenzialiClaudeCode() {
  final Map<String, String> env = Platform.environment;
  final String casa = env['USERPROFILE'] ?? env['HOME'] ?? '';
  final String s = Platform.pathSeparator;
  return '$casa$s.claude$s.credentials.json';
}

/// Token dal testo del file credenziali; null se manca o è rotto.
String? tokenDaCredenziali(String testo) {
  try {
    final Object? d = jsonDecode(testo);
    if (d is! Map<String, Object?>) {
      return null;
    }
    final Object? oauth = d['claudeAiOauth'];
    if (oauth is! Map<String, Object?>) {
      return null;
    }
    final Object? t = oauth['accessToken'];
    return t is String && t.isNotEmpty ? t : null;
  } on FormatException {
    return null;
  }
}

/// Lettore col token di Claude Code.
class LettoreClaudeCode implements LettoreUso {
  /// Crea il lettore ([fileCredenziali] diverso solo nei test).
  LettoreClaudeCode({required this.client, String? fileCredenziali})
    : fileCredenziali = fileCredenziali ?? percorsoCredenzialiClaudeCode();

  /// Chi fa le richieste.
  final ClientJson client;

  /// Percorso del file credenziali.
  final String fileCredenziali;

  @override
  String get id => 'claude_code';

  @override
  String get nome => 'Claude Code';

  @override
  String get gestore => gestoreAnthropic;

  /// Vero se Claude Code sembra installato (file credenziali presente).
  bool get disponibile => File(fileCredenziali).existsSync();

  @override
  Future<Uso> leggi() async {
    final String testo;
    try {
      testo = await File(fileCredenziali).readAsString();
    } on FileSystemException {
      throw const ErroreLettura('Claude Code non trovato');
    }
    final String? token = tokenDaCredenziali(testo);
    if (token == null) {
      throw const ErroreLettura('Claude Code: login non trovato');
    }
    final Object? body = await client.prendi(urlUsoOauth, <String, String>{
      'Authorization': 'Bearer $token',
      'anthropic-beta': 'oauth-2025-04-20',
      'anthropic-version': '2023-06-01',
      'Accept': 'application/json',
      'User-Agent': agenteApp,
    });
    return leggiRisposta(body);
  }
}

/// Intestazioni per claude.ai col [cookie] (solo valore -> 'sessionKey=...').
Map<String, String> intestazioniCookie(String cookie) {
  String c = cookie.replaceAll(RegExp(r'[\r\n]'), '').trim();
  if (!c.contains('=')) {
    c = 'sessionKey=$c';
  }
  return <String, String>{
    'Cookie': c,
    'Accept': 'application/json',
    'User-Agent': agenteBrowser,
    'Referer': 'https://claude.ai/settings/usage',
  };
}

/// Sceglie l'organizzazione: prima quella con le chat (abbonamento
/// claude.ai), altrimenti la prima. Niente -> ErroreLettura.
String scegliOrganizzazione(Object? elenco) {
  if (elenco is! List<Object?>) {
    throw const ErroreLettura('nessuna organizzazione trovata');
  }
  String? prima;
  for (final Object? o in elenco) {
    if (o is! Map<String, Object?>) {
      continue;
    }
    final Object? uuid = o['uuid'];
    if (uuid is! String || uuid.isEmpty) {
      continue;
    }
    prima ??= uuid;
    final Object? cap = o['capabilities'];
    if (cap is List<Object?> && cap.contains('chat')) {
      return uuid;
    }
  }
  if (prima == null) {
    throw const ErroreLettura('nessuna organizzazione trovata');
  }
  return prima;
}

/// Lettore col cookie di claude.ai incollato a mano.
class LettoreClaudeWeb implements LettoreUso {
  /// Crea il lettore.
  LettoreClaudeWeb({required this.client, required this.cassaforte});

  /// Chi fa le richieste.
  final ClientJson client;

  /// Dove stanno cookie e organizzazione.
  final Cassaforte cassaforte;

  @override
  String get id => 'cookie';

  @override
  String get nome => 'cookie claude.ai';

  @override
  String get gestore => gestoreAnthropic;

  /// Vero se c'è un cookie salvato.
  Future<bool> disponibile() async =>
      ((await cassaforte.leggi(chiaveCookieAnthropic)) ?? '').trim().isNotEmpty;

  @override
  Future<Uso> leggi() async {
    final String cookie =
        ((await cassaforte.leggi(chiaveCookieAnthropic)) ?? '').trim();
    if (cookie.isEmpty) {
      throw const ErroreLettura('cookie mancante');
    }
    final Map<String, String> h = intestazioniCookie(cookie);
    String org = ((await cassaforte.leggi(chiaveOrgAnthropic)) ?? '').trim();
    if (org.isEmpty) {
      org = scegliOrganizzazione(await client.prendi(urlOrganizzazioni, h));
      await cassaforte.scrivi(chiaveOrgAnthropic, org);
    }
    return leggiRisposta(await client.prendi(urlUsoOrg(org), h));
  }
}

/// Lettori Anthropic disponibili adesso, in ordine di prova:
/// estensione (sempre), Claude Code (se installato), cookie (se salvato).
Future<List<LettoreUso>> lettoriAnthropic({
  required LettoreUso estensione,
  required LettoreClaudeCode claudeCode,
  required LettoreClaudeWeb web,
}) async => <LettoreUso>[
  estensione,
  if (claudeCode.disponibile) claudeCode,
  if (await web.disponibile()) web,
];
