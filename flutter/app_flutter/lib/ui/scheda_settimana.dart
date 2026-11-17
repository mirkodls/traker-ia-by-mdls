// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui (V2, B13): scheda di una settimana archiviata di un progetto.
// Grafici RIDISEGNATI dall'istantanea salvata (non si ricalcola dalle
// letture vive), log, costo energia con STIMA, token scritti a mano.
import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/archivio_settimane.dart';
import 'package:traker_ia/domain/progetti.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/dialogo_esporta.dart';
import 'package:traker_ia/ui/grafico.dart';
import 'package:traker_ia/ui/grafico_dati.dart';
import 'package:traker_ia/ui/progetti_dati.dart';
import 'package:traker_ia/ui/stato_app.dart';
import 'package:traker_ia/ui/tema.dart';

/// Altezza del grafico principale salvato.
const double altezzaGraficoScheda = 260;

/// Altezza del grafico intensità salvato.
const double altezzaIntensitaScheda = 130;

/// Scheda di una settimana archiviata.
class SchedaSettimanaView extends StatelessWidget {
  /// Crea la scheda.
  const SchedaSettimanaView({
    required this.stato,
    required this.scheda,
    required this.mouse,
    required this.onIndietro,
    super.key,
  });

  /// Stato dell'app.
  final StatoApp stato;

  /// Dati già pronti della settimana.
  final SchedaSettimana scheda;

  /// Mouse condiviso dei due grafici.
  final MouseGrafici mouse;

  /// Torna all'elenco.
  final VoidCallback onIndietro;

  RigaArchivio get _riga {
    for (final RigaArchivio r in stato.settimane ?? const <RigaArchivio>[]) {
      if (r.id == scheda.riga.id) {
        return r;
      }
    }
    return scheda.riga;
  }

  @override
  Widget build(BuildContext context) {
    final RigaArchivio r = _riga;
    final String nome = nomeProgetto(r.progettoId, stato.progetti);
    final Color colore = coloreProgetto(r.progettoId, stato.progetti);
    final DateTime? fine = r.fine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            FilledButton(
              key: const ValueKey<String>('scheda-indietro'),
              onPressed: onIndietro,
              child: const Text(Testi.indietro),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: colore, shape: BoxShape.circle),
            ),
            OutlinedButton(
              key: const ValueKey<String>('scheda-esporta'),
              onPressed: () => apriDialogoEsporta(
                context,
                stato,
                <SettimanaProgetto>[r.riga],
              ),
              child: const Text(Testi.tastoEsportaIA),
            ),
            Text(nome, style: stileTitolo.copyWith(color: Colori.testo)),
            Text(
              Testi.intervalloSettimana(
                quandoData(r.inizio),
                fine == null ? '…' : quandoData(fine),
              ),
              style: stilePiccolo,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _graficiSalvati(),
        const SizedBox(height: 8),
        _costo(r),
        const SizedBox(height: 8),
        _CampoToken(key: ValueKey<int>(r.id), stato: stato, riga: r),
        const SizedBox(height: 8),
        _log(r),
      ],
    );
  }

  Widget _graficiSalvati() {
    final DatiGrafico? d = scheda.grafico;
    return Carta(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(Testi.titoloGraficiSalvati, style: stileTitolo),
          const SizedBox(height: 4),
          if (d == null)
            const Text(Testi.istantaneaRotta, style: stilePiccolo)
          else ...<Widget>[
            SizedBox(
              height: altezzaGraficoScheda,
              child: RepaintBoundary(
                child: Grafico(
                  key: const ValueKey<String>('scheda-grafico'),
                  tipo: TipoGrafico.principale,
                  dati: d,
                  letture: scheda.dati.letture,
                  mouse: mouse,
                  mostraIdeale: scheda.conPiano,
                  mostraAdattiva: scheda.conPiano,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: altezzaIntensitaScheda,
              child: RepaintBoundary(
                child: Grafico(
                  key: const ValueKey<String>('scheda-intensita'),
                  tipo: TipoGrafico.intensita,
                  dati: d,
                  letture: scheda.dati.letture,
                  mouse: mouse,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _costo(RigaArchivio r) {
    final List<String> righe = <String>[
      Testi.rigaSett(Testi.stimaPt(r.sett.stima, r.sett.min, r.sett.max)),
      Testi.rigaSess(Testi.stimaPt(r.sess.stima, r.sess.min, r.sess.max)),
      Testi.rigaOre(durata(r.oreAttive), durata(r.oreCondivise)),
      if (r.mediaSettOra != null && r.mediaSessOra != null)
        Testi.rigaMedie(numero(r.mediaSettOra), numero(r.mediaSessOra, dec: 1)),
      if (r.piccoSessOra != null)
        Testi.rigaPicco(numero(r.piccoSessOra, dec: 1)),
      if (r.token != null) Testi.rigaToken(r.token!),
    ];
    return Carta(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(Testi.titoloCosto, style: stileTitolo),
          const SizedBox(height: 4),
          for (final String t in righe)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(t, style: stileNormale),
            ),
        ],
      ),
    );
  }

  Widget _log(RigaArchivio r) {
    final String t = r.riga.log.trim();
    return Carta(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(Testi.titoloLog, style: stileTitolo),
          const SizedBox(height: 4),
          if (t.isEmpty)
            const Text(Testi.logVuoto, style: stilePiccolo)
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: SelectableText(
                  t,
                  key: const ValueKey<String>('scheda-log'),
                  style: stilePiccolo.copyWith(
                    fontFamily: 'Consolas',
                    color: Colori.testo,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Campo "token scritti a mano" (opzionale, mai calcolati dalle %).
class _CampoToken extends StatefulWidget {
  const _CampoToken({required this.stato, required this.riga, super.key});

  final StatoApp stato;
  final RigaArchivio riga;

  @override
  State<_CampoToken> createState() => _StatoCampoToken();
}

class _StatoCampoToken extends State<_CampoToken> {
  late final TextEditingController _testo = TextEditingController(
    text: widget.riga.token?.toString() ?? '',
  );
  String? _errore;

  @override
  void dispose() {
    _testo.dispose();
    super.dispose();
  }

  Future<void> _salva() async {
    final String t = _testo.text.trim();
    int? v;
    if (t.isNotEmpty) {
      v = int.tryParse(t);
      if (v == null || v < 0) {
        setState(() => _errore = Testi.tokenNonValidi);
        return;
      }
    }
    setState(() => _errore = null);
    await widget.stato.salvaTokenSettimana(widget.riga, v);
  }

  @override
  Widget build(BuildContext context) => Carta(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(Testi.spiegaToken, style: stilePiccolo),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                key: const ValueKey<String>('campo-token'),
                controller: _testo,
                style: stileNormale,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: Testi.campoToken,
                  errorText: _errore,
                ),
                onSubmitted: (_) => _salva(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const ValueKey<String>('salva-token'),
              onPressed: _salva,
              style: stileAccento(),
              child: const Text(Testi.salva),
            ),
          ],
        ),
      ],
    ),
  );
}
