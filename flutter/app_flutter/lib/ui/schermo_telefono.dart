// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui (solo telefono): tutto in una schermata, senza scorrere.
// In alto % piccole + ⟳ + ⚙, poi il grafico grande (zoom a due dita),
// sotto nota, modelli/skill e i tasti per Dati, Intensità, Confronti.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/periodo.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/dialoghi.dart';
import 'package:traker_ia/ui/grafico.dart';
import 'package:traker_ia/ui/grafico_dati.dart';
import 'package:traker_ia/ui/sezioni.dart';
import 'package:traker_ia/ui/stato_app.dart';
import 'package:traker_ia/ui/tema.dart';

/// Schermata unica del telefono.
class SchermoTelefono extends StatelessWidget {
  /// Crea la schermata.
  const SchermoTelefono({required this.stato, required this.mouse, super.key});

  /// Stato dell'app.
  final StatoApp stato;

  /// Mouse/dito sui grafici.
  final MouseGrafici mouse;

  @override
  Widget build(BuildContext context) {
    final DatiGrafico? d = stato.grafico;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _testata(context),
          RigaStato(stato: stato),
          const SizedBox(height: 4),
          Expanded(child: d == null ? const SizedBox.shrink() : _grafico(d)),
          const SizedBox(height: 6),
          RigaNota(stato: stato),
          const SizedBox(height: 6),
          BarraTasti(
            stato: stato,
            compatta: true,
            modifica: (Gruppo g) => apriModifica(context, stato, g),
          ),
          const SizedBox(height: 4),
          _tastiSezioni(context, d),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- testata

  Widget _testata(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: _Mini(
          titolo: Testi.cortoSess,
          valore: stato.cartaSess,
          colore: Colori.sess,
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: _Mini(
          titolo: Testi.cortoSett,
          valore: stato.cartaSett,
          colore: Colori.sett,
        ),
      ),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            tooltip: Testi.leggiOra,
            onPressed: stato.inLettura ? null : stato.leggi,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: Testi.impostazioni,
            onPressed: () => unawaited(_menu(context)),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
    ],
  );

  Future<void> _menu(BuildContext context) async {
    final String? scelta = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colori.carta,
      builder: (BuildContext c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _voce(c, Icons.settings, Testi.impostazioni, 'imp'),
            _voce(c, Icons.edit_note, Testi.letturaManuale, 'man'),
            _voce(c, Icons.smart_toy_outlined, Testi.gruppoModelli, 'mod'),
            _voce(c, Icons.bolt, Testi.gruppoSkill, 'skill'),
          ],
        ),
      ),
    );
    if (!context.mounted || scelta == null) {
      return;
    }
    switch (scelta) {
      case 'imp':
        await apriImpostazioni(
          context,
          stato,
          claudeCode: stato.servizi.claudeCodeTrovato,
        );
      case 'man':
        await apriManuale(context, stato);
      case 'mod':
        await apriModifica(context, stato, Gruppo.modelli);
      case 'skill':
        await apriModifica(context, stato, Gruppo.skill);
    }
  }

  Widget _voce(BuildContext c, IconData i, String t, String v) => ListTile(
    leading: Icon(i, color: Colori.accento),
    title: Text(t, style: stileNormale),
    onTap: () => Navigator.of(c).pop(v),
  );

  // ------------------------------------------------------------- grafico

  Widget _grafico(DatiGrafico d) => Carta(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
    child: Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Slider(
                value: stato.preferenze.periodo.toDouble(),
                max: (oreScatti.length - 1).toDouble(),
                divisions: oreScatti.length - 1,
                onChanged: (double v) => stato.cambiaPeriodo(v.round()),
              ),
            ),
            Text(
              etichettaScatto(stato.preferenze.periodo),
              style: stileTitolo.copyWith(color: Colori.accento),
            ),
            const SizedBox(width: 6),
          ],
        ),
        Expanded(
          // Due dita = zoom e spostamento; il grafico resta dentro il riquadro.
          child: ClipRect(
            child: InteractiveViewer(
              maxScale: 6,
              child: Grafico(
                tipo: TipoGrafico.principale,
                dati: d,
                letture: stato.letture,
                mouse: mouse,
              ),
            ),
          ),
        ),
        const Text(Testi.aiutoZoom, style: stilePiccolo),
      ],
    ),
  );

  // ------------------------------------------------------------ sezioni

  Widget _tastiSezioni(BuildContext context, DatiGrafico? d) => Row(
    children: <Widget>[
      for (final (String chiave, Widget Function() corpo) x
          in <(String, Widget Function())>[
            ('dati', () => CartaDati(stato: stato)),
            (
              'intensita',
              () => d == null
                  ? const SizedBox.shrink()
                  : Carta(
                      padding: const EdgeInsets.all(6),
                      child: SizedBox(
                        height: 220,
                        child: Grafico(
                          tipo: TipoGrafico.intensita,
                          dati: d,
                          letture: stato.letture,
                          mouse: mouse,
                        ),
                      ),
                    ),
            ),
            ('confronti', () => CartaConfronti(stato: stato)),
          ])
        Expanded(
          child: TextButton(
            onPressed: () => unawaited(_foglio(context, x.$1, x.$2)),
            child: Text(
              Testi.titoliSezioni[x.$1] ?? x.$1,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ),
    ],
  );

  Future<void> _foglio(
    BuildContext context,
    String chiave,
    Widget Function() corpo,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colori.sfondo,
    builder: (BuildContext c) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (BuildContext c, ScrollController sc) => ListenableBuilder(
        listenable: stato,
        builder: (BuildContext c, Widget? _) => ListView(
          controller: sc,
          padding: const EdgeInsets.all(10),
          children: <Widget>[
            Text(
              Testi.titoliSezioni[chiave] ?? chiave,
              style: stilePiccolo.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            corpo(),
          ],
        ),
      ),
    ),
  );
}

/// Carta % piccola per il telefono.
class _Mini extends StatelessWidget {
  const _Mini({
    required this.titolo,
    required this.valore,
    required this.colore,
  });

  final String titolo;
  final ValoreCarta valore;
  final Color colore;

  @override
  Widget build(BuildContext context) {
    final double? v = valore.valore;
    return Carta(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                percento(v),
                style: TextStyle(
                  color: colore,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  titolo,
                  style: stilePiccolo.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            valore.sotto,
            style: const TextStyle(color: Colori.spento, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: v == null ? 0 : (v / 100).clamp(0, 1).toDouble(),
              minHeight: 3,
              color: colore,
              backgroundColor: Colori.carta2,
            ),
          ),
        ],
      ),
    );
  }
}
