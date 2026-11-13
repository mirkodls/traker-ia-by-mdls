// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: cursore periodo del grafico (scatto -> intervallo).

/// Scatti del cursore: etichetta e ore (null = Settimana o Tutto).
const List<({String etichetta, int? ore})> scatti = <({String etichetta, int? ore})>[
  (etichetta: '2 ore', ore: 2),
  (etichetta: '6 ore', ore: 6),
  (etichetta: '12 ore', ore: 12),
  (etichetta: '24 ore', ore: 24),
  (etichetta: '3 giorni', ore: 72),
  (etichetta: 'Settimana', ore: null),
  (etichetta: '7 giorni', ore: 168),
  (etichetta: 'Tutto', ore: null),
];

/// Indice dello scatto "Settimana" (dall'ultimo reset).
const int scattoSettimana = 5;

/// Indice dello scatto "Tutto" (dal primo dato).
const int scattoTutto = 7;

/// Scatto predefinito.
const int scattoPredefinito = scattoSettimana;

/// Indice valido; dato strano (non int, fuori range) -> predefinito.
int normalizzaScatto(Object? i) =>
    i is int && i >= 0 && i < scatti.length ? i : scattoPredefinito;

/// Etichetta dello scatto.
String etichettaScatto(Object? i) => scatti[normalizzaScatto(i)].etichetta;

/// (da, a) per lo scatto [i]. Settimana = da [inizioSett]; Tutto = da
/// [primoDato]. Settimana/Tutto: almeno 1 ora di larghezza.
({DateTime da, DateTime a}) intervallo(
  Object? i,
  DateTime ora,
  DateTime inizioSett,
  DateTime? primoDato,
) {
  final int n = normalizzaScatto(i);
  final int? ore = scatti[n].ore;
  if (ore != null) {
    return (da: ora.subtract(Duration(hours: ore)), a: ora);
  }
  final DateTime ini = n == scattoSettimana
      ? inizioSett
      : primoDato ?? ora.subtract(const Duration(days: 1));
  final DateTime minimo = ini.add(const Duration(hours: 1));
  return (da: ini, a: ora.isAfter(minimo) ? ora : minimo);
}
