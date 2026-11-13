// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: funzioni sul tempo (formato CSV, ore, reset settimanale).

/// Nomi brevi dei giorni, da lunedì.
const List<String> giorniBrevi = <String>[
  'lun',
  'mar',
  'mer',
  'gio',
  'ven',
  'sab',
  'dom',
];

String _due(int n) => n.toString().padLeft(2, '0');

/// Data nel formato dei CSV: 'aaaa-mm-gg hh:mm'.
String formatta(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_due(d.month)}-${_due(d.day)} '
    '${_due(d.hour)}:${_due(d.minute)}';

final RegExp _formato = RegExp(r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})$');

/// 'aaaa-mm-gg hh:mm' -> data. Testo sbagliato o data impossibile -> null.
DateTime? interpreta(String s) {
  final RegExpMatch? m = _formato.firstMatch(s.trim());
  if (m == null) {
    return null;
  }
  final List<int> n = <int>[
    for (int i = 1; i <= 5; i++) int.parse(m.group(i)!),
  ];
  if (n[1] < 1 || n[1] > 12 || n[2] < 1 || n[3] > 23 || n[4] > 59) {
    return null;
  }
  final DateTime d = DateTime(n[0], n[1], n[2], n[3], n[4]);
  return d.month == n[1] && d.day == n[2] ? d : null;
}

/// Stessa data senza secondi e microsecondi.
DateTime alMinuto(DateTime d) =>
    DateTime(d.year, d.month, d.day, d.hour, d.minute);

/// Ore (con decimali) da [da] ad [a]. Negativo se [a] viene prima.
double oreTra(DateTime da, DateTime a) =>
    a.difference(da).inMicroseconds / Duration.microsecondsPerHour;

/// Durata in ore (con decimali) -> Duration.
Duration durataOre(double ore) =>
    Duration(microseconds: (ore * Duration.microsecondsPerHour).round());

/// La più tarda tra [x] e [y].
DateTime piuTardi(DateTime x, DateTime y) => x.isAfter(y) ? x : y;

/// La più presto tra [x] e [y].
DateTime piuPresto(DateTime x, DateTime y) => x.isBefore(y) ? x : y;

/// Ultimo reset settimanale <= [ora]. Predefinito: martedì 20:00.
/// [giorno] come DateTime.weekday (1 = lunedì).
DateTime inizioSettimana(
  DateTime ora, {
  int giorno = DateTime.tuesday,
  int h = 20,
  int m = 0,
}) {
  final int indietro = (ora.weekday - giorno) % 7;
  final DateTime base = DateTime(ora.year, ora.month, ora.day - indietro, h, m);
  if (base.isAfter(ora)) {
    return DateTime(base.year, base.month, base.day - 7, h, m);
  }
  return base;
}

/// Prossimo reset settimanale (> [ora]).
DateTime prossimoReset(
  DateTime ora, {
  int giorno = DateTime.tuesday,
  int h = 20,
  int m = 0,
}) {
  final DateTime ini = inizioSettimana(ora, giorno: giorno, h: h, m: m);
  return DateTime(ini.year, ini.month, ini.day + 7, h, m);
}

/// Orario reset da mostrare: entro ±[tolMin] minuti dall'ora intera -> ora
/// intera (19:59 -> 20:00). Solo per mostrare/prevedere: i dati non cambiano.
DateTime? arrotondaReset(DateTime? d, {int tolMin = 2}) {
  if (d == null) {
    return null;
  }
  final DateTime base = DateTime(d.year, d.month, d.day, d.hour);
  final int tol = tolMin * Duration.microsecondsPerMinute;
  for (final DateTime h in <DateTime>[base, base.add(const Duration(hours: 1))]) {
    if (d.difference(h).inMicroseconds.abs() <= tol) {
      return h;
    }
  }
  return d;
}

/// 'mar 20:00'.
String quando(DateTime d) =>
    '${giorniBrevi[d.weekday - 1]} ${_due(d.hour)}:${_due(d.minute)}';

/// 'mar 17/11 20:00'.
String quandoData(DateTime d) =>
    '${giorniBrevi[d.weekday - 1]} ${_due(d.day)}/${_due(d.month)} '
    '${_due(d.hour)}:${_due(d.minute)}';

/// Copia ordinata per ora, stabile (a parità di ora resta l'ordine di arrivo).
List<T> ordinaPerOra<T>(Iterable<T> voci, DateTime Function(T) ora) {
  final List<T> l = voci.toList();
  bool ordinata = true;
  for (int i = 1; i < l.length && ordinata; i++) {
    if (ora(l[i]).isBefore(ora(l[i - 1]))) {
      ordinata = false;
    }
  }
  if (ordinata) {
    return l;
  }
  final List<int> idx = List<int>.generate(l.length, (int i) => i);
  idx.sort((int a, int b) {
    final int c = ora(l[a]).compareTo(ora(l[b]));
    return c != 0 ? c : a.compareTo(b);
  });
  return <T>[for (final int i in idx) l[i]];
}
