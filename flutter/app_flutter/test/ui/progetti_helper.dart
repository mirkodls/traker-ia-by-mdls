// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Dati finti di più settimane per i test della pagina Progetti.
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/tempo.dart';

import 'servizi_finti.dart';

DateTime t(String s) => interpreta(s)!;

/// Ora finta: martedì 17/11/2026 12:00 (il reset della settimana in corso
/// è martedì 10/11 20:00).
final DateTime adessoFinto = t('2026-11-17 12:00');

/// Riempie [f] con [settimane] settimane CHIUSE (reset martedì 20:00) di
/// letture ogni [passoMin] minuti, più la settimana in corso fino a
/// [adessoFinto]; 2 progetti (Alfa e Beta) con note-comando in ogni
/// settimana (Alfa da solo, poi Alfa+Beta insieme).
void riempi(ServiziFinti f, {int settimane = 3, int passoMin = 30}) {
  f.prog
    ..clear()
    ..addAll(const <Progetto>[
      Progetto(id: 1, nome: 'Alfa', colore: 0xFF60A5FA, note: 'primo'),
      Progetto(id: 2, nome: 'Beta'),
    ]);
  final DateTime corrente = t('2026-11-10 20:00');
  for (int w = settimane; w >= 0; w--) {
    final DateTime ini = DateTime(
      corrente.year,
      corrente.month,
      corrente.day - 7 * w,
      20,
    );
    final DateTime fine = w == 0
        ? adessoFinto
        : DateTime(ini.year, ini.month, ini.day + 7, 20);
    int i = 0;
    for (
      DateTime x = ini;
      x.isBefore(fine);
      x = x.add(Duration(minutes: passoMin))
    ) {
      final int k = i * passoMin;
      f.lett.add(
        Lettura(
          ora: x,
          sett: ((k / 60) * 0.35 + w % 3).floorToDouble().clamp(0, 100),
          sess: ((k % 300) / 3).floorToDouble(),
        ),
      );
      i++;
    }
    void nota(int ore, String testo) => f.ev.add(
      Evento(
        ora: ini.add(Duration(hours: ore)),
        tipo: TipoEvento.nota,
        testo: testo,
      ),
    );
    nota(2, 'Alfa inizio');
    nota(10, 'Beta inizio');
    nota(20, 'Beta fine');
    nota(30, 'Alfa fine');
  }
}
