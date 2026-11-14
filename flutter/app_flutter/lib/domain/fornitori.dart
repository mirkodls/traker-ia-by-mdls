// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: fornitori di IA leggibili col login dentro l'app
// (telefono). Ora solo Claude; ChatGPT/Gemini si aggiungono qui dopo.
import 'modelli.dart';

/// User-Agent della pagina di login: Chrome per telefono, senza il segno
/// "wv" della WebView (alcuni login rifiutano le WebView).
const String agenteWebTelefono =
    'Mozilla/5.0 (Linux; Android 14; SM-S911B) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36';

/// Un fornitore leggibile col login web dentro l'app.
class FornitoreWeb {
  /// Crea il fornitore.
  const FornitoreWeb({
    required this.id,
    required this.nome,
    required this.gestore,
    required this.paginaAccesso,
    required this.sito,
    required this.nomeCookie,
  });

  /// Id fisso ('claude').
  final String id;

  /// Nome mostrato.
  final String nome;

  /// Gestore delle letture (es. 'anthropic').
  final String gestore;

  /// Pagina di login aperta nell'app.
  final String paginaAccesso;

  /// Sito di cui leggere i cookie dopo il login.
  final String sito;

  /// Nome del cookie della sessione.
  final String nomeCookie;

  /// Valore del cookie di sessione dentro l'intestazione [cookie]
  /// ('a=1; sessionKey=xyz; b=2'); null se non c'è (login non finito).
  String? cookieSessione(String cookie) {
    for (final String pezzo in cookie.split(';')) {
      final int i = pezzo.indexOf('=');
      if (i <= 0) {
        continue;
      }
      if (pezzo.substring(0, i).trim() == nomeCookie) {
        final String v = pezzo.substring(i + 1).trim();
        return v.isEmpty ? null : v;
      }
    }
    return null;
  }
}

/// Claude (claude.ai).
const FornitoreWeb fornitoreClaude = FornitoreWeb(
  id: 'claude',
  nome: 'Claude',
  gestore: gestoreAnthropic,
  paginaAccesso: 'https://claude.ai/login',
  sito: 'https://claude.ai',
  nomeCookie: 'sessionKey',
);

/// Tutti i fornitori col login nell'app (MVP: solo Claude).
const List<FornitoreWeb> fornitoriWeb = <FornitoreWeb>[fornitoreClaude];
