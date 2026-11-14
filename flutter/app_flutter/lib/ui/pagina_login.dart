// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui (solo telefono): pagina di login del fornitore dentro l'app
// (webview_flutter). Fatto il login prende da sola il cookie di sessione e
// lo restituisce a chi l'ha aperta (che lo mette in cassaforte).
// Il cookie non si mostra e non si scrive mai nei log.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/fornitori.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/servizi.dart';
import 'package:traker_ia/ui/tema.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  bool _errore = false;

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
    await _web.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _web.setUserAgent(agenteWebTelefono);
    await _web.setBackgroundColor(Colori.sfondo);
    await _web.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (_) => _segna(carica: true),
        onPageFinished: (_) {
          _segna(carica: false);
          unawaited(_controlla());
        },
        onUrlChange: (_) => unawaited(_controlla()),
        onWebResourceError: (WebResourceError e) {
          if (e.isForMainFrame ?? false) {
            _segna(carica: false, errore: true);
          }
        },
      ),
    );
    await _web.loadRequest(Uri.parse(widget.fornitore.paginaAccesso));
  }

  @override
  void dispose() {
    _controllo?.cancel();
    super.dispose();
  }

  void _segna({required bool carica, bool errore = false}) {
    if (mounted) {
      setState(() {
        _carica = carica;
        _errore = errore;
      });
    }
  }

  Future<void> _controlla() async {
    if (_fatto) {
      return;
    }
    final String? valore = widget.fornitore.cookieSessione(
      await widget.servizi.cookieWeb(widget.fornitore.sito),
    );
    if (valore == null || _fatto || !mounted) {
      return;
    }
    _fatto = true;
    _controllo?.cancel();
    Navigator.of(context).pop(valore);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colori.sfondo,
    appBar: AppBar(
      backgroundColor: Colori.carta,
      title: Text(Testi.titoloLogin(widget.fornitore.nome)),
    ),
    body: Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            _errore ? Testi.loginErrore : Testi.spiegaLogin,
            style: _errore
                ? const TextStyle(color: Colori.errore)
                : stilePiccolo,
          ),
        ),
        if (_carica) const LinearProgressIndicator(minHeight: 2),
        Expanded(child: WebViewWidget(controller: _web)),
      ],
    ),
  );
}
