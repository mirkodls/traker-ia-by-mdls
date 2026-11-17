// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui (V2, B14+B17): dialogo "Esporta per IA". Il testo si crea UNA
// volta all'apertura (mai in build); Copia lo mette negli appunti, Salva .md
// lo scrive nella cartella scelta. B17: Resoconto IA lo manda all'IA scelta
// (dopo conferma costo), salva la risposta come ..._resoconto.md e la
// mostra; i resoconti già salvati della settimana si rileggono da qui.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/archivio_settimane.dart';
import 'package:traker_ia/domain/export_ia.dart';
import 'package:traker_ia/domain/progetti.dart';
import 'package:traker_ia/domain/resoconto_ia.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/dialogo_resoconto.dart';
import 'package:traker_ia/ui/stato_app.dart';
import 'package:traker_ia/ui/tema.dart';

/// Quanti caratteri del testo si vedono nell'anteprima.
const int anteprimaEsportaCaratteri = 3000;

/// Apre il dialogo per esportare le [righe] (1 progetto o tutta una
/// settimana).
Future<void> apriDialogoEsporta(
  BuildContext context,
  StatoApp stato,
  List<SettimanaProgetto> righe,
) => showDialog<void>(
  context: context,
  builder: (BuildContext _) => _DialogoEsporta(stato: stato, righe: righe),
);

class _DialogoEsporta extends StatefulWidget {
  const _DialogoEsporta({required this.stato, required this.righe});

  final StatoApp stato;
  final List<SettimanaProgetto> righe;

  @override
  State<_DialogoEsporta> createState() => _StatoDialogoEsporta();
}

class _StatoDialogoEsporta extends State<_DialogoEsporta> {
  late final String _testoIA = _crea();
  late final TextEditingController _cartella = TextEditingController(
    text: widget.stato.servizi.cartellaEsportaPredefinita,
  );
  String? _esito;
  bool _errore = false;
  bool _occupato = false;
  List<FileResoconto> _salvati = <FileResoconto>[];

  @override
  void initState() {
    super.initState();
    unawaited(_caricaSalvati());
  }

  DateTime? get _inizio =>
      widget.righe.isEmpty ? null : widget.righe.first.inizio;

  /// Nome del progetto nei nomi file ('' = tutta la settimana).
  String get _nomeProgetto => widget.righe.length == 1
      ? nomeProgetto(widget.righe.first.progettoId, widget.stato.progetti)
      : '';

