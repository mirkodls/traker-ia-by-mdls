// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/periodo.dart';
import 'package:traker_ia/domain/riordino.dart';
import 'package:traker_ia/domain/vista.dart';

import 'aiuti.dart';

void main() {
  test('vista base e json rotto', () {
    final StatoVista v = StatoVista.daJson('rotto');
    expect(v.mostra().length, Sezione.values.length);
    expect(v.chiEspande(), Sezione.grafico);
    final StatoVista w = StatoVista.daJson(<String, Object?>{
      'visibili': <String, Object?>{'grafico': false, 'dati': 'boh'},
      'modo': 'strano',
      'primo_piano': true,
    });
    expect(w.visibili[Sezione.grafico], isFalse);
    expect(w.visibili[Sezione.dati], isTrue);
    expect(w.modo, ModoVista.tutto);
    expect(w.primoPiano, isTrue);
    expect(w.chiEspande(), Sezione.intensita);
    final StatoVista z = StatoVista.daJson(w.aJson());
    expect(z.aJson(), w.aJson());
  });

  test('modi solo-X e ritorno', () {
    final StatoVista g = StatoVista.base().scegliModo(ModoVista.grafico);
    expect(g.mostra(), <(Sezione, bool)>[(Sezione.grafico, true)]);
    expect(g.conTitoli, isFalse);
    expect(g.spuntata(Sezione.carte), isFalse);
    final StatoVista c = g.cambiaVisibile(Sezione.carte);
    expect(c.modo, ModoVista.tutto);
    expect(
      c.mostra().map(((Sezione, bool) x) => x.$1).toList(),
      <Sezione>[Sezione.carte, Sezione.grafico],
    );
    final StatoVista tutto = c.scegliModo(ModoVista.tutto);
    expect(tutto.mostra().length, Sezione.values.length);
  });

  test('aperta/chiusa e primo piano', () {
    final StatoVista v = StatoVista.base().cambiaAperta(Sezione.grafico);
    expect(v.chiEspande(), Sezione.intensita);
    expect(v.cambiaPrimoPiano().primoPiano, isTrue);
    final StatoVista nascosta = StatoVista.base().cambiaVisibile(Sezione.dati);
    expect(nascosta.spuntata(Sezione.dati), isFalse);
    expect(nascosta.cambiaVisibile(Sezione.dati).aperte[Sezione.dati], isTrue);
  });

  test('disponi barre a capo', () {
    final List<List<int>> g1 = <List<int>>[
      <int>[40, 40],
      <int>[30],
    ];
    final List<PostoTasto> p = disponi(g1, 200);
    expect(p[0], (gruppo: 0, indice: 0, x: 0, riga: 0));
    expect(p[1], (gruppo: 0, indice: 1, x: 44, riga: 0));
    expect(p[2], (gruppo: 1, indice: 0, x: 170, riga: 0));
    final List<List<int>> g2 = <List<int>>[
      <int>[60, 60],
      <int>[50],
    ];
    final List<PostoTasto> q = disponi(g2, 100);
    expect(q[1].riga, 1);
    expect(q[2], (gruppo: 1, indice: 0, x: 0, riga: 2));
  });

  test('sposta e indice di rilascio', () {
    expect(sposta(<String>['a', 'b', 'c'], 0, 2), <String>['b', 'c', 'a']);
    expect(sposta(<String>['a', 'b', 'c'], 2, -5), <String>['c', 'a', 'b']);
    expect(sposta(<String>['a'], 3, 0), <String>['a']);
    final List<Punto> centri = <Punto>[
      (x: 75, y: 10),
      (x: 50, y: 10),
      (x: 90, y: 10),
    ];
    expect(indiceRilascio(centri, 0, 5), 1);
  });

  test('riquadro mouse mai tagliato', () {
    final ({double x, double y, bool entra}) a =
        posizionaRiquadro(10, 10, 50, 20, 300, 200);
    expect((a.x, a.y, a.entra), (24.0, 24.0, true));
    final ({double x, double y, bool entra}) b =
        posizionaRiquadro(290, 190, 50, 20, 300, 200);
    expect((b.x, b.y, b.entra), (226.0, 156.0, true));
    expect(posizionaRiquadro(10, 10, 500, 20, 300, 200).entra, isFalse);
  });

  test('cursore periodo', () {
    expect(normalizzaScatto(true), scattoPredefinito);
    expect(normalizzaScatto(99), scattoPredefinito);
    expect(etichettaScatto(0), '2 ore');
    final DateTime ora = t('2026-11-13 12:00');
    expect(intervallo(1, ora, t('2026-11-10 20:00'), null).da, t('2026-11-13 06:00'));
    expect(intervallo(scattoSettimana, ora, t('2026-11-10 20:00'), null).da, t('2026-11-10 20:00'));
    expect(intervallo(scattoTutto, ora, ora, null).da, t('2026-11-12 12:00'));
    final ({DateTime da, DateTime a}) s =
        intervallo(scattoSettimana, ora, t('2026-11-13 11:50'), null);
    expect(s.a, t('2026-11-13 12:50'));
  });
}
