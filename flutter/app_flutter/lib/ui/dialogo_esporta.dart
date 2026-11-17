// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui (V2, B14): dialogo "Esporta per IA". Il testo si crea UNA volta
// all'apertura (mai in build); Copia lo mette negli appunti, Salva .md lo
// scrive nella cartella scelta. L'app non chiama nessuna IA.
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/archivio_settimane.dart';
import 'package:traker_ia/domain/export_ia.dart';
import 'package:traker_ia/domain/progetti.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
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
    final SettimanaProgetto p = widget.righe.first;
    final bool uno = widget.righe.length == 1;
    return nomeFileEsportazione(
      p.inizio,
      nome: uno ? nomeProgetto(p.progettoId, widget.stato.progetti) : '',
    );
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