  Future<void> _caricaSalvati() async {
    final DateTime? i = _inizio;
    final String c = _cartella.text.trim();
    if (i == null || c.isEmpty) {
      return;
    }
    try {
      final List<FileResoconto> l = await widget.stato.servizi.resocontiSalvati(
        c,
        inizio: i,
      );
      if (mounted) {
        setState(() => _salvati = l);
      }
    } on Object {
      // cartella illeggibile: elenco vuoto
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

  Future<void> _resoconto() async {
    final String cart = _cartella.text.trim();
    if (cart.isEmpty) {
      _mostra(Testi.cartellaEsportaVuota, errore: true);
      return;
    }
    final ConfigIA c = widget.stato.preferenze.ia;
    if (c.fornitore.chiaveObbligatoria &&
        await widget.stato.servizi.fineChiaveIA(c.fornitore) == null) {
      _mostra(Testi.mancaChiaveIA, errore: true);
      return;
    }
    if (!mounted || !await confermaInvioIA(context, c)) {
      return;
    }
    setState(() => _occupato = true);
    _mostra(Testi.attendoIA);
    String? testo;
    String? percorso;
    try {
      final String risposta = await widget.stato.servizi.chiediIA(c, _testoIA);
      testo = testoFileResoconto(
        risposta: risposta,
        config: c,
        creato: DateTime.now(),
      );
      percorso = await widget.stato.servizi.salvaTestoInCartella(
        cartella: cart,
        nome: nomeFileResoconto(_inizio ?? DateTime.now(), nome: _nomeProgetto),
        testo: testo,
      );
      _mostra(Testi.resocontoSalvato(percorso));
    } on ErroreIA catch (e) {
      _mostra(Testi.erroreIA(e.messaggio), errore: true);
    } on Object catch (e) {
      _mostra(Testi.erroreSalvaEsporta('$e'), errore: true);
    }
    if (mounted) {
      setState(() => _occupato = false);
    }
    await _caricaSalvati();
    if (testo != null && percorso != null && mounted) {
      await apriDialogoResoconto(
        context,
        widget.stato.servizi,
        testo: testo,
        percorso: percorso,
      );
    }
  }

  Future<void> _apriSalvato(FileResoconto f) async {
    try {
      final String t = await widget.stato.servizi.leggiTestoFile(f.percorso);
      if (mounted) {
        await apriDialogoResoconto(
          context,
          widget.stato.servizi,
          testo: t,
          percorso: f.percorso,
        );
      }
    } on Object catch (e) {
      _mostra(Testi.erroreLeggiFile('$e'), errore: true);
    }
  }

  String _crea() {
    final Map<int, String> nomi = <int, String>{
      for (final SettimanaProgetto r in widget.righe)
        r.progettoId: nomeProgetto(r.progettoId, widget.stato.progetti),
    };
    return esportaPerIA(widget.righe, nomi);
  }

  String get _nomeFile {
    if (widget.righe.isEmpty) {
      return nomeFileEsportazione(DateTime.now());
    }
    return nomeFileEsportazione(widget.righe.first.inizio, nome: _nomeProgetto);
  }

  @override
  void dispose() {
    _cartella.dispose();
    super.dispose();
  }

  Future<void> _copia() async {
    await Clipboard.setData(ClipboardData(text: _testoIA));
    if (!mounted) {
      return;
    }
    setState(() {
      _esito = Testi.copiatoEsporta;
      _errore = false;
    });
  }

  Future<void> _salva() async {
    final String c = _cartella.text.trim();
    if (c.isEmpty) {
      setState(() {
        _esito = Testi.cartellaEsportaVuota;
        _errore = true;
      });
      return;
    }
    String msg;
    bool err = false;
    try {
      final String p = await widget.stato.servizi.salvaTestoInCartella(
        cartella: c,
        nome: _nomeFile,
        testo: _testoIA,
      );
      msg = Testi.salvatoEsporta(p);
    } on Object catch (e) {
      msg = Testi.erroreSalvaEsporta('$e');
      err = true;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _esito = msg;
      _errore = err;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String anteprima = _testoIA.length > anteprimaEsportaCaratteri
        ? '${_testoIA.substring(0, anteprimaEsportaCaratteri)}\n…'
        : _testoIA;
    return AlertDialog(
      title: const Text(Testi.titoloEsportaIA),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(Testi.spiegaEsportaIA, style: stilePiccolo),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  child: SelectableText(
                    anteprima,
                    key: const ValueKey<String>('esporta-anteprima'),
                    style: stilePiccolo.copyWith(
                      fontFamily: 'Consolas',
                      color: Colori.testo,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const ValueKey<String>('esporta-copia'),
                onPressed: _copia,
                style: stileAccento(),
                child: const Text(Testi.tastoCopiaEsporta),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey<String>('esporta-cartella'),
                controller: _cartella,
                onSubmitted: (String _) => unawaited(_caricaSalvati()),
                style: stileNormale,
                decoration: const InputDecoration(
                  labelText: Testi.campoCartellaEsporta,
                ),
              ),
              const SizedBox(height: 6),
              FilledButton(
                key: const ValueKey<String>('esporta-salva'),
                onPressed: _salva,
                child: const Text(Testi.tastoSalvaMd),
              ),
              const SizedBox(height: 6),
              FilledButton(
                key: const ValueKey<String>('esporta-resoconto'),
                onPressed: _occupato ? null : _resoconto,
                style: stileAccento(),
                child: const Text(Testi.tastoResocontoIA),
              ),
              if (_occupato)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: LinearProgressIndicator(),
                ),
              if (_esito != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _esito!,
                    key: const ValueKey<String>('esporta-esito'),
                    style: stilePiccolo.copyWith(
                      color: _errore ? Colori.errore : Colori.testo,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const Text(Testi.titoloResocontiSalvati, style: stileNormale),
              if (_salvati.isEmpty)
                const Text(Testi.nessunResoconto, style: stilePiccolo)
              else
                for (final FileResoconto f in _salvati)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: ValueKey<String>('resoconto-salvato-${f.nome}'),
                      onPressed: () => unawaited(_apriSalvato(f)),
                      child: Text(f.nome, style: stilePiccolo),
                    ),
                  ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('esporta-chiudi'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(Testi.tastoChiudi),
        ),
      ],
    );
  }
}
