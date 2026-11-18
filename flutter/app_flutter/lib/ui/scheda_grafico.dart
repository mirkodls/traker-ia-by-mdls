// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui (V2, B18): scheda "Grafico" delle Impostazioni. Per ogni linea:
// colore (tavolozza pronta), trasparenza, spessore. Sotto, l'ANTEPRIMA: il
// grafico vero, con i dati attuali, che cambia subito mentre si muovono
// cursori e colori. Cambiare lo stile è solo un ridisegno: le serie non
// vengono mai ricalcolate. Tutto si salva da solo.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/stile_linee.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/grafico.dart';
import 'package:traker_ia/ui/grafico_dati.dart';
import 'package:traker_ia/ui/stato_app.dart';
import 'package:traker_ia/ui/tema.dart';

/// Linee regolabili: id, nome e colore base (quello di oggi).
const List<(LineaGrafico, String, Color)> lineeImpostazioni =
    <(LineaGrafico, String, Color)>[
      (LineaGrafico.settimana, Testi.lineaSettimana, Colori.sett),
      (LineaGrafico.sessione, Testi.lineaSessione, Colori.sess),
      (LineaGrafico.ideale, Testi.lineaIdeale, Colori.ideale),
      (LineaGrafico.adattiva, Testi.lineaAdattiva, Colori.adattiva),
      (LineaGrafico.int5h, Testi.lineaInt5h, Colori.sess),
      (LineaGrafico.int7gg, Testi.lineaInt7gg, Colori.sett),
    ];

/// Larghezza da cui ogni linea sta tutta su una riga.
const double _larghezzaRigaUnica = 660;

/// Riga: etichetta + cursore + valore.
Widget _cursore({
  required Key chiave,
  required String etichetta,
  required double valore,
  required double min,
  required double max,
  required int divisioni,
  required String testoValore,
  required ValueChanged<double>? alCambio,
  required ValueChanged<double>? allaFine,
  double larghezzaEtichetta = 84,
  double larghezzaValore = 60,
}) => Row(
  children: <Widget>[
    if (larghezzaEtichetta > 0)
      SizedBox(
        width: larghezzaEtichetta,
        child: Text(etichetta, style: stilePiccolo),
      ),
    Expanded(
      child: Slider(
        key: chiave,
        value: valore.clamp(min, max).toDouble(),
        min: min,
        max: max,
        divisions: divisioni,
        onChanged: alCambio,
        onChangeEnd: allaFine,
      ),
    ),
    SizedBox(
      width: larghezzaValore,
      child: Text(testoValore, style: stilePiccolo, textAlign: TextAlign.end),
    ),
  ],
);

/// Scheda "Grafico" (PC e telefono).
class SchedaGrafico extends StatefulWidget {
  /// Crea la scheda.
  const SchedaGrafico({required this.stato, super.key});

  /// Stato dell'app.
  final StatoApp stato;

  @override
  State<SchedaGrafico> createState() => _StatoSchedaGrafico();
}

class _StatoSchedaGrafico extends State<SchedaGrafico> {
  final MouseGrafici _mouse = MouseGrafici();
  TipoGrafico _anteprima = TipoGrafico.principale;
  int? _sogliaProva; // soglia rossa mentre si trascina il cursore

  @override
  void dispose() {
    _mouse.dispose();
    super.dispose();
  }

  /// L'anteprima mostra il grafico a cui appartiene la linea che si tocca.
  void _vediLinea(LineaGrafico l) {
    final TipoGrafico t = l == LineaGrafico.int5h || l == LineaGrafico.int7gg
        ? TipoGrafico.intensita
        : TipoGrafico.principale;
    if (t != _anteprima) {
      setState(() => _anteprima = t);
    }
  }

  void _cambia(LineaGrafico l, StileLinee n, {required bool salva}) {
    _vediLinea(l);
    unawaited(widget.stato.cambiaStileLinee(n, salva: salva));
  }

