// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui (V2, B17): sezione "IA resoconto" delle Impostazioni.
// Fornitore/modello/URL si salvano da soli (impostazioni v2_ia_*, mai
// segreti). La chiave API va SOLO in cassaforte (Servizi.salvaChiaveIA):
// qui si vede solo "salvata ••••1234". Prova = chiamata minima con conferma.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/resoconto_ia.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/dialogo_resoconto.dart';
import 'package:traker_ia/ui/stato_app.dart';
import 'package:traker_ia/ui/tema.dart';

/// Sezione "IA resoconto" (solo PC).
class SezioneIA extends StatefulWidget {
  /// Crea la sezione.
  const SezioneIA({required this.stato, super.key});

  /// Stato dell'app.
  final StatoApp stato;

  @override
  State<SezioneIA> createState() => _StatoSezioneIA();
}

class _StatoSezioneIA extends State<SezioneIA> {
  late ConfigIA _c = widget.stato.preferenze.ia;
  late final TextEditingController _modello = TextEditingController(
    text: _c.modello,
  );
  late final TextEditingController _url = TextEditingController(text: _c.url);
  final TextEditingController _chiave = TextEditingController();
  String? _fine;
  String? _esito;
  bool _errore = false;
  bool _occupato = false;

  @override
  void initState() {
    super.initState();
    unawaited(_caricaFine());
  }

  @override
  void dispose() {
    // Salva dopo lo smontaggio (mai avvisare mentre l'albero è bloccato).
    final StatoApp st = widget.stato;
    final ConfigIA c = _config();
    scheduleMicrotask(() => unawaited(st.cambiaIA(c)));
    _modello.dispose();
    _url.dispose();
    _chiave.clear();
    _chiave.dispose();
    super.dispose();
  }

  ConfigIA _config() => _c.copia(modello: _modello.text, url: _url.text);

  Future<void> _caricaFine() async {
    final String? f = await widget.stato.servizi.fineChiaveIA(_c.fornitore);
    if (mounted) {
      setState(() => _fine = f);
    }
  }

  void _mostra(String testo, {bool errore = false}) {
    if (mounted) {
      setState(() {
        _esito = testo;
        _errore = errore;
      });
    }
  }

  Future<void> _cambiaFornitore(FornitoreIA? f) async {
    if (f == null || f == _c.fornitore) {
      return;
    }
    final ConfigIA vecchia = _config();
    setState(() {
      _c = vecchia.copia(fornitore: f);
      _modello.text = _c.modello;
      _chiave.clear();
      _esito = null;
      _fine = null;
    });
    await widget.stato.cambiaIA(_c);
    await _caricaFine();
  }

  Future<void> _salvaChiave() async {
    final String k = _chiave.text;
    _chiave.clear();
    if (k.trim().isEmpty) {
      return;
    }
    try {
      await widget.stato.servizi.salvaChiaveIA(_c.fornitore, k);
      _mostra(Testi.chiaveIASalvataOk);
    } on ErroreIA catch (e) {
      _mostra(Testi.erroreIA(e.messaggio), errore: true);
    }
    await _caricaFine();
  }

  Future<void> _cancellaChiave() async {
    await widget.stato.servizi.salvaChiaveIA(_c.fornitore, '');
    _mostra(Testi.chiaveIACancellata);
    await _caricaFine();
  }

  Future<void> _prova() async {
    final ConfigIA c = _config();
    await widget.stato.cambiaIA(c);
    if (!mounted) {
      return;
    }
    if (c.fornitore.chiaveObbligatoria && _fine == null) {
      _mostra(Testi.mancaChiaveIA, errore: true);
      return;
    }
    if (!await confermaInvioIA(context, c)) {
      return;
    }
    setState(() {
      _occupato = true;
      _esito = Testi.attendoIA;
      _errore = false;
    });
    String msg = Testi.provaIAOk;
    bool err = false;
    try {
      await widget.stato.servizi.provaIA(c);
    } on ErroreIA catch (e) {
      msg = Testi.erroreIA(e.messaggio);
      err = true;
    }
    if (mounted) {
      setState(() => _occupato = false);
    }
    _mostra(msg, errore: err);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Text(Testi.titoloIA, style: stileNormale),
      const Text(Testi.spiegaIA, style: stilePiccolo),
      const SizedBox(height: 4),
      const Text(Testi.campoFornitoreIA, style: stilePiccolo),
      DropdownButton<FornitoreIA>(
        key: const ValueKey<String>('ia-fornitore'),
        value: _c.fornitore,
        isExpanded: true,
        dropdownColor: Colori.carta2,
        style: stileNormale,
        items: <DropdownMenuItem<FornitoreIA>>[
          for (final FornitoreIA f in FornitoreIA.values)
            DropdownMenuItem<FornitoreIA>(value: f, child: Text(f.nome)),
        ],
        onChanged: _occupato
            ? null
            : (FornitoreIA? f) => unawaited(_cambiaFornitore(f)),
      ),
      TextField(
        key: const ValueKey<String>('ia-modello'),
        controller: _modello,
        style: stileNormale,
        decoration: const InputDecoration(labelText: Testi.campoModelloIA),
      ),
      if (_c.fornitore == FornitoreIA.compatibile)
        TextField(
          key: const ValueKey<String>('ia-url'),
          controller: _url,
          style: stileNormale,
          decoration: const InputDecoration(labelText: Testi.campoUrlIA),
        ),
      TextField(
        key: const ValueKey<String>('ia-chiave'),
        controller: _chiave,
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        style: stileNormale,
        decoration: const InputDecoration(labelText: Testi.campoChiaveIA),
      ),
      const SizedBox(height: 4),
      Text(
        Testi.chiaveIASalvata(_fine),
        key: const ValueKey<String>('ia-stato-chiave'),
        style: stilePiccolo,
      ),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: <Widget>[
          FilledButton(
            key: const ValueKey<String>('ia-salva-chiave'),
            onPressed: _occupato ? null : _salvaChiave,
            child: const Text(Testi.tastoSalvaChiaveIA),
          ),
          if (_fine != null)
            OutlinedButton(
              key: const ValueKey<String>('ia-cancella-chiave'),
              onPressed: _occupato ? null : _cancellaChiave,
              child: const Text(Testi.tastoCancellaChiaveIA),
            ),
          OutlinedButton(
            key: const ValueKey<String>('ia-prova'),
            onPressed: _occupato ? null : _prova,
            child: const Text(Testi.tastoProvaIA),
          ),
        ],
      ),
      const Text(Testi.spiegaChiaveIA, style: stilePiccolo),
      const Text(
        Testi.avvisoCostoIA,
        style: TextStyle(color: Colori.errore, fontSize: Misure.piccolo),
      ),
      if (_esito != null)
        Text(
          _esito!,
          key: const ValueKey<String>('ia-esito'),
          style: stilePiccolo.copyWith(
            color: _errore ? Colori.errore : Colori.testo,
          ),
        ),
    ],
  );
}
