// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain (V2): aspetto delle linee dei grafici (trasparenza e
// spessore), scelto dall'utente in Impostazioni. Puro: nessun import
// ui/data/dart:io. Solo numeri: i pittori li usano senza ricalcolare serie.

/// Spessore minimo (px).
const double spessoreMin = 0.5;

/// Spessore massimo (px).
const double spessoreMax = 6;

/// Una linea dei due grafici.
enum LineaGrafico {
  /// Grafico principale: % settimana (blu).
  settimana('settimana', 2),

  /// Grafico principale: % sessione 5 ore (arancione).
  sessione('sessione', 2),

  /// Grafico principale: linea ideale del piano (verde tratteggiata).
  ideale('ideale', 2),

  /// Grafico principale: linea adattiva del piano (gialla a puntini).
  adattiva('adattiva', 2.4),

  /// Grafico intensità: fonte 5 ore.
  int5h('int5h', 2),

  /// Grafico intensità: fonte 7 giorni.
  int7gg('int7gg', 2);

  const LineaGrafico(this.nome, this.spessorePredefinito);

  /// Nome nelle chiavi delle impostazioni (v2_linea_NOME_alfa e v2_linea_NOME_spessore).
  final String nome;

  /// Spessore di oggi (px): finché l'utente non tocca, nulla cambia.
  final double spessorePredefinito;

  /// Chiave impostazione dell'opacità (0-100, 100 = linea piena).
  String get chiaveAlfa => 'v2_linea_${nome}_alfa';

  /// Chiave impostazione dello spessore (px).
  String get chiaveSpessore => 'v2_linea_${nome}_spessore';

  /// Aspetto di oggi.
  StileLinea get predefinito => StileLinea(spessore: spessorePredefinito);
}

/// Aspetto di una linea: [alfa] = opacità % (100 = piena, 0 = invisibile);
/// [spessore] in px.
class StileLinea {
  /// Crea lo stile (valori NON controllati: usare [StileLinea.valido]).
  const StileLinea({required this.spessore, this.alfa = 100});

  /// Opacità 0-100 (la trasparenza mostrata all'utente è 100 - alfa).
  final int alfa;

  /// Spessore (px), da [spessoreMin] a [spessoreMax].
  final double spessore;

  /// Opacità 0-1 per il pittore.
  double get opacita => alfa / 100;

  /// Copia con valori riportati nei limiti (spessore a passo 0,1).
  static StileLinea valido(int alfa, double spessore) => StileLinea(
    alfa: alfa < 0 ? 0 : (alfa > 100 ? 100 : alfa),
    spessore: spessore.isNaN
        ? spessoreMin
        : _arrotonda(spessore.clamp(spessoreMin, spessoreMax)),
  );

  static double _arrotonda(double v) => (v * 10).roundToDouble() / 10;

  @override
  bool operator ==(Object other) =>
      other is StileLinea && other.alfa == alfa && other.spessore == spessore;

  @override
  int get hashCode => Object.hash(alfa, spessore);

  @override
  String toString() => 'StileLinea($alfa%, $spessore px)';
}

/// Aspetto di tutte le linee (immutabile). Solo le linee cambiate dall'utente
/// sono salvate in [_scelte]; le altre valgono [LineaGrafico.predefinito].
class StileLinee {
  /// Aspetto di oggi per tutte le linee.
  const StileLinee() : _scelte = const <LineaGrafico, StileLinea>{};

  const StileLinee._(this._scelte);

  /// Da impostazioni salvate (chiave -> testo). Valore mancante, rotto o
  /// fuori limiti -> aspetto predefinito di quella linea.
  factory StileLinee.daMappa(Map<String, String?> m) {
    final Map<LineaGrafico, StileLinea> s = <LineaGrafico, StileLinea>{};
    for (final LineaGrafico l in LineaGrafico.values) {
      final int? a = int.tryParse((m[l.chiaveAlfa] ?? '').trim());
      final double? p = double.tryParse(
        (m[l.chiaveSpessore] ?? '').trim().replaceAll(',', '.'),
      );
      final bool aOk = a != null && a >= 0 && a <= 100;
      final bool pOk =
          p != null && !p.isNaN && p >= spessoreMin && p <= spessoreMax;
      final StileLinea v = StileLinea.valido(
        aOk ? a : 100,
        pOk ? p : l.spessorePredefinito,
      );
      if (v != l.predefinito) {
        s[l] = v;
      }
    }
    return StileLinee._(Map<LineaGrafico, StileLinea>.unmodifiable(s));
  }

  final Map<LineaGrafico, StileLinea> _scelte;

  /// Aspetto della linea [l].
  StileLinea di(LineaGrafico l) => _scelte[l] ?? l.predefinito;

  /// Copia con la linea [l] cambiata (valori riportati nei limiti).
  StileLinee con(LineaGrafico l, {int? alfa, double? spessore}) {
    final StileLinea a = di(l);
    final StileLinea n = StileLinea.valido(
      alfa ?? a.alfa,
      spessore ?? a.spessore,
    );
    final Map<LineaGrafico, StileLinea> s = <LineaGrafico, StileLinea>{
      ..._scelte,
    };
    if (n == l.predefinito) {
      s.remove(l);
    } else {
      s[l] = n;
    }
    return StileLinee._(Map<LineaGrafico, StileLinea>.unmodifiable(s));
  }

  /// Vero se nessuna linea è stata cambiata.
  bool get predefinito => _scelte.isEmpty;

  /// Impostazioni da salvare (tutte le 12 chiavi).
  Map<String, String> aMappa() => <String, String>{
    for (final LineaGrafico l in LineaGrafico.values) ...<String, String>{
      l.chiaveAlfa: '${di(l).alfa}',
      l.chiaveSpessore: '${di(l).spessore}',
    },
  };

  @override
  bool operator ==(Object other) {
    if (other is! StileLinee) {
      return false;
    }
    for (final LineaGrafico l in LineaGrafico.values) {
      if (other.di(l) != di(l)) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(<StileLinea>[
    for (final LineaGrafico l in LineaGrafico.values) di(l),
  ]);
}

/// Soglia rossa: percentuale minima ammessa (della soglia del giorno).
const int sogliaRossoMin = 50;

/// Soglia rossa: percentuale massima ammessa.
const int sogliaRossoMax = 100;

/// Soglia rossa predefinita (95% della soglia del giorno).
const int sogliaRossoPredefinita = 95;

/// Soglia rossa valida (50-100); vuota/rotta/fuori limiti -> 95.
int sogliaRossoValida(int? v) =>
    v != null && v >= sogliaRossoMin && v <= sogliaRossoMax
    ? v
    : sogliaRossoPredefinita;