  Widget _pallini(LineaGrafico l, Color base, StileLinea v) {
    final int baseArgb = base.toARGB32();
    final int scelto = v.colore ?? baseArgb;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: <Widget>[
        for (int i = 0; i < tavolozzaLinee.length; i++)
          GestureDetector(
            key: Key('linea-${l.nome}-colore-$i'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              final int c = tavolozzaLinee[i];
              _cambia(
                l,
                widget.stato.preferenze.stileLinee.con(
                  l,
                  colore: c == baseArgb ? null : c,
                  coloreBase: c == baseArgb,
                ),
                salva: true,
              );
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(tavolozzaLinee[i]),
                border: Border.all(
                  color: tavolozzaLinee[i] == scelto
                      ? Colors.white
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Una linea: nome, colore, trasparenza, spessore (compatta).
  Widget _riga(LineaGrafico l, String nome, Color base, double larghezza) {
    final StatoApp st = widget.stato;
    final StileLinea v = st.preferenze.stileLinee.di(l);
    StileLinee con({int? alfa, double? spessore}) =>
        st.preferenze.stileLinee.con(l, alfa: alfa, spessore: spessore);
    final Widget trasparenza = _cursore(
      chiave: Key('linea-${l.nome}-trasparenza'),
      etichetta: Testi.trasparenza,
      valore: (100 - v.alfa).toDouble(),
      min: 0,
      max: 100,
      divisioni: 20,
      testoValore: Testi.trasparenzaN(100 - v.alfa),
      alCambio: (double x) =>
          _cambia(l, con(alfa: 100 - x.round()), salva: false),
      allaFine: (double x) =>
          _cambia(l, con(alfa: 100 - x.round()), salva: true),
      larghezzaEtichetta: larghezza >= _larghezzaRigaUnica ? 0 : 84,
      larghezzaValore: larghezza >= _larghezzaRigaUnica ? 40 : 60,
    );
    final Widget spessore = _cursore(
      chiave: Key('linea-${l.nome}-spessore'),
      etichetta: Testi.spessore,
      valore: v.spessore,
      min: spessoreMin,
      max: spessoreMax,
      divisioni: 11,
      testoValore: Testi.spessoreN(v.spessore),
      alCambio: (double x) => _cambia(l, con(spessore: x), salva: false),
      allaFine: (double x) => _cambia(l, con(spessore: x), salva: true),
      larghezzaEtichetta: larghezza >= _larghezzaRigaUnica ? 0 : 84,
      larghezzaValore: larghezza >= _larghezzaRigaUnica ? 52 : 60,
    );
    final Widget nomeLinea = Row(
      children: <Widget>[
        Container(
          width: 18,
          height: 4,
          color: Color(v.colore ?? base.toARGB32()),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(nome, style: stileNormale)),
      ],
    );
    if (larghezza >= _larghezzaRigaUnica) {
      // PC largo: tutto su una riga: nome · colori · trasparenza · spessore.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: <Widget>[
            SizedBox(width: 170, child: nomeLinea),
            SizedBox(width: 284, child: _pallini(l, base, v)),
            Expanded(child: trasparenza),
            Expanded(child: spessore),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          nomeLinea,
          const SizedBox(height: 6),
          _pallini(l, base, v),
          trasparenza,
          spessore,
        ],
      ),
    );
  }

  /// PC largo: titoli delle colonne (le righe non hanno etichette).
  Widget _intestazioni() => const Padding(
    padding: EdgeInsets.only(top: 6),
    child: Row(
      children: <Widget>[
        SizedBox(width: 170),
        SizedBox(width: 284, child: Text(Testi.colore, style: stilePiccolo)),
        Expanded(child: Text(Testi.trasparenza, style: stilePiccolo)),
        Expanded(child: Text(Testi.spessore, style: stilePiccolo)),
      ],
    ),
  );

  Widget _impostazioni(double larghezza) {
    final StatoApp st = widget.stato;
    return ListenableBuilder(
      listenable: st,
      builder: (BuildContext _, Widget? _) {
        final int soglia = _sogliaProva ?? st.preferenze.sogliaRosso;
        final bool rosso = st.preferenze.rossoAcceso;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(Testi.titoloLinee, style: stileNormale),
            const Text(Testi.spiegaLinee, style: stilePiccolo),
            const SizedBox(height: 4),
            if (larghezza >= _larghezzaRigaUnica) _intestazioni(),
            for (final (LineaGrafico, String, Color) r in lineeImpostazioni)
              _riga(r.$1, r.$2, r.$3, larghezza),
            const Divider(height: 24),
            const Text(Testi.gruppoRosso, style: stileNormale),
            const Text(Testi.spiegaRosso, style: stilePiccolo),
            SwitchListTile(
              key: const Key('rosso-acceso'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: rosso,
              onChanged: (bool v) => unawaited(st.cambiaRossoAcceso(acceso: v)),
              title: const Text(Testi.rossoAcceso, style: stileNormale),
            ),
            _cursore(
              chiave: const Key('rosso-soglia'),
              etichetta: Testi.sogliaRosso,
              valore: soglia.toDouble(),
              min: sogliaRossoMin.toDouble(),
              max: sogliaRossoMax.toDouble(),
              divisioni: sogliaRossoMax - sogliaRossoMin,
              testoValore: Testi.sogliaRossoN(soglia),
              alCambio: rosso
                  ? (double x) => setState(() => _sogliaProva = x.round())
                  : null,
              allaFine: rosso
                  ? (double x) {
                      setState(() => _sogliaProva = null);
                      unawaited(st.cambiaSogliaRosso(x.round()));
                    }
                  : null,
              larghezzaValore: 96,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                key: const Key('ripristina-linee'),
                onPressed: () {
                  setState(() => _sogliaProva = null);
                  unawaited(st.ripristinaLinee());
                },
                child: const Text(Testi.ripristinaLinee),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Il grafico vero (stessi dati e stesso pittore dell'app), altezza fissa.
  Widget _grafico(double altezza, double larghezza) {
    final StatoApp st = widget.stato;
    return ListenableBuilder(
      listenable: st,
      builder: (BuildContext _, Widget? _) {
        final DatiGrafico? d = st.grafico;
        final bool principale = _anteprima == TipoGrafico.principale;
        final Preferenze p = st.preferenze;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                if (larghezza >= 500)
                  const Text(Testi.anteprima, style: stileNormale),
                ChoiceChip(
                  key: const Key('anteprima-principale'),
                  label: const Text(Testi.anteprimaPrincipale),
                  selected: principale,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) =>
                      setState(() => _anteprima = TipoGrafico.principale),
                ),
                ChoiceChip(
                  key: const Key('anteprima-intensita'),
                  label: const Text(Testi.anteprimaIntensita),
                  selected: !principale,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) =>
                      setState(() => _anteprima = TipoGrafico.intensita),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: altezza,
              child: d == null
                  ? const Center(
                      child: Text(Testi.anteprimaVuota, style: stilePiccolo),
                    )
                  : RepaintBoundary(
                      key: const Key('anteprima-grafico'),
                      child: Grafico(
                        key: ValueKey<TipoGrafico>(_anteprima),
                        tipo: _anteprima,
                        dati: d,
                        letture: st.letture,
                        mouse: _mouse,
                        modelliSkill: p.modelliSkill,
                        mostraIdeale: p.lavoroV2 && p.lineaIdeale,
                        mostraAdattiva: p.lavoroV2 && p.lineaAdattiva,
                        stile: p.stileLinee,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext _, BoxConstraints c) {
      // Anteprima ~200 px; se la finestra è bassa si accorcia (min 90).
      final double alt = (c.maxHeight * 0.32).clamp(90, 200).toDouble();
      return Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(Testi.siSalvaDaSolo, style: stilePiccolo),
                  _impostazioni(c.maxWidth - 32),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: _grafico(alt, c.maxWidth),
          ),
        ],
      );
    },
  );
}
