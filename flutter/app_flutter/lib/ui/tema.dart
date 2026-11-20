// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui: tema scuro (colori ripresi dall'app Python, riscritti).
import 'package:material_ui/material_ui.dart';

/// Colori dell'app.
abstract final class Colori {
  /// Sfondo finestra.
  static const Color sfondo = Color(0xFF0B1220);

  /// Sfondo carte.
  static const Color carta = Color(0xFF151E2E);

  /// Sfondo campi e tasti.
  static const Color carta2 = Color(0xFF1C2740);

  /// Bordi.
  static const Color bordo = Color(0xFF26324A);

  /// Testo normale.
  static const Color testo = Color(0xFFE5E9F0);

  /// Testo spento.
  static const Color spento = Color(0xFF8B97AD);

  /// Linea settimanale.
  static const Color sett = Color(0xFF60A5FA);

  /// Area sotto la linea settimanale.
  static const Color settArea = Color(0xFF15294A);

  /// Linea sessione 5 ore.
  static const Color sess = Color(0xFFFB923C);

  /// Linea Fable (rosa della tavolozza linee, stile_linee.dart).
  static const Color fable = Color(0xFFF472B6);

  /// Note.
  static const Color nota = Color(0xFFC084FC);

  /// Reset.
  static const Color reset = Color(0xFF4B5875);

  /// Fascia lavoro.
  static const Color lavoro = Color(0xFF10291C);

  /// Linea settimana oltre la soglia del giorno (rosso).
  static const Color settRossa = Color(0xFFEF4444);

  /// Linea ideale del piano (verde, tratteggio lungo).
  static const Color ideale = Color(0xFF4ADE80);

  /// Linea adattiva del piano (giallo, puntini).
  static const Color adattiva = Color(0xFFFACC15);

  /// Giorno senza lavoro nel piano (grigio tenue).
  static const Color giornoSpento = Color(0x0FFFFFFF);

  /// Riga verticale tra due giorni del piano.
  static const Color confineGiorno = Color(0xFF42527A);

  /// Pallino legenda lavoro.
  static const Color lavoroLegenda = Color(0xFF1F5E3B);

  /// Ok / sceso.
  static const Color ok = Color(0xFF34D399);

  /// Errore / salito.
  static const Color errore = Color(0xFFF87171);

  /// Griglia grafico.
  static const Color griglia = Color(0xFF1D2738);

  /// Accento (tasti principali, modelli accesi).
  static const Color accento = Color(0xFF3B82F6);

  /// Skill accese.
  static const Color skill = Color(0xFF7C3AED);

  /// Sfondo tasto inizio lavoro.
  static const Color inizioSfondo = Color(0xFF123024);

  /// Sfondo tasto fine lavoro.
  static const Color fineSfondo = Color(0xFF3B1D24);
}

/// Misure di testo.
abstract final class Misure {
  /// Testo piccolo.
  static const double piccolo = 12;

  /// Testo normale.
  static const double normale = 13.5;

  /// Numero grande delle carte.
  static const double carta = 28;
}

/// Stile piccolo spento.
const TextStyle stilePiccolo = TextStyle(
  color: Colori.spento,
  fontSize: Misure.piccolo,
);

/// Stile titolo (spento, grassetto).
const TextStyle stileTitolo = TextStyle(
  color: Colori.spento,
  fontSize: Misure.normale,
  fontWeight: FontWeight.bold,
);

/// Stile testo normale.
const TextStyle stileNormale = TextStyle(
  color: Colori.testo,
  fontSize: Misure.normale,
);

/// Tema scuro dell'app.
ThemeData temaScuro() {
  const ColorScheme cs = ColorScheme.dark(
    primary: Colori.accento,
    onPrimary: Colors.white,
    secondary: Colori.skill,
    surface: Colori.carta,
    onSurface: Colori.testo,
    error: Colori.errore,
  );
  final OutlineInputBorder bordoCampo = OutlineInputBorder(
    borderRadius: BorderRadius.circular(6),
    borderSide: BorderSide.none,
  );
  return ThemeData(
    colorScheme: cs,
    scaffoldBackgroundColor: Colori.sfondo,
    canvasColor: Colori.carta2,
    dialogTheme: const DialogThemeData(backgroundColor: Colori.sfondo),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Colori.carta2,
        border: Border.all(color: Colori.spento),
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: stileNormale,
      waitDuration: const Duration(milliseconds: 250),
      showDuration: const Duration(seconds: 30),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colori.carta2,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: bordoCampo,
      enabledBorder: bordoCampo,
      focusedBorder: bordoCampo.copyWith(
        borderSide: const BorderSide(color: Colori.accento),
      ),
      labelStyle: stilePiccolo,
      hintStyle: stilePiccolo,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colori.carta2,
        foregroundColor: Colori.testo,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: Misure.normale),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: Colori.accento,
      inactiveTrackColor: Colori.carta2,
      thumbColor: Colori.accento,
      trackHeight: 4,
    ),
    checkboxTheme: CheckboxThemeData(
      side: const BorderSide(color: Colori.spento),
      fillColor: WidgetStateProperty.resolveWith(
        (Set<WidgetState> s) =>
            s.contains(WidgetState.selected) ? Colori.accento : null,
      ),
    ),
    // Niente animazioni lunghe: leggerezza.
    splashFactory: NoSplash.splashFactory,
  );
}

/// Stile tasto accento (blu).
ButtonStyle stileAccento() => FilledButton.styleFrom(
  backgroundColor: Colori.accento,
  foregroundColor: Colors.white,
);

/// Carta (riquadro) dell'app.
class Carta extends StatelessWidget {
  /// Crea una carta.
  const Carta({required this.child, super.key, this.padding});

  /// Contenuto.
  final Widget child;

  /// Margine interno.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colori.carta,
      border: Border.all(color: Colori.bordo),
      borderRadius: BorderRadius.circular(8),
    ),
    padding: padding ?? const EdgeInsets.all(12),
    child: child,
  );
}
