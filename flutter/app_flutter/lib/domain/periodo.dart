// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: cursore periodo del grafico (scatto -> intervallo).
import 'traduzioni/testi_it.dart';

/// Ore di ogni scatto del cursore (null = Settimana o Tutto).
/// Etichette in Testi.scatti (file traduzioni), stesso ordine.
const List<int?> oreScatti = <int?>[2, 6, 12, 24, 72, null, 168, null];

/// Indice dello scatto "Settimana" (dall'ultimo reset).
const int scattoSettimana = 5;

/// Indice dello scatto "Tutto" (dal primo dato).
const int scattoTutto = 7;

/// Scatto predefinito.
const int scattoPredefinito = scattoSettimana;

/// Indice valido; dato strano (non int, fuori range) -> predefinito.
int normalizzaScatto(Object? i) =>
    i is int && i >= 0 && i < oreScatti.length ? i : scattoPredefinito;

/// Etichetta dello scatto.
String etichettaScatto(Object? i) => Testi.scatti[normalizzaScatto(i)];

/// (da, a) per lo scatto [i]. Settimana = da [inizioSett]; Tutto = da
/// [primoDato]. Settimana/Tutto: almeno 1 ora di larghezza.
({DateTime da, DateTime a}) intervallo(
  Object? i,
  DateTime ora,
  DateTime inizioSett,
  DateTime? primoDato,
) {
  final int n = normalizzaScatto(i);
  final int? ore = oreScatti[n];
  if (ore != null) {
    return (da: ora.subtract(Duration(hours: ore)), a: ora);
  }
  final DateTime ini = n == scattoSettimana
      ? inizioSett
      : primoDato ?? ora.subtract(const Duration(days: 1));
  final DateTime minimo = ini.add(const Duration(hours: 1));
  return (da: ini, a: ora.isAfter(minimo) ? ora : minimo);
}
