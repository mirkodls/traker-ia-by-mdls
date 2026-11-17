// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui (V2): barra sopra il grafico intensità. Scelta della finestra N
// (30/60/120 minuti) dell'intensità postuma settimanale, casella "Solo
// Lavoro" e medie. Solo tasti e testo: i calcoli stanno nella cache dello
// stato.
import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/intensita.dart';
import 'package:traker_ia/domain/serie_intensita.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/stato_app.dart';
import 'package:traker_ia/ui/tema.dart';

String _num(double v, double err) =>
    numero(arrotondaStima(v, err), dec: err >= 1 ? 0 : (err >= 0.1 ? 1 : 2));

/// Testo delle medie ("Media: ~12 ±2 pt sess/h · ~1 ±1 pt sett/h (solo
/// Lavoro)"). Sempre "~" e "±": è una stima.
String testoMedie(StatIntensita st, {required bool soloLavoro}) {
  final List<String> parti = <String>[
    if (st.media5h != null)
      Testi.mediaBarra(
        _num(st.media5h!, st.errore5h ?? 0),
        numero(st.errore5h ?? 0, dec: (st.errore5h ?? 0) >= 1 ? 0 : 1),
        Testi.unita5h,
      ),
    if (st.media7gg != null)
      Testi.mediaBarra(
        _num(st.media7gg!, st.errore7gg ?? 0),
        numero(st.errore7gg ?? 0, dec: (st.errore7gg ?? 0) >= 1 ? 0 : 1),
        Testi.unita7gg,
      ),
  ];
  if (parti.isEmpty) {
    return Testi.nessunaMedia;
  }
  final String base = '${Testi.mediaPrefisso} ${parti.join(' · ')}';
  return soloLavoro ? '$base ${Testi.soloLavoroSuffisso}' : base;
}

/// Barra del grafico intensità: finestra postuma + solo Lavoro + medie.
class BarraIntensita extends StatelessWidget {
  /// Crea la barra.
  const BarraIntensita({required this.stato, required this.serie, super.key});

  /// Stato dell'app.
  final StatoApp stato;

  /// Serie intensità attuale (per le medie).
  final IntensitaV2 serie;

  @override
  Widget build(BuildContext context) {
    final int n = stato.preferenze.finestraPostuma;
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4, left: 4, right: 4),
      child: Wrap(
        spacing: 5,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Text(Testi.postumaMedia, style: stileTitolo),
          for (final int m in finestrePostuma)
            Tooltip(
              message: Testi.spiegaPostuma(m),
              child: InkWell(
                key: ValueKey<String>('postuma-$m'),
                borderRadius: BorderRadius.circular(5),
                onTap: () => stato.cambiaFinestraPostuma(m),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 30),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: n == m ? Colori.accento : Colori.carta2,
                    border: Border.all(
                      color: n == m ? Colori.accento : Colori.bordo,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    Testi.minutiN(m),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: n == m ? Colors.white : Colori.spento,
                      fontSize: Misure.piccolo,
                      fontWeight: n == m ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 6),
          Tooltip(
            message: Testi.spiegaSoloLavoro,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Checkbox(
                  key: const ValueKey<String>('solo-lavoro-int'),
                  value: stato.preferenze.soloLavoro,
                  visualDensity: VisualDensity.compact,
                  onChanged: (bool? v) =>
                      stato.cambiaSoloLavoro(acceso: v ?? false),
                ),
                const Text(Testi.contaSoloLavoroInt, style: stilePiccolo),
              ],
            ),
          ),
          Text(
            testoMedie(serie.stat, soloLavoro: serie.soloLavoro),
            key: const ValueKey<String>('medie-intensita'),
            style: stilePiccolo,
          ),
        ],
      ),
    );
  }
}
