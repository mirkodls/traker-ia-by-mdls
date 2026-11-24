// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui: sync Wi-Fi PC <-> telefono (B22) in Impostazioni > Generale.
// PC: "Abbina telefono" (codice grande) + elenco abbinati + "Dimentica".
// Telefono: "Abbina al PC" (scrivi il codice del PC) + "Sincronizza ora".
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/sync_dati.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/stato_app.dart';
import 'package:traker_ia/ui/tema.dart';

/// Sezione sync delle impostazioni.
class SezioneSync extends StatefulWidget {
  /// Crea la sezione.
  const SezioneSync({required this.stato, super.key});

  /// Stato dell'app.
  final StatoApp stato;

  @override
  State<SezioneSync> createState() => _SezioneSyncState();
}

class _SezioneSyncState extends State<SezioneSync> {
  List<String> _abbinati = const <String>[];
  String? _messaggio;
  bool _errore = false;
  bool _lavoro = false;

  bool get _tel => widget.stato.servizi.telefono;

  @override
  void initState() {
    super.initState();
    unawaited(_carica());
  }

  Future<void> _carica() async {
    final List<String> a = await widget.stato.servizi.abbinati();
    if (mounted) {
      setState(() => _abbinati = a);
    }
  }

  void _esito(EsitoSync e) {
    if (mounted) {
      setState(() {
        _messaggio = e.messaggio;
        _errore = !e.ok;
        _lavoro = false;
      });
    }
  }

  Future<void> _abbinaTel() async {
    setState(() {
      _lavoro = true;
      _messaggio = Testi.abbinaCerco;
      _errore = false;
    });
    final EsitoSync e = await widget.stato.servizi.abbinaAlPc(_chiediCodice);
    _esito(e);
    await _carica();
  }

  Future<String?> _chiediCodice() async {
    if (!mounted) {
      return null;
    }
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext _) => const _DialogoCodice(),
    );
  }

  Future<void> _sync({required bool tutto}) async {
    setState(() {
      _lavoro = true;
      _messaggio = null;
    });
    _esito(await widget.stato.sincronizza(tutto: tutto));
  }

  Future<void> _abbinaPc() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext _) => _DialogoAbbinaPc(stato: widget.stato),
    );
    await _carica();
  }

  Future<void> _dimentica() async {
    await widget.stato.servizi.dimenticaAbbinati();
    await _carica();
  }

  @override
  Widget build(BuildContext context) {
    final bool abbinato = _abbinati.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          !abbinato
              ? Testi.nessunTelefono
              : _tel
              ? Testi.pcAbbinato(_abbinati.last)
              : Testi.telefoniAbbinati(_abbinati),
          style: stilePiccolo,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            if (_tel && abbinato) ...<Widget>[
              FilledButton(
                key: const Key('sync-ora'),
                onPressed: _lavoro
                    ? null
                    : () => unawaited(_sync(tutto: false)),
                child: const Text(Testi.tastoSyncOra),
              ),
              OutlinedButton(
                key: const Key('sync-tutto'),
                onPressed: _lavoro ? null : () => unawaited(_sync(tutto: true)),
                child: const Text(Testi.tastoSyncTutto),
              ),
            ],
            OutlinedButton(
              key: const Key('sync-abbina'),
              onPressed: _lavoro
                  ? null
                  : () => unawaited(_tel ? _abbinaTel() : _abbinaPc()),
              child: Text(
                _tel ? Testi.tastoAbbinaPc : Testi.tastoAbbinaTelefono,
              ),
            ),
            if (!_tel && abbinato)
              TextButton(
                key: const Key('sync-dimentica'),
                onPressed: () => unawaited(_dimentica()),
                child: const Text(Testi.tastoDimenticaTelefoni),
              ),
          ],
        ),
        if (_messaggio != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _messaggio!,
              key: const Key('sync-messaggio'),
              style: _errore
                  ? stilePiccolo.copyWith(color: Colori.errore)
                  : stilePiccolo,
            ),
          ),
      ],
    );
  }
}

/// PC: dialogo di abbinamento (attesa -> codice -> fatto).
class _DialogoAbbinaPc extends StatefulWidget {
  const _DialogoAbbinaPc({required this.stato});

  final StatoApp stato;

  @override
  State<_DialogoAbbinaPc> createState() => _DialogoAbbinaPcState();
}

class _DialogoAbbinaPcState extends State<_DialogoAbbinaPc> {
  String? _codice;
  String? _fatto;
  bool _occupata = false;

  @override
  void initState() {
    super.initState();
    unawaited(_apri());
  }

  Future<void> _apri() async {
    final bool ok = await widget.stato.servizi.apriAbbinamento(
      codice: (String c) {
        if (mounted) {
          setState(() => _codice = c);
        }
      },
      fatto: (String n) {
        if (mounted) {
          setState(() => _fatto = n);
        }
      },
    );
    if (!ok && mounted) {
      setState(() => _occupata = true);
    }
  }

  @override
  void dispose() {
    widget.stato.servizi.chiudiAbbinamento();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colori.carta,
    title: const Text(Testi.titoloAbbina, style: stileNormale),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (_occupata)
            const Text(
              Testi.abbinaPortaOccupata,
              style: TextStyle(color: Colori.errore),
            )
          else if (_fatto != null)
            Text(Testi.abbinatoTelefono(_fatto!), style: stileNormale)
          else if (_codice != null) ...<Widget>[
            const Text(Testi.abbinaScriviCodice, style: stilePiccolo),
            const SizedBox(height: 8),
            SelectableText(
              _codice!,
              key: const Key('sync-codice-pc'),
              style: stileNormale.copyWith(
                fontSize: 40,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else
            const Text(Testi.abbinaAttesa, style: stilePiccolo),
        ],
      ),
    ),
    actions: <Widget>[
      TextButton(
        key: const Key('sync-chiudi'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(Testi.chiudi),
      ),
    ],
  );
}

/// Telefono: chiede il codice del PC (il campo vive col dialogo).
class _DialogoCodice extends StatefulWidget {
  const _DialogoCodice();

  @override
  State<_DialogoCodice> createState() => _DialogoCodiceState();
}

class _DialogoCodiceState extends State<_DialogoCodice> {
  final TextEditingController _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colori.carta,
    title: const Text(Testi.titoloAbbina, style: stileNormale),
    content: TextField(
      key: const Key('sync-codice'),
      controller: _c,
      autofocus: true,
      keyboardType: TextInputType.number,
      maxLength: 6,
      style: stileNormale.copyWith(fontSize: 24, letterSpacing: 6),
      decoration: const InputDecoration(labelText: Testi.campoCodicePc),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(Testi.annulla),
      ),
      FilledButton(
        key: const Key('sync-conferma'),
        onPressed: () => Navigator.of(context).pop(_c.text.trim()),
        child: const Text(Testi.tastoConferma),
      ),
    ],
  );
}
