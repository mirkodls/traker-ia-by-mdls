// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui (solo telefono): pagina di login del fornitore dentro l'app
// (webview_flutter). Fatto il login prende da sola il cookie di sessione e
// lo restituisce a chi l'ha aperta (che lo mette in cassaforte).
// Il cookie non si mostra e non si scrive mai nei log: la riga di
// controllo mostra solo sito+percorso, quanti cookie e se c'è la sessione.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/fornitori.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/servizi.dart';
import 'package:traker_ia/ui/tema.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Apre la pagina di login di [fornitore]; restituisce il cookie di
/// sessione (null = chiusa senza login).
Future<String?> apriLogin(
  BuildContext context,
  Servizi servizi,
  FornitoreWeb fornitore,
) => Navigator.of(context).push<String>(
  MaterialPageRoute<String>(
    builder: (BuildContext _) =>
        PaginaLogin(servizi: servizi, fornitore: fornitore),
  ),
);

/// Pagina di login dentro l'app.
class PaginaLogin extends StatefulWidget {
  /// Crea la pagina.
  const PaginaLogin({
    required this.servizi,
    required this.fornitore,
    super.key,
  });

  /// Servizi (per leggere i cookie della pagina).
  final Servizi servizi;

  /// Fornitore da cui entrare.
  final FornitoreWeb fornitore;

  @override
  State<PaginaLogin> createState() => _StatoPaginaLogin();
}

class _StatoPaginaLogin extends State<PaginaLogin> {
  final WebViewController _web = WebViewController();
  Timer? _controllo;
  bool _fatto = false;
  bool _carica = true;
  String? _errore;
  String _url = '';
  String _pagina = '';
  int _cookie = 0;
  bool _sessione = false;

  @override
  void initState() {
    super.initState();
    unawaited(_prepara());
    // Riserva: il sito cambia pagina anche senza ricaricarla.
    _controllo = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_controlla()),
    );
  }

  Future<void> _prepara() async {
    final Object p = _web.platform;
    if (p is AndroidWebViewController) {
      await widget.servizi.preparaWeb(p.webViewIdentifier);
    }
    await _web.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _web.setUserAgent(agenteWebTelefono);
    await _web.setBackgroundColor(Colori.sfondo);
    await _web.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String u) => _segna(carica: true, url: u),
        onPageFinished: (String u) {
          _segna(carica: false, url: u);
          unawaited(_controlla());
        },
        onUrlChange: (UrlChange c) {
          _segna(carica: _carica, url: c.url);
          unawaited(_controlla());
        },
        onWebResourceError: (WebResourceError e) {
          if (e.isForMainFrame ?? false) {
            _segna(carica: false, errore: '${e.errorCode}');
          }
        },
        onHttpError: (HttpResponseError e) {
          if (e.request?.uri.toString() == _url) {
            _segna(
              carica: false,
              errore: 'HTTP ${e.response?.statusCode ?? 0}',
            );
          }
        },
      ),
    );
    await _ricomincia();
  }

  Future<void> _ricomincia() =>
      _web.loadRequest(Uri.parse(widget.fornitore.paginaAccesso));

  @override
  void dispose() {
    _controllo?.cancel();
    super.dispose();
  }

  /// Solo sito + percorso: mai la parte dopo "?" (può avere codici).
  void _segna({required bool carica, String? url, String? errore}) {
    if (!mounted) {
      return;
    }
    setState(() {
      _carica = carica;
      _errore = errore;
      if (url != null) {
        _url = url;
        final Uri? u = Uri.tryParse(url);
        _pagina = u == null ? '' : '${u.host}${u.path}';
      }
    });
  }

  Future<void> _controlla() async {
    if (_fatto) {
      return;
    }
    final String tutti = await widget.servizi.cookieWeb(widget.fornitore.sito);
    final String? valore = widget.fornitore.cookieSessione(tutti);
    if (!mounted || _fatto) {
      return;
    }
    final int n = tutti.trim().isEmpty ? 0 : tutti.split(';').length;
    if (n != _cookie || (valore != null) != _sessione) {
      setState(() {
        _cookie = n;
        _sessione = valore != null;
      });
    }
    if (valore == null) {
      return;
    }
    _fatto = true;
    _controllo?.cancel();
    Navigator.of(context).pop(valore);
  }

  /// Android: composizione ibrida (più sicura contro lo schermo nero).
  Widget _vista() {
    final Object p = _web.platform;
    if (p is AndroidWebViewController) {
      return WebViewWidget.fromPlatformCreationParams(
        params: AndroidWebViewWidgetCreationParams(
          controller: p,
          displayWithHybridComposition: true,
        ),
      );
    }
    return WebViewWidget(controller: _web);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colori.sfondo,
    appBar: AppBar(
      backgroundColor: Colori.carta,
      title: Text(Testi.titoloLogin(widget.fornitore.nome)),
      actions: <Widget>[
        TextButton(
          onPressed: () => unawaited(_web.reload()),
          child: const Text(Testi.ricarica),
        ),
        TextButton(
          onPressed: () => unawaited(_ricomincia()),
          child: const Text(Testi.ricomincia),
        ),
      ],
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
          child: Text(
            _errore == null ? Testi.spiegaLogin : Testi.loginErrore(_errore!),
            style: _errore == null
                ? stilePiccolo
                : const TextStyle(color: Colori.errore),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          child: Text(
            Testi.controlloLogin(_pagina, _cookie, sessione: _sessione),
            style: stilePiccolo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_carica) const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _vista()),
      ],
    ),
  );
}
