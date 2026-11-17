// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui (V2, B17): conferma costo prima di OGNI invio all'IA e dialogo
// che mostra un resoconto salvato (Copia, Apri file, Apri cartella).
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/resoconto_ia.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/servizi.dart';
import 'package:traker_ia/ui/tema.dart';

/// Chiede conferma prima di mandare dati all'IA di [c] (costo a consumo).
/// Vero = invia.
Future<bool> confermaInvioIA(BuildContext context, ConfigIA c) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      key: const ValueKey<String>('ia-conferma'),
      title: const Text(Testi.titoloConfermaIA),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              Testi.confermaIA(c.fornitore.nome, c.modello),
              style: stileNormale,
            ),
            const SizedBox(height: 8),
            const Text(
              Testi.avvisoCostoIA,
              key: ValueKey<String>('ia-costo'),
              style: TextStyle(color: Colori.errore, fontSize: Misure.piccolo),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('ia-annulla'),
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text(Testi.annulla),
        ),
        FilledButton(
          key: const ValueKey<String>('ia-invia'),
          onPressed: () => Navigator.of(ctx).pop(true),
          style: stileAccento(),
          child: const Text(Testi.tastoInviaIA),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Mostra il resoconto [testo] salvato in [percorso].
Future<void> apriDialogoResoconto(
  BuildContext context,
  Servizi servizi, {
  required String testo,
  required String percorso,
}) => showDialog<void>(
  context: context,
  builder: (BuildContext _) =>
      _DialogoResoconto(servizi: servizi, testo: testo, percorso: percorso),
);

class _DialogoResoconto extends StatefulWidget {
  const _DialogoResoconto({
    required this.servizi,
    required this.testo,
    required this.percorso,
  });

  final Servizi servizi;
  final String testo;
  final String percorso;

  @override
  State<_DialogoResoconto> createState() => _StatoDialogoResoconto();
}

class _StatoDialogoResoconto extends State<_DialogoResoconto> {
  String? _esito;

  Future<void> _copia() async {
    await Clipboard.setData(ClipboardData(text: widget.testo));
    if (mounted) {
      setState(() => _esito = Testi.copiato);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const ValueKey<String>('resoconto-dialogo'),
    title: const Text(Testi.titoloResoconto),
    content: SizedBox(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Flexible(
            child: SingleChildScrollView(
              child: SelectableText(
                widget.testo,
                key: const ValueKey<String>('resoconto-testo'),
                style: stileNormale,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(widget.percorso, style: stilePiccolo),
          if (_esito != null) Text(_esito!, style: stilePiccolo),
        ],
      ),
    ),
    actions: <Widget>[
      Wrap(
        spacing: 6,
        runSpacing: 4,
        alignment: WrapAlignment.end,
        children: <Widget>[
          TextButton(
            key: const ValueKey<String>('resoconto-copia'),
            onPressed: _copia,
            child: const Text(Testi.tastoCopiaEsporta),
          ),
          TextButton(
            key: const ValueKey<String>('resoconto-apri-file'),
            onPressed: () => widget.servizi.apriFile(widget.percorso),
            child: const Text(Testi.tastoApriFile),
          ),
          TextButton(
            key: const ValueKey<String>('resoconto-apri-cartella'),
            onPressed: () => widget.servizi.mostraCartella(widget.percorso),
            child: const Text(Testi.tastoApriCartella),
          ),
          TextButton(
            key: const ValueKey<String>('resoconto-chiudi'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(Testi.tastoChiudi),
          ),
        ],
      ),
    ],
  );
}
