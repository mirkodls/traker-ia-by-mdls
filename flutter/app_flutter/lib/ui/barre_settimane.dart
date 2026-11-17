// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui (V2, B13): confronto tra settimane con barre semplici (niente
// disegno a mano: solo caselle colorate). Una barra = punti % settimanali
// consumati nella settimana (STIMA), a pezzi per progetto.
import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/progetti_dati.dart';
import 'package:traker_ia/ui/tema.dart';

/// Altezza utile delle barre.
const double altezzaBarre = 110;

String _due(int n) => n.toString().padLeft(2, '0');

/// Barre del confronto (la settimana più recente a destra).
class BarreSettimane extends StatelessWidget {
  /// Crea le barre.
  const BarreSettimane({
    required this.barre,
    required this.progetti,
    super.key,
  });

  /// Barre, dalla più vecchia.
  final List<BarraSettimana> barre;

  /// Progetti (per i colori).
  final List<Progetto> progetti;

  @override
  Widget build(BuildContext context) {
    final double cima = cimaBarre(barre);
    return RepaintBoundary(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            for (final BarraSettimana b in barre)
              _Barra(barra: b, cima: cima, progetti: progetti),
          ],
        ),
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.barra,
    required this.cima,
    required this.progetti,
  });

  final BarraSettimana barra;
  final double cima;
  final List<Progetto> progetti;

  @override
  Widget build(BuildContext context) {
    final DateTime d = barra.inizio;
    return Tooltip(
      message:
          '${quandoData(d)}: ${numero(barra.totale, dec: 1)} pt '
          '(${Testi.stima})',
      child: SizedBox(
        width: 46,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Text(
              numero(barra.totale, dec: 1),
              style: stilePiccolo.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: 24,
              height: altezzaBarre,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  for (final ({int progettoId, double valore}) s
                      in barra.segmenti.reversed)
                    if (s.valore > 0)
                      Container(
                        height: s.valore / cima * altezzaBarre,
                        color: coloreProgetto(s.progettoId, progetti),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_due(d.day)}/${_due(d.month)}',
              style: stilePiccolo.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
