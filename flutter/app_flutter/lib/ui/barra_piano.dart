// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui (V2): barra sotto il cursore periodo del grafico. Scelta dei
// giorni di lavoro (lun..dom + scorciatoie "primi N giorni") e interruttori
// delle linee ideale/adattiva. Solo tasti: i calcoli stanno nello stato.
import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/piano_giorni.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/stato_app.dart';
import 'package:traker_ia/ui/tema.dart';

/// Scorciatoie: primi N giorni dal reset.
const List<int> scorciatoieGiorni = <int>[1, 3, 4, 5, 7];

/// Barra del piano: giorni di lavoro + interruttori linee.
class BarraPiano extends StatelessWidget {
  /// Crea la barra.
  const BarraPiano({required this.stato, super.key});

  /// Stato dell'app.
  final StatoApp stato;

  @override
  Widget build(BuildContext context) {
    final int mask = stato.preferenze.giorniPiano;
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Wrap(
        spacing: 5,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Text(Testi.giorniLavoro, style: stileTitolo),
          for (int g = DateTime.monday; g <= DateTime.sunday; g++)
            _Pillola(
              chiave: ValueKey<String>('giorno-$g'),
              testo: giorniBrevi[g - 1],
              acceso: mask & (1 << (g - 1)) != 0,
              onTap: () => stato.cambiaGiornoPiano(g),
            ),
          const SizedBox(width: 6),
          for (final int n in scorciatoieGiorni)
            _Pillola(
              chiave: ValueKey<String>('primi-$n'),
              testo: '$n',
              acceso: mask == mascheraPrimiGiorni(n),
              spiega: Testi.primiGiorni(n),
              onTap: () => stato.scegliGiorniPiano(mascheraPrimiGiorni(n)),
            ),
          const SizedBox(width: 6),
          _Interruttore(
            chiave: const ValueKey<String>('linea-ideale'),
            testo: Testi.legIdeale,
            colore: Colori.ideale,
            spiega: Testi.spiegaIdeale,
            acceso: stato.preferenze.lineaIdeale,
            onCambia: (bool v) => stato.cambiaLineaIdeale(acceso: v),
          ),
          _Interruttore(
            chiave: const ValueKey<String>('linea-adattiva'),
            testo: Testi.legAdattiva,
            colore: Colori.adattiva,
            spiega: Testi.spiegaAdattiva,
            acceso: stato.preferenze.lineaAdattiva,
            onCambia: (bool v) => stato.cambiaLineaAdattiva(acceso: v),
          ),
        ],
      ),
    );
  }
}

/// Tasto piccolo acceso/spento (giorno o scorciatoia).
class _Pillola extends StatelessWidget {
  const _Pillola({
    required this.chiave,
    required this.testo,
    required this.acceso,
    required this.onTap,
    this.spiega,
  });

  final Key chiave;
  final String testo;
  final bool acceso;
  final VoidCallback onTap;
  final String? spiega;

  @override
  Widget build(BuildContext context) {
    final Widget w = InkWell(
      key: chiave,
      borderRadius: BorderRadius.circular(5),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 30),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: acceso ? Colori.accento : Colori.carta2,
          border: Border.all(color: acceso ? Colori.accento : Colori.bordo),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          testo,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: acceso ? Colors.white : Colori.spento,
            fontSize: Misure.piccolo,
            fontWeight: acceso ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
    final String? s = spiega;
    return s == null ? w : Tooltip(message: s, child: w);
  }
}

/// Casella con nome colorato come la sua linea.
class _Interruttore extends StatelessWidget {
  const _Interruttore({
    required this.chiave,
    required this.testo,
    required this.colore,
    required this.spiega,
    required this.acceso,
    required this.onCambia,
  });

  final Key chiave;
  final String testo;
  final Color colore;
  final String spiega;
  final bool acceso;
  final ValueChanged<bool> onCambia;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: spiega,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Checkbox(
          key: chiave,
          value: acceso,
          visualDensity: VisualDensity.compact,
          onChanged: (bool? v) => onCambia(v ?? false),
        ),
        Text(
          testo,
          style: TextStyle(
            color: colore,
            fontSize: Misure.piccolo,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
