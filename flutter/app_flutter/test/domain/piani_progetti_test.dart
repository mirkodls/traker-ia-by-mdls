// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/piani_progetti.dart';

void main() {
  final DateTime t = DateTime(2026, 11, 17, 20);

  test('maschera giorni: andata e ritorno, fuori 1-7 ignorati', () {
    expect(mascheraGiorni(<int>[1, 3, 4, 5]), 0x1D);
    expect(mascheraGiorni(<int>[0, 8, 7, 7]), 0x40);
    expect(giorniDaMaschera(0x1D), <int>[1, 3, 4, 5]);
    expect(giorniDaMaschera(tuttiIGiorni), <int>[1, 2, 3, 4, 5, 6, 7]);
    expect(giorniDaMaschera(0), isEmpty);
  });

  test('piano: predefiniti e giorni', () {
    final Piano p = Piano(nome: 'Lavoro', giorniMask: 0x1D | 0x100, inizio: t);
    expect(p.id, isNull);
    expect(p.targetPct, 99);
    expect(p.confine, ConfinePiano.reset24h);
    expect(p.fine, isNull);
    expect(p.giorni, <int>[1, 3, 4, 5]);
    expect(p.numeroGiorni, 4);
    expect(p.lavoraIl(DateTime.monday), isTrue);
    expect(p.lavoraIl(DateTime.tuesday), isFalse);
    expect(p.lavoraIl(9), isFalse);
  });

  test('confine: testo e sconosciuto', () {
    expect(ConfinePiano.reset24h.testo, 'reset24h');
    expect(ConfinePiano.daTesto(' reset24h '), ConfinePiano.reset24h);
    expect(ConfinePiano.daTesto('boh'), ConfinePiano.reset24h);
    expect(ConfinePiano.daTesto(null), ConfinePiano.reset24h);
  });

  test('progetto: predefiniti', () {
    const Progetto p = Progetto(nome: 'TraKer');
    expect(p.id, isNull);
    expect(p.colore, 0);
    expect(p.note, '');
  });
}
