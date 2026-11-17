// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain (V2): tipi puri Piano e Progetto. Nessuna logica di calcolo
// qui (arriva nei blocchi dopo).

/// % settimanale da raggiungere a fine piano (predefinita).
const double targetPredefinito = 99;

/// Tutti i giorni (lun-dom) nella maschera.
const int tuttiIGiorni = 0x7F;

/// Dove finisce un "giorno" del piano.
enum ConfinePiano {
  /// 24 ore a partire dall'ora del reset settimanale.
  reset24h;

  /// Testo salvato ('reset24h').
  String get testo => name;

  /// Da testo salvato; sconosciuto -> [reset24h].
  static ConfinePiano daTesto(String? s) {
    for (final ConfinePiano c in ConfinePiano.values) {
      if (c.name == s?.trim()) {
        return c;
      }
    }
    return ConfinePiano.reset24h;
  }
}

/// Maschera dei giorni: bit 0 = lunedì ... bit 6 = domenica
/// ([giorni] come DateTime.weekday, 1-7; fuori 1-7 ignorati).
int mascheraGiorni(Iterable<int> giorni) {
  int m = 0;
  for (final int g in giorni) {
    if (g >= DateTime.monday && g <= DateTime.sunday) {
      m |= 1 << (g - 1);
    }
  }
  return m;
}

/// Giorni (1 = lunedì ... 7 = domenica) della maschera [m], in ordine.
List<int> giorniDaMaschera(int m) => <int>[
  for (int g = DateTime.monday; g <= DateTime.sunday; g++)
    if (m & (1 << (g - 1)) != 0) g,
];

/// Piano di lavoro settimanale (immutabile).
class Piano {
  /// Crea un piano. [giorniMask] viene ristretta ai 7 bit dei giorni.
  const Piano({
    required this.nome,
    required this.giorniMask,
    required this.inizio,
    this.id,
    this.targetPct = targetPredefinito,
    this.confine = ConfinePiano.reset24h,
    this.fine,
  });

  /// Id nel database (null = non ancora salvato).
  final int? id;

  /// Nome del piano.
  final String nome;

  /// Giorni di lavoro (vedi [mascheraGiorni]).
  final int giorniMask;

  /// % settimanale da raggiungere a fine piano.
  final double targetPct;

  /// Confine del giorno.
  final ConfinePiano confine;

  /// Inizio validità.
  final DateTime inizio;

  /// Fine validità (null = ancora valido).
  final DateTime? fine;

  /// Giorni di lavoro (1 = lunedì ... 7 = domenica).
  List<int> get giorni => giorniDaMaschera(giorniMask & tuttiIGiorni);

  /// Numero di giorni di lavoro.
  int get numeroGiorni => giorni.length;

  /// Vero se [g] (1-7, come DateTime.weekday) è giorno di lavoro.
  bool lavoraIl(int g) =>
      g >= DateTime.monday &&
      g <= DateTime.sunday &&
      giorniMask & (1 << (g - 1)) != 0;
}

/// Progetto seguito nelle settimane (immutabile).
class Progetto {
  /// Crea un progetto.
  const Progetto({
    required this.nome,
    this.id,
    this.colore = 0,
    this.note = '',
  });

  /// Id nel database (null = non ancora salvato).
  final int? id;

  /// Nome del progetto.
  final String nome;

  /// Colore ARGB (0xAARRGGBB).
  final int colore;

  /// Note libere.
  final String note;
}
